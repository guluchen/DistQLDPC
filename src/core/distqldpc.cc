/*
 * DistQLDPC — QLDPC / CSS code minimum distance via MaxCDCL (SimpSolver / MaxSAT).
 *
 * Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Data: data/matrices/tierN/<code>_{Hx,Hz,Gx,Gz}.txt (N = 0..5, see data/matrices/README.md).
 *   A bare code name (no '/') resolves to data/matrices/<code> if <code>_Hx.txt is there,
 *   else to the first of data/matrices/tier0 .. tier5 containing it; an argument with
 *   a '/' is used as a path prefix unchanged.
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
#include "../cc/cc_driver.h"   /* GH-124: CC level-search engine (-engine=cc, experimental) */

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

/* GH-124 (timing seeds): -seed=N. N = 0 (default) leaves every MaxCDCL solver at its built-in random_seed
 * (91648253), so the search is main's, byte for byte. N > 0 sets random_seed of every fresh solver of the
 * MaxSAT path to a value derived from N (splitmix64, in [1, 2^31 - 2], never the built-in value). In this
 * build random_seed only drives the engine's 1% sampling of the lookahead threshold (Solver::lookahead;
 * rnd-init and random decisions are off), so a seed perturbs the search order but never the encoding, the
 * bounds or the answer. With the CC engine -seed=N is -cc-seed=N (relabeling). */
static uint64_t g_seed = 0;

static double maxsat_random_seed(uint64_t seed)
{
    uint64_t z = seed + 0x9e3779b97f4a7c15ULL;
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
    z ^= z >> 31;
    uint64_t v = 1 + z % 2147483646ULL;   /* drand() is a Lehmer generator mod 2^31 - 1: seed in [1, 2^31 - 2] */
    if (v == 91648253ULL) v++;            /* never MaxCDCL's built-in default */
    return (double)v;
}

static void apply_maxsat_seed(Solver& S)
{
    if (g_seed != 0) S.random_seed = maxsat_random_seed(g_seed);
}

static int min_distance_stabilizer_maxsat(
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    int cpu_lim, int verb, int bounds_pipe_w, int card_mode,
    const char* dump_wcnf_path)
{
    (void)cpu_lim;
    SimpSolver S;
    apply_maxsat_seed(S);
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

/* ---- GH-73: interleaved CSS split with a global bound search (PI-approved formulation change,
 * recorded in GH-71, 2026-10-09). For a CSS code d = min(dX, dZ): every nontrivial logical (x,z) has
 * x a nontrivial X-type logical or z a nontrivial Z-type logical with |x|,|z| <= |(x,z)|, and pure
 * X/Z logicals are Pauli logicals. Half instance (one Pauli type, vars v_0..v_{n-1}):
 *   Hpar . v = 0,  a_j = Glog_j . v,  OR_j a_j,  soft -v_i (weight 1).
 * X half: Hpar = Hz, Glog = Gx.  Z half: Hpar = Hx, Glog = Gz (same a_j test as the joint encoding).
 * Only globally valid bounds are forwarded: LB = min over halves of their proven LB, UB = best found. */
static bool add_clause_soft_fail(SimpSolver& S, const std::vector<Lit>& lits, unsigned w) {
    vec<Lit> ps;
    for (size_t i = 0; i < lits.size(); i++) ps.push(lits[i]);
    return S.addClause_(ps, w);
}

static bool xor_equals_zero_soft_fail(SimpSolver& S, const std::vector<Lit>& inputs, std::vector<Var>& aux) {
    if (inputs.empty()) return true;
    std::vector<Lit> c;
    if (inputs.size() == 1) c.push_back(~inputs[0]);
    else c.push_back(~parity(S, inputs, aux));
    return add_clause_soft_fail(S, c, S.hardWeight);
}

/* ---- GH-85: per-half symmetry breaking inside the interleaved CSS halves (GH-73 x GH-75
 * interaction experiment). Candidate family and GF(2) verifier reused from GH-75 (bbe5055).
 * Half feasible set F = ker(Hpar) \ ker([Hpar; Glog]). A qubit permutation pi is kept for the
 * half iff pi(rs Hpar) = rs Hpar and pi(rs [Hpar; Glog]) = rs [Hpar; Glog] (each permuted row
 * reduces to zero in an RREF basis of the space; permutations preserve rank). Permutations
 * preserve the dot product, hence both kernels, so v |-> pi v maps F onto F and keeps |v|.
 * Only such plain maps are used: XZ-dual maps send X-half solutions to Z-half solutions and are
 * not automorphisms of one half. With orbits O_1..O_k (minima r_j) of the generated group, any
 * feasible v can be moved (same weight) to one whose first met orbit O_j* contains r_j* in its
 * support; the orbit clauses below therefore preserve, for every w, the existence of a half
 * solution of weight <= w, i.e. every answer of every GH-73 oracle call.
 * Static symmetry breaking: Crawford et al. KR'96; Satsuma, Anders/Brenner/Rattan, SAT 2024. */
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

struct HalfSymInfo {
    int n;
    std::vector<std::string> generators; /* "plain <desc>" */
    std::vector<int> orbit_of;           /* orbit representative (min) per qubit */
    std::vector<int> reps;               /* sorted orbit minima */
    int candidates;
    double seconds;
};

/* Shared by GH-85 and GH-87 (GH-92 dedup): drops exact duplicates of earlier candidates. */
static void add_candidate(std::vector<SymCandidate>& out, const std::string& desc, const std::vector<int>& perm) {
    for (size_t k = 0; k < out.size(); k++)
        if (out[k].perm == perm) return;
    SymCandidate c;
    c.desc = desc;
    c.perm = perm;
    out.push_back(c);
}

/* GH-75 candidate family (generic index maps; none assumed, all verified), shared by GH-85 and
 * GH-87 (GH-92 dedup). The identity is seeded first so that family members equal to it or to an
 * earlier member are dropped; with_identity=false (GH-85 half automorphisms) then removes it,
 * which gives exactly GH-85's list (identity and duplicates rejected, same order);
 * with_identity=true (GH-87 dual maps, rs Hz = rs Hx type codes) keeps it first, as in GH-87. */
static std::vector<SymCandidate> candidate_family(int n, bool with_identity) {
    std::vector<SymCandidate> out;
    char buf[96];
    std::vector<int> p((size_t)n);
    for (int i = 0; i < n; i++) p[i] = i;
    add_candidate(out, "identity", p);
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
    if (!with_identity) out.erase(out.begin());
    return out;
}

static int uf_find(std::vector<int>& par, int a) {
    while (par[a] != a) {
        par[a] = par[par[a]];
        a = par[a];
    }
    return a;
}

/* Verified plain automorphisms of one CSS half (Hpar, Glog) and their qubit orbits. */
static HalfSymInfo find_half_symmetry(const Matrix& Hpar, const Matrix& Glog)
{
    const double t0 = cpuTime();
    HalfSymInfo info;
    const int n = Hpar.cols;
    info.n = n;
    RowSupports sH, sHG;
    append_supports(sH, Hpar);
    append_supports(sHG, Hpar);
    append_supports(sHG, Glog);
    const Gf2Basis bH = basis_of(sH, n), bHG = basis_of(sHG, n);
    std::vector<int> par((size_t)n);
    for (int i = 0; i < n; i++) par[i] = i;
    const std::vector<SymCandidate> cands = candidate_family(n, false);
    info.candidates = (int)cands.size();
    for (size_t k = 0; k < cands.size(); k++) {
        const std::vector<int>& pi = cands[k].perm;
        if (!permuted_rows_in(sH, pi, bH) || !permuted_rows_in(sHG, pi, bHG)) continue;
        info.generators.push_back("plain " + cands[k].desc);
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

static void print_half_symmetry(const HalfSymInfo& info, const char* prefix, bool all_reps) {
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
        for (int j = 0; j < k && (all_reps || j < 64); j++) printf(" %d(%d)", info.reps[j], size[info.reps[j]]);
        printf(!all_reps && k > 64 ? " ...\n" : "\n");
    }
    fflush(stdout);
}

/* GH-75 orbit clauses (unit v_{r_1} if transitive, else orbit chain), on the half variables v. */
static bool add_half_orbit_clauses(SimpSolver& S, std::vector<Var>& aux, int n, const std::vector<int>& orb)
{
    std::vector<int> reps, idx((size_t)n, -1);
    for (int i = 0; i < n; i++)
        if (orb[i] == i) {
            idx[i] = (int)reps.size();
            reps.push_back(i);
        }
    const int k = (int)reps.size();
    if (k >= n) return true;
    std::vector<Lit> sb;
    for (int j = 0; j < k; j++) sb.push_back(mkLit(reps[j]));
    if (!add_clause_soft_fail(S, sb, S.hardWeight)) return false;
    if (k == 1) return true;
    std::vector<std::vector<int> > members((size_t)k);
    for (int i = 0; i < n; i++) members[idx[orb[i]]].push_back(i);
    std::vector<Lit> pref((size_t)k);
    for (int j = 0; j + 1 < k; j++) {
        Var v = ensure_var(S, S.nVars());
        aux.push_back(v);
        pref[j] = mkLit(v);
    }
    for (int j = 0; j + 1 < k; j++) {
        /* p_j -> p_{j-1} v OR_{q in O_j} v_q ;  p_{j-1} -> p_j ;  v_q -> p_j */
        std::vector<Lit> up;
        up.push_back(~pref[j]);
        if (j > 0) up.push_back(pref[j - 1]);
        for (size_t t = 0; t < members[j].size(); t++) up.push_back(mkLit(members[j][t]));
        if (!add_clause_soft_fail(S, up, S.hardWeight)) return false;
        if (j > 0) {
            std::vector<Lit> c;
            c.push_back(~pref[j - 1]); c.push_back(pref[j]);
            if (!add_clause_soft_fail(S, c, S.hardWeight)) return false;
        }
        for (size_t t = 0; t < members[j].size(); t++) {
            std::vector<Lit> c;
            c.push_back(~mkLit(members[j][t])); c.push_back(pref[j]);
            if (!add_clause_soft_fail(S, c, S.hardWeight)) return false;
        }
    }
    for (int j = 0; j < k; j++)
        for (size_t t = 0; t < members[j].size(); t++) {
            const int q = members[j][t];
            if (q == reps[j]) continue;
            std::vector<Lit> c;
            c.push_back(~mkLit(q));
            c.push_back(mkLit(reps[j]));
            if (j > 0) c.push_back(pref[j - 1]);
            if (!add_clause_soft_fail(S, c, S.hardWeight)) return false;
        }
    return true;
}

/* Returns false when this half has no nontrivial logical (instance UNSAT). */
static bool build_css_half(SimpSolver& S, std::vector<Var>& aux, int& n_out,
                           const Matrix& Hpar, const Matrix& Glog, int verb, int card_mode,
                           const std::vector<int>* sb_orbit)
{
    const int n = Hpar.cols;
    n_out = n;
    if (Glog.cols != n) die("matrix column mismatch");
    const int k_log = Glog.rows;
    if (k_log == 0) return false;
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
        ok = xor_equals_zero_soft_fail(S, lits, aux);
    }
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
            ok = xor_equals_zero_soft_fail(S, lits, aux);
        }
    }
    if (ok) {
        std::vector<Lit> ors;
        for (int j = 0; j < k_log; j++) ors.push_back(mkLit(off_a + j));
        ok = add_clause_soft_fail(S, ors, S.hardWeight);
    }
    for (int i = 0; ok && i < n; i++) {
        std::vector<Lit> sc; sc.push_back(~mkLit(i));
        ok = add_clause_soft_fail(S, sc, 1);
    }
    if (ok && sb_orbit && (int)sb_orbit->size() == n)   /* GH-85 */
        ok = add_half_orbit_clauses(S, aux, n, *sb_orbit);
    if (!ok) return false;
    S.parsing = false;
    S.setFrozenVars();
    S.eliminate(true);
    return S.okay();
}

