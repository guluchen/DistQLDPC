/*
 * DistQLDPC — QLDPC / CSS code minimum distance via MaxCDCL (SimpSolver / MaxSAT).
 *
 * Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Data: data/matrices/<code>_{Hx,Hz,Gx,Gz}.txt
 *   Hx, Hz: X / Z stabilizer parity checks (rows of 0/1).
 *   Gx: Z-type logical basis rows (ker(Hx) / rowspan(Hz)), n bits each.
 *   Gz: X-type logical basis rows (ker(Hz) / rowspan(Hx)), n bits each.
 *
 * Stabilizer matrix (standard CSS symplectic convention):
 *   S = [Hx | 0]  (X stabilizers)  stacked with  [0 | Hz]  (Z stabilizers),  shape (m, 2n).
 *
 * Code distance (N(S)/S, Pauli weight):
 *   d = min { sum_i (x_i v z_i) : P = (x,z) in S^perp \ S, P != 0 }
 * where x_i,z_i are GF(2) Pauli components and (x_i v z_i) is 1 iff qubit i is nontrivial.
 *
 * MaxSAT encoding:
 *   - Hard: commutation with each row of S; P != 0; for each precomputed logical L_j,
 *           XOR(P|_Lj, a_j)=0 and (a_1 v ... v a_k).
 *   - Soft: unit (-w_i) weight 1 with w_i <-> x_i v z_i.
 *   - Implied (MaxCDCL solve path, GH-79): (-a_j v OR_{i in supp u} x_i) for verified
 *     low-weight u in Gx_j + rowspan(Hz), likewise z for Gz_j + rowspan(Hx); -no-conj omits.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdint.h>
#include <vector>
#include <algorithm>
#include <string>
#include <sys/wait.h>
#include <sys/time.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>

#include "utils/System.h"
#include "SimpSolver.h"

using namespace Minisat;

enum SolverBackend {
    SOLVER_MAXCDCL = 0,
    SOLVER_ROUNDINGSAT = 1,
};

static const char* DEFAULT_ROUNDINGSAT_BIN = "roundingsat";

struct Matrix {
    int rows;
    int cols;
    std::vector<uint8_t> data;
};

static void die(const char* msg) {
    fprintf(stderr, "error: %s\n", msg);
    exit(1);
}

static Matrix load_matrix(const char* path) {
    FILE* f = fopen(path, "r");
    if (!f) {
        fprintf(stderr, "error: cannot open %s\n", path);
        exit(1);
    }
    Matrix m;
    m.rows = 0;
    m.cols = -1;
    char line[65536];
    while (fgets(line, sizeof(line), f)) {
        char* p = line;
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '#' || *p == '\n' || *p == '\0') continue;
        std::vector<uint8_t> row;
        for (; *p; p++) {
            if (*p == '0') row.push_back(0);
            else if (*p == '1') row.push_back(1);
        }
        if (row.empty()) continue;
        if (m.cols < 0) m.cols = (int)row.size();
        else if ((int)row.size() != m.cols) die("inconsistent row width");
        m.data.insert(m.data.end(), row.begin(), row.end());
        m.rows++;
    }
    fclose(f);
    if (m.rows == 0 || m.cols < 0) die("empty matrix");
    return m;
}

static uint8_t getm(const Matrix& m, int r, int c) {
    return m.data[(size_t)r * m.cols + c];
}

static void add_hard_clause(SimpSolver& S, const std::vector<Lit>& lits) {
    vec<Lit> ps;
    for (size_t i = 0; i < lits.size(); i++) ps.push(lits[i]);
    if (!S.addClause_(ps, S.hardWeight))
        die("hard constraints UNSAT during encoding");
}

static void add_soft_clause(SimpSolver& S, const std::vector<Lit>& lits, unsigned w) {
    vec<Lit> ps;
    for (size_t i = 0; i < lits.size(); i++) ps.push(lits[i]);
    if (!S.addClause_(ps, w))
        die("soft clause contradicts previous constraints");
}

static Var ensure_var(SimpSolver& S, Var v) {
    while (v >= S.nVars()) S.newVar();
    return v;
}

static Lit xor2(SimpSolver& S, Lit a, Lit b, std::vector<Var>& aux) {
    Var t = ensure_var(S, S.nVars());
    aux.push_back(t);
    Lit tl = mkLit(t);
    std::vector<Lit> c1, c2, c3, c4;
    c1.push_back(~a); c1.push_back(~b); c1.push_back(~tl); add_hard_clause(S, c1);
    c2.push_back(a);  c2.push_back(b);  c2.push_back(~tl); add_hard_clause(S, c2);
    c3.push_back(a);  c3.push_back(~b); c3.push_back(tl);  add_hard_clause(S, c3);
    c4.push_back(~a); c4.push_back(b);  c4.push_back(tl);  add_hard_clause(S, c4);
    return tl;
}

static Lit parity(SimpSolver& S, const std::vector<Lit>& inputs, std::vector<Var>& aux) {
    if (inputs.empty()) die("empty parity");
    Lit acc = inputs[0];
    for (size_t i = 1; i < inputs.size(); i++)
        acc = xor2(S, acc, inputs[i], aux);
    return acc;
}

/* Force XOR(inputs) = value (0 or 1) via Tseitin chain. */
static void add_xor_equals(
    SimpSolver& S, const std::vector<Lit>& inputs, bool value, std::vector<Var>& aux)
{
    if (inputs.empty()) return;
    if (inputs.size() == 1) {
        std::vector<Lit> c;
        if (value) c.push_back(inputs[0]);
        else c.push_back(~inputs[0]);
        add_hard_clause(S, c);
        return;
    }
    Lit p = parity(S, inputs, aux);
    std::vector<Lit> c;
    if (value) c.push_back(p);
    else c.push_back(~p);
    add_hard_clause(S, c);
}

static void pipe_write_result(int pipe_w, int distance, bool optimal) {
    if (pipe_w < 0)
        return;
    char buf[64];
    int n = optimal && distance >= 0
        ? snprintf(buf, sizeof(buf), "RESULT %d OPTIMAL\n", distance)
        : snprintf(buf, sizeof(buf), "RESULT -1 UNKNOWN\n");
    if (n > 0)
        (void)write(pipe_w, buf, (size_t)n);
}

