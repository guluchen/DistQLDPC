# GH-89 result: incremental half solver with per-half symmetry breaking (GH-85 x GH-76): Tier0

Session `mac-split-symbreak-inc-20261009`; issue #89; draft PR #91; hub #15.
- Baseline (corrected source): `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7`.
- Preregistration: `654ede6`, committed before any code.
- Candidate source: `09d8bc2`. The evidence commits that follow change no source.
- Cross-repo branch: `ci/xrepo-gh89` = `946953e` (tree of `09d8bc2`, single parent `72d1fe1`).
- State: **TIER0_PASS**. Tier1/Tier2 are for the coordinator. This agent made no timing comparison.

## Construction and conflict resolution
- Candidate = GH-76 `b3d6b5d` (whole `src/`, `tests/test_incremental_probes.cc`) + GH-85 delta `cad2c70..cc7e5ea` (`distqldpc.cc`), applied with `git apply -3`.
- `src/solver/` is byte-identical to GH-76 `b3d6b5d`. GH-85 changed no engine file beyond GH-73's hooks, and GH-76 had already replaced those.

Three conflict hunks, all in `src/core/distqldpc.cc`:
1. `struct CssHalf`: both member sets are kept (GH-76 `S`, `n`, `builds`; GH-85 `sb_orbit`, last so aggregate initialisation still works).
2. `run_css_half`: GH-76 body (persistent instance, `incProbe`, rebuild on `INC_REBUILD`, witness check). GH-85's per-probe `build_css_half(..., sb_orbit)` call disappears, so **nothing is added per probe**.
3. `hs[]` initialiser: GH-76's, followed by GH-85's once-per-half detection. Detection runs before Phase 1, before any half solver exists.

