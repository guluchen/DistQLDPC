# Agent experiment: literal-indexed assignment mirror for `Solver::value(Lit)`

Agent/session: `mac-litvals-20261009` (independent; not a sub-role of another
experiment). Hub: https://github.com/guluchen/DistQLDPC/issues/15 .
Immutable source baseline: `24572d6d09cce9a4a5faa58300a89e0feba9da6a`.
History/docs read from `experiment/h001-logical-row-xor` (never used as baseline).
Hypothesis IDs: GH-<issue>-A/B/C; experiment record GH-<issue> (this directory is
renamed once the GitHub issue number exists). Status: PROPOSED / UNTESTED.

DistQLDPC is the downstream CSS-distance application; QDistSAT is its separate
benchmark platform; `src/solver/` is a downstream MaxCDCL-derived engine whose
upstream notices are preserved.

## Evidence gathered before proposing (baseline only, no candidate timing)

Host: Apple M6 Mac mini, 12 logical CPUs, macOS 27, Apple clang 21.0.0
(`c++`). The pinned baseline does not compile with Apple clang because of
`"%"PRIi64` literal concatenation in `utils/Options.h`; both baseline and
candidate are built with the identical compiler-command shim
`CXX="c++ -Wno-reserved-user-defined-literal"` and the original Makefile flags.

1. `sample` profile of the forked solver child, LP_340_56_8, 15 s per mode
   (self-time, ~13k samples each): `propagateForLK` 9011/9081 samples (~70%),
   `lookbackResetTrail` ~8%, `pickAuxiVar` ~5%, `uncheckedEnqueueForLK` ~2.5%,
   ordinary `propagate` ~2%.
2. Counting-only copy of `propagateForLK` (scratch, not production), Tier1
   cases. Example BB_108_8_10 OFF: 390.1M long-watcher visits, 318.1M (81.5%)
   resolved by the blocker literal without loading the clause; 72.1M clause
   loads (size3 41%, size4 32%, size>=9 24%); 111.5M further literal scans;
   17.1M binary-watcher checks. Every one of these steps is one
   `value(Lit)` = `assigns[var(p)] ^ sign(p)` evaluation. Other Tier1
   case/modes show the same pattern (blocker hit 58–82%).

## Three proposals (ranked)

### A — SELECTED: literal-indexed assignment mirror (general program optimization)

