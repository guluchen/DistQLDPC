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
    int verb, int card_mode, int bounds_pipe_w)
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
    if (!build_stabilizer_instance(S, aux, meta, Hx, Hz, Gx, Gz, verb, card_mode, bounds_pipe_w))
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

/* ---- GH-78: single-XOR decomposition of the CSS halves via verified code automorphisms
 * (PI-approved formulation change, 2026-10-09, recorded in GH-71/GH-75), inside a global bound
 * search over all parts (GH-73's interleaved driver generalised from 2 halves to N parts).
 *
 * CSS: d = min(dX, dZ). X half: dX = min{|x| : Hz x = 0, Gx x != 0}; Z half uses (Hx, Gz).
 * For a half (Hpar, Glog) let R = rowspace(Hpar), T = span(Glog), A = group generated by qubit
 * permutations sigma with sigma(R) = R (each generator verified over GF(2)). If rows g_1..g_r of
 * Glog satisfy T <= R + span{sigma(g_i) : sigma in A} (verified at encode time), then
 *   d_half = min_i d(g_i),  d(g) = min{|x| : Hpar x = 0, g.x = 1}.
 * (>=) an optimal x has t.x = 1 for some t in T, t = sum sigma(g_i) + h, h in R, h.x = 0, so
 *      g_i . sigma^{-1}(x) = 1 for some i, sigma; sigma^{-1}(x) is in ker Hpar and has weight |x|.
 * (<=) g_i is a Glog row, so g_i.x = 1 implies Glog x != 0: every subproblem point is nontrivial.
 * A subproblem is Hpar x = 0, XOR(g.x) = 1, soft -x_q: no a_j variables, no OR clause.
 * Halves without a small spanning set (r > rmax or r >= k) keep the OR formulation (GH-73).
 * Only globally valid bounds are forwarded: LB = min over parts of their proven LB, UB = best found.
 *
 * GF(2) basis and the generic candidate-permutation family below are reused from GH-75
 * (mac-symbreak-20261009, commit bbe5055) with attribution; the per-half verification condition,
 * the spanning-set selection and the decomposition are GH-78. Half instance, run_css_half and the
 * driver structure follow GH-73 (mac-cssinterleave-20261009, commit a1585b4). */
static bool add_clause_soft_fail(SimpSolver& S, const std::vector<Lit>& lits, unsigned w) {
    vec<Lit> ps;
    for (size_t i = 0; i < lits.size(); i++) ps.push(lits[i]);
    return S.addClause_(ps, w);
}

static bool xor_equals_soft_fail(SimpSolver& S, const std::vector<Lit>& inputs, bool value, std::vector<Var>& aux) {
    if (inputs.empty()) return !value;
    std::vector<Lit> c;
    Lit p = inputs.size() == 1 ? inputs[0] : parity(S, inputs, aux);
    c.push_back(value ? p : ~p);
    return add_clause_soft_fail(S, c, S.hardWeight);
}

