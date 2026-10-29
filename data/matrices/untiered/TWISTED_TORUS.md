# Generalized toric / BB codes on twisted tori

Issue: [GH-159](https://github.com/guluchen/DistQLDPC/issues/159).
These are a BB subclass, using the existing `BB` prefix. This batch adds
different quotient lattices and polynomial checks; it is not presented as a
new unrelated code family. All six remain `unknown`, untiered and excluded
from QDistSAT until separate PI-approved timing/tiering.

## Source parameters

Z. Liang, K. Liu, H. Song and Y.-A. Chen,
[*Generalized toric codes on twisted tori for quantum error correction*](https://arxiv.org/abs/2503.03827v3),
PRX Quantum 6, 020357 (2025), [DOI:10.1103/rmy6-9n89](https://doi.org/10.1103/rmy6-9n89).
Mathematics: Eqs. (3)-(5); numerical instances: Tables 1-4.

The parameter columns below mean `f=1+x+x^a y^b`, `g=1+y+x^c y^e`,
and lattice generators `(0,h)`, `(w,s)`. The paper's exponent d is written e
here to avoid confusing it with distance.

| n | k | Published exact distance | h | w | s | (a,b,c,e) | Table |
|---|---|---|---|---|---|---|---|
| 30 | 4 | 6 | 3 | 5 | 1 | (2,0,2,0) | 1 |
| 120 | 8 | 12 | 10 | 6 | 4 | (-2,1,1,2) | 2 |
| 186 | 10 | 14 | 31 | 3 | 7 | (2,3,2,-2) | 2 |
| 248 | 10 | 18 | 62 | 2 | 25 | (-2,1,-3,-2) | 3 |
| 294 | 10 | 20 | 21 | 7 | 7 | (-3,1,1,-3) | 4 |
| 340 | 16 | 18 | 34 | 5 | -7 | (0,-4,4,0) | 4 |

These exact labels are published claims, kept separate from this project's
observed bounds. The original paper used integer programming for these
distances; no such external solver is executed here. Cases labeled only with
an upper bound in the paper are not silently treated as exact or included
in this batch. Original GPL-3.0-or-later code reconstructs the matrices from
mathematical parameters; no third-party code, matrix files or paper text copied.
The numerical parameter file is `scripts/codegen/twisted_torus_cases.json`.

## Coordinate and matrix convention

Write a group element of `Z^2 / <(0,h),(w,s)>` as `(x,y)` with
`0 <= x < w`, `0 <= y < h`; its index is `x*h+y`. For an arbitrary integer
coordinate, write `x=q*w+r` with `0 <= r < w`. Its representative is
`(r,(y-q*s) mod h)`. In particular crossing the x seam subtracts s from y;
negative exponents require floor division, not truncation toward zero.

There are two qubits per group element, so `n=2*h*w`. For each translated
origin, the X-check row supports f in block 0 and g in block 1; the Z-check
supports g with all exponents negated in block 0 and the negated f in block 1.
Equivalently `Hx=[F G]`, `Hz=[G^T F^T]`, where F/G are sums of translation
permutation matrices. Coincident monomials cancel by XOR. All bundled checks
have weight six, including after lattice reduction.

Translations commute in this abelian quotient, so `Hx Hz^T=FG+GF=0` over
GF(2). The independent rank checker verifies `k=n-rank(Hx)-rank(Hz)` for every
instance. Gx and Gz come from the existing `compute_logicals.py --method bitset`
and use the repository's `ker(Hx)/row(Hz)` and `ker(Hz)/row(Hx)` conventions.

The separate validator does not import the generator or reuse its reduction
routine. Instead it checks whether each candidate target minus the translated
polynomial term lies in the integer lattice: `dx mod w=0` and
`(dy-s*(dx/w)) mod h=0`. It reconstructs all rows by congruence, then checks
CSS/logical semantics and explicit nontrivial basis-row witnesses. These
witness weights are valid upper bounds and need not equal the published d.

The tiny n=30 oracle enumerates increasing supports through weight six,
computes syndromes directly and excludes stabilizer row space. It confirms
d=6 independently for both halves and a relabeled version. Tests also catch
an omitted antipode and wrong seam sign. No asymptotic or performance claim
is made.

## Reproduce and check

```sh
python3 scripts/codegen/twisted_torus.py --all --out /tmp/twisted-fresh
python3 tests/test_codegen_twisted_torus.py
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
python3 scripts/codegen/validate_twisted_torus.py --output /tmp/twisted-certificates.json
```

For one instance use `--n 120`. Generation refuses overwrite. CI compares
all 24 matrix files byte for byte. Same-(n,k) row-space and X/Z-swapped
comparisons cover existing tiers and untiered; the selected six have no
same-(n,k) peers. Arbitrary column permutations are not searched.

The branch workflow executes six default 60-second Linux smoke checks,
serially pinned to a runner core with a 4 GiB address-space cap and 90-second
wall backstop. No solver timing runs on the PI's Mac or server. Every
published exact claim is compared with the emitted bounds and answer;
contradictions fail collection and require scientific review. A timeout
without numeric bounds remains an unmet bound requirement, even if its
execution check succeeds. Final results and raw identities are recorded in
the manifest and [GH-159 report](../../../optimization/experiments/GH-159/REPORT.md).
