/*
 * DistQLDPC — CC engine driver (GH-124, experimental; selected with -engine=cc).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * d = min(dX, dZ) for a CSS code (DistQLDPC's split, see CssHalf in src/core/distqldpc.cc):
 *   X half: x with Hz x = 0, nontrivial iff Gx x != 0   (same-type stabilizers Hx, basis rows Gz)
 *   Z half: z with Hx z = 0, nontrivial iff Gz z != 0   (same-type stabilizers Hz, basis rows Gx)
 * Each half is searched by the exact CC level search (cc_half.h) one weight level at a time, starting
 * at 1, so a level-w search always runs with the precondition "no nontrivial logical of weight < w in
 * this half" established by the half's own earlier levels (levels are contiguous from 1).
 *
 * Bound algebra (all bounds emitted are global):
 *   lb_h  proven: every nontrivial logical of half h has weight >= lb_h (level lb_h - 1 EMPTY; with the parity
 *         rule on a half whose column weights are all odd, every logical has even weight, so odd levels are
 *         skipped: level 1 is empty and an EMPTY level 2t gives lb_h = 2t + 2, GH-133);
 *   ub_h  weight of a verified nontrivial logical of half h; U = min_h ub_h;  LB = min_h lb_h.
 *   A level-w hit in half h (with lb_h = w) gives d_h = w; with the other half's lb >= w, d = w.
 *   Termination: LB >= U gives d = U.
 *   With a verified XZ-dual map pi (GH-87/GH-107 detection; a weight-preserving bijection
 *   F_X -> F_Z, so dX = dZ) only the X half is searched; its lb and ub are mirrored to the Z half
 *   and pi(witness) is verified in the Z half.
 * GH-140 -ub-search: a randomized low-weight logical finder per searched half (cc_ubsearch.h) runs as a pre-pass
 *   (ub_pre seconds) and interleaved with the level ladder (it gets the share ub_share of the elapsed wall time;
 *   total finder time capped at ub_cap seconds when ub_cap >= 0). The ladder stays single-threaded: the finder runs
 *   between levels and inside a level through HalfSearch's poll callback (every 16384 nodes). Every found word is
 *   verified exactly like a level witness (with a dual map, its image too) before it lowers ub_h and U and is
 *   reported as UB; a level in progress at weight w is abandoned (LEVEL_ABORTED, lb unchanged) once U <= w, after
 *   which the termination rule LB >= U applies as before. A finder word lighter than a half's proven lb is a trap.
 * Every witness is verified before it is reported: H e = 0 for the half's parity checks and
 * e not in the row space of the same-type stabilizers (an independent GF(2) rank test, not the
 * detector rows). Always-on traps (error + RESULT -1 TRAP, never a value; the receiver withdraws the
 * bounds already sent): detector check failure at start-up, a dual map that fails the driver's own
 * check, a witness that fails verification, a nontrivial syndrome-free cluster below a level,
 * lb_h > ub_h for a half, LB > U.
 */
#ifndef DISTQLDPC_CC_DRIVER_H
#define DISTQLDPC_CC_DRIVER_H

#include <stddef.h>
#include <stdint.h>
#include <string>
#include <vector>

#include "cc_half.h"
#include "cc_ubsearch.h"