Mechanism. Keep the existing per-variable `vec<lbool> assigns` unchanged and add
a per-literal byte array `litvals` with `litvals[toInt(mkLit(v,s))] ==
assigns[v] ^ s` maintained at every write. `Solver::value(Lit)` then returns
`litvals[toInt(p)]` (one indexed byte load) instead of shift + load + xor.
All 23 `assigns[x] = ...` write sites in `Solver.cc` become one inline setter
writing all three bytes; the two `assigns.push(l_Undef)` sites in variable
creation push two `l_Undef` literal entries. `value(Var)`, all readers of
`assigns`, data layout of clauses/watchers, heuristics, propagation order and
every other component stay untouched. lbool encodings are copied bit-exactly
(l_Undef xor 1 = 3, still undefined under MiniSat's `==`), so every
`value(Lit)` result is identical by construction.

Origin: standard engineering in modern CDCL solvers (Kissat and CaDiCaL index
their value arrays by literal). No paper is claimed as the source and no code
is copied from those solvers.

Code location: `src/solver/Solver.h` (member, setter, `value(Lit)`),
`src/solver/Solver.cc` (write and push sites only). MODIFICATIONS.md/NOTICE
updated to list the patch.

Expected affected cases: all modes, dominated by `propagateForLK` blocker/literal
checks; no predicted percentage. Costs: two extra byte stores per
assign/unassign (far fewer than reads: e.g. 42M lookahead propagations vs
>500M value reads on BB108 OFF), 2 bytes/variable memory.

Risks: a missed write site silently desynchronises the mirror (guarded by a
test-only assertion build that checks the identity at every `value(Lit)` call
and by byte-identical verbose search logs); code-size/register-pressure
changes; benefit may already be hidden by out-of-order execution.

Relation to prior work: distinct from H001/H002 encoding, H004/GH17 allocation
reuse, H007 LTO, H008 SLS, H009 BDD, H010 PGO, GH20 watch-tail copy skip, GH21
O2, GH22 VSIDS, GH26 cap2 FLA, GH27 enqueue inlining, H005/GH17-C/GH26-C
prefetch, GH21-B native ISA and GH22-B Clang backend. Search found no prior
literal-indexed value proposal.

### B — UNSELECTED: ternary-clause fast path in `propagateForLK` (engineering)

For clauses of size exactly 3 (41% of lookahead clause loads above), replace the
two `lastPoint` scan loops by a direct test of `c[2]`, writing exactly the same
`lastPoint`, literal swaps and watcher moves as the generic code, so search is
unchanged. Smaller reach than A (only after a clause load, ~19% of visits),
adds a size branch to every clause load; ~1 day. Ranked below A because A
touches every read on the hot path.

### C — UNSELECTED: prioritised lookahead propagation (paper-derived)

Source: B. Kaiser, R. Clausecker, M. Mavroskoufis, "Prioritised Unit
Propagation by Partitioning the Watch Lists", 14th Pragmatics of SAT workshop
(PoS 2023), CEUR-WS Vol-3545 paper 2 (CC BY 4.0). Read: abstract, Sections 1–3
outline (PriPro: second two-watched-literal structure for prioritised clauses,
propagated first; prioritisation from recent resolvents, LBD<=6 upgrade).
Adaptation idea: in `propagateForLK`, exhaust watchers of a prioritised clause
partition before the rest, aiming for earlier/shorter lookahead conflicts. This
changes the lookahead search path and core detection, so correctness and
performance both need full re-validation; multi-day; outside the 2024–2026
window (no 2024–2026 SAT/CAV/TACAS/CP propagation paper with a directly
applicable technique was found in this round; AAAI 2025 soft-clause unlocking,
Li et al. DOI 10.1609/aaai.v39i11.33226, is already present in this engine via
`isetLock`/`unLockedSoftVarForLK`). Ranked last for cost and risk.

## Selection rationale

A attacks the measured dominant cost (~70% of samples in `propagateForLK`, whose
work is mostly `value(Lit)` reads), is exactly one concept, and keeps the
search trace byte-identical, which gives an unusually strong correctness
oracle. No speedup is claimed before measurement.

## Exact scope and exclusions

Only the mirror and its maintenance. No change to Makefile/flags, encoding,
heuristics, watcher/clause layout, inlining attributes, prefetching, clause
order, `value(Var)`, timeouts, outputs or bounds. Not combined with any other
agent's change.

## Validation plan (preregistered)

Tier0 (must all pass before any timing):
1. Both binaries build from the same compiler command; `scripts/smoke_test.sh`
   passes for both.
2. Test-only assertion build (candidate + `-UNDEBUG -DLITVALS_CHECK`): every
   `value(Lit)` call asserts `litvals[toInt(p)] == assigns[var(p)] ^ sign(p)`
   bit-exactly; run the four Tier1 cases plus LP_34_20_2 in OFF/MTO.
   Production binaries never contain this check.
3. Search-trace identity: `-v` stdout of baseline and candidate must be
   byte-identical after masking only timing fields, for every case in
   `data/matrices` that finishes within 60 s, in modes no-card, card-mto,
   card-sinz and default; any difference = STOP/REJECT.
4. Distances (`o N`) equal to the known value in the code name where known.
5. Timeout semantics: LP_340_56_8 with `-cpu-lim=1` and `-cpu-lim=5` gives the
   same status line format and the same emitted bounds in both binaries.
6. Required QDistSAT cross-repo PR check on the draft PR.

Tier1 (only after Tier0 PASS; on this Mac, the only runner on this host):
BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6; `-no-card` and `-card-mto`
separately; baseline 3 + candidate 3 per case/mode in AB/BA/AB order; one solve
at a time; `-cpu-lim=180`, external watchdog 195 s. Record raw wall times,
stdout/stderr, all bound/objective lines, binary/input SHA256, and telemetry
(load averages and summed process CPU before/after each run).
Numerical filter (unchanged GH16 judge): per mode, geometric mean of median
ratios; range envelope max(candidate)/min(baseline) geometric mean; positive
only if every per-case median is non-worse AND envelope mean < 1; all candidate
samples slower than all baseline samples flags a regression.
Resource guard: start a solve only if 1-min load average < 6.0 (global spare
> 50% of 12 CPUs); this experiment uses one CPU (<= half spare). macOS offers no
user CPU pinning; P/E-core placement is a recorded limitation.
Supplementary replication (preregistered, does not change the gate): 10 further
alternating AB/BA pairs per case/mode, same guard, reported separately.

Tier2 only if Tier1 numerically positive with no serious regression:
LP_340_56_8, both modes, 3+3 AB/BA/AB, `-cpu-lim=600`, watchdog 615 s.
No Tier3. Mac timings are diagnostic local evidence, not a dedicated-server
controlled claim.

Budget: ~1 day engineering; Tier0 < 30 min CPU; Tier1 ~3 min of solves plus
replication ~10 min; Tier2 <= ~40 min.

Disposition rules: any semantic mismatch, assertion failure or crash ->
REJECT and stop. Otherwise ACCEPT/REJECT/INCONCLUSIVE strictly by the gates
above; inconclusive is not PASS; no repeat-until-favourable.
