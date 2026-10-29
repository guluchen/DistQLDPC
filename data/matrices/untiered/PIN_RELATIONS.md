# General static pin-relation CSS inputs (GH-189)

Six fixed inputs add the general even-pin relation prescription. Existing
color/colex examples are special cases and are already represented; these
new chain relations have non-thin fibers of size>2, so the finite relation
is not a closed-manifold flag triangulation. This is construction/provenance
coverage, not a count of disjoint mathematical families or proof that every
pin code is inequivalent to every color presentation. No same(n,k) peer was
found across28 pinned main/library refs; different invariants exclude those
existing inputs from equivalence. Full row-space/XZ-swap checks still run.

## Source and clean-room boundary

Christophe Vuillot and Nikolas P. Breuckmann, *Quantum Pin Codes*,
[1906.11394v3](https://arxiv.org/abs/1906.11394v3), IEEE TIT68(9),5955–5974
(2022), [DOI10.1109/TIT.2022.3170846](https://doi.org/10.1109/TIT.2022.3170846),
Definitions1–4/Propositions3/11, SecII-F3 Eqs21–23, V-B Eqs59–60/TableVI.
Latest version checked2026-10-30. Paper perpetual/nonexclusive license is
not imputed to software/data. Reconstruct published mathematics only;
no author code/matrix files, paper prose/images or external algebra/distance
program used. Full NOTICE citation; original scripts/new matrices GPL3+.

The complete Cartesian anchor has levels[2,2,2,2,2,2,4],(x,z)=(2,4),
source [[256,30,8]]. The five original chain cases are not identified with
unparameterized points in the source Fig8 scatter. They inherit no
individually published exact distance, decoder/gate/asymptotic guarantee.
No gauge generators are substituted for these static CSS stabilizers.

## Frozen factors and independent reconstruction

```
J2 = [[1,1],[1,1]]
C3 = [[1,0,1],[1,1,0],[0,1,1]]
H8A = [[1,1,0,0],[0,0,1,1],[1,1,1,1]]
H8B = [[1,1,1,0],[1,0,0,1],[0,1,1,1]]
H9 = [[1,1,1,0],[1,1,0,1],[1,0,1,1]]
```
These factors, tensor order and pin types were frozen in issue189 before
rank/logical/distance observations. Actual k computed afterward without
replacement. All six have k>0 and passed typed physical connectivity;
no duplicate/zero-logical candidate was silently replaced.

Each factor is a length2 complex with low basis=row labels, high basis=
column labels, boundary given by its binary matrix. Tensor basis label
(mask,tuple) uses factor i as bit i, sorted by mask then lexicographic tuple
within each grade. Boundary flips one high factor to a low one along a
nonzero factor entry, XOR overGF2. Thus the two orders of any pair of flips
cancel and successive boundaries compose to zero. The independent checker
instead appends factors recursively using Eq59–60 and verifies every actual
boundary column and each original/completed boundary product.

Endpoint completion follows Eq23: add one bottom pin linked to odd columns
of the first boundary if needed; add one top pin whose boundary is the XOR
of original last-boundary columns if needed. H8B-square needs a top pin;
H9-square needs both. No arbitrary pin is designated free and no gauge
interpretation is used. The remaining three chains need neither endpoint.

Qubits are complete unique flags (one pin per level along a full boundary
path), not chain cells. Constructor descends the completed boundary maps;
checker independently chooses one edge of each factor and every permutation
of factor flips, reconstructs all original flags, then completes odd missing-
endpoint fibers directly on those tuples. Both complete flag sets agree.
All D-pin projection fibers are even; multiplicity histograms retained.
Hx is ALL nonempty x-pin sets, Hz ALL nonempty z-pin sets, type sorted
lexicographically then pin tuple. Checker intersects independent single-pin
incidence masks and checks every physical column and label. All full GF2
ranks/commutation/logical quotients/pairing and typed physical RREF pass.

| case | n | k | rank Hx | rank Hz | x,z | initial actual upper X,Z |
|---|---:|---:|---:|---:|---|---|
|H8B square|160|64|48|48|1,1|4,4|
|H9 square|240|142|49|49|1,1|4,4|
|TableVI complete|256|30|43|183|2,4|32,8|
|J2,C3,H8A|1152|60|165|927|1,2|16,4|
|C3,C3,H8A|1728|84|249|1395|1,2|16,4|
|C3,H8A,H8A|2304|207|291|1806|1,2|16,4|

Those are actual supplied logical-basis words verified overGF2, not assumed
minima. A separate explicit Cartesian weight8 Z word for the anchor varies
pins0/1 on levels0,1,6 and fixes the other levels to0; it also passes kernel,
quotient and detector checks. It is not the entire four-valued level6 fiber.

## Independent finite lower certificates

The written support-isolation proof is in MODIFICATIONS.md. For a complete
t-pin check matrix on DISTINCT flags, every nonzero kernel word has weight
at least2^(t+1): successively choose a smallest nonempty split class to isolate
one support point within t pins, and pad to exactly t pins. A hypothetical
smaller word would have odd overlap with that actual check. All completeness/
uniqueness hypotheses are checked against physical input columns, not merely
against abstract relations. Hence dX>=2^(z+1), dZ>=2^(x+1).

This gives overall lower4 for all five original cases and8 for the anchor.
The actual words meet these bounds already. These are useful finite small-
distance controls, not evidence of distance growth or a set of difficult
remaining open problems. Original individual source values were absent,
not globally proven open. Retain these easy/poor outcomes without reselection;
internal Linux engines will independently cross-check before final reporting.
Never substitute this certificate into missing raw CLI numeric fields.

## Reproduction and gates

```
python3 scripts/codegen/pin_relations.py --all --out data/matrices/untiered --certificates optimization/experiments/GH-189/raw/certificates
python3 scripts/codegen/validate_pin_relations.py --out optimization/experiments/GH-189/raw/construction.json
python3 tests/test_codegen_pin_relations.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```
Existing files/certificates are not overwritten.16new tiny units+34prior pass;
new mutants cover odd/repeated flags, absent endpoint, altered boundary,
missing pinned class, commuting wrong row basis, identity/logicals and false
stabilizer words; tiny predetermined support-isolation certificates and
20random recursive/path examples test the proof hypotheses. No Mac solver
or scientific support/distance search. Original HGP default12 and triangular
COLOR6 CLI workloads preserved; PIN explicit selector only.

Full24matrix+6complete-certificate byte reproduction and serial six-case
MaxSAT/CC Linux60sCPU/90swall/4GiB/defaultseed/pinned allocated CPU checks
are pending,14min cap. Retain raw/source/binary/input identities and actual
words. All numeric missing fields remain INCOMPLETE; finite certificate and
engine results distinguished. Heavy completion becomes unexecuted yfclab2
packages requiring PI allocation, never long Actions/Mac or paid cloud work.
No solver/default/name/tier/main/gh-pages/QDistSAT change or PR. APM source
hold, other pending jobs and remaining mainstream gaps remain separate.
