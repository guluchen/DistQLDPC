# GH-153: repetition-product HGP library

Date: 2026-10-28 (Asia/Taipei). Issue: https://github.com/guluchen/DistQLDPC/issues/153.
Base: `e52d15baa7a430104329d20467c12375fe60f0f2` (main).
Branch: `codex/hgp-repetition-library`.
Status: **GF(2) VALIDATED; SIX DEFAULT SMOKES RECORDED; SUPPLEMENTAL LOADING CHECK PASSED**.
One default smoke produced no numeric bounds; see the limitation below.
Final collector/workflow CI recheck is pending at this report revision.

## What changed

Original standard-library generator for the repetition-code specialization of
the Tillich-Zemor hypergraph product, with proposed family prefix HGP. Six
untiered codes have k=1 and n=13,41,113,265,481,1105. Claimed exact distances
3,5,8,12,16,24 follow from Theorem 1 of arXiv:0903.0566v2 applied to [L,1,L]
repetition factors. These are ground-truth construction instances, not new
distance discoveries. All stems retain `_unknown`.

Includes manifest, provenance/NOTICE, tensor-order documentation, independent
bitset GF(2) verifier, corruption/duplicate tests, matrix hashes and bounded
Linux/Actions runners. No src/, Makefile, solver default, tier or existing
matrix bytes changed; untiered codes are not mirrored into QDistSAT.

Three proposals preceded implementation in #153: repetition-HGP (selected:
known-distance ladder), cyclic repetition toric (deferred), non-repetition
finite-rate HGP (deferred). Open issues/branches were inspected before claiming
the topic; hub #15 links it. AGENTS.md, optimization policy and literature
context were read. This is library engineering, not a performance round.

## Validation performed

Mac: system Python 3.9.6, standard library only; generation and deterministic
tests, no solver runs. Exact commands from the repository root:

```sh
python3 scripts/codegen/hgp_repetition.py --ladder
python3 scripts/codegen/hgp_repetition.py --ladder --out /tmp/distqldpc-gh153-regeneration
python3 tests/test_codegen_hgp.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 scripts/codegen/smoke_untiered.py --cpu 54 --out /tmp/not-executed --dry-run
git diff --check
```

Core 54 in that dry-run is only an example; no server core was allocated or
used. Initial unit tests exposed unavailable Python `int.bit_count`; portable
population counting fixed it. Final local suite: 8 tests PASS.

- Tiny exhaustive support enumeration for L=2,3 in both CSS quotients agrees
  with d=L; no external solver.
- Deterministic random relabeling/check-basis transformations preserve checks.
- Mutants are caught: broken commutation, logical replaced by stabilizer,
  dependent quotient rows, invalid kernel row, direct and swapped duplicate
  row spaces, contradictory smoke answers/bounds and withdrawn numeric bounds.
- All six bundled codes pass independent commutation, rank/dimension, complete
  logical quotient and pairing-rank checks. Straight weight-L logical witnesses
  in both halves are independently checked for zero syndrome, non-stabilizer
  membership and odd mutual pairing. The cited theorem supplies the lower bound.
- Inventory: 51 existing + 6 new codes. No same-(n,k) peers exist, hence no
  candidates for rowspace or column-permutation duplication in this snapshot.
- All 24 fresh matrix files are byte-identical; the validation JSON also
  reproduces exactly. See `raw/regeneration.log`, `raw/validation.log`, and
  `data/matrices/untiered/validation.json` for hashes and full results.

## Solver smoke evidence

The PI asked to continue. AGENTS.md permits bounded ordinary CI smoke tests,
so GitHub Actions supplied the execution environment without using the Mac
or dedicated-server cores. No paid-cloud replacement or long experiment.

Original source: `64586f1c6f2c2613e6e1ef6b9175e1b521eaa912`.
Run: https://github.com/guluchen/DistQLDPC/actions/runs/40656041189.
Ubuntu 24.04, GCC 13.3.0, one pinned Actions core; build `make --jobs=2 bin/distqldpc`.
Binary SHA-256: `13aa8ba74b3960b8767bfda60d10fb09f057e6655f5112c6f3f343dfdee03328`.
For each stem the exact command was:

```
taskset -c 0 prlimit --as=4294967296 -- /home/runner/work/DistQLDPC/DistQLDPC/bin/distqldpc -cpu-lim=60 data/matrices/untiered/STEM
```