namespace distcc {

struct DriverInput {
    SparseRows Hx, Hz, Gx, Gz;
    std::vector<int> orbit_of[2];   /* [0] X half, [1] Z half: verified per-half orbits (empty: none) */
    std::vector<int> dual_perm;     /* verified XZ-dual map: X-half qubit i -> Z-half qubit dual_perm[i] */
    std::string dual_desc;
};

struct DriverOptions {
    Rules rules;             /* -cc-rules (default excl,pack,orbf,parity,leaf,overlap) */
    bool dual;               /* -cc-dual=on|off (default on) */
    bool ub_basis;           /* -ub-basis (default on; -ub-basis=off): verified basis rows as initial upper bound */
    uint64_t seed;           /* -cc-seed=N (default 0 = identity labels) */
    int mutant;              /* -cc-mutant=K (test only; 0 = none). Driver mutant 4: stop rule without the
                                other half's lower bound, run under the sequential schedule (under lockstep
                                the pick order already gives olb >= w at every hit, so skipping the check
                                alone could never change an answer). GH-140: mutant 11 = finder without the detector
                                check (cc_ubsearch.h; the driver's verification must trap), mutant 12 = mutant 11 and
                                finder words reported without the driver's verification (wrong upper bounds) */
    std::string trace_path;  /* -cc-trace=FILE */
    bool stats;              /* -cc-stats */
    int verb;
    bool sequential;         /* -cc-schedule=sequential (TEST ONLY; default lockstep): the first searchable
                                half is raised to its own distance before the other half, so the stop rule's
                                other-half check is load-bearing; mutant 4 forces it */
    /* GH-140 -ub-search=off|on|budget:S (CC engine) */
    bool ub_search;          /* finder on */
    double ub_cap;           /* total finder seconds (budget:S); < 0: no cap (on) */
    double ub_pre;           /* -cc-ub-pre=S: pre-pass seconds before the first level (capped by ub_cap) */
    double ub_share;         /* -cc-ub-share=F: share of the elapsed wall time given to the finder after the pre-pass */
    int ub_hits;             /* -cc-ub-hits=H: after H finder iterations re-hit the current U without improving it, or
                                after a plateau (max(64, 4 x the iteration count at the last improvement) iterations
                                without improvement), the share drops to ub_share / 16 (QDistRnd-style convergence
                                heuristic; scheduling only; 0 = never) */
    bool ub_only;            /* -cc-ub-only (diagnostic): run only the finder for ub_cap seconds, no ladder, no answer */
    UbParams ub;             /* -cc-ub-triples=K, -cc-ub-slack=L (finder tuning) */
    uint64_t ub_poll_mask;   /* test only: level poll when (nodes & mask) == 0 (default 0x3FFF) */
    uint64_t ub_skip_polls;  /* test only: the first N finder polls do nothing (the finder starts mid-ladder) */
    DriverOptions() : dual(true), ub_basis(true), seed(0), mutant(0), stats(false), verb(0), sequential(false),
                      ub_search(true), ub_cap(-1), ub_pre(0), ub_share(0.05), ub_hits(16), ub_only(false), ub_poll_mask(0x3FFF), ub_skip_polls(0) {}
};

/* Bound output: kind is "TRY", "LB" or "UB"; result(d, true) = RESULT d OPTIMAL, result(-1, false).
 * trap (optional): called instead of result(-1, false) when the driver stops without an answer (a trap or
 * an unusable input); it tells the receiver to withdraw every bound already sent ("RESULT -1 TRAP"). */
struct BoundSink {
    void* ctx;
    void (*bound)(void* ctx, const char* kind, uint64_t v);
    void (*result)(void* ctx, int d, bool optimal);
    void (*trap)(void* ctx);
    BoundSink() : ctx(NULL), bound(NULL), result(NULL), trap(NULL) {}
};

/* Returns d >= 0 (RESULT d OPTIMAL emitted) or -1 (RESULT -1 emitted). */
int min_distance_cc(const DriverInput& in, const DriverOptions& opt, const BoundSink& sink);

/* "-cc-rules=" value: comma list of excl, pack, orbf, parity, leaf, overlap, mrv (or "none"); empty values and empty items
 * are invalid. */
bool parse_rules(const char* s, Rules& out);
std::string rules_string(const Rules& r);

/* Independent witness check: e (qubit support) satisfies Hpar e = 0 and e is not in the row
 * space of Sstab. Exposed for tests. */
bool verify_logical(const SparseRows& Hpar, const SparseRows& Sstab, const std::vector<int>& e, std::string& why);

} /* namespace distcc */

#endif
