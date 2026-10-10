# GH-107 Tier0 result — PASS (correctness only; no timing performed by this agent)

Dual-map bound sharing on main's interleaved CSS split, no incremental solver (issue #107; hub #15).
- Preregistration: `PROPOSAL.md`, commit `fc59b7d`, pushed before any code change.
- Branch `experiment/gh-107-dualshare-noinc`, from GH-92 candidate source `e226951` (main 7eadd54 split + GH-85 + GH-87/A1).
- **Candidate source: `0889c59`** (single source commit: `src/core/distqldpc.cc`, `MODIFICATIONS.md`, `NOTICE`; engine
  `src/solver` unchanged). Later commits are tests and records only (`tests/test_split_dualshare.cc` is not linked
  into `bin/distqldpc`).
- Cross-repo branch `ci/xrepo-gh107` = `d22799b` (tree of `0889c59`, single parent `72d1fe1`).
- yfclab2 not used. Every solver/test process ran under the PI 2 GB cap (`capped.py` / `tier0_science.py` ->
  `memlimit.run`, byte-identical copy of `scratchpad/coord/memlimit.py`). **0 MEMOUT**; largest process-group RSS 455 MB.

## Design (as implemented)

- One flag `-dualmode=share|skip|off`:
  - **share (new default).** With a verified XZ-dual map (GH-87 detection, unchanged code), both halves stay in main's
    interleaved driver (Phase 1 doubling, Phase 2a tie rounds, Phase 2b optimise in incumbent order with cap U, a fresh
    solver per probe). After every half probe `dualshare_sync` writes max(lb_X, lb_Z) into both halves (GH-102's
    sharing logic, ported). Main's own skip tests then drop every probe whose NONE the other half already proved
    (Phase 1 `lb > m`; Phase 2 `lb >= U`). UBs stay global; the Phase-2 emitted-LB cap is U under sharing; no new
    probe kind or cap; GH-87's A1 is not used. A synced lb > U (impossible with a verified map) refuses to answer
    (`RESULT -1`). The shared lb enters a fresh half solver only as `initLB`, which is a proven lower bound.
  - **skip** = GH-92 exactly (X half only under a verified map, A1).
  - **off** (alias: GH-92's `-no-dualskip`) = main 7eadd54 exactly (no detection, no extra output).
- `-dualshare-stats` (any mode; off by default) prints one `c dualshare stats:` line with probes, engine conflicts
  per half, and implied skips. off/skip are trace-identical to main/GH-92 (below), so their stats are main's and
  GH-92's work counts.
- Kept unchanged: `-joint`, `-no-symbreak`, `-symbreak-report`, `-dualskip-report`.

## Checks (Mac, Apple clang; `mac.sh`, `raw/mac/run1.log`, 02:45:39-02:57:21 CST 2026-10-11)

| Check | Result |
|---|---|
| `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"` (`build107.log`) | rc 0; 32 warnings, **none in `distqldpc.cc`** (= GH-92) |
| `scripts/smoke_test.sh` (frozen107) | PASS |
| `python3 -B scripts/test_partition_soft_literals.py` | PASS (11 adjacent oracles, 1024 assignments each) |
| `tests/test_partition_soft_literals.cc` oracle | `GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1` |
| **new** `tests/test_split_dualshare.cc`, 20000 instances (`raw/mac/test_split_dualshare.20000.txt`) | **PASS, 0 failures**: 64592 driver runs (4 configs); 8600 instances with a verified map (2737 with orbit clauses on both halves); 2049 with dX != dZ; 17200 shared runs, 6160 with implied skips (17422 skips); 8600 skip-mode runs with 0 Z probes; 107 shared descents |
| Mutants (2000 instances each, `raw/mac/test_split_dualshare.mutations.txt`) | all detected (exit 1): m1 sharing without a verified map (21 failures); m1s = m1 caught by the d/LB/UB checks alone (24); m2 shared lb + 1 (21); m3 skip-mode elimination without a verified map, semantic checks only (23) |
| GH-85 `verify_half_autos.py`, 50 codes x 2 halves | ALL_PASS |
| GH-87 `check_dual_maps.py`, 50 codes | ALL_PASS |
| `-symbreak-report` and `-dualskip-report` vs frozen92, 50 codes each | 100/100 identical (cpu fields masked) |

### Oracle `tests/test_split_dualshare.cc` (adaptation of GH-102's `test_incremental_dualshare.cc` / GH-94's `test_incremental_dualskip.cc`)

- Production `src/core/distqldpc.cc` is included (main renamed). `min_distance_css_interleaved` (the non-incremental
  driver) runs in a forked child with the production bounds pipe, as in `solve_in_child_fork`. The child's stdout
  (`verb=1`) goes to a temp file under `$TMPDIR` and is scanned for the driver lines.
- Instance generator unchanged from GH-94/GH-102: planted dual (family pi or random pi, optional planted shift group so
  the halves get orbit clauses), near misses (one bit flipped), independent halves; n = 4..18.
- Four configurations per instance: share (default), skip, share with `-no-symbreak`, off.
- Checks: RESULT d OPTIMAL = brute-force min(dX, dZ) without symmetry clauses; every emitted LB <= d <= every emitted
  UB; sharing (resp. elimination) reported iff production detection verifies a map; no Z probe after elimination;
  no implied skip without sharing; verified map implies dX = dZ by enumeration; every planted family map detected.

### Trace identities (`traces.sh`, `-v -cpu-lim=120` on both sides, 2 GB cap; `raw/mac/traces/`)

Cases: BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, LP_34_20_2, BB_72_12_6, TN_36_8_4 x {no-card, card-mto, default}.

| Comparison | Result |
|---|---|
| `-dualmode=off -v` vs frozen-main7e `-v` | **21/21 byte-identical** (off prints no dual line at all) |
| `-no-dualskip -v` (alias) vs frozen-main7e | **21/21 byte-identical** |
| `-dualmode=skip -v` vs frozen92 `-v` | **21/21 byte-identical** |
| `-joint -v` vs frozen-main7e `-joint -v` | **21/21 byte-identical** |
| default vs main on codes without a dual map (LP_238_44_6, LP_34_20_2) | **6/6 identical except the single `c dualshare: no dual map ...` line** |
| default on dual-map codes (BB_90, GB_144_12_8, BB_108, BB_72, TN_36_8_4; 15 runs) | differs by design: one `c dualshare: dual map ... verified` line plus 3-5 implied-skip lines. TN_36_8_4 has a verified dual map (blockshift), as in GH-92's Tier0, so it is not an identity case. |
| final `o`, all 21 x {main, GH-92, -joint, off, skip, share} | equal to the named distance: 10/8/10/6/2/6/4 |
| GB_144_12_12 (no-card, card-mto; `-cpu-lim=300`): off vs main, skip vs GH-92 (`raw/mac/workcounts/gb144_12_12_identity.txt`) | 4/4 byte-identical (stats line removed) |

## Informational work counts (`workcounts.sh`, `raw/mac/workcounts/`; no timing claims)

Engine conflicts summed over each half's probes (fresh solver per probe). off = main's search, skip = GH-92's search.

| Code | Mode | off (= main) probes X/Z, conflicts X+Z | share probes X/Z, conflicts X+Z, skips | skip (= GH-92) probes X, conflicts | share/main | skip/main |
|---|---|---|---|---|---:|---:|
| BB_90_8_10 | no-card | 6/6, 4672+3755 = 8427 | 6/1, 4672+1 = 4673, 5 | 6, 4672 | 0.55 | 0.55 |
| BB_90_8_10 | card-mto | 6/6, 3661+4147 = 7808 | 6/1, 3661+20 = 3681, 5 | 6, 3661 | 0.47 | 0.47 |
| BB_108_8_10 | no-card | 7/6, 11866+3985 = 15851 | 6/2, 9279+2272 = 11551, 5 | 6, 10330 | 0.73 | 0.65 |
| BB_108_8_10 | card-mto | 7/6, 15054+3000 = 18054 | 6/2, 12541+2012 = 14553, 5 | 6, 13336 | 0.81 | 0.74 |
| GB_144_12_8 | no-card | 5/5, 961+3403 = 4364 | 5/1, 961+2102 = 3063, 4 | 5, 961 | 0.70 | 0.22 |
| GB_144_12_8 | card-mto | 5/5, 1082+2918 = 4000 | 5/1, 1082+1348 = 2430, 4 | 5, 1082 | 0.61 | 0.27 |
| GB_144_12_12 | no-card | 7/7, 354414+976144 = 1330558 | 6/3, 237320+973567 = 1210887, 5 | 6, 1937192 | 0.91 | 1.46 |
| GB_144_12_12 | card-mto | 6/6, 1367081+410584 = 1777665 | 6/1, 1367081+302781 = 1669862, 5 | 6, 918306 | 0.94 | 0.52 |

What the counts show (all runs give the named distance):
- **share is main's trajectory minus the duplicated refutations.** Every trace has the same FOUND/OPT sequence as
  main. The Z copies of the Phase-1 NONE probes (caps 1, 2, 4, 8) and the second half's final optimise or tie probe
  are skipped (`... skipped (NONE implied ...)` / `(lb = UB implied, shared)`). So share's probes are a subsequence of
  main's on every case here, and the conflicts are <= main's.
- **GB_144_12_12 no-card (GH-92's 1.95x case).** share 0.91x main's conflicts against skip's 1.46x. The Z half finds 14
  and proves OPT 12 (973k conflicts). X's duplicate `optimize cap 12` (117k) is skipped. GH-92 instead makes X
  descend 16 -> 12 alone (1.94M). The hard-half penalty is gone.
- **The price: share keeps only part of GH-92's gain where the second half's solution-finding probe is expensive.**
  GB_144_12_8 0.61-0.70 (GH-92 0.22-0.27), GB_144_12_12 card-mto 0.94 (GH-92 0.52). After both halves' Phase-1
  FOUND, main's schedule still has the Z half re-find an incumbent at cap 16. The probe is guaranteed FOUND by pi, but
  not free (GB_144_12_12 card-mto: Z cap 16 = 303k conflicts). On BB codes share is close to GH-92 (BB_90 equal,
  BB_108 0.73-0.81 vs 0.65-0.74).
- These are conflict counts, not wall times. The coordinator's timing decides.

## Science sweep (`science.sh`, `raw/tier0-science-01/`, `raw/tier0-science-01.log`)

- Run on the Mac under the timing lock. The script waited for `mac.sh` to finish (at most 4 parallel jobs) and for
  the lock to be absent. It took the lock at 02:57:41 CST 2026-10-11 ("GH-107 Tier0 science sweep ...") and released
  it at 04:05:35 (verified absent afterwards).
- Harness: GH-102's `tier0_science.py` (GH-60/GH-94 harness + 2 GB cap) unchanged; 50 codes x {default, no-card,
  card-mto, card-sinz}, 60 s, `--jobs 4`.
- Binaries: baseline **main 7eadd54** `frozen-main7e/distqldpc` (6bdcaa25...), candidate `frozen107/cand/distqldpc`
  (68338e32...). Walls are not timing evidence (4 parallel jobs).

Results:
```
{"both_done": 71, "only_cand_done": 1, "only_base_done": 2, "problems": 0, "memout_base": 0, "memout_cand": 0} ALL_OK
POSTHOC_PASS   (candidate timeouts 128, all with a d_lb; timeout in both 126: candidate final d_lb higher 0, equal 126, lower 0)
check_sweep.py VERDICT PASS (0 abnormal candidate exits)
```
- **200/200 OK, zero unsound bounds.** Every completed value equals the named distance, and every emitted
  d_lb <= d <= d_ub. 0 MEMOUT.
- Completed only by the candidate: BB_144_14_14 card-sinz (d=14, 58.7 s).
- Completed only by main: LP_544_80_12 card-mto and default (d=12, main 58.4 / 58.6 s against the 60 s limit).
  LP_544 has no dual map, so the candidate runs main's search exactly there (trace identity above: identical apart
  from one report line). This is a boundary effect under 4-job load, not a semantic difference (GH-102 saw the same
  cells).