enum HalfStatus { HALF_FOUND, HALF_NONE, HALF_OPT, HALF_UNKNOWN, HALF_INFEASIBLE };

struct CssHalf {
    const char* tag; const Matrix* H; const Matrix* G;
    bool exists;          /* has a nontrivial logical of this type (instance SAT) */
    uint64_t lb;          /* proven: every logical of this type has weight >= lb */
    uint64_t ub;          /* best weight found (UINT64_MAX if none) */
    std::vector<int> sb_orbit;  /* GH-85: verified per-half orbits (empty: no clause) */
    /* GH-107 work counters (informational, printed only with -dualshare-stats; value-initialised to 0) */
    uint64_t probes;      /* oracle calls (fresh solvers) on this half */
    uint64_t conflicts;   /* engine conflicts spent in those calls */
    uint64_t own_lb;      /* lb this half would hold without dual-map sharing (skip accounting only) */
};

/* One oracle call on a half. cap: only solutions of weight <= cap are sought (strict).
 * first_only: stop at the first solution. Emitted bounds are capped/hidden as requested. */
static HalfStatus run_css_half(CssHalf& h, uint64_t cap, bool first_only, int verb, int card_mode,
                               int pipe_w, uint64_t lb_cap, uint64_t ub_cap, bool hide_lb, uint64_t& value)
{
    SimpSolver S;
    apply_maxsat_seed(S);   /* GH-124: -seed=N (no-op for N = 0) */
    std::vector<Var> aux;
    int n = 0;
    if (!build_css_half(S, aux, n, *h.H, *h.G, verb, card_mode, h.sb_orbit.empty() ? NULL : &h.sb_orbit)) { h.exists = false; return HALF_INFEASIBLE; }
    S.setBoundsPipe(pipe_w);
    S.initUB = cap >= (uint64_t)INT32_MAX ? INT32_MAX : cap;
    S.strictUB = cap < (uint64_t)INT32_MAX;
    S.initLB = h.lb;
    S.stopAtFirstSolution = first_only;
    S.startAtCap = true;   /* first test is the cap itself: probes test only "weight <= cap"; optimisation finds, then descends */
    S.boundsLbCap = lb_cap; S.boundsUbCap = ub_cap; S.boundsHideLB = hide_lb;
    vec<Lit> dummy;
    lbool ret = S.solveLimited(dummy);
    h.probes++; h.conflicts += S.conflicts;   /* GH-107 work counters (fresh solver per probe) */
    uint64_t opt = S.getLastOptimalCost();
    HalfStatus st = HALF_UNKNOWN;
    if (first_only && ret == l_True) { value = S.getCostUB(); st = HALF_FOUND; }
    else if (!first_only && opt != UINT64_MAX && opt <= (uint64_t)n) { value = opt; st = HALF_OPT; }
    else if (ret == l_False && opt == UINT64_MAX) st = HALF_NONE;      /* nothing of weight <= cap */
    if (verb > 0)
        printf("c CSS interleave: %s half cap %llu lb %llu %s -> %s %llu\n", h.tag,
               (unsigned long long)cap, (unsigned long long)h.lb, first_only ? "feasibility" : "optimize",
               st == HALF_FOUND ? "FOUND" : st == HALF_OPT ? "OPT" : st == HALF_NONE ? "NONE" : "UNKNOWN",
               (unsigned long long)(st == HALF_FOUND || st == HALF_OPT ? value : 0));
    return st;
}

static void pipe_bound(int pipe_w, const char* kind, uint64_t v) {
    if (pipe_w < 0) return;
    char buf[64];
    int len = snprintf(buf, sizeof(buf), "%s %llu\n", kind, (unsigned long long)v);
    if (len > 0) (void)write(pipe_w, buf, (size_t)len);
}

