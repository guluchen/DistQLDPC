// GH-76 test: sequences of Solver::incProbe() on one persistent instance against exhaustive enumeration.
// Random small weighted-unit-soft instances (all soft weights 1, as in DistQLDPC); probe schedules follow the
// CSS-split driver (doubling feasibility caps before the first solution, tie-break and capped optimisation
// probes after it) and also request forbidden raises after a solution to exercise INC_REBUILD.
// Every answer is checked: NONE => optimum > cap; FOUND/OPT => witness satisfies all hard clauses, its
// violated-soft count equals the reported value, value <= cap; OPT => value == optimum.
// GH-106: optional argv[2] = half-solver policy emulated by the probe driver exactly as in
// src/core/distqldpc.cc run_css_half (gh89: never rebuild; postsol: fresh instance while !feasible;
// feasfresh: also before every first-only probe; fresh: before every probe; atcap: postsol + fresh after a FOUND
// exactly at its cap; atcapfeas: same, feasibility probes only; budget: postsol + a conflict budget on post-solution
// feasibility probes of a kept solver, factor argv[3] (default 4) x the most conflicts of a fresh probe, floor
// argv[4] (default 2000; small values exercise the interrupt-and-rebuild path); budgettot: the same with factor x all
// conflicts spent so far on this instance's probes. Default gh89 = GH-76 counts.
// Engine output goes to stdout; the verdict goes to stderr.
#include "SimpSolver.h"
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <vector>
using namespace Minisat;

typedef std::vector<std::vector<int> > Cnf;   // literals as +-(var+1)
static unsigned long long rng = 0x9e3779b97f4a7c15ULL;
static unsigned rnd(unsigned m) { rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17; return (unsigned)(rng % m); }
static int fails = 0;
static void need(bool x, const char* why, int inst) {
    if (!x) { std::fprintf(stderr, "GH76_INCREMENTAL_FAIL inst=%d %s\n", inst, why); fails++; }
}

struct Inst { int n; Cnf hard, soft; };

static bool satc(const std::vector<int>& c, unsigned m) {
    for (int l : c) { bool v = (m >> (abs(l) - 1)) & 1; if ((l > 0) == v) return true; }
    return false;
}
static int optimum(const Inst& I) {   // -1: no hard model
    int best = -1;
    for (unsigned m = 0; m < (1u << I.n); m++) {
        bool ok = true;
        for (const auto& c : I.hard) if (!satc(c, m)) { ok = false; break; }
        if (!ok) continue;
        int cost = 0;
        for (const auto& c : I.soft) cost += !satc(c, m);
        if (best < 0 || cost < best) best = cost;
    }
    return best;
}
static SimpSolver* build(const Inst& I, bool& prepared) {
    SimpSolver* S = new SimpSolver;
    S->parsing = true; S->verbosity = 0; S->instanceType = 1;
    S->hardWeight = (unsigned)(I.soft.size() + 64); S->UB = S->hardWeight; S->initUB = INT32_MAX; S->nbOriVars = I.n;
    while (S->nVars() < I.n) S->newVar();
    bool ok = true;
    for (int pass = 0; pass < 2 && ok; pass++)
        for (const auto& c : (pass == 0 ? I.hard : I.soft)) {
            vec<Lit> ps; for (int l : c) ps.push(mkLit(abs(l) - 1, l < 0));
            if (!S->addClause_(ps, pass == 0 ? S->hardWeight : 1)) { ok = false; break; }
        }
    prepared = false;
    if (ok) { S->parsing = false; S->setFrozenVars(); S->eliminate(true); prepared = S->okay() && S->incPrepare(); }
    return S;
}
static void checkWitness(const Inst& I, const SimpSolver& S, uint64_t v, int inst) {
    unsigned m = 0;
    for (int i = 0; i < I.n; i++) {
        if (S.model.size() <= i || S.model[i] == l_Undef) { need(false, "undefined witness", inst); return; }
        if (S.model[i] == l_True) m |= 1u << i;
    }
    for (const auto& c : I.hard) if (!satc(c, m)) { need(false, "witness violates hard clause", inst); return; }
    int cost = 0; for (const auto& c : I.soft) cost += !satc(c, m);
    need((uint64_t)cost == v, "witness cost != reported value", inst);
}

