# Re-test of INCONCLUSIVE experiments on the corrected baseline 72d1fe1

Requested by the PI on 2026-10-09: re-test the experiments whose result was
INCONCLUSIVE. This record covers **porting, building and Tier0 correctness only**.
No timing was run here; the coordinator does timing later with the frozen binaries
below. No PRs were opened.

- Corrected baseline: `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7` (#62 / merge of PR #59).
- Frozen baseline binary: `yfclab2:~/mac-agent-20261009/frozen/tier3/base/distqldpc`,
  SHA256 `b943c2c94d67574505112a06e1bb806aec378fbbc79e9edca4a1c5236283e00e`.
- Host: yfclab2 (Linux, GCC 13.3.0 Ubuntu 24.04), every command pinned to NUMA node 0
  (`taskset -c 0-63,128-191`), at most 8 processes (4 concurrent solver runs = 4 parent + 4 child).
- Each port is a single commit on 72d1fe1 that re-applies only the original
  non-evidence delta (net diff of the original branch against its merge base, limited
  to the source/build/attribution paths). Nothing was redesigned.

## Results

| Candidate | Original PR / branch | Port branch / commit | Conflicts | Smoke | Partition py | Partition oracle | `-v` trace identity (10 cases) | Frozen server binary | SHA256 |
|---|---|---|---|---|---|---|---|---|---|
| GH-34 literal-indexed value mirror | #35 `experiment/gh-34-mac-litvals` (src 9735547 + a1b90ad on 24572d6) | `retest/gh34-litvals-72d` cbfbc4d | NOTICE summary list (GH58 line); kept both | PASS | PASS | PASS | 10/10 identical | `~/mac-agent-20261009/frozen/retest/gh34-litvals/distqldpc` | `8be62eede2298f6f7feba5a74fcb197e917558fea722da9224dac2da5b64e585` |
| GH21 O2-only | #24 `experiment/gh21-o2` (c9e924f/e1aa917) | `retest/gh21-o2-72d` 4871658 | none | PASS | PASS | PASS | 10/10 identical | `~/mac-agent-20261009/frozen/retest/gh21-o2/distqldpc` | `d83dbd20ab453e295c7513a014738a93c23125fa16cf32d6669db9f72ca6c812` |
| GH-16 PGO | #19 `experiment/gh16-pgo` (ad06d1a/4674331) | `retest/gh16-pgo-72d` 133055f | none | PASS | PASS | PASS | 10/10 identical | `~/mac-agent-20261009/frozen/retest/gh16-pgo/distqldpc` | `cef1978b6b4d83b3e25cb66a76307d42ab1d98f282604bf882be4492e8ff4d43` |
| H-007 LTO | #12 `experiment/h007-lto` (5b13a2c + 2efbdc1) | `retest/h007-lto-72d` ccc3347 | none | PASS | PASS | PASS | 10/10 identical | `~/mac-agent-20261009/frozen/retest/h007-lto/distqldpc` | `41bfa59ca9f6b99a23c6e60d99aaab57ff13cfb2fcd1b15858bf51bffe991696` |
| GH48 x86-64-v2 ISA | #49 `experiment/gh48-isa-v2` (d27cf4d + 5907551 + gate source from 80bd6ce) | `retest/gh48-isa-v2-72d` 59b9b6e | none (ci.yml gate step dropped, see notes) | PASS | PASS | PASS | 10/10 identical | `~/mac-agent-20261009/frozen/retest/gh48-isa-v2/distqldpc` | `a935d86b94b64e38cc0d1e4ef71a82b5273deac56fc1a793cd84dbeacb22f635` |
| GH64 guarded next-clause prefetch | #65 `experiment/gh64-guarded-prefetch` (7bde632, already on 72d1fe1) | `retest/gh64-prefetch-72d` 1d8fd6b | none | PASS | PASS | PASS | 10/10 identical | `~/mac-agent-20261009/frozen/retest/gh64-prefetch/distqldpc` | `4b49ffa7480378957a5bb6acfcae358a9a31706e92997ab4324fa44d0b0e86eb` |
| GH20 skip identity watch-tail copies | #23 `experiment/gh20-watch-tail` (7a0d6a2 + 3fe5afe) | `retest/gh20-watch-tail-72d` c9285b6 | NOTICE summary list (GH58 line); kept both | PASS | PASS | PASS | 10/10 identical | `~/mac-agent-20261009/frozen/retest/gh20-watch-tail/distqldpc` | `9c281e71685ad0cd462011e7f0a6f14fdaf88cd73fed3bb6429b4b8dc94134a3` |

All seven candidates: **Tier0 PASS, no regressions, search-trace identical to the
frozen 72d1fe1 baseline on every case.** Frozen binaries are mode 0555 in
mode-0555 directories, each with its own `SHA256SUMS`; the collected list is
`raw/frozen-SHA256SUMS.txt`.

## Tier0 procedure (per candidate, in its server worktree `~/mac-agent-20261009/retest/<name>`)

1. Build: `make -j8` (GH-34, GH21, GH48, GH64, GH20); `make -j1 LTO=1` (H-007, the
   original CI recipe); `bash scripts/pgo_train_build.sh <evidence>` (GH-16, see below).
2. Smoke: `bash scripts/smoke_test.sh`.
3. `python3 -B scripts/test_partition_soft_literals.py` (uses `bin/maxcdcl`).
4. Oracle: the `.github/workflows/ci.yml` compile line for
   `tests/test_partition_soft_literals.cc` linked against the candidate's `build/*.o`,
   then `timeout 20s build/test_partition_soft_literals` (prints
   `GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1` for all seven).
5. Trace identity (`raw/retest_trace.py`): `-v -cpu-lim=120 -{no-card,card-mto}` on
   BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, LP_34_20_2, run from the
   `base72` checkout. The frozen baseline was run twice (rep 2 identical to rep 1 on
   10/10, establishing determinism); each candidate's stdout, stderr and exit status
   were compared byte-for-byte with baseline rep 1. All 90 runs (2 baseline reps + 7 candidates, x 10 cases) completed (no
   TIMEOUT), with the named distances (10, 10, 8, 8, 10, 10, 6, 6, 2, 2). Per-run wall
   times in `raw/trace/trace_identity.json` are incidental and are **not** timing evidence.

## Notes and deviations

- **GH-34**: ports the final bit-exact version (`litvals.push(l_Undef ^ true)` for the
  negative slot, a1b90ad) plus MODIFICATIONS/NOTICE entries from 55bb1c0.
- **GH-16 PGO**: training reproduced exactly with the ported `scripts/pgo_train_build.sh`
  (fixed LP_34_20_2 and LP_136_32_4 x no-card/card-mto, `-cpu-lim=120`, `-j1`
  generate/use builds). All four training runs gave the correct distances (2, 2, 4, 4).
  The profile execution counts (`search` 89, `propagate` 375867) equal the original
  hosted training record (`raw/hosted-4674331/report/pgo-training/profiles.json` on the
  GH-16 branch). `-Werror=missing-profile -Werror=coverage-mismatch` passed and the
  final binary contains no `__gcov_` symbols. The script builds only `bin/distqldpc`,
  so `bin/maxcdcl` was linked afterwards with `make PGO=use PGO_DIR=$PWD/pgo-data bin/maxcdcl`
  for step 3; engine objects were not rebuilt. Profiles (`.gcda`) remain only on the
  server at `~/mac-agent-20261009/retest/gh16-pgo/pgo-data`; their hashes are in
  `raw/gh16-pgo/pgo-evidence/profiles.json`. Not ported: the raw-evidence
  `.gitattributes` rule. The MODIFICATIONS entry still links GH-16's PROPOSAL.md, which
  lives on the original branch.
- **H-007 LTO**: the oracle compile used the CI line plus `-flto=1`, because the
  slim LTO objects can be linked only with LTO enabled.
- **GH48 ISA**: the portable v2 gate (`optimization/experiments/GH-48/cpu_isa_gate.cc`)
  reports `compatible: true, level x86-64-v2` on yfclab2 (`raw/gh48-isa-v2/isa-gate.json`).
  The same gate step in `.github/workflows/ci.yml` was **not** ported. GitHub refused the
  push because the token lacks the `workflow` scope needed to change ci.yml. It is a
  CI host check, not part of the compiled delta. The gate step in the cross-repo
  workflow is ported.
- **GH20 / GH64**: the original focused probes (`GH-20/test_watch_tail.cc`, which the
  ported cross-repo workflow step uses, and GH-64's `test_prefetch.cc`) were not run.
  They are outside the requested Tier0 set.
- Binary hashes differ from the baseline even for flag-only changes, as expected (the
  `-g` paths differ and so does the code generation). Search identity is shown by the traces.

## Raw evidence (`raw/`)

Build and Tier0 scripts (`build_all.sh`, `retest_tier0.sh`, `retest_trace.py`), build
logs, per-candidate smoke, partition and oracle logs, the PGO evidence (without the
binary `.gcda` profiles and the training build tree), and all 90 trace logs with
`trace/trace_identity.json`.
