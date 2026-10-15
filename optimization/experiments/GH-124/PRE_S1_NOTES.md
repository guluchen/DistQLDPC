# GH-124 pre-S1 changes: `-engine=auto` rule, `-seed=N`, S0 §9 minor items

- Date: 2026-10-16. Branch `experiment/gh-124-cc-engine`, on top of f38075a.
- PI decisions unchanged: CC is optional and not the default; `-engine=maxsat` (default) stays byte-identical
  to main 398054e; `-ub-basis` is on by default inside CC.
- Evidence: `pre-s1/` (Mac, at most 4 solver processes at once, 2 GB RSS watchdog per process group, `-cpu-lim`
  on every run; `pre-s1/runner.py`).

## 1. `-engine=auto` (replaces the S0 rule; S0_REPORT §9 item 2)

**Rule.** CC, except MaxSAT when, in the parity matrix of some half that has logicals (X half `Hz`, Z half `Hx`):

- (a) some row has weight > 32; or
- (b) n >= 64 and the mean row weight is > n/4.

With `-v` the decision and the measured values are printed, e.g.
`c engine: auto -> cc (X half (Hz): max row weight 16, mean 10.00, n 496; Z half (Hx): ...: sparse (...))`.

**Why this rule.**

- The S0 rule (minimum qubit degree >= 3, row weight <= 16) and the plan's §5.3 gate (mean degree >= 2.5) both
  use qubit degree. The S0d calibration (S0_REPORT §5.5) contradicts that: on toric and planar surface codes
  (qubit degree 1-2, row weight <= 4, L = 6..32) CC was never slower than MaxSAT and was faster from toric L = 12
  and planar L = 8 on. Degree is dropped.
- On all 49 bundled codes CC is at the process floor (tier0) or far faster (tier1-4 candidate/main 0.0001-0.07;
  tier5: the four codes main solves in 5321-18346 s take 2.6-672 s, four more are solved, and the open codes
  reach far higher lower bounds). They must all go to CC.
- What can make CC slow is row weight: it branches over the free qubits of one odd row, so the per-level growth
  rises with the row weight. Dense codes were not calibrated (§5.5 caveat), so they keep main's MaxSAT search.
- Margins (`pre-s1/structure_stats.txt`): the bundled codes have max row weight 6-16 (TN_496: 16) and mean row
  density <= 12.5% at n >= 64 (TN_72_8_8: 9/72); the calibration codes have row weight <= 4. Both limits are 2x
  the largest calibrated value. The n < 64 exemption covers the small dense-looking tier0 codes (LP_34_20_2
  23.5%, TN_36_8_4 25%), which CC solves at the floor.
- The plan's n <= 16384 limit is not used: no size effect against CC was seen up to n = 2048, and CC's largest
  max RSS in S0 was 32 MB (MaxSAT: 107 MB).

**Check.** All 49 bundled codes and all 18 calibration codes print `auto -> cc` (`pre-s1/cc_auto_tier0-5_runs.tsv`;
the tier3-5 rows are 1 s decision runs, rc 1 = timeout). `tests/test_cc_flags.sh` generates three d = 2 block
codes: one block of 34 (row weight 34: maxsat), two blocks of 32 at n = 64 (mean 32 > 16: maxsat), four blocks
of 32 at n = 128 (mean 32 = n/4: cc).

## 2. `-seed=N` (S0_REPORT §9 item 3, first bullet)

