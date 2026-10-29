# Untiered matrix library

The library contains [repetition-factor HGP codes](#construction-and-distance-provenance) (GH-153),
[nonzero-rate cycle-factor HGP codes](CYCLE_HGP.md) (GH-154),
[triangular 6.6.6 color codes](COLOR666.md) (GH-156), and
[twisted-torus generalized toric/BB codes](TWISTED_TORUS.md) (GH-159), and
[binary nonprimitive CSS BCH codes](BCH.md) (GH-207; dense CSS, not qLDPC). The shared MANIFEST.csv
and validation.json cover all batches. The table below describes the original
repetition-factor HGP batch only.

Issue: [GH-153](https://github.com/guluchen/DistQLDPC/issues/153).
Proposed prefix: **HGP**. All six codes have k=1; stems retain `unknown`
until DistQLDPC evidence and PI naming approval are available.

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
These files do not enter the existing tier suites or the QDistSAT mirror.
Run by path, e.g. `./bin/distqldpc -cpu-lim=60 data/matrices/untiered/HGP_13_1_unknown`.

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