Six serial jobs; 4 GiB address-space cap, outer 90-second backstop. `-cpu-lim`
is the solver flag name; its parent wrapper implements a wall deadline.

| n | Default result | Exit | Observed wall seconds |
|---|---|---|---|
| 13 | d=3 | 0 | 0.040 |
| 41 | d=5 | 0 | 0.016 |
| 113 | d=8 | 0 | 0.164 |
| 265 | d=12 | 0 | 16.349 |
| 481 | 9 <= d <= 16; timeout | 1 | 60.060 |
| 1105 | UNKNOWN; both bounds unavailable; timeout | 1 from CLI; collector failed | approximately 60 (job log) |

This is a single smoke per input, default seed. Wall times are retained only
as execution evidence; no medians, speedups, seed-range comparisons or tier
verdicts are claimed. All numeric answers/bounds agree with ground truth.

The first workflow failed because its collector rejected n=1105's legitimate
no-bound timeout. The CLI supplied `c d_lb: -`, `c d_ub: -`, TIMEOUT and UNKNOWN;
there was no crash or numeric contradiction. Default `g_ub_pre=60.0` consumes
the entire smoke allowance in this case; bounds are sent only after that pass
returns (see `ub_prepass` / `min_distance_css_interleaved`). This is an observed
default-bound visibility limitation, not a solver semantic change or an exact
distance claim. The manifest preserves empty default bounds with explicit
TIMEOUT_NO_BOUNDS; they are not filled from published d or another mode.

All 14 original artifact text files, plus the failed job log, are retained
under `raw/actions-attempt1/`. Recovery run 40656784722 copied the existing
artifact as text without rerunning solvers. Artifact ID 12802180334, ZIP
SHA-256 `e9939b20d66716308edda021d117dc3ede9673956706c092afa2a18dc1ec2d9c`.
The durable record does not depend on the expiring Actions artifact.

### Supplemental largest-input loading check

Source: `cbf1416906f655e738b063b1732531560074020a` (identical solver sources).
Run: https://github.com/guluchen/DistQLDPC/actions/runs/40657138146.
Same binary SHA-256 and input hashes as the original run. Exact command:

```
timeout --kill-after=5s 90s taskset -c 0 prlimit --as=4294967296 -- ./bin/distqldpc -cpu-lim=60 -ub-pre=1 -v data/matrices/untiered/HGP_1105_1_unknown
```

PASS: verbose output confirms Hx/Hz 552 by 1105 and both logical bases 1 by
1105. Result: 9 <= d <= 26, timeout/exit 1, wall 60.027 seconds. The pre-pass
budget is checked between iterations; its single iteration took 3.261 seconds.
This explicit tuning is not a new default and is not substituted into the
default manifest columns. The weight-26 X witness independently passes zero
Hz syndrome, exclusion from row(Hx) and nonzero Gx detector pairing; evidence
is `raw/short-prepass/{solver.log,metadata.json,result.json,witness-verification.json}`.
It is a valid upper bound although the known mathematical distance is 24.

The collector now records a genuine timeout with no/partial numeric bounds
as UNKNOWN with null fields. Missing output without a timeout, wrong numeric
answers/bounds and withdrawal of previously numeric bounds still fail. Added
fixtures cover these distinctions. The permanent library CI checks six
defaults and the explicitly labeled supplemental short-pre-pass configuration.
The temporary artifact-recovery workflow is removed after evidence retention.

## Results and unresolved issues

Generation, GF(2), duplicate inventory, regeneration and short CLI execution
evidence are complete. Four exact distances were reproduced; both larger
inputs have observed consistent numeric bounds, with n=1105's numeric bounds
coming from the separately recorded supplemental setting. Its **default**
60-second run still has no numeric bounds. Do not label that numeric-bound
gate as passed or erase the failed attempt. No scientific contradiction was
found and no solver behavior was changed to obtain a pass.

Remaining PI work is review of the proposed HGP prefix/data, deciding whether
to request a PR, and eventual dedicated-server timing/tier assignment. No PR
opened (the handoff requires a request); no merge or rename attempted.

- Scientific semantics changed: **no**.
- PI action required: **yes** — data/prefix review and explicit merge approval;
  no compute permission is needed for the already completed smoke checks.
