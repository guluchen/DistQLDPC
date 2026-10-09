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
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdint.h>
#include <vector>
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

/*
 * GH-75: code-automorphism orbit symmetry breaking (MaxCDCL solve path only).
 *
 * Encoded feasible set F = {(x,z): Hz x = 0, Hx z = 0, Gx x != 0 or Gz z != 0}.
 * A qubit permutation pi (support moved by pi) is accepted as
 *   plain   if pi(rs Hx) = rs Hx, pi(rs Hz) = rs Hz, pi(rs[Hz;Gx]) = rs[Hz;Gx],
 *           pi(rs[Hx;Gz]) = rs[Hx;Gz]           -> (x,z) |-> (pi x, pi z) maps F onto F;
 *   XZ-dual if pi(rs Hx) = rs Hz, pi(rs Hz) = rs Hx, pi(rs[Hz;Gx]) = rs[Hx;Gz],
 *           pi(rs[Hx;Gz]) = rs[Hz;Gx]           -> (x,z) |-> (pi z, pi x) maps F onto F.
 * Both preserve the Pauli weight |supp x U supp z|. Equalities are verified over GF(2)
 * (every permuted row reduces to zero against an RREF basis of the target space, and the
 * ranks agree). For orbits O_1..O_k of the generated group on qubits, every optimum can be
 * moved so that its support contains r_j = min O_j for some j, so the hard clause
 * (w_{r_1} v ... v w_{r_k}) preserves the optimum and the soundness of all bounds.
 * Candidate permutations are generic index maps (block/strided cyclic shifts, 2D
 * translations, block swaps with group inverse); none is assumed, all are verified.
 * Domain-specific adaptation of static symmetry breaking (Crawford et al. KR'96;
 * Satsuma, Anders/Brenner/Rattan, SAT 2024, DOI 10.4230/LIPIcs.SAT.2024.4).
 */
struct Gf2Basis {
    int words;
    std::vector<std::vector<uint64_t> > rows;
    std::vector<int> piv;

    explicit Gf2Basis(int n) : words((n + 63) / 64) {}

    /* Reduce v against the RREF basis; true iff v ends up zero (v in span). */
    bool reduce(std::vector<uint64_t>& v) const {
        for (size_t k = 0; k < rows.size(); k++) {
            const int p = piv[k];
            if ((v[p >> 6] >> (p & 63)) & 1) {
                const std::vector<uint64_t>& r = rows[k];
                for (int w = 0; w < words; w++) v[w] ^= r[w];
            }
        }
        for (int w = 0; w < words; w++)
            if (v[w]) return false;
        return true;
    }

    void insert(std::vector<uint64_t> v) {
        if (reduce(v)) return;
        int p = -1;
        for (int w = 0; w < words && p < 0; w++)
            if (v[w]) p = w * 64 + __builtin_ctzll(v[w]);
        for (size_t k = 0; k < rows.size(); k++)
            if ((rows[k][p >> 6] >> (p & 63)) & 1)
                for (int w = 0; w < words; w++) rows[k][w] ^= v[w];
        rows.push_back(v);
        piv.push_back(p);
    }

    int rank() const { return (int)rows.size(); }
};

/* Row supports of a (stacked) 0/1 matrix. */
typedef std::vector<std::vector<int> > RowSupports;

static void append_supports(RowSupports& out, const Matrix& M) {
    for (int r = 0; r < M.rows; r++) {
        std::vector<int> s;
        for (int c = 0; c < M.cols; c++)
            if (getm(M, r, c)) s.push_back(c);
        if (!s.empty()) out.push_back(s);
    }
}

static Gf2Basis basis_of(const RowSupports& rs, int n) {
    Gf2Basis B(n);
    std::vector<uint64_t> v((size_t)B.words);
    for (size_t r = 0; r < rs.size(); r++) {
        std::fill(v.begin(), v.end(), 0);
        for (size_t t = 0; t < rs[r].size(); t++) v[rs[r][t] >> 6] |= 1ULL << (rs[r][t] & 63);
        B.insert(v);
    }
    return B;
}

/* pi(rows of src) subset of span(dst). */
static bool permuted_rows_in(const RowSupports& src, const std::vector<int>& pi, const Gf2Basis& dst) {
    std::vector<uint64_t> v((size_t)dst.words);
    for (size_t r = 0; r < src.size(); r++) {
        std::fill(v.begin(), v.end(), 0);
        for (size_t t = 0; t < src[r].size(); t++) {
            const int c = pi[src[r][t]];
            v[c >> 6] |= 1ULL << (c & 63);
        }
        if (!dst.reduce(v)) return false;
    }
    return true;
}

