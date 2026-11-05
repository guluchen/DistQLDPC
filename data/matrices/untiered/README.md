# Untiered matrix library

The library contains [repetition-factor HGP codes](#construction-and-distance-provenance) (GH-153),
[nonzero-rate cycle-factor HGP codes](CYCLE_HGP.md) (GH-154),
[triangular 6.6.6 color codes](COLOR666.md) (GH-156), and
[twisted-torus generalized toric/BB codes](TWISTED_TORUS.md) (GH-159). The shared MANIFEST.csv
and validation.json cover all batches. The table below describes the original
repetition-factor HGP batch only.

Issue: [GH-153](https://github.com/guluchen/DistQLDPC/issues/153).
Prefix: **HGP**. All six codes have k=1; the `unknown` generator stems were
replaced by the measured distances on 2026-11-04 ([placement](#placement-2026-11-04)).

| Factor length L | n | k | Claimed exact d |
|---|---|---|---|
| 3 | 13 | 1 | 3 |
| 5 | 41 | 1 | 5 |
| 8 | 113 | 1 | 8 |
| 12 | 265 | 1 | 12 |
| 16 | 481 | 1 | 16 |
| 24 | 1105 | 1 | 24 |

The small cases provide correctness anchors; the larger cases form a scaling
ladder. These are the surface-code specialization of the HGP family, with
vanishing rate. Nonzero-rate cycle-factor HGP codes are documented separately above.
Since 2026-11-04 the matrices live in the tier directories under the stems of the
[placement table](#placement-2026-11-04) and are mirrored to QDistSAT, e.g. `./bin/distqldpc HGP_13_1_3`.

## Placement (2026-11-04)

All 29 codes of the five batches were measured with main 02879a93 on yfclab2 (2026-11-04, PI plan of the same day;
runner, raw records and tables in `optimization/baselines/` and its `raw/main-02879a93/`) and moved into
`data/matrices/tier0` … `tier5` by the tier rule (slower of `-no-card` / `-card-mto`, 5-seed median, 5000 s limit).
Solved codes carry the distance DistQLDPC found; unsolved ones carry DistQLDPC's own proven bounds, never a
literature claim. The generators still write the `_unknown` generator stems below; `MANIFEST.csv` maps them to the
bundled files (`placed_tier`, `placed_stem`), and `scripts/codegen/validate_css.py` (`locate`, `same_as_bundled`)
resolves them, so the regeneration checks compare against the placed files (only the Gx/Gz header comment,
which names the parity file, differs). Every solved distance has a GF(2)-verified logical of that weight
(independent pure-Python check of x ∈ ker H_other \ rowspan H_same). No result disagrees with a claimed distance.

| Generator stem | Placed as | Tier | Claimed d | MaxSAT slower-mode median (s) | CC default median (s) | CC opt-in full median (s) | DistQLDPC result | Agrees |
|---|---|---:|---:|---:|---:|---:|---|---|
| AMC_108_6_unknown | AMC_108_6_9 | 0 | 9 | 0.14 | 0.08 | 0.09 | d = 9 | yes |
| AMC_216_6_unknown | AMC_216_6_12 | 0 | ≈12 (est.) | 0.37 | 0.08 | 0.07 | d = 12 | yes |
| AMC_330_6_unknown | AMC_330_6_14 | 0 | ≈14 (est.) | 0.82 | 0.07 | 0.07 | d = 14 | yes |
| AMC_438_6_unknown | AMC_438_6_17 | 1 | ≈17 (est.) | 9.08 | 0.12 | 0.10 | d = 17 | yes |
| AMC_522_6_unknown | AMC_522_6_20 | 2 | ≈20 (est.) | 55.43 | 0.57 | 0.26 | d = 20 | yes |
| BB_30_4_unknown | BB_30_4_6 | 0 | 6 | 0.05 | 0.08 | 0.09 | d = 6 | yes |
| BB_120_8_unknown | BB_120_8_12 | 0 | 12 | 0.59 | 0.08 | 0.10 | d = 12 | yes |
| BB_186_10_unknown | BB_186_10_14 | 1 | 14 | 1.22 | 0.08 | 0.09 | d = 14 | yes |
| BB_248_10_unknown | BB_248_10_18 | 2 | 18 | 33.00 | 0.55 | 0.43 | d = 18 | yes |
| BB_294_10_unknown | BB_294_10_20 | 3 | 20 | 610 | 2.34 | 1.22 | d = 20 | yes |
| BB_340_16_unknown | BB_340_16_18 | 2 | 18 | 28.85 | 0.32 | 0.26 | d = 18 | yes |
| COLOR_7_1_unknown | COLOR_7_1_3 | 0 | 3 | 0.04 | 0.06 | 0.06 | d = 3 | yes |
| COLOR_19_1_unknown | COLOR_19_1_5 | 0 | 5 | 0.06 | 0.09 | 0.09 | d = 5 | yes |
| COLOR_127_1_unknown | COLOR_127_1_13 | 1 | 13 | 1.60 | 0.08 | 0.07 | d = 13 | yes |
| COLOR_331_1_unknown | COLOR_331_1_21 | 5 | 21 | > 5000 | 122 | 13.65 | d = 21 | yes |
| COLOR_1027_1_unknown | COLOR_1027_1_31to37 | 5 | 37 | > 5000 | > 5000 | > 5000 | bounds 28–37 | consistent (open) |
| COLOR_2791_1_unknown | COLOR_2791_1_28to61 | 5 | 61 | > 5000 | > 5000 | > 5000 | bounds 26–61 | consistent (open) |
| HGP_13_1_unknown | HGP_13_1_3 | 0 | 3 | 0.05 | 0.08 | 0.08 | d = 3 | yes |
| HGP_41_1_unknown | HGP_41_1_5 | 0 | 5 | 0.08 | 0.09 | 0.08 | d = 5 | yes |
| HGP_45_9_unknown | HGP_45_9_3 | 0 | 3 | 0.06 | 0.08 | 0.09 | d = 3 | yes |
| HGP_106_16_unknown | HGP_106_16_4 | 0 | 4 | 0.11 | 0.08 | 0.08 | d = 4 | yes |
| HGP_113_1_unknown | HGP_113_1_8 | 0 | 8 | 0.11 | 0.07 | 0.07 | d = 8 | yes |
| HGP_265_1_unknown | HGP_265_1_12 | 1 | 12 | 1.93 | 0.09 | 0.08 | d = 12 | yes |
| HGP_306_36_unknown | HGP_306_36_5 | 0 | 5 | 0.42 | 0.06 | 0.06 | d = 5 | yes |
| HGP_481_1_unknown | HGP_481_1_16 | 3 | 16 | 120 | 0.24 | 0.13 | d = 16 | yes |
| HGP_610_64_unknown | HGP_610_64_6 | 1 | 6 | 9.53 | 0.19 | 0.19 | d = 6 | yes |
| HGP_1105_1_unknown | HGP_1105_1_24 | 5 | 24 | > 5000 | 181 | 3.86 | d = 24 | yes |
| HGP_1261_121_unknown | HGP_1261_121_6 | 3 | 6 | 107 | 3.40 | 3.37 | d = 6 | yes |
| HGP_2866_256_unknown | HGP_2866_256_8 | 3 | 8 | 562 | 257 | 191 | d = 8 | yes |

Notes: HGP_1105 (d = 24) and the color codes show the largest MaxSAT/CC gap: MaxSAT does not solve HGP_1105 in 6 h (CC default 72-189 s, CC opt-in full 3-7 s) and needs 4300-7900 s for COLOR_331 (CC default 21-148 s, opt-in 5-20 s). COLOR_1027 and COLOR_2791 stay open: their stems carry DistQLDPC's reproduced lower bounds (28 and 26) and the weights of verified basis logicals (37 and 61), which equal the claimed distances; nothing contradicts the claims.

## Construction and distance provenance

Source: J.-P. Tillich and G. Zemor,
[arXiv:0903.0566v2](https://arxiv.org/abs/0903.0566v2), Theorem 1;
published DOI [10.1109/TIT.2013.2292061](https://doi.org/10.1109/TIT.2013.2292061).
The published theorem applied to the full-rank [L,1,L] repetition check
gives parameters [[L^2+(L-1)^2,1,L]]. The individual ladder entries are our
specializations of that theorem, not a paper's numerical table or new solver results.

Let R be (L-1) by L, with R[i,i]=R[i,i+1]=1. We generate

```
Hx = [R tensor I_L | I_(L-1) tensor R^T]
Hz = [I_L tensor R | R^T tensor I_(L-1)]
```

Columns are (v1,v2), then (c1,c2), second coordinate fastest.
The two terms in Hx Hz^T are identical and cancel in GF(2).
The left blocks give full row rank L(L-1) for each check matrix, so k=1.
Straight strings on the first block, at fixed v2 for ker(Hx) and fixed v1
for ker(Hz), supply weight-L logicals with odd mutual pairing. The source
theorem supplies the matching distance lower bound.

Gx/Gz use DistQLDPC's convention: Gx is ker(Hx)/row(Hz), Gz is
ker(Hz)/row(Hx). They are computed by `scripts/compute_logicals.py`.
All code and matrices were generated from mathematics; no third-party code,
matrix files, or paper text was copied. Distribution: GPL-3.0-or-later; see NOTICE.

## Reproduce and verify

From the repository root (Python standard library only):

```sh
python3 scripts/codegen/hgp_repetition.py --ladder --out /tmp/hgp-fresh
python3 tests/test_codegen_hgp.py
python3 scripts/codegen/validate_css.py --output /tmp/hgp-validation.json
```

The generator refuses overwrite. Compare the 24 files in the fresh directory
with this directory byte for byte. `validation.json` records independent bitset
GF(2) checks and file hashes: commutation, ranks, logical kernel membership,
quotient independence and full logical-pairing rank. Duplicate comparison
uses row spaces in both X/Z orientations for every same-(n,k) filename in
tier0..tier5 and untiered. There are no such peers in this snapshot (57 codes).
This is not a general column-permutation equivalence algorithm.

## Solver smoke evidence

The branch workflow `HGP library smoke` supplies a bounded GitHub Actions
environment for these six checks. It builds the unchanged solver, rechecks
GF(2) invariants and byte-identical regeneration, then runs the six inputs
serially. `--ci` is restricted to a Linux GitHub Actions VM and selects one
core from that job's allocated affinity; it does not allocate server cores.
Results are uploaded as `gh153-hgp-smoke` and printed in the job log so they
can be copied into the durable GH-153 record before the artifact expires.

All six default 60-second CLI attempts ran in GitHub Actions, not on the PI
Mac. Their exact logs, commands and binary/input identities are retained in
`optimization/experiments/GH-153/raw/actions-attempt1/`.

| n | Default 60-second result | Supplemental result |
|---|---|---|
| 13 | d=3 | — |
| 41 | d=5 | — |
| 113 | d=8 | — |
| 265 | d=12 | — |
| 481 | 9 <= d <= 16; timeout | — |
| 1105 | UNKNOWN; no numeric bounds before timeout | 9 <= d <= 26 with `-ub-pre=1 -v` |

The default finder pre-pass has a 60-second budget, matching the entire smoke
limit. On n=1105 the parent timed out before receiving any bound. This is an
observed limitation of the default short smoke, not a claim that the input is
invalid. That row's empty default-bound fields mean **unavailable**, not zero
or claimed_d. Its extra loading/bounds check uses an explicit shorter pre-pass;
those results are recorded separately in the manifest and `raw/short-prepass/`.
The weight-26 witness from that check passed independent GF(2) verification.
The pre-pass budget is checked between iterations, so `-ub-pre=1` need not
finish within one second; the outer 60-second limit stays in force.

The first Actions job failed because the original collector rejected the
legitimate no-bound timeout. That failed run remains preserved. The collector
now distinguishes this UNKNOWN state from missing output, contradictory
results and withdrawn numeric bounds. The latter still fail validation.
The CI also performs the explicit short-pre-pass check on the largest input.
Do not infer dedicated-server timings or tiers from hosted-CI smoke results.

The Linux runner makes six serial jobs, each with 60 CPU seconds, a 90-second
wall backstop, pinned to one explicitly supplied core and a 4 GiB address-space
cap. It stops on contradictory bounds/answers or run failures. No core is
allocated by this package. Have the PI assign a core and check it is free
(including `ps -eLo pid,tid,psr,pcpu,comm` and `taskset -pc PID`) before starting.
Cores 54-63 require PI approval just like any other unassigned core.

```sh
make
python3 scripts/codegen/smoke_untiered.py --cpu ASSIGNED_CORE --out /tmp/hgp-smoke --dry-run
nohup python3 scripts/codegen/smoke_untiered.py --cpu ASSIGNED_CORE --out /tmp/hgp-smoke > /tmp/hgp-smoke-runner.log 2>&1 < /dev/null &
```

Retain all logs/JSON/CSV (including failed runs) in the issue's evidence record.
For a solved case require d=L; any numeric bounds must contain L. A missing
numeric bound remains unknown, and is never filled from the claimed distance.
A contradiction is a scientific escalation. The runner does not rename codes,
modify the manifest, assign tiers or mirror QDistSAT.
