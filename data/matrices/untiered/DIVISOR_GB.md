# Divisor-driven cyclic generalized bicycle reference inputs

Original reconstruction of four published mathematical instances from
Liangdong Lu, Guanmin Guo, Yang Liu and Ruipan Yang,
*Quantum Bicycle LDPC Codes with High kd²/n from Divisor-Driven Search*,
[arXiv:2608.09115v3](https://arxiv.org/html/2608.09115v3), Tables II, IV, V,
Example 11. Source supports are attributed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Changes: original binary circulant expansion, independent validator, logical
bases and library format; no source software or matrix files copied.
Original scripts and generated files follow this project's GPL-3.0-or-later.

| Stem | l | k | Published exact d | Check weight | Source |
|---|---:|---:|---:|---:|---|
| GB_46_2_unknown | 23 | 2 | 8 | 14 | Table V, also Table II lifts |
| GB_66_20_unknown | 33 | 20 | 7 | 19 | Table II, Example 11 |
| GB_90_4_unknown | 45 | 4 | 10 | 14 | Table IV |
| GB_170_10_unknown | 85 | 10 | 8 | 12 | Table IV |

These extend an existing GB family; they are not four new families or an
asymptotic scaling claim. The fixed source supports, divisors and (where
published for the selected presentation) lifts are in
`scripts/codegen/divisor_gb_cases.json`. Latest v3 supports agree with the
earlier v1 research notes. Published distances are source claims until
reproduced internally; no external distance solver is used.

## Coordinates and reproducibility

For m=x^l+1 over GF(2), expand a,b in R=GF(2)[x]/(m).
Physical qubits are (block,h), index block*l+h, block=0,1.
The row r of Hx has a-support at (0,r-e) and b-support at (1,r-e), modulo l.
Hz uses b-support at (0,r+e) and a-support at (1,r+e).
Thus Hx=[A B], Hz=[B^T A^T]. Polynomial multiplication uses XOR cancellation,
including when the supplied divisor/lifts overlap. For n=66 the products
have supports a={1,2,3,5,10,27,32} and
b={0,1,3,4,5,7,13,15,22,24,30,32}, weights7 and12.

```sh
python3 scripts/codegen/divisor_gb.py --all
python3 scripts/codegen/validate_divisor_gb.py --output /tmp/gb-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
python3 tests/test_codegen_divisor_gb.py
python3 scripts/codegen/divisor_gb.py --all --out /tmp/gb-fresh
```

Generation refuses to overwrite any of the four files. Gx/Gz use the existing
`compute_logicals.py --method bitset`. Every logical quotient combination,
not only each row separately, is validated through rank extension and full
pairing. Gx denotes ker(Hx)/row(Hz) in the repository's matrix convention;
its physical witness is a Z word, and Gz supplies X words.

## Soundness and independent checks

Circulant translations commute, so Hx Hz^T=AB+BA=0. This CSS argument does
not require the stronger a*bar(b)+b*bar(a)=0 identity also checked for these
source examples. Omitting the transpose can pass CSS on that stronger
subclass; an independent column-by-column reconstruction is necessary.

Let d=gcd(a,b,m). Bezout gives the ideal (a,b)=(d) in R.
The kernel of the map s -> (sa,sb) equals the annihilator of that ideal:
sa=sb=0 iff sd=0. Since d divides m, this means m/d divides s, giving
kernel dimension deg(d) and rank l-deg(d). Reflection of both cyclic blocks
and exchanging blocks maps Hx's space onto Hz's space, so their ranks agree.
Consequently k=2deg(d). This argument works even with repeated factors in m;
it does not assume either component projection is injective. The independent
validator computes a set-polynomial Euclidean gcd and compares with actual
binary ranks; it does not import the generator's integer-polynomial routines.

All four cases must have both connected Tanner graphs, distinct check rows,
the stated row and column degrees, cyclic-shift automorphism and explicit
reflection/block-swap X/Z duality. Basis-row upper witnesses are checked in
GF(2); they are upper bounds only. Same-(n,k) peers are checked across all
current tiers/untiered and inspected pending library branches. No matching
peer exists for these four parameter pairs, which also rules out any
equivalence by column permutation with a current library input.

The unit suite includes randomized tiny cyclic pairs at even and odd lengths,
independent polynomial arithmetic/ranks, <=12-qubit exhaustive-distance units
and random relabelings. It catches missing-transpose, source-lift, gcd,
stabilizer-as-logical and singular-basis mutants. The first unit run had an
incorrect test-only assumption that all four tiny examples had distance2;
the complete support enumeration gives2,2,3,3 for l=3,4,5,6. Both initial and
corrected logs are retained. This was not a published-case disagreement.

Linux short-run results and any outstanding proof work are recorded in
`optimization/experiments/GH-171/REPORT.md`; missing numeric bounds remain
incomplete. Keep unknown stems, tiers and QDistSAT unchanged until PI review.
