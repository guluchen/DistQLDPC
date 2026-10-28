# GH-154: nonzero-rate HGP cycle-factor library

Date: 2026-10-28 (Asia/Taipei). Issue: https://github.com/guluchen/DistQLDPC/issues/154.
Branch: `codex/hgp-finite-rate-library`, stacked on GH-153 commit
`742eda14c05924a9473eeaaa75368096124f589f`; solver baseline e52d15b.
Status: **GENERATED, VALIDATED AND PUSHED; BOTH CI RUNS PASS**.
Default numeric-bound visibility limitations are retained explicitly below.
The PI requested direct work-branch push with no PR; no PR or merge attempted.

## What changed

Six original HGP self-products of connected cubic-graph cycle codes, retaining
the approved HGP_{n}_{k}_unknown naming:

| Graph | n | k | Theorem-derived exact d |
|---|---|---|---|
| K4 | 45 | 9 | 3 |
| K3,3 | 106 | 16 | 4 |
| Petersen | 306 | 36 | 5 |
| Heawood | 610 | 64 | 6 |
| Desargues | 1261 | 121 | 6 |
| Tutte-Coxeter | 2866 | 256 | 8 |

For V vertices/E=3V/2 edges, a full-row-rank incidence check gives
[E,E-V+1,girth]. Tillich-Zemor Theorem 1 gives the HGP parameters. The
construction class has k/n tending to 1/13 and bounded degrees. Distance is
graph girth; no linear classical-distance or sqrt(n) quantum-distance scaling
is claimed. See `data/matrices/untiered/CYCLE_HGP.md` for proof and sources.
The values are theorem specializations, not copied quantum-code numerical
tables or new open-code distance discoveries. Stems remain unknown.

Three proposals preceded implementation in #154: cycle-factor ground truth
(selected), random regular (3,6) factors/open targets (deferred), and
Hamming/BCH factors with growing check degrees (deferred). Open issues and
branches were inspected; hub #15 links the claim.

Includes generator, manifest, NOTICE, certificates, tests and bounded CI.
`scripts/compute_logicals.py` gains an opt-in bitset backend with identical
pivot/basis order; its default stays dense. The repetition CI explicitly
selects its original six inputs when multiple HGP subfamilies coexist. The
shared smoke runner accepts explicitly labeled pre-pass-off checks and keeps
UNKNOWN bounds unknown. No solver source/default, existing tier matrix, tier
membership or distance name changes. No QDistSAT mirror or external code/data.

## Validation performed

Mac Python 3.9.6: generation, algebra and short deterministic unit checks only,
with no solver process or experiment timing.

```sh
python3 scripts/codegen/hgp_cycle.py --ladder
python3 scripts/codegen/hgp_cycle.py --ladder --out /tmp/distqldpc-gh154-regeneration
python3 tests/test_codegen_cycle.py
python3 tests/test_codegen_hgp.py
python3 scripts/codegen/validate_css.py --output /tmp/gh154-validation.json
python3 scripts/codegen/validate_cycle.py --output optimization/experiments/GH-154/raw/construction-witnesses.json
git diff --check
```

- Seven new cycle/backend tests and eight repetition/verifier tests PASS.
- Graph simplicity, degree 3, connectedness, incidence rank V-1 and the omitted
  parity-row dependency are independently checked.
- Edge-deletion BFS shortest cycles and exhaustive enumeration of at most
  2^16 classical words agree on all six classical distances.
- Independent small quantum oracles certify [[10,4,2]] and K4-product d=3:
  all supports of weights 1/2 excluded, with weight-3 witnesses verified.
- Bitset bases exactly match the dense algorithm on 100 random small CSS
  inputs, degenerate cases and LP_34/TN_36/BB_72. A product fixture's logical
  files match byte for byte. The existing default remains dense.
- All 12 untiered codes pass independent commutation, dimensions/ranks,
  complete logical quotients and full pairing-rank checks. Inventory is 63
  codes including existing tiers. These six new codes have no same-(n,k)
  peers, hence no candidates for rowspace/permutation duplication.
- All 24 new matrices reproduce byte for byte. Hashes are retained in
  `raw/regeneration.log`; all matrix checks in `raw/validation.json`.
- `raw/construction-witnesses.json` checks lifted shortest-cycle witnesses
  against the actual quantum matrices and logical bases: both zero syndromes,
  exclusion from the appropriate stabilizer rowspace, nonzero detector values
  and odd mutual pairing. This independently verifies every claimed upper
  witness; the HGP theorem and independently certified classical distances
  supply the matching mathematical lower bound.