Non-conflicting fix-up:
- `css_half_build` (GH-76's only construction site: first probe and every `INC_REBUILD`) now passes `h.sb_orbit` to `build_css_half`. The orbit clauses are therefore part of the persistent instance from construction, and identical in every rebuild.
- Comments mark this (GH-89). `MODIFICATIONS.md`/`NOTICE` merge both parents' rows plus a GH-89 row.

Flags:
- `-no-symbreak`: GH-76.
- `-joint`: baseline.
- `-symbreak-report`: GH-85; output identical to GH-85 for all 50 codes.
- GH-76 has **no non-incremental switch**, so GH-85 behaviour is reproduced by GH-85's own binary. The alternative that would add one (GH-89-B) was not selected.

Soundness: see PROPOSAL.md. The clauses preserve, at every w, whether a half solution of weight <= w exists (GH-85, reviewed). GH-76 probes are exact for a fixed formula. So NONE, FOUND, OPT and the proven LB fed into rebuilds are exact for the half without the clauses.

## Tier0 evidence
| Check | Host | Result |
|---|---|---|
| Build: Mac clang (`make -j2 CXX="c++ -Wno-reserved-user-defined-literal"`); yfclab2 GCC 13.3.0 (`taskset -c 0-63,128-191 make -j8`) | both | PASS. Mac warnings 34 (= GH-76), none in `distqldpc.cc`. Linux 163 vs GH-85 159; the extra 4 are `%llu` format warnings in GH-76's `incProbe` prints (`Solver.cc` = b3d6b5d), verified by diffing the build logs |
| `scripts/smoke_test.sh` | both | PASS |
| `python3 -B scripts/test_partition_soft_literals.py` (fixture + 11 adjacent oracles) | both | PASS |
| `tests/test_partition_soft_literals.cc` oracle (compile line from `ci.yml`) | both | PASS, `GH58_PARTITION_ORACLE_PASS cases=80` |
| GH-76 `tests/test_incremental_probes.cc` (unchanged engine) | Mac 20000; yfclab2 100000 | PASS. Counts identical to GH-76's record: 91872 probes/154 rebuilds; 458595/725; 0 failures |
| **new** `tests/test_incremental_symbreak.cc` (see below) | Mac 20000; yfclab2 100000 | PASS, 0 failures. yfclab2: 533084 probes; 1673 rebuilds; symmetry none/unit/chain = 24122/60945/14933 instances |
| Mutation check of the new oracle: unverified transitive orbit (unit clause v_0) injected on instances without symmetry | Mac 300 | detected: 141 failures, exit 1 |
| `-joint -v` vs fresh 72d1fe1 build: LP_34_20_2, BB_72_12_6, TN_36_8_4, BB_90_8_10, GB_144_12_8 x {default, no-card} | Mac + yfclab2 | 10/10 IDENTICAL on each host |
| `-no-symbreak -v` vs GH-76 `b3d6b5d` (Mac fresh build; yfclab2 `gh76-frozen/cand`, ea91c0e0…): LP_34, BB_72, TN_36 x {default, no-card} | Mac + yfclab2 | 6/6 IDENTICAL on each host |
| Default `-v` traces (orbit report, probe log, `solver builds X 1, Z 1`); GH-85 traces alongside | Mac + yfclab2 | d equal to name in all 6 |
| `-symbreak-report` on all 50 codes vs GH-85 binary | Mac | 50/50 byte-identical. Halves: 70 orbit-chain, 30 none, 0 unit (bundled codes have no transitive half) |
| GH-60 `tier0_science.py` (sha256 41ee9dfc…, = GH-85 copy), 50 codes x 4 modes, 60 s, `--jobs 4`, pinned to NUMA node 0, vs frozen 72d1fe1 `frozen/gh73n/base` (b943c2c9…) | yfclab2 | **ALL_OK**: both done 53 (equal values, equal to name), only candidate done 10, only baseline done 0, problems 0 |
| Post-hoc (`check_sweep.py`): every candidate timeout emits d_lb; abnormal exits | yfclab2 | 137/137 candidate timeouts emit a d_lb. 0 abnormal exits. On the 137 common timeouts the candidate's final LB is higher in all 137 (informational, all sound) |
| TN_648_10_71 (name known wrong, true d <= 52) | yfclab2 | Times out in every mode on both binaries. No d_ub emitted; final d_lb baseline 4–8, candidate 9 (both sound w.r.t. d <= 52). Reported, not fixed |
| QDistSAT cross-repo (LP_136_32_4, BB_108_8_10; no-card, card-mto), workflow_dispatch on `ci/xrepo-gh89` | GitHub run 37925876334 | success, **scientific results match YES** |
| Hosted CI on PR #91 | GitHub | build-and-smoke pass |

The 10 candidate-only completions were BB_144_12_12 card-sinz, LP_340_56_8 x4, LP_442_68_10 no-card, TN_108_2_12 x3 and TN_200_10_10 card-sinz. All equal their names.

New oracle `tests/test_incremental_symbreak.cc`:
- It includes the production `src/core/distqldpc.cc` (its `main` renamed) and drives `find_half_symmetry` -> `CssHalf.sb_orbit` -> `run_css_half` (`css_half_build` + `incProbe` + `INC_REBUILD` + witness check).
- Instances: random half instances with n = 4..16, row spaces closed under planted GH-75/GH-85 family maps (full cyclic shift gives the unit clause; block or strided shifts give an orbit chain), plus unstructured controls. All four cardinality modes.
- Probe schedule follows GH-76: doubling caps, forced raise after a solution, tie-break/random/capped optimisation, and re-asking after completion.
- Every answer is checked against exhaustive enumeration of the half **without** the clauses. The test also checks that the optimum restricted to the orbit predicate equals the optimum, and that the planted generators lie in the verified group.
- Each instance also runs with the clauses off (GH-76 control).
- Compile (the token lacks `workflow` scope, so this is not added to `ci.yml`):

  ```
  g++ -Isrc/solver -O3 -DNDEBUG -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS tests/test_incremental_symbreak.cc build/{SimpSolver,Solver,Options,System}.o -lz -o build/test_incremental_symbreak
  ```

## Binaries (sha256)
Mac, read-only, outside build trees: `scratch-2026-10-08-ce0ddb/frozen89/`.
| Role | Path | sha256 |
|---|---|---|
| **candidate** (09d8bc2) | `frozen89/cand/distqldpc` | fb6846d0613b187a881e08071729e36629bc10775a4aad34e3d5df34d3d1ff37 |
| fresh 72d1fe1 | `frozen89/base/distqldpc` | 9beae620688ab36ef8b5f8dedb0bae5529ce997b2225ce683b00b1831a2882a8 |
| GH-76 b3d6b5d | `frozen89/gh76/distqldpc` | 226afcbcb9bcf49e225d39fc7b5b79a43fe615622ea004305a8f3ee4d8f0cf8a |
| GH-85 (34b7d2f = cc7e5ea src) | `frozen89/gh85/distqldpc` | 9fbd2433a73e829f04a9e2f797f2440be7fae7e08734036ac42fe16f03c72fc6 |

yfclab2: `~/mac-agent-20261009/frozen/gh89/cand/distqldpc`, sha256 f3ce5b7eeb59d3491ede079de84e6d1980f315fbdfa79b73bfc9ca82a28cd6dd. Worktree: `~/mac-agent-20261009/gh89`. Results: `~/mac-agent-20261009/gh89-results`.

Raw evidence: `raw/mac/` (regressions, traces, per-half reports) and `raw/yfclab2/` (regressions, traces, sweep logs + `science.json`, `check_sweep.txt`). Manifest: `raw/SHA256SUMS.txt`.

## Risks / limitations
- Soundness of the composition rests on the two reviewed arguments plus the fact that the formula of a persistent instance never changes. The enumeration oracle covers n <= 16 only. Half weights are witness-checked; LBs have no certificate (as in all split variants).
- No bundled code has a transitive half, so the unit-clause path (soft literal fixed at preprocessing, `incOffset() > 0`) is exercised only by the oracle: 60945 unit-clause instances on yfclab2, 0 failures.
- The interaction is not guaranteed multiplicative. Orbit clauses change the persistent instance's learnt-state evolution. This is unknown until the coordinator's Tier1; the gate is vs 72d1fe1, and GH-85/GH-76 comparisons are attribution only.
- No `-no-inc` switch. Attributing against GH-85 needs GH-85's binary.
- `incPrepare()` duplicates the `solve_()` prologue (GH-76 risk, inherited).
- The new test's `#include` of `distqldpc.cc` couples it to static symbol names in that file.
