# Brain Round 2 revision: recent literature and program optimization

> 2026-10-08: user shelves H-007 and selects H-008 through fresh
> [Round3](2026-10-08-round3.md). [E005](../experiments/E005/README.md) tests the
> fixed configuration: Tier0 PASS, no verified caps on8 case/mode calls,
> mechanism rejected; controlled performance INCONCLUSIVE. Original ranking
> and pre-execution alternatives below are preserved as chronology, not a queue.

> Subsequent execution: user accepted H-007; [E004](../experiments/E004/README.md)
> reached INCONCLUSIVE after Tier 0 PASS and 48 correct diagnostic Tier 1 solves.
> No Tier 2/3 or promotion. Text below is the original pre-execution proposal;
> H-008/H-009 remain unimplemented alternatives, not a queue.

Research date: 2026-10-07. User requests two complementary strategies: recent
MaxSAT papers and ordinary program optimization. This supersedes the recommendation
in [the first Round 2 proposal](2026-10-07-round2.md), preserving that document and
its witness receipt as history. This is a proposal, not a performance experiment.
No implementation, new experiment ID, solver run, or gate promotion occurred.

E001 remains provisionally shelved; controlled performance remains INCONCLUSIVE.
Read E001's [LEARN record](../experiments/E001/DISPOSITION-2026-10-07.md) and
E002/E003 history first. Fewer clauses did not reliably improve search; local
clause-buffer reuse did not establish an allocation bottleneck. Consequently,
prefer a measurable mechanism over another speculative CNF-size reduction.

## Literature screen

Eligibility uses publication/submission dates within 2024-10-07 through
2026-10-07, not search-engine crawl dates. Primary sources only. This is a targeted
screen, not an exhaustive survey. Reading depth is explicit; published papers and
preprints are distinguished. Competition results are not QLDPC speedup evidence.