- GB_144_12_12 times out at 60 s for both binaries in all modes (it needs about 60-140 s single-job). TN_648_10_71
  (name known wrong) and TN_648_14_50 time out for both with final d_lb 9. Sound.

## Hosted (`raw/hosted/cross-repo-38077114639.txt`)

- `ci/xrepo-gh107` = `d22799b` (tree of `0889c59`, parent 72d1fe1).
- CI https://github.com/guluchen/DistQLDPC/actions/runs/38077108280: success.
- QDistSAT cross-repo https://github.com/guluchen/DistQLDPC/actions/runs/38077114639: success, **scientific match YES**
  (LP_136_32_4 d=4, BB_108_8_10 d=10, no-card and card-mto). Shared-runner times are informational only.

## Frozen binary for the coordinator (`frozen-binaries.sha256`)

| Role | Path (under the workspace root) | sha256 |
|---|---|---|
| **candidate GH-107** (`0889c59`, default `-dualmode=share`; `-dualmode=skip` = GH-92, `-dualmode=off` = main), read-only | `frozen107/cand/distqldpc` | `68338e32e891b5514ebbbc26f881659a92805931601a03d984411be8128fbfd5` |
| gate main 7eadd54 | `frozen-main7e/distqldpc` | `6bdcaa2523cdcbeae5164cedbf54c9ac0f9e64f9a91c3da7ef4b804df393db9d` |
| GH-92 | `frozen92/cand/distqldpc` | `49e37dee170eb6685344aefd25b37bdb1dccc129d640d6802ded25562b51d28f` |
| GH-102 | `frozen102/cand/distqldpc` | `e1801a58a33db97c638fbdd0ad4235928956c3474a6225caed6cd0fca362d4e1` |