/* GF(2) row-reduced basis (from GH-75 bbe5055). */
struct Gf2Basis {
    int words;
    std::vector<std::vector<uint64_t> > rows;
    std::vector<int> piv;
    explicit Gf2Basis(int n) : words((n + 63) / 64) {}
    bool reduce(std::vector<uint64_t>& v) const {   /* true iff v ends up zero (v in span) */
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
    bool insert(std::vector<uint64_t> v) {          /* true iff the rank increased */
        if (reduce(v)) return false;
        int p = -1;
        for (int w = 0; w < words && p < 0; w++)
            if (v[w]) p = w * 64 + __builtin_ctzll(v[w]);
        for (size_t k = 0; k < rows.size(); k++)
            if ((rows[k][p >> 6] >> (p & 63)) & 1)
                for (int w = 0; w < words; w++) rows[k][w] ^= v[w];
        rows.push_back(v);
        piv.push_back(p);
        return true;
    }
    int rank() const { return (int)rows.size(); }
};

static std::vector<uint64_t> row_bits(const Matrix& M, int r) {
    std::vector<uint64_t> v((size_t)((M.cols + 63) / 64), 0);
    for (int c = 0; c < M.cols; c++)
        if (getm(M, r, c)) v[c >> 6] |= 1ULL << (c & 63);
    return v;
}

static std::vector<uint64_t> permute_bits(const std::vector<uint64_t>& v, const std::vector<int>& pi) {
    std::vector<uint64_t> o(v.size(), 0);
    for (size_t w = 0; w < v.size(); w++) {
        uint64_t x = v[w];
        while (x) {
            const int c = pi[w * 64 + __builtin_ctzll(x)];
            o[c >> 6] |= 1ULL << (c & 63);
            x &= x - 1;
        }
    }
    return o;
}

struct SymCandidate {
    std::string desc;
    std::vector<int> perm;
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

/* Generic candidate qubit permutations (from GH-75 bbe5055); none is assumed, all are verified. */
static std::vector<SymCandidate> symmetry_candidates(int n) {
    std::vector<SymCandidate> out;
    char buf[96];
    std::vector<int> p((size_t)n);
    for (int L = 2; L <= n; L++) {
        if (n % L) continue;
        const int B = n / L;
        for (int i = 0; i < n; i++) p[i] = (i / L) * L + ((i % L) + 1) % L;
        snprintf(buf, sizeof(buf), "blockshift L=%d", L);
        add_candidate(out, buf, p);
        for (int i = 0; i < n; i++) p[i] = (((i / B) + 1) % L) * B + (i % B);
        snprintf(buf, sizeof(buf), "stridedshift L=%d", L);
        add_candidate(out, buf, p);
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
        for (int i = 0; i < n; i++) {
            const int g = i % h, side = i / h;
            p[i] = (1 - side) * h + (h - g) % h;
        }
        add_candidate(out, "halfswap-inverse Z_h", p);
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

static int g_xor_rmax = 4;          /* -xor-rmax=N (0 disables the decomposition) */
static bool g_xordecomp_report = false;

struct HalfPlan {
    const char* tag;
    int n, k, rank_h, candidates;
    std::vector<SymCandidate> gens;   /* verified: sigma(rowspace Hpar) = rowspace Hpar */
    std::vector<int> chosen;          /* Glog rows g_1..g_r (spanning set; may be partial if aborted) */
    bool spans;                       /* every Glog row lies in closure_A(R + span{g_i}) */
    bool decompose;                   /* use single-XOR subproblems for this half */
    const char* method;
    double seconds;
};

/* Add v and its images under the generators until the span is generator-invariant. */
static void closure_add(Gf2Basis& V, const std::vector<uint64_t>& v, const std::vector<SymCandidate>& gens) {
    std::vector<std::vector<uint64_t> > q(1, v);
    while (!q.empty()) {
        std::vector<uint64_t> u = q.back();
        q.pop_back();
        if (!V.insert(u)) continue;
        for (size_t s = 0; s < gens.size(); s++) q.push_back(permute_bits(u, gens[s].perm));
    }
}

static HalfPlan plan_half(const char* tag, const Matrix& Hpar, const Matrix& Glog, int rmax) {
    const double t0 = cpuTime();
    HalfPlan P;
    P.tag = tag; P.n = Hpar.cols; P.k = Glog.rows; P.spans = false; P.decompose = false;
    P.method = "none"; P.candidates = 0;
    const int n = Hpar.cols;
    Gf2Basis R(n);
    std::vector<std::vector<uint64_t> > hrows;
    for (int r = 0; r < Hpar.rows; r++) { hrows.push_back(row_bits(Hpar, r)); R.insert(hrows.back()); }
    P.rank_h = R.rank();
    if (rmax > 0 && P.k > 1) {
        std::vector<SymCandidate> cands = symmetry_candidates(n);
        P.candidates = (int)cands.size();
        for (size_t c = 0; c < cands.size(); c++) {
            bool ok = true;
            for (size_t r = 0; ok && r < hrows.size(); r++) {
                std::vector<uint64_t> v = permute_bits(hrows[r], cands[c].perm);
                ok = R.reduce(v);
            }
            if (ok) P.gens.push_back(cands[c]);
        }
        std::vector<std::vector<uint64_t> > grows;
        for (int j = 0; j < P.k; j++) grows.push_back(row_bits(Glog, j));
        Gf2Basis V = R;
        const bool maxgain = P.k <= 64;
        P.method = maxgain ? "max-gain greedy" : "in-order greedy";
        for (;;) {
            int best = -1, best_rank = -1;
            Gf2Basis bestV(n);
            for (int j = 0; j < P.k; j++) {
                std::vector<uint64_t> v = grows[j];
                if (V.reduce(v)) continue;
                Gf2Basis W = V;
                closure_add(W, grows[j], P.gens);
                if (W.rank() > best_rank) { best = j; best_rank = W.rank(); bestV = W; }
                if (!maxgain) break;
            }
            if (best < 0) break;
            P.chosen.push_back(best);
            V = bestV;
            if ((int)P.chosen.size() > rmax) break;     /* too many: decomposition will not be used */
        }
        bool all = true;
        for (int j = 0; all && j < P.k; j++) { std::vector<uint64_t> v = grows[j]; all = V.reduce(v); }
        P.spans = all;
        const int r = (int)P.chosen.size();
        P.decompose = P.spans && r >= 1 && r <= rmax && r < P.k;
    }
    P.seconds = cpuTime() - t0;
    return P;
}

static void print_half_plan(const HalfPlan& P, bool perms) {
    printf("c xordecomp %s half: n=%d k=%d rank(Hpar)=%d candidates=%d verified_generators=%zu r=%s%zu spans=%s decision=%s method=%s plan_cpu=%.3fs\n",
           P.tag, P.n, P.k, P.rank_h, P.candidates, P.gens.size(),
           (P.spans ? "" : ">"), P.chosen.size(), P.spans ? "yes" : "no",
           P.decompose ? "decompose" : "fallback-OR", P.method, P.seconds);
    for (size_t s = 0; s < P.gens.size(); s++) {
        printf("c xordecomp %s generator: %s\n", P.tag, P.gens[s].desc.c_str());
        if (perms) {
            printf("c xordecomp %s perm:", P.tag);
            for (int i = 0; i < P.n; i++) printf(" %d", P.gens[s].perm[i]);
            printf("\n");
        }
    }
    printf("c xordecomp %s chosen rows:", P.tag);
    for (size_t i = 0; i < P.chosen.size(); i++) printf(" %d", P.chosen[i]);
    printf("\n");
    fflush(stdout);
}

/* One part of the global search. xor_row < 0: OR half (GH-73 build_css_half); else single XOR. */
struct CssPart {
    std::string tag; const Matrix* H; const Matrix* G; int xor_row;
    bool exists;          /* has a feasible point (instance SAT) */
    uint64_t lb;          /* proven: every point of this part has weight >= lb */
    uint64_t ub;          /* best weight found (UINT64_MAX if none) */
};

/* Returns false when this part is UNSAT. */
static bool build_css_part(SimpSolver& S, std::vector<Var>& aux, int& n_out, const CssPart& p,
                           int verb, int card_mode)
{
    const Matrix& Hpar = *p.H;
    const Matrix& Glog = *p.G;
    const int n = Hpar.cols;
    n_out = n;
    if (Glog.cols != n) die("matrix column mismatch");
    const int k_log = p.xor_row < 0 ? Glog.rows : 0;
    if (p.xor_row < 0 && k_log == 0) return false;
    aux.clear();
    S.setBoundsPipe(-1);                 /* bounds forwarded only through explicit settings below */
    S.cardinalityEncMode = card_mode;
    S.parsing = true;
    S.verbosity = verb;
    S.instanceType = 1;
    S.hardWeight = (unsigned)(n + k_log + 64);
    S.UB = S.hardWeight;
    S.initUB = INT32_MAX;
    S.nbOriVars = n;
    const Var off_a = n;
    while (S.nVars() < n + k_log) S.newVar();
    bool ok = true;
    for (int r = 0; ok && r < Hpar.rows; r++) {
        std::vector<Lit> lits;
        for (int i = 0; i < n; i++) if (getm(Hpar, r, i)) lits.push_back(mkLit(i));
        ok = xor_equals_soft_fail(S, lits, false, aux);
    }
    if (p.xor_row >= 0) {
        /* single-XOR subproblem: g.x = 1 (implies x != 0 and nontriviality) */
        std::vector<Lit> lits;
        for (int i = 0; ok && i < n; i++) if (getm(Glog, p.xor_row, i)) lits.push_back(mkLit(i));
        ok = ok && xor_equals_soft_fail(S, lits, true, aux);
    } else {
        if (ok) {
            std::vector<Lit> nz;
            for (int i = 0; i < n; i++) nz.push_back(mkLit(i));
            ok = add_clause_soft_fail(S, nz, S.hardWeight);
        }
        for (int j = 0; ok && j < k_log; j++) {
            std::vector<Lit> lits;
            for (int i = 0; i < n; i++) if (getm(Glog, j, i)) lits.push_back(mkLit(i));
            Lit a_lit = mkLit(off_a + j);
            if (lits.empty()) {
                std::vector<Lit> c; c.push_back(~a_lit);
                ok = add_clause_soft_fail(S, c, S.hardWeight);
            } else {
                lits.push_back(a_lit);
                ok = xor_equals_soft_fail(S, lits, false, aux);
            }
        }
        if (ok) {
            std::vector<Lit> ors;
            for (int j = 0; j < k_log; j++) ors.push_back(mkLit(off_a + j));
            ok = add_clause_soft_fail(S, ors, S.hardWeight);
        }
    }
    for (int i = 0; ok && i < n; i++) {
        std::vector<Lit> sc; sc.push_back(~mkLit(i));
        ok = add_clause_soft_fail(S, sc, 1);
    }
    if (!ok) return false;
    S.parsing = false;
    S.setFrozenVars();
    S.eliminate(true);
    return S.okay();
}

enum PartStatus { PART_FOUND, PART_NONE, PART_OPT, PART_UNKNOWN, PART_INFEASIBLE };

/* One oracle call on a part (GH-73 run_css_half). cap: only solutions of weight <= cap (strict).
 * first_only: stop at the first solution. Emitted bounds are capped/hidden as requested. */
static PartStatus run_css_part(CssPart& h, uint64_t cap, bool first_only, int verb, int card_mode,
                               int pipe_w, uint64_t lb_cap, uint64_t ub_cap, bool hide_lb, uint64_t& value)
{
    SimpSolver S;
    std::vector<Var> aux;
    int n = 0;
    if (!build_css_part(S, aux, n, h, verb, card_mode)) { h.exists = false; return PART_INFEASIBLE; }
    S.setBoundsPipe(pipe_w);
    S.initUB = cap >= (uint64_t)INT32_MAX ? INT32_MAX : cap;
    S.strictUB = cap < (uint64_t)INT32_MAX;
    S.initLB = h.lb;
    S.stopAtFirstSolution = first_only;
    S.startAtCap = true;
    S.boundsLbCap = lb_cap; S.boundsUbCap = ub_cap; S.boundsHideLB = hide_lb;
    vec<Lit> dummy;
    lbool ret = S.solveLimited(dummy);
    uint64_t opt = S.getLastOptimalCost();
    PartStatus st = PART_UNKNOWN;
    if (first_only && ret == l_True) { value = S.getCostUB(); st = PART_FOUND; }
    else if (!first_only && opt != UINT64_MAX && opt <= (uint64_t)n) { value = opt; st = PART_OPT; }
    else if (ret == l_False && opt == UINT64_MAX) st = PART_NONE;      /* nothing of weight <= cap */
    if (verb > 0)
        printf("c xordecomp: part %s cap %llu lb %llu %s -> %s %llu\n", h.tag.c_str(),
               (unsigned long long)cap, (unsigned long long)h.lb, first_only ? "feasibility" : "optimize",
               st == PART_FOUND ? "FOUND" : st == PART_OPT ? "OPT" : st == PART_NONE ? "NONE" : "UNKNOWN",
               (unsigned long long)(st == PART_FOUND || st == PART_OPT ? value : 0));
    return st;
}

static void pipe_bound(int pipe_w, const char* kind, uint64_t v) {
    if (pipe_w < 0) return;
    char buf[64];
    int len = snprintf(buf, sizeof(buf), "%s %llu\n", kind, (unsigned long long)v);
    if (len > 0) (void)write(pipe_w, buf, (size_t)len);
}

static void make_parts(std::vector<CssPart>& parts, const char* tag, const Matrix& Hpar, const Matrix& Glog,
                       int verb, bool decomp)
{
    if (Glog.rows == 0) return;          /* no logical of this type */
    if (decomp) {
        HalfPlan P = plan_half(tag, Hpar, Glog, g_xor_rmax);
        if (verb > 0) print_half_plan(P, false);
        if (P.decompose) {
            for (size_t i = 0; i < P.chosen.size(); i++) {
                char buf[48];
                snprintf(buf, sizeof(buf), "%s/g%d", tag, P.chosen[i]);
                CssPart p = { buf, &Hpar, &Glog, P.chosen[i], true, 1, UINT64_MAX };
                parts.push_back(p);
            }
            return;
        }
    }
    CssPart p = { std::string(tag) + "/OR", &Hpar, &Glog, -1, true, 1, UINT64_MAX };
    parts.push_back(p);
}

/* Global LB: min over the unfinished existing parts (except skip) of their proven lb, and U. */
static uint64_t global_lb(const std::vector<CssPart>& parts, const std::vector<bool>& done, uint64_t U, int skip) {
    uint64_t g = U;
    for (size_t j = 0; j < parts.size(); j++)
        if ((int)j != skip && !done[j] && parts[j].exists && parts[j].lb < g) g = parts[j].lb;
    return g;
}

static int min_distance_css_parts(
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    int verb, int pipe_w, int card_mode, bool decomp)
{
    if (Hx.cols != Hz.cols || Gx.cols != Hx.cols || Gz.cols != Hx.cols) die("matrix column mismatch");
    const uint64_t n = (uint64_t)Hx.cols, INF = UINT64_MAX;
    std::vector<CssPart> parts;
    make_parts(parts, "X", Hz, Gx, verb, decomp);
    make_parts(parts, "Z", Hx, Gz, verb, decomp);
    const size_t N = parts.size();
    if (N == 0) die("no nontrivial logical operator in either half");
    uint64_t U = INF, v = 0, lastLB = 0;
    std::vector<bool> done(N, false);
    /* Phase 1: doubling feasibility tests on all parts; anytime global LB. */
    for (uint64_t m = 1; ; m = (m >= n ? n : 2 * m)) {
        bool any_ub = false;
        for (size_t k = 0; k < N; k++) {
            CssPart& h = parts[k];
            if (!h.exists || h.ub != INF || h.lb > m) continue;
            PartStatus st = run_css_part(h, m, true, verb, card_mode, pipe_w, INF, U, true, v);
            if (st == PART_FOUND) { h.ub = v; if (v < U) { U = v; pipe_bound(pipe_w, "UB", U); } }
            else if (st == PART_NONE) h.lb = m + 1;
            else if (st == PART_INFEASIBLE) done[k] = true;
            else { pipe_write_result(pipe_w, -1, false); return -1; }
        }
        bool any = false;
        for (size_t k = 0; k < N; k++) if (parts[k].exists) { any = true; if (parts[k].ub != INF) any_ub = true; }
        if (!any) die("no nontrivial logical operator in either half");
        uint64_t glb = global_lb(parts, done, U, -1);
        if (glb != INF && glb > lastLB) { lastLB = glb; pipe_bound(pipe_w, "LB", glb); }
        if (any_ub || m >= n) break;
    }
    if (U == INF) { pipe_write_result(pipe_w, -1, false); return -1; }
    /* Phase 2: parts in order of (incumbent, index); each either refutes "weight <= U-1" (finished,
     * value >= U) or is optimised below U, lowering the shared UB. */
    for (;;) {
        int k = -1;
        for (size_t j = 0; j < N; j++)
            if (!done[j] && parts[j].exists && (k < 0 || parts[j].ub < parts[k].ub)) k = (int)j;
        if (k < 0) break;
        CssPart& h = parts[k];
        if (h.lb >= U) { done[k] = true; continue; }
        uint64_t lbc = global_lb(parts, done, U, k);
        PartStatus st = run_css_part(h, U - 1, false, verb, card_mode, pipe_w, lbc, U, false, v);
        if (st == PART_OPT) { h.lb = h.ub = v; if (v < U) { U = v; pipe_bound(pipe_w, "UB", U); } }
        else if (st == PART_NONE || st == PART_INFEASIBLE) { h.lb = U; }
        else { pipe_write_result(pipe_w, -1, false); return -1; }
        done[k] = true;
        uint64_t glb = global_lb(parts, done, U, -1);
        if (glb > lastLB) { lastLB = glb; pipe_bound(pipe_w, "LB", glb); }
    }
    if (verb > 0) printf("c xordecomp: %zu parts, d = %llu\n", N, (unsigned long long)U);
    pipe_bound(pipe_w, "LB", U);
    pipe_write_result(pipe_w, (int)U, true);
    return (int)U;
}

static bool g_css_joint = false;   /* -joint: original symplectic joint encoding */
static bool g_xordecomp = true;    /* -no-xordecomp: OR halves only */

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
        } else if (!g_css_joint) {
            d = min_distance_css_parts(Hx, Hz, Gx, Gz, verb, pipefd[1], card_mode, g_xordecomp);
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
        else if (!strcmp(argv[i], "-joint"))
            g_css_joint = true;
        else if (!strcmp(argv[i], "-no-xordecomp"))
            g_xordecomp = false;
        else if (!strncmp(argv[i], "-xor-rmax=", 10))
            g_xor_rmax = atoi(argv[i] + 10);
        else if (!strcmp(argv[i], "-xordecomp-report"))
            g_xordecomp_report = true;
        else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
            printf("Usage: %s [options] <code>\n", argv[0]);
            printf("  <code>  e.g. LP_34_20_2  (loads data/matrices/<code>_{{Hx,Hz,Gx,Gz}}.txt)\n");
            printf("  Distance: min Pauli weight in S^perp \\\\ S (symplectic MaxSAT).\n");
            printf("  Options: -cpu-lim=N  -v|-debug  -q  -dump-wcnf=PATH  -dump-opb=PATH  -dump-only\n");
            printf("           -native-parity-opb  GF(2) parity as PB equalities (OPB dump only)\n");
            printf("  Solver: default MaxCDCL; -roundingsat[=BIN] uses external RoundingSat on WCNF\n");
            printf("  Cardinality: default Sinz+MTO (Sinz if n<=100); -no-card | -card-sinz | -card-mto\n");
            printf("               -card-both-force  always Sinz+MTO regardless of n\n");
            printf("  Formulation: default CSS split d=min(dX,dZ), each half decomposed into single-XOR subproblems\n");
            printf("               via verified code automorphisms when r <= -xor-rmax=N (default 4) and r < k, else OR half;\n");
            printf("               global bound search over all parts; -no-xordecomp = OR halves; -joint = original joint encoding\n");
            printf("  -xordecomp-report: print per-half verified generators (with permutations), r, chosen rows; no solve\n");
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

    if (g_xordecomp_report) {
        HalfPlan px = plan_half("X", Hz, Gx, g_xor_rmax);
        print_half_plan(px, true);
        HalfPlan pz = plan_half("Z", Hx, Gz, g_xor_rmax);
        print_half_plan(pz, true);
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
