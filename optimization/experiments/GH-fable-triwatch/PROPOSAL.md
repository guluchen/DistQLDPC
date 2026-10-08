# GH-<issue> / agent `fable-triwatch-20261008`: ternary-clause inline watchers (tri-watch)

Preregistration written BEFORE any candidate source edit. Coordination hub:
[issue 15](https://github.com/guluchen/DistQLDPC/issues/15). Baseline (immutable):
`24572d6d09cce9a4a5faa58300a89e0feba9da6a`. History/docs read from branch
`experiment/h001-logical-row-xor` (documentation commit bc9c470); none of its
H001 source is used. Branch: `experiment/fable-triwatch-20261008` (worktree
isolated from every other agent's checkout). Record directory is named
`GH-fable-triwatch` until the GitHub issue number is known; it is then renamed
to `GH-<issue>` with `git mv` (history preserved).

State at writing: PROPOSED / UNTESTED. No candidate code exists yet.

## 0. Evidence that motivated this round (diagnostic, not performance claims)

Baseline built from the pinned commit with Homebrew GCC 16.2.0 and the original
Makefile `-O3 -g` flags on an Apple M3 Max (macOS 27.0.1). Function-level
sampling (`/usr/bin/sample`, 1 ms) of the forked solver child on the four Tier 1
cases in both modes, raw files in `raw/baseline-profile/`:

| Case / mode | samples | `propagateForLK` | `lookbackResetTrail` | `pickAuxiVar` | `propagate` |
|---|---:|---:|---:|---:|---:|
| BB_90_8_10 OFF | 1934 | 64.0% | 7.3% | 5.7% | 4.6% |
| BB_90_8_10 MTO | 1742 | 63.0% | 8.7% | 6.1% | 3.7% |
| GB_144_12_8 OFF | 628 | 64.3% | 10.7% | 8.3% | 3.0% |
| GB_144_12_8 MTO | 1168 | 64.7% | 8.2% | 8.0% | 3.5% |
| BB_108_8_10 OFF | 2518 | 63.8% | 8.1% | 6.2% | 3.3% |
| BB_108_8_10 MTO | 2555 | 67.4% | 7.3% | 5.6% | 3.3% |
| LP_238_44_6 OFF | 1247 | 70.6% | 8.5% | 5.4% | 1.8% |
| LP_238_44_6 MTO | 1217 | 68.2% | 7.7% | 4.8% | 2.7% |

So 63–71% of solver time is the watched-literal unit propagation performed
inside the lower-bound lookahead (`Solver::propagateForLK`, baseline
`src/solver/Solver.cc:3932-4048`); the ordinary `propagate()` is 2–5%.

An instrumented COPY of the baseline (counters only, `raw/diag-instrumentation.patch`,
never part of the candidate) counted what happens inside that loop
(`raw/diag-counts.txt`). BB_90_8_10 OFF: 315.9M long-watch visits, of which
250.5M (79.3%) are skipped by the blocking literal; the remaining 65.3M
dereference the clause. Of those dereferences 22.2M (34%) are size-3 clauses,
19.6M (30%) size-4, 39% are learnt clauses. LP_238 MTO: 54.0M dereferences,
10.8M (20%) size 3. GB_144 OFF: 20.6M dereferences, 7.2M (35%) size 3.
BB_108 MTO: 79.2M dereferences, 29.2M (37%) size 3. Post-preprocessing
instances contain mostly size-3 and size-4 hard clauses (SimpSolver variable
elimination resolves Tseitin XOR chains into 3/4-literal clauses; histogram in
`raw/diag-counts.txt`). Each size-3 dereference executes the full
MiniSat/Maple scan: header load, `c[0]/c[1]` swap, `lastPoint` circular scan
with a header store, a literal swap and a `watches[~c[1]].push` into another
list (41.2M watch moves in BB_90 OFF), or a unit enqueue (20.1M).

These counts quantify an opportunity; they are not a measured time share per
clause size and they are not a predicted speedup.

## 1. Three proposals (ranked)

### A (SELECTED, rank 1): ternary-clause inline watchers ("tri-watch") — engineering

Mechanism. Add a third occurrence-list family `watches_tri` beside the existing
`watches_bin` / `watches`. A clause of exactly three literals is watched on ALL
three literals; each watcher stores the clause reference plus the OTHER TWO
literals (`{CRef, Lit, Lit}`, 12 bytes). Propagating a false literal through a
tri watcher needs only two `assigns` lookups and no clause memory access:
other literal true → nothing; both unassigned → nothing (all literals are
watched, so no watch ever moves); one false and one unassigned → unit
propagation with the clause as reason; both false → conflict. Clause memory is
touched only in the unit/conflict case, to keep the invariant the analysis
code relies on (`c[0]` is the implied literal of a reason clause). Binary
clauses keep their existing inline treatment; clauses of size ≥ 4 keep the
existing two-watch circular-scan loop unchanged.

Engineering precedent (not invented novelty): blocking literals and inlined
binary clauses were evaluated by Chu, Harwood and Stuckey, *Cache Conscious
Data Structures for Boolean Satisfiability Solvers*, JSAT 6 (2009) 99–120,
DOI 10.3233/SAT190064 (key `chu2009cache`; metadata read from the publisher
index and search summary, full text not re-read for this round — the engine
already has both techniques). Dedicated ternary watch entries existed in
CryptoMiniSat (from memory, unverified) and in Z3's SAT core; Z3 later removed
its ternary optimisation after measuring no effect on QF_BV (commit note seen
in search results; URL recorded in `references.bib` comments). This precedent
is a risk, not an endorsement: the expected effect is workload-dependent.

Exact scope (one performance concept):
- `src/solver/Solver.h`: `Watcher3`/`Watcher3Deleted` types, `watches_tri` member.
- `src/solver/Solver.cc`: `attachClause`/`detachClause` route size-3 clauses to
  `watches_tri` (3 watchers); tri loops in the four propagation routines
  (`propagate`, `propagateForLK`, `simplePropagate`, `simplepropagateForLK`)
  placed after the binary loop and before the long loop; `relocAll`, `newVar`,
  `newAuxiVar`, `cleanAll` call sites and `SimpSolver` cleanup extended for the
  new lists; every in-place literal rewrite that can change a clause's size
  across the size-3 boundary (`simplifyLearnt`, `splitClauses`) is bracketed by
  detach/attach so watcher contents stay consistent.
- `MODIFICATIONS.md` / `NOTICE`: document the downstream engine patch.
- No change to heuristics, restarts, clause-database policy, cardinality
  encodings, preprocessing, the application encoding, timeouts, output or
  compiler flags.

What changes observably: the ORDER in which implications of one literal are
discovered (binary → ternary → longer, instead of binary → long list in
insertion order). The propagation closure (set of implied literals; existence
of a conflict) is unchanged; which conflict clause is reported first may
differ, so learnt clauses and the search trajectory may differ. Final distance,
objective, bounds, timeout semantics and the exported WCNF must be identical.

Expected cases: both modes on all Tier 1 inputs and LP340 (size-3 share of
dereferences 20–37% in the four diagnostic runs). No percentage is claimed.

Risks: (1) a watcher that stores literal values must be refreshed whenever a
size-3 clause's literals are rewritten in place — missed sites cause wrong
propagation; (2) size-transition bugs (long → 3, 3 → 2) in simplification
and on-the-fly clause reduction; (3) the `c[0]`-implied invariant for tri
reason clauses; (4) lazy-deletion/GC paths for the new lists; (5) +50% watcher
visits for ternary clauses (3 watchers instead of 2) and 12-byte entries may
cost more than the saved dereferences; (6) trajectory change may produce
family-dependent regressions as E001/E002 did. Any wrong implication or
scientific mismatch is a REJECT.

Cost: estimated 2–3 days engineering plus Tier 0 harness; standard tiers.

### B (rank 2, UNSELECTED): proximity literal ordering for the MTO totalizer inputs — paper-derived

Source: Joseph E. Reeves, João Filipe, Min-Chien Hsu, Ruben Martins, Marijn
J. H. Heule, *The Impact of Literal Sorting on Cardinality Constraint
Encodings*, AAAI 2025, 39(11):11327–11335, DOI 10.1609/aaai.v39i11.33232
(key `reeves2025literalsorting`; full text read by the literature sub-task:
section "Literal Sorting Methods", sub-sections "Occurrence and Proximity
Orderings" and "Graph-based Ordering", Table 1). Mechanism: keep the encoding,
permute its input literals so that literals that co-occur in short clauses
share totalizer subtrees, making auxiliary sum variables better abstractions
for clause learning. Reported on MSE-2023-derived SAT instances: kmtotalizer
natural order 635 vs proximity 645 vs PAMO+occurrence 655 solved of 796.

Here: `addCardinalityConstraints()` (baseline `Solver.cc:6195`) builds
`activeSoftLits` in `allSoftLitsForCardC` order (qubit index order) and
`addCardinalityConstraintsMTO` / `nLevelsMTO` split that order recursively.
A one-time proximity score (BFS over hard clauses from each soft literal,
score 1/len for long clauses, 4 for binary clauses, as in the paper) would
reorder `allSoftLitsForCardC` once after preprocessing. Only `-card-mto`
(and Sinz/both) modes are affected; `-no-card` is untouched. Semantics
preserving. Cost ~1 day. Unselected because the measured runtime is dominated
by lookahead propagation, not by the cardinality constraint's learning quality,
and because PAMO (the strongest variant) needs at-most-one groups that this
encoding does not have. Remains a concrete candidate for a later round.

### C (rank 3, UNSELECTED): "used" flag retention in learnt-clause reduction — paper-derived

Source: Bernhard Gstrein, Florian Pollitt, André Schidler, Mathias Fleury,
Armin Biere, *Learn to Unlearn*, SAT 2025, LIPIcs 341, 14:1–14:12,
DOI 10.4230/LIPIcs.SAT.2025.14 (key `gstrein2025unlearn`; full text read by
the literature sub-task: Algorithm 1 "unlearn", §6 "Used Clauses are Useful").
Mechanism: a one-bit `used` flag set whenever a clause participates in conflict
analysis; the next reduction skips (and clears) used clauses and keeps small
clauses unconditionally. Here: the local tier `reduceDB()` (baseline
`Solver.cc:2658`) sorts by activity and deletes half; tier 2 demotion uses
`touched`. Cost < 1 day. Unselected because the effect on a BnB solver whose
cost is lookahead propagation is unknown and could go either way (retaining
more clauses makes every lookahead propagation visit more watchers), and the
paper's evidence is SAT-competition UNSAT instances. Remains a candidate.

Not proposed again: clause prefetch (GH-17-C / H005), demand watch cleanup
(GH-17-B / GH-20-C), self-copy skip (GH-20-A, active), PGO (GH-16, active),
scratch reuse (GH-17-A, shelved), LTO (E004), SLS (E005), BDD bound (E006),
encoding shortening (E001/E002). A directly attacks the same hotspot that
GH-17-C and GH-20-A address, by a different mechanism (fewer clause
dereferences rather than hiding their latency or skipping copies); it is not
combined with either.

## 2. Why A

A is the only candidate whose target was measured in this round: 63–71% of
runtime in one loop, with 20–37% of that loop's clause dereferences being
size-3 clauses that a three-watch scheme never dereferences. B and C change
search behaviour through learning quality and are supported by evidence from
different workloads; their applicability here is a guess. A's downside is
engineering risk, which Tier 0 is designed to expose.

## 3. Tier 0 plan (all must pass before any timing)

1. Build candidate and baseline from the pinned sources with identical flags
   (`CXX=g++-16`, original Makefile flags, `-isysroot` added on macOS only);
   record compiler version and binary SHA-256.
2. Exported WCNF (`-dump-only -dump-wcnf`) byte-identical to baseline for
   LP_34, LP_136, BB_90, GB_144, BB_108, LP_238, LP_340 (preprocessing is not
   touched, so any difference is a bug).
3. Propagation-closure differential test: a test-only harness (compiled
   separately, not in the production binary) loads each of the seven
   instances, applies many random partial assignments at decision level ≥ 1,
   runs `propagate()` and `propagateForLK()` on the solver and records
   (sorted implied-literal set, conflict yes/no). Baseline and candidate
   outputs must be identical for every assignment (the set, not the order).
   Includes assignments that make size-3 clauses unit and conflicting, and
   runs after `simplifyLearnt`-style clause shrinking where reachable.
4. Exhaustive tiny CSS oracles (brute force over all Pauli operators) vs the
   candidate, default/OFF/MTO.
5. End-to-end exact distances/objectives/bounds equal to baseline on the seven
   instances above, OFF and MTO (LP_340 once per mode, 600 s limit, science
   only — not Tier 2 timing).
6. `scripts/smoke_test.sh`; six forced `-cpu-lim=1` runs return `s UNKNOWN`
   with sound bounds; parent/child cleanup verified.
7. Hosted CI and the required QDistSAT cross-repo check on the draft PR.
Any mismatch, crash, changed bound or changed output → REJECT, stop, report.

## 4. Tier 1 plan (preregistered decision rule)

Host: this agent's own machine (Apple M3 Max, 14 cores, 96 GiB, macOS 27.0.1),
not previously used by any agent; requested as an independent host runner in
issue 15 (`RUN_REQUEST`) and from the PI directly. No timed run starts without
that assignment. Cases BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6;
OFF (`-no-card`) and MTO (`-card-mto`); baseline/candidate three repeats each,
serial, interleaved AB/BA/AB per case/mode, 48 solves, 180 s parent limit /
195 s watchdog; same binaries throughout; load average and per-process CPU
time recorded for each solve; all raw logs retained.

Decision per mode: ratio_c = candidate median / baseline median per case;
G = geometric mean of the four ratios; V = geometric mean over cases of
(baseline max / baseline min). PASS if G·V < 1 (improvement beyond baseline
spread), G < 1, and no case shows a disjoint regression (candidate min >
baseline max). REJECT if any case/mode shows a disjoint regression larger than
2% and G ≥ 1 for that mode. Otherwise INCONCLUSIVE. Tier 2 (LP_340_56_8, 12
solves, 600/615 s) only if both modes PASS or the PI explicitly authorises an
exploratory step; no Tier 3 from this record. Macbook timings are diagnostic
evidence; research-grade claims still need the dedicated server.

## 5. Budgets

Tier 0: < 1 h compute. Tier 1: worst case 156 min watchdog, expected ~5 min.
Tier 2 if reached: worst 123 min. Engineering 2–3 days.

## 6. Bibliography

Local additions in `references.bib` beside this file (keys `chu2009cache`,
`reeves2025literalsorting`, `gstrein2025unlearn`); the integrator reconciles
them into `optimization/references.bib` after review.
