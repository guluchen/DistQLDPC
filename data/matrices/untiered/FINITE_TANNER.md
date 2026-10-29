# Moderate-blocklength finite-group Quantum Tanner inputs (GH-169)

Original reconstruction of six fixed instances from F. A. Mian, V. L. Addala,
A. Meraj, A. Chadha and S. Krastanov, *Quantum Tanner Codes at Moderate
Blocklength*, [arXiv:2608.12509v1](https://arxiv.org/abs/2608.12509v1),
Eq.(34), Tables I, IX and XII. TN is the existing family prefix. These inputs
add finite-group/local-code specializations, not a new disjoint code family.
All stems remain unknown, all logical sectors retained, no gauge removal.

|n|k|group order / group|published (dX,dZ) upper estimates|
|---|---|---|---|
|288|8|6 / S3|(15,15)|
|360|6|10 / D10|(18,18)|
|480|8|10 / D10|(21,18)|
|588|14|14 / D14|(20,18)|
|756|10|12 / C3 semidirect C4|(9,42)|
|864|8|18 / C3 x S3|(27,32)|

All these distances are **randomized upper estimates**, not exact distances
or lower-bound certificates. Table III contains different same-(n,k) variants;
in particular its 480/864 headline claims are not substituted for Table I.
The source filenames can contain older estimator values, e.g.480 (22,18),
756 (9,46),864 (41,60). Their full local matrices, multisets and permutations
match the selected published instances. File estimates are retained separately
from the later paper estimates in the case JSON. None is an internally verified
logical word until checked in GF(2). No parameter sweep was performed.

## Construction, conventions and proof

Qubits (i,j,g) have index (i*nB+j)*|G|+index(g). Group permutations use the
published right-action cycle convention, product a*b maps point t to b(a(t)).
Enumerate the generated finite group and sort its point images; arbitrary
group enumeration only relabels each fiber's qubit coordinates.

Local H_A,G_A and H_B,G_B are full orthogonal dual pairs. Column permutations
pi_A,pi_B act simultaneously on H and G: new column i is old column pi[i].
Denote the original local matrices by subscript0 and permuted ones by1.
The two regular actions follow A. Leverrier, W. Rozendaal and G. Zemor,
*Small quantum Tanner codes from left-right Cayley complexes*,
[arXiv:2512.20532v1](https://arxiv.org/abs/2512.20532v1), Sec.1 Eq.(2):
lambda_a rowg meets column a*g; rho_b rowg meets column g*b^-1. In particular
the right-action inverse must not be dropped. These are mathematical
definitions, no source implementation was used.

Hx has H0_A tensor G0_B on slices g, then H1_A tensor G1_B on a_i*g*b_j^-1.
Hz has G0_A tensor H1_B on g*b_j^-1, then G1_A tensor H0_B on a_i*g.
Left/right regular actions commute and are orthogonal permutation matrices.
For Xtop/Ztop and Xbottom/Zbottom, the common action cancellation leaves
H0_A G0_A^T=0 or H1_A G1_A^T=0. For Xtop/Zbottom and Xbottom/Ztop,
it leaves G0_B H0_B^T=0 or G1_B H1_B^T=0. The surviving group action depends
only on the other coordinate and cannot spoil that sum. Thus Hx Hz^T=0.
Full binary ranks, k and logical quotient bases are measured, not inferred
from an asymptotic rate formula. Existing compute_logicals.py --method bitset
builds full bases; independent checks verify both quotients and full pairing.

The independent validator represents group elements by **inverse point
images**, separately parses cycles, and reconstructs **columns by pullback**.
For physical group coordinate h, slice roots are respectively h,
a_i^-1*h*b_j, h*b_j, a_i^-1*h. It imports neither generator nor logical
builder. It verifies actual matrices, finite group order/noncommutativity,
local full duality, source projection/permutations, connected Tanner halves,
GF(2), logicals and source dimensions. No disconnected-copy size inflation.

## Source-instance identity and license

Numeric reconstruction records are pinned to QuantumSavory's repository
commit ca3af9bf2236d7da0486cd9df5804f6bd46f8895. Each HDF5 file was verified
by its exact Git blob identity and SHA256, and its full mathematical parameter
projection is retained/digested. The HDF5 local arrays are transposed into
row matrices explicitly; no matrix orientation is guessed from dimensions.

An additional numeric-only source audit extracts left/right regular action
permutations from the source Z-check blocks. Starting at a consistent identity
fiber index, it reconstructs each source index's abstract group value and
verifies all A/B action equations. That gives an explicit qubit permutation
within every fiber. After this permutation, both source Hx/Hz stabilizer row
spaces equal the original reconstructions. All six pass; the permutation and
source identities are retained in GH-169/raw/source-equivalence.json.
This validates which code a source claim refers to, not its distance.

No external constructor, search or verifier implementation was read/copied/run.
Only published mathematical descriptions, numeric local inputs and numeric
matrix comparisons were used. The optional source audit uses h5py solely to
read HDF5; normal generation and validation need only Python's standard library.
No author HDF5, downloaded logical basis or original matrix file is redistributed.
Original scripts/generated matrices are GPL-3.0-or-later. Numeric source inputs
are credited under the source repository's MIT notice, copied in full to NOTICE
(Copyright2026 Quantum Savory). The Mian paper has arXiv perpetual/nonexclusive
license; no paper text is copied. The Leverrier-Rozendaal-Zemor mathematical
reference is CC BY4.0, credited with the original reconstruction identified.

## Reproduction and validation

```sh
python3 scripts/codegen/finite_tanner.py --all --out /tmp/finite-tanner-rebuilt
python3 scripts/codegen/validate_finite_tanner.py --out /tmp/finite-tanner-check.json
python3 scripts/codegen/validate_css.py --output /tmp/all-css-check.json
python3 tests/test_codegen_finite_tanner.py
# Optional numeric-only source identity audit; requires h5py, no external solver:
python3 scripts/codegen/verify_finite_tanner_source.py --cache /tmp/tanner-source --fetch --out /tmp/source-equivalence.json
```

All24 matrix files reproduce byte-for-byte. Check all same-(n,k) stabilizer
spaces including X/Z swap against tiered/untiered inputs; pinned pending
GH-160/164/165/166/167/168 branches have no such peers. No suspected equivalent
instance is silently added. Source digests and permutations are checked offline.

Tests include source/local permutation/digest mutants, wrong right-action
convention that still yields CSS, single-half corruption, singular logicals,
disconnected halves, independent randomized tiny local-code lifts and an
exhaustive8-qubit support oracle. The parser distinguishes exact claims from
upper estimates and never promotes an unbounded timeout to a numeric result.

Linux smoke is six serial default60s checks per engine, one allocated pinned
core,4GiB address cap,90s wall backstop and stdin /dev/null. Retain all raw
outputs and source/binary/input identities, verify every printed word in GF(2),
and preserve absent bounds. A smaller witness than a heuristic estimate is
compatible with the source; a lower bound exceeding that upper estimate is a
scientific escalation. New one-engine stronger lower bounds/exact results are
PLAUSIBLE until independently checked. Results follow in GH-169/REPORT.md.
Heavy work becomes an unexecuted server package; no Mac solver run. No main
integration, tier assignment, rename or QDistSAT mirror is part of this round.