static const char* cardinality_mode_label(int mode) {
    switch (mode) {
        case 0: return "off (soft-conflict only)";
        case 1: return "Sinz+MTO (default, Sinz if n<=100)";
        case 2: return "Sinz only";
        case 3: return "MTO only";
        case 4: return "Sinz+MTO forced";
        default: return "unknown";
    }
}

struct StabilizerInstance {
    int n;
    int base_vars;
};

/* Aux bits for sum(x_i) = b + 2*a0 + 4*a1 + ... with Boolean a_j. */
static int parity_aux_count(int n, bool xor_one)
{
    if (n <= 1)
        return 0;
    int max_sum = xor_one ? n : (n - (n & 1));
    if (max_sum <= 0)
        return 0;
    for (int k = 1;; k++) {
        int rhs_max = (xor_one ? 1 : 0) + 2 * ((1 << k) - 1);
        if (rhs_max >= max_sum)
            return k;
    }
}

/*
 * Native GF(2) parity in OPB: x1+...+xn = b + 2*a0 + 4*a1 + ...
 * Returns new parity-aux 1-based var indices via out_aux (appended).
 */
static void write_parity_eq(
    FILE* f, const std::vector<int>& vars, bool xor_one, int& next_var,
    std::vector<int>& out_aux, int& ncons)
{
    const int n = (int)vars.size();
    if (n == 0)
        return;
    if (n == 1) {
        if (xor_one)
            fprintf(f, "+1 x%d >= 1;\n", vars[0]);
        else
            fprintf(f, "+1 ~x%d >= 1;\n", vars[0]);
        ncons++;
        return;
    }
    const int k = parity_aux_count(n, xor_one);
    std::vector<int> aux;
    for (int i = 0; i < k; i++)
        aux.push_back(next_var++);
    out_aux.insert(out_aux.end(), aux.begin(), aux.end());

    bool first = true;
    for (size_t vi = 0; vi < vars.size(); vi++) {
        int v = vars[vi];
        if (first) {
            fprintf(f, "+1 x%d", v);
            first = false;
        } else {
            fprintf(f, " +1 x%d", v);
        }
    }
    int coef = 2;
    for (int i = 0; i < k; i++) {
        fprintf(f, " -%d x%d", coef, aux[i]);
        coef *= 2;
    }
    fprintf(f, " = %d;\n", xor_one ? 1 : 0);
    ncons++;
}

static int z_var_idx(int n, int i) { return n + 1 + i; }
static int x_var_idx(int i) { return 1 + i; }
static int w_var_idx(int n, int i) { return 2 * n + 1 + i; }
static int a_var_idx(int n, int j) { return 3 * n + 1 + j; }

static void count_parity_row(int lit_count, int& ncons, int& parity_aux_total)
{
    ncons++;
    if (lit_count > 1)
        parity_aux_total += parity_aux_count(lit_count, false);
}

static void write_opb_native_parity(
    FILE* f,
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz)
{
    const int n = Hx.cols;
    const int k_log = Gx.rows + Gz.rows;
    const int base = 3 * n + k_log;

    int ncons = 0;
    int parity_aux_total = 0;

    for (int r = 0; r < Hx.rows; r++) {
        int cnt = 0;
        for (int i = 0; i < n; i++)
            if (getm(Hx, r, i))
                cnt++;
        count_parity_row(cnt, ncons, parity_aux_total);
    }
    for (int r = 0; r < Hz.rows; r++) {
        int cnt = 0;
        for (int i = 0; i < n; i++)
            if (getm(Hz, r, i))
                cnt++;
        count_parity_row(cnt, ncons, parity_aux_total);
    }
    ncons++; /* P != 0 */
    for (int j = 0; j < Gx.rows; j++) {
        int cnt = 0;
        for (int i = 0; i < n; i++)
            if (getm(Gx, j, i))
                cnt++;
        if (cnt == 0)
            ncons++;
        else
            count_parity_row(cnt + 1, ncons, parity_aux_total);
    }
    for (int j = 0; j < Gz.rows; j++) {
        int cnt = 0;
        for (int i = 0; i < n; i++)
            if (getm(Gz, j, i))
                cnt++;
        if (cnt == 0)
            ncons++;
        else
            count_parity_row(cnt + 1, ncons, parity_aux_total);
    }
    ncons++; /* OR of logical indicators */
    ncons += 3 * n; /* w <-> x v z */

    const int nvars = base + parity_aux_total;
    int next_var = base + 1;
    std::vector<int> parity_aux;
    int written = 0;

    fprintf(f, "* #variable= %d #constraint= %d\n", nvars, ncons);
    fprintf(f, "* DistQLDPC symplectic MaxSAT (native GF(2) parity, min Pauli weight)\n");

    fprintf(f, "min:");
    for (int i = 0; i < n; i++)
        fprintf(f, " +1 x%d", w_var_idx(n, i));
    fprintf(f, " ;\n");

    for (int r = 0; r < Hx.rows; r++) {
        std::vector<int> vars;
        for (int i = 0; i < n; i++)
            if (getm(Hx, r, i))
                vars.push_back(z_var_idx(n, i));
        write_parity_eq(f, vars, false, next_var, parity_aux, written);
    }
    for (int r = 0; r < Hz.rows; r++) {
        std::vector<int> vars;
        for (int i = 0; i < n; i++)
            if (getm(Hz, r, i))
                vars.push_back(x_var_idx(i));
        write_parity_eq(f, vars, false, next_var, parity_aux, written);
    }
    {
        bool first = true;
        for (int i = 0; i < n; i++) {
            if (first) {
                fprintf(f, "+1 x%d", w_var_idx(n, i));
                first = false;
            } else {
                fprintf(f, " +1 x%d", w_var_idx(n, i));
            }
        }
        fprintf(f, " >= 1;\n");
        written++;
    }
    for (int j = 0; j < Gx.rows; j++) {
        std::vector<int> vars;
        for (int i = 0; i < n; i++)
            if (getm(Gx, j, i))
                vars.push_back(x_var_idx(i));
        if (vars.empty()) {
            fprintf(f, "+1 ~x%d >= 1;\n", a_var_idx(n, j));
            written++;
        } else {
            vars.push_back(a_var_idx(n, j));
            write_parity_eq(f, vars, false, next_var, parity_aux, written);
        }
    }
    for (int j = 0; j < Gz.rows; j++) {
        std::vector<int> vars;
        for (int i = 0; i < n; i++)
            if (getm(Gz, j, i))
                vars.push_back(z_var_idx(n, i));
        if (vars.empty()) {
            fprintf(f, "+1 ~x%d >= 1;\n", a_var_idx(n, Gx.rows + j));
            written++;
        } else {
            vars.push_back(a_var_idx(n, Gx.rows + j));
            write_parity_eq(f, vars, false, next_var, parity_aux, written);
        }
    }
    {
        bool first = true;
        for (int j = 0; j < k_log; j++) {
            if (first) {
                fprintf(f, "+1 x%d", a_var_idx(n, j));
                first = false;
            } else {
                fprintf(f, " +1 x%d", a_var_idx(n, j));
            }
        }
        fprintf(f, " >= 1;\n");
        written++;
    }
    for (int i = 0; i < n; i++) {
        const int w = w_var_idx(n, i);
        const int x = x_var_idx(i);
        const int z = z_var_idx(n, i);
        fprintf(f, "+1 ~x%d +1 x%d +1 x%d >= 1;\n", w, x, z);
        fprintf(f, "+1 ~x%d +1 x%d >= 1;\n", x, w);
        fprintf(f, "+1 ~x%d +1 x%d >= 1;\n", z, w);
        written += 3;
    }
    (void)written;
}

