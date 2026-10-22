/*
 * DistQLDPC — in-process library entry point (web demo, WebAssembly build). See dq_api.h.
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * This translation unit includes distqldpc.cc with DQ_LIBRARY defined (a unity build), so dq_solve runs the CLI's
 * own option parser, checks, engines and summary printing; only the process plumbing differs:
 *   - matrices come from memory (dq_lib_load) instead of files; Gx / Gz are computed when not given;
 *   - the engine runs in-process (dq_lib_solve) instead of in a forked child; the pipe lines go through
 *     bounds_write -> dq_lib_bounds into the same BoundsBook / progress printing as the CLI's parent, and to the
 *     caller's callback;
 *   - -cpu-lim is a deadline polled by both engines (dq_poll_stop / dq_poll_stop_fast) instead of SIGKILL.
 * All other files of the library build are compiled with -DDQ_LIBRARY too (Solver.h / Solver.cc / cc_driver.cc use
 * the poll and the bound hook only under that macro); the CLI build never defines it.
 */
#ifndef DQ_LIBRARY
#define DQ_LIBRARY 1
#endif

#include "distqldpc.cc"
#include "dq_api.h"

#include <ctype.h>
#include <stdarg.h>
#include <atomic>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#ifndef DQ_GIT_COMMIT
#define DQ_GIT_COMMIT "unknown"
#endif

static dq_event_fn g_dq_cb = NULL;
static void* g_dq_user = NULL;
static const char* g_dq_txt[4] = { NULL, NULL, NULL, NULL };   /* Hx, Hz, Gx, Gz text of the current dq_solve */
static std::atomic<int> g_dq_cancel(0);
static bool g_dq_stopped = false;       /* latched once a stop was seen */
static double g_dq_deadline = 0;        /* wall-clock deadline (0: none) */
static bool g_dq_deadline_hit = false;
static BoundsBook* g_dq_book = NULL;
static ProgressState* g_dq_prog = NULL;
static bool g_dq_quiet = false;         /* solver stdout redirected to /dev/null (CLI child without -v) */
static int g_dq_saved_stdout = -1, g_dq_devnull = -1;
static double g_dq_t0 = 0;
static int g_dq_result = -1;

static bool dq_events_on() { return g_dq_cb != NULL; }

static void dq_emit(const char* line) {
    if (g_dq_cb) g_dq_cb(line, g_dq_user);
}

static void dq_event(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    char small[512];
    va_list ap2;
    va_copy(ap2, ap);
    const int len = vsnprintf(small, sizeof(small), fmt, ap);
    va_end(ap);
    if (len < 0) { va_end(ap2); return; }
    if ((size_t)len < sizeof(small)) {
        va_end(ap2);
        dq_emit(small);
        return;
    }
    std::string big((size_t)len + 1, '\0');
    vsnprintf(&big[0], big.size(), fmt, ap2);
    va_end(ap2);
    big.resize((size_t)len);
    dq_emit(big.c_str());
}

extern "C" int dq_poll_stop(void) {
    if (g_dq_stopped) return 1;
    if (g_dq_cancel.load(std::memory_order_relaxed)) { g_dq_stopped = true; return 1; }
    if (g_dq_deadline > 0 && wall_seconds() >= g_dq_deadline) {
        g_dq_deadline_hit = true;
        g_dq_stopped = true;
        return 1;
    }
    return 0;
}

/* MaxCDCL's withinBudget() calls this at every decision: read the clock only every 4096 calls. */
extern "C" int dq_poll_stop_fast(void) {
    static unsigned calls = 0;
    if (g_dq_stopped) return 1;
    if ((++calls & 4095u) != 0) return g_dq_cancel.load(std::memory_order_relaxed) ? dq_poll_stop() : 0;
    return dq_poll_stop();
}

static bool dq_lib_cancelled() { return g_dq_stopped && !g_dq_deadline_hit; }

/* One or more pipe-protocol lines from an engine: the CLI parent's bookkeeping and progress lines, then the callback. */
static void dq_lib_bounds(const char* buf, size_t n) {
    size_t i = 0;
    while (i < n) {
        size_t j = i;
        while (j < n && buf[j] != '\n') j++;
        if (j > i) {
            const std::string line(buf + i, j - i);
            if (g_dq_book) {
                if (g_dq_quiet) { fflush(stdout); dup2(g_dq_saved_stdout, STDOUT_FILENO); }
                apply_pipe_line(*g_dq_book, line.c_str(), g_dq_prog);
                if (g_dq_quiet) { fflush(stdout); dup2(g_dq_devnull, STDOUT_FILENO); }
            }
            dq_emit(line.c_str());
        }
        i = j + 1;
    }
}

