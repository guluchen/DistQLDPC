# GH-76 result: persistent per-half solver with resumable capped probes — Tier0

Session `mac-incremental-20261009`; issue #76; draft PR #81; hub #15.
Baseline (corrected source) `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7`. Candidate `b3d6b5d`
(preregistration `4f570b2` committed before code). Cross-repo branch `ci/xrepo-gh76` = `94deab6`
(tree of `b3d6b5d`, single parent `72d1fe1`). State: TIER0_PASS (Tier1/Tier2 to be run by the coordinator).

## Feasibility findings (src/solver/Solver.cc line numbers at b3d6b5d)
* `solve_()` (6525) cannot be re-entered on the same object: its prologue redoes preprocessing and resets
  bookkeeping (`feasible`, `infeasibleUB`, `fixedCostBySearch`, soft-literal lists); its l_True branch
  re-bases costs (`fixedCostBySearch += falseLits.size(); beginning = trail.size()`, 6799).
* MaxCDCL already carries state across bound changes inside one run, via exactly two transitions:
  * raise after `UB=k fails`: `cancelUntilBeginning(beginning)` (6765; 5148) drops every level-0 unit derived
    after preprocessing; `removeLearntClauses()` (6776; 5110) drops all learnt tiers (core/tier2/local),
    `hardens`, `cardinalityC`, `isetClauses` and recycles dynVars. MaxCDCL does not track bound independence
    (soft-conflict learning, lookahead/iset clauses, hardening and the cardinality encoding depend on UB, and
    hard-conflict learnts can rest on bound-dependent level-0 units dropped from learnt clauses by analysis),
    so on a raise nothing learnt can be kept without new provenance tracking (GH-76-B, not selected).
  * fall at a solution: `UB = falseLits.size(); cancelUntil(0)` inside `search()` (3828), everything kept;
    `search()` then replaces `cardinalityC`/`hardens` (`prevUB > UB`, 3534). Clauses valid under a looser
    bound remain valid under a tighter one.
  * once `feasible`, `reduceClause`/`simplereduceClause` (1582/458: `if (feasible || c.learnt())`) also
    shorten ORIGINAL clauses with bound-dependent reasons, which no reset undoes: after the first solution of
    an instance its UB must never rise above the UB in force since.
  * `addCardinalityConstraints()` (6208) skips when `UB == card_prevUB` (6211); with the transitions above the
    UB after a removal never equals the last encoded UB (strict raise after a fail; strict fall otherwise).
* Hence a sound incremental scheme exists if probes are restricted to those transitions. The GH-73 schedule
  already satisfies them per half (phase-1 caps rise only before the half's first solution; afterwards caps
  only fall, and a refutation after a solution finishes the half). Implemented as `incPrepare()` (6884, the
  `solve_()` prologue) and `incProbe()` (6977, the loop body for one bounded test, with the fail-path reset
  before any raise, phase/restart state carried over after a solution, and `INC_REBUILD` for a raise after
  `feasible`; the driver then builds a fresh instance with its proven LB).