/*
 * GH-79: implied conjugate-coset clauses.
 *
 * X side: the encoding has Hz x = 0 (hard) and a_j <-> Gx_j . x. For every h in
 * rowspace(Hz), h . x = 0, so every u in Gx_j + rowspace(Hz) satisfies u . x = a_j.
 * Hence (-a_j v OR_{i in supp(u)} x_i) is implied by the hard constraints; the
 * same holds on the Z side for Gz_j + rowspace(Hx) and the z variables. Adding
 * implied clauses leaves the feasible set and the optimum unchanged.
 *
 * Low-weight representatives are searched with a deterministic, bounded GF(2)
 * information-set procedure (seeded splitmix64 permutations; pivot-reduced coset
 * representative; greedy descent by single stabilizer rows). Every candidate is
 * re-verified by exact reduction of (u xor g) against an echelon basis of the
 * stabilizer row space; failures are dropped. Per row: candidates of weight
 * <= 2*wmin, greedy pairwise-disjoint packing first, then the lightest rest,
 * original row excluded (its XOR chain already enforces it), at most
 * CONJ_MAX_PER_ROW clauses.
 */
typedef std::vector<uint64_t> ConjBits;

static const int CONJ_MAX_PER_ROW = 4;
static const int CONJ_MAX_TRIALS = 32;
static const int CONJ_MIN_TRIALS = 4;
static const double CONJ_TRIAL_BUDGET = 1.5e8; /* estimated word operations per side */

static bool g_conj_clauses = true; /* -no-conj disables (baseline instance) */

static inline int conj_wt(const ConjBits& v) {
    int s = 0;
    for (size_t k = 0; k < v.size(); k++) s += __builtin_popcountll(v[k]);
    return s;
}
static inline bool conj_get(const ConjBits& v, int i) {
    return (v[(size_t)i >> 6] >> (i & 63)) & 1;
}
static inline void conj_xor(ConjBits& a, const ConjBits& b) {
    for (size_t k = 0; k < a.size(); k++) a[k] ^= b[k];
}
static inline bool conj_is_zero(const ConjBits& v) {
    for (size_t k = 0; k < v.size(); k++) if (v[k]) return false;
    return true;
}
static inline bool conj_disjoint(const ConjBits& a, const ConjBits& b) {
    for (size_t k = 0; k < a.size(); k++) if (a[k] & b[k]) return false;
    return true;
}

static ConjBits conj_row(const Matrix& M, int r, size_t words) {
    ConjBits v(words, 0);
    for (int i = 0; i < M.cols; i++)
        if (getm(M, r, i)) v[(size_t)i >> 6] |= (uint64_t)1 << (i & 63);
    return v;
}

struct ConjPivotRow {
    int pivot;
    ConjBits row;
};

/* Fully reduced echelon basis of span(rows); pivots taken in column `order`.
 * Stops once `max_rank` pivots are found (pass rows.size() if unknown). */
static std::vector<ConjPivotRow> conj_echelon(
    std::vector<ConjBits> rows, const std::vector<int>& order, size_t max_rank)
{
    std::vector<ConjPivotRow> basis;
    size_t used = 0;
    for (size_t oi = 0; oi < order.size() && used < rows.size() && basis.size() < max_rank; oi++) {
        const int c = order[oi];
        size_t sel = rows.size();
        for (size_t r = used; r < rows.size(); r++)
            if (conj_get(rows[r], c)) { sel = r; break; }
        if (sel == rows.size())
            continue;
        std::swap(rows[used], rows[sel]);
        const ConjBits& p = rows[used];
        for (size_t r = used + 1; r < rows.size(); r++)
            if (conj_get(rows[r], c)) conj_xor(rows[r], p);
        for (size_t b = 0; b < basis.size(); b++)
            if (conj_get(basis[b].row, c)) conj_xor(basis[b].row, p);
        ConjPivotRow pr;
        pr.pivot = c;
        pr.row = p;
        basis.push_back(pr);
        used++;
    }
    return basis;
}

static void conj_reduce(ConjBits& v, const std::vector<ConjPivotRow>& basis) {
    for (size_t b = 0; b < basis.size(); b++)
        if (conj_get(v, basis[b].pivot)) conj_xor(v, basis[b].row);
}

