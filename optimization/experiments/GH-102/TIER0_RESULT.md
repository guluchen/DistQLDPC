# GH-102 Tier0 result — PASS (correctness only; no timing performed by this agent)

GH-89 + dual-map bound sharing (issue #102; hub #15).
- Preregistration: `PROPOSAL.md`, commit `871e559`, pushed before any code change.
- Branch `experiment/gh-102-dualmap-bound-sharing`, from GH-89 candidate source `09d8bc2`.
- **Candidate source: `69f91c1`** (single source commit: `src/core/distqldpc.cc`, `MODIFICATIONS.md`, `NOTICE`).
  Later commits are tests and records only (`tests/test_incremental_dualshare.cc` is not linked into `bin/distqldpc`).
- Cross-repo branch `ci/xrepo-gh102` = `90affd0` (tree of `69f91c1`, single parent `72d1fe1`).
- yfclab2 not used. Every solver/test process ran under the PI 2 GB cap (`capped.py` / `tier0_science.py` ->
  `memlimit.run`, copy of `scratchpad/coord/memlimit.py`; macOS process-group RSS poll). **0 MEMOUT.**

## Design (as implemented)

- Dual-map detection = GH-94's code path verbatim (`find_dual_maps`, `candidate_family(n, with_identity)`;
  `-dualskip-report` kept, output identical to GH-94).
- With a verified map (default, **variant A**) both halves stay in GH-89's interleaved search. After every half probe
  `dualshare_sync` writes max(lb_X, lb_Z) into both halves. GH-89's own skip tests then drop every probe whose NONE
  the other half already proved (Phase 1 `lb > m`, Phase 2 `lb >= U`). UBs stay global. Under sharing the Phase-2
  emitted-LB cap is U. A synced lb > U (impossible with a verified map) makes the driver refuse to answer (RESULT -1).
- **Variant B** (`-dualshare-b`): after Phase 1 only the X half runs possibly-NONE probes (cap U-1, first-only); the Z
  half only runs cap-U first-only probes when its incumbent is worse than U (must succeed by pi; a NONE is refused).
- `-no-dualshare` = GH-89 exactly (no detection, no extra output). `-dualshare-stats` (with `-v`) prints one
  `c dualshare stats:` work line. Kept: `-joint`, `-no-symbreak`, `-symbreak-report`, `-dualskip-report`.
- Engine (`src/solver`) unchanged. Work counters (`probes`, `conflicts`, `own_lb`) were appended to `CssHalf`
  (value-initialised; existing aggregate initialisers in tests compile unchanged).
- Incremental contract: A adds no probe kind and no cap. Each half's cap sequence is a subsequence of GH-89's, and the
  shared lb enters the engine only as `knownLB`. GH-94's A1 is not used (no half is solved alone). B's caps are falls
  after a half's first solution (target <= inc_sup <= inc_ceil). 0 `half rebuilt` lines in all traces.

## Default variant: A (reasoning + work counts)

