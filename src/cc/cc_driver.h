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
 *   lb_h  proven: every nontrivial logical of half h has weight >= lb_h (level lb_h - 1 EMPTY);
 *   ub_h  weight of a verified nontrivial logical of half h; U = min_h ub_h;  LB = min_h lb_h.
 *   A level-w hit in half h (with lb_h = w) gives d_h = w; with the other half's lb >= w, d = w.
 *   Termination: LB >= U gives d = U.
 *   With a verified XZ-dual map pi (GH-87/GH-107 detection; a weight-preserving bijection
 *   F_X -> F_Z, so dX = dZ) only the X half is searched; its lb and ub are mirrored to the Z half
 *   and pi(witness) is verified in the Z half.
 * Every witness is verified before it is reported: H e = 0 for the half's parity checks and
 * e not in the row space of the same-type stabilizers (an independent GF(2) rank test, not the
 * detector rows). Always-on traps (error + RESULT -1, never a value): detector check failure at
 * start-up, a witness that fails verification, a nontrivial syndrome-free cluster below a level,
 * lb_h > ub_h for a half, LB > U.
 */
#ifndef DISTQLDPC_CC_DRIVER_H
#define DISTQLDPC_CC_DRIVER_H

#include <stdint.h>
#include <string>
#include <vector>

#include "cc_half.h"

namespace distcc {

struct DriverInput {
    SparseRows Hx, Hz, Gx, Gz;
    std::vector<int> orbit_of[2];   /* [0] X half, [1] Z half: verified per-half orbits (empty: none) */
    std::vector<int> dual_perm;     /* verified XZ-dual map: X-half qubit i -> Z-half qubit dual_perm[i] */
    std::string dual_desc;
};

struct DriverOptions {
    Rules rules;             /* -cc-rules (default excl,pack,orbf) */
    bool dual;               /* -cc-dual=on|off (default on) */
    bool ub_basis;           /* -ub-basis (default off): verified basis rows as initial upper bound */
    uint64_t seed;           /* -cc-seed=N (default 0 = identity labels) */
    int mutant;              /* -cc-mutant=K (test only; 0 = none) */
    std::string trace_path;  /* -cc-trace=FILE */
    bool stats;              /* -cc-stats */
    int verb;
    bool sequential;         /* TEST ONLY (no flag): halves searched one after the other instead of
                                level by level; used to expose driver mutant 4 */
    DriverOptions() : dual(true), ub_basis(false), seed(0), mutant(0), stats(false), verb(0), sequential(false) {}
};

/* Bound output: kind is "TRY", "LB" or "UB"; result(d, true) = RESULT d OPTIMAL, result(-1, false). */
struct BoundSink {
    void* ctx;
    void (*bound)(void* ctx, const char* kind, uint64_t v);
    void (*result)(void* ctx, int d, bool optimal);
};

/* Returns d >= 0 (RESULT d OPTIMAL emitted) or -1 (RESULT -1 emitted). */
int min_distance_cc(const DriverInput& in, const DriverOptions& opt, const BoundSink& sink);

/* "-cc-rules=" value: comma list of excl, pack, orbf, mrv (or "none"). */
bool parse_rules(const char* s, Rules& out);
std::string rules_string(const Rules& r);

/* Independent witness check: e (qubit support) satisfies Hpar e = 0 and e is not in the row
 * space of Sstab. Exposed for tests. */
bool verify_logical(const SparseRows& Hpar, const SparseRows& Sstab, const std::vector<int>& e, std::string& why);

} /* namespace distcc */

#endif
