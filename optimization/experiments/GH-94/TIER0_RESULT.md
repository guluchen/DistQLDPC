# GH-94 Tier0 result — PASS (correctness only; no timing performed by this agent)

Triple stack = GH-89 (GH-85 per-half symmetry breaking x GH-76 persistent half solver) + GH-87 dual-half
elimination (issue #94; hub #15).
- Preregistration: `PROPOSAL.md`, commit `a9bb342`, pushed before any code change.
- Branch `experiment/gh-94-triple-stack`, from GH-89 candidate source `09d8bc2`.
- **Candidate source: `d01a7e5`** (single source commit). Later commits are tests and records only
  (`tests/test_incremental_dualskip.cc` is a test; it is not linked into `bin/distqldpc`).
- Cross-repo branch `ci/xrepo-gh94` = `2a84ec3` (tree of `d01a7e5`, single parent `72d1fe1`).
- State: **TIER0_PASS**, waiting for the coordinator's Tier1/Tier2. The server yfclab2 was not used.

## Merge

- `git diff cc7e5ea e226951 -- src | git apply -3` on `09d8bc2` (GH-92's dual-half delta: GH-87 dual-half
  elimination, A1, and the GH-92 dedup `candidate_family(n, with_identity)`).
- One conflict hunk, the `hs[]` initialiser in `min_distance_css_interleaved`: GH-89's initialiser (with GH-76's
  `S`, `n`, `builds`) is kept, followed by GH-92's dual-map detection block, then GH-85's per-half detection
  (GH-89 comment). Everything else applied cleanly: `find_dual_maps`, A1 in phase 2b, `g_dualskip`,
  `-no-dualskip`, `-dualskip-report`, help text, report mode.
- `MODIFICATIONS.md` (one GH-87/GH-94 row) and `NOTICE` (GH-87 paragraph) updated. All files LF, unchanged.
- Resulting driver: dual-map detection first; a verified map eliminates the Z half (`hs[1].exists = false`).
  Per-half symmetry detection then runs on the halves still present, so under elimination only the X half
  gets orbit clauses. The X half is solved by GH-76's persistent solver (`css_half_build` / `run_css_half` /
  `incProbe`, all unchanged) with the orbit clauses in the instance from construction. Without a dual map the
  code path is GH-89's exactly.
- Flags: `-joint`, `-no-symbreak`, `-symbreak-report`, `-no-dualskip`, `-dualskip-report`.

## How A1 was handled: kept, through the existing probe API (no rebuild, no change to GH-76)

A1 caps single-half phase 2b at U-1 when the X half holds the incumbent. Under the incremental contract a cap
may **fall** after a solution (level 0, all state kept). Only a raise above the previous probe's ceiling is
forbidden, and such a request returns `INC_REBUILD`.

After the X half's Phase-1 FOUND at weight U, the instance has `inc_sup = inc_ceil = U - offs`. `incProbe`
searches for cost < min(capU + 1, inc_sup):
- GH-89's cap U gives target inc_sup.
- A1's cap U-1 also gives target inc_sup.

So the two probes run the identical search from the identical state, and target <= inc_ceil, so no rebuild is
ever requested. They differ only in the label returned:
- no improvement: GH-89 returns OPT U; A1 returns NONE, and the driver sets lb = U, with the Phase-1 witness giving d = U;
- improvement: both return OPT v < U.

The half gets no later probe. If a future change ever made the A1 cap exceed the ceiling, `run_css_half`'s
existing GH-76 rebuild path would handle it. This is documented in the code comment at the A1 line and in
`PROPOSAL.md`.

The traces confirm this. On every dual-map code (BB_90, GB_144, BB_108, BB_72, TN_36) x 3 modes:
- the log is Phase-1 doubling, then `cap U-1 ... optimize`;
- that probe ends OPT 10 on BB_90 and BB_108, OPT 6 on BB_72, and NONE on GB_144 and TN_36 (proving the incumbent);
- the log shows `solver builds X 1, Z 0`, 0 rebuilds, and no Z-half line.

Soundness (as preregistered):
- Dual elimination is exact: a verified pi gives dX = dZ.
- Orbit clauses preserve the X half's existence-at-weight answers. They come only from plain X-half automorphisms, never from the XZ-dual map.
- GH-76 probes are exact for the fixed formula F_X u S.
- The A1 probe is a cap fall.

## Checks (Mac, Apple clang, one solver process unless stated; `mac.sh`, `raw/mac/run1.log`)

