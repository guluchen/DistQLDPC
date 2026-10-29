# Next-source lead: SL(2,p) quantum Margulis / 2BGA

Research only; no additional family inputs implemented or claimed here.

M. Pacenti, D. Chytas and B. Vasic, *Construction and Decoding of Quantum
Margulis Codes*, [2503.03936v3](https://arxiv.org/abs/2503.03936v3), Quantum
10,2101(2026), [DOI](https://doi.org/10.22331/q-2026-05-12-2101), CC BY4.0.
Sec3 Eq8 supplies the left/right regular two-block CSS prescription;
Sec4 Eqs10/11 gives conjugated integral unipotent generators and reduction
modulo a prime. The paper focuses on decoding, not an individual exact
distance table. Sec7 explicitly distinguishes decoder performance from
minimum distance. No decoder/code/data from the authors is used.

Author repository Error-Correction-Lab/quantumMargulisCodes inspected only
through repository metadata/root listing at main commit
a25d3bad4682a207fc7df67edfd96dffe5ca4a5b. GitHub license=null, no root LICENSE.
Do not copy or redistribute its matrices. Rebuild the published mathematics
with original fixed generator parameters instead; cite the paper. A dataset
claim is not a solver-verified bound.

Source cautions: the paper repeatedly prints length642 for p7, whereas its
own formula2p(p^2-1) gives672. Do not silently identify an original672-qubit
specialization with that ambiguous published instance, copy its k/decoder
claim or rename source data. Specific source-instance reproduction would
require a PI interpretation. Original finite instances of the unambiguous
group formula can be labeled separately. Other source prose/transpose
conventions should be resolved by actual group maps and explicit GF2 chain
identities, not by trusting a transcribed equation alone.

Possible original next specialization (not frozen/implemented yet): choose
one even generator-set size4, fixed integral conjugation directions and
eta not divisible by p, for p5/7/11 (n240/672/2640). Even supports force a
known row dependency, so nontrivial finite k need not be found by repeated
rank/distance screening. Prove that actual support elements are distinct
and generate the group; verify physical rowspace connectivity rather than
counting disconnected copies. Compute actual k after fixing parameters.

The implementation would enumerate determinant-one2x2 matrices directly,
verify products with an independent faithful action, reconstruct both left/
right maps and inverse transposes, and check every binary column plus full
logical quotient bases/pairing. Do not infer a quantum-distance lower bound
from classical girth/expansion, use a projective quotient accidentally, or
assume an identity X/Z metric map. No distance-based support reselection.

This is a provenance/group specialization of2BGA, not an asserted disjoint
mathematical class or a completed certified-expander/good-qLDPC theorem.
Refresh issues/remotes and preregister the exact choices before work.

## Another genuine construction gap

Vijay–Haah–Fu, [1603.04442v1](https://arxiv.org/abs/1603.04442v1),
PRB94,235157(2016), TableI and AppendixB EqB8 describes static X-cube
CSS: physical links, cube-X12 and planar vertex-Z4 checks. Haah Code1
does not supply this type-I/foliated prescription. The displayed k=6L-3
derivation has an odd-L qualification, which must be retained. A future
small fixed odd-L ladder could check this missing mainstream family,
without treating it as an open-distance target or importing gauge/Floquet
and memory-lifetime claims. No author implementation read, no input built,
no distance/source-license acceptance claimed yet.