struct SymCandidate {
    std::string desc;
    std::vector<int> perm;
};

struct SymBreakInfo {
    int n;
    std::vector<std::string> generators; /* "plain <desc>" / "dual <desc>" */
    std::vector<int> orbit_of;           /* orbit representative (min) per qubit */
    std::vector<int> reps;               /* sorted orbit minima */
    int candidates;
    double seconds;
};

static void add_candidate(std::vector<SymCandidate>& out, const std::string& desc, const std::vector<int>& perm) {
    bool ident = true;
    for (size_t i = 0; i < perm.size() && ident; i++)
        if (perm[i] != (int)i) ident = false;
    if (ident) return;
    for (size_t k = 0; k < out.size(); k++)
        if (out[k].perm == perm) return;
    SymCandidate c;
    c.desc = desc;
    c.perm = perm;
    out.push_back(c);
}

static std::vector<SymCandidate> symmetry_candidates(int n) {
    std::vector<SymCandidate> out;
    char buf[96];
    std::vector<int> p((size_t)n);
    for (int L = 2; L <= n; L++) {
        if (n % L) continue;
        const int B = n / L;
        /* contiguous blocks of size L, cyclic shift by 1 inside each block */
        for (int i = 0; i < n; i++) p[i] = (i / L) * L + ((i % L) + 1) % L;
        snprintf(buf, sizeof(buf), "blockshift L=%d", L);
        add_candidate(out, buf, p);
        /* B interleaved blocks (index = a*B + b), cyclic shift of a */
        for (int i = 0; i < n; i++) p[i] = (((i / B) + 1) % L) * B + (i % B);
        snprintf(buf, sizeof(buf), "stridedshift L=%d", L);
        add_candidate(out, buf, p);
        /* 2D translations inside contiguous blocks of size L = l*m, local index a*m+b */
        for (int l = 2; l < L; l++) {
            if (L % l) continue;
            const int m = L / l;
            if (m < 2) continue;
            for (int i = 0; i < n; i++) {
                const int base = (i / L) * L, loc = i % L, a = loc / m, b = loc % m;
                p[i] = base + ((a + 1) % l) * m + b;
            }
            snprintf(buf, sizeof(buf), "2dshift-a L=%d (%dx%d)", L, l, m);
            add_candidate(out, buf, p);
            for (int i = 0; i < n; i++) {
                const int base = (i / L) * L, loc = i % L, a = loc / m, b = loc % m;
                p[i] = base + a * m + (b + 1) % m;
            }
            snprintf(buf, sizeof(buf), "2dshift-b L=%d (%dx%d)", L, l, m);
            add_candidate(out, buf, p);
        }
    }
    if (n % 2 == 0) {
        const int h = n / 2;
        for (int i = 0; i < n; i++) p[i] = (i + h) % n;
        add_candidate(out, "halfswap", p);
        /* swap halves with group inverse g -> -g, cyclic Z_h */
        for (int i = 0; i < n; i++) {
            const int g = i % h, side = i / h;
            p[i] = (1 - side) * h + (h - g) % h;
        }
        add_candidate(out, "halfswap-inverse Z_h", p);
        /* swap halves with inverse in Z_l x Z_m, local index a*m+b */
        for (int l = 2; l < h; l++) {
            if (h % l) continue;
            const int m = h / l;
            if (m < 2) continue;
            for (int i = 0; i < n; i++) {
                const int g = i % h, side = i / h, a = g / m, b = g % m;
                p[i] = (1 - side) * h + ((l - a) % l) * m + (m - b) % m;
            }
            snprintf(buf, sizeof(buf), "halfswap-inverse Z_%d x Z_%d", l, m);
            add_candidate(out, buf, p);
        }
    }
    return out;
}

static int uf_find(std::vector<int>& par, int a) {
    while (par[a] != a) {
        par[a] = par[par[a]];
        a = par[a];
    }
    return a;
}

