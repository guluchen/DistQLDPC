# Finite single-sector homological-product CSS inputs (GH-179)

## Source and classification

S. Bravyi and M. B. Hastings, *Homological Product Codes*,
[arXiv:1311.0885v1](https://arxiv.org/abs/1311.0885v1), SecII/III,
Lemmas1/2/3 and Eq13; STOC2014,273–282. Onlyv1 exists. Original
mathematical reconstruction; no external code, matrices, paper prose/images
or solver is redistributed or run. The arXiv perpetual/nonexclusive paper
license is not a software/data license. Original scripts/matrices GPL3+.

Proposed HPC provenance prefix distinguishes these single-sector CSS
products from classical-factor graded HGP. Their checks can grow as
O(sqrtN), so they are NOT constant-check-weight modern qLDPC. The selected
finite rates/seeded matrices do not assert an asymptotic linear-distance
theorem. Practical asymptotically-good constant-check coverage remains open.

| Factor M,H,R | n=M² | k=H² | Actual check-weight range | Independent overall upper |
|---|---:|---:|---|---:|
|13,3,5|169|9|2–21|16|
|19,5,7|361|25|10–27|42|
|29,7,11|841|49|18–41|110|
|37,9,14|1369|81|20–49|168|
|43,11,16|1849|121|30–55|272|
|53,13,20|2809|169|36–68|266|

These are new finite parameters with initially unknown exact distances,
following the PI's priority. Upper words below are actual physical vectors,
not published finite distances or asserted minima. Unknown stems remain
pending PI naming/tiering; no QDistSAT mirror or main integration.

## Frozen factors and construction

Partition each M-dimensional binary factor as H,R,R, M=H+2R. Let D map
the final R basis vectors identically to the middle R and vanish otherwise.
Then D²=0,rankD=R. Generate independent seeded binary matrices U1,U2,
retaining the first invertible draw for each, and set delta_a=Ua D Ua^-1.
An explicit stable64-bit stream freezes every U/inverse/delta/seed and draw
count. Singular rejection counts(left,right) are(1,0),(0,5),(3,2),(1,1),
(0,4),(1,5). A raw/reduced-row-space connectedness guard exists, but every
case accepts pair sample0: NO connectedness resampling or other pair rejection
actually occurred. No word-weight, distance or solve-time screening occurs.
Poor finite distances, if observed, are retained rather than resampled.
The seeded deterministic examples do not assert exact uniform sampling or
that their finite H/M meets a sufficiently-small-rate theorem hypothesis.

Physical qubit(i,j) is labelled i*M+j. Define

```
partial=delta1 tensor I + I tensor delta2   (binary XOR)
Hx=partial
Hz=partial^T
```

The diagonal overlap MUST cancel by XOR. Since delta_a²=0 and the two tensor
terms commute, partial²=0, proving Hx Hz^T=0. This uses binary arithmetic,
not an assumption that partial is symmetric. No X/Z metric duality is assumed.
Rows/columns weigh at most the sum of factor maximum row/column weights,
hence at most2M. Actual rankHx=rankHz=(n-H²)/2 and k=H² are independently
checked along with all supplied logical quotient bases/full pairing.
Both actual Tanner graphs and the unique reduced-row-space partition are
connected, excluding hidden physical direct sums under check-basis changes.

The constructor uses row-bitset multiplication/inversion and tensor rows.
The independent verifier imports none of that implementation. It tests
U Uinv=Uinv U=I by actions on ALL factor basis vectors; delta U=U D by
column actions; factor squarezero/rank; and constructs the physical product
from tensor COLUMN actions. Every actual matrix entry is compared. This
checks the intended source construction beyond merely testing CSS commutation.

## Canonical logical basis: soundness and metric limitation

For h in the first H canonical coordinates, factor cycles are Ua e_h and
cocycles Ua^-T e_h. D and D^T kill e_h, so the transformed vectors have
zero appropriate syndrome, and cycle/cocycle pairings are the identity.
Tensor products give H² Z and H² X logical representatives for partial,
with identity pairing because tensor pairings multiply. Actual finite
syndromes, quotient extension ranks and the FULL H²-by-H² identity are
checked; matching actual k proves completeness. Their hashes and input
parameters bind this certificate to the matrices, alongside unchanged
compute_logicals.py --method bitset and independent validation of its bases.

For each half choose the lightest member of this CANONICAL BASIS (not all
logical combinations or physical supports), verify its actual syndrome,
nonmembership in the stabilizer and logical detector, then take the smaller
of the two physical weights as an overall upper. The weights are computed
AFTER applying U, not transferred from the canonical differential.

Crucial: U is a general invertible linear matrix, NOT a physical qubit
permutation or Hamming-weight isometry. It can preserve algebraic homology
while changing distance. A tiny unit exhibits similar four-qubit differentials
with distances1 and2, independently exhausting only15 nonzero words. Other
mutants catch inverse width, wrong canonical orientation, OR instead of
XOR, and a stabilizer incorrectly offered as a logical witness. No lower
bound or exact distance is inferred from U similarity or source asymptotics.

## Reproduction and validation boundary

```
python3 scripts/codegen/homological_product.py --all --out /tmp/homological-rebuilt
python3 scripts/codegen/validate_homological_product.py --out /tmp/homological-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/homological-inventory.json
python3 tests/test_codegen_homological_product.py
```

Compare all24 files byte for byte. Same(n,k) direct/swapped row spaces are
checked against tier0..5/untiered; current pending library branches also have
no same(n,k) peer. Different n separates this batch internally. Preserve all
prior24 manifest rows/96 files and51 tiered inputs.

Mac generation/algebra/tiny units only; selected Linux serial60sCPU per case/
engine,4GiB,90swall,one allocated pinned CPU. Every actual solver word is
independently GF2-verified. Missing CLI fields remain unavailable/INCOMPLETE,
not filled by a canonical upper. One-engine exact/stronger lower results
remain PLAUSIBLE until independent completion. Longer work is an unexecuted
yfclab2 package requiring PI allocation. No solver/build/default/bound/tier/
final-name/main change or automatic PR. See GH-179/REPORT.md and raw evidence.
