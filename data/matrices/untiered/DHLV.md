# Finite DHLV edge-qubit CSS representatives (GH-186)

Six original finite specializations of the Dinur–Hsieh–Lin–Vidick chain
prescription. Prefix DHLV is proposed for this provenance/construction; it
does not assert mathematical disjointness from all product constructions.
The physical coordinates are binary components on edges, not the squares
used as physical qubits in the previously collected Tanner inputs.

## Source and attribution

I. Dinur, M.-H. Hsieh, T.-C. Lin and T. Vidick,
*Good Quantum LDPC Codes with Linear Time Decoders*,
[arXiv:2206.07750v1](https://arxiv.org/abs/2206.07750v1), 2022,
Sec. 2.4, 2.7, 3.1, Eq. (6) and Lemma 3.1.
The mathematical source is [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
These finite group/local-code choices and implementation are original
specializations, not author-provided matrices or published individual
distance records. Scripts and generated matrices are GPL-3.0-or-later.
No author implementation, matrix file, prose or image copied; no external
group/distance solver run. No claim of author endorsement.

## Frozen inputs and physical conventions

Dihedral group elements are r^u s^v, with rotation order m and group order
2m. The generator uses the defining multiplication; the independent checker
instead composes faithful permutations of the m polygon vertices, checking
all products, identity, inverse closure, distinct generators and connected
Cayley graphs. Both ordered generating sets are fixed, not distance-screened.

The first case has m=3, A=(r,r^-1,s), B=(r,r^-1,rs), local parity matrices
HA=(111), HB=(110;011). The five other cases have m=4/6/8/10/14 and degree7:
A=(r,r^-1,r^(m/2),s,rs,r^2s,r^3s),
B=(r,r^-1,r^(m/2),rs,r^2s,r^3s,r^4s).
HA has ordered binary columns1..7; HB has row supports
(0,1,2), (0,3,4), (1,3,5), (0,1,3,6).
Thus their kernels are the binary Hamming code and its dual. All entries,
dimensions and orders are frozen in dhlv_cases.json. Actual k was computed
by GF(2) rank from these fixed choices before distance observation, not
used to select or reject a case.

Use four copies Vxy of G. A-edges join (g,0,y) to (ag,1,y); B-edges join
(g,x,0) to (gb,x,1). Each square has vertices g,ag,gb,agb in the four
distinct parts. At both endpoints an edge keeps the same generator label;
inverting it at one endpoint would change the local map. The four-part
version does not require the total-nonconjugacy restriction of some
two-part face-qubit Tanner prescriptions. Every edge/face remains identified
by ordered endpoints and part, even when group products coincide.

An A-edge carries mb binary qubits and a B-edge ma qubits, with ma/mb the
row counts of HA/HB. Hx is d1 with one ma-by-mb component at each vertex;
Hz is d2-transpose, one binary row per square. A physical Pauli word's
weight counts each nonzero binary component. Counting occupied geometric
edge blocks instead would give a different quantity and is never used here.

## Written soundness and independent checks

For an A-edge component q, d1 contributes HA[:,a] tensor e_q to each
endpoint. For a B-edge component p it contributes e_p tensor HB[:,b].
The square boundary d2 puts HB[:,b] on its two A-edges and HA[:,a] on its
two B-edges. At every corner, each of the two paths is separately the same
tensor HA[:,a] tensor HB[:,b]; their binary sum vanishes. Nonincident
vertices contribute zero. Therefore d1*d2=0 and Hx*Hz^T=0. This is an
explicit binary-chain statement, not a distance or decoding theorem.

The validator does not import the constructor. It checks every multiplication
through the faithful polygon action, every actual four-part edge and square,
left/right closure, connectedness, regularity, and full stars: each edge
has degree-many squares with all missing-direction labels exactly once.
It identifies actual square edges from endpoint pairs, then reconstructs d2
by edge-to-face stars, separately from the generator's square assembly.
Every actual d1/d2 binary column is compared, and each of the eight separate
tensor paths per square is checked from the retained matrices before
cancellation. Full GF(2) multiplication independently checks the result.

For group size G and degree Delta, n=2G*Delta*(ma+mb), X rows4G*ma*mb and
Z rowsG*Delta^2. Actual ranks give the complete logical dimension; the
simple finite counting lower bound on k is also checked. Full logical
quotient bases, kernel conditions, stabilizer exclusion and nonsingular
pairing are verified independently of the logical builder. Reduced
stabilizer-space support must be connected to exclude physical direct sums
hidden by mixed check rows. All main/published pending-library same-(n,k)
peers are scanned at pinned refs, with no peers found; local direct/swapped
row-space checks and full inventory still run.

| m | Degree | n | k | rank Hx | rank Hz | Actual existing-basis upper |
|---:|---:|---:|---:|---:|---:|---:|
|3|3|108|10|46|52|4|
|4|7|784|40|368|376|8|
|6|7|1176|50|557|569|6|
|8|7|1568|48|752|768|28|
|10|7|1960|58|941|961|10|
|14|7|2744|66|1325|1353|34|

The upper column is an actual independently GF(2)-verified logical-basis
word, never presumed minimum. The checker selects the lightest existing
basis row, without enumerating combinations or searching supports. Cases
with short words are retained without changing generators/local matrices.
No published individual exact distance is asserted for these original
finite inputs; absence is not a claim of a globally unsolved problem.

The paper's asymptotically good distance and linear-time decoder conclusions
need additional spectral/local-distance/robustness hypotheses. Those are
NOT certified for these finite choices. We implement neither a decoder nor
the missing theorem hypotheses, and do not count this batch as completing
the explicit certified-growing-distance expander-factor gap. The family
prescription and actual finite code validity are the coverage supplied here.

## Reproduction and gates

```
python3 scripts/codegen/dhlv.py --all --out data/matrices/untiered --certificates optimization/experiments/GH-186/raw/certificates
python3 scripts/codegen/validate_dhlv.py --out optimization/experiments/GH-186/raw/construction.json
python3 tests/test_codegen_dhlv.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```

The builder refuses existing matrices or certificates. Fresh directories
reproduce all24 matrix files and six complete certificates byte for byte.
Fifteen new units include corrupted group/source symmetry, edge/square/star,
stalk and local-label/actual-column mutants. A valid commuting square-row
basis change still fails the actual source-incidence check. False
stabilizer-as-upper and hidden physical direct-sum mutants are rejected.
Prior34 unit checks retain their original workloads/default selections.

Explicit six-case default MaxSAT/CC Linux60sCPU/90swall/4GiB serial pinned
smokes pass construction and actual-word audits; five numeric gates PASS,
while n2744 default MaxSAT lacks numeric fields (INCOMPLETE). Both engines
exact4/8/6; remaining CC-only exact16/10/14 stay PLAUSIBLE, with three
unexecuted MaxSAT proof/numeric jobs packaged. Actual numeric fields,
source/binary/input identities and raw witnesses will be retained and
checked independently; missing fields stay INCOMPLETE. New one-engine
lower/exact results remain PLAUSIBLE until independently completed. Heavy
work becomes an unexecuted server package. No unknown stem, tiered input,
solver/default, QDistSAT or main/gh-pages change is made here.