Informational work counts (`workcounts.sh`, `raw/mac/workcounts/`, `-v -cpu-lim=120 -dualshare-stats`; engine
conflicts summed over a half's probes; **no timing claims**):

| Code | Mode | -no-dualshare (= GH-89 search) probes X/Z, conflicts X+Z | A probes X/Z, conflicts X+Z, implied skips | B probes X/Z, conflicts X+Z, implied skips |
|---|---|---|---|---|
| BB_108_8_10 | no-card | 7/7, 4438+3825 = 8263 | 5/2, 2535+1877 = **4412**, 5 | 7/2, 7656+835 = 8491, 4 |
| BB_108_8_10 | card-mto | 7/7, 4456+4630 = 9086 | 5/2, 2399+2973 = **5372**, 5 | 7/2, 8002+1098 = 9100, 4 |
| BB_90_8_10 | no-card | 7/7, 2892+3545 = 6437 | 5/2, 1590+1855 = 3445, 5 | 6/1, 2806+1 = **2807**, 4 |
| BB_90_8_10 | card-mto | 7/7, 3133+3781 = 6914 | 5/2, 1737+1964 = 3701, 5 | 6/1, 2984+20 = **3004**, 4 |
| GB_144_12_8 | no-card | 5/5, 1248+3178 = 4426 | 5/1, 1248+2102 = **3350**, 4 | identical to A (3 skips) |
| GB_144_12_8 | card-mto | 5/5, 1285+1850 = 3135 | 5/1, 1285+1348 = **2633**, 4 | identical to A (3 skips) |

For comparison, GH-94 (X half only) issues 6/6/5 X probes on BB_108/BB_90/GB_144. Its conflicts are not
instrumented (frozen94 has no stats flag).

What the counts show:
- **Variant A, BB codes.** The X half's Phase-1 refutations (caps 1, 2, 4, 8) are each proven once, and the Z half's
  copies are skipped (4 skips).
- **BB_108 no-card (the GH-94 regression case).** The Z half now finds 12 directly under cap 16. It descends to
  OPT 10, proving that no weight <= 9 exists, and the X half's duplicate final proof is skipped (`X half optimize
  cap 10 skipped`). That is GH-89's trajectory minus the duplicated refutations.
- **GB_144.** After both halves find 8, the X half proves NONE at cap 7 and the Z copy is skipped. What remains, compared
  with GH-94, is the Z half's guaranteed-FOUND probe at cap 8 (2102 / 1348 conflicts).
- **Total conflicts, A vs -no-dualshare.** 0.53 / 0.59 (BB_108), 0.54 / 0.54 (BB_90), 0.76 / 0.84 (GB_144).
- **Variant B** has the leader re-find and descend alone. That is about 2x A's work on BB_108 (8491 / 9100, about
  the same as no sharing), and 0.81x A on BB_90, where the Z half happened to find 10 at once. Equal to A on GB_144.
- **Default: A.** A is a strict sub-schedule of GH-89's probes, and B loses on the regression case that motivates
  this issue. B stays available as `-dualshare-b` for the coordinator.

## Checks (Mac, Apple clang; `mac.sh`, `raw/mac/run1.log`, 23:03:41-23:07:25 CST 2026-10-10)

| Check | Result |
|---|---|
| `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"` (`build102.log`) | rc 0; 32 warnings, **none in `distqldpc.cc`** (= GH-94) |
| `scripts/smoke_test.sh` (frozen102) | PASS |
| `python3 -B scripts/test_partition_soft_literals.py` | PASS (11 adjacent oracles, 1024 assignments each) |
| `tests/test_partition_soft_literals.cc` oracle | `GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1` |
| GH-76 `tests/test_incremental_probes.cc` (unchanged), 20000 | PASS, 0 failures; probes 91872 / rebuilds 154 (= GH-76/GH-89/GH-94 records) |
| GH-89 `tests/test_incremental_symbreak.cc` (unchanged), 20000 | PASS, 0 failures; probes 106247, rebuilds 308, sym none/unit/chain 4807/12134/3059 (= GH-89/GH-94 records) |
| **new** `tests/test_incremental_dualshare.cc`, 20000 (`raw/mac/test_incremental_dualshare.20000.txt`) | **PASS, 0 failures**: 64592 driver runs (4 configs); 8600 instances with a verified map (2737 with orbit clauses on both halves); 2049 with dX != dZ; 25800 shared runs, 9240 with implied skips (24932 skips); 8617 B-mode Z feasibility probes; 128 shared descents |
| Mutants (2000 each, `raw/mac/test_incremental_dualshare.mutations.txt`) | all detected (exit 1): m1 share without verified map (25 failures); m1s = m1 caught by the d/LB/UB checks alone (24); m2 shared lb + 1 (21); m3 B follower cap U-1 (2) |
| GH-85 `verify_half_autos.py`, 50 codes x 2 halves | ALL_PASS |
| GH-87 `check_dual_maps.py`, 50 codes | ALL_PASS |
| `-symbreak-report` and `-dualskip-report` vs GH-94 binary, 50 codes each | 100/100 identical (cpu fields masked) |

### New oracle `tests/test_incremental_dualshare.cc` (port of GH-94's dual-path oracle)

- Production `src/core/distqldpc.cc` is included (main renamed). `min_distance_css_interleaved` runs in a forked child,
  as in `solve_in_child_fork`, with the production bounds pipe. The child's stdout (`verb=1`) goes to a temp file that
  is scanned for the GH-102 lines.
- The instance generator is GH-94's, unchanged: planted dual (family pi or random pi, optional planted shift group so
  the halves get orbit clauses), near misses (one bit flipped), independent halves; n = 4..18.
- Four configurations per instance: A (default), B, A with `-no-symbreak`, and `-no-dualshare` (= GH-89).
- Checks:
  - RESULT d OPTIMAL = brute-force min(dX, dZ), enumerated without symmetry clauses;
  - every emitted LB <= d <= every emitted UB;
  - the driver reports sharing iff production detection verifies a map;
  - a verified map implies dX = dZ by enumeration;
  - every planted family map is detected.
- Parsing fix compared with GH-94: `RESULT -1 UNKNOWN` is no longer read as a result with d = -1. It now counts as no
  answer, while still failing the d check.
- Full classification of mutant m1 (`raw/mac/m1_semantic_full.txt`; semantic checks only, failure cap lifted, 2000
  instances): 360 failing runs, of which 35 report a **wrong value as OPTIMAL** and 325 are refused by the consistency
  guard; about 585 emitted LB > d. So the oracle catches unverified sharing directly, and the guard turns most of it
  into refusals.

### Trace identities (`traces.sh`, `-v -cpu-lim=120` on both sides, 2 GB cap; `raw/mac/traces/`)

Cases: BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, LP_34_20_2, BB_72_12_6, TN_36_8_4 x {no-card, card-mto, default}.