static void conj_descend(ConjBits& u, const std::vector<ConjBits>& H) {
    int w = conj_wt(u);
    ConjBits t(u.size());
    bool improved = true;
    while (improved) {
        improved = false;
        for (size_t r = 0; r < H.size(); r++) {
            for (size_t k = 0; k < u.size(); k++) t[k] = u[k] ^ H[r][k];
            int wt = conj_wt(t);
            if (wt < w) { u.swap(t); w = wt; improved = true; }
        }
    }
}

static uint64_t conj_splitmix(uint64_t& s) {
    uint64_t z = (s += 0x9E3779B97F4A7C15ULL);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

static bool conj_less(const ConjBits& a, const ConjBits& b) {
    int wa = conj_wt(a), wb = conj_wt(b);
    if (wa != wb) return wa < wb;
    return a < b;
}

struct ConjStats {
    int trials;
    int rows;
    int clauses;
    long literals;
    int min_wt;
    int max_wt;
    int lighter_rows;
    int verify_fail;
};

/* Adds implied clauses (-a_{a_first+j} v OR_{i in supp(u)} v_{off_v+i}) for
 * representatives u of G_j + rowspace(H). */
static void add_conjugate_coset_clauses(
    SimpSolver& S, const Matrix& G, const Matrix& H, Var off_v, Var a_first, ConjStats& st)
{
    st.trials = 0; st.rows = 0; st.clauses = 0; st.literals = 0;
    st.min_wt = INT_MAX; st.max_wt = 0; st.lighter_rows = 0; st.verify_fail = 0;
    if (G.rows == 0)
        return;
    const int n = G.cols;
    const size_t words = ((size_t)n + 63) / 64;

    std::vector<ConjBits> Hrows;
    for (int r = 0; r < H.rows; r++) {
        ConjBits h = conj_row(H, r, words);
        if (!conj_is_zero(h)) Hrows.push_back(h);
    }
    std::vector<int> order(n);
    for (int i = 0; i < n; i++) order[i] = i;
    const std::vector<ConjPivotRow> exact = conj_echelon(Hrows, order, Hrows.size());
    const size_t rank = exact.size();

    double est = (double)(rank + 1) * (double)(Hrows.size() + rank + 1) * (double)words
               + (double)G.rows * (double)Hrows.size() * (double)words * 8.0;
    int T = (int)(CONJ_TRIAL_BUDGET / est);
    if (T > CONJ_MAX_TRIALS) T = CONJ_MAX_TRIALS;
    if (T < CONJ_MIN_TRIALS) T = CONJ_MIN_TRIALS;
    st.trials = T;

    std::vector<ConjBits> Grows;
    std::vector< std::vector<ConjBits> > cands(G.rows);
    for (int j = 0; j < G.rows; j++) {
        Grows.push_back(conj_row(G, j, words));
        if (conj_is_zero(Grows[j])) continue;
        cands[j].push_back(Grows[j]);
        ConjBits u = Grows[j];
        conj_descend(u, Hrows);
        cands[j].push_back(u);
    }
    uint64_t seed = 0x6A09E667F3BCC909ULL ^ ((uint64_t)n << 32) ^ (uint64_t)(G.rows * 131 + H.rows);
    for (int t = 0; t < T && rank > 0; t++) {
        for (int i = n - 1; i > 0; i--) {
            int k = (int)(conj_splitmix(seed) % (uint64_t)(i + 1));
            int tmp = order[i]; order[i] = order[k]; order[k] = tmp;
        }
        const std::vector<ConjPivotRow> basis = conj_echelon(Hrows, order, rank);
        for (int j = 0; j < G.rows; j++) {
            if (conj_is_zero(Grows[j])) continue;
            ConjBits u = Grows[j];
            conj_reduce(u, basis);
            conj_descend(u, Hrows);
            cands[j].push_back(u);
        }
    }

    for (int j = 0; j < G.rows; j++) {
        const ConjBits& g = Grows[j];
        if (conj_is_zero(g)) continue; /* a_j already forced false */
        std::vector<ConjBits>& c = cands[j];
        std::sort(c.begin(), c.end(), conj_less);
        c.erase(std::unique(c.begin(), c.end()), c.end());
        std::vector<ConjBits> ok;
        for (size_t q = 0; q < c.size(); q++) {
            ConjBits d = c[q];
            conj_xor(d, g);
            conj_reduce(d, exact);
            if (conj_is_zero(d)) ok.push_back(c[q]);
            else st.verify_fail++;
        }
        if (ok.empty()) continue;
        st.rows++;
        const int wmin = conj_wt(ok[0]);
        if (wmin < conj_wt(g)) st.lighter_rows++;
        const Lit a_lit = mkLit(a_first + j);
        std::vector<char> take(ok.size(), 0);
        int ntake = 0;
        ConjBits used(words, 0);
        for (size_t q = 0; q < ok.size() && ntake < CONJ_MAX_PER_ROW; q++) {
            if (conj_wt(ok[q]) > 2 * wmin) break;
            if (!conj_disjoint(ok[q], used)) continue;
            for (size_t k = 0; k < words; k++) used[k] |= ok[q][k];
            if (ok[q] == g) continue;
            take[q] = 1; ntake++;
        }
        for (size_t q = 0; q < ok.size() && ntake < CONJ_MAX_PER_ROW; q++) {
            if (conj_wt(ok[q]) > 2 * wmin) break;
            if (take[q] || ok[q] == g) continue;
            take[q] = 1; ntake++;
        }
        for (size_t q = 0; q < ok.size(); q++) {
            if (!take[q]) continue;
            std::vector<Lit> cl;
            cl.push_back(~a_lit);
            for (int i = 0; i < n; i++)
                if (conj_get(ok[q], i)) cl.push_back(mkLit(off_v + i));
            add_hard_clause(S, cl);
            const int w = (int)cl.size() - 1;
            st.clauses++;
            st.literals += (long)cl.size();
            if (w < st.min_wt) st.min_wt = w;
            if (w > st.max_wt) st.max_wt = w;
        }
    }
}

static bool build_stabilizer_instance(
    SimpSolver& S,
    std::vector<Var>& aux,
    StabilizerInstance& meta,
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    int verb, int card_mode, int bounds_pipe_w, bool conj_clauses = false)
{
    meta.n = Hx.cols;
    if (Hz.cols != meta.n || Gx.cols != meta.n || Gz.cols != meta.n) die("matrix column mismatch");
    const int k_log = Gx.rows + Gz.rows;
    if (k_log == 0)
        return false;

    aux.clear();
    S.setBoundsPipe(bounds_pipe_w);
    S.cardinalityEncMode = card_mode;
    S.parsing = true;
    S.verbosity = verb;
    S.instanceType = 1;
    S.hardWeight = (unsigned)(2 * meta.n + k_log + 64);
    S.UB = S.hardWeight;
    S.initUB = INT32_MAX;
    S.nbOriVars = 2 * meta.n;

    const Var off_x = 0;
    const Var off_z = meta.n;
    const Var off_w = 2 * meta.n;
    const Var off_a = 3 * meta.n;
    meta.base_vars = 3 * meta.n + k_log;
    while (S.nVars() < meta.base_vars) S.newVar();

    for (int r = 0; r < Hx.rows; r++) {
        std::vector<Lit> lits;
        for (int i = 0; i < meta.n; i++)
            if (getm(Hx, r, i)) lits.push_back(mkLit(off_z + i));
        add_xor_equals(S, lits, false, aux);
    }
    for (int r = 0; r < Hz.rows; r++) {
        std::vector<Lit> lits;
        for (int i = 0; i < meta.n; i++)
            if (getm(Hz, r, i)) lits.push_back(mkLit(off_x + i));
        add_xor_equals(S, lits, false, aux);
    }
    {
        std::vector<Lit> nz;
        for (int i = 0; i < meta.n; i++) {
            nz.push_back(mkLit(off_x + i));
            nz.push_back(mkLit(off_z + i));
        }
        add_hard_clause(S, nz);
    }
    int aj = 0;
    for (int j = 0; j < Gx.rows; j++, aj++) {
        std::vector<Lit> lits;
        for (int i = 0; i < meta.n; i++)
            if (getm(Gx, j, i)) lits.push_back(mkLit(off_x + i));
        Lit a_lit = mkLit(off_a + aj);
        if (lits.empty()) {
            std::vector<Lit> c;
            c.push_back(~a_lit);
            add_hard_clause(S, c);
        } else {
            lits.push_back(a_lit);
            add_xor_equals(S, lits, false, aux);
        }
    }
    for (int j = 0; j < Gz.rows; j++, aj++) {
        std::vector<Lit> lits;
        for (int i = 0; i < meta.n; i++)
            if (getm(Gz, j, i)) lits.push_back(mkLit(off_z + i));
        Lit a_lit = mkLit(off_a + aj);
        if (lits.empty()) {
            std::vector<Lit> c;
            c.push_back(~a_lit);
            add_hard_clause(S, c);
        } else {
            lits.push_back(a_lit);
            add_xor_equals(S, lits, false, aux);
        }
    }
    {
        std::vector<Lit> ors;
        for (int j = 0; j < k_log; j++) ors.push_back(mkLit(off_a + j));
        add_hard_clause(S, ors);
    }
    if (conj_clauses) {
        ConjStats sx, sz;
        add_conjugate_coset_clauses(S, Gx, Hz, off_x, off_a, sx);
        add_conjugate_coset_clauses(S, Gz, Hx, off_z, off_a + Gx.rows, sz);
        if (verb > 0) {
            const ConjStats* st[2] = {&sx, &sz};
            const char* side[2] = {"X(Gx+rs(Hz))", "Z(Gz+rs(Hx))"};
            for (int s = 0; s < 2; s++)
                printf("c conj-clauses %s: trials %d, rows %d, lighter-than-row %d, clauses %d, "
                       "literals %ld, rep weight %d..%d, verify failures %d\n",
                       side[s], st[s]->trials, st[s]->rows, st[s]->lighter_rows, st[s]->clauses,
                       st[s]->literals, st[s]->clauses ? st[s]->min_wt : 0, st[s]->max_wt,
                       st[s]->verify_fail);
        }
    }
    for (int i = 0; i < meta.n; i++) {
        Lit xi = mkLit(off_x + i);
        Lit zi = mkLit(off_z + i);
        Lit wi = mkLit(off_w + i);
        std::vector<Lit> c1, c2, c3;
        c1.push_back(~wi); c1.push_back(xi);  c1.push_back(zi);  add_hard_clause(S, c1);
        c2.push_back(~xi); c2.push_back(wi); add_hard_clause(S, c2);
        c3.push_back(~zi); c3.push_back(wi); add_hard_clause(S, c3);
        std::vector<Lit> sc;
        sc.push_back(~wi);
        add_soft_clause(S, sc, 1);
    }

    S.parsing = false;
    S.setFrozenVars();
    S.eliminate(true);
    if (!S.okay()) die("hard constraints UNSAT");
    return true;
}

static int min_distance_stabilizer_maxsat(
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    int cpu_lim, int verb, int bounds_pipe_w, int card_mode,
    const char* dump_wcnf_path)
{
    (void)cpu_lim;
    SimpSolver S;
    std::vector<Var> aux;
    StabilizerInstance meta;
    if (!build_stabilizer_instance(S, aux, meta, Hx, Hz, Gx, Gz, verb, card_mode, bounds_pipe_w,
                                   g_conj_clauses))
        return INT_MAX;

    if (dump_wcnf_path && dump_wcnf_path[0])
        S.toWcnf(dump_wcnf_path);

    /* Wall-clock timeout is enforced by the parent (fork + SIGKILL).
     * Do not set RLIMIT_CPU here: SIGXCPU can stop the child early and
     * surface as UNKNOWN instead of a parent TIMEOUT with bounds. */

    vec<Lit> dummy;
    lbool ret = S.solveLimited(dummy);

    int weight = -1;
    uint64_t opt = S.getLastOptimalCost();
    if (opt != UINT64_MAX && opt <= (uint64_t)meta.n)
        weight = (int)opt;
    if (weight < 0 && (ret == l_False || ret == l_True)) {
        weight = 0;
        const Var off_x = 0;
        const Var off_z = meta.n;
        const Var off_w = 2 * meta.n;
        for (int i = 0; i < meta.n; i++) {
            if (S.value(off_w + i) == l_True)
                weight++;
            else if (S.value(off_x + i) == l_True || S.value(off_z + i) == l_True)
                weight++;
        }
        if (weight == 0) weight = -1;
    }

    if (verb > 0)
        printf("c MaxSAT: %s, Pauli weight %d (reported cost %llu), vars %d (base %d + aux %zu)\n",
               ret == l_True ? "SAT" : ret == l_False ? "OPTIMAL" : "UNKNOWN",
               weight, (unsigned long long)opt, S.nVars(), meta.base_vars, aux.size());

    bool optimal = (ret == l_False) || (weight >= 0 && opt != UINT64_MAX);
    pipe_write_result(bounds_pipe_w, weight, optimal && weight >= 0);
    return weight;
}

static int parse_roundingsat_cost(const std::string& out)
{
    bool optimum = false;
    int cost = -1;
    for (size_t i = 0; i < out.size();) {
        size_t eol = out.find('\n', i);
        if (eol == std::string::npos)
            eol = out.size();
        std::string line = out.substr(i, eol - i);
        i = eol + 1;
        if (line.find("OPTIMUM FOUND") != std::string::npos)
            optimum = true;
        if (line.size() >= 2 && line[0] == 'o' && line[1] == ' ') {
            char* end = NULL;
            long v = strtol(line.c_str() + 2, &end, 10);
            if (end != line.c_str() + 2)
                cost = (int)v;
        }
    }
    return optimum ? cost : -1;
}

static int min_distance_stabilizer_roundingsat(
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    int verb, int bounds_pipe_w, const char* roundingsat_bin, const char* dump_wcnf_path)
{
    StabilizerInstance meta;
    SimpSolver S;
    std::vector<Var> aux;
    if (!build_stabilizer_instance(S, aux, meta, Hx, Hz, Gx, Gz, 0, 0, bounds_pipe_w))
        return INT_MAX;

    char tmpl[] = "/tmp/distqldpc_XXXXXX.wcnf";
    bool tmp_wcnf = !(dump_wcnf_path && dump_wcnf_path[0]);
    const char* wcnf_path = dump_wcnf_path;
    if (tmp_wcnf) {
        int fd = mkstemp(tmpl);
        if (fd < 0) die("mkstemp() failed");
        close(fd);
        wcnf_path = tmpl;
    }
    S.toWcnf(wcnf_path);

    std::string cmd = std::string(roundingsat_bin) + " " + wcnf_path + " 2>&1";
    FILE* fp = popen(cmd.c_str(), "r");
    if (!fp) {
        if (tmp_wcnf)
            unlink(tmpl);
        die("failed to run RoundingSat");
    }
    std::string out;
    char buf[4096];
    while (fgets(buf, sizeof(buf), fp) != NULL)
        out += buf;
    int pclose_rc = pclose(fp);
    if (tmp_wcnf)
        unlink(tmpl);

    int weight = parse_roundingsat_cost(out);
    if (verb > 0) {
        printf("c RoundingSat: exit=%d, Pauli weight %d, vars %d (base %d + aux %zu)\n",
               pclose_rc, weight, S.nVars(), meta.base_vars, aux.size());
        if (weight < 0) {
            printf("c RoundingSat output tail:\n");
            size_t start = out.size() > 1200 ? out.size() - 1200 : 0;
            fputs(out.c_str() + start, stdout);
        }
    }

    bool optimal = weight >= 0;
    pipe_write_result(bounds_pipe_w, weight, optimal);
    return weight;
}

struct BoundsBook {
    bool has_lb;
    bool has_ub;
    uint64_t lb;
    uint64_t ub;
    int distance;
    bool optimal;
    bool finished;

    BoundsBook()
        : has_lb(false), has_ub(false), lb(0), ub(0),
          distance(-1), optimal(false), finished(false) {}
};

struct ProgressState {
    bool show;
    bool bounds_printed;
    bool has_lb;
    bool has_ub;
    uint64_t last_lb;
    uint64_t last_ub;

    ProgressState(bool s)
        : show(s), bounds_printed(false), has_lb(false), has_ub(false),
          last_lb(0), last_ub(0) {}
};

static void apply_pipe_line(BoundsBook& b, const char* line, ProgressState* prog) {
    unsigned long long v;
    int d;
    if (sscanf(line, "TRY %llu", &v) == 1) {
        if (prog && prog->show) {
            printf("c trying d: %llu\n", v);
            fflush(stdout);
        }
    } else if (sscanf(line, "LB %llu", &v) == 1) {
        b.has_lb = true;
        b.lb = (uint64_t)v;
        if (prog) {
            if (prog->show && (!prog->has_lb || prog->last_lb != b.lb)) {
                printf("c d_lb: %llu\n", (unsigned long long)b.lb);
                fflush(stdout);
                prog->bounds_printed = true;
            }
            prog->has_lb = true;
            prog->last_lb = b.lb;
        }
    } else if (sscanf(line, "UB %llu", &v) == 1) {
        b.has_ub = true;
        b.ub = (uint64_t)v;
        if (prog) {
            if (prog->show && (!prog->has_ub || prog->last_ub != b.ub)) {
                printf("c d_ub: %llu\n", (unsigned long long)b.ub);
                fflush(stdout);
                prog->bounds_printed = true;
            }
            prog->has_ub = true;
            prog->last_ub = b.ub;
        }
    } else if (sscanf(line, "RESULT %d OPTIMAL", &d) == 1 && d >= 0) {
        b.distance = d;
        b.optimal = true;
        b.finished = true;
        b.has_lb = true;
        b.has_ub = true;
        b.lb = (uint64_t)d;
        b.ub = (uint64_t)d;
    } else if (strncmp(line, "RESULT -1", 9) == 0) {
        b.distance = -1;
        b.optimal = false;
        b.finished = true;
    }
}

static void drain_bounds_pipe(int pipe_r, BoundsBook& b, std::string& carry, ProgressState* prog) {
    char chunk[512];
    for (;;) {
        ssize_t n = read(pipe_r, chunk, sizeof(chunk));
        if (n < 0) {
            if (errno == EINTR)
                continue;
            break;
        }
        if (n == 0)
            break;
        carry.append(chunk, chunk + n);
        size_t pos;
        while ((pos = carry.find('\n')) != std::string::npos) {
            std::string line = carry.substr(0, pos);
            carry.erase(0, pos + 1);
            apply_pipe_line(b, line.c_str(), prog);
        }
    }
}

static double wall_seconds() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec * 1e-6;
}