## Solver smoke evidence and results

Ordinary bounded GitHub Actions CI supplied the environment. No Mac solver
run, dedicated-server core, paid-cloud substitute or external distance solver.
Ubuntu 24.04 / GCC 13.3.0; build `make --jobs=2 bin/distqldpc`.
Binary SHA-256 for both attempts:
`13aa8ba74b3960b8767bfda60d10fb09f057e6655f5112c6f3f343dfdee03328`.

Each default command is recorded fully in its JSON:

```
taskset -c 0 prlimit --as=4294967296 -- /home/runner/work/DistQLDPC/DistQLDPC/bin/distqldpc -cpu-lim=60 data/matrices/untiered/STEM
```

Six serial jobs per run; one pinned Actions core, 4 GiB address-space limit,
90-second external backstop. The -cpu-lim flag's parent wrapper uses a wall
deadline. Default seed only. No medians, seed-range/performance claims,
geomeans or tier decisions; all timings are raw execution evidence only.

### Initial run

Source `a6efadf9fc7024403f2bd5fb5bec62f2c63dea26`.
[HGP CI 40667615158](https://github.com/guluchen/DistQLDPC/actions/runs/40667615158)
and ordinary CI 40667614946: PASS.

| n | Default 60-second result |
|---|---|
| 45 | d=3 |
| 106 | d=4 |
| 306 | d=5 |
| 610 | d=6 |
| 1261 | 5 <= d <= 6; TIMEOUT |
| 2866 | TIMEOUT_NO_BOUNDS |

The separately recorded `-ub-pre=1 -v` n=2866 check also gave
TIMEOUT_NO_BOUNDS. It confirms Hx/Hz 1305x2866, Gx/Gz 256x2866, and completion
of symmetry detection, but no finder banner before the timeout. A short
finder budget does not cap its constructor; this observation motivated a
separate pre-pass-off check, without changing any default or input.

Raw records: `raw/actions/default/`, `raw/actions/short-prepass/`, and the full
job log `raw/actions/initial-job.log`. Primary manifest smoke columns refer
to this first attempt and are never replaced by later favorable outcomes.

### Recheck and largest-input pre-pass-off check

Source `3166097c1127a6d9e467f83f4e3ba0637d839851`.
[HGP CI 40668580167](https://github.com/guluchen/DistQLDPC/actions/runs/40668580167)
and ordinary CI 40668580295: PASS, including all 15 tests, regeneration,
independent graph/CSS/witness checks and both solver steps.

The four small exact results repeat. n=1261 and n=2866 default runs both return
TIMEOUT_NO_BOUNDS. The n=1261 difference from the first attempt is retained
in separate `smoke_recheck_*` manifest fields. No bound is invented, pooled or
selected by best performance; correctness/timeout semantics remain unchanged.

The largest input's explicit supplemental command appends `-ub-pre=off -v`
to the same 60-second/pinned/capped command. Result: **5 <= d <= 8**, timeout,
consistent with the independently verified weight-8 logicals. This setting
skips finder initialization and yields numeric search bounds; it does not
establish a controlled speedup or modify main behavior.

Raw records: `raw/actions/recheck-default/`, `raw/actions/no-prepass/`, and full
job log `raw/actions/no-prepass-job.log`. Supplemental flags/results remain
separate from default columns. Replaying all 14 retained execution records
reproduces their parsed outcomes, and every input SHA-256 matches the bundled
matrices. All raw records are committed, not dependent on expiring artifacts.

## Unresolved issues / PI action

Generation, independent correctness checks, reproducibility and short CLI
execution evidence are complete. The default 60-second numeric-bound gate
is still unavailable for n=2866 and, on recheck, n=1261. Do not label that
gate as passed merely because execution-check CI is green. Numeric bounds
for the largest input come from the explicitly labeled pre-pass-off setting.
No numeric contradiction or scientific mismatch was found.

Further main-baseline timing and tier/name assignment belong to a server-enabled
agent under PI policy. No long experiments, renames, tier moves or merges were
performed. The PI authorized direct push without PR; no PR was opened.

- Scientific semantics changed: **no**.
- PI action required: **no** to complete this authorized work-branch push.
  Later tier/name assignment or adoption remains a separate PI decision.