/* ---- GH-87: dual-half elimination (extension of GH-73; idea: unselected proposal GH-78-B).
 * X half F_X = ker(Hz) \ ker([Hz;Gx]), Z half F_Z = ker(Hx) \ ker([Hx;Gz]). If a qubit permutation
 * pi satisfies pi(rs Hz) = rs Hx and pi(rs [Hz;Gx]) = rs [Hx;Gz], then (dot products are permutation
 * invariant) pi(ker Hz) = ker Hx and pi(ker [Hz;Gx]) = ker [Hx;Gz], so v |-> pi v is a weight-
 * preserving bijection F_X -> F_Z and dX = dZ: the X half alone yields d, and its proven LB/UB are
 * global. Equalities are verified over GF(2): equal ranks, and every permuted source row reduces to
 * zero in an RREF basis of the target space (a permutation preserves rank). Candidates: identity,
 * then the generic GH-75 family (none assumed, all verified). GH-92: the GF(2) basis, row supports
 * and the candidate family are the single shared copies defined in the GH-85 block above
 * (Gf2Basis, append_supports, basis_of, permuted_rows_in, candidate_family(n, true)). */
struct DualMapInfo {
    int n, rank_hz, rank_hx, rank_hzgx, rank_hxgz, candidates;
    std::vector<std::string> maps;   /* verified dual maps, in candidate order (first = used) */
    std::vector<std::vector<int> > perms;   /* GH-124: the qubit maps of `maps` (same order) */
    double seconds;
};

/* Verified XZ-dual maps of the two CSS half instances. all=false stops at the first one. */
static DualMapInfo find_dual_maps(const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz, bool all)
{
    const double t0 = cpuTime();
    DualMapInfo info;
    const int n = Hx.cols;
    info.n = n;
    RowSupports sHz, sHzGx, sHx, sHxGz;
    append_supports(sHz, Hz);
    append_supports(sHzGx, Hz);
    append_supports(sHzGx, Gx);
    append_supports(sHx, Hx);
    append_supports(sHxGz, Hx);
    append_supports(sHxGz, Gz);
    const Gf2Basis bHx = basis_of(sHx, n), bHxGz = basis_of(sHxGz, n);
    info.rank_hx = bHx.rank();
    info.rank_hxgz = bHxGz.rank();
    info.rank_hz = basis_of(sHz, n).rank();
    info.rank_hzgx = basis_of(sHzGx, n).rank();
    info.candidates = 0;
    if (info.rank_hz == info.rank_hx && info.rank_hzgx == info.rank_hxgz) {
        const std::vector<SymCandidate> cands = candidate_family(n, true);
        info.candidates = (int)cands.size();
        for (size_t k = 0; k < cands.size(); k++) {
            const std::vector<int>& pi = cands[k].perm;
            if (!permuted_rows_in(sHz, pi, bHx) || !permuted_rows_in(sHzGx, pi, bHxGz)) continue;
            info.maps.push_back(cands[k].desc);
            info.perms.push_back(pi);
            if (!all) break;
        }
    }
    info.seconds = cpuTime() - t0;
    return info;
}

/* ---- GH-107: dual-map bound sharing on main's interleaved split (no incremental solver; issue #107).
 * Port of GH-102 variant A (69f91c1) to the fresh-solver-per-probe driver of main 7eadd54 / GH-92.
 * A verified XZ-dual map pi (find_dual_maps above) is a weight-preserving bijection F_X -> F_Z, so for every w
 * one half has a solution of weight <= w iff the other has; with GH-85's orbit clauses (plain per-half
 * automorphisms only, existence-at-weight preserving) the same holds for the two symmetry-broken half instances.
 * Every proven half bound is therefore a bound of both halves and dX = dZ. Instead of eliminating the Z half
 * (GH-87/GH-92, -dualmode=skip), -dualmode=share keeps both halves in main's interleaved search unchanged and,
 * after every probe, writes the larger proven half LB into both halves (global LB = max of the half LBs). Main's
 * own skip tests then drop every probe whose NONE the other half already proved (Phase 1: lb > m; Phase 2:
 * lb >= U). UBs stay global; no probe kind and no cap is added (GH-87's A1 is not used), so each half's probe
 * sequence is a subsequence of main's for the same U history. The shared lb enters a fresh half solver only as
 * initLB (a true lower bound of that instance's optimum). A shared lb above U would contradict the map: no answer
 * (RESULT -1), never a value. -dualmode=off = main exactly (no detection, no output). */
enum { DUALMODE_OFF = 0, DUALMODE_SHARE = 1, DUALMODE_SKIP = 2 };

/* GH-107 (= GH-102's dualshare_sync): writes max(lb_X, lb_Z) into both halves; false if it exceeds U. */
static bool dualshare_sync(CssHalf hs[2], uint64_t U) {
    if (!hs[0].exists || !hs[1].exists) return true;
    const uint64_t L = hs[0].lb > hs[1].lb ? hs[0].lb : hs[1].lb;
    hs[0].lb = hs[1].lb = L;
    if (L > U) {
        printf("c dualshare: inconsistent shared bound (lb %llu > UB %llu): no answer\n",
               (unsigned long long)L, (unsigned long long)U);
        return false;
    }
    return true;
}

/* ---- GH-128: -p1skip=on|off (default on after the S1 evaluation; off = main's probe sequence). Redundant-probe
 * removal in the interleaved search.
 * d = min(dX, dZ) with UB U = the weight of a logical found by some probe (U >= d). A half whose proven lb
 * (own or shared via GH-107) is >= U holds no logical of weight < U, so no probe on it can lower U and every
 * probe on it would leave d = min(U, d of the other half) unchanged: it is skipped in Phase 1 (Phase 2a/2b
 * already skip such a half through their h.lb >= U guards, so nothing is added there). When every existing half has lb >= U the global lb min(lbX, lbZ) equals U and
 * d = U is proven: the search stops at once and reports d = U through the usual output (no probe follows,
 * the reported LB/UB/d are the values main would report). No other probe, cap or bound changes. */
static bool g_p1skip = true;   /* GH-128 S1: default on (sound, never more probes; see the experiment REPORT) */

/* GH-128: global lb (min of the existing halves' proven lbs) has reached U (U finite). */
static bool css_bounds_meet(const CssHalf hs[2], uint64_t U) {
    if (U == UINT64_MAX) return false;
    bool any = false;
    for (int k = 0; k < 2; k++) if (hs[k].exists) { any = true; if (hs[k].lb < U) return false; }
    return any;
}