Decision: **Tier0 PASS** (state TIER0_PASS / waiting for the coordinator's timing).

Suggested timing cells (coordinator): GH-107 default vs main on the dual-map Tier3 cases. GB_144_12_12 no-card is the
case to check against GH-92's 1.95x; card-mto is the case to check against GH-102's 1.34x. From the work counts,
expect share to be <= main everywhere but to keep less than GH-92's gain on GB codes. Non-dual codes run main's search
exactly (trace-identical), so only detection cost (milliseconds) separates them.

## Deviations from the plan

- `-no-dualskip` is kept as an alias of `-dualmode=off`, so GH-92-style invocations keep working.
- The dual report line exists only in share/skip modes. off runs no detection, so off is fully byte-identical to main
  (stronger than "except the dual report line").
- TN_36_8_4 has a verified dual map, so "LP/TN default == main" holds for the LP codes only. TN_36's default differs by
  design (5 dual-map codes, 15 runs). No TN code without a dual map was in the trace set.
- Mutant m3 (skip-mode elimination without a verified map) was added alongside the preregistered m1/m2.
- The work counts for main and GH-92 come from this binary's `-dualmode=off/skip -dualshare-stats`. They are valid
  because those modes are byte-identical to frozen-main7e/frozen92 on all 21 trace cases and on GB_144_12_12
  (4/4 extra identity runs).
- `tests/test_split_dualshare.cc` is not added to `ci.yml` (token lacks `workflow` scope, as for GH-89/GH-94/GH-102).