| Check | Result |
|---|---|
| `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"` (`build94.log`) | rc 0; 32 warnings, **none in `distqldpc.cc`** (= GH-92 full build) |
| `scripts/smoke_test.sh` | PASS |
| `python3 -B scripts/test_partition_soft_literals.py` | PASS (11 adjacent oracles, 1024 assignments each) |
| `tests/test_partition_soft_literals.cc` oracle | `GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1` |
| GH-76 `tests/test_incremental_probes.cc` (unchanged), 20000 | PASS, 0 failures; probes 91872 / rebuilds 154 = GH-76's and GH-89's records |
| GH-89 `tests/test_incremental_symbreak.cc` (unchanged), 20000 | PASS, 0 failures; counts byte-identical to GH-89's Mac record (probes 106247, rebuilds 308, sym none/unit/chain 4807/12134/3059) |
| **new** `tests/test_incremental_dualskip.cc`, 20000 (`raw/mac/test_incremental_dualskip.20000.v2.txt`) | **PASS, 0 failures**: 48444 driver runs; 8600 instances with a verified dual map (3158 also with X-half orbit clauses); 2049 instances with dX != dZ; 128 dual-path descents (first incumbent not optimal) |
| Mutation checks of the new oracle (2000 each, `raw/mac/test_incremental_dualskip.mutations.txt`) | both detected (exit 1): m1 eliminates Z whenever rank Hz = rank Hx (22 failures); m2 A1 off by one (cap U-2; 21 failures) |
| GH-85 `verify_half_autos.py`, 50 codes x 2 halves | ALL_PASS |
| GH-87 `check_dual_maps.py`, 50 codes | ALL_PASS |
| `-symbreak-report` and `-dualskip-report` vs GH-92 binary, 50 codes each | 100/100 identical (cpu-time fields masked) |

### New oracle `tests/test_incremental_dualskip.cc` (dual-map path, end to end)

- Includes production `src/core/distqldpc.cc` (main renamed). It runs the production
  `min_distance_css_interleaved` in a forked child, as `solve_in_child_fork` does, and parses the production
  bounds pipe (`LB`/`UB`/`RESULT`).
- Random CSS-split instances with n = 4..18:
  - planted dual: pi from the production `candidate_family(n, true)`, or a random pi. Hx is built by row
    operations on pi(Hz), sometimes with a redundant row; Gz = pi(Gx) plus row operations with Hx/Gz rows. Hz
    and Gx are optionally closed under a planted shift group, so the X half also gets orbit clauses;
  - near misses: one bit of Hx or Gz flipped;
  - independent halves.
- Each instance runs three configurations: triple, `symbreak` off, and `dualskip` off (= GH-89).
- Checks:
  - RESULT d OPTIMAL equals the brute-force min(dX, dZ), enumerated without symmetry clauses;
  - every emitted LB <= d <= every emitted UB;
  - whenever production detection verifies a map, enumeration gives dX = dZ;
  - every planted family map is detected.
- Compile line, same as `mac.sh` (Apple shim):
  `c++ -Wno-reserved-user-defined-literal -Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG tests/test_incremental_dualskip.cc build/{SimpSolver,Solver,Options,System}.o -lz -o build/test_incremental_dualskip`
- Honest note: the first 20000 run (`raw/mac/test_incremental_dualskip.20000.txt`, from `mac.sh`) reported 9
  failures. All 9 were `cfg=-1` test-construction checks in 5 instances; **no driver answer failed**.
  - Cause: a row operation could zero a Gz row. When the logical rows lay in rs Hz, all Gz rows vanished, and the
    zero-row filter replaced Gz by a random unit row. That is not a row operation, so the X half was infeasible
    and the Z half feasible.
  - Fix: a row operation that would zero a Gz row is now skipped.
  - The rerun (v2, same seed scheme) passed with 0 failures, and both mutations are still detected.

### Trace identities (`traces.sh`, `-v -cpu-lim=120` on both sides; `raw/mac/traces/`)

Cases: BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, LP_34_20_2, BB_72_12_6, TN_36_8_4 x {no-card, card-mto, default}.