static int min_distance_css_interleaved(
    const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
    int verb, int pipe_w, int card_mode, bool symbreak, int dualmode, bool stats = false)
{
    if (Hx.cols != Hz.cols || Gx.cols != Hx.cols || Gz.cols != Hx.cols) die("matrix column mismatch");
    const uint64_t n = (uint64_t)Hx.cols, INF = UINT64_MAX;
    CssHalf hs[2] = { {"X", &Hz, &Gx, Gx.rows > 0, 1, INF}, {"Z", &Hx, &Gz, Gz.rows > 0, 1, INF} };
    hs[0].own_lb = hs[1].own_lb = 1;
    /* GH-92 (stack of GH-87 on GH-85): dual-map detection first, then per-half symmetry detection on
     * every half that is still solved. Soundness of the combination: a verified XZ-dual map proves
     * dX = dZ (weight-preserving bijection F_X -> F_Z, see the GH-87 block), so solving only the X
     * half is exact and its bounds are global. The orbit clauses added to the X half come only from
     * verified *plain* automorphisms of that half (never from the XZ-dual map, which is not one);
     * they preserve, for every w, the existence of an X-half solution of weight <= w, hence every
     * oracle answer (FOUND/NONE/OPT under any cap) and the X half's optimum. Therefore the stack
     * returns dX = d with only proven global bounds. When the Z half is eliminated, symmetry
     * breaking is still applied to the X half (the half that is solved); without a dual map both
     * halves get their own clauses exactly as in GH-85. -dualmode=off = GH-85, -no-symbreak = GH-87. */
    /* GH-87 (-dualmode=skip): a verified XZ-dual map proves dX = dZ; the Z half is then eliminated (treated
     * as absent), so every bound below is the X half's, which is global.
     * GH-107 (-dualmode=share, default): both halves stay; proven lower bounds are shared (see above). */
    bool z_eliminated = false, share = false;
    if (dualmode != DUALMODE_OFF && hs[0].exists && hs[1].exists) {
        DualMapInfo dm = find_dual_maps(Hx, Hz, Gx, Gz, false);
        if (!dm.maps.empty()) {
            if (dualmode == DUALMODE_SKIP) { hs[1].exists = false; z_eliminated = true; }
            else share = true;
        }
        if (verb > 0) {
            if (dualmode == DUALMODE_SKIP) {
                if (!dm.maps.empty())
                    printf("c dualskip: dual map '%s' verified (rank Hz=Hx=%d, [Hz;Gx]=[Hx;Gz]=%d, cpu %.3fs): dX = dZ, solving X half only\n",
                           dm.maps[0].c_str(), dm.rank_hx, dm.rank_hxgz, dm.seconds);
                else
                    printf("c dualskip: no dual map (ranks Hz %d Hx %d [Hz;Gx] %d [Hx;Gz] %d, %d candidates, cpu %.3fs): both halves\n",
                           dm.rank_hz, dm.rank_hx, dm.rank_hzgx, dm.rank_hxgz, dm.candidates, dm.seconds);
            } else {
                if (!dm.maps.empty())
                    printf("c dualshare: dual map '%s' verified (rank Hz=Hx=%d, [Hz;Gx]=[Hx;Gz]=%d, cpu %.3fs): dX = dZ, both halves kept, lower bounds shared\n",
                           dm.maps[0].c_str(), dm.rank_hx, dm.rank_hxgz, dm.seconds);
                else
                    printf("c dualshare: no dual map (ranks Hz %d Hx %d [Hz;Gx] %d [Hx;Gz] %d, %d candidates, cpu %.3fs): both halves, no sharing\n",
                           dm.rank_hz, dm.rank_hx, dm.rank_hzgx, dm.rank_hxgz, dm.candidates, dm.seconds);
            }
            fflush(stdout);
        }
    }
    uint64_t implied = 0;   /* GH-107: probes main would issue whose NONE the other half already proved */
    /* GH-85: per-half verified orbits, detected once and used by every oracle call of that half. */
    for (int k = 0; symbreak && k < 2; k++) {
        if (!hs[k].exists) continue;
        HalfSymInfo info = find_half_symmetry(*hs[k].H, *hs[k].G);
        if (verb > 0) {
            char pre[32];
            snprintf(pre, sizeof(pre), "c symbreak %s:", hs[k].tag);
            print_half_symmetry(info, pre, false);
        }
        if ((int)info.reps.size() < info.n) hs[k].sb_orbit = info.orbit_of;
    }
    uint64_t U = INF, v = 0, lastLB = 0;
    uint64_t p1skips = 0;   /* GH-128: probes skipped because lb >= U */
    bool met = false;       /* GH-128: global lb = U reached (d proven) */
    /* Phase 1: doubling feasibility tests on both halves; anytime global LB. */
    for (uint64_t m = 1; ; m = (m >= n ? n : 2 * m)) {
        for (int k = 0; k < 2; k++) {
            CssHalf& h = hs[k];
            if (!h.exists || h.ub != INF || h.lb > m) {
                if (share && h.exists && h.ub == INF && h.lb > m && h.own_lb <= m) {   /* GH-107 */
                    implied++;
                    h.own_lb = m + 1;   /* the NONE main would have proven here */
                    if (verb > 0) printf("c dualshare: %s half cap %llu skipped (NONE implied, shared lb %llu)\n",
                                         h.tag, (unsigned long long)m, (unsigned long long)h.lb);
                }
                continue;
            }
            if (g_p1skip && U != INF && h.lb >= U) {   /* GH-128: cannot lower U; d unaffected (when every half
                                                          * has lb >= U this skips all remaining probes: d = U) */
                p1skips++;
                if (verb > 0) printf("c p1skip: %s half cap %llu skipped (lb %llu >= UB %llu)\n", h.tag,
                                     (unsigned long long)m, (unsigned long long)h.lb, (unsigned long long)U);
                continue;
            }
            HalfStatus st = run_css_half(h, m, true, verb, card_mode, pipe_w, INF, U, true, v);
            if (st == HALF_FOUND) { h.ub = v; if (v < U) { U = v; pipe_bound(pipe_w, "UB", U); } }
            else if (st == HALF_NONE) h.lb = h.own_lb = m + 1;
            else if (st == HALF_UNKNOWN) { pipe_write_result(pipe_w, -1, false); return -1; }
            if (share && !dualshare_sync(hs, U)) { pipe_write_result(pipe_w, -1, false); return -1; }
        }
        uint64_t glb = INF;
        bool any_ub = false, any = false;
        for (int k = 0; k < 2; k++) if (hs[k].exists) { any = true; if (hs[k].lb < glb) glb = hs[k].lb; if (hs[k].ub != INF) any_ub = true; }
        if (!any) die("no nontrivial logical operator in either half");
        if (glb != INF && glb > lastLB) { lastLB = glb; pipe_bound(pipe_w, "LB", glb); }
        if (g_p1skip && css_bounds_meet(hs, U)) met = true;   /* GH-128 */
        if (any_ub || m >= n) break;
    }
    if (met && verb > 0)
        printf("c p1skip: global lb %llu = UB %llu after Phase 1: d determined, no further probe\n",
               (unsigned long long)U, (unsigned long long)U);
    /* Phase 2a: tie-breaking probes for a logical of weight <= U-1 (stop at first), alternating
     * halves while their incumbents are equal.
     * FOUND improves the global UB; NONE proves the half cannot beat U, which finishes it. */
    bool done[2] = { !hs[0].exists, !hs[1].exists };
    uint64_t lastU = INF;
    /* Rounds while the two incumbents tie (no basis for ordering); each round probes both halves. */
    while (!done[0] && !done[1] && hs[0].ub == hs[1].ub) {
        for (int k = 0; k < 2; k++) {
            CssHalf& h = hs[k];
            if (done[k]) continue;
            if (h.lb >= U) {
                if (share && h.own_lb < U) {   /* GH-107 */
                    implied++;
                    if (verb > 0) printf("c dualshare: %s half cap %llu skipped (NONE implied, shared lb %llu)\n",
                                         h.tag, (unsigned long long)(U - 1), (unsigned long long)h.lb);
                }
                done[k] = true; continue;
            }
            uint64_t lbc = U;
            if (!share && !done[1 - k] && hs[1 - k].lb < lbc) lbc = hs[1 - k].lb;
            HalfStatus st = run_css_half(h, U - 1, true, verb, card_mode, pipe_w, lbc, U, false, v);
            if (st == HALF_FOUND) { h.ub = v; if (v < U) { U = v; pipe_bound(pipe_w, "UB", U); } }
            else if (st == HALF_NONE || st == HALF_INFEASIBLE) { h.lb = h.own_lb = (h.ub < U ? h.ub : U); done[k] = true; }
            else { pipe_write_result(pipe_w, -1, false); return -1; }
            if (share && !dualshare_sync(hs, U)) { pipe_write_result(pipe_w, -1, false); return -1; }
        }
    }
    (void)lastU;
    /* Phase 2b/3: optimise the unfinished halves in order of incumbent (smaller first), each with
     * cap U (find, then descend and prove); the second therefore only searches weight <= U. */
    for (int round = 0; round < 2; round++) {
        int k = -1;
        for (int j = 0; j < 2; j++)
            if (!done[j] && (k < 0 || hs[j].ub < hs[k].ub)) k = j;
        if (k < 0) break;
        CssHalf& h = hs[k];
        if (h.lb >= U) {
            if (share && h.own_lb < U) {   /* GH-107 */
                implied++;
                if (verb > 0) printf("c dualshare: %s half optimize cap %llu skipped (lb %llu = UB implied, shared)\n",
                                     h.tag, (unsigned long long)U, (unsigned long long)h.lb);
            }
            done[k] = true; continue;
        }
        uint64_t lbc = U;
        if (!share && !done[1 - k] && hs[1 - k].lb < lbc) lbc = hs[1 - k].lb;
        /* GH-87: with the Z half eliminated the X half holds the global incumbent itself, so its
         * optimisation only seeks weight <= U-1 (no re-find of its own incumbent): OPT improves U,
         * NONE proves lb = U. Without elimination (main, GH-107 share) the cap stays U exactly as in GH-73. */
        const uint64_t cap = (z_eliminated && h.ub == U) ? U - 1 : U;
        HalfStatus st = run_css_half(h, cap, false, verb, card_mode, pipe_w, lbc, U, false, v);
        if (st == HALF_OPT) { h.lb = h.ub = h.own_lb = v; if (v < U) { U = v; pipe_bound(pipe_w, "UB", U); } }
        else if (st == HALF_NONE || st == HALF_INFEASIBLE) { h.lb = h.own_lb = U; }
        else { pipe_write_result(pipe_w, -1, false); return -1; }
        done[k] = true;
        if (share && !dualshare_sync(hs, U)) { pipe_write_result(pipe_w, -1, false); return -1; }
        uint64_t glb = U;
        for (int j = 0; j < 2; j++) if (!done[j] && hs[j].lb < glb) glb = hs[j].lb;
        if (glb > lastLB) { lastLB = glb; pipe_bound(pipe_w, "LB", glb); }
    }
    if (verb > 0) printf("c CSS interleave: d = %llu\n", (unsigned long long)U);
    char p1buf[48] = "";   /* GH-128: the p1skips field appears only with -p1skip=on (off = main's line) */
    if (g_p1skip) snprintf(p1buf, sizeof(p1buf), " p1skips %llu", (unsigned long long)p1skips);
    if (stats)
        printf("c dualshare stats: mode %s map %d probes X %llu Z %llu conflicts X %llu Z %llu implied_skips %llu%s d %llu\n",
               dualmode == DUALMODE_OFF ? "off" : dualmode == DUALMODE_SKIP ? "skip" : "share", (int)(share || z_eliminated),
               (unsigned long long)hs[0].probes, (unsigned long long)hs[1].probes,
               (unsigned long long)hs[0].conflicts, (unsigned long long)hs[1].conflicts,
               (unsigned long long)implied, p1buf, (unsigned long long)U);
    pipe_bound(pipe_w, "LB", U);
    pipe_write_result(pipe_w, (int)U, true);
    return (int)U;
}

