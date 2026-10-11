// GH-89 test: GH-76 persistent per-half solver WITH GH-85 per-half orbit clauses, against exhaustive enumeration.
// Drives the production code (src/core/distqldpc.cc is included verbatim, its main() renamed):
// find_half_symmetry -> CssHalf.sb_orbit -> run_css_half (css_half_build adds the orbit clauses once at
// construction and on every INC_REBUILD; incProbe answers every probe of the half).
// Random small half instances (Hpar v = 0, Glog v != 0, minimise |v|) whose row spaces are closed under a
// planted qubit permutation group drawn from the GH-75/GH-85 candidate family (full cyclic shift -> transitive
// -> unit clause; block / strided shifts -> orbit chain), plus unstructured instances (control).
// Probe schedules follow the CSS-split driver (doubling feasibility caps, forced raise after a solution ->
// rebuild, tie-break / random / capped optimisation probes, re-asking after completion), all four cardinality modes.
// Every answer is checked against the half WITHOUT symmetry clauses: NONE => optimum > cap; FOUND/OPT =>
// witness (independently re-checked here) solves the half with the reported weight, value <= cap;
// OPT => value == optimum. Also checked: the optimum restricted to the orbit predicate equals the optimum
// (GH-85's every-w claim, by enumeration) and the verified group contains the planted generators.
// Each instance runs with symmetry clauses (candidate) and without (GH-76 control).
// GH-106: optional argv[2] = half-solver policy (gh89 | postsol | feasfresh | fresh; default gh89, which keeps
// GH-89's counts); the policy decides inside the production run_css_half when a half gets a fresh solver.
// Engine output goes to stdout; the verdict goes to stderr.
#define main distqldpc_main_unused
#include "../src/core/distqldpc.cc"
#undef main

#include <set>

static unsigned long long rng_state = 0x2545f4914f6cdd1dULL;
static unsigned rnd(unsigned m) {
    rng_state ^= rng_state << 13; rng_state ^= rng_state >> 7; rng_state ^= rng_state << 17;
    return (unsigned)(rng_state % m);
}
static int fails = 0;
static void need(bool x, const char* why, int inst, bool sb) {
    if (!x) { fprintf(stderr, "GH89_SYMBREAK_INC_FAIL inst=%d sb=%d %s\n", inst, (int)sb, why); fails++; }
}

typedef unsigned Mask;
static Mask apply(const std::vector<int>& p, Mask v) {
    Mask w = 0;
    for (size_t i = 0; i < p.size(); i++) if ((v >> i) & 1) w |= 1u << p[i];
    return w;
}
static Matrix to_matrix(const std::vector<Mask>& rows, int n) {
    Matrix m; m.rows = (int)rows.size(); m.cols = n; m.data.assign((size_t)m.rows * n, 0);
    for (int r = 0; r < m.rows; r++) for (int c = 0; c < n; c++) m.data[(size_t)r * n + c] = (rows[r] >> c) & 1;
    return m;
}
static bool odd(Mask x) { return __builtin_popcount(x) & 1; }
static bool feasible(const std::vector<Mask>& H, const std::vector<Mask>& G, Mask v) {
    for (Mask h : H) if (odd(h & v)) return false;
    for (Mask g : G) if (odd(g & v)) return true;
    return false;
}
// GH-85 orbit predicate (semantics of the unit / orbit-chain clauses): v = 0, or the first orbit met
// (orbits ordered by minimum) contains its representative in supp v.
static bool orbit_pred(const std::vector<int>& orb, int n, Mask v) {
    if (orb.empty()) return true;
    for (int i = 0; i < n; i++) if ((v >> i) & 1) {
        // first met orbit = orbit with the smallest representative among those met
        int best = orb[i];
        for (int j = i + 1; j < n; j++) if (((v >> j) & 1) && orb[j] < best) best = orb[j];
        return (v >> best) & 1;
    }
    return true;
}

// Planted generators: the same index maps as GH-75/GH-85's symmetry_candidates (so detection must find them).
static std::vector<int> blockshift(int n, int L) { std::vector<int> p(n); for (int i = 0; i < n; i++) p[i] = (i / L) * L + ((i % L) + 1) % L; return p; }
static std::vector<int> stridedshift(int n, int L) { const int B = n / L; std::vector<int> p(n); for (int i = 0; i < n; i++) p[i] = (((i / B) + 1) % L) * B + (i % B); return p; }