| Comparison | Result |
|---|---|
| `-no-dualskip -v` vs frozen89 | **21/21 byte-identical** |
| `-joint -v` vs 72d1fe1 (frozen73n) | **21/21 byte-identical** (all runs completed inside the limit) |
| default vs frozen89 on LP codes (LP_238_44_6, LP_34_20_2; no dual map) | **6/6 identical except the single `c dualskip: no dual map ...` line** |
| default on dual-map codes (15 runs) | differs from GH-89 by design (X half only). `c symbreak X` lines identical to GH-92's; no Z-half line; `solver builds X 1, Z 0` |
| final `o` | equal to the named distance in all 21 x {gh89, gh92, base, cand}: 10/8/10/6/2/6/4 |

## Science sweep (`science.sh`, `raw/tier0-science-01/`, `raw/tier0-science-01.log`)

- Run on the Mac under the timing lock. The script waited until the lock was absent and took it with
  "GH-94 Tier0 science sweep Sat Oct 10 09:38:48 CST 2026". The sweep ran 09:38:48-10:49:21 +0800, and the lock
  was released (verified absent).
- Harness: unmodified GH-60 `tier0_science.py` (sha256 41ee9dfc...), 50 codes x {default, no-card, card-mto,
  card-sinz}, 60 s, `--jobs 4`.
- Binaries: baseline 72d1fe1 frozen73n (3f2fbc42...), candidate frozen94 (4a15a105...). Wall times are not timing evidence.

Results:
- **200/200 OK, ALL_OK, 0 problems, zero unsound results.**
- 58 completed by both, with identical named distances.
- 18 completed only by the candidate, all equal to their names:
  - BB_144_14_14 x4, d = 14;
  - GB_144_12_12 default/mto/no-card, d = 12;
  - LP_340_56_8 x4, d = 8;
  - LP_442_68_10 x4, d = 10;
  - LP_544_80_12 no-card, d = 12;
  - TN_200_10_10 no-card/sinz, d = 10.
- 0 completed only by the baseline.
- Every emitted d_lb <= d <= every emitted d_ub.
- Post-hoc (`posthoc_science.py`, POSTHOC_PASS; `check_sweep.py`, VERDICT PASS):
  - **124/124 candidate timeouts emitted a d_lb**;
  - on the 124 runs that timed out in both versions, the candidate's final d_lb was higher in 124 and lower in 0 (diagnostic);
  - 0 abnormal exits.
- TN_648_10_71 (its name is known to be wrong): times out in every mode on both binaries, with no d_ub emitted. Final d_lb is 4-8 for the baseline and 9 for the candidate, both sound. Reported, not blamed.

## Hosted (`raw/hosted/cross-repo-38013988822.txt`)

- `ci/xrepo-gh94` = `2a84ec3` (tree of `d01a7e5`, parent 72d1fe1).
- CI https://github.com/guluchen/DistQLDPC/actions/runs/38013984999: success.
- QDistSAT cross-repo https://github.com/guluchen/DistQLDPC/actions/runs/38013988822: success, **scientific match YES** (LP_136_32_4 d=4, BB_108_8_10 d=10, no-card and card-mto). Shared-runner times are informational only.

## Frozen binary for the coordinator (`frozen-binaries.sha256`)

| Role | Path (under the workspace root) | sha256 |
|---|---|---|
| **candidate GH-94** (`d01a7e5`), read-only | `frozen94/cand/distqldpc` | `4a15a105198094768c45433c516ef9f7b81e22fbbf028abbc5daa4d94050d69a` |
| primary comparison GH-89 | `frozen89/cand/distqldpc` | `fb6846d0613b187a881e08071729e36629bc10775a4aad34e3d5df34d3d1ff37` |
| secondary GH-92 | `frozen92/cand/distqldpc` | `49e37dee170eb6685344aefd25b37bdb1dccc129d640d6802ded25562b51d28f` |
| secondary 72d1fe1 | `frozen73n/base/distqldpc` | `3f2fbc4215e17c4a5b5e62d1f10f99619bdf6efaea7881acb46157effe78c9dc` |

## Deviations from the plan

- The new dual-path oracle needed one test-construction fix after its first 20000 run (see above). The production source was not changed.
- The `-joint` identity was checked on all 7 cases x 3 modes, more than the preregistered minimum.
- The science sweep ran on the Mac (`--jobs 4`) under the timing lock. The serial correctness script (`mac.sh`, one process) ran at the same time, outside the lock, as instructed for correctness runs.
- No Linux build: the server was not used.
- `tests/test_incremental_dualskip.cc` is not added to `ci.yml` (the token lacks `workflow` scope, as for GH-89).

Decision: **Tier0 PASS**. State TIER0_PASS / WAITING_FOR_HOST (Tier1/Tier2 by the coordinator).
