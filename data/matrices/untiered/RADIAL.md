# Finite quantum radial lifted products (GH-193)

Four fixed radial LP inputs cover n352/928/1504/2528 with actual k18.
The first reconstructs the published AppendixD2 instance; the other three
reuse its integer exponent pair at primes29/47/79 and are original finite
modulus cases. They inherit no published individual distance20, distance-
growth, confinement, memory or single-shot performance conclusion. All
fixed cases remain even if easy/poor; no screening or replacement.

Source: Thomas R. Scruby, Timo Hillmann, Joschka Roffe,
*High-threshold, low-overhead and single-shot decodable fault-tolerant
quantum memory*, [2406.14445v2](https://arxiv.org/abs/2406.14445v2), latest
20Apr2026, PRX Quantum7,020310,
[DOI10.1103/67xf-zdjb](https://doi.org/10.1103/67xf-zdjb). Eq8/SecII/AppC/D.
PDFp16 D1/D2 visually checked; HTML labels26/27 describe the same pairs.
Paper perpetual license is not imputed to author files; original mathematics-
only scripts/matrices GPL3+, NOTICE attribution. No author code/matrix
files/prose/images copied, no external distance software executed.

All four use r4 and the fixed exponent matrices
```
A1=[[10,10,1,6],[4,7,5,2],[8,10,6,9],[1,6,0,6]]
A2=[[9,5,8,3],[5,4,1,0],[0,4,6,10],[2,8,4,2]]
```
| s | n | k | classical binary ranks (each) | quantum ranks Hx,Hz | initial actual upper | source claim |
|---:|---:|---:|---:|---|---:|---|
|11|352|18|41|167,167|22|numerical word-search estimate20, not exact certification|
|29|928|18|113|455,455|58|general ring bound58; no published individual d|
|47|1504|18|185|743,743|94|general ring bound94; no published individual d|
|79|2528|18|313|1255,1255|158|general ring bound158; no published individual d|

Source circulants shift identity rows RIGHT: row v meets column v+a.
Hx=[H1 tensor I | I tensor H2], Hz=[I tensor H2* | H1* tensor I], with
conjugate transpose negating shifts and transposing base indices. Physical
columns: two halves, base pair(i,j), cyclic spoke v. Original row constructor
versus independent actual-column incident roots and separate spoke-major
Kronecker instantiation/pullback agree. Full actual GF2 commutation, both
logical quotient bases/pairing, row/column degrees8/4, physical typed
stabilizer RREF connectivity and spoke translation automorphism pass.
No arbitrary XZ metric map or equal half distance is presumed.

Sourcev2 SecII explicitly qualifies the expected classical dependencies as
high-probability and checks actual binary ranks. We check prime/r<=s,
all four-cycle differences, exponent rank over F_s AND actual binary rank,
then actual quantum k. These are verified finite facts, not a strengthened
source theorem. A tiny full-exponent-rank/no-four-cycle extra-dependency
fixture in the tests catches removal of the actual-rank gate.

For odd s, independent physical X/Z ring-pair words have weight2s and odd
mutual overlap. Each commutes with its relevant checks; their odd pairing
proves both nontrivial. Actual kernels, stabilizer quotients and bundled
logical detectors are checked in GF2. Written library-only upper proof in
MODIFICATIONS.md; no engine bound/pruning added. Source estimated20 for
n352 requires a separate actual<=20 word; initial22 does not reproduce it.

The published AppendixD1 n90k8 is comparison-only: an existing tier0
BB_90_8_10 peer has the same n,k. Full source algebra/logicals/words pass,
but direct/swapped rowspaces and288 fixed coordinate maps do not resolve
arbitrary column equivalence. No inequivalence claim and no second benchmark
copy. Comparison script/receipt retains this open item; it was not discarded
after distance testing. The four added cases have no same(n,k) peer across
32pinned refs; generic duplicate checks also run. Branch28untiered/79total,
prior24manifest rows/300matrix files unchanged.

Reproduce in fresh directories (overwrite refused):
```
python3 scripts/codegen/radial.py --all --out /absolute/new/matrices
python3 scripts/codegen/validate_radial.py --out /absolute/new/construction.json
python3 scripts/codegen/review_radial_peer.py --out /absolute/new/peer90.json
python3 tests/test_codegen_radial.py
python3 scripts/codegen/validate_css.py --output /absolute/new/validation.json
```
17new+34prior tests pass, including25tiny randomized coordinate/commutation/
upper-word checks, source/transpose/commuting-wrong-matrix/logical/entry/
rank/girth/parameter/audit mutants,16matrix byte reproduction/overwrite/
HGP12/LP4 selections and peer90 CLI exclusion. Mac algebra/generation/tiny
checks only, no solver or support-distance search. Linux40931932802/
job123652333577 passes51units/full source/pullback/peer90/inventory compare,
16matrix byte reproduction and8one-time serial60sCPU/90swall/4GiB/defaultseed/
pinned allocated CPU attempts. Actual upper words20/26/26/26 independently
GF2-verified; source352 estimate20 word PASS. MaxSAT raw[9,20]/[9,26]/
[9,26]/no numeric fields; CC[19,20]/[22,58]/[22,26]/[22,26]. Strongest CC
lower19/22 PLAUSIBLE pending independent proof. Largest MaxSAT numeric
INCOMPLETE; do not fill from CC. Original cases' common actual upper26 is
not growing-distance evidence. Full607114-character job log/22engine files/
audit retained; local replay byte-identical. Four default MaxSAT proof/
numeric jobs plus a separately selected optional four-CC completion queue
are frozen unexecuted. No allocated core/run.
Raw missing numbers stay INCOMPLETE; source words and scientific proofs
have separate gates. New exact/lower results PLAUSIBLE until independent
implementation/search plus actual GF2 words. Heavy work freezes unexecuted
yfclab2 jobs requiring explicit PI allocation. No solver/default/tier/name/
main/QDistSAT/PR changes.