| Paper / date / source | Reading depth and transferable observation | Applicability to this repository |
| --- | --- | --- |
| [SLS-Enhanced Core-Boosted Linear Search for Anytime Maximum Satisfiability](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.CP.2025.28), CP 2025 | Read full HTML, especially sections 3 and 4. Integrates SLS with Loandra; initial solutions and relaxed-instance reconstruction matter. Increasing precision is mainly relevant to weighted objectives. | Consider only one bounded SLS call providing a verified original-instance upper bound. Do not import the three-phase architecture, core feedback, or precision schedule. Anytime-score improvements do not establish faster exact-distance proofs. |
| [Certified Branch-and-Bound MaxSAT Solving](https://ojs.aaai.org/index.php/AAAI/article/view/38449), AAAI 2026, published 2026-03-14; [extended version](https://arxiv.org/html/2511.10273v1), submitted 2025-11-13 | Read extended version, particularly section 0.4 and appendix .9. Describes BDD/MDD solution-improving constraints and their certification in upstream MaxCDCL. Its contribution is certification, not a newly invented faster encoding. | BDD is an encoding candidate. MDD groups require established at-most-one constraints; Pauli support bits must not be assumed mutually exclusive. No wholesale upstream replacement or proof-logging optimization claim. |
| [Improving the Lower Bound in Branch-and-Bound Algorithms for MaxSAT](https://ojs.aaai.org/index.php/AAAI/article/view/33226), AAAI 2025, published 2025-04-11 | Publisher abstract and mechanism description: unlocking reuses soft clauses from discovered cores while preserving lower-bound soundness. | Repository already has unlockReason, seeUnlockLits and lookahead locking machinery. Exact equivalence to the paper is not established, but adding generic unlocking is not a justified new hypothesis. Audit differences before considering a transplant. |
| [An Efficient Core-Guided Solver for Weighted Partial MaxSAT](https://www.ijcai.org/proceedings/2025/295), IJCAI 2025, conference 2025-08-16--22 | Publisher abstract and PDF introduction/references: extended weight stratification and disjoint-core minimization in CASHWMaxSAT. | Current original soft clauses have weight one. Weight stratification provides no immediate differentiation; core-guided control differs from this downstream BnB engine. Not shortlisted. |
| [Enhancing Local Search for MaxSAT with Deep Differentiation Clause Weighting](https://arxiv.org/abs/2512.05619), arXiv submitted 2025-12-05; [publisher text](https://journals.sagepub.com/doi/10.3233/FAIA250891) | Read abstract and publisher methodology/evaluation. Distinguishes partial and weighted partial objectives; reports anytime and hybrid results. Publisher metadata dates differ, so the verified arXiv date is used for eligibility. | Possible later SLS backend comparison, not an additional change in the first SLS experiment. Its weighting and decimation package must not be bundled into our candidate. |
| [SAT, MaxSAT, and SMT for QLDPC Distance Computation: A Large-Scale Empirical Study](https://arxiv.org/html/2606.12445v1), preprint submitted 2026-05-29 | Read formulation/evaluation/conclusion. Domain evidence emphasizes cardinality, bounds and backend interactions; encoding effects vary by solver. | Supports examining objective-bound handling. SAT encoding results do not prove BDD beats our MTO. DistQLDPC is a downstream MaxCDCL-derived application with its own changes; QDistSAT is the benchmark platform. |

IJCAI 2024 papers published in August are outside this window, even if recently
crawled. Older encoding papers may supply background, but are not counted as
recent research. No performance result in these papers is adopted as our result.

## Program inspection and evidence limits

At baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`, Makefile already uses
`-O3 -g -DNDEBUG` but separately compiles Solver.cc, SimpSolver.cc and utilities
without LTO. [GCC 13.3 documentation](https://gcc.gnu.org/onlinedocs/gcc-13.3.0/gcc/Optimize-Options.html)
explains that LTO exposes function bodies across translation units and must be
enabled during compilation and linking. Benefit is a hypothesis, not measured.

Solver.cc already has binary watches and circular lastPoint scans. General
prefetch is therefore not automatically the next improvement. The long-clause
loop in propagateForLK (around line 3932) is a profiling target, not an established
memory bottleneck. addCardinalityConstraints (around line 6195) removes previous
clauses and recycles dynamic variables, then builds an encoding over active
soft literals with k = UB - 1 - nbFalse. This lifecycle constrains encoding trials.
Application initUB is initialized to INT32_MAX at distqldpc.cc:439; the engine
converts/caps it in solve_ (around 6626/6761). Residual costs need explicit review.

No hardware profile was collected in this Brain revision. Do not state that
cache misses, allocation, cardinality construction or call overhead dominate.
For future diagnosis use the unmodified baseline with debug symbols and a
single allowed CPU. Example commands, from a disposable baseline checkout:

```sh
make -j1
perf record -o gb-off.data -g -- taskset -c "$BENCH_CPU" ./bin/distqldpc -no-card -cpu-lim=300 GB_144_12_8
perf report --stdio -i gb-off.data > gb-off.profile.txt
perf record -o gb-mto.data -g -- taskset -c "$BENCH_CPU" ./bin/distqldpc -card-mto -cpu-lim=300 GB_144_12_8
perf report --stdio -i gb-mto.data > gb-mto.profile.txt
```

BENCH_CPU must be observed eligible, not assumed available; check spare CPU >50%
and allocation <= half spare capacity before and during runs. perf must inherit
child sampling because the solver forks. If user perf permission is denied,
record the denial, do not install privileged helpers or resume deferred CPU
isolation. These are diagnostic commands, not Tier 1 measurements; their cap
must not replace the preregistered benchmark timeout. Record compiler, hashes,
kernel, counters, raw profiles and resource telemetry. Profile perturbation is
excluded from scientific timing comparisons.

## Three independent proposals, ranked

### #1 H-007: LTO only (general program optimization)

- Hypothesis/mechanism: cross-translation-unit optimization lowers execution
  overhead without deliberately changing CNF, search heuristics or bounds.
- Scope: one opt-in build setting adds `-flto=1` at compile and link time; clean
  independent baseline/candidate builds with identical GCC 13.3 and other flags.
  No PGO, native architecture tuning, fast-math, prefetch or source refactoring.
- Expected cases: possible benefit across both OFF and MTO; likely limited if
  hot functions are already inlined within Solver.cc. No predicted percentage.
- Risk: code layout may regress instruction-cache behavior; undefined behavior
  may surface under stronger optimization. Do not waive correctness failures.
- Cost: two clean builds, normal Tier 0, then 48 Tier 1 solves (four cases x two
  modes x two binaries x three repetitions). Build serially; no uncontrolled
  `-flto=auto`. Gate failure stops before Tier 2.
- Evidence/falsification: preserve CNF and scientific output, inspect search
  counters, compiler diagnostics and binary sizes. Reproducible total runtime
  is decisive; smaller binaries alone are insufficient. No measurable benefit
  or material regression means no promotion.
- Previous attempts: independent of E001/E002 CNF changes and E003 allocations.
  Lower implementation risk, but a modest engineering hypothesis, not a new
  MaxSAT algorithm or evidence of a large gain.

### #2 H-008: one bounded SLS warm start (recent-paper adaptation)

- Hypothesis/mechanism: one local-search call on the original hard/soft formula
  finds a better feasible objective cap before exact BnB, reducing loose probes.
  Inspired by CP 2025 initial SLS integration; this adaptation is our hypothesis.
- Scope: one SLS implementation, one preregistered fixed seed/flip budget, once
  per solve. Verify original hard clauses, decode original x/z, and independently
  check stabilizer/logical predicates and union Pauli weight. Pass only verified
  cap through initUB after auditing residual-offset and strict-bound conversion.
  Failure to find a feasible witness follows the original exact path.
- Do not import Loandra, core-guided rewriting, core feedback, phase-saving
  transfer, increasing precision or DeepDist's extra mechanisms. A full backend
  dependency requires license/attribution review; one backend choice is frozen
  before testing, without a backend sweep.
- Expected cases: helps only where initial upper bounds are poor; dense parity
  constraints may make feasible SLS solutions hard to find. BB_108 and LP_340
  original-row bounds (12 and 14) leave room, but that is not speedup evidence.
- Risk: confusing original and simplified objective, invalid witness/model,
  RNG instability, preprocessing mappings, and wasted warm-start time. SLS cannot
  certify nonexistence, optimal distance, or a lower bound. Keep exact BnB proof.
  Warm-start time counts inside the existing wall-clock budget and whole-solve
  timing; do not reset the parent timeout or fabricate a RESULT from the cap.
- Cost: substantially more integration than H-007, plus tiny-formula exhaustive
  witness/cost/timeout checks, Tier 0 and 48 Tier 1 solves. Seed variability may
  require a later separately preregistered robustness check, not hidden retries.
- Falsification: no tighter verified cap, overhead exceeding saved search, or
  per-case regression. Report time to witness separately from proof time.
- Previous attempts: H-003 screened original rows only; this searches assignments
  and is a separate concept. Do not combine the row initializer with SLS in one
  experiment. No current evidence shows UB initialization is the main bottleneck.

### #3 H-009: singleton BDD bound encoding (paper-informed representation)

- Hypothesis/mechanism: reduced ordered BDD CNF for the same active sum <= k
  improves propagation/search relative to the existing MTO bound representation.
  The 2026 certification paper supplies formal structure; BDD is an older method,
  not a new 2026 invention and not an empirically established gain here.
- Scope: experimental replacement of the MTO construction at its existing
  call site only; fixed active-literal order, same k, invocation conditions and
  size guard. OFF remains the negative control. Keep public result/bound/timeout
  semantics and accurately identify candidate encoding in retained metadata.
  No incremental tree reuse, inferred AMO groups, variable reordering, threshold
  tuning, bound heuristic or proof logging in this experiment.
- Use singleton groups; arbitrary support bits may simultaneously be true.
  Build/verify the graph before adding clauses, handle terminal nodes exactly,
  and integrate auxiliary-variable/reason/garbage-collection lifetime with the
  current removal lifecycle. Do not retain stale units across bound relaxation.
- Expected cases: MTO-enabled cases sensitive to bound propagation; OFF should
  have no deliberate change. Smaller CNF may still worsen search, as E001 shows.
- Risk/cost: highest correctness burden; unit objective may offer little node
  reduction, and construction can outweigh propagation gains. Require exhaustive
  small n/k projection checks over original literals, boundary/assignment tests,
  dynamic cleanup checks, normal Tier 0 and 48 Tier 1 solves. Update downstream
  patch documentation if embedded engine code changes.
- Falsification: projection mismatch rejects immediately; larger build overhead
  or worse proof time prevents promotion. Log clauses, auxiliaries, construction
  time and search counters, without treating clause counts as speed results.
- Previous attempts: changes objective-bound encoding, not logical XOR basis;
  distinct from H-006 reuse, which retains MTO and changes its lifetime.

## Scheduling recommendation and unchanged gates

Recommend H-007 as the next low-cost single experiment; H-008 is the leading
recent-literature research direction, H-009 the more invasive encoding direction.
This revision withdraws automatic H-003 priority. H-003/H-005/H-006 remain
unimplemented historical candidates, not rejected algorithms or a FIFO queue.
No performance improvement, ACCEPT decision, or next experiment selection is
claimed by this documentation-only research revision.

Each selected trial starts from independent baseline 24572d6, not the current
historical E001 source. Record exact diff, parameters, cost/noise criteria and
commands before implementation. Tier 0 -> Tier 1 (three repetitions per binary,
case and mode) -> conditional Tier 2 LP_340. No Tier 3 yet. Shared/noisy runs
remain diagnostic; user deferral of CPU isolation does not make them controlled.
Scientific mismatch stops immediately. No scientific semantics changed here.