static bool g_css_joint = false;   /* -joint: original symplectic joint encoding */
static bool g_half_symbreak = true; /* GH-85: per-half orbit clauses in the split path; -no-symbreak disables */
static int g_dualmode = DUALMODE_SHARE; /* GH-107: -dualmode=share (default) | skip (GH-92) | off (main); -no-dualskip = off */
static bool g_dualshare_stats = false;  /* GH-107: -dualshare-stats prints one work-count line (with -v) */

/* ---- GH-124 (S0, experimental): connected-cluster (CC) level-search engine, src/cc/.
 * -engine=maxsat (default) runs main's search above unchanged; -engine=cc runs the exact CC level search
 * of src/cc/cc_driver.h on the same CSS split (X half: Hz x = 0, Gx x != 0; Z half: Hx z = 0, Gz z != 0;
 * d = min(dX, dZ)) and reports through the same pipe protocol (TRY / LB / UB / RESULT); -engine=auto routes
 * to cc unless a half's parity matrix is dense (cc_auto_select).
 * Symmetry input is DistQLDPC's own verified machinery: GH-85 per-half orbits (find_half_symmetry) as CC
 * seeds (orbf; -no-symbreak gives index seeds) and the GH-87/GH-107 verified XZ-dual map (find_dual_maps;
 * -cc-dual=on searches the X half only; -dualmode=off also disables it). */
enum { ENGINE_MAXSAT = 0, ENGINE_CC = 1, ENGINE_AUTO = 2 };
static int g_engine = ENGINE_MAXSAT;
static distcc::DriverOptions g_cc_opt;

static distcc::SparseRows cc_rows(const Matrix& M) {
    distcc::SparseRows R;
    R.cols = M.cols;
    R.rows.resize((size_t)M.rows);
    for (int r = 0; r < M.rows; r++)
        for (int c = 0; c < M.cols; c++)
            if (getm(M, r, c)) R.rows[r].push_back(c);
    return R;
}

static void cc_sink_bound(void* ctx, const char* kind, uint64_t v) { pipe_bound(*(int*)ctx, kind, v); }
static void cc_sink_result(void* ctx, int d, bool optimal) { pipe_write_result(*(int*)ctx, d, optimal); }
static void cc_sink_trap(void* ctx) {   /* withdraws the bounds already sent (parent: BoundsBook::trapped) */
    const int pw = *(int*)ctx;
    if (pw >= 0) (void)write(pw, "RESULT -1 TRAP\n", 15);
}

static int min_distance_css_cc(const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
                               int verb, int pipe_w, const distcc::DriverOptions& opt_in, bool symbreak, bool dual_allowed)
{
    if (Hx.cols != Hz.cols || Gx.cols != Hx.cols || Gz.cols != Hx.cols) die("matrix column mismatch");
    distcc::DriverOptions opt = opt_in;
    opt.verb = verb;
    distcc::DriverInput in;
    in.Hx = cc_rows(Hx); in.Hz = cc_rows(Hz); in.Gx = cc_rows(Gx); in.Gz = cc_rows(Gz);
    bool dual = false;
    if (opt.dual && dual_allowed && Gx.rows > 0 && Gz.rows > 0) {
        DualMapInfo dm = find_dual_maps(Hx, Hz, Gx, Gz, false);
        if (!dm.maps.empty()) {
            in.dual_perm = dm.perms[0];
            in.dual_desc = dm.maps[0];
            dual = true;
        }
        if (verb > 0) {
            if (dual)
                printf("c cc: dual map detection: '%s' verified (rank Hz=Hx=%d, [Hz;Gx]=[Hx;Gz]=%d, cpu %.3fs)\n",
                       dm.maps[0].c_str(), dm.rank_hx, dm.rank_hxgz, dm.seconds);
            else
                printf("c cc: dual map detection: none (ranks Hz %d Hx %d [Hz;Gx] %d [Hx;Gz] %d, %d candidates, cpu %.3fs): both halves\n",
                       dm.rank_hz, dm.rank_hx, dm.rank_hzgx, dm.rank_hxgz, dm.candidates, dm.seconds);
        }
    }
    if (opt.rules.orbf && symbreak) {
        for (int k = 0; k < 2; k++) {
            const Matrix& H = k == 0 ? Hz : Hx;
            const Matrix& G = k == 0 ? Gx : Gz;
            if (G.rows == 0 || (k == 1 && dual)) continue;   /* seeds only from per-half automorphisms of a searched half */
            HalfSymInfo info = find_half_symmetry(H, G);
            if (verb > 0) print_half_symmetry(info, k == 0 ? "c cc symbreak X:" : "c cc symbreak Z:", false);
            if ((int)info.reps.size() < info.n) in.orbit_of[k] = info.orbit_of;
        }
    }
    fflush(stdout);
    int pw = pipe_w;
    distcc::BoundSink sink;
    sink.ctx = &pw;
    sink.bound = cc_sink_bound;
    sink.result = cc_sink_result;
    sink.trap = cc_sink_trap;
    return distcc::min_distance_cc(in, opt, sink);
}

