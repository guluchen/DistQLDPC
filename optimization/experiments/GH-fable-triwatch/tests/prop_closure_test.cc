/*
 * Test-only harness for experiment GH-fable-triwatch (tri-watch).
 * NOT part of the production binary.
 *
 * Builds the real DistQLDPC MaxSAT instance (same code path as the production
 * binary, including SimpSolver preprocessing) and then applies many random
 * partial assignments at decision level 1, running the solver's own
 * propagate() and propagateForLK() routines. For every trial it prints the
 * conflict flag and, when there is no conflict, the SORTED set of literals
 * implied at level 1. Compiled once against the baseline sources and once
 * against the candidate sources, the two outputs must be byte-identical:
 * the tri-watch change may reorder implications but must not change the
 * propagation closure or the existence of a conflict.
 *
 * Build (from a checkout that already ran `make`):
 *   g++ -I<checkout>/src/solver -DDISTQLDPC_CC='"<checkout>/src/core/distqldpc.cc"' \
 *       -O2 -DNDEBUG -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS \
 *       -o prop_closure_test prop_closure_test.cc <checkout>/build/{SimpSolver,Solver,Options,System}.o -lz
 * Run:
 *   prop_closure_test <code-stem> <card-mode 0|3> <trials> <seed> [matrix-dir] [max-decisions=12]
 */
#define main distqldpc_main
#include DISTQLDPC_CC
#undef main

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

using namespace Minisat;

struct ProbeSolver : public SimpSolver {
    // Everything below only reads/writes members the real search code already uses.
    int level0Trail() const { return trail_lim.size() == 0 ? trail.size() : trail_lim[0]; }

    // propagate(): standard decision-level-1 probe.
    // Returns 1 on conflict, 0 otherwise; fills 'out' with the sorted implied literals.
    int probeMain(const std::vector<Lit>& decisions, std::vector<int>& out) {
        cancelUntil(0);
        falseLits_lim.push(falseLits.size()); // Solver::search does this before every new level
        newDecisionLevel();
        for (size_t i = 0; i < decisions.size(); i++)
            if (value(decisions[i]) == l_Undef)
                uncheckedEnqueue(decisions[i]);
        CRef confl = propagate();
        int rc = (confl != CRef_Undef) ? 1 : 0;
        out.clear();
        if (!rc)
            for (int i = trail_lim[0]; i < trail.size(); i++) out.push_back(toInt(trail[i]));
        std::sort(out.begin(), out.end());
        cancelUntil(0);
        return rc;
    }

    // propagateForLK(): lookahead-style probe (no decision level is opened; the
    // routine itself tags assignments with decisionLevel()+1). Undo exactly like
    // the non-conflict branch of Solver::lookahead().
    int probeLK(const std::vector<Lit>& decisions, std::vector<int>& out) {
        cancelUntil(0);
        int trailRecordLocal = trail.size();
        falseVar = var_Undef;
        for (size_t i = 0; i < decisions.size(); i++)
            if (value(decisions[i]) == l_Undef)
                uncheckedEnqueueForLK(decisions[i]);
        CRef confl = propagateForLK();
        int rc = (confl != CRef_Undef) ? 1 : 0;
        if (falseVar != var_Undef) rc |= 2;
        out.clear();
        if (!rc)
            for (int i = trailRecordLocal; i < trail.size(); i++) out.push_back(toInt(trail[i]));
        std::sort(out.begin(), out.end());
        for (int i = trailRecordLocal; i < trail.size(); i++)
            assigns[var(trail[i])] = l_Undef;
        trail.shrink(trail.size() - trailRecordLocal);
        qhead = trailRecordLocal;
        return rc;
    }

    // Count clauses per size among attached original clauses (sanity/report).
    void sizeReport() {
        int s2 = 0, s3 = 0, sl = 0;
        for (int i = 0; i < clauses.size(); i++) {
            const Clause& c = ca[clauses[i]];
            if (c.mark() == 1) continue;
            if (c.size() == 2) s2++; else if (c.size() == 3) s3++; else sl++;
        }
        printf("c clauses size2=%d size3=%d longer=%d vars=%d level0=%d\n", s2, s3, sl, nVars(), level0Trail());
    }
};

static uint32_t rng_state;
static uint32_t rnd() { // xorshift32, deterministic across builds/platforms
    uint32_t x = rng_state; x ^= x << 13; x ^= x >> 17; x ^= x << 5; return rng_state = x;
}

int main(int argc, char** argv) {
    if (argc < 5) { fprintf(stderr, "usage: %s <code> <card-mode> <trials> <seed> [dir]\n", argv[0]); return 2; }
    std::string stem = argv[1];
    int card_mode = atoi(argv[2]);
    int trials = atoi(argv[3]);
    rng_state = (uint32_t)strtoul(argv[4], NULL, 10); if (rng_state == 0) rng_state = 1;
    std::string dir = argc > 5 ? argv[5] : "data/matrices/";
    int maxk = argc > 6 ? atoi(argv[6]) : 12; if (maxk < 1) maxk = 1;
    std::string p = dir + stem;
    Matrix Hx = load_matrix((p + "_Hx.txt").c_str());
    Matrix Hz = load_matrix((p + "_Hz.txt").c_str());
    Matrix Gx = load_matrix((p + "_Gx.txt").c_str());
    Matrix Gz = load_matrix((p + "_Gz.txt").c_str());

    ProbeSolver S;
    std::vector<Var> aux;
    StabilizerInstance meta;
    if (!build_stabilizer_instance(S, aux, meta, Hx, Hz, Gx, Gz, 0, card_mode, -1)) {
        printf("c no logicals\n"); return 0;
    }
    S.sizeReport();

    std::vector<Var> cand;
    for (Var v = 0; v < S.nVars(); v++)
        if (!S.isEliminated(v) && S.value(v) == l_Undef) cand.push_back(v);
    printf("c probe-able vars %zu\n", cand.size());

    std::vector<Lit> decs;
    std::vector<int> out;
    long nConflMain = 0, nConflLK = 0, nImplied = 0;
    for (int t = 0; t < trials; t++) {
        int k = 1 + (int)(rnd() % maxk);
        decs.clear();
        for (int i = 0; i < k; i++) {
            Var v = cand[rnd() % cand.size()];
            decs.push_back(mkLit(v, (rnd() & 1) != 0));
        }
        int which = (int)(rnd() % 3); // 0,1: main propagate; 2: lookahead propagate
        int rc = (which == 2) ? S.probeLK(decs, out) : S.probeMain(decs, out);
        if (rc) { if (which == 2) nConflLK++; else nConflMain++; }
        nImplied += out.size();
        printf("%d %s k=%d rc=%d n=%zu:", t, which == 2 ? "LK" : "UP", k, rc, out.size());
        if (!rc) for (size_t i = 0; i < out.size(); i++) printf(" %d", out[i]);
        printf("\n");
    }
    printf("c summary trials=%d conflMain=%ld conflLK=%ld implied=%ld\n", trials, nConflMain, nConflLK, nImplied);
    return 0;
}
