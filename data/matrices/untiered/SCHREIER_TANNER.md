# Generalized Schreier Tanner finite prescriptions (GH-202)

Original mathematical reconstruction of Mostad-Rosnes-Lin, IEEEJSAIT6,
367-382(2025), DOI10.1109/JSAIT.2025.3594310, Def10/SecV/TableI/AppB.
Primary accepted manuscript:
https://hsuanyin-lin.com/docs/papers/OAMostad-ERosnes-HYLin_25JSAIT.pdf
No author code/matrix/paper text/image redistributed. Original GPL3+ scripts
and generated matrices; no external distance solver. TN retains the existing
Tanner prefix; this is finite-prescription coverage, not a disjoint-family count.

| stem | base | local degree | ranks Hx/Hz | source global distance | initial actual X/Z word uppers |
|---|---|---|---|---|---|
|TN_180_26_unknown|p5,2+2|3|77/77|exact6|6/6|
|TN_500_42_unknown|p5,2+2|5|230/228|exact6|10/10|
|TN_686_28_unknown|p7,2+1|7|328/330|exact14|52/14|
|TN_1100_66_unknown|p11,2+2|5|518/516|unknown original|14/10|
|TN_1900_98_unknown|p19,2+2|5|902/900|unknown original|14/10|
|TN_2900_138_unknown|p29,2+2|5|1382/1380|unknown original|14/10|

All source/original parameters and local label order frozen in issue202
before generation. Larger cases extend the explicit p5template with three
fixed primes; k comes from actual ranks/full logical row counts. Source
exact distances are not inherited by originals. No claim of global openness,
novelty, asymptotic growth/expansion, threshold, decoder or gate guarantees.
Retain easy/poor outcomes, no result-based replacement.

Group coordinates are ordered by A-layer,B-layer,group element; B-layer
omitted in2+1. Internal labels precede cross labels; lists retain the source
displayed inverse-pair order. Within-layer labels use the first/third sets
positionally. Cross e acts by+e from layer0 and-e from layer1 (self-inverse,
matching off-diagonal transpose). Quadripartite cover qubits(u,a,b) have four
labelled corners. Opposite labels come from actual inverse arcs. SourceH0
is stored Hx, H1 asHz; complete logicals use unchanged compute_logicals.py
--method bitset. Tensor row bases can differ from the paper decoder basis;
the physical stabilizer rowspaces are checked, no performance comparison.

Independent inverse-neighbor/literal graph/local-code enumeration reconstructs
all four corner pullbacks and every shared tensor strip. All actual GF2,
rank-derived dimensions/complete logical quotients/pairing pass. Canonical
actual stabilizer support spaces are connected. No XZ metric map assumed;
actual half ranks differ on five cases. The180A-factor is exactly the usual
Petersen graph, which provides the source non-Cayley anchor; no claim that
every unlabelled graph in the original ladder is non-Cayley.

39pinned-ref review finds one same(n,k)peer: GB180k26 fromGH196. Actual
rowspace pairs differ, including XZ swap. TN has a materialized verified
logical word6, while retained independent MaxSAT+CC/GF2 evidence proves
GB distance7, certifying physical inequivalence under arbitrary qubit
permutation/global XZ swap. This does not itself prove TN lower6.

16new+34prior units PASS;30tiny random labelled-graph algebra cases and
entry/logical/k/invalid inverse/support/source-exact/unknown-field/missing
numeric/no-minimum/invalid-word/cross-bound mutants.24matrix byte regeneration
and overwrite refusal/default HGP12/TN6 dry selection PASS.30untiered/81total
inventory; prior24manifest rows/300matrices/src/Makefile unchanged. Linux
short runs/actual source6/6/14 minimum-word reproduction pending. No Mac
quantum-distance experiments. Missing gates become unexecuted server packages.
GH200 remains independently on source hold; no decision or parameter changed.