## Tier0 evidence
| Check | Host | Result |
|---|---|---|
| build (clang 21 Mac; GCC 13.3 yfclab2), warnings unchanged vs baseline on Mac (34/34) | both | PASS |
| `scripts/smoke_test.sh` | both | PASS |
| mandatory fixture `tests/fixtures/partition-retired-soft.wcnf` (sha256 ae851ec8…, optimum 5) + 11 adjacent oracles; `tests/test_partition_soft_literals.cc` (80+1) | both | PASS |
| new `tests/test_incremental_probes.cc` (probe sequences on persistent instances vs exhaustive enumeration, incl. forced raise-after-solution -> rebuild) | Mac 20000 inst / 91872 probes / 154 rebuilds; yfclab2 100000 inst / 458595 probes / 725 rebuilds | PASS, 0 failures |
| `-joint -v` traces byte-identical to fresh 72d1fe1 build, BB_90/GB_144_12_8/BB_108/LP_238 x {default,no-card,card-mto,card-sinz} | Mac | 16/16 IDENTICAL (`raw/joint-identity/`) |
| GH-60 `tier0_science.py` (unchanged copy), 50 codes x 4 modes, 60 s, `--jobs 4` (8 processes, server rule) | yfclab2 | ALL_OK: both done 53, only candidate done 9, only baseline done 0, problems 0 (`raw/yfclab2-tier0-base72/`) |
| anytime LB on the 138 runs timing out in both | yfclab2 | candidate emits d_lb in 138/138 (baseline 138/138); candidate final LB higher in 136, lower in 2 (TN_496_2_32 card-sinz 5 vs 8, xu_42 card-sinz 3 vs 4; informational, all sound) |
| correctness vs GH-73 (b3a2fd9 built on yfclab2, same harness with GH-73 as "base") | yfclab2 | ALL_OK: both done 61 with identical values, only GH-76 done 1 (TN_200 no-card), only GH-73 done 2 (TN_200 default/card-mto: GH-73 16.6 s, GH-76 timeout at 60 s under shared-server load), problems 0 (`raw/yfclab2-vs-gh73/`) |
| QDistSAT cross-repo (LP_136_32_4, BB_108_8_10; no-card, card-mto) | GitHub run 37905193929 | success, scientific results match YES |
| hosted CI on PR #81 / push | GitHub | success |

A partial serial Mac sweep (13 jobs, all OK, `raw/mac-tier0-partial/`) was stopped when the coordinator moved
correctness work to yfclab2; it is retained, not pooled.

Binaries (sha256): Mac frozen candidate `frozen76/cand/distqldpc` 67a7a7d78ebfae4690365d8a954cfa6e821a40cdcb8b346ec704792fe7bd165e
(for Tier1/Tier2 timing on the Mac); Mac fresh baseline `frozen76/base/distqldpc` 80a591ebc233d116ae537c74c4cd0fbaaf23dba13cd55f1a7f13e31f8aa8fab8.
yfclab2 (`~/mac-agent-20261009/gh76-frozen/`): cand ea91c0e0e7113922feba517a51c0c30ea2fd861c10c9c6c3bcc575ca5f12d6a5,
base 85e70f20c06b2a8662e5d59898ebd97c7deed9c4a5d6723026c92856ed298952, gh73 1268357982f8478e7d44065740c9ebc06acbfa6dcff3b945b9617798212b2d0b.

No timing comparison was made by this agent (wall times inside the harness JSON are incidental and not evidence).

## Risks / limitations
* Soundness rests on restricting probes to MaxCDCL's native bound transitions; the enumeration oracle covers small
  instances only. Every reported half weight is independently re-checked against its witness (parity, logical,
  weight) in the driver; lower bounds have no such certificate (they come from refutations, as in baseline/GH-73).
* `incPrepare()` duplicates the `solve_()` prologue (kept separate so `solve_()`/`-joint` stay untouched); future
  engine edits to the prologue must be mirrored.
* Phase/restart state now carries over between probes after a solution (heuristic choice, differs from GH-73's
  fresh runs); performance effect unknown until Tier1.
* The new test could not be added to `ci.yml` (token lacks `workflow` scope); command:
  `g++ -Isrc/solver -O3 -DNDEBUG -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS tests/test_incremental_probes.cc build/{SimpSolver,Solver,Options,System}.o -lz -o build/test_incremental_probes && build/test_incremental_probes 20000 >/dev/null`.
* TN_200_10_10 (asymmetric, dX=14 > dZ=10) sits near the 60 s limit on the loaded server for all three binaries; GH-76 timed out in default/card-mto where GH-73 finished (no timing conclusion; the coordinator should include TN_200 in a Tier1 diagnostic). Against the baseline there is no timeout regression (only-baseline-done = 0).
* GCC warns about `%llu` with `uint64_t` in the new debug printf (same pattern as existing engine prints; output only).