static std::vector<Mask> closure(std::vector<Mask> seeds, const std::vector<std::vector<int> >& gens) {
    std::set<Mask> seen; std::vector<Mask> out, todo(seeds);
    while (!todo.empty()) {
        Mask v = todo.back(); todo.pop_back();
        if (!v || seen.count(v)) continue;
        seen.insert(v); out.push_back(v);
        for (const auto& g : gens) todo.push_back(apply(g, v));
    }
    return out;
}

int main(int argc, char** argv) {
    const int N = argc > 1 ? atoi(argv[1]) : 2000;
    g_inc_policy = INC_POLICY_GH89;   // GH-106: the GH-89 control unless a policy is given
    if (argc > 2 && !parse_inc_policy(argv[2], g_inc_policy)) { fprintf(stderr, "unknown policy %s\n", argv[2]); return 2; }
    // GH-106 v2: optional argv[3] = budget factor, argv[4] = budget floor (small values exercise the budget fallback)
    if (argc > 3) g_inc_budget_factor = (uint64_t)atoi(argv[3]);
    if (argc > 4) g_inc_budget_floor = (uint64_t)atoi(argv[4]);
    long probes = 0, found = 0, opts = 0, nones = 0, infeasible = 0, rebuilds = 0, unsat = 0;
    long sym_none = 0, sym_unit = 0, sym_chain = 0;
    for (int inst = 0; inst < N; inst++) {
        // n in 4..16 with a planted group (3 of 4 instances) or none
        int n = 4 + (int)rnd(13);
        const int card = (int)rnd(4);   // cardinality encoding: off / Sinz+MTO / Sinz / MTO
        std::vector<std::vector<int> > gens;
        const unsigned kind = rnd(4);
        if (kind != 3) {
            std::vector<int> divs;
            for (int L = 2; L <= n; L++) if (n % L == 0) divs.push_back(L);
            int L = kind == 0 ? n : divs[rnd((unsigned)divs.size())];
            gens.push_back(kind == 2 ? stridedshift(n, L) : blockshift(n, L));
            if (rnd(3) == 0) { int L2 = divs[rnd((unsigned)divs.size())]; gens.push_back(rnd(2) ? stridedshift(n, L2) : blockshift(n, L2)); }
        }
        std::vector<Mask> hs, gs;
        int nh = (int)rnd(3), ng = 1 + (int)rnd(2);
        for (int k = 0; k < nh; k++) { Mask v = 0; int w = 2 + (int)rnd(3); for (int j = 0; j < w; j++) v |= 1u << rnd(n); hs.push_back(v); }
        for (int k = 0; k < ng; k++) { Mask v = 0; int w = 1 + (int)rnd(n); for (int j = 0; j < w; j++) v |= 1u << rnd(n); gs.push_back(v); }
        std::vector<Mask> H = closure(hs, gens), G = closure(gs, gens);
        if (G.empty()) G.push_back(1u << rnd(n));
        if (H.size() > 40) H.resize(40);   // keep enumeration cheap; truncation may break the planted symmetry
        const Matrix Hm = to_matrix(H, n), Gm = to_matrix(G, n);

        int opt = -1;
        for (Mask v = 1; v < (1u << n); v++) if (feasible(H, G, v)) { int w = __builtin_popcount(v); if (opt < 0 || w < opt) opt = w; }

        HalfSymInfo info = find_half_symmetry(Hm, Gm);
        std::vector<int> orb;
        if ((int)info.reps.size() < n) orb = info.orbit_of;
        if (orb.empty()) sym_none++; else if (info.reps.size() == 1) sym_unit++; else sym_chain++;
        // independent re-check of every verified generator (a qubit permutation keeping the half feasible set
        // and weights): checked by enumeration on the feasible set; and planted generators must be in the group
        if (!orb.empty()) {
            int opt_sb = -1;
            for (Mask v = 1; v < (1u << n); v++)
                if (feasible(H, G, v) && orbit_pred(orb, n, v)) { int w = __builtin_popcount(v); if (opt_sb < 0 || w < opt_sb) opt_sb = w; }
            need(opt_sb == opt, "optimum under orbit predicate != optimum", inst, true);
            if (H.size() < 40)
                for (const auto& g : gens) for (int i = 0; i < n; i++)
                    need(info.orbit_of[i] == info.orbit_of[g[i]], "planted generator not in verified group", inst, true);
        }

        for (int pass = 0; pass < 2; pass++) {
            const bool sb = pass == 0;
            CssHalf h = { "T", &Hm, &Gm, true, 1, UINT64_MAX, NULL, 0, 0 };
            g_inc_conflicts_total = 0;   // GH-106 v2: one "run" per half instance for the budgettot policy
            if (sb) h.sb_orbit = orb;
            const uint64_t maxc = (uint64_t)n;
            uint64_t lb = 0, ub = UINT64_MAX, v = 0;
            auto probe = [&](uint64_t cap, bool first) -> HalfStatus {
                h.lb = lb > 1 ? lb : 1;   // the driver's proven half LB (>= 1: v != 0)
                const int b0 = h.builds;
                HalfStatus st = run_css_half(h, cap, first, 0, card, -1, UINT64_MAX, UINT64_MAX, true, v);
                probes++;
                if (h.builds > b0 + (b0 == 0 ? 1 : 0)) rebuilds++;
                if (st == HALF_INFEASIBLE) { infeasible++; need(opt < 0, "INFEASIBLE but a logical exists", inst, sb); }
                else if (st == HALF_NONE) { nones++; need(opt < 0 || (uint64_t)opt > cap, "NONE but optimum <= cap", inst, sb); if (cap + 1 > lb) lb = cap + 1; }
                else if (st == HALF_FOUND || st == HALF_OPT) {
                    need(opt >= 0 && v <= cap && v >= (uint64_t)opt, "FOUND/OPT value out of range", inst, sb);
                    Mask m = 0; bool def = h.S && h.S->model.size() >= n;
                    for (int i = 0; def && i < n; i++) { if (h.S->model[i] == l_Undef) def = false; else if (h.S->model[i] == l_True) m |= 1u << i; }
                    need(def && feasible(H, G, m) && (uint64_t)__builtin_popcount(m) == v, "witness invalid", inst, sb);
                    if (st == HALF_OPT) { opts++; need(!first, "OPT for first-only probe", inst, sb); need((int)v == opt, "OPT != optimum", inst, sb); lb = v; }
                    else { found++; need(first, "FOUND for optimisation probe", inst, sb); }
                    if (v < ub) ub = v;
                }
                else need(false, "UNKNOWN (interrupted or witness check failed)", inst, sb);
                return st;
            };
            HalfStatus st0 = HALF_UNKNOWN;
            for (uint64_t m = 1; ; m = (m >= maxc ? maxc : 2 * m)) {
                if (lb > m) { if (m >= maxc) break; continue; }
                st0 = probe(m, true);
                if (st0 == HALF_FOUND || st0 == HALF_INFEASIBLE || m >= maxc) break;
            }
            if (st0 == HALF_INFEASIBLE) { if (sb) unsat++; continue; }
            if (ub != UINT64_MAX && ub > lb + 1 && rnd(2)) { probe(lb > 1 ? lb : 1, true); if (lb < ub) probe(ub - 1, true); }
            for (int step = 0; step < 6 && ub != UINT64_MAX && lb < ub; step++) {
                unsigned k = rnd(3);
                if (k == 0) probe(ub - 1, true);
                else if (k == 1) probe(lb + rnd((unsigned)(ub - lb)), true);
                else probe(lb + rnd((unsigned)(ub - lb + 1)), false);
            }
            if (ub != UINT64_MAX && lb < ub) probe(ub, false);
            if (ub == UINT64_MAX) need(opt < 0, "no solution found on a satisfiable half", inst, sb);
            else need((int)ub == opt && lb >= ub, "final bounds != optimum", inst, sb);
            if (ub != UINT64_MAX && ub > 1) { lb = 0; probe(ub - 1, true); probe(ub, false); }
            delete h.S;
        }
    }
    fprintf(stderr, "GH89_SYMBREAK_INC_%s instances=%d unsat=%ld sym(none/unit/chain)=%ld/%ld/%ld probes=%ld found=%ld opt=%ld none=%ld infeasible=%ld rebuilds=%ld failures=%d\n",
            fails ? "FAIL" : "PASS", N, unsat, sym_none, sym_unit, sym_chain, probes, found, opts, nones, infeasible, rebuilds, fails);
    if (g_inc_policy != INC_POLICY_GH89) fprintf(stderr, "GH106_POLICY %s budget_factor=%llu budget_floor=%llu (rebuilds include policy rebuilds)\n", inc_policy_name(g_inc_policy),
                                                 (unsigned long long)g_inc_budget_factor, (unsigned long long)g_inc_budget_floor);
    return fails ? 1 : 0;
}
