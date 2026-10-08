# GH-34 result — INCONCLUSIVE / NOT ADOPTED (small consistent gain, search unchanged)

| Field | Value |
|---|---|
| Agent / issue | `mac-litvals-20261009` / https://github.com/guluchen/DistQLDPC/issues/34 |
| Selected hypothesis | GH-34-A: literal-indexed assignment mirror for `Solver::value(Lit)` |
| Unselected | GH-34-B ternary-clause fast path; GH-34-C prioritised lookahead propagation (PoS 2023) |
| Baseline SHA | 24572d6d09cce9a4a5faa58300a89e0feba9da6a |
| Candidate (production src) | a1b90ad (`src/` tree de939e35b12ea420e22988a2d580d6988f825046); later commits are records only |
| PR | https://github.com/guluchen/DistQLDPC/pull/35 (draft, not for merge) |
| Host | Apple M6 Mac mini, 12 logical CPUs, macOS 27, Apple clang 21.0.0; user-authorised; sole runner |
| Build | `make CXX="c++ -Wno-reserved-user-defined-literal"` both versions; original flags |
| Binaries | baseline ac43af52…6eb26, candidate 0549c4ec…61b8b (full hashes in TIER0_RESULT.md) |
| Reached tier | Tier1 (gate INCONCLUSIVE) + one preregistered exploratory LP_340 Tier2 |
| Disposition | **INCONCLUSIVE / NOT ADOPTED**; no Tier3; formal controlled status unmeasured |

## Science
- Tier0 local PASS: bit-exact LITVALS_CHECK 24/24; trace identity on 50 codes x 4 modes
  (52 completed byte-identical; timeouts prefix-consistent after a disclosed post-hoc
  comparator fix); preregistered 60 s check 152/152 OK with 10 newly completed runs byte-identical (TIER0_60S_RESULT.md); timeout outputs
  identical. Hosted CI and QDistSAT cross-repo: SUCCESS, scientific match YES.
- 220 timed solves (208 Tier1 + 12 Tier2), all correct, identical emitted bounds.

## Performance (diagnostic; unpinned desktop host)
| Set | OFF median ratio (geomean) | MTO median ratio (geomean) | Judge |
|---|---:|---:|---|
| Tier1 gate 3+3 | 0.99264 (env 1.00580) | 0.99068 (env 0.99443) | not positive either mode |
| Tier1 replication 10 pairs | 0.98970 (env 1.00329) | 0.98994 (env 0.99861) | supplementary |
| LP_340 exploratory 3+3 | 0.9949 | 0.9973 | direction consistent |

14 of 16 Tier1 case/mode medians favour the candidate; no non-overlapping
regression anywhere; several non-overlapping improvements (Tier1 gate 4 cells,
replication 5, LP_340 MTO).

## Why not adopted
The fixed GH16 judge was not met (GB144 OFF +0.05%, LP238 MTO +0.06% medians, OFF
envelope >= 1). The gain is about 1% on Tier1 and 0.3–0.5% on LP_340; it was not
isolated from code-layout effects and comes from one interactive host. Per policy a
Tier1 INCONCLUSIVE cannot be promoted; acceptance would need controlled
dedicated-server runs.

## What the next agent should learn
1. Profiling: on this engine `propagateForLK` is ~70% of self time on LP_340, and
   58–82% of its long-watcher visits end at a single blocker `value(Lit)` check.
   Hot-loop work is dominated by watcher scanning, not clause inspection.
2. Removing the sign-xor from `value(Lit)` changes the machine code as intended
   (`ldrb`+`cmp`, no `and`/`eor`) but buys at most ~0.5–1%: the loop is bound by
   loads and branches, not ALU ops. Further micro-ALU work there is unlikely to pay.
   Larger wins likely need fewer watcher visits (e.g. B: ternary handling, or
   algorithmic lookahead changes such as GH26 FLA) rather than cheaper visits.
3. Search-identical candidates allow a very strong, cheap correctness oracle:
   byte-identical `-v` traces (they print exact conflict/UP counters). Trace
   comparisons on timeouts must separate the child log from the parent's trailer.
4. Apple clang needs `-Wno-reserved-user-defined-literal` for the pinned baseline;
   the Makefile has no header dependencies, so header-only edits need `make clean`.
5. Mac M6 timings for these cases are very stable (LP_340 spread ~0.2–0.6%), which
   makes 3+3 sub-1% effects partly resolvable; still not a controlled environment.

## Follow-up prerequisites
- Controlled dedicated-server Tier1 (Linux/GCC) of the unchanged a1b90ad candidate,
  with the same judge, if the integrator wants to resolve INCONCLUSIVE.
- A code-layout control (its own separate experiment) before attributing the ~1% to
  the mechanism.
- Interaction with GH27 (enqueue inlining touches the same assignment writes) needs a
  separate interaction experiment; do not combine silently.

## Records
PROPOSAL.md (preregistration, b51fab3), ATTEMPTS.md (failed first candidate,
harness STOP, review), TIER0_RESULT.md, TIER0_60S_PLAN.md / TIER0_60S_RESULT.md,
TIER1_RUN.md, TIER1_RESULT.md, TIER2_EXPLORATORY.md, TIER2_EXPLORATORY_RESULT.md,
raw/ (all logs, samples, telemetry), raw-sha256.json (manifest of raw/).
