# GH-124 S0 report: clean-room CC engine (`-engine=cc`, engine commit 114b901)

- Date: 2026-10-16.
- Round: GH-124 (issue #124). Design: P1 "CC-Ladder Hybrid", stage S0 (`CC_INTEGRATION_PLAN.md` §5-8).
- Branch: `experiment/gh-124-cc-engine`.
  - `a3c64a7`: the engine.
  - `114b901`: fix round 1.
  - Both sit on main `141dac8`, whose solver equals main `398054e`.
  - The commit that adds this report adds documentation and raw data only. It changes no code.
- Binaries used for S0d/S0e:
  - Mac build of 114b901: `frozen-gh124-114b901/distqldpc`, sha256 `d0110ca5…32e8`.
  - yfclab2 build: `~/mac-agent-20261009/frozen/server-gh124-114b901/distqldpc`, sha256 `5b722ce9…6d60`.
  - Reference: frozen main 398054e, sha256 `2c9e33b4…`.
- Clean room:
  - No file was opened under `ext/qs-scripts`, `ext/verify/reimpl-A`, `ext/verify/reimpl-B` or `ext/qubitserf*`.
  - The prototype comparison uses only the prototype's logs in `ext/logs`.
  - Figures for reimpl-A/B come from `ADJUDICATION.md`.
- No PR, no merge, no GitHub post.

## Summary

**Results**

- **The in-repo engine reproduces all five adjudicated tier5 distances** on yfclab2, one core, 6 h cap. Each witness was verified twice: in the run, and by an independent GF(2) script (`wcheck.py`).
  - BB_360 d=24 (1993 s), LP_1054 d=20 (83 s), LP_1428 d=24 (4235 s), LP_1768 d=22 (345 s). MRV branching gives the same values.
  - LP_1054 is also exact without orbits (1552 s).
  - TN_252 is split across two runs:
    - The default lockstep schedule times out at lb 21. It proves Z levels 1..21 empty, so dZ >= 22.
    - The test-only `-cc-schedule=sequential` finds the weight-21 X logical in 17116 s, so dX = 21.
    - Together: d = 21, as adjudicated.
- **The four tier5 codes main already solves are solved in 2.6-672 s**, against main's 5321-18346 s.
- **The 17 open tier5 codes get higher lower bounds.** After 1 h each:
  - every bound is >= the prototype's 30/60-min bound;
  - 6 codes are higher by 1;
  - every cell is far above main's 6 h bounds (9 or 17).
- **Tier 0-4 (Mac, default seed) are all correct.** Candidate/main time ratios:
  - tier 1-4: 0.0001 to 0.07;
  - tier 0: 0.06 to 1.03 (cells at the 0.018 s process floor are neutral).
- **Node counts match the prototype exactly.** Across 35 trace-to-log comparisons (1236 (half, level) cells; 3 tier3-4 codes on the Mac and 22 tier5 codes on the server), every verdict is identical. Every node count is identical except one hit-level cell, where the prototype ran 4 threads.
- **Speed.** About 65-100 ns/node on the Mac, which is 0.41-0.55x the prototype's ns/node on the same levels (so faster). The server/Mac ratio is 2.55-2.71.
- **Selector calibration (toric and planar surface codes, L = 6-32).** CC is never slower than MaxSAT, and is faster from toric L = 12 and planar L = 8 on. Where everything times out, CC reaches lb 20-24 against MaxSAT's 9. This contradicts the S0 `-engine=auto` rule and the plan's assumption that toric/surface codes belong on MaxSAT.

**Gate.** The S0 exit gate (plan §6) is **met**; see §8. One condition attached: the PI should confirm the fix-round-1 redefinition of mutants 3 and 4.

**Main open issues** (full list in §9):

- TN_252 is not solved under the default schedule.
- The `-engine=auto` rule must be replaced before S1.
- `-seed` for the MaxSAT side, `-engine-report` and the CI targets are missing.
- The certification track (`cc_check`) has not started.
- NOTICE is still a draft.

## 1. What was built

### 1.1 Files (diff 141dac8..114b901)

| File | Lines | Content |
|---|---:|---|
| `src/cc/cc_half.{h,cc}` | 129 + 315 | `HalfSearch`: the exact level-w search on one CSS half |
| `src/cc/cc_driver.{h,cc}` | 84 + 434 | Start-up checks, dual map, level loop, stop rule, traps, witness verification, pipe output |
| `src/core/distqldpc.cc` | +247 / -6 | Engine switch and `min_distance_css_cc` wrapper; `-engine=auto` selector; flags, help and conflict checks; `-v` solver line. `find_dual_maps` also keeps the permutations; its report output is unchanged. |
| `Makefile` | +31 | `CC_OBJS` (C++17), header dependencies for the cc objects, `make test-cc`, `make test-cc-flags` |
| `tests/test_cc_engine.cc` | 356 | Brute-force ladder and driver tests through the real fork and pipe, plus the mutant expectations |
| `tests/test_cc_flags.sh` | 108 | 93 command-line checks |
| `README.md`, `MODIFICATIONS.md`, `NOTICE` | +28 / +21 / +12 | Flag table, CC paragraph, src/cc section. NOTICE is a DRAFT pending PI approval. |
| `optimization/experiments/GH-124/` | | Plan, adjudication, `S0/` (smoke TSVs, S0 raw logs, identity records, test logs) |

`src/solver`, `scripts`, `data` and `.github` are untouched.

### 1.2 Flags and defaults

| Flag | Default | Meaning |
|---|---|---|
| `-engine=maxsat\|cc\|auto` | `maxsat` | `maxsat` is main's search, byte-identical. `cc` is the new engine. `auto` (S0 rule) picks `cc` iff every qubit has degree >= 3 and every row weight is <= 16 in each existing half's parity matrix; otherwise it picks `maxsat`. |
| `-cc-rules=excl,pack,orbf[,mrv]` | `excl,pack,orbf` | The rules are: sibling exclusion; disjoint odd-row packing bound; GH-85 orbit seeds; fewest-candidate branching. `none` means plain CC. |
| `-cc-dual=on\|off` | `on` | With a verified GH-107 XZ-dual map, only the X half is searched and its bounds are mirrored. `-dualmode=off` also turns this off. |
| `-ub-basis[=on\|off]` | off | Emit the minimum weight of the verified Gx/Gz rows (U0) as the initial upper bound. CC only. |
| `-cc-seed=N` | 0 (identity) | splitmix64 relabelling of qubits and rows, for seed-median timing |
| `-cc-trace=FILE` | none | One line per finished (half, level): verdict, nodes, seconds, witness |
| `-cc-stats` | off | Per-level node and prune counts; printed even without `-v` |
| `-cc-schedule=lockstep\|sequential` | `lockstep` | Test only. `sequential` raises one half to its distance before the other half. |
| `-cc-mutant=1..4` | 0 | Test only (see §2.2) |

**Flag conflicts** (fix round 1) end with exit code 1:

- `-cc-*` and `-ub-basis` require `-engine=cc` or `-engine=auto`.
- `-engine=cc` and `-engine=auto` refuse `-joint`, `-roundingsat[=BIN]`, `-dump-wcnf`, `-dump-opb`, `-dump-only` and `-native-parity-opb`.
- `-engine=cc` also refuses the cardinality flags and `-dualshare-stats`.
- `-engine=auto` warns on stderr about any flags its choice ignores.

**Mapping of existing flags:** `-no-symbreak` gives index seeds; `-dualmode=off` searches both halves.

### 1.3 How it works

**Half search** (`HalfSearch`, `src/cc/cc_half.cc`). It runs on F_h = {v : H v = 0, G v != 0}, using DistQLDPC's CssHalf convention: X half H = Hz, G = Gx; Z half H = Hx, G = Gz.

- **Search.** A depth-first search per seed grows Tanner-connected clusters. It tracks the syndrome bitset with an odd-row count, an incremental detector parity, per-qubit block counters (cluster plus forbidden set), 64-bit packing stamps and per-depth candidate buffers.
- **At |S| = w.** Accept iff the syndrome is 0 and the G-parity is nonzero.
- **Below w.** A syndrome-free cluster is a dead end. If that cluster is nontrivial, the level returns INCONSISTENT, which the driver turns into a trap. This is the plan's precondition lb_h >= w.
- **Pruning.**
  - An odd row with no candidate is a dead end.
  - Packing greedily takes odd rows with pairwise disjoint candidate sets and prunes when |S| + p > w.
- **Branching.** On the lowest-index odd row (or, with MRV, the row with the fewest candidates), candidates in ascending order. Exhausted siblings are forbidden and restored in LIFO order.
- **Seeds.** GH-85 orbit representatives; after seed i its whole orbit is forbidden. Without nontrivial orbits the index rule applies.

**Driver** (`src/cc/cc_driver.cc`).

- **Start-up check per half.** Every same-type stabilizer row must have even overlap with all H and G rows, and rank[H;G] + rank S = n. A failure is a trap.
- **Dual map.** Under the verified dual map only X is searched, and pi(witness) is verified in Z.
- **Level loop (lockstep).** Pick the half with the lowest lb that is still below U. Ties go to the half that had fewer nodes at its previous level, then to X.
  - EMPTY sets lb_h = w + 1.
  - FOUND is double-verified: H e = 0, plus an independent echelon test that e is not in the rowspace of the stabilizers.
  - Stop rule: d = w when the other half has lb >= w.
- **Traps.** Each of these ends the run with RESULT -1, never a value: lb_h > ub_h, LB > U, a failed witness, an inconsistent level, a failed detector check.
- **Output.** TRY, LB and UB go through the existing `pipe_bound` / `pipe_write_result`. The parent process and the `-cpu-lim` SIGKILL path are unchanged.

### 1.4 Deviations from the plan (§5.1, §6 S0)

- **Flag name.** `-cc=` is called `-cc-rules=`. The `lazy` and `psort` rules are not built, so the S0a rule subsets are those of {excl, pack, orbf, mrv}.
- **Not built in S0:**
  - `-engine-report`;
  - `-seed=N` (MaxCDCL random seed on the MaxSAT path);
  - a separate `cc_trace.cc` with an event hash;
  - `tools/cc_check`.
  The trace is v1: per (half, level), the verdict, nodes, seconds and witness.
- **`-engine=auto` rule** (minimum qubit degree >= 3, maximum row weight <= 16) differs from the §5.3 gate (mean degree >= 2.5, maximum check weight <= 32, ...). As a result, all 28 TN and GB codes go to MaxSAT. S0d (§5.5) shows the rule must change.
- **ADJUDICATION §7 step 3b (self-contained levels) was not adopted.** The precondition stays, and a closed nontrivial cluster below w is a trap.
- **Mutants 3 and 4 were redefined in fix round 1** (§2.2), and the test-only `-cc-schedule` flag was added.
- **MODIFICATIONS.md** documents the application-layer changes, as for earlier rounds. **NOTICE** is a draft. **CI** is unchanged.

## 2. Verification history

### 2.1 Round 0: engine commit a3c64a7

| Check | Result | Main findings |
|---|---|---|
| **S0a** oracle + mutation harness (independent, `tests/gh-124-cc-oracle` 985ea93). Brute force from Hx/Hz only; 266 codes (252 with n <= 24); 61 configurations (16 rule subsets x dual on/off, `-cc-seed` 1-4, `-ub-basis`, `-no-symbreak`, `-dualmode=off`). | **FAIL** (blocking, but not a correctness defect) | 16226 canonical runs, 0 failures. Mutants 1 and 2 killed. Mutants 3 and 4 survived 16226 runs each: as specified they are *equivalent* mutants, so no corpus can kill them (§2.2). |
| **S0b** agreement with the prototype logs (23 tier0-4 codes, 72 runs) + **S0c** identity (28 tier0+1 pairs) | PASS | 1210 (half, level) cells run by both: identical verdicts and node counts. FOUND witnesses identical. The 218 prototype-only cells are all explained: 146 + 14 dual-mirrored Z levels, 58 hit-level skips. S0c: 28/28 `-v` logs raw byte-identical to frozen main, both without new flags and with `-engine=maxsat`. |
| Adversarial **soundness review** of `src/cc` | PASS | No way to report a too-high lb or a wrong d with production flags. Its own brute-force oracle: 1663 codes / 25052 runs, 0 failures. Symmetry inputs of all 49 stems re-verified. 92/92 unusual tier0-4 configurations OK. Two minor findings (§9, items 7-8). |
| **Integration / semantics review** | PASS | Default path byte-identical (42 cases plus reports). Output and timeout semantics are main's. Bounds monotone (0 violations). `-ub-basis` is off by default. LP_1768 peaks at 9-17 MB. One **major** finding: conflicting flags were accepted silently. Plus 5 minor. |

### 2.2 Fix round 1: commit 114b901

- **Mutant 3** is now the orbit seed rule off by one: while r_i is searched, O_1..O_i are forbidden, not O_1..O_{i-1} (r_i itself excepted).
  - The original "orbit seeds without forbidding earlier orbits" only drops a restriction, so every level verdict stays exact.
- **Mutant 4** (stop rule without the other half's lb) now forces the sequential schedule.
  - Under lockstep, the pick order already guarantees olb >= w at every hit, so skipping the check changes nothing.
  - The sequential schedule is exposed as `-cc-schedule=lockstep|sequential` (test only, default lockstep).
- **Flag conflicts** are rejected, and values are checked strictly: `-cc-seed` decimal only, `-cc-mutant` 0..4, non-empty `-cc-trace`, `-ub-basis=` on/off only, unknown `-cc-*` flags rejected.
- **New test:** `tests/test_cc_flags.sh` (93 checks).
- **Unchanged:** production search code. The only `src/cc` hunks are the mutant-3 branch, the mutant-4 schedule switch and the schedule option.

### 2.3 Round 1: commit 114b901

| Check | Result | Main findings |
|---|---|---|
| **S0a** re-verification: original harness on 114b901 (`S0/oracle_s0a_fix1.log`) | PASS | 16226 canonical runs, 0 failures. All four mutants killed: mutant 3 with 200 wrong values and 1080 no-answer runs; mutant 4 with 1184 wrong values. |
| **S0a** re-verification: a second, independently written harness (`tests/gh-124-cc-oracle-r1` 6329459) | PASS | 316 codes (304 with n <= 24, up to n = 127; 71 with d_X != d_Z). 632 `-v` replays of generators, orbits and dual maps. 15484 canonical runs (49 configurations), 0 failures. 17753 trace witnesses verified. Mutants 1/2/3/4 killed with 165 / 36 / 304 / 3008 wrong values. Mutant 2 can only fail with "no answer" on the rule grid; its wrong values need `-ub-basis` (minor note). |
| `make test-cc 2000 1000` | PASS | 96000 ladders and 9000 driver runs, 0 bad. Wrong outputs per mutant: 805/16000, 4152/16000, 2056/8240, 113/1000. |
| `make test-cc-flags`, `scripts/smoke_test.sh` | PASS | 93/93; smoke passes |
| CC smoke tier0-4 (`S0/smoke_*_fix1*.tsv`) | PASS | 22/22 tier0-3 plus TN_250 correct. The sequential schedule is also 22/22. |
| S0b / S0c, soundness review | carried from round 0 | Production search unchanged (above). The 114b901 traces from S0d/S0e re-confirm node identity with the prototype on 25 codes: 3 tier3-4 codes from S0b plus 22 tier5 codes (§3.3). |
| Identity re-check (`S0/identity_vs_main398_fix1.txt`) | PASS | `-v` default, `-v -engine=maxsat` and quiet runs: tier0+1 x 2 card modes, plus 3 tier2 cases, all identical. The first pass showed 4 `-v` differences: parent/child pipe interleaving that main shows too. On repeat, all byte-identical. |
| **Integration / semantics review** at 114b901 | PASS | Default path byte-identical in all main modes (card modes, `-joint`, dualmode, reports, dumps, `-q`). Timeouts on BB_360 / TN_252 / LP_1768 give main's tail format with valid bounds. 242-run monotonicity matrix: 0 problems. Six minor findings remain (§9). |

**Main path unchanged.**

- With no new flag, and with `-engine=maxsat`, the binary is byte-identical to main 398054e on every tested output.
- In the default path the only new code that runs is:
  - the argv scan for engine flags;
  - storing the dual-map permutations;
  - the dispatch branch.
- **Scientific semantics changed: no.**

## 3. S0e: the five tier5 claims, reproduced in-repo

Setup: yfclab2, `taskset -c <core> prlimit --as=4294967296`, one process per core, `-cpu-lim=21600`, default seed. `def` means the default rules `excl,pack,orbf`.

### 3.1 Results and comparison

Column notes:

- "Levels EMPTY" means levels 1..w proven empty in X / Z; "m" means mirrored through the verified dual map.
- Prototype times are from its logs: Mac, single thread unless noted.
- reimpl-A/B times are from ADJUDICATION §2; B ran each half as its own server process.
- main is the recorded 398054e result on the server, 6 h (`baselines/SERVER.md`).

| Stem (adjudicated d) | Config | Result | Levels EMPTY X / Z | Witness | Wall s (server) | Prototype (Mac) | reimpl-A | reimpl-B (server, per half) | main 398054e (server, no-card / card-mto) |
|---|---|---|---|---|---:|---|---|---|---|
| BB_360_12_17to24 (24) | def | d=24 | 23 / m | X + dual Z image | 1993.2 | 3037 s (both halves) | 6422 s | X 1694, Z 1764 | TIMEOUT [17,24] / [17,24] |
| | mrv | d=24 | 23 / m | X + Z image | 1606.2 | MRV 3424 s | | | |
| TN_252_2_17to28 (21: dX=21, dZ>=22) | def | TIMEOUT, lb 21, ub - | 20 / **21** | - | 21600.2 | 1 thread: TIMEOUT 7200 s at X<=19, Z<=20. 4 threads: d=21 in 9787 s | lvl 20 in 19084 s, then the 6 h cap during X21; split runs complete it | X21 FOUND 9512 s; Z lvl 21 20101 s | TIMEOUT [17,28] / [17,-] |
| | mrv | TIMEOUT, lb 21, ub - | 20 / 20 | - | 21600.2 | MRV, 4 threads, killed at 1244 s | | | |
| | `-cc-schedule=sequential` (extra) | **d=21** | 20, then X21 FOUND / 20 | X | 17115.5 | | | | |
| LP_1054_140_17to32 (20) | def | d=20 | 19 / 19 | X | 82.7 | 76 s | 140 s | X 47, Z 61 | TIMEOUT [17,-] / [17,-] |
| | mrv | d=20 | 19 / 19 | X | 69.1 | | | | |
| | excl,pack (no orbits) | d=20 | 19 / 19 | X | 1552.2 | 1357 s | 2864 s | 730 s | |
| LP_1428_184_ge17 (24) | def | d=24 | 23 / 23 | X | 4234.9 | 3013 s | 5816 s | X 1427, Z 1846 | TIMEOUT [17,-] / [17,-] |
| | mrv | d=24 | 23 / 23 | X | 3044.6 | MRV 3505 s | | | |
| LP_1768_224_ge17 (22) | def | d=22 | 21 / 21 | X | 344.5 | 327 s | 637 s | X 158, Z 219 | TIMEOUT [9,-] / [9,-] |
| | mrv | d=22 | 21 / 21 | X | 247.2 | MRV 351 s | | | |

**Witnesses.** 71 witness checks over 62 server runs, all VALID: H e = 0, e not in the stabilizer rowspace, odd overlap with G, weight = level, and the dual image where one exists.

**Health of the runs.**

- No TRAP, no INCONSISTENT level, no MEMOUT.
- Every nonzero exit code is a `-cpu-lim` timeout.
- Largest CC max RSS on the server: 32 MB. Largest MaxSAT max RSS (calibration runs): 107 MB.

**Comparison by host.**

- The candidate's times are server times. The prototype's are Mac times.
- With the measured server/Mac ratio of about 2.6 (§5.2), the candidate's Mac-equivalent times are 0.25-0.55x the prototype's. Examples:
  - BB_360: about 770 s, against 3037 s for the prototype, which searched both halves.
  - LP_1428: about 1630 s, against 3013 s.
  - LP_1768: about 130 s, against 327 s.
- In wall time, the candidate is in the same range as the sum of B's per-half server processes, and needs 1.4-3.2x less than A's recorded runs.
- Against main: under the default rules, four codes go from TIMEOUT to an exact value. TN_252 reaches its exact value only with the test-only sequential schedule; its default run ends at lb 21, against main's 17. Main's 6 h lower bounds on these five codes were 17 (four codes) and 9 (LP_1768).

### 3.2 Why TN_252 times out under the default schedule

1. **Level 21 starts with Z.** After X20 and Z20 are EMPTY, both halves have lb 21. The lockstep tie-break picks the half with fewer nodes at the previous level. That is Z: 9.16e9 nodes, against 1.71e10 for X.
2. **Z has no weight-21 logical, so its whole level runs.** Z21: 3.29e10 nodes, 9289 s, EMPTY. This proves dZ >= 22.
3. **The X21 hit then does not fit in the cap.** The sequential run shows it needs 2.42e10 nodes and 6992 s. Levels X<=20 and Z<=21 already took 19.6 ks of search time, so the total need is about 26.6 ks against the 21.6 ks cap.

Sequential schedule:

- X runs to its hit first (X<=20 EMPTY, X21 FOUND). Z then runs up to level 20.
- The hit level is 41% of the run time.

Assessment:

- This is exactly the case for the plan's S2b hit-level interleaving.
- Plan §7 already expected TN_252 to time out under S1 ("TIMEOUT [20, 28 from U0]"). The measured lb is 21, one level better.
- `-cc-schedule=sequential` is a test-only flag and was not proposed as a default. On TN_200, sequential takes 5.1 s against lockstep's 0.08 s, because X has to be raised to dX >= 11 first.

### 3.3 Node-count identity with the prototype (black box)

`raw/report-analysis/cmp_proto.py` compares every 114b901 trace with the prototype's logs under the same rules (`raw/report-analysis/cmp_proto.txt`). The S0d Mac traces were compared with `proto_validate_orbf`; the S0e and tier5 server traces with `proto_t5`, `proto_t5_mt` and `proto_xcheck`.

- **35 comparisons, 1236 (half, level) cells:**
  - 1236/1236 verdicts identical;
  - 1235/1236 node counts identical.
- **The one difference is the TN_252 X21 FOUND cell.** The 4-thread prototype stops at its first hit after 1.34e10 nodes; the single-thread candidate stops after 2.42e10. A hit level's node count depends on search order. The verdict is the same.
- **TN_252's X20 EMPTY (17,078,923,788 nodes) and Z21 EMPTY (32,891,746,145 nodes)** now have a single-thread in-repo reproduction with node counts identical to the prototype. ADJUDICATION F10 had noted that these two levels came only from the prototype's 4-thread run.
- **Every cell that only the prototype has** is either a dual-mirrored Z level (BB codes) or a hit-level skip after the stop rule.
- **Every cell that only the candidate has** is a level the candidate reached beyond the prototype's budget.

### 3.4 Certification bundle (plan §8.5) for the five claims

| Item | Status |
|---|---|
| Verified witness, both checks | done: ADJUDICATION; in-run check plus `wcheck.py` here |
| In-repo DistQLDPC CC result with trace | **done (this S0e).** For TN_252 it comes from two runs: dX = 21 (sequential) and dZ >= 22 (default). |
| Agreement from a clean-room reimplementation | done (A and B) |
| Rule-diverse re-run | done: MRV in-repo for all five; no orbits in-repo for LP_1054; no orbits by A/B for BB_360, TN_252 and LP_1768. LP_1428 Z at w = 23 still rests on orbits (verified by DistQLDPC and three recomputations). |
| `cc_check` trace replay | **missing** (certification track, from S1) |

No stem was renamed. That decision stays with the PI (§10).

## 4. Other tier5 codes

### 4.1 The four codes main already solves (server, default rules, 21600 s cap)

| Stem | Candidate | Levels EMPTY X / Z | Wall s | Prototype (Mac) | main 398054e server (no-card / card-mto) |
|---|---|---|---:|---|---|
| LP_714_100_16 | d=16 | 15 / 15 | 3.9 | 21 s (excl,pack, no orbits); 3.6 s with orbits (ADJ §8) | 8752 / 5321 s |
| LP_1020_136_16 | d=16 | 15 / 15 | 2.6 | 1.4 s | 7159 / 8328 s |
| TN_180_2_17 | d=17 | 16 / 16, Z17 FOUND | 267.2 | 853 s (no orbits); 341-384 s with orbits (ADJ §8) | 9837 s / TIMEOUT [17,19] |
| TN_216_4_18 | d=18 | 17 / 17, Z18 FOUND | 672.5 | 595 s | 16802 / 18346 s |

### 4.2 The 17 open codes (server, default rules, 3600 s cap)

All 17 runs hit the cap with no upper bound.

| Stem | Candidate lb (Z / X) at 1 h | Prototype lb (Z / X), ADJ §3 (Mac, 30 min TN / 60 min BB) | main 398054e lb at 6 h |
|---|---|---|---:|
| TN_288_2_ge9 | 18 (19 / 18) | 18 (19 / 18) | 9 |
| TN_324_4_ge9 | 18 (19 / 18) | 18 (19 / 18) | 9 |
| TN_432_8_ge9 | 19 (20 / 19) | 19 (19 / 19) | 9 |
| TN_540_4_ge9 | 19 (20 / 19) | 19 (19 / 19) | 9 |
| TN_576_2_ge9 | 20 (20 / 20) | 20 (20 / 20) | 9 |
| TN_648_14_ge9 | **20** (20 / 20) | 19 (20 / 19) | 9 |
| TN_648_10_9to52 | **20** (20 / 20) | 19 (20 / 19) | 9 |
| TN_684_2_ge9 | 20 (21 / 20) | 20 (20 / 20) | 9 |
| TN_360_4_ge17 | **21** (21 / 21) | 20 (21 / 20) | 17 |
| TN_396_4_ge17 | **21** (21 / 21) | 20 (21 / 20) | 17 |
| TN_468_4_ge17 | **21** (22 / 21) | 20 (21 / 20) | 17 |
| TN_496_2_ge17 | 20 (20 / 21) | 20 (20 / 20) | 17 |
| TN_504_2_ge17 | 21 (22 / 21) | 21 (22 / 21) | 17 |
| TN_612_2_ge17 | 22 (23 / 22) | 22 (22 / 22) | 17 |
| BB_756_16_ge17 | 25 (X only; Z mirrored) | 25 (25 / 25) | 17 |
| BB_864_4_ge17 | **26** (X only) | 25 (25 / 25) | 17 |
| BB_1080_4_ge17 | 25 (X only) | 25 (26 / 25) | 17 |

- **Every code-level lower bound is >= the prototype's**, and six are higher by 1.
- **The searched halves are never below the prototype's.**
- **One exception in a mirrored half: BB_1080.** The prototype's Z search reached 26, while the candidate's mirrored Z is 25, because only X is searched. Since the dual map gives dX = dZ, the prototype's Z result alone would imply d >= 26. This is a prototype-only fact, and it is not used here.
- **Budgets.** The candidate had 60 min on the server, at about 2.6x the Mac's ns/node. The prototype had 30 min (TN) or 60 min (BB) on the Mac. The node budgets are therefore comparable, within about 1.5x; on the BB codes the candidate spends all of its budget on X.
- **Node counts agree** on all common cells (§3.3).
- **Status of these bounds.** ADJUDICATION's status for them is PLAUSIBLE. These runs add an in-repo, clean-room, single-thread trace for every one of them. Whether that upgrades them to CONFIRMED is left to the adjudicator or PI (§10). They are produced by the identical canonical search, so they are not an independent search tree.

## 5. S0d measurements

All metrics were recomputed from the traces (`raw/report-analysis/metrics.py` → `metrics.txt`). The Mac runs were serial under `caffeinate -i -s`, one solver at a time, with a 2 GB watchdog; peak RSS was under 5 MB.

### 5.1 ns per node, against the prototype (exit-gate item)

| Host | Code | Candidate ns/node (EMPTY levels >= 1e6 nodes) | Prototype ns/node, same levels (Mac log) | Candidate / prototype |
|---|---|---|---|---|
| Mac | BB_288_12_18, `-cc-dual=off` (both halves, 3 runs) | 62.6-68.3 | 149.3-160.4 | **0.41-0.44** |
| Mac | BB_288_12_18, default (X half) | 65.2-70.0 | 149.3-157.0 | 0.43-0.44 |
| Mac | TN_250_10_15 (3 runs) | 81.7-99.4 | 158.4-186.5 | **0.49-0.55** |
| Mac | LP_544_80_12 | 49-103 over the whole run (16-34 ms search; no level >= 1e6 nodes) | n/a | n/a |
| Server | tier3-4, seed 0, uncontended cores | BB_288 186-196; TN_250 224-249 | (Mac) | host factor |
| Server | tier5, 28 runs with a matching single-thread prototype log (24 default rules, 4 MRV; EMPTY levels >= 1e7 nodes) | 188-551. LP_1428's Z half runs at about 390. | 161-364 (default rules, Mac) | 0.92-1.93 default rules; 0.60-1.25 MRV (cross-host) |

- **On the same host the candidate is about 2x faster per node than the prototype.** The prototype's Mac runs had a load average of about 4 on 12 cores; even if that inflated the prototype by 2x, the ratio would stay under 1.1.
- **The gate "ns/node within 1.5x of the prototype" holds with a wide margin.**
- **Cross-host ratios** (server candidate against Mac prototype) are 0.92-1.93 under the default rules. That is the host factor (§5.2), not an engine difference. Under MRV they are 0.60-1.25, because the prototype's MRV code is slower per node.

### 5.2 Server/Mac speed ratio (seed 0, 3 runs each, median)

| Code | Mac search s | Server search s | Ratio, search | Ratio, wall |
|---|---|---|---:|---:|
| BB_288_12_18 | 0.774 / 0.793 / 0.796 | 2.159 / 2.127 / 2.151 | **2.71** | 2.67 |
| TN_250_10_15 | 29.05 / 29.37 / 29.51 | 74.91 / 74.90 / 106.17 | **2.55** | 2.54 |
| LP_544_80_12 | 0.016-0.034 | 0.047-0.072 | not measurable | wall is runner-bound |

- **The plan's §7 assumption of 2.5 holds.**
- **Wall-time resolution.** The Mac runner polls every 0.25 s and the server runner every 0.2 s. Walls under about 0.3 s are therefore quantised; use the search time or `S0/smoke_*_fix1.tsv` for small codes. For example, LP_544's Mac wall is 0.031 s in the smoke TSV.
- **Contended cores reach up to about 3.5x the Mac.** Cores 0-63 have SMT siblings (128-191) that another user's unpinned jobs were using. TN_250 rep3 on core 60 took 106 s against 75 s. TN_250 seeds 3-4 ran at 357-359 ns/node, and LP_1428 at 350-381.

### 5.3 Growth, hit-level share, Z/X cost, single-half saving

**Per-level growth b** (node ratio over the last 4 EMPTY levels):

| Code | b |
|---|---|
| BB_288 | 3.03-3.12 |
| TN_250 | X 3.20-3.33, Z 3.08-3.21 |
| LP_544 | 2.44-3.76 |
| BB_360 | 3.08-3.12 (MRV 2.97-2.98) |
| LP tier5 | 2.42-3.09 |
| TN_180 / TN_216 / TN_252 | 3.23-3.72 (MRV on TN_252: up to 3.83) |
| Open TN codes | 2.69-3.35 |
| BB_756 / BB_864 / BB_1080 | 2.74-2.84 |

**Hit-level share of search time:**

- Under 2% on every LP and BB tier5 run: LP_1054 0.05%, LP_1428 0.01%, LP_1768 0.75%, BB_360 0.34%.
- TN codes: TN_250 4.5% at seed 0 (0.2-15% across seeds), TN_216 13%, TN_180 31%, TN_252 sequential 41%.

**Z/X search-time ratio:**

| Code | Default | MRV |
|---|---|---|
| TN_250 | 0.43-0.45 at seed 0; 0.44-0.80 across seeds | |
| LP_544 | 0.77-1.36 | |
| LP_1054 | 3.1 | 1.9 |
| LP_1768 | 6.2 | 2.8 |
| LP_1428 | 8.4 | 2.5 |
| Open TN codes | 0.41-2.79 | |

The LP tier5 codes are strongly Z-heavy under the default rules. Part of this is node counts and part is ns/node: LP_1428 Z runs at 390 ns/node against 227 for X.

**Single-half saving (BB_288, Mac):** the dual map halves the work.

- Nodes: 11.18M with the dual map, 22.79M with `-cc-dual=off` (2.04x).
- Search time: 0.79 s against 1.50 s (1.9x).

### 5.4 Determinism and `-cc-seed` variance

**Determinism.** For all 15 code-and-seed pairs, the server and Mac traces are identical: levels, verdicts, node counts and witnesses. Repeat runs give identical node counts.

**Seed variance:**

| Code | Nodes over seeds 0-4 (max/min) | Mac serial search s, seeds 0..4 | Server wall s, seeds 0..4 | Result |
|---|---|---|---|---|
| BB_288 | 11.18-14.53M (1.30x) | 0.77 / 0.98 / 0.81 / 0.94 / 0.92 | 2.4 / 3.0 / 2.4 / 2.8 / 3.8 | all d=18 |
| TN_250 | 308-545M (1.77x) | 29.0 / 41.8 / 56.0 / 52.5 / 48.2 (median 48.2 = 1.66x seed 0) | 75.1 / 108.5 / 140.9 / 180.6 / 169.5 | all d=15 |
| LP_544 | 0.30-0.33M (1.11x) | 0.016-0.020 | about 0.2 (runner floor) | all d=12 |

- Seed 0 happens to be the fastest seed on TN_250.
- From the S0 smoke runs on the Mac, seeds 1-2 are also slower on other TN codes:
  - TN_144: 1.09 s at seed 0, 3.79 s and 4.27 s at seeds 1-2;
  - TN_108: 0.30 s, then 0.85 s and 1.17 s;
  - TN_200: 0.08 s, then 0.21 s and 0.19 s.
- Seed medians, which the Tier 1-4 policy judges on, will therefore be 1.5-4x seed 0 on TN codes. The §7 table below uses seed medians.

### 5.5 Selector calibration (server, 600 s cap, wall s)

Calibration codes:

- Generated by `gen_codes.py`, with Gx/Gz from `scripts/compute_logicals.py`; all have d = L.
- The matrices are not committed: see `raw/CALIB_CODES_MANIFEST.txt`. Regenerating L <= 16 gave byte-identical files.
- L = 16-32 were added because everything finished in under 23 s at L <= 12.

| Code (n) | CC, pack | CC, no pack (excl,orbf) | MaxSAT (main's search) |
|---|---|---|---|
| TORIC L=6 / 8 / 10 (72 / 128 / 200) | 0.2 / 0.2 / 0.2 | 0.2 / 0.2 / 0.2 | 0.2 / 0.2 / 0.2 |
| TORIC L=12 (288) | 0.2 | 0.2 | 1.2 |
| TORIC L=16 (512) | 0.4 | 0.2 | 144.1 |
| TORIC L=20 (800) | 6.0 | 7.0 | TIMEOUT lb 9 |
| TORIC L=24 (1152) | 510.0 | 372.3 | TIMEOUT lb 9 |
| TORIC L=28 / 32 (1568 / 2048) | TIMEOUT lb 24 / 24 | TIMEOUT lb 24 / 23 | TIMEOUT lb 9 / 9 |
| PLANAR L=6 / 8 (61 / 113) | 0.2 / 0.2 | 0.2 / 0.2 | 0.2 / 0.4 |
| PLANAR L=10 / 12 (181 / 265) | 0.2 / 0.2 | 0.2 / 0.2 | 2.0 / 22.4 |
| PLANAR L=16 (481) | 3.0 | 2.6 | TIMEOUT lb 9, ub 16 |
| PLANAR L=20 (761) | 179.6 | 169.4 | TIMEOUT lb 9 |
| PLANAR L=24 / 28 / 32 | TIMEOUT lb 20 | TIMEOUT lb 20 | TIMEOUT lb 9 |

**What the runs show:**

- Every solved CC run has levels 1..L-1 EMPTY and a verified witness.
- The toric codes were searched on one half with Z mirrored (verified dual map), and they have one translation orbit.
- Node counts below level L are independent of L: TORIC L=24/28/32 have identical counts through level 23, as expected for clusters that cannot wrap around the torus.
- On these degree-2 codes, packing cuts nodes by 1.3-2.7x, but wall time is equal or worse. On toric L=24, packing is 1.37x slower.

**Implications:**

- CC is never slower than MaxSAT and wins from toric L = 12 and planar L = 8 on (ties at the 0.2 s floor below that).
- The in-code `-engine=auto` rule (qubit degree >= 3, else MaxSAT) and plan §5.3's routing of toric/surface codes to MaxSAT are both contradicted at these sizes.
- Context: the prototype's earlier toric_20 run had no orbits and searched both halves (4.85e9 nodes, 240 s on the Mac; a separate construction file). With orbits and the dual map, the candidate needs 9.4e7 nodes.

**Caveats:**

- MaxSAT ran in its default mode only.
- Dense codes were **not** calibrated.

## 6. Tier 0-4 comparison on the Mac (default seed)

- **Candidate:** 114b901, `S0/smoke_tier0_tier1_tier2_tier3_fix1.tsv` and `S0/smoke_tier4_fix1.tsv`. Every answer equals its stem's d.
- **main:** recorded 398054e Mac medians (`baselines/README.md`).
- **Prototype:** `proto_validate_orbf` (`excl,pack,orbf`, both halves searched up to both hit levels).

| Tier | Code | main Mac no-card / card-mto (s) | Prototype (Mac s) | Candidate (Mac s) | Candidate / main | Candidate / prototype |
|---|---|---|---:|---:|---|---:|
| 0 | 10 codes | 0.017-0.32 | 0.003-0.024 | 0.017-0.018 (process floor) | 0.06-1.03 (geomean 0.52 / 0.51) | floor |
| 1 | BB_108_8_10 | 0.285 / 0.388 | 0.006 | 0.018 | 0.063 / 0.046 | floor |
| 1 | BB_144_12_12 | 0.252 / 0.550 | 0.024 | 0.018 | 0.072 / 0.033 | floor |
| 1 | LP_238_44_6 | 0.395 / 0.376 | 0.006 | 0.018 | 0.046 / 0.048 | floor |
| 1 | LP_340_56_8 | 1.484 / 1.563 | 0.012 | 0.019 | 0.013 / 0.012 | floor |
| 2 | BB_144_14_14 | 30.28 / 28.19 | 2.81 | 0.495 | 0.016 / 0.018 | 0.18 |
| 2 | LP_442_68_10 | 32.18 / 20.52 | 0.024 | 0.019 | 0.0006 / 0.0009 | floor |
| 2 | TN_108_2_12 | 9.59 / 11.02 | 0.78 | 0.298 | 0.031 / 0.027 | 0.38 |
| 3 | BB_288_12_18 | 303.8 / 377.6 | 3.63 | 0.800 | 0.0026 / 0.0021 | 0.22 |
| 3 | GB_144_12_12 | 60.18 / 100.66 | 0.37 | 0.079 | 0.0013 / 0.0008 | 0.21 |
| 3 | LP_544_80_12 | 219.5 / 50.76 | 0.086 | 0.031 | 0.00014 / 0.0006 | 0.36 |
| 3 | TN_144_2_13 | 70.67 / 158.72 | 4.07 | 1.091 | 0.015 / 0.0069 | 0.27 |
| 3 | TN_200_10_10 | 13.63 / 10.57 | 0.33 | 0.078 | 0.0057 / 0.0074 | 0.24 |
| 4 | TN_250_10_15 | 1082.5 / 985.1 | 80.4 | 29.29 | 0.027 / 0.030 | 0.36 |

Tier geomeans of candidate/main (no-card / card-mto):

| Tier | Geomean |
|---|---|
| 1 | 0.040 / 0.031 |
| 2 | 0.0067 / 0.0076 |
| 3 | 0.0021 / 0.0022 |
| 4 | 0.027 / 0.030 |

The candidate is 2.6-5.6x faster than the prototype on the non-floor codes. This comes from three sources:

- about 2x per node;
- the hit-level skip (the prototype runs both hit levels);
- the single-half search under the dual map on BB/GB.

## 7. Plan §7 expectation table, rewritten with the S0d ratios (proposed preregistration for S1)

### 7.1 Assumptions (stated before any S1 run)

- **A1. Routing.** S1 routes every bundled code to CC. The plan's §5.3 gate does this for all 49 codes. The S0 `-engine=auto` rule does not: it routes the 28 TN/GB codes to MaxSAT, so it must be replaced (§9, item 2). If the S0 rule were kept, every TN/GB cell would run main's search and its expected ratio would be 1.0.
- **A2. Engine settings.** Default rules `excl,pack,orbf`, lockstep schedule, `-cc-dual=on`, `-ub-basis` as the PI decides (§10). Card modes do not change the CC computation, so both mode cells measure the same search.
- **A3. Server/Mac ratio** 2.6 (measured 2.55-2.71; up to 3.5 on cores with a busy SMT sibling). Predicted candidate server time = 0.1 s + 2.6 x (Mac time - 0.017 s Mac floor).
- **A4. Candidate seed medians:**
  - BB_288, TN_250 and LP_544: measured on the server with seeds 0-4;
  - other tier1-3 codes: predicted from Mac seeds 0-2 (`S0/smoke_*_{fix1,seed1,seed2}.tsv`; the a3c64a7 search is identical).
- **A5. Main's reference.** Main's recorded server medians are for the default seed. The decisive gate uses a concurrent main seed panel, whose medians may differ by 2-20x (GH-121), so the ratios below are indicative.
- **Pass rules: unchanged from plan §7.** Tier 1-4: for each tier and mode, the geomean of seed-median ratios is < 1 and no cell exceeds 1.25. Tier 5: the criteria are listed below §7.4.

### 7.2 Tier 0-2 quick filter (Mac, default seed): measured

Every tier1-2 cell's ratio is measured (§6) and lies in 0.0006-0.072. Every tier0 cell is in 0.06-1.03; the cells near 1.0 sit at the 0.018 s process floor.

The plan's §7 expected S1 Mac times were 2-3x pessimistic. Measured against expected:

| Code | Measured (s) | Plan expected (s) |
|---|---|---|
| BB_144_14_14 | 0.50 | 1.3-1.7 |
| TN_108 | 0.30 | about 0.8 |
| GB_144_12_12 | 0.08 | 0.2-0.4 |
| TN_144 | 1.09 | 2.6-3.0 |
| TN_200 | 0.08 | 0.15-0.35 |
| BB_288 | 0.80 | 1.8-2.2 |
| TN_250 | 29.3 | 47-56 |
| LP_544 | 0.03 | about 0.1 |

### 7.3 Tier 1-4 decisive panel (yfclab2, 5 seeds): expected seed-median ratios

| Tier | Code | main server no-card / card-mto (s) | Candidate server, seed median (range) | Source | Expected ratio, no-card / card-mto | Worst-seed ratio |
|---|---|---|---|---|---|---|
| 1 | BB_108_8_10 | 0.82 / 1.10 | about 0.1 (floor) | predicted | 0.13 / 0.09 | same |
| 1 | BB_144_12_12 | 0.72 / 1.68 | about 0.1 (floor) | predicted | 0.14 / 0.06 | same |
| 1 | LP_238_44_6 | 1.30 / 1.58 | about 0.1 (floor) | predicted | 0.08 / 0.06 | same |
| 1 | LP_340_56_8 | 3.78 / 4.46 | about 0.11 | predicted | 0.03 / 0.02 | same |
| 2 | BB_144_14_14 | 72.66 / 62.33 | 1.30 (1.22-1.34) | predicted | 0.018 / 0.021 | 0.018 / 0.022 |
| 2 | LP_442_68_10 | 40.69 / 45.76 | about 0.1 (floor) | predicted | 0.0025 / 0.0022 | 0.0026 / 0.0023 |
| 2 | TN_108_2_12 | 25.10 / 30.16 | 2.27 (0.83-3.09) | predicted | 0.09 / 0.075 | 0.12 / 0.10 |
| 3 | BB_288_12_18 | 735.4 / 919.0 | 2.83 (2.43-3.83) | measured | 0.0039 / 0.0031 | 0.0052 / 0.0042 |
| 3 | GB_144_12_12 | 130.93 / 59.26 | 0.29 (0.26-0.38) | predicted | 0.0022 / 0.0049 | 0.0029 / 0.0063 |
| 3 | LP_544_80_12 | 521.4 / 335.5 | 0.23 (0.20-0.23) | measured | 0.0004 / 0.0007 | same |
| 3 | TN_144_2_13 | 362.4 / 340.5 | 9.9 (2.9-11.2) | predicted | 0.027 / 0.029 | 0.031 / 0.033 |
| 3 | TN_200_10_10 | 129.44 / 20.55 | 0.56 (0.26-0.59) | predicted | 0.0043 / 0.027 | 0.0046 / 0.029 |
| 4 | TN_250_10_15 | 1786 / 3091 | 140.9 (75.1-180.6) | measured | 0.079 / 0.046 | 0.10 / 0.058 |

**Expected tier geomeans** (no-card / card-mto):

| Tier | Expected geomean |
|---|---|
| 1 | 0.08 / 0.05 |
| 2 | 0.016 / 0.015 |
| 3 | 0.0034 / 0.0061 |
| 4 | 0.079 / 0.046 |

**Expected outcome.** Every tier passes by a wide margin. The largest expected cell is 0.14, on a tier1 cell set by the process floor. Even a 5x adverse deviation (seed luck, core contention, a main panel faster than its recorded median) keeps every cell under 1.

**Comparison with the plan's expectations:**

- The plan's §7 ratios (tier1 about 0.02-0.2, tier2 0.002-0.09, tier3 0.002-0.04, tier4 0.05-0.06) are confirmed in direction.
- They change mainly through the server floor (tier1) and the seed medians (TN codes): tier4 is 0.046-0.079 instead of 0.05-0.06.

### 7.4 Tier 5 (yfclab2, 6 h, default seed, 1 run per cell): measured S0 values and preregistered expectations

The expected time for a solved code is at most 2x the S0 time. The factor of 2 covers measured core contention of 1.4-1.5x.

| Stem(s) | main 398054e server (no-card / card-mto) | Plan §7 expectation | Measured in S0 (114b901, server) | S1 expectation |
|---|---|---|---|---|
| LP_714_100_16 | 8752 / 5321 s | <= about 60 s | d=16, 3.9 s | d=16, <= 10 s |
| LP_1020_136_16 | 7159 / 8328 s | about 5 s | d=16, 2.6 s | d=16, <= 10 s |
| TN_216_4_18 | 16802 / 18346 s | 1500-1850 s | d=18, 672.5 s | d=18, <= 1350 s |
| TN_180_2_17 | 9837 s / TIMEOUT [17,19] | <= about 2100 s | d=17, 267.2 s | d=17, <= 550 s |
| BB_360_12_17to24 | TIMEOUT [17,24] both | d=24, 3.8-4.7 ks | d=24, 1993 s | d=24, <= 4.0 ks |
| LP_1054_140_17to32 | TIMEOUT [17,-] both | d=20, 200-250 s | d=20, 82.7 s | d=20, <= 170 s |
| LP_1768_224_ge17 | TIMEOUT [9,-] both | d=22, 820-1000 s | d=22, 344.5 s | d=22, <= 700 s |
| LP_1428_184_ge17 | TIMEOUT [17,-] both | d=24, about 7.5 ks | d=24, 4235 s | d=24, <= 8.5 ks (5.1x margin to the 6 h cap) |
| TN_252_2_17to28 | TIMEOUT [17,28] / [17,-] | TIMEOUT [20, 28 from U0] | TIMEOUT, lb 21, ub '-' (U0 off) | TIMEOUT, lb 21; ub 28 only with `-ub-basis=on`. d=21 is **not** expected under lockstep (§3.2). |
| TN ge9 group (7) + TN_648_10 | TIMEOUT [9,-] | TIMEOUT [19-21] | lb 18-20 at 1 h | TIMEOUT; lb >= the 1 h value, +1 expected at 6 h |
| TN ge17 group (6) | TIMEOUT [17,-] | TIMEOUT [21-23] | lb 20-22 at 1 h | TIMEOUT; lb >= the 1 h value, +1 expected |
| BB_756 / BB_864 / BB_1080 | TIMEOUT [17,-] | TIMEOUT [25-26] | lb 25 / 26 / 25 at 1 h | TIMEOUT; lb >= 25 / 26 / 25, +1 expected |

- **Expected solved cells: 16 of 52** (8 codes x 2 modes), against 7 for main. This equals the plan's expectation.
- **The plan's Tier-5 criteria hold on the S0 data, with one exception: the upper bound on the TN_252 no-card cell.**
  - All 7 cells main solves are solved, with the same d.
  - The lb is >= main's in every cell.
  - BB_360's upper bound (24) and TN_180 card-mto's (19) are matched or beaten by exact values.
  - The exception is TN_252 no-card, where main has ub 28. The candidate shows ub '-' unless `-ub-basis=on`. This is the one declared ub regression that plan §11.2 asks the PI to decide.

## 8. S0 exit gate (plan §6)

| Gate item | Status | Evidence |
|---|---|---|
| All tests pass | **Met** | `make test-cc` (0 bad, all mutants caught). `make test-cc-flags` 93/93. `smoke_test.sh` pass. Two independent S0a oracle harnesses (16226 + 15484 canonical runs, 0 failures, all 4 mutants killed). Tier0-4 smoke 23/23. Condition: mutants 3 and 4 are the fix-round-1 redefinitions, because the literal specification describes equivalent mutants. **PI to confirm.** |
| Verdicts agree on the 23 codes | **Met** | S0b: 72 runs, 1210 common cells with identical verdicts and node counts. Final d agrees in all 72 runs. Every prototype-only cell is explained. 114b901 additionally matches the prototype on 1236 cells across 25 tier3-5 codes (§3.3). |
| ns/node within 1.5x of the prototype | **Met** | Same host (Mac): 0.41-0.55x, i.e. faster (§5.1). |
| No refutation open (§9 of the plan) | **Met** | No lighter logical anywhere. All in-repo values equal the adjudicated ones. The orbits and dual maps of all 49 stems were re-verified independently (soundness review). No orbit-audit discrepancy. No open blocking finding. |
| §7 table rewritten with the S0d ratios and preregistered | **Met by this report (§7)** | Measured server/Mac ratio, seed medians and tier5 times. Assumption A1 (selector) must be implemented as stated. |

**Verdict: the S0 exit gate is met.**

S1 can start once the S1-blocking items in §9 are settled: items 2 and 3 are implementation work; U0 and the mutant definitions are PI confirmations. None of them is a correctness issue.

## 9. Open issues

Ordered by impact on S1.

1. **TN_252 is not solved under the default lockstep schedule** (§3.2).
   - The lockstep tie-break runs the empty Z21 before the X21 hit, so the run needs about 26.6 ks against the 21.6 ks cap.
   - d = 21 is reproduced in-repo only with the test-only `-cc-schedule=sequential`.
   - S1 expectation: TIMEOUT, lb 21 (as plan §7 expected).
   - Fix: S2b hit-level interleaving, or a preregistered schedule change. Do not tune it on this one code.
2. **The `-engine=auto` rule contradicts the S0d calibration.**
   - It sends 28 of the 49 bundled codes (all TN and GB) to MaxSAT, while CC wins on every toric and planar size tested.
   - For S1, implement the plan's §5.3 gate. It routes all 49 bundled codes to CC; the degree condition could be dropped altogether per §5.5.
   - Dense codes are still uncalibrated.
3. **S1 needs pieces that are not built yet:**
   - `-seed=N` on the MaxSAT path: the policy's main seed panel needs a seed flag in a candidate binary whose default is byte-identical to main;
   - `-engine-report`;
   - CI steps for `make test-cc`, `make test-cc-flags` and an `-engine=maxsat` identity check (plan §8.2).
4. **The certification track has not started.** There is no event-hash trace and no `tools/cc_check`. A `cc_check` replay is the only §8.5 bundle item still missing for the five claims.
5. **Mutants 3 and 4 were redefined** (fix round 1), because the specified versions are equivalent mutants. The PI should confirm the new definitions.
6. **NOTICE** still carries "DRAFT (pending PI approval)" and lacks the Qubitserf MIT copyright line (plan §5.1). Under the clean-room rule, this line must be added by someone allowed to read Qubitserf's LICENSE.
7. **A trap does not withdraw LB lines already sent.**
   - A run that ends UNKNOWN without a timeout can print a final `c d_lb` that rests on a level verdict the trap has just put in doubt.
   - This needs an engine bug first, and main's dualshare trap behaves the same way.
   - Harness rule until fixed: discard the bounds of any non-TIMEOUT UNKNOWN run.
8. **The driver trusts `dual_perm` and `orbit_of`.** Its only caller passes verified inputs. For defence in depth, the driver could re-verify the dual map with its own echelon.
9. **CC refuses to answer on incomplete logical bases** (rank[H;G] + rank S != n). It reports UNKNOWN, where main answers relative to the given G. This is conservative, and all bundled data passes; README should say that complete bases are required.
10. **Cosmetic:**
    - the `-v` banner still says "(symplectic MaxSAT)" under `-engine=cc`;
    - the `c cc: ... dual on` line prints the option, not whether a dual map is actually in use;
    - `-cc-rules=` (empty) is accepted as `none`.
11. **Seed sensitivity on TN codes.** The TN_250 seed median is 1.66x seed 0; TN_108 and TN_144 are 2.9-3.9x slower at seeds 1-2. This is not a defect, but it is already priced into §7.3.
12. **Server contention.** The SMT siblings of cores 0-63 were used by other users' unpinned jobs, giving 1.4-1.5x slowdowns. For the decisive and Tier-5 runs: prefer cores whose siblings are idle, or record per-core drift samples.
13. **Informational:**
    - builds are not byte-reproducible across worktree paths, though the logs are;
    - the stop rule means 58 hit-level cells are never searched, so facts such as TN_200 dX >= 11 cannot be cross-checked;
    - MRV is 1.2-1.4x faster on BB and LP tier5 codes but not on TN_252 or TN_144; the default stays unchanged (S2b);
    - pre-existing in main: the `-v` header is printed twice when stdout is a file, and README says "o -1 on failure" while the binary prints `s UNKNOWN`.
14. **Runner incident (S0d).** The first server runner could not start threads for cores 61-63 under the 4 GB address-space cap. Those jobs ran in a second runner with 512 KB thread stacks. Results are unaffected.

## 10. PI decisions requested

1. **Mutants 3 and 4:** confirm the fix-round-1 redefinitions (§2.2).
2. **U0 (`-ub-basis`) in S1.** Off (the S0 default) leaves the TN_252 no-card cell with ub '-' against main's 28. On emits U0 at t=0 (TN_252: 28).
3. **Stem renames for the five claims.**
   - ADJUDICATION §7 step 4 (in-repo reproduction) is now done. The remaining §8.5 item is a `cc_check` replay.
   - Options as in ADJUDICATION §7.5:
     - (a) rename now;
     - (b) wait for `cc_check` (certification track, S1);
     - (c) interim upper-bound-only renames.
4. **The 17 open lower bounds.** In-repo, single-thread traces now reach at least the prototype's bounds, with identical node counts. Decide whether this counts as the "clean-room implementation" agreement in ADJUDICATION §1. It is clean-room code, but it runs the identical canonical search, so it does not give an independent search tree. Alternatively, keep the bounds PLAUSIBLE until A/B or `cc_check` reproduces them.
5. **NOTICE wording** (plan §11.6).
6. **For information:** the S1 routing (§9, item 2) follows plan §5.3, which S0d allowed to be revised. On the bundled set it changes nothing compared with the plan's gate.

## 11. Files and reproduction

All paths are relative to `optimization/experiments/GH-124/`.

**This report and its raw data:**

- This report: `S0_REPORT.md`.
- S0d/S0e raw data, committed with this report (about 2.3 MB):
  - `raw/server-s0de/`: 74 server runs (logs, traces, `.done` markers, `results.jsonl`, `summary.tsv`, `summary.json`);
  - `raw/server-s0de2/`: 34 calibration and repeat runs;
  - `raw/server-s0de3/`: the TN_252 sequential run;
  - `raw/mac-s0d/`: 24 Mac runs with logs, traces and `results.jsonl`.
- `raw/server-runner/`: job lists, runners, `gen_codes.py`, `wcheck.py`, `summarize.py`, `s0d_metrics.py`, `compare17.py`, `mac_speed.py` and the server build log.
- `raw/report-analysis/`:
  - `cmp_proto.py` and `cmp_proto.txt`: node and verdict identity with the prototype logs;
  - `metrics.py` and `metrics.txt`: the S0d metrics recomputed from the traces.
- `raw/CALIB_CODES_MANIFEST.txt`: sha256 and regeneration commands for the 72 calibration matrices.
  - The matrices themselves (33 MB) are not committed.
  - Mac copy: untracked under `raw/calib-codes/`, ignored by `raw/.gitignore`.
  - Server copies: `yfclab2:~/mac-agent-20261009/gh124-s0de/{calib,calib2}/`, byte-identical to the Mac copy.

**Original copies:**

- Mac: `<scratch>/gh124-s0d-mac/`, where `<scratch>` is the Mac scratch workspace `scratch-2026-10-08-ce0ddb`.
- Server: `yfclab2:~/mac-agent-20261009/gh124-s0de/{out,out2,out3}`.
- Server build worktree: `yfclab2:~/mac-agent-20261009/gh124-114b901`.
- Nothing was left running on either host (checked 2026-10-16).

**Verification artifacts** (from the verification rounds):

- `tests/gh-124-cc-oracle` 985ea93 and `tests/gh-124-cc-oracle-r1` 6329459: the two oracle harnesses, on local branches (not pushed).
- `S0/oracle_s0a_fix1.log`, `S0/test_cc_engine_2000_1000_fix1.log`, `S0/identity_vs_main398_fix1.txt` (on this branch).
- The reviewers' logs are in the session scratchpad named in their reports.

## Completion report

- **What changed:** this report plus the S0d/S0e raw data, analysis scripts and the calibration manifest. No code change.
- **Validation performed:**
  - Recomputed every S0d metric from the traces.
  - Compared 35 trace sets cell by cell with the prototype logs: 1236 cells.
  - Regenerated the L <= 16 calibration codes and got byte-identical files; the Mac and server copies are byte-identical too.
  - Checked both frozen binaries' sha256.
  - Confirmed no leftover processes on either host.
- **Results:** see the Summary and §3-§7.
- **Unresolved issues:** §9.
- **Scientific semantics changed:** no.
- **PI action required:** yes (§10).