/* ---- GF(2) logical bases: port of scripts/compute_logicals.py (same kernel basis, same quotient order, so the
 * rows are the script's rows). Gx = ker(Hx) / rs(Hz) (Z-type logicals), Gz = ker(Hz) / rs(Hx) (X-type). */
typedef std::vector<uint64_t> DqBits;

static inline bool dq_bit(const DqBits& v, int c) { return (v[(size_t)c >> 6] >> (c & 63)) & 1; }

static std::vector<DqBits> dq_rows_bits(const Matrix& M) {
    const int words = (M.cols + 63) / 64;
    std::vector<DqBits> out((size_t)M.rows, DqBits((size_t)words, 0));
    for (int r = 0; r < M.rows; r++)
        for (int c = 0; c < M.cols; c++)
            if (getm(M, r, c)) out[r][(size_t)c >> 6] |= 1ULL << (c & 63);
    return out;
}

/* _kernel_gf2: RREF with pivots in column order, one basis vector per free column. */
static std::vector<DqBits> dq_kernel(std::vector<DqBits> mat, int n) {
    const int words = (n + 63) / 64;
    std::vector<DqBits> basis;
    if (mat.empty()) {
        for (int i = 0; i < n; i++) {
            DqBits e((size_t)words, 0);
            e[(size_t)i >> 6] |= 1ULL << (i & 63);
            basis.push_back(e);
        }
        return basis;
    }
    const int m = (int)mat.size();
    std::vector<int> pivrow((size_t)n, -1), pivcols;
    int row = 0;
    for (int col = 0; col < n && row < m; col++) {
        int piv = -1;
        for (int r = row; r < m; r++)
            if (dq_bit(mat[r], col)) { piv = r; break; }
        if (piv < 0) continue;
        std::swap(mat[row], mat[piv]);
        pivcols.push_back(col);
        pivrow[col] = row;
        for (int r2 = 0; r2 < m; r2++)
            if (r2 != row && dq_bit(mat[r2], col))
                for (int w = 0; w < words; w++) mat[r2][w] ^= mat[row][w];
        row++;
    }
    for (int c = 0; c < n; c++) {
        if (pivrow[c] >= 0) continue;
        DqBits v((size_t)words, 0);
        v[(size_t)c >> 6] |= 1ULL << (c & 63);
        for (size_t t = 0; t < pivcols.size(); t++)   /* w[p] = mat[row(p)][c] in the fully reduced form */
            if (dq_bit(mat[pivrow[pivcols[t]]], c)) v[(size_t)pivcols[t] >> 6] |= 1ULL << (pivcols[t] & 63);
        basis.push_back(v);
    }
    return basis;
}

/* css_logical_nbit_rows.quotient: kernel vectors of `parity` not in the span of `mod_rows` and the earlier picks. */
static Matrix dq_quotient(const Matrix& parity, const Matrix& mod, int n) {
    const std::vector<DqBits> ker = dq_kernel(dq_rows_bits(parity), n);
    Gf2Basis span(n);
    for (const DqBits& r : dq_rows_bits(mod)) span.insert(r);
    Matrix out;
    out.rows = 0;
    out.cols = n;
    for (const DqBits& v : ker) {
        DqBits t(v);
        if (span.reduce(t)) continue;
        for (int c = 0; c < n; c++) out.data.push_back(dq_bit(v, c) ? 1 : 0);
        out.rows++;
        span.insert(v);
    }
    return out;
}

static bool dq_blank(const char* s) {
    if (!s) return true;
    for (; *s; s++)
        if (*s == '0' || *s == '1') return false;
    return true;
}

static Matrix dq_parse_text(const char* txt, const char* what) {
    if (dq_blank(txt)) {
        fprintf(stderr, "error: %s: empty matrix\n", what);
        exit(1);
    }
    FILE* f = fmemopen((void*)txt, strlen(txt), "r");
    if (!f) {
        fprintf(stderr, "error: %s: cannot read the matrix text\n", what);
        exit(1);
    }
    Matrix m = parse_matrix_stream(f);
    fclose(f);
    if (m.rows == 0 || m.cols < 0) {
        fprintf(stderr, "error: %s: empty matrix\n", what);
        exit(1);
    }
    return m;
}

