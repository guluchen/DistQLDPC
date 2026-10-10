/*
 * DistQLDPC engine -- module Xor.cc (GH-98): native XOR constraints.
 *
 * At solve start (after original-clause vivification) the complete CNF expansions of parity
 * constraints among the original clauses are detected: 2^(k-1) clauses over the same k variables
 * (3 <= k <= xorMaxK) excluding every assignment of one parity. Each such group becomes one XOR
 * record propagated with two watched VARIABLES in propagate, propagateForLK, simplePropagate and
 * simplepropagateForLK. The clauses stay in the clause DB (in `clauses`, flagged `xorc`, detached
 * from the watch lists) and serve as the reason of every XOR implication (implied literal moved to
 * index 0) and as the conflict clause of every XOR conflict, so conflict analysis, the lookahead
 * lookback and soft-conflict analysis see only ordinary clauses. The XOR state is solve-local:
 * every exit of solve_() re-attaches the clauses. Design and soundness argument:
 * optimization/experiments/GH-98/PROPOSAL.md.
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Xor.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

#include <vector>
#include <algorithm>

#define XOR_HARD_MAXK 6   // largest arity the store supports (2^(k-1) clause refs per record)

// Record layout at offset o of xorMem:
//   [o]                header: k | (parity << 8)   (XOR of the k variables == parity)
//   [o+1   .. o+k]     watch-order variables w_0..w_{k-1}; w_0 and w_1 are watched
//   [o+1+k .. o+2k]    canonical (sorted) variables cv_0..cv_{k-1}
//   [o+1+2k .. ]       2^(k-1) clause CRefs; index bit t = value of cv_t excluded by that clause (t < k-1)

#ifdef XOR_STATS
// Process-wide counters (one distqldpc child runs several solver instances in sequence).
static uint64_t xst_visits = 0, xst_insp = 0, xst_xvisits = 0, xst_ximp = 0, xst_xconf = 0;
static uint64_t xst_lk = 0, xst_lkprop = 0, xst_props = 0;
static double   xst_last = -1;
static void xorStatsPrint(const char* tag) {
    fprintf(stderr, "c XOR_STATS %s cpu=%.2f lk=%llu lkprop=%llu visits=%llu insp=%llu xvisits=%llu ximp=%llu xconf=%llu\n",
            tag, cpuTime(), (unsigned long long)xst_lk, (unsigned long long)xst_lkprop,
            (unsigned long long)xst_visits, (unsigned long long)xst_insp, (unsigned long long)xst_xvisits,
            (unsigned long long)xst_ximp, (unsigned long long)xst_xconf);
    fflush(stderr);
}
static inline void xorStatsTick() {
    if ((xst_lk & 255) != 0) return;
    double t = cpuTime();
    if (xst_last < 0) xst_last = t;
    if (t - xst_last >= 2.0) { xst_last = t; xorStatsPrint("tick"); }
}
#endif

#ifdef XOR_SELFCHECK
static void xorSelfCheckFail(const char* where, const char* what, int o) {
    printf("c XOR_SELFCHECK_FAIL %s: %s (record %d)\n", where, what, o);
    fprintf(stderr, "c XOR_SELFCHECK_FAIL %s: %s (record %d)\n", where, what, o);
    fflush(stdout); fflush(stderr);
    abort();
}
#endif

// Pattern index of the clause excluding the current assignment, where impliedVar (if any) takes the
// excluded value exclImplied instead of its current value.
inline uint32_t Solver::xorPattern(const uint32_t* r, int k, Var impliedVar, unsigned exclImplied) const {
    const uint32_t* cv = r + 1 + k;
    uint32_t idx = 0;
    for (int t = 0; t < k - 1; t++) {
        Var v = (Var)cv[t];
        unsigned b = (v == impliedVar) ? exclImplied : (unsigned)(value(v) == l_True);
        idx |= b << t;
    }
    return idx;
}

// Propagate the XOR records watching variable x (just assigned).
// MODE 0: propagate, 1: propagateForLK, 2: simplePropagate, 3: simplepropagateForLK (each with its own
// enqueue and falseVar convention). Returns 0 (done), 1 (conflict, confl set) or 2 (stopped on falseVar).
// On 1 and 2 the remaining watchers are kept; the caller sets qhead = trail.size().
template<int MODE>
inline int Solver::xorPropagate(Var x, CRef& confl) {
    vec<uint32_t>& xw = xorWatches[x];
    uint32_t *i, *j, *end;
    uint32_t* M = (uint32_t*)xorMem;
    for (i = j = (uint32_t*)xw, end = i + xw.size(); i != end;) {
        const uint32_t o = *i;
        uint32_t* r = M + o;
        const int k = (int)(r[0] & 0xff);
        Var* w = (Var*)(r + 1);
#ifdef XOR_STATS
        if (MODE == 1) xst_xvisits++;
#endif
        if (w[0] == x) { w[0] = w[1]; w[1] = x; }
        for (int t = 2; t < k; t++) {
            if (value(w[t]) == l_Undef) {
                w[1] = w[t]; w[t] = x;
                xorWatches[w[1]].push(o);
                i++;
                goto NextXor;
            }
        }
        {
            unsigned s = (r[0] >> 8) & 1;
            for (int t = 1; t < k; t++) s ^= (unsigned)(value(w[t]) == l_True);
            lbool v0 = value(w[0]);
            *j++ = *i++;
            if (v0 == l_Undef) {
                // w_0 = s is implied; its reason excludes w_0 = 1 - s.
                Var y = w[0];
                Lit imp = mkLit(y, !s);
                CRef cr = r[1 + 2 * k + xorPattern(r, k, y, (unsigned)!s)];
                Clause& c = ca[cr];
                if (var(c[0]) != y) {
                    int t = 1;
                    while (var(c[t]) != y) t++;
                    Lit tmp = c[0]; c[0] = c[t]; c[t] = tmp;
                }
#ifdef XOR_SELFCHECK
                if (c[0] != imp) xorSelfCheckFail("xorPropagate", "reason clause does not contain the implied literal", (int)o);
                for (int t = 1; t < c.size(); t++)
                    if (value(c[t]) != l_False) xorSelfCheckFail("xorPropagate", "reason clause literal not false", (int)o);
#endif
#ifdef XOR_STATS
                if (MODE == 1) xst_ximp++;
#endif
                bool stop = false;
                if (MODE == 0) uncheckedEnqueue(imp, cr);
                else if (MODE == 1) { if (!uncheckedEnqueueForLK(imp, cr)) { falseVar = y; stop = true; } }
                else if (MODE == 2) simpleUncheckEnqueue(imp, cr);
                else {
                    simpleuncheckedEnqueueForLK(imp, cr);
                    if (auxiVar(y) && value(softLits[y]) == l_False && !softVarLocked[y]) { falseVar = y; stop = true; }
                }
                if (stop) {
                    while (i < end) *j++ = *i++;
                    xw.shrink(i - j);
                    return 2;
                }
            }
            else if ((unsigned)(v0 == l_True) != s) {
                confl = r[1 + 2 * k + xorPattern(r, k, var_Undef, 0)];
#ifdef XOR_SELFCHECK
                { Clause& c = ca[confl];
                  for (int t = 0; t < c.size(); t++)
                      if (value(c[t]) != l_False) xorSelfCheckFail("xorPropagate", "conflict clause literal not false", (int)o); }
#endif
#ifdef XOR_STATS
                if (MODE == 1) xst_xconf++;
#endif
                while (i < end) *j++ = *i++;
                xw.shrink(i - j);
                return 1;
            }
        }
    NextXor:;
    }
    xw.shrink(i - j);
    return 0;
}

void Solver::xorFree() {
    xorMem.clear(true);
    xorOffsets.clear(true);
    for (int v = 0; v < xorWatches.size(); v++) xorWatches[v].clear(true);
    xorCount = 0;
}

struct XorRec {
    int k; Var v[XOR_HARD_MAXK]; unsigned q; uint32_t pat; CRef cr;
};

struct XorRecLt {
    bool operator()(const XorRec& a, const XorRec& b) const {
        if (a.k != b.k) return a.k < b.k;
        for (int t = 0; t < a.k; t++) if (a.v[t] != b.v[t]) return a.v[t] < b.v[t];
        if (a.q != b.q) return a.q < b.q;
        if (a.pat != b.pat) return a.pat < b.pat;
        return a.cr < b.cr;
    }
};

static inline bool xorSameGroup(const XorRec& a, const XorRec& b) {
    if (a.k != b.k || a.q != b.q) return false;
    for (int t = 0; t < a.k; t++) if (a.v[t] != b.v[t]) return false;
    return true;
}

void Solver::xorDetect() {
    xorFree();
    while (xorWatches.size() < nVars()) xorWatches.push();
    int maxk = xorMaxK < 3 ? 3 : (xorMaxK > XOR_HARD_MAXK ? XOR_HARD_MAXK : xorMaxK);

    std::vector<XorRec> recs;
    int nOrig = 0, cand[XOR_HARD_MAXK + 1] = {0}, nx[XOR_HARD_MAXK + 1] = {0}, covered = 0;
    long long origLits = 0, coveredLits = 0;
    for (int ci = 0; ci < clauses.size(); ci++) {
        CRef cr = clauses[ci];
        Clause& c = ca[cr];
        if (c.mark() == 1 || c.learnt()) continue;
        nOrig++; origLits += c.size();
        int k = c.size();
        if (k < 3 || k > maxk) continue;
        Lit L[XOR_HARD_MAXK];
        bool okc = true;
        for (int t = 0; t < k; t++) {
            if (value(c[t]) != l_Undef) { okc = false; break; }
            L[t] = c[t];
        }
        if (!okc) continue;
        for (int a = 1; a < k; a++) {           // insertion sort by variable
            Lit l = L[a]; int b = a - 1;
            while (b >= 0 && var(L[b]) > var(l)) { L[b + 1] = L[b]; b--; }
            L[b + 1] = l;
        }
        for (int t = 1; t < k; t++) if (var(L[t]) == var(L[t - 1])) { okc = false; break; }
        if (!okc) continue;
        XorRec R; R.k = k; R.cr = cr; R.q = 0; R.pat = 0;
        for (int t = 0; t < k; t++) {
            R.v[t] = var(L[t]);
            R.q ^= (unsigned)sign(L[t]);           // excluded value of var(L[t]) is sign(L[t])
            if (t < k - 1) R.pat |= (uint32_t)sign(L[t]) << t;
        }
        cand[k]++;
        recs.push_back(R);
    }
    std::sort(recs.begin(), recs.end(), XorRecLt());

    for (size_t a = 0; a < recs.size();) {
        size_t b = a + 1;
        while (b < recs.size() && xorSameGroup(recs[a], recs[b])) b++;
        const int k = recs[a].k;
        const uint32_t full = 1u << (k - 1);
        if (b - a >= full) {
            CRef tab[1u << (XOR_HARD_MAXK - 1)];
            uint64_t mask = 0;
            for (size_t t = a; t < b; t++) {
                uint32_t p = recs[t].pat;
                if (!((mask >> p) & 1)) { mask |= (uint64_t)1 << p; tab[p] = recs[t].cr; }
            }
            if (mask == (((uint64_t)1 << full) - 1)) {
                uint32_t o = (uint32_t)xorMem.size();
                xorMem.push((uint32_t)k | ((1u - recs[a].q) << 8));     // parity = 1 - excluded parity
                for (int t = 0; t < k; t++) xorMem.push((uint32_t)recs[a].v[t]);
                for (int t = 0; t < k; t++) xorMem.push((uint32_t)recs[a].v[t]);
                for (uint32_t p = 0; p < full; p++) { xorMem.push(tab[p]); ca[tab[p]].xorc(true); }
                xorWatches[recs[a].v[0]].push(o);
                xorWatches[recs[a].v[1]].push(o);
                xorOffsets.push(o);
                xorCount++; nx[k]++; covered += (int)full; coveredLits += (long long)full * k;
            }
        }
        a = b;
    }

    if (xorCount > 0) {                          // detach the XOR clauses from the long watch lists
        watches.cleanAll();
        for (int v = 0; v < nVars(); v++)
            for (int s = 0; s < 2; s++) {
                vec<Watcher>& ws = watches[mkLit(v, s)];
                int a, b;
                for (a = b = 0; a < ws.size(); a++)
                    if (!ca[ws[a].cref].xorc()) ws[b++] = ws[a];
                ws.shrink(a - b);
            }
    }
#ifdef XOR_SELFCHECK
    xorCheckTables("xorDetect");
#endif
    if (verbosity >= 1) {
        printf("c GH-98 XOR detection: %d XORs (k3 %d, k4 %d, k5 %d, k6 %d); %d of %d original clauses (%.1f%%), "
               "%lld of %lld literals (%.1f%%); candidates k3 %d, k4 %d, k5 %d, k6 %d\n",
               xorCount, nx[3], nx[4], nx[5], nx[6], covered, nOrig, nOrig ? 100.0 * covered / nOrig : 0.0,
               coveredLits, origLits, origLits ? 100.0 * coveredLits / origLits : 0.0,
               cand[3], cand[4], cand[5], cand[6]);
        fflush(stdout);
    }
}

// Back to the clause-only state (every exit of solve_()): re-attach the XOR clauses with a valid
// watch order for level 0 (true literals first, then unassigned, then false) and free the XOR store.
void Solver::xorRestoreClauses() {
    for (int x = 0; x < xorOffsets.size(); x++) {
        const uint32_t* r = &xorMem[xorOffsets[x]];
        const int k = (int)(r[0] & 0xff);
        const uint32_t full = 1u << (k - 1);
        for (uint32_t p = 0; p < full; p++) {
            CRef cr = r[1 + 2 * k + p];
            Clause& c = ca[cr];
            c.xorc(false);
            for (int a = 1; a < c.size(); a++) {     // stable insertion sort by rank
                Lit l = c[a];
                int rl = value(l) == l_True ? 0 : (value(l) == l_Undef ? 1 : 2);
                int b = a - 1;
                while (b >= 0) {
                    int rb = value(c[b]) == l_True ? 0 : (value(c[b]) == l_Undef ? 1 : 2);
                    if (rb <= rl) break;
                    c[b + 1] = c[b]; b--;
                }
                c[b + 1] = l;
            }
            attachClause(cr);
            clauses_literals -= c.size();            // detection never subtracted them
        }
    }
    xorFree();
}

void Solver::xorRelocAll(ClauseAllocator& to) {
    for (int x = 0; x < xorOffsets.size(); x++) {
        uint32_t* r = &xorMem[xorOffsets[x]];
        const int k = (int)(r[0] & 0xff);
        const uint32_t full = 1u << (k - 1);
        for (uint32_t p = 0; p < full; p++) {
            CRef cr = r[1 + 2 * k + p];
            ca.reloc(cr, to);
            r[1 + 2 * k + p] = cr;
        }
    }
}

lbool Solver::solve_() {
    lbool r = solveMain_();
    if (xorCount > 0) xorRestoreClauses();
#ifdef XOR_STATS
    xorStatsPrint("solve_end");
#endif
    return r;
}

#ifdef XOR_SELFCHECK
// Every record: tables consistent with its clauses, watched variables are distinct members, and the
// record is in exactly the watch lists of w_0 and w_1.
void Solver::xorCheckTables(const char* where) {
    vec<int> cnt; cnt.growTo(xorMem.size(), 0);
    int total = 0;
    for (int v = 0; v < xorWatches.size(); v++)
        for (int t = 0; t < xorWatches[v].size(); t++) {
            uint32_t o = xorWatches[v][t];
            const uint32_t* r = &xorMem[o];
            if ((Var)r[1] != v && (Var)r[2] != v) xorSelfCheckFail(where, "watch list entry for an unwatched variable", (int)o);
            cnt[o]++; total++;
        }
    if (total != 2 * xorCount) xorSelfCheckFail(where, "watch entry count != 2 * xorCount", -1);
    for (int x = 0; x < xorOffsets.size(); x++) {
        uint32_t o = xorOffsets[x];
        const uint32_t* r = &xorMem[o];
        const int k = (int)(r[0] & 0xff);
        const unsigned par = (r[0] >> 8) & 1;
        if (cnt[o] != 2) xorSelfCheckFail(where, "record not watched exactly twice", (int)o);
        const uint32_t* w = r + 1; const uint32_t* cv = r + 1 + k;
        if (w[0] == w[1]) xorSelfCheckFail(where, "same variable watched twice", (int)o);
        for (int t = 0; t < k; t++) {      // w is a permutation of cv
            int found = 0;
            for (int u = 0; u < k; u++) if (w[u] == cv[t]) found++;
            if (found != 1) xorSelfCheckFail(where, "watch order is not a permutation", (int)o);
        }
        for (uint32_t p = 0; p < (1u << (k - 1)); p++) {
            const Clause& c = ca[r[1 + 2 * k + p]];
            if (c.size() != k || !c.xorc() || c.mark() == 1) xorSelfCheckFail(where, "pattern clause size/flag", (int)o);
            unsigned q = 0;
            for (int t = 0; t < k; t++) {
                int pos = -1;
                for (int u = 0; u < k; u++) if (var(c[u]) == (Var)cv[t]) pos = u;
                if (pos < 0) xorSelfCheckFail(where, "pattern clause misses a variable", (int)o);
                unsigned ex = (unsigned)sign(c[pos]);
                q ^= ex;
                if (t < k - 1 && ex != ((p >> t) & 1)) xorSelfCheckFail(where, "pattern clause at wrong index", (int)o);
            }
            if (q == par) xorSelfCheckFail(where, "pattern clause excludes a right-parity assignment", (int)o);
        }
    }
}

// At a propagation fixpoint every XOR is fully assigned with the right parity, or has both watched
// variables unassigned (hence >= 2 unassigned): no clause of its CNF is unit or false.
void Solver::xorCheckFixpoint(const char* where) {
    for (int x = 0; x < xorOffsets.size(); x++) {
        uint32_t o = xorOffsets[x];
        const uint32_t* r = &xorMem[o];
        const int k = (int)(r[0] & 0xff);
        unsigned s = (r[0] >> 8) & 1;
        int nund = 0;
        for (int t = 0; t < k; t++) {
            lbool v = value((Var)r[1 + k + t]);
            if (v == l_Undef) nund++; else s ^= (unsigned)(v == l_True);
        }
        if (nund == 1) xorSelfCheckFail(where, "unit XOR at fixpoint (missed implication)", (int)o);
        if (nund == 0 && s != 0) xorSelfCheckFail(where, "falsified XOR at fixpoint (missed conflict)", (int)o);
        if (nund > 0 && (value((Var)r[1]) != l_Undef || value((Var)r[2]) != l_Undef))
            xorSelfCheckFail(where, "assigned watched variable in an incomplete XOR", (int)o);
    }
    if ((++xorCheckCalls & 4095) == 0) xorCheckTables(where);
}
#endif