- N = 0 or no flag: nothing changes (main's search).
- MaxSAT path, N > 0: every fresh MaxCDCL solver (`run_css_half` probes and `-joint`) gets `random_seed` =
  1 + splitmix64(N) mod (2^31 - 2), never the built-in 91648253. Set from `src/core`; `src/solver` is unchanged.
  In this build `random_seed` only drives the 1% sampling of the lookahead threshold in `Solver::lookahead`
  (`rnd-init` is off and the random-decision code is commented out), as GH-121's `-pib-seed`. The encoding,
  the bounds and the answer cannot change; only the search order does.
- CC engine: `-seed=N` sets `-cc-seed=N` (relabeling). `-cc-seed` stays as the CC-only alias; giving both with
  different values is an error. With `-engine=auto` the seed goes to whichever engine is chosen.
- `-seed` with `-roundingsat` is rejected (it would have no effect).
- `-v` shows `c solver: MaxCDCL, cardinality encoding: ..., seed N (rnd-seed X)` only for N > 0.

**Identity** (`pre-s1/identity_vs_main398.txt`): all 14 tier0+tier1 codes x {`-no-card`, `-card-mto`}; raw
stdout+stderr compared with frozen main 398054e: `-v` default, `-v -seed=0`, `-v -engine=maxsat` and quiet
default. 112/112 identical on the first pass; main's hashes equal the S0-recorded ones.

**Seed effect** (`pre-s1/maxsat_seed_panel.tsv`): seeds 1-4 on the 17 tier0-2 codes x 2 modes (136 runs, plus
tier2 seed 0): every answer equals the stem d. The search (the `-v` log) changes in 128 of 136 runs and in all
34 cells; the 8 unchanged runs are LP_34_20_2 and TN_36_8_3 at seeds 1 and 4, which finish before any
threshold sample matters. Tier2 wall times over seeds 0-4 (4 parallel, indicative): BB_144_14_14 22-37 s,
LP_442_68_10 16-39 s, TN_108_2_12 10-13 s.

## 3. S0_REPORT §9 items

| Item | Status |
|---|---|
| 2 `-engine=auto` rule | fixed (§1) |
| 3 `-seed=N` | fixed (§2). `-engine-report` and the CI steps are still open |
| 7 a trap does not withdraw earlier LB lines | fixed: every CC no-answer stop sends `RESULT -1 TRAP`; the parent withdraws the bounds it had received. The final summary prints `c d_lb: -`, `c d_ub: -` and `c status: UNKNOWN (CC engine stopped without an answer: earlier d_lb/d_ub lines withdrawn)`. Live lines already printed cannot be recalled; the final lines are the result. Main's MaxSAT traps are unchanged (default path must stay identical). Tested with test mutant 2 on LP_136_32_4 |
| 8 driver trusts `dual_perm` / `orbit_of` | dual map: fixed. The driver now checks pi(rs Hz) ⊆ rs Hx, pi(rs Hx) ⊆ rs Hz and rank Hx = rank Hz with its own echelon (this implies pi maps F_X onto F_Z, weight preserved); failure is a trap. `orbit_of` is still trusted: checking it needs the generators, which the driver does not receive |
| 9 incomplete logical bases | documented in README (complete bases required; CC answers UNKNOWN otherwise) |
| 10 cosmetic | fixed: the `-v` banner says "(connected-cluster level search)" under CC (MaxSAT banner unchanged); the `c cc:` line prints `dual on (verified map in use)`, `dual on (no verified map: both halves)` or `dual off`; `-cc-rules=` with an empty value or an empty item is rejected |
| 13 README "o -1 on failure" | fixed in README (failure prints `c d  : UNKNOWN` / `s UNKNOWN`). The doubled `-v` header with file stdout is main's behaviour and is left unchanged |
| 1, 4, 5, 6, 11, 12, 14 | left: TN_252 schedule (S2b), certification track, PI confirmations (mutants, NOTICE), seed sensitivity and server contention (informational), runner incident (closed) |

## 4. Tests (clean build, Apple clang)

- `make test-cc`: PASS (14400 ladder runs, 1800 driver runs, 0 bad, 0 RESULT -1; all four mutants caught).
  The driver runs include 67 codes with a verified dual map, which now pass the driver's own dual-map check.
- `make test-cc-flags`: 129/129 (was 93): adds `-seed` values and conflicts, auto decisions on generated dense
  codes, `-v` decision and banner lines, the `dual` wording and bound withdrawal after a trap.
- `scripts/smoke_test.sh`: PASS.
- `-engine=cc`, `-engine=cc -seed=3` and `-engine=auto` on all 17 tier0-2 codes: 51/51 answers equal the stem d.

Scientific semantics changed: no. The default MaxSAT path is byte-identical to main 398054e.