static void print_bounds(const BoundsBook& b) {
    if (b.has_lb)
        printf("c d_lb: %llu\n", (unsigned long long)b.lb);
    else
        printf("c d_lb: -\n");
    if (b.has_ub)
        printf("c d_ub: %llu\n", (unsigned long long)b.ub);
    else
        printf("c d_ub: -\n");
}

static int solve_in_child_fork(
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    int cpu_lim, int verb, int card_mode, SolverBackend backend,
    const char* roundingsat_bin, const char* dump_wcnf_path,
    BoundsBook& out, bool& timed_out, ProgressState& prog)
{
    int pipefd[2];
    if (pipe(pipefd) != 0)
        die("pipe() failed");

    pid_t pid = fork();
    if (pid < 0)
        die("fork() failed");

    if (pid == 0) {
        close(pipefd[0]);
        if (verb == 0 && backend == SOLVER_MAXCDCL) {
            int devnull = open("/dev/null", O_WRONLY);
            if (devnull >= 0) {
                dup2(devnull, STDOUT_FILENO);
                close(devnull);
            }
        }
        int d;
        if (backend == SOLVER_ROUNDINGSAT) {
            d = min_distance_stabilizer_roundingsat(
                Hx, Hz, Gx, Gz, verb, pipefd[1], roundingsat_bin, dump_wcnf_path);
        } else {
            d = min_distance_stabilizer_maxsat(
                Hx, Hz, Gx, Gz, cpu_lim, verb, pipefd[1], card_mode, dump_wcnf_path);
        }
        if (d < 0)
            pipe_write_result(pipefd[1], -1, false);
        close(pipefd[1]);
        fflush(stdout);
        fflush(stderr);
        _exit(d >= 0 ? 0 : 1);
    }

    close(pipefd[1]);
    int flags = fcntl(pipefd[0], F_GETFL, 0);
    if (flags >= 0)
        fcntl(pipefd[0], F_SETFL, flags | O_NONBLOCK);

    BoundsBook book;
    std::string carry;
    prog = ProgressState(verb == 0);
    timed_out = false;
    double deadline = (cpu_lim != INT32_MAX) ? wall_seconds() + (double)cpu_lim : -1.0;

    for (;;) {
        drain_bounds_pipe(pipefd[0], book, carry, &prog);

        int status = 0;
        pid_t w = waitpid(pid, &status, WNOHANG);
        if (w == pid) {
            drain_bounds_pipe(pipefd[0], book, carry, &prog);
            if (!carry.empty())
                apply_pipe_line(book, carry.c_str(), &prog);
            break;
        }
        if (w < 0 && errno != ECHILD)
            die("waitpid() failed");

        if (deadline >= 0.0 && wall_seconds() >= deadline) {
            kill(pid, SIGKILL);
            (void)waitpid(pid, &status, 0);
            timed_out = true;
            drain_bounds_pipe(pipefd[0], book, carry, &prog);
            if (!carry.empty())
                apply_pipe_line(book, carry.c_str(), &prog);
            break;
        }
        usleep(10000);
    }

    close(pipefd[0]);
    out = book;
    return out.distance;
}

