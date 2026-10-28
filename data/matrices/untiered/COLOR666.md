# Triangular 6.6.6 color-code library

Issue: [GH-156](https://github.com/guluchen/DistQLDPC/issues/156).
Prefix: `COLOR`, approved for this batch to avoid confusion with the connected-cluster
(`cc`) engine. All files remain untiered and retain `unknown`; no tiered code,
benchmark suite or QDistSAT mirror changes.

| Odd lattice distance d | Data qubits n | Logical qubits k | Stem |
|---|---|---|---|
| 3 | 7 | 1 | COLOR_7_1_unknown |
| 5 | 19 | 1 | COLOR_19_1_unknown |
| 13 | 127 | 1 | COLOR_127_1_unknown |
| 21 | 331 | 1 | COLOR_331_1_unknown |
| 37 | 1027 | 1 | COLOR_1027_1_unknown |
| 61 | 2791 | 1 | COLOR_2791_1_unknown |

This adds a self-dual, geometrically local CSS family with three colored
boundaries. The 7-qubit member is the Steane code. The family has vanishing
encoding rate; its purpose here is structural diversity and known-distance
correctness/scaling checks. It is distinct from the repetition-factor HGP
surface-code specialization already in the library. No performance conclusion
is drawn from shared CI.

## Published construction and provenance

- H. Bombin and M. A. Martin-Delgado, *Topological Quantum Distillation*,
  [quant-ph/0605138v3](https://arxiv.org/abs/quant-ph/0605138v3),
  [DOI:10.1103/PhysRevLett.97.180501](https://doi.org/10.1103/PhysRevLett.97.180501):
  original color-code and triangular-boundary construction.
- K. Sahay and B. J. Brown, *A decoder for the triangular color code by matching
  on a Mobius strip*, [arXiv:2108.11395v3](https://arxiv.org/abs/2108.11395v3),
  Sec. II, Fig. 1 and Eqs. (1)-(2): honeycomb patch, face checks, parameters
  `[[3(d-1)(d+1)/4+1, 1, d]]`, and weight-d boundary logical operators.

The generator and matrices are original GPL-3.0-or-later project work derived
from the mathematics. No paper text, third-party implementation or matrix file
is redistributed. In particular, no decoder or third-party distance solver is
used for verification. See NOTICE, section 9.

`claimed_d` records the published family formula evaluated at each selected d.
It is not a new exact-distance discovery or a DistQLDPC result. Independent
GF(2) boundary-witness checks establish the corresponding upper bound for the
actual generated matrices. The matching lower bound for larger patches relies
on the published construction, not on the geometric validator or a 60-second
smoke run. Small d=3,5,7 are additionally checked by exact enumeration.

## Coordinate specification

For odd `d >= 3`, let `b = 3(d-1)/2`. Enumerate integer pairs `(r,c)` in
row-major order with `0 <= c <= r <= b`. Pairs with `r+c = 2 (mod 3)` are
face centers; the remaining pairs are qubits. A face at `(r,c)` meets qubits at

```
(r-1,c-1), (r-1,c), (r,c-1), (r,c+1), (r+1,c), (r+1,c+1),
```

retaining only positions inside the patch. Write these incidences as both
`Hx` and `Hz`. Interior checks have weight 6 and boundary checks weight 4.
Faces sharing qubits have different colors, assigned by `r mod 3`.
Each face has even size and any two different faces share either zero or two
qubits, giving `Hx Hz^T = 0` over GF(2).

With `t=(d-1)/2`, direct counting gives `n=3t(t+1)+1` qubits and
`m=3t(t+1)/2` faces, of which `3t` have weight 4. The rank is checked
independently for every bundled instance; `rank(Hx)=rank(Hz)=m`, so `k=1`.
The three boundaries `c=0`, `c=r`, and `r=b` each contain d qubits. Their
indicators have zero syndrome and odd self-pairing, making them nontrivial
X/Z logical representatives. They are verified against both computed logical
bases and stabilizer row spaces.

Gx/Gz are computed with the existing `compute_logicals.py --method bitset`.
In this repository Gx spans `ker(Hx)/row(Hz)` and Gz spans
`ker(Hz)/row(Hx)`. No solver or logical-builder behavior was changed.

## Reproduction and independent checks

From the repository root, using only Python's standard library:

```sh
python3 scripts/codegen/color666.py --ladder --out /tmp/color666-fresh
python3 tests/test_codegen_color666.py
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
python3 scripts/codegen/validate_color666.py --output /tmp/color-witnesses.json
```

Use a new output directory; generation refuses to overwrite a stem. Individual
codes use `--distance 13`, for example. CI compares all 24 regenerated files
byte for byte.

The separate geometric checker uses Cartesian coordinates `(x,sqrt(3)*y)`
inside `|x| <= y <= b` and identifies incidence by squared Euclidean distance
4. It imports neither the generator nor the logical builder. It checks exact
matrix incidence, boundary/bulk check counts, distinct incident face colors,
qubit degrees, GF(2) semantics, and three explicit boundary logicals per code.
The small-distance oracle enumerates all stabilizer translates of a logical;
for d=7 that is only `2^18` words. Relabeling and mutations exercise the
independent checks. Missing-face mutations are tested even though they keep
the remaining checks commuting.

The inventory checker compares same-(n,k) peers in all existing tiers and
untiered, including X/Z-swapped row spaces. No same-(n,k) peer exists for this
batch. Arbitrary column-permutation equivalence is not searched.

## Linux smoke and limits

Run by full path, e.g.

```sh
./bin/distqldpc -cpu-lim=60 data/matrices/untiered/COLOR_19_1_unknown
```

The branch workflow runs six default smoke checks serially, each pinned to
one runner core with a 4 GiB address-space cap and a 90-second wall backstop.
One separately labeled largest-code diagnostic uses `-ub-pre=off -v` under
the same limits. No solver experiment runs on the PI's Mac or server.
Logs, input/binary hashes, source commit, argv and results are retained under
`optimization/experiments/GH-156/raw/actions/` once the checks complete.
The manifest and report record observed bounds separately from claimed d.
Timeouts without numeric bounds do not satisfy the numeric-bound acceptance
requirement, even if the execution workflow completes successfully.
