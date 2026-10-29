# Tanner-cycle balanced-product specializations

Issue [GH-160](https://github.com/guluchen/DistQLDPC/issues/160).
Proposed prefix `BP` identifies construction provenance. Cyclic balanced
products also admit an LP description; BP is not a claim of a mathematically
disjoint family. All new stems remain `BP_{n}_{k}_unknown` and untiered.

## Provenance and scientific scope

N. P. Breuckmann and J. N. Eberhardt, *Balanced Product Quantum Codes*,
[arXiv:2012.09271v3](https://arxiv.org/abs/2012.09271v3),
[DOI:10.1109/TIT.2021.3097347](https://doi.org/10.1109/TIT.2021.3097347),
Sec. IV-D/E/F: balanced total complexes, Tanner factors and cycle factors.

The finite graphs and labels below are our explicit specializations of that
general construction. They are not the paper's 1014-qubit hyperbolic instance,
and no asymptotic expansion/distance theorem is claimed for these small cyclic
graphs. In particular, the paper's horizontal-subsystem distance claims are
not assigned to these full CSS codes. Every homology class is retained; no
logical class is discarded as gauge. The solver semantics are unchanged.

All code and matrices are original GPL-3.0-or-later work from mathematics;
no third-party implementation, matrix file or paper text copied. Source
distance fields contain derived, independently verified upper bounds only.
The paper does not publish exact numerical distances for these instances.
Any exact result from our first search remains PLAUSIBLE until cross-checked
with another implementation/search order and a verified GF(2) witness.

## Complete finite construction

For odd length l, let graph vertices be integers modulo `4*l` and join x
to `x+s` for offsets, in this exact order,

```
1, 2, 3, 2*l, 4*l-3, 4*l-2, 4*l-1.
```

Undirected edge tuples are sorted lexicographically. The graph is simple,
connected and 7-regular, with `4*l` vertices and `14*l` edges. At vertex x,
use the following Hamming parity-check columns, selected by `x mod 4`:

```
5 3 2 1 6 4 7
2 1 5 6 7 3 4
7 4 1 6 3 2 5
3 1 4 2 7 6 5
```

Each integer denotes its three binary entries, least-significant bit first;
the column position matches the offset list. The labels were fixed from a
seed-0 permutation before any distance measurement, not selected for solver
performance. Every local check has weight four. Concatenating three checks
per vertex gives a Tanner matrix A with `12*l` rows and `14*l` columns.

The deck generator T adds 4 to each graph vertex. It acts on edges by moving
both endpoints and on checks by moving the vertex while keeping the local
bit index. Its order is l and all graph/check-cell orbits are free. No edge
joins vertices in one deck orbit: none of the offsets is 0 modulo 4 for odd l.
Labels depend only on the residue modulo 4, so they are invariant under T.
Thus the factor differential is equivariant: `A*T1=T0*A`.

Take the other factor to be the length-l cycle with its rotational action.
Anti-diagonal product orbits identify `[c,j]` with `[T^j(c),0]`. Order physical
qubits first by the `14*l` graph edges, then by the `12*l` Tanner checks.
The full CSS matrices are the two total-complex differentials:

```
Hx = d1 = [ A       I+T0 ]
Hz = d2^T, where d2 = [ I+T1 ]
                       [ A    ]
```

Here the matrix of T has column c equal to the unit vector at T(c).
Then `d1*d2=A*(I+T1)+(I+T0)*A=0` in GF(2). X-check weights are six;
Z-check weights reflect the two endpoint Hamming-column degrees plus two.
There are `26*l` physical qubits, a factor l fewer than the unquotiented
product. No subsystem projection is applied.

The actual Tanner matrix is full row rank for every selected l, checked by
independent elimination. The full CSS ranks also give k=2 directly. This
agrees with the homology of the quotient factor: 14 edge orbits, 12 independent
check orbits and zero check cokernel. Logicals are computed by the existing
`compute_logicals.py --method bitset` and independently checked in GF(2).

| l | n | k | Independently verified upper bound on d |
|---|---|---|---|
| 3 | 78 | 2 | 3 |
| 5 | 130 | 2 | 5 |
| 7 | 182 | 2 | 7 |
| 11 | 286 | 2 | 11 |
| 19 | 494 | 2 | 19 |
| 37 | 962 | 2 | 37 |

A horizontal-qubit indicator of a complete edge orbit has zero Hz syndrome.
The validator selects such an orbit outside row(Hx), checks its logical
detector, and stores its full support. This is an explicit weight-l logical,
so d<=l; it does not prove d=l. For the smallest l=3, independent enumeration
excludes weight-1/2 logicals in both halves and confirms a nontrivial weight-3
cycle, giving an exact tiny oracle.

## Reproduction and validation

```sh
python3 scripts/codegen/balanced_tanner.py --ladder --out /tmp/bp-fresh
python3 tests/test_codegen_balanced_tanner.py
python3 scripts/codegen/validate_balanced_tanner.py --output /tmp/bp-certificates.json
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
```

Use `--length 7` for one input. Generation refuses overwrite and verifies
k before assigning a stem. All 24 files are compared byte for byte in CI.
The independent validator imports neither the generator nor logical builder:
it enumerates graph pairs and full product cells, constructs anti-diagonal
orbit lookup tables, and quotients each cell boundary. It verifies the factor
rank, full CSS dimension, quotient condition, all logical bases and cycle
witnesses. Tests catch a reversed deck action, malformed witnesses and the
mistake of treating a verified upper bound as an exact distance.

The existing inventory checks all tiers plus untiered for same-(n,k) row-space
and X/Z-swapped duplicates. No same-(n,k) peers exist for this batch.
Arbitrary column-permutation equivalence is not searched.

Linux Actions runs each input serially for 60 seconds with default MaxSAT,
then independently with CC, using one pinned CPU and a 4 GiB address-space
cap per process. Both use verbose witness output. A separate Python audit
verifies every printed witness's syndrome, non-stabilizer membership and
logical detector, compares all engine intervals, and marks exact results as
cross-checked only when both engines agree and a matching weight witness is
independently verified. Solver sources/defaults are unchanged. No external
solver, server allocation or solver timing on the PI's Mac.

Observed results, scientific status and durable identities are in the manifest
and [GH-160 report](../../../optimization/experiments/GH-160/REPORT.md).

Two Linux panels (source `5a58dafa`, corrected collector `2831b4b7`) agree:
both engines solve n=78,130,182,286,494 with distances 3,5,7,9,9 and matching
independently verified witnesses. For n=962, CC solves 9 while MaxSAT times out
with [5,9]; that exact result remains PLAUSIBLE pending independent completion.
All observed intervals are numeric and consistent with the cycle upper bounds.