static bool dump_stabilizer_instance(
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    const char* dump_wcnf_path, const char* dump_opb_path, bool native_parity_opb)
{
    if ((!dump_wcnf_path || !dump_wcnf_path[0]) && (!dump_opb_path || !dump_opb_path[0]))
        die("dump requires -dump-wcnf=PATH and/or -dump-opb=PATH");

    if (dump_wcnf_path && dump_wcnf_path[0]) {
        SimpSolver S;
        std::vector<Var> aux;
        StabilizerInstance meta;
        if (!build_stabilizer_instance(S, aux, meta, Hx, Hz, Gx, Gz, 0, 0, -1))
            return false;
        S.toWcnf(dump_wcnf_path);
    }

    if (dump_opb_path && dump_opb_path[0]) {
        if (native_parity_opb) {
            FILE* f = fopen(dump_opb_path, "w");
            if (!f) {
                fprintf(stderr, "error: cannot open %s\n", dump_opb_path);
                return false;
            }
            write_opb_native_parity(f, Hx, Hz, Gx, Gz);
            fclose(f);
        } else {
            SimpSolver S;
            std::vector<Var> aux;
            StabilizerInstance meta;
            if (!build_stabilizer_instance(S, aux, meta, Hx, Hz, Gx, Gz, 0, 0, -1))
                return false;
            S.toOpb(dump_opb_path);
        }
    }
    return true;
}

