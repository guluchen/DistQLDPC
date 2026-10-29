# Quaternary group-valued PP inputs (GH-170)

Four original binary reconstructions from Jong Yeon Lee, *Designing Group-Valued
Codes with Full Regular Low-Weight Bases*, [arXiv:2610.06820v1](https://arxiv.org/abs/2610.06820v1),
Sec.V Eq.(21), App.B.3 Eq.(35), App.D.2. Existing prefix PP denotes provenance,
not a disjoint mathematical family. GH-167 binary CPM inputs did not supply
this noncyclic/quaternary specialization.

|n|k|group|source exact claim|source identifier|
|---|---|---|---|---|
|256|64|C16|12|pp-f4-256-64-12|
|512|128|C16 x C2|19|pp-f4-c16xc2-512-128-19-w10|
|768|192|C48|22|pp-f4-768-192-w10|
|1024|256|C64|25|pp-f4-1024-256-25|

One case per(n,k); alternate check presentations are not extra codes. Unknown
stems, full binary stabilizer/logical spaces, no halving/folding/gauge removal.
Source exact labels are not our own lower proofs. The noncyclic numeric record
labels its algebra as upper-only and retains older d_upper22 screening data;
the paper and separate exclusion receipts claim exact19, with a physical
weight19 word. These different evidence scopes are preserved.

## Construction and soundness

Mixed-radix group coordinates have the first component fastest. In C16xC2,
e=a+16b represents(a mod16,b mod2), with componentwise addition:15+1=0,
whereas C32 would give16. Group order alone does not specify this construction.

GF4 values1,2,3 denote1,w,w^2, with w^2+w+1=0. In the trace-self-dual basis
(w,w^2), multiplication matrices are I, [[0,1],[1,1]], [[1,1],[1,0]]. They
are symmetric and preserve field multiplication/addition. Tr(beta_i beta_j)
is delta_ij, so the binary dot product equals the field trace pairing and
binary expansion preserves CSS commutation. Weight counts physical bits;
field value1 has coordinates(1,1) and physical weight2, not symbol weight1.

Raw binary row(2i+a)P+g meets column(2l+b)P+(g-E[i,l]) when
rho(C[i,l])[a,b]=1. Hx=(U,V), Hz=(barV,barU), exchanging the four-column
halves and inverting group labels while fixing coefficients. For each row
pair, accumulate C[i,l]*C[j,l+4] at group label E[i,l]+E[j,l+4], l+4 mod8.
Independent polynomial GF4 arithmetic verifies cancellation at every label.
Together with the field representation this proves binary Hx Hz^T=0.

At n1024 the independent component-row pairs are(A,A+B),(B,A+B),(B,A+B),
giving maximum check weight11; other cases use(A,B). Any such independent
pair spans the original two binary rows, preserving all stabilizers/distance.
Measured rank pairs are(96,96),(192,192),(288,288),(384,384), giving k4P.
Ranks and both full logical quotients/pairing are directly verified, including
C48 where a power-of-two augmentation argument alone would not suffice.

## Independent validation

The validator imports neither generator nor logical builder. It derives GF4
multiplication by polynomial reduction and components by trace, enumerates
tuple groups independently, and reconstructs physical columns with root
g=h+e. It checks exact matrices, weighted cancellation, actual ranks, full
GF(2)/logical quotients/pairing, connected Tanner halves and source projections.
Every selected group generator preserves both check spaces. The involution
exchanging binary block j with j+8 mod16 and g with -g exchanges X/Z check
spaces and preserves physical weight, establishing dX=dZ.

Source Z words of weights12,19,22,25 and their reflected X words pass syndrome,
stabilizer exclusion and complete logical-detector checks. They prove upper
bounds only; no external exclusion log/program supplies our lower proofs.
Logical bases are computed by our compute_logicals.py --method bitset.

A preliminary plus-shift convention is exactly equivalent under inversion
of physical group positions and row slice indices. The final convention
matches source words directly. The coordinate certificate is retained in
GH-170/raw/coordinate-convention.json. A regression initially required unchanged
row order; its correction includes the proved row permutation. Both failure
and passing logs are retained; no solver run or distance contradiction occurred.

Tests cover all field products/trace, symbol-vs-bit weight, the C16xC2-as-C32
mutant, invalid field representation, stale source facts, singular logicals,
stabilizer exclusion, invertible row presentations, randomized tiny lifts and
exhaustive16-qubit supports. A global coordinate relabeling is distinguished
from an invalid field entry. All16 matrix files reproduce byte-for-byte.

## Source and license boundary

Numeric facts are pinned to yeon-lee/public-regular-logical-frames commit
04ad4795ad15cb89ee47b7868ff925c30b2fc731. The repository packs virtual records
inside catalogue.json and proofs/noncyclic_pp.json; virtual paths are not
claimed as downloadable files. Both outer Git blobs/SHA256 and mathematical
projection digests were checked. Only C/E/group/row-choice/witness facts are
extracted; no unpacker, constructor, search/verifier implementation was read,
copied or executed, and no external distance solver is used.

The repository has no LICENSE; the paper uses arXiv perpetual/nonexclusive
license. Following handoff7.2, independently rebuild from published mathematics
and cite it. No original JSON, matrix, frame or proof-program file is
redistributed and no MIT/CC BY license is imputed. Original scripts/generated
binary matrices are GPL-3.0-or-later, with attribution in NOTICE. Source facts
and independently checked word coordinates are identified as such.

```sh
python3 scripts/codegen/quaternary_pp.py --all --out /tmp/pp4-rebuilt
python3 scripts/codegen/validate_quaternary_pp.py --out /tmp/pp4-check.json
python3 scripts/codegen/validate_css.py --output /tmp/pp4-css.json
python3 tests/test_codegen_quaternary_pp.py
# Optional numeric-source audit; original files remain in external cache:
python3 scripts/codegen/verify_quaternary_pp_source.py --cache /tmp/pp4-source --fetch --out /tmp/pp4-source-check.json
```

Four additions here,28 total branch untiered. No same(n,k) peers in main or
pending GH-160/164/165/166/167/168/169 heads; reviewed identities retained.
Current duplicate checks compare both orientations including X/Z swap;
suspected permutation equivalences must be reported before same-dimension additions.

Linux: four serial default60s checks per engine, allocated pinned core,4GiB,
90s wall backstop, stdin null. Preserve actual CLI fields and source/binary/input
identities. GF2-checked source words may certify an exact answer's upper bound,
but never fill missing CLI numeric fields or lower proofs. Stronger one-engine
lower/exact results stay PLAUSIBLE. Missing gates stay incomplete; heavy work
becomes a server package. No solver/default/main/tier/rename/QDistSAT changes.
