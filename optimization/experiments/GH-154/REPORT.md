# GH-154: nonzero-rate HGP cycle-factor library

Date: 2026-10-28 (Asia/Taipei). Issue: https://github.com/guluchen/DistQLDPC/issues/154.
Branch: `codex/hgp-finite-rate-library`, stacked on GH-153 commit
`742eda14c05924a9473eeaaa75368096124f589f`; solver baseline e52d15b.
Status: **GENERATION / GF(2) / REPRODUCTION / FIRST CI PASS**.
Largest-input numeric bounds remain unavailable in the first configurations;
an explicitly separate no-pre-pass loading/bound check is pending.

## What changed

Six original HGP self-products of connected cubic-graph cycle codes, using
the approved HGP_{n}_{k}_unknown naming. Prefix is unchanged; this batch has
larger logical dimensions than the previous k=1 repetition specialization.

| Graph | n | k | Theorem-derived exact d |
|---|---|---|---|
| K4 | 45 | 9 | 3 |
| K3,3 | 106 | 16 | 4 |
| Petersen | 306 | 36 | 5 |
| Heawood | 610 | 64 | 6 |
| Desargues | 1261 | 121 | 6 |
| Tutte-Coxeter | 2866 | 256 | 8 |

For V vertices/E=3V/2 edges, a full-row-rank incidence check gives
[E,E-V+1,girth]. Tillich-Zemor Theorem 1 gives the parameters above. The
construction class has k/n tending to 1/13, bounded check/qubit degree, and
distance equal to graph girth. It does not claim linear classical-distance
or sqrt(n) quantum-distance scaling. See CYCLE_HGP.md for proof and sources.

Three proposals preceded implementation in #154: cycle-factor known-distance
ladder (selected), random regular (3,6) factors/open targets (deferred), and
Hamming/BCH factors with growing check degrees (deferred). Open issues and
branches were checked before claiming; hub #15 links the topic.

Generator, manifest, NOTICE, independent certificates, tests and bounded CI
are included. `scripts/compute_logicals.py` gains an **opt-in** bitset backend
with identical pivot/basis order; its default remains dense. The HGP
repetition CI is scoped explicitly to its six original stems when additional
HGP subfamilies are present. No solver code/defaults, tier data or names change.
No external graph/code data were copied, and no QDistSAT mirror is made.

## Validation performed

Mac: Python 3.9.6, algebra/generation/unit checks only; no solver process.

```sh
python3 scripts/codegen/hgp_cycle.py --ladder
python3 scripts/codegen/hgp_cycle.py --ladder --out /tmp/distqldpc-gh154-regeneration
python3 tests/test_codegen_cycle.py
python3 tests/test_codegen_hgp.py
python3 scripts/codegen/validate_css.py --output /tmp/gh154-validation.json
python3 scripts/codegen/validate_cycle.py --output optimization/experiments/GH-154/raw/construction-witnesses.json
git diff --check
```

- Seven cycle/backend tests and eight existing repetition/verifier tests pass.
- Graph simplicity, degree 3, connectedness, retained incidence rank V-1 and
  the omitted parity-row dependency are independently checked.
- Edge-deletion BFS shortest cycles and exhaustive enumeration of at most
  2^16 classical codewords agree on every classical distance.
- Independent small quantum oracles certify [[10,4,2]] and the K4 product's
  distance 3 (all supports of weights 1/2 excluded; weight-3 witnesses checked).
- Bitset output matches the dense implementation exactly on 100 random small
  CSS inputs, degenerate inputs and existing LP_34/TN_36/BB_72 cases. Logical
  files match byte for byte on a product fixture. No new default is selected.
- All 12 untiered codes (63 including existing tiered codes) pass the shared
  independent GF(2) verifier: commutation, dimensions/ranks, logical quotients
  and full pairing rank. No same-(n,k) peers exist for these six new codes.
- All 24 newly generated matrices reproduce byte for byte in a fresh directory.
  Raw hashes are in `raw/regeneration.log`; matrix checks are in `raw/validation.json`.
- Actual quantum matrices/logical bases are checked against independent lifted
  shortest-cycle witnesses in both halves; zero syndrome, non-stabilizer
  membership, nonzero logical detectors and odd mutual pairing are required.

## Solver smoke and results

First CI run 40667615158 passed all steps, including the default six smoke
attempts. Source `a6efadf9fc7024403f2bd5fb5bec62f2c63dea26`, binary SHA-256
`13aa8ba74b3960b8767bfda60d10fb09f057e6655f5112c6f3f343dfdee03328`.
Results: n=45/106/306/610 reproduce 3/4/5/6 exactly; n=1261 gives 5..6 at
timeout; n=2866 gives TIMEOUT_NO_BOUNDS. Its explicit `-ub-pre=1 -v` run
also returns TIMEOUT_NO_BOUNDS and confirms Hx/Hz 1305x2866 and Gx/Gz 256x2866.
Symmetry detection completed in this run, with no finder banner before timeout.
The first run's default and short-pre-pass records are preserved separately
under `raw/actions/default/` and `raw/actions/short-prepass/`.

To resolve the remaining numeric-bound visibility check, the next revision
adds one explicitly labeled `-ub-pre=off -v` 60-second setting for n=2866.
No constructor cost or speedup is claimed from this diagnostic; no solver
default changes. The first unavailable bounds are retained rather than replaced.

A branch-scoped ordinary GitHub Actions job builds
the unchanged solver and runs only these six new codes serially with
`-cpu-lim=60`, one pinned Actions core, a 4 GiB address-space cap and a
90-second backstop. This flag's parent wrapper implements a wall deadline.
An explicitly labeled supplemental check on the largest input records loading
and bounds separately from the default. No unavailable bound is replaced by
the mathematical claim or another configuration.

All output is retained as text, with commands, source/binary/input hashes and
environment. Numeric contradictions stop the sequence and trigger scientific
escalation. The Mac and dedicated-server cores are not used for solver runs.
No medians, seed-range/performance claims or timing-tier decisions are made.

## Unresolved / PI action

Pending the no-pre-pass CI check and final manifest backfill. A new exact-distance discovery
is not claimed: expected values follow from the published construction theorem
and independently verified classical distances. Stems stay unknown pending PI
names/tiers. The PI explicitly requested **direct push with no PR** for this
batch; no PR or merge will be attempted. Branch push is authorized; direct
main/gh-pages pushes remain outside scope.

- Scientific semantics changed: **no**.
- PI action required: **no** for generation, validation and work-branch push;
  future timing/tier assignment and benchmark-data adoption remain PI decisions.