/* -engine=auto (GH-124 pre-S1 structural selector, not the default). CC unless the code is clearly dense:
 * MaxSAT iff, in the parity matrix H of some half that has logicals (X half: Hz, Z half: Hx),
 *   (a) some row has weight > CC_AUTO_MAX_ROW_WEIGHT (32), or
 *   (b) n >= 64 and the mean row weight exceeds n / 4 (relative row density > 25%).
 * Basis (optimization/experiments/GH-124/S0_REPORT.md section 5.5 and PRE_S1_NOTES.md): CC was never slower than
 * MaxSAT on toric and planar surface codes L = 6..32 (qubit degree 1-2, row weight <= 4), and on the 49
 * bundled codes (row weight 6..16, density <= 12.5% at n >= 64) it is at the process floor (tier0) or
 * 14x to > 1000x faster (tier1-5), so qubit degree is not a criterion. CC branches over the candidates of one odd row, so its per-level branching grows
 * with the row weight; dense codes were not calibrated, and they go to main's MaxSAT search. Both limits
 * leave a 2x margin over every calibrated code (max row weight 16, max density 12.5% at n >= 64). */
static const int CC_AUTO_MAX_ROW_WEIGHT = 32;

static bool cc_auto_select(const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz, std::string& why)
{
    char buf[200];
    std::string stats;
    bool cc = true;
    for (int k = 0; k < 2; k++) {
        const Matrix& H = k == 0 ? Hz : Hx;
        if ((k == 0 ? Gx : Gz).rows == 0) continue;
        long total = 0;
        int maxrow = 0;
        for (int r = 0; r < H.rows; r++) {
            int wt = 0;
            for (int c = 0; c < H.cols; c++) wt += getm(H, r, c);
            total += wt;
            if (wt > maxrow) maxrow = wt;
        }
        const double mean = H.rows > 0 ? (double)total / H.rows : 0.0;
        const bool heavy = maxrow > CC_AUTO_MAX_ROW_WEIGHT;
        const bool dense = H.cols >= 64 && mean * 4.0 > (double)H.cols;
        snprintf(buf, sizeof(buf), "%s%s half (%s): max row weight %d, mean %.2f, n %d%s%s", stats.empty() ? "" : "; ",
                 k == 0 ? "X" : "Z", k == 0 ? "Hz" : "Hx", maxrow, mean, H.cols,
                 heavy ? " [row weight > 32]" : "", dense ? " [mean row weight > n/4]" : "");
        stats += buf;
        if (heavy || dense) cc = false;
    }
    why = stats.empty() ? std::string("no half with logicals") : stats;
    why += cc ? ": sparse (max row weight <= 32, mean row weight <= n/4 or n < 64)" : ": dense";
    return cc;
}

/* GH-124: strict non-negative decimal integer (no sign, no trailing characters, no overflow). */
static bool cc_parse_uint(const char* s, unsigned long long* out)
{
    if (!s || *s < '0' || *s > '9') return false;
    errno = 0;
    char* end = NULL;
    const unsigned long long v = strtoull(s, &end, 10);
    if (errno != 0 || !end || *end != '\0') return false;
    *out = v;
    return true;
}

/* GH-124: engine-specific flags (exact spellings accepted by main's parser), used to reject combinations
 * that the selected engine would silently override or ignore.
 *   ENGFLAG_MAXSAT_FORM  MaxSAT formulation, backend or dump: refused with -engine=cc and -engine=auto
 *   ENGFLAG_MAXSAT_TUNE  MaxSAT tuning (cardinality encoding, -dualshare-stats): refused with -engine=cc;
 *                        with -engine=auto applied when auto selects maxsat (warning otherwise)
 *   ENGFLAG_CC           CC engine flags: refused with -engine=maxsat (and the default); with -engine=auto
 *                        applied when auto selects cc (warning otherwise)
 * -dualmode=off (no dual map), -no-symbreak (index seeds), -cpu-lim, -v/-q and the report flags are
 * shared by both engines. */