static void dq_lib_load(Matrix& Hx, Matrix& Hz, Matrix& Gx, Matrix& Gz) {
    Hx = dq_parse_text(g_dq_txt[0], "Hx");
    Hz = dq_parse_text(g_dq_txt[1], "Hz");
    if (Hx.cols != Hz.cols) die("matrix column mismatch (Hx and Hz)");
    const bool gx_given = !dq_blank(g_dq_txt[2]), gz_given = !dq_blank(g_dq_txt[3]);
    if (gx_given != gz_given) die("give both Gx and Gz, or neither (then both are computed from Hx and Hz)");
    if (gx_given) {
        Gx = dq_parse_text(g_dq_txt[2], "Gx");
        Gz = dq_parse_text(g_dq_txt[3], "Gz");
        dq_event("LOGICALS given Gx %d Gz %d 0", Gx.rows, Gz.rows);
    } else {
        const double t0 = wall_seconds();
        Gx = dq_quotient(Hx, Hz, Hx.cols);   /* Z-type logicals: ker Hx / rs Hz */
        Gz = dq_quotient(Hz, Hx, Hx.cols);   /* X-type logicals: ker Hz / rs Hx */
        dq_event("LOGICALS computed Gx %d Gz %d %.6f", Gx.rows, Gz.rows, wall_seconds() - t0);
        if (Gx.rows == 0 || Gz.rows == 0) die("no logical qubits (k = 0): Hx and Hz define no nontrivial logical operator");
    }
    dq_event("INFO n %d Hx %d Hz %d Gx %d Gz %d", Hx.cols, Hx.rows, Hz.rows, Gx.rows, Gz.rows);
}

static int dq_lib_solve(const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
                        int cpu_lim, int verb, int card_mode, SolverBackend backend,
                        const char* roundingsat_bin, const char* dump_wcnf_path,
                        BoundsBook& out, bool& timed_out, ProgressState& prog)
{
    BoundsBook book;
    prog = ProgressState(verb == 0);
    g_dq_book = &book;
    g_dq_prog = &prog;
    dq_event("ENGINE %s", g_engine == ENGINE_CC ? "cc" : "maxsat");
    g_dq_deadline = cpu_lim != INT32_MAX ? wall_seconds() + (double)cpu_lim : 0;
    fflush(stdout);
    g_dq_quiet = false;
    if (quiet_solver_stdout(verb, backend)) {
        g_dq_saved_stdout = dup(STDOUT_FILENO);
        g_dq_devnull = open("/dev/null", O_WRONLY);
        if (g_dq_saved_stdout >= 0 && g_dq_devnull >= 0 && dup2(g_dq_devnull, STDOUT_FILENO) >= 0) g_dq_quiet = true;
    }
    /* any non-negative value: bounds_write hands every line to dq_lib_bounds, nothing is written to this fd */
    const int PIPE_TOKEN = 1 << 20;
    (void)run_engine(Hx, Hz, Gx, Gz, cpu_lim, verb, card_mode, backend, roundingsat_bin, dump_wcnf_path, PIPE_TOKEN);
    fflush(stdout);
    if (g_dq_quiet) dup2(g_dq_saved_stdout, STDOUT_FILENO);
    if (g_dq_saved_stdout >= 0) close(g_dq_saved_stdout);
    if (g_dq_devnull >= 0) close(g_dq_devnull);
    g_dq_saved_stdout = g_dq_devnull = -1;
    g_dq_quiet = false;
    g_dq_book = NULL;
    g_dq_prog = NULL;
    timed_out = g_dq_deadline_hit;
    out = book;
    return out.distance;
}

static void dq_lib_final(const BoundsBook& book, bool timed_out, int d) {
    const bool ok = d >= 0 && book.optimal && !timed_out;
    const char* st = ok ? "OPTIMAL" : timed_out ? "TIMEOUT" : dq_lib_cancelled() ? "CANCELLED" : book.trapped ? "TRAP" : "UNKNOWN";
    char lb[32], ub[32];
    if (book.has_lb) snprintf(lb, sizeof(lb), "%llu", (unsigned long long)book.lb); else snprintf(lb, sizeof(lb), "-");
    if (book.has_ub) snprintf(ub, sizeof(ub), "%llu", (unsigned long long)book.ub); else snprintf(ub, sizeof(ub), "-");
    g_dq_result = ok ? d : -1;
    dq_event("FINAL %d %s lb %s ub %s %.6f", ok ? d : -1, st, lb, ub, wall_seconds() - g_dq_t0);
}