int main(int argc, char** argv) {
    int N = argc > 1 ? atoi(argv[1]) : 3000;
    const char* policy = argc > 2 ? argv[2] : "gh89";
    const char* names[8] = { "gh89", "postsol", "feasfresh", "fresh", "atcap", "atcapfeas", "budget", "budgettot" };
    int pol = -1;
    for (int i = 0; i < 8; i++) if (!strcmp(policy, names[i])) pol = i;
    if (pol < 0) { std::fprintf(stderr, "unknown policy %s\n", policy); return 2; }
    const uint64_t bfactor = argc > 3 ? (uint64_t)atoi(argv[3]) : 4, bfloor = argc > 4 ? (uint64_t)atoi(argv[4]) : 2000;
    long policy_builds = 0, budget_fallbacks = 0;
    long probes = 0, rebuilds = 0, found = 0, opts = 0, nones = 0, unsat = 0;
    for (int inst = 0; inst < N; inst++) {
        Inst I; I.n = 3 + rnd(14);
        int nh = rnd(3 * I.n);
        const unsigned bias = 2 + inst % 3;   // positive-literal bias 1/2, 2/3, 3/4: larger optima and gaps
        for (int k = 0; k < nh; k++) {
            std::vector<int> c; int len = 2 + rnd(3);
            for (int j = 0; j < len; j++) c.push_back((int)(1 + rnd(I.n)) * (rnd(bias) ? 1 : -1));
            I.hard.push_back(c);
        }
        if (rnd(2)) { std::vector<int> c; for (int i = 0; i < I.n; i++) c.push_back(i + 1); I.hard.push_back(c); } // nonzero
        for (int i = 0; i < I.n; i++) I.soft.push_back(std::vector<int>(1, -(i + 1)));
        int ns = rnd(3);
        for (int k = 0; k < ns; k++) {
            std::vector<int> c; for (int j = 0; j < 2; j++) c.push_back((int)(1 + rnd(I.n)) * (rnd(2) ? 1 : -1));
            I.soft.push_back(c);
        }
        const int opt = optimum(I);
        const uint64_t maxc = I.soft.size();
        bool prep; SimpSolver* S = build(I, prep);
        if (!prep) { need(opt < 0, "prepare failed on a satisfiable instance", inst); unsat++; delete S; continue; }
        uint64_t lb = 0, ub = UINT64_MAX, v = 0;   // proven bounds known to the "driver"
        bool last_at_cap = false, built = true; uint64_t fresh_max = 0, spent = 0;   // GH-106 policy state of this instance
        auto probe = [&](uint64_t cap, bool first) -> Solver::IncResult {
            const bool want = pol == 3 || (pol >= 1 && !S->feasible) || (pol == 2 && first)
                              || (pol == 4 && last_at_cap) || (pol == 5 && last_at_cap && first);
            if (want) {   // GH-106 policy rebuild
                delete S; S = build(I, prep); policy_builds++; built = true;
                need(prep, "policy rebuild prepare failed", inst);
            }
            uint64_t limit = UINT64_MAX;
            if (pol >= 6 && !built && first && S->feasible) { uint64_t b = bfactor * (pol == 6 ? fresh_max : spent); limit = S->conflicts + (b < bfloor ? bfloor : b); }
            uint64_t c0 = S->conflicts;
            S->inc_conflictLimit = limit;
            Solver::IncResult r = S->incProbe(cap, first, lb, v); probes++;
            S->inc_conflictLimit = UINT64_MAX;
            if (built && S->conflicts - c0 > fresh_max) fresh_max = S->conflicts - c0;
            spent += S->conflicts - c0;
            if (r == Solver::INC_INTERRUPTED && limit != UINT64_MAX && S->conflicts >= limit) {   // budget fallback
                budget_fallbacks++; delete S; S = build(I, prep); built = true;
                need(prep, "budget rebuild prepare failed", inst);
                c0 = S->conflicts;
                r = S->incProbe(cap, first, lb, v); probes++;
                if (S->conflicts - c0 > fresh_max) fresh_max = S->conflicts - c0;
                spent += S->conflicts - c0;
            }
            if (r == Solver::INC_REBUILD) {
                rebuilds++; delete S; S = build(I, prep);
                need(prep, "rebuild prepare failed", inst);
                r = S->incProbe(cap, first, lb, v); probes++;
                need(r != Solver::INC_REBUILD, "rebuild requested twice", inst);
            }
            if (r == Solver::INC_NONE) { nones++; need(opt < 0 || (uint64_t)opt > cap, "NONE but optimum <= cap", inst); if (cap + 1 > lb) lb = cap + 1; }
            else if (r == Solver::INC_FOUND || r == Solver::INC_OPT) {
                need(opt >= 0 && v <= cap && v >= (uint64_t)opt, "FOUND/OPT value out of range", inst);
                checkWitness(I, *S, v, inst);
                if (r == Solver::INC_OPT) { opts++; need(!first, "OPT for first-only probe", inst); need((int)v == opt, "OPT != optimum", inst); lb = v; }
                else { found++; need(first, "FOUND for optimisation probe", inst); }
                if (v < ub) ub = v;
            }
            else need(false, "interrupted/unexpected result", inst);
            last_at_cap = (r == Solver::INC_FOUND && v == cap);
            built = false;   // the next probe starts on a kept solver unless rebuilt
            return r;
        };
        // phase 1: doubling feasibility caps until a solution or the maximum
        for (uint64_t m = 1; ; m = (m >= maxc ? maxc : 2 * m)) {
            if (lb > m) { if (m >= maxc) break; continue; }
            Solver::IncResult r = probe(m, true);
            if (r == Solver::INC_FOUND || m >= maxc) break;
        }
        // forced raise after a refutation that followed a solution (must yield INC_REBUILD inside probe())
        if (ub != UINT64_MAX && ub > lb + 1 && rnd(2)) { probe(lb, true); if (lb < ub) probe(ub - 1, true); }
        // phase 2: random tie-break / capped optimisation / forbidden-raise probes
        for (int step = 0; step < 6 && ub != UINT64_MAX && lb < ub; step++) {
            unsigned kind = rnd(3);
            if (kind == 0) probe(ub - 1, true);                                         // tie-break
            else if (kind == 1) probe(lb + rnd((unsigned)(ub - lb)), true);            // random lower cap
            else { uint64_t c = lb + rnd((unsigned)(ub - lb + 1)); probe(c, false); }  // capped optimisation
        }
        if (ub != UINT64_MAX && lb < ub) probe(ub, false);
        if (ub == UINT64_MAX) need(opt < 0, "no solution found on a satisfiable instance", inst);
        else need((int)ub == opt && lb >= ub, "final bounds != optimum", inst);
        // re-asking after completion (knownLB forgotten): answers must stay consistent
        if (ub != UINT64_MAX && ub > 0) { lb = 0; probe(ub - 1, true); probe(ub, false); }
        delete S;
    }
    std::fprintf(stderr, "GH76_INCREMENTAL_%s instances=%d unsat=%ld probes=%ld found=%ld opt=%ld none=%ld rebuilds=%ld failures=%d\n",
                 fails ? "FAIL" : "PASS", N, unsat, probes, found, opts, nones, rebuilds, fails);
    if (pol != 0) std::fprintf(stderr, "GH106_POLICY %s policy_builds=%ld budget_fallbacks=%ld (factor %llu floor %llu)\n", policy, policy_builds,
                               budget_fallbacks, (unsigned long long)bfactor, (unsigned long long)bfloor);
    return fails ? 1 : 0;
}