enum { ENGFLAG_NONE = 0, ENGFLAG_MAXSAT_FORM = 1, ENGFLAG_MAXSAT_TUNE = 2, ENGFLAG_CC = 3 };
static int engine_flag_family(const char* a)
{
    if (!strcmp(a, "-joint") || !strcmp(a, "-roundingsat") || !strncmp(a, "-roundingsat=", 13) ||
        !strncmp(a, "-dump-wcnf=", 11) || !strncmp(a, "-dump-opb=", 10) || !strcmp(a, "-dump-only") ||
        !strcmp(a, "-native-parity-opb"))
        return ENGFLAG_MAXSAT_FORM;
    if (!strcmp(a, "-no-card") || !strcmp(a, "-card-sinz") || !strcmp(a, "-card-mto") || !strcmp(a, "-card-both") ||
        !strcmp(a, "-card-both-force") || !strcmp(a, "-dualshare-stats"))
        return ENGFLAG_MAXSAT_TUNE;
    if (!strncmp(a, "-cc-", 4) || !strcmp(a, "-ub-basis") || !strncmp(a, "-ub-basis=", 10))
        return ENGFLAG_CC;
    return ENGFLAG_NONE;
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
    bool trapped;   /* GH-124: "RESULT -1 TRAP" (CC trap or other no-answer stop): earlier bounds withdrawn */

    BoundsBook()
        : has_lb(false), has_ub(false), lb(0), ub(0),
          distance(-1), optimal(false), finished(false), trapped(false) {}
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
        if (strcmp(line, "RESULT -1 TRAP") == 0) {   /* GH-124: only the CC engine sends this */
            b.trapped = true;
            b.has_lb = false;
            b.has_ub = false;
        }
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
        /* GH-124: -cc-stats lines of the CC engine stay visible without -v */
        if (verb == 0 && backend == SOLVER_MAXCDCL && !(g_engine == ENGINE_CC && g_cc_opt.stats)) {
            int devnull = open("/dev/null", O_WRONLY);
            if (devnull >= 0) {
                dup2(devnull, STDOUT_FILENO);
                close(devnull);
            }
        }
        int d;
        if (g_engine == ENGINE_CC) {   /* GH-124 (experimental); -engine=maxsat (default) takes the paths below */
            d = min_distance_css_cc(Hx, Hz, Gx, Gz, verb, pipefd[1], g_cc_opt, g_half_symbreak, g_dualmode != DUALMODE_OFF);
        } else if (backend == SOLVER_ROUNDINGSAT) {
            d = min_distance_stabilizer_roundingsat(
                Hx, Hz, Gx, Gz, verb, pipefd[1], roundingsat_bin, dump_wcnf_path);
        } else if (!g_css_joint) {
            d = min_distance_css_interleaved(Hx, Hz, Gx, Gz, verb, pipefd[1], card_mode, g_half_symbreak, g_dualmode, g_dualshare_stats);
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

/* Bare code name (no '/'): data/matrices/<code> if <code>_Hx.txt exists there, else the
 * first of data/matrices/tier0 .. tier5 that has it; if none, data/matrices/<code> (so the
 * load error names the old flat path). Arguments containing '/' are returned unchanged. */
static std::string resolve_prefix(const char* prefix) {
    std::string p(prefix);
    if (p.find('/') != std::string::npos)
        return p;
    std::string flat = std::string("data/matrices/") + p;
    if (access((flat + "_Hx.txt").c_str(), F_OK) == 0)
        return flat;
    for (int t = 0; t <= 5; t++) {
        std::string cand = std::string("data/matrices/tier") + std::to_string(t) + "/" + p;
        if (access((cand + "_Hx.txt").c_str(), F_OK) == 0)
            return cand;
    }
    return flat;
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
    bool symbreak_report = false;  /* GH-85 */
    bool dualskip_report = false;  /* GH-87 */
    bool seed_given = false, cc_seed_given = false;   /* GH-124: -seed=N, -cc-seed=N */

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
        else if (!strcmp(argv[i], "-no-symbreak"))
            g_half_symbreak = false;
        else if (!strcmp(argv[i], "-symbreak-report"))
            symbreak_report = true;
        else if (!strcmp(argv[i], "-no-dualskip") || !strcmp(argv[i], "-dualmode=off"))
            g_dualmode = DUALMODE_OFF;
        else if (!strcmp(argv[i], "-dualmode=share"))
            g_dualmode = DUALMODE_SHARE;
        else if (!strcmp(argv[i], "-dualmode=skip"))
            g_dualmode = DUALMODE_SKIP;
        else if (!strncmp(argv[i], "-dualmode=", 10))
            die("invalid -dualmode (share | skip | off)");
        else if (!strcmp(argv[i], "-dualshare-stats"))
            g_dualshare_stats = true;
        else if (!strcmp(argv[i], "-p1skip=on"))   /* GH-128 */
            g_p1skip = true;
        else if (!strcmp(argv[i], "-p1skip=off"))
            g_p1skip = false;
        else if (!strncmp(argv[i], "-p1skip=", 8))
            die("invalid -p1skip (on | off)");
        else if (!strcmp(argv[i], "-dualskip-report"))
            dualskip_report = true;
        else if (!strcmp(argv[i], "-engine=maxsat"))   /* GH-124 */
            g_engine = ENGINE_MAXSAT;
        else if (!strcmp(argv[i], "-engine=cc"))
            g_engine = ENGINE_CC;
        else if (!strcmp(argv[i], "-engine=auto"))
            g_engine = ENGINE_AUTO;
        else if (!strncmp(argv[i], "-engine=", 8))
            die("invalid -engine (maxsat | cc | auto)");
        else if (!strncmp(argv[i], "-cc-rules=", 10)) {
            if (!distcc::parse_rules(argv[i] + 10, g_cc_opt.rules))
                die("invalid -cc-rules (comma list of excl, pack, orbf, mrv, or none)");
        } else if (!strcmp(argv[i], "-cc-dual=on"))
            g_cc_opt.dual = true;
        else if (!strcmp(argv[i], "-cc-dual=off"))
            g_cc_opt.dual = false;
        else if (!strncmp(argv[i], "-cc-dual=", 9))
            die("invalid -cc-dual (on | off)");
        else if (!strcmp(argv[i], "-ub-basis") || !strcmp(argv[i], "-ub-basis=on"))
            g_cc_opt.ub_basis = true;
        else if (!strcmp(argv[i], "-ub-basis=off"))
            g_cc_opt.ub_basis = false;
        else if (!strncmp(argv[i], "-ub-basis=", 10))
            die("invalid -ub-basis (on | off)");
        else if (!strncmp(argv[i], "-seed=", 6)) {   /* GH-124: timing seed for either engine */
            unsigned long long v = 0;
            if (!cc_parse_uint(argv[i] + 6, &v)) die("invalid -seed (non-negative integer)");
            g_seed = (uint64_t)v;
            seed_given = true;
        } else if (!strncmp(argv[i], "-cc-seed=", 9)) {
            unsigned long long v = 0;
            if (!cc_parse_uint(argv[i] + 9, &v)) die("invalid -cc-seed (non-negative integer)");
            g_cc_opt.seed = (uint64_t)v;
            cc_seed_given = true;
        } else if (!strncmp(argv[i], "-cc-mutant=", 11)) {
            unsigned long long v = 0;
            if (!cc_parse_uint(argv[i] + 11, &v) || v > 4) die("invalid -cc-mutant (0..4, test only)");
            g_cc_opt.mutant = (int)v;
        } else if (!strncmp(argv[i], "-cc-trace=", 10)) {
            g_cc_opt.trace_path = argv[i] + 10;
            if (g_cc_opt.trace_path.empty()) die("invalid -cc-trace (needs a file name)");
        } else if (!strcmp(argv[i], "-cc-stats"))
            g_cc_opt.stats = true;
        else if (!strcmp(argv[i], "-cc-schedule=lockstep"))   /* test only */
            g_cc_opt.sequential = false;
        else if (!strcmp(argv[i], "-cc-schedule=sequential"))
            g_cc_opt.sequential = true;
        else if (!strncmp(argv[i], "-cc-schedule=", 13))
            die("invalid -cc-schedule (lockstep | sequential, test only)");
        else if (!strncmp(argv[i], "-cc-", 4))
            die("unknown -cc- option (see --help)");
        else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
            printf("Usage: %s [options] <code>\n", argv[0]);
            printf("  <code>  e.g. LP_34_20_2  (loads data/matrices/[tierN/]<code>_{Hx,Hz,Gx,Gz}.txt;\n");
            printf("          flat dir first, then tier0..tier5; a path containing '/' is used as given)\n");
            printf("  Distance: min Pauli weight in S^perp \\\\ S (symplectic MaxSAT).\n");
            printf("  Options: -cpu-lim=N  -v|-debug  -q  -dump-wcnf=PATH  -dump-opb=PATH  -dump-only\n");
            printf("           -native-parity-opb  GF(2) parity as PB equalities (OPB dump only)\n");
            printf("  Solver: default MaxCDCL; -roundingsat[=BIN] uses external RoundingSat on WCNF\n");
            printf("  Cardinality: default Sinz+MTO (Sinz if n<=100); -no-card | -card-sinz | -card-mto\n");
            printf("               -card-both-force  always Sinz+MTO regardless of n\n");
            printf("  Formulation: default CSS split d=min(dX,dZ), interleaved bound search; -joint = original symplectic joint encoding\n");
            printf("  Symmetry (split only): default adds optimum-preserving orbit clauses per CSS half from\n");
            printf("            verified half automorphisms; -no-symbreak disables them;\n");
            printf("            -symbreak-report prints per-half generators/orbits and exits\n");
            printf("  Dual halves (split only): when a verified XZ-dual qubit permutation proves dX = dZ,\n");
            printf("            -dualmode=share (default) keeps both halves and shares proven lower bounds\n");
            printf("            (implied NONE probes skipped); -dualmode=skip solves only the X half;\n");
            printf("            -dualmode=off (alias -no-dualskip) ignores dual maps; -dualshare-stats prints\n");
            printf("            work counts (with -v); -dualskip-report prints the verified dual maps and exits\n");
            printf("  Redundant probes (GH-128, split MaxSAT path): -p1skip=on (default) skips a half's probe once its\n");
            printf("            proven lb >= the global UB and stops as soon as the global lb equals the UB; -p1skip=off\n");
            printf("            = main abd1770's probe sequence\n");
            printf("  Engine (GH-124, experimental): -engine=maxsat (default, the MaxSAT search above) | cc | auto\n");
            printf("            cc = exact connected-cluster level search per CSS half (src/cc); auto = cc unless a\n");
            printf("            half's parity matrix is dense (a row weight > 32, or mean row weight > n/4 with n >= 64)\n");
            printf("            -cc-rules=excl,pack,orbf[,mrv] (default excl,pack,orbf; 'none' = plain CC)\n");
            printf("            -cc-dual=on|off (default on: verified XZ-dual map -> X half only)\n");
            printf("            -ub-basis[=on|off]  verified logical basis rows as initial upper bound (default on)\n");
            printf("            -cc-seed=N relabel qubits/rows (default 0 = identity); -cc-trace=FILE; -cc-stats\n");
            printf("  Seed (both engines): -seed=N (default 0 = main's search): MaxCDCL random seed on the MaxSAT\n");
            printf("            path; with the CC engine the same as -cc-seed=N\n");
            printf("            -cc-mutant=K deliberately broken variant for tests only (K = 1..4)\n");
            printf("            -cc-schedule=lockstep|sequential half schedule, tests only (default lockstep)\n");
            printf("            Conflicts are rejected: -cc-*/-ub-basis need -engine=cc|auto; -engine=cc|auto refuse\n");
            printf("            -joint, -roundingsat, -dump-*, -native-parity-opb; -engine=cc refuses the\n");
            printf("            cardinality flags and -dualshare-stats (auto warns when its choice ignores a flag)\n");
            printf("  Output (default): live c trying d / c d_lb / c d_ub, then c d / o d\n");
            printf("  -v / -debug: solver search log and matrix paths\n");
            printf("  Solver runs in forked child; bounds sync via pipe; hard kill on timeout.\n");
            return 0;
        } else if (!prefix)
            prefix = argv[i];
        else
            die("unexpected argument");
    }

    /* GH-124: conflicting engine flags are rejected (see engine_flag_family); without any -engine= or CC
     * flag nothing below fires, so the default path is main's */
    std::string auto_ignored_by_cc, auto_ignored_by_maxsat;
    {
        std::string fam[4];
        for (int i = 1; i < argc; i++) {
            const int f = engine_flag_family(argv[i]);
            if (f == ENGFLAG_NONE) continue;
            if (!fam[f].empty()) fam[f] += " ";
            fam[f] += argv[i];
        }
        const char* ename = g_engine == ENGINE_CC ? "cc" : g_engine == ENGINE_AUTO ? "auto" : "maxsat";
        std::string msg;
        if (g_engine == ENGINE_MAXSAT && !fam[ENGFLAG_CC].empty())
            msg = fam[ENGFLAG_CC] + ": CC engine option(s) need -engine=cc or -engine=auto (the default engine is maxsat)";
        else if (g_engine != ENGINE_MAXSAT && !fam[ENGFLAG_MAXSAT_FORM].empty())
            msg = fam[ENGFLAG_MAXSAT_FORM] + ": MaxSAT formulation/backend/dump option(s) cannot be combined with -engine=" +
                  ename + " (use -engine=maxsat)";
        else if (g_engine == ENGINE_CC && !fam[ENGFLAG_MAXSAT_TUNE].empty())
            msg = fam[ENGFLAG_MAXSAT_TUNE] + ": MaxSAT option(s) have no effect with -engine=cc (use -engine=maxsat or -engine=auto)";
        if (msg.empty() && seed_given && backend == SOLVER_ROUNDINGSAT)
            msg = "-seed: no effect with -roundingsat (it seeds MaxCDCL or the CC engine)";
        if (msg.empty() && seed_given && cc_seed_given && g_seed != g_cc_opt.seed)
            msg = "-seed and -cc-seed give different seeds (-cc-seed is an alias of -seed for the CC engine)";
        if (!msg.empty()) die(msg.c_str());
        if (seed_given) g_cc_opt.seed = g_seed;   /* one flag seeds both engines (-cc-seed: CC only) */
        auto_ignored_by_cc = fam[ENGFLAG_MAXSAT_TUNE];
        auto_ignored_by_maxsat = fam[ENGFLAG_CC];
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

    if (symbreak_report) {   /* GH-85 */
        if (Hz.cols != Hx.cols || Gx.cols != Hx.cols || Gz.cols != Hx.cols)
            die("matrix column mismatch");
        printf("c symbreak report: %s\n", prefix);
        if (Gx.rows > 0) print_half_symmetry(find_half_symmetry(Hz, Gx), "c symbreak X:", true);
        else printf("c symbreak X: no logical rows (half absent)\n");
        if (Gz.rows > 0) print_half_symmetry(find_half_symmetry(Hx, Gz), "c symbreak Z:", true);
        else printf("c symbreak Z: no logical rows (half absent)\n");
        if (!dualskip_report) return 0;
    }

    if (dualskip_report) {   /* GH-87 */
        if (Hz.cols != Hx.cols || Gx.cols != Hx.cols || Gz.cols != Hx.cols)
            die("matrix column mismatch");
        printf("c dualskip report: %s\n", prefix);
        if (Gx.rows == 0 || Gz.rows == 0) {
            printf("c dualskip: a half has no logical rows (Gx %d, Gz %d): not applicable\n", Gx.rows, Gz.rows);
            return 0;
        }
        DualMapInfo dm = find_dual_maps(Hx, Hz, Gx, Gz, true);
        printf("c dualskip: n=%d rank Hz=%d Hx=%d [Hz;Gx]=%d [Hx;Gz]=%d candidates=%d verified_maps=%zu detect_cpu=%.3fs used=%s\n",
               dm.n, dm.rank_hz, dm.rank_hx, dm.rank_hzgx, dm.rank_hxgz, dm.candidates, dm.maps.size(), dm.seconds,
               dm.maps.empty() ? "none" : dm.maps[0].c_str());
        for (size_t k = 0; k < dm.maps.size(); k++) printf("c dualskip map: %s\n", dm.maps[k].c_str());
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

    std::string engine_why;   /* GH-124 */
    const bool engine_auto = g_engine == ENGINE_AUTO;
    if (engine_auto) {
        if (Hz.cols != Hx.cols || Gx.cols != Hx.cols || Gz.cols != Hx.cols)
            die("matrix column mismatch");
        g_engine = cc_auto_select(Hx, Hz, Gx, Gz, engine_why) ? ENGINE_CC : ENGINE_MAXSAT;
        const std::string& ignored = g_engine == ENGINE_CC ? auto_ignored_by_cc : auto_ignored_by_maxsat;
        if (!ignored.empty())
            fprintf(stderr, "warning: -engine=auto selected %s (%s); ignoring %s\n",
                    g_engine == ENGINE_CC ? "cc" : "maxsat", engine_why.c_str(), ignored.c_str());
    }

    if (verb > 0) {
        if (g_engine == ENGINE_CC)   /* GH-124; the MaxSAT banner below is main's */
            printf("c DistQLDPC — QLDPC/CSS minimum distance (connected-cluster level search)\n");
        else
            printf("c DistQLDPC — QLDPC/CSS minimum distance (symplectic MaxSAT)\n");
        if (engine_auto)
            printf("c engine: auto -> %s (%s)\n", g_engine == ENGINE_CC ? "cc" : "maxsat", engine_why.c_str());
        if (g_engine == ENGINE_CC)
            printf("c solver: CC connected-cluster level search (GH-124, experimental), rules %s, cc-seed %llu%s\n",
                   distcc::rules_string(g_cc_opt.rules).c_str(), (unsigned long long)g_cc_opt.seed,
                   g_cc_opt.mutant ? " [TEST MUTANT]" : "");
        else if (backend == SOLVER_ROUNDINGSAT)
            printf("c solver: RoundingSat (%s)\n", roundingsat_bin);
        else if (g_seed != 0)   /* GH-124 -seed=N; without it (or with N = 0) the line is main's */
            printf("c solver: MaxCDCL, cardinality encoding: %s, seed %llu (rnd-seed %.0f)\n", cardinality_mode_label(card_mode),
                   (unsigned long long)g_seed, maxsat_random_seed(g_seed));
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
    else if (book.trapped)   /* GH-124 */
        printf("c status: UNKNOWN (CC engine stopped without an answer: earlier d_lb/d_ub lines withdrawn)\n");
    else
        printf("c status: UNKNOWN\n");
    printf("c d  : UNKNOWN\n");
    printf("s UNKNOWN\n");
    return 1;
}
