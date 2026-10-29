# Nonabelian ZSZ lifted products (GH-166)

Six original reconstructions from Yifan Hong,
[arXiv:2607.27644v1](https://arxiv.org/abs/2607.27644v1), Sections 2.1-2.4,
Eqs. (1),(5)-(10),(13), Tables 1 and 3. Existing LP prefix is retained;
nonabelian structure is new coverage, not a claim that lifted products and
balanced products are disjoint families. These are the full CSS data codes,
not the paper's fold-symmetric or surgery/gauge variants.

| n | k | group (l1,l2,q) | published distance claim |
|---|---|---|---|
| 160 | 32 | (16,2,9) | exact 10 |
| 240 | 48 | (12,4,7) | exact 12 |
| 320 | 64 | (16,4,3) | exact 14 |
| 390 | 78 | (26,3,3) | heuristic upper estimate <=16 |
| 550 | 110 | (22,5,3) | heuristic upper estimate <=18 |
| 775 | 155 | (31,5,2) | heuristic upper estimate <=22 |

The case JSON records all four trinomials and exact source table rows.
Published estimates are not lower bounds and are not exact expected solver
answers. Stems stay `LP_{n}_{k}_unknown`. These explicit finite examples span
the source's 160-775 range; no larger parameters/distances are extrapolated.
No third-party source, matrix file, paper text or distance solver is used.
Original generator/validators and derived matrices: GPL-3.0-or-later; see NOTICE.
The source paper is CC BY 4.0; author/title/source/license attribution and
the change of representation to generated binary matrices are recorded there.

## Mathematical construction and soundness

Elements of Z_l1 semidirect_q Z_l2 are canonical pairs (a,b)=x^a y^b with
q^l2=1 mod l1. Multiplication is
`(a,b)*(c,d)=(a+q^b*c mod l1, b+d mod l2)`; inverse is
`(-q^(-b)*a mod l1,-b mod l2)`. Associativity follows by distributing powers
q^(b+d)=q^b*q^d, with modular representatives consistent because q^l2=1.
All selected twists are nontrivial; xy and yx differ.

Use column-action permutation matrices L[g]|h>=|gh>, R[g]|h>=|hg>.
Associativity implies L[g] R[h]=R[h] L[g]. R is a right action, so canonical
monomial x^a y^b applies right-x first, then right-y; left action applies
left-y first, then left-x. Transpose inverts the group element. Let
A=L[a],B=L[b],C=R[c],D=R[d] for the four specified trinomials. The block form is

```
Hx = [ A  0  B  0  C^T ]     Hz = [ C  D  0  0  A^T ]
     [ 0  A  0  B  D^T ]          [ 0  0  C  D  B^T ]
```

Every block of Hx Hz^T is one left/right commutator and vanishes in GF(2).
Classical [A B] and [C D] have full row rank l=l1*l2; the corresponding two
copies in each quantum matrix prove rank(Hx)=rank(Hz)=2l and k=5l-4l=l.
All checks have weight 9; qubit degrees are 3 or 6. No homology or logicals
are removed as gauge. Gx/Gz use the repository's existing bitset logical builder.

## Reproduce and independently validate

```
python3 scripts/codegen/zsz_lp.py --all --out /tmp/zsz-fresh
python3 tests/test_codegen_zsz_lp.py
python3 scripts/codegen/validate_zsz_lp.py --output /tmp/zsz-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/zsz-validation.json
```

Compare all 24 fresh matrix files byte for byte. Independent reconstruction
imports neither direct multiplication generator nor logical builder: it builds
basic left/right x/y permutations from elementary shifts/shears, applies
monomial powers in order, then assembles dense five-block matrices. Shared
GF(2) validation checks commutation, ranks, both logical quotient bases and
full pairing. Duplicate comparison includes both X/Z orientations on all
same-(n,k) peers. None exist on current main/untiered or the pending GH-160,
GH-164 and GH-165 library branches at this snapshot.

Tests include exhaustive associativity on the smallest group and random
larger-group triples, inverses/presentation, independent incidence, mutations
using abelian multiplication or left action in right blocks, GF(2) monomial
cancellation, reproduction/overwrite protection, witness rejection and
exact-vs-upper claim semantics. The unchanged default MaxSAT argv is tested;
CC selection is explicit. This is library validation, not a solver change.

## Linux smoke and scientific-result handling

The branch workflow builds the unchanged solver and runs units/algebra and
regeneration, then six serial default MaxSAT and six serial CC 60-second
checks, one allocated CPU, 4 GiB cap, stdin /dev/null, 90-second wall backstop.
Raw logs/source/binary/all input hashes are retained and actual printed
witnesses independently verified in GF(2), including quotient exclusion and
logical detector pairing.

For an exact literature claim, any answer or bounds excluding it reject the
run. For an upper estimate, a lower bound above it or an exact answer above
it rejects the run; a smaller exact answer is possible. Finding a weaker
upper bound than the estimate is not a contradiction, but also does not
independently reproduce the claimed upper witness. The audit records that
separately. Partial/no bounds stay incomplete numeric gates. New exact results
stay PLAUSIBLE until both independent engines complete and a minimum witness
is verified; the literature heuristic is not an independent lower-bound proof.

Linux workflow [40843413324](https://github.com/guluchen/DistQLDPC/actions/runs/40843413324)
passed. Actual results (default 60s per engine):

| n | MaxSAT | CC | confidence |
|---|---|---|---|
| 160 | exact 10 | exact 10 | two engines + verified minimum witness |
| 240 | exact 12 | exact 12 | two engines + verified minimum witness |
| 320 | [9,14] | exact 14 | CC reproduction; independent completion pending |
| 390 | [9,16] | [15,16] | CC stronger lower bound PLAUSIBLE |
| 550 | [9,18] | [16,18] | CC stronger lower bound PLAUSIBLE |
| 775 | [9,22] | [16,22] | CC stronger lower bound PLAUSIBLE |

All six pass the numeric smoke gate. Last three upper bounds are actual
GF(2)-verified nontrivial witness weights, independently reproducing the
published estimates. The common lower bound proved by both engines is 9
for n=320/390/550/775. Stronger CC-only lower bounds remain PLAUSIBLE under
PI policy; do not present [15,16]/[16,18]/[16,22] as independently confirmed
scientific intervals. Raw observed values remain intact in the manifest;
confidence is explicit in checks, report and raw/bound-crosschecks.json.
The source paper's last three distances remain estimates, not exact answers.

All twelve raw logs, input/source/binary identities, result CSVs and audit are
durably retained under GH-166/raw/actions/default/. Audit replay matches CI.
Seven unresolved exact-proof jobs are prepared, not executed, in GH-166/runner/;
no longer CI runs, Mac solver experiments or server cores were allocated.
No solver/default changes, main integration, stem rename or tier move.