| Comparison | Result |
|---|---|
| `-no-dualshare -v` vs frozen89 | **21/21 byte-identical** |
| `-joint -v` vs main 7eadd54 `-joint -v` | **21/21 byte-identical** |
| `-joint -v` vs 72d1fe1 (frozen73n, joint encoding by default) | **21/21 byte-identical** |
| default vs frozen89 on LP codes (no dual map) | **6/6 identical except the single `c dualshare: no dual map ...` line** |
| default on dual-map codes (15 runs) | differs by design: one `c dualshare: dual map ... verified` line, 3-5 implied-skip lines, `solver builds X 1, Z 1`, 0 rebuilds |
| final `o`, all 21 x {gh89, gh94, 72d1fe1, cand -joint, cand A, cand B} | equal to the named distance: 10/8/10/6/2/6/4 |

## Science sweep (`science.sh`, `raw/tier0-science-01/`, `raw/tier0-science-01.log`)

- Run on the Mac under the timing lock. The script waited until `mac.sh` had finished (at most 4 parallel jobs) and
  until the lock was absent; it took the lock at 23:17:29 CST 2026-10-10 ("GH-102 Tier0 science sweep ...") and
  released it at 00:25:18 CST 2026-10-11 (verified absent afterwards).
- Harness: `tier0_science.py` = GH-60/GH-94 harness plus the 2 GB cap (`memlimit.run`, status MEMOUT); 50 codes x
  {default, no-card, card-mto, card-sinz}, 60 s, `--jobs 4`.
- Binaries: baseline **main 7eadd54** `frozen-main7e/distqldpc` (6bdcaa25...), candidate `frozen102/cand/distqldpc`
  (e1801a58...). Wall times are not timing evidence (4 parallel jobs).

Results:
```
{"both_done": 71, "only_cand_done": 3, "only_base_done": 2, "problems": 0, "memout_base": 0, "memout_cand": 0} ALL_OK
POSTHOC_PASS   (candidate timeouts 126, all with a d_lb; timeout in both 124: candidate final d_lb higher in 2, lower in 0)
check_sweep.py VERDICT PASS (0 abnormal candidate exits)
```
- **200/200 OK, zero unsound bounds.** Every completed value equals the named distance, and every emitted
  d_lb <= d <= d_ub. 0 MEMOUT; the largest process-group RSS seen was 452 MB.
- Completed only by the candidate: BB_144_14_14 card-sinz (d=14, 51 s), GB_144_12_12 no-card (d=12, 29 s),
  LP_544_80_12 no-card (d=12, 49 s).
- Completed only by main: LP_544_80_12 card-mto and default (d=12). Main finished at 58.3 s, against the 60 s limit.
  LP_544 has no dual map, so on it the candidate runs GH-89's search. These are boundary effects, not timing
  evidence; LP_544 is a cell to watch in Tier2/3, as GH-98 also noted.
- TN_648_10_71 (name known wrong) and TN_648_14_50 time out on both binaries in every mode with final d_lb 9 on both;
  no d_ub emitted. Sound; reported, not blamed.

## Hosted (`raw/hosted/cross-repo-38062114288.txt`)

- `ci/xrepo-gh102` = `90affd0` (tree of `69f91c1`, parent 72d1fe1).
- CI https://github.com/guluchen/DistQLDPC/actions/runs/38062113897: success.
- QDistSAT cross-repo https://github.com/guluchen/DistQLDPC/actions/runs/38062114288: success, **scientific match YES**
  (LP_136_32_4 d=4, BB_108_8_10 d=10, no-card and card-mto). Shared-runner times are informational only.

## Frozen binary for the coordinator (`frozen-binaries.sha256`)

| Role | Path (under the workspace root) | sha256 |
|---|---|---|
| **candidate GH-102** (`69f91c1`, default = variant A; `-dualshare-b` = B), read-only | `frozen102/cand/distqldpc` | `e1801a58a33db97c638fbdd0ad4235928956c3474a6225caed6cd0fca362d4e1` |
| primary attribution GH-89 | `frozen89/cand/distqldpc` | `fb6846d0613b187a881e08071729e36629bc10775a4aad34e3d5df34d3d1ff37` |
| secondary GH-94 | `frozen94/cand/distqldpc` | `4a15a105198094768c45433c516ef9f7b81e22fbbf028abbc5daa4d94050d69a` |
| gate main 7eadd54 | `frozen-main7e/distqldpc` | `6bdcaa2523cdcbeae5164cedbf54c9ac0f9e64f9a91c3da7ef4b804df393db9d` |

Decision: **Tier0 PASS** (state TIER0_PASS / waiting for the coordinator's Tier1+).

Suggested Tier1 cells (coordinator): GH-102 default vs main (gate), vs GH-89 (primary: expect ~1.0 on LP and gains
on BB_90 / GB_144 / BB_108), vs GH-94 (BB_108 no-card is the case to watch). `-dualshare-b` is optional.

## Deviations from the plan

- `tier0_science.py` was changed in one place only: solver processes now run under the 2 GB cap through
  `memlimit.run`, and a `MEMOUT` status was added. Everything else is the GH-60/GH-94 harness.
- `-dualshare-stats` is a new flag that was not in the issue. It only adds output and is off by default.
- The oracle's result parser was tightened (see above).
- The `-joint` identity was checked against both main 7eadd54 `-joint` and 72d1fe1.
- `tests/test_incremental_dualshare.cc` is not added to `ci.yml`, because the token lacks `workflow` scope (as for
  GH-89/GH-94).
