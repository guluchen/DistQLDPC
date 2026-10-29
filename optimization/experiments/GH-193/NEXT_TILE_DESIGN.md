# Next unselected candidate: planar tiles with an open-distance target

Primary Steffan–Choe–Breuckmann–Pereira–Eberhardt2504.09171v1, latest/only
listed. PDFp2–4 visually checked. Paper CC BY-NC-SA4.0; reconstruct mathematics
only, no author implementation/matrix/prose/images redistributed. TableI
claims exact distances; main text separately gives weight10 [[512,18,<=23]]
without exact certification. Do not relabel TableI values as heuristic.

Candidate next batch, NOT frozen/implemented/added: one exact [[288,8,12]]
anchor (B3,10x10bulk), source weight10 open512k18 (B4,13x13bulk), plus
original same-weight10 layouts21x21/33x33 (predicted n1152/2592,k18;
actual ranks/pruning authoritative, no inherited d23/growth claim).

Physical edge label (H/V,x,y) uses lower-left endpoint, tile origin(0,0).
Candidate transcriptions, to recheck/freeze only after fresh coordination:
- Source B3 weight6 X: H[(0,0),(2,1),(2,2)], V[(0,2),(1,2),(2,0)].
- Source B4 weight10 X: H[(0,0),(1,0),(3,0),(2,1),(2,3)],
  V[(0,3),(1,0),(3,1),(3,2),(3,3)].
Z follows source T2: swap H/V and reflect both coordinates B-1-coordinate.
The blue partner in the PDF independently agrees with these reflections.

Independent proposed finite implementation derivation:
Let b=B-1, square bulk anchors0..L-1 in both axes. The PDF's unrotated
layout has RED X boundary anchors above/below, BLUE Z anchors left/right
(do not interchange). Thus X anchors: x0..L-1,y(-b)..L+b-1;
Z anchors: x(-b)..L+b-1,y0..L-1. Pre-pruning physical H/V origins each
0..L+b-1 in both axes, giving n=2(L+b)^2. Bulk rows countL^2 per type,
boundary2bL; without dependencies/pruning k=2b^2. These counts are derived
checks, not an assumed source theorem about every possible tile.

Commutation derivation: reflected orientation-swapped tiles have cancelling
Laurent convolution cross terms on the infinite grid. For any opposite
boundary pair, X box's x-range and Z box's y-range are wholly physical;
their intersection is wholly physical, so truncation removes no cross
intersection. After restricting to the physical domain, remove columns
unsupported by either check type, then empty rows. Deleted cross terms
were alreadyzero; compare all actual GF2 entries and retained coordinates.

Required independent checker: enumerate actual edge columns/translated
anchors separately from constructor; verify support inventory, boundary
box intersections and source reflected partner, final pruning and all GF2/
ranks/logical quotients/pairing/physical rowspace/actual words/byte checks.
Compare same(n,k) and suspected column permutations across current refs;
source n512k18 has other published weight8 cases, so do not assume distinct
from a label/weight alone. Preliminary32ref scan also finds GH169
TN_288_8_unknown as a same(n,k) peer for the proposed anchor. Its retained
MaxSAT[9,15]/CC[13,15] does not constitute an independently confirmed
lower13; do not use that provisional lower alone to prove inequivalence.
Fresh direct/swapped/physical equivalence review is still required. No external ILP/distance tools; short Linux only,
heavy proof/source23-word completions become frozen server jobs. New prefix
TILE would be proposed, not an asserted disjoint algebraic family.

Earlier radial90 equivalence and source/proof packages, APM source hold and
certified-expander/cosheaf finite-hypothesis gaps remain visible. No new
issue/input/experimental distance result is claimed by this design.