static SymBreakInfo find_code_symmetry(
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz)
{
    const double t0 = cpuTime();
    SymBreakInfo info;
    const int n = Hx.cols;
    info.n = n;
    RowSupports sHx, sHz, sHzGx, sHxGz;
    append_supports(sHx, Hx);
    append_supports(sHz, Hz);
    append_supports(sHzGx, Hz);
    append_supports(sHzGx, Gx);
    append_supports(sHxGz, Hx);
    append_supports(sHxGz, Gz);
    const Gf2Basis bHx = basis_of(sHx, n), bHz = basis_of(sHz, n);
    const Gf2Basis bHzGx = basis_of(sHzGx, n), bHxGz = basis_of(sHxGz, n);
    const bool dual_ranks = bHx.rank() == bHz.rank() && bHzGx.rank() == bHxGz.rank();

    std::vector<int> par((size_t)n);
    for (int i = 0; i < n; i++) par[i] = i;

    const std::vector<SymCandidate> cands = symmetry_candidates(n);
    info.candidates = (int)cands.size();
    for (size_t k = 0; k < cands.size(); k++) {
        const std::vector<int>& pi = cands[k].perm;
        bool ok_plain =
            permuted_rows_in(sHx, pi, bHx) && permuted_rows_in(sHz, pi, bHz) &&
            permuted_rows_in(sHzGx, pi, bHzGx) && permuted_rows_in(sHxGz, pi, bHxGz);
        bool ok_dual = dual_ranks &&
            permuted_rows_in(sHx, pi, bHz) && permuted_rows_in(sHz, pi, bHx) &&
            permuted_rows_in(sHzGx, pi, bHxGz) && permuted_rows_in(sHxGz, pi, bHzGx);
        if (ok_plain) info.generators.push_back("plain " + cands[k].desc);
        if (ok_dual) info.generators.push_back("dual " + cands[k].desc);
        if (ok_plain || ok_dual)
            for (int i = 0; i < n; i++) {
                const int a = uf_find(par, i), b = uf_find(par, pi[i]);
                if (a != b) par[a < b ? b : a] = a < b ? a : b;
            }
    }
    info.orbit_of.resize((size_t)n);
    for (int i = 0; i < n; i++) {
        info.orbit_of[i] = uf_find(par, i);
        if (info.orbit_of[i] == i) info.reps.push_back(i);
    }
    info.seconds = cpuTime() - t0;
    return info;
}

static void print_symmetry_info(const SymBreakInfo& info, const char* prefix) {
    const int k = (int)info.reps.size();
    printf("%s n=%d candidates=%d verified_generators=%zu orbits=%d detect_cpu=%.3fs clause=%s\n",
           prefix, info.n, info.candidates, info.generators.size(), k, info.seconds,
           k == info.n ? "none" : (k == 1 ? "unit" : "orbit-chain"));
    for (size_t g = 0; g < info.generators.size(); g++)
        printf("%s generator: %s\n", prefix, info.generators[g].c_str());
    if (k < info.n) {
        std::vector<int> size((size_t)info.n, 0);
        for (int i = 0; i < info.n; i++) size[info.orbit_of[i]]++;
        printf("%s orbit reps (size):", prefix);
        for (int j = 0; j < k && j < 64; j++) printf(" %d(%d)", info.reps[j], size[info.reps[j]]);
        printf(k > 64 ? " ...\n" : "\n");
    }
    fflush(stdout);
}

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

