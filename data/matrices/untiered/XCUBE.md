# Static periodic link-qubit X-cube CSS inputs (GH-190)

Four fixed odd sizes L3/5/7/9 give(n,k)=(81,15),(375,27),(1029,39),
(2187,51). Proposed prefix XCB. This adds a mainstream foliated type-I
fracton prescription distinct from collected Haah Code1. It is a finite
structure/scaling control, not an unresolved-distance headline.

Source: Sagar Vijay, Jeongwan Haah and Liang Fu, *Fracton Topological Order,
Generalized Lattice Gauge Theory and Duality*,
[1603.04442v1](https://arxiv.org/abs/1603.04442v1), PRB94,235157(2016),
[DOI10.1103/PhysRevB.94.235157](https://doi.org/10.1103/PhysRevB.94.235157),
TableI/main Hamiltonian and AppendixB final odd-L degeneracy formula.
Latest/only version checked2026-10-30. Original mathematics only; paper
perpetual/nonexclusive license is not imputed to author files. No author
code/matrix files/prose/images or external algebra/distance program used.
Original scripts/new matrices GPL3+, NOTICE attribution. Source k=6L-3
is explicitly oddL; actual ranks checked, no evenL/boundary claim imported.

Physical qubits are positive-axis periodic cubic links(axis,vertex), axis-
major then lexicographic start vertex. Hx rows are cube origins, twelve
surrounding links. Hz rows are vertex then plane-normal0/1/2, four incident
links in the plane. Independent checker reconstructs each column from the
four containing cube origins and two endpoints/two containing planes.
It verifies every physical column, row weights12/4, full commutation,
ranks L^3-3L+2 and2L^3-3L+1, computed full logical quotients/pairing and
typed physical full stabilizer RREF connectivity. No same(n,k) peer across
29pinned main/library refs; direct/swapped rowspace checks still run.

Written finite lower proof is in MODIFICATIONS.md. Complete X line and Z
ribbon detector bases each have3(2L-1)=k rows. Per orientation, X lines at
transverse(0,b) all b plus(a,0),a>0 pair nonsingularly with all fixed-b/
vary-a ribbons and fixed-a/vary-b ribbons,a>0. Actual full quotient/pairing
ranks are checked, not presumed from geometry. For EACH detector, L actual
pairwise support-disjoint representatives are verified in its stabilizer
coset. Z ribbons translate through longitudinal layers; X line equivalents
use the original plus L-1 triple-line rectangle supports. All materialized
supports, kernels, coset membership and disjointness verified independently.
A tested nontrivial word must pair oddly with one complete opposite detector
and hence all its disjoint equivalents, forcing weight>=L. Actual nontrivial
line/ribbon words of weightL are GF2-verified against bundled computed
logicals. Both half distances have finite lower/upperL certificates.

| L | n | k | rank Hx | rank Hz | certified lower/upper per half |
|---:|---:|---:|---:|---:|---|
|3|81|15|20|46|3|
|5|375|27|112|236|5|
|7|1029|39|324|666|7|
|9|2187|51|704|1432|9|

These are original actual-matrix finite certificates, not source individual
exact-table labels or a transferred decoder/energy-barrier theorem. Internal
Linux engine comparison is required before final cross-checked labels. No
identity X/Z metric map, subsystem/gauge/circuit distance or physical face-
qubit convention silently assumed. Raw missing CLI fields stay missing.

Reproduction in fresh directories (existing files never overwritten):
```
python3 scripts/codegen/xcube.py --all --certificates optimization/experiments/GH-190/raw/certificates
python3 scripts/codegen/validate_xcube.py --out optimization/experiments/GH-190/raw/construction.json
python3 tests/test_codegen_xcube.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```
16new+34prior units pass. Missing/duplicate quotient detectors, insufficient
representatives, overlap, wrong coset, source edge, logical/hash/stabilizer
mutants and5tiny random physical relabels exercise the proof hypotheses.
First4matrix+1fullcert regeneration passes. Full16matrix+4certificate byte
reproduction and4case MaxSAT+CC serial60sCPU/90swall/4GiB/defaultseed/pinned
allocated Linux CPU checks pending,12min cap. Heavy unfinished work becomes
unexecuted yfclab2 packages requiring PI allocation. No solver/scientific
support search on Mac; no solver/default/tier/name/main/QDistSAT/PR change.