static std::string resolve_prefix(const char* prefix) {
    std::string p(prefix);
    if (p.find('/') == std::string::npos)
        p = std::string("data/matrices/") + p;
    return p;
}

int main(int argc, char** argv) {
    const char* prefix = NULL;
    int cpu_lim = INT32_MAX;
    int verb = 0;
    int card_mode = 1;  /* CARD_ENC_BOTH */
    SolverBackend backend = SOLVER_MAXCDCL;
    const char* roundingsat_bin = DEFAULT_ROUNDINGSAT_BIN;
    const char* dump_wcnf_path = NULL;
    const char* dump_opb_path = NULL;
    bool dump_only = false;
    bool native_parity_opb = false;

    for (int i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "-cpu-lim=", 9))
            cpu_lim = atoi(argv[i] + 9);
        else if (!strncmp(argv[i], "-dump-wcnf=", 11))
            dump_wcnf_path = argv[i] + 11;
        else if (!strncmp(argv[i], "-dump-opb=", 10))
            dump_opb_path = argv[i] + 10;
        else if (!strcmp(argv[i], "-dump-only"))
            dump_only = true;
        else if (!strcmp(argv[i], "-native-parity-opb"))
            native_parity_opb = true;
        else if (!strncmp(argv[i], "-roundingsat=", 13)) {
            backend = SOLVER_ROUNDINGSAT;
            roundingsat_bin = argv[i] + 13;
        } else if (!strcmp(argv[i], "-roundingsat"))
            backend = SOLVER_ROUNDINGSAT;
        else if (!strcmp(argv[i], "-v") || !strcmp(argv[i], "-debug"))
            verb = 1;
        else if (!strcmp(argv[i], "-q"))
            verb = 0;
        else if (!strcmp(argv[i], "-no-card"))
            card_mode = 0;
        else if (!strcmp(argv[i], "-card-sinz"))
            card_mode = 2;
        else if (!strcmp(argv[i], "-card-mto"))
            card_mode = 3;
        else if (!strcmp(argv[i], "-card-both"))
            card_mode = 1;
        else if (!strcmp(argv[i], "-card-both-force"))
            card_mode = 4;
        else if (!strcmp(argv[i], "-no-conj"))
            g_conj_clauses = false;
        else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
            printf("Usage: %s [options] <code>\n", argv[0]);
            printf("  <code>  e.g. LP_34_20_2  (loads data/matrices/<code>_{{Hx,Hz,Gx,Gz}}.txt)\n");
            printf("  Distance: min Pauli weight in S^perp \\\\ S (symplectic MaxSAT).\n");
            printf("  Options: -cpu-lim=N  -v|-debug  -q  -dump-wcnf=PATH  -dump-opb=PATH  -dump-only\n");
            printf("           -native-parity-opb  GF(2) parity as PB equalities (OPB dump only)\n");
            printf("  Solver: default MaxCDCL; -roundingsat[=BIN] uses external RoundingSat on WCNF\n");
            printf("  Cardinality: default Sinz+MTO (Sinz if n<=100); -no-card | -card-sinz | -card-mto\n");
            printf("               -card-both-force  always Sinz+MTO regardless of n\n");
            printf("  -no-conj  omit implied conjugate-coset clauses (MaxCDCL solve path)\n");
            printf("  Output (default): live c trying d / c d_lb / c d_ub, then c d / o d\n");
            printf("  -v / -debug: solver search log and matrix paths\n");
            printf("  Solver runs in forked child; bounds sync via pipe; hard kill on timeout.\n");
            return 0;
        } else if (!prefix)
            prefix = argv[i];
        else
            die("unexpected argument");
    }
    if (!prefix) die("need code name (e.g. LP_34_20_2)");
    if (card_mode != 0 && card_mode != 1 && card_mode != 2 && card_mode != 3 && card_mode != 4)
        die("invalid cardinality mode");

    std::string p = resolve_prefix(prefix);
    std::string hx_path = p + "_Hx.txt";
    std::string hz_path = p + "_Hz.txt";
    std::string gx_path = p + "_Gx.txt";
    std::string gz_path = p + "_Gz.txt";

    Matrix Hx = load_matrix(hx_path.c_str());
    Matrix Hz = load_matrix(hz_path.c_str());
    Matrix Gx = load_matrix(gx_path.c_str());
    Matrix Gz = load_matrix(gz_path.c_str());

    if (dump_only) {
        if (!dump_stabilizer_instance(
                Hx, Hz, Gx, Gz, dump_wcnf_path, dump_opb_path, native_parity_opb))
            die("dump failed");
        if (verb > 0) {
            if (dump_opb_path)
                printf("c wrote OPB %s%s\n", dump_opb_path,
                       native_parity_opb ? " (native parity)" : "");
            if (dump_wcnf_path)
                printf("c wrote WCNF %s\n", dump_wcnf_path);
        }
        return 0;
    }

    if (verb > 0) {
        printf("c DistQLDPC — QLDPC/CSS minimum distance (symplectic MaxSAT)\n");
        if (backend == SOLVER_ROUNDINGSAT)
            printf("c solver: RoundingSat (%s)\n", roundingsat_bin);
        else
            printf("c solver: MaxCDCL, cardinality encoding: %s\n", cardinality_mode_label(card_mode));
        if (dump_wcnf_path)
            printf("c dump WCNF: %s\n", dump_wcnf_path);
        printf("c Hx: %s\n", hx_path.c_str());
        printf("c Hz: %s\n", hz_path.c_str());
        printf("c Gx: %s\n", gx_path.c_str());
        printf("c Gz: %s\n", gz_path.c_str());
        printf("c Hx: %d x %d, Hz: %d x %d, Gx: %d x %d, Gz: %d x %d, logicals: %d\n",
               Hx.rows, Hx.cols, Hz.rows, Hz.cols, Gx.rows, Gx.cols, Gz.rows, Gz.cols,
               Gx.rows + Gz.rows);
    }

    BoundsBook book;
    bool timed_out = false;
    ProgressState prog(false);
    int d = solve_in_child_fork(
        Hx, Hz, Gx, Gz, cpu_lim, verb, card_mode, backend,
        roundingsat_bin, dump_wcnf_path, book, timed_out, prog);

    if (verb > 0 || !prog.bounds_printed || timed_out || !book.optimal)
        print_bounds(book);

    if (d >= 0 && book.optimal && !timed_out) {
        printf("c d  : %d\n", d);
        printf("o %d\n", d);
        return 0;
    }
    if (timed_out)
        printf("c status: TIMEOUT (child killed after -cpu-lim)\n");
    else
        printf("c status: UNKNOWN\n");
    printf("c d  : UNKNOWN\n");
    printf("s UNKNOWN\n");
    return 1;
}