/* Restores the option globals of distqldpc.cc to their initial values (keep in sync with that file). */
static void dq_reset_globals() {
    g_seed = 0;
    g_frontier_mode = 4;
    g_frontier_stats = g_frontier_check = false;
    g_oddcap_skip = true;
    g_ub_pre = UBPRE_ON_SECONDS;
    g_ub_pre_given = false;
    g_ub_pre_max_iters = 0;
    g_ub_pre_mutant = 0;
    g_ub_pre_hits = 16;
    g_ub_pre_plateau = 1000;
    g_css_joint = false;
    g_half_symbreak = true;
    g_dualmode = DUALMODE_SHARE;
    g_dualshare_stats = false;
    g_engine = ENGINE_MAXSAT;
    g_cc_opt = distcc::DriverOptions();
    g_dq_stab[0] = g_dq_stab[1] = NULL;
}

extern "C" int dq_solve(const char* hx, const char* hz, const char* gx, const char* gz, const char* flags,
                        dq_event_fn cb, void* user)
{
    dq_reset_globals();
    g_dq_txt[0] = hx; g_dq_txt[1] = hz; g_dq_txt[2] = gx; g_dq_txt[3] = gz;
    g_dq_cb = cb;
    g_dq_user = user;
    g_dq_cancel.store(0);
    g_dq_stopped = g_dq_deadline_hit = false;
    g_dq_deadline = 0;
    g_dq_result = -1;
    g_dq_t0 = wall_seconds();
    std::vector<std::string> args;
    args.push_back("distqldpc");
    const std::string f(flags ? flags : "");
    for (size_t i = 0; i < f.size();) {
        while (i < f.size() && isspace((unsigned char)f[i])) i++;
        size_t j = i;
        while (j < f.size() && !isspace((unsigned char)f[j])) j++;
        if (j > i) args.push_back(f.substr(i, j - i));
        i = j;
    }
    args.push_back("memory/input");   /* the code name (contains '/': used as given; matrices come from memory) */
    std::vector<char*> argv;
    for (size_t i = 0; i < args.size(); i++) argv.push_back(&args[i][0]);
    argv.push_back(NULL);
    (void)distqldpc_main((int)args.size(), argv.data());
    fflush(stdout);
    fflush(stderr);
    g_dq_cb = NULL;
    g_dq_user = NULL;
    return g_dq_result;
}

extern "C" void dq_cancel(void) { g_dq_cancel.store(1); }

extern "C" const char* dq_version(void) { return DQ_GIT_COMMIT; }

static char* dq_matrix_text(const Matrix& M) {
    std::string s;
    s.reserve((size_t)M.rows * ((size_t)M.cols * 2 + 1));
    for (int r = 0; r < M.rows; r++) {
        for (int c = 0; c < M.cols; c++) {
            if (c) s += ' ';
            s += getm(M, r, c) ? '1' : '0';
        }
        s += '\n';
    }
    char* out = (char*)malloc(s.size() + 1);
    if (out) memcpy(out, s.c_str(), s.size() + 1);
    return out;
}

extern "C" int dq_compute_logicals(const char* hx, const char* hz, char** gx_out, char** gz_out) {
    Matrix Hx = dq_parse_text(hx, "Hx"), Hz = dq_parse_text(hz, "Hz");
    if (Hx.cols != Hz.cols) die("matrix column mismatch (Hx and Hz)");
    Matrix Gx = dq_quotient(Hx, Hz, Hx.cols), Gz = dq_quotient(Hz, Hx, Hx.cols);
    if (gx_out) *gx_out = dq_matrix_text(Gx);
    if (gz_out) *gz_out = dq_matrix_text(Gz);
    return Gx.rows;
}

#ifdef __EMSCRIPTEN__
/* Browser entry: events go to Module.onDqEvent(line) (set by web/worker.js). */
EM_JS(void, dq_js_event, (const char* line), {
    if (Module["onDqEvent"]) Module["onDqEvent"](UTF8ToString(line));
});

static void dq_js_cb(const char* line, void*) { dq_js_event(line); }

extern "C" EMSCRIPTEN_KEEPALIVE int dq_solve_js(const char* hx, const char* hz, const char* gx, const char* gz, const char* flags) {
    return dq_solve(hx, hz, gx, gz, flags, dq_js_cb, NULL);
}
#endif