static bool build_stabilizer_instance(
    SimpSolver& S,
    std::vector<Var>& aux,
    StabilizerInstance& meta,
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    int verb, int card_mode, int bounds_pipe_w,
    const std::vector<int>* symbreak_orbit = NULL)
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
    /* GH-75: optimum-preserving orbit symmetry breaking (see find_code_symmetry).
     * Orbits O_1..O_k ordered by their minima r_j. For an optimum P let j* be the first
     * orbit met by supp(P); a group element moving a qubit of supp(P) n O_j* to r_j*
     * keeps every orbit setwise, so we may require: r_j* in supp and supp misses
     * O_1..O_{j*-1}. Aux p_j <-> (supp meets O_1 u ... u O_j), j = 1..k-1.
     *   (w_{r_1} v ... v w_{r_k});  for q in O_j \ {r_j}: (-w_q v w_{r_j} v p_{j-1})
     * (p_0 = false). Transitive group: unit clause w_{r_1}. */
    if (symbreak_orbit && (int)symbreak_orbit->size() == meta.n) {
        const std::vector<int>& orb = *symbreak_orbit;
        std::vector<int> reps, idx((size_t)meta.n, -1);
        for (int i = 0; i < meta.n; i++)
            if (orb[i] == i) {
                idx[i] = (int)reps.size();
                reps.push_back(i);
            }
        const int k = (int)reps.size();
        if (k < meta.n) {
            std::vector<Lit> sb;
            for (int j = 0; j < k; j++) sb.push_back(mkLit(off_w + reps[j]));
            add_hard_clause(S, sb);
        }
        if (k > 1 && k < meta.n) {
            std::vector<std::vector<int> > members((size_t)k);
            for (int i = 0; i < meta.n; i++) members[idx[orb[i]]].push_back(i);
            std::vector<Lit> pref((size_t)k);
            for (int j = 0; j + 1 < k; j++) {
                Var v = ensure_var(S, S.nVars());
                aux.push_back(v);
                pref[j] = mkLit(v);
            }
            for (int j = 0; j + 1 < k; j++) {
                /* p_j -> p_{j-1} v OR_{q in O_j} w_q ;  p_{j-1} -> p_j ;  w_q -> p_j */
                std::vector<Lit> up;
                up.push_back(~pref[j]);
                if (j > 0) up.push_back(pref[j - 1]);
                for (size_t t = 0; t < members[j].size(); t++)
                    up.push_back(mkLit(off_w + members[j][t]));
                add_hard_clause(S, up);
                if (j > 0) {
                    std::vector<Lit> c;
                    c.push_back(~pref[j - 1]); c.push_back(pref[j]);
                    add_hard_clause(S, c);
                }
                for (size_t t = 0; t < members[j].size(); t++) {
                    std::vector<Lit> c;
                    c.push_back(~mkLit(off_w + members[j][t])); c.push_back(pref[j]);
                    add_hard_clause(S, c);
                }
            }
            for (int j = 0; j < k; j++)
                for (size_t t = 0; t < members[j].size(); t++) {
                    const int q = members[j][t];
                    if (q == reps[j]) continue;
                    std::vector<Lit> c;
                    c.push_back(~mkLit(off_w + q));
                    c.push_back(mkLit(off_w + reps[j]));
                    if (j > 0) c.push_back(pref[j - 1]);
                    add_hard_clause(S, c);
                }
        }
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
    const char* dump_wcnf_path, bool symbreak)
{
    (void)cpu_lim;
    SimpSolver S;
    std::vector<Var> aux;
    StabilizerInstance meta;
    std::vector<int> sb_orbit;
    if (symbreak && Gx.rows + Gz.rows > 0 && Hz.cols == Hx.cols && Gx.cols == Hx.cols &&
        Gz.cols == Hx.cols) {
        SymBreakInfo info = find_code_symmetry(Hx, Hz, Gx, Gz);
        if (verb > 0)
            print_symmetry_info(info, "c symbreak:");
        if ((int)info.reps.size() < info.n)
            sb_orbit = info.orbit_of;
    }
    if (!build_stabilizer_instance(S, aux, meta, Hx, Hz, Gx, Gz, verb, card_mode, bounds_pipe_w,
                                   sb_orbit.empty() ? NULL : &sb_orbit))
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
    const char* roundingsat_bin, const char* dump_wcnf_path, bool symbreak,
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
                Hx, Hz, Gx, Gz, cpu_lim, verb, pipefd[1], card_mode, dump_wcnf_path, symbreak);
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
    bool symbreak = true;          /* GH-75 orbit clause (MaxCDCL path only) */
    bool symbreak_report = false;

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
        else if (!strcmp(argv[i], "-no-symbreak"))
            symbreak = false;
        else if (!strcmp(argv[i], "-symbreak-report"))
            symbreak_report = true;
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
        else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
            printf("Usage: %s [options] <code>\n", argv[0]);
            printf("  <code>  e.g. LP_34_20_2  (loads data/matrices/<code>_{{Hx,Hz,Gx,Gz}}.txt)\n");
            printf("  Distance: min Pauli weight in S^perp \\\\ S (symplectic MaxSAT).\n");
            printf("  Options: -cpu-lim=N  -v|-debug  -q  -dump-wcnf=PATH  -dump-opb=PATH  -dump-only\n");
            printf("           -native-parity-opb  GF(2) parity as PB equalities (OPB dump only)\n");
            printf("  Solver: default MaxCDCL; -roundingsat[=BIN] uses external RoundingSat on WCNF\n");
            printf("  Symmetry: default adds one optimum-preserving clause from verified code\n");
            printf("            automorphisms (MaxCDCL only); -no-symbreak disables it;\n");
            printf("            -symbreak-report prints generators/orbits and exits\n");
            printf("  Cardinality: default Sinz+MTO (Sinz if n<=100); -no-card | -card-sinz | -card-mto\n");
            printf("               -card-both-force  always Sinz+MTO regardless of n\n");
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

    if (symbreak_report) {
        if (Hz.cols != Hx.cols || Gx.cols != Hx.cols || Gz.cols != Hx.cols)
            die("matrix column mismatch");
        printf("c symbreak report: %s\n", prefix);
        print_symmetry_info(find_code_symmetry(Hx, Hz, Gx, Gz), "c symbreak:");
        return 0;
    }

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
        roundingsat_bin, dump_wcnf_path, symbreak, book, timed_out, prog);

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
