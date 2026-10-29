# Periodic spatially coupled CSS / SC-HGP inputs (GH-188)

Five fixed tail-biting2D-SC-HGP inputs use the published3x7 partition
matrices in Yang–Calderbank Eq89, memory(3,3), and square periods2/4/5/7/10.
Proposed prefix SC records provenance. These are quasi-abelian lifted
products, not a mathematically disjoint family or ordinary full binary HGP.
The period10 input is the actual Table2 Code7 n5800 source instance;
period2/4/5/7 are original finite specializations. Their individual distances,
cycle counts and decoder properties are not inherited from the source table.

## Source, selection and attribution

Siyi Yang and Robert Calderbank, *Spatially-Coupled QLDPC Codes*,
[arXiv2305.00137v6](https://arxiv.org/abs/2305.00137v6), Quantum9,1693(2025),
[DOI10.22331/q-2025-04-07-1693](https://doi.org/10.22331/q-2025-04-07-1693),
Eq58, Sec6.1 footnote2, Table2 Code7 and AppendixB Eq89.
Mathematical source [CC BY4.0](https://creativecommons.org/licenses/by/4.0/);
full attribution in NOTICE. Original mathematical reconstruction only;
no author software, matrix files, distance tools, paper prose or images copied.
Our original scripts/generated matrices GPL-3.0-or-later. No endorsement.

Frozen numerical A partition:
```
4 10 3 12 13 1 5
7 8 8 11 7 11 3
1 6 12 3 2 0 15
```
B:
```
4 11 13 12 7 3 12
3 13 15 10 6 1 0
4 1 5 7 14 15 3
```
Source footnote2 encodes each entry d by(u,v)=(floor(d/4),d mod4).
These coordinates are elements of C_L x C_L, never a cyclic16 lift.
All supports and periods were fixed before rank/logical/distance evaluation;
actual k added after ranks without resampling. Period2 aliases distinct
integer offsets modulo2; retain that easy control, never select on distance.
The n5800 example deliberately exceeds the approximate100–3000 size ladder
to retain an actual published case whose distance is only upper-estimated.
Source dimension is at least1600, not asserted exactly1600; actual k1624.

## Source Eq58 and soundness on physical binary coordinates

A and B are3x7 monomial matrices over the periodic two-variable group ring.
For monomial offset a=(u,v), write bar(a)=m-a with m=(3,3).
Use Hx=[I_7 tensor A | bar(B)^T tensor I_3],
Hz=[B tensor I_7 | I_3 tensor bar(A)^T], with the explicit variable ordering
below. Every group-ring entry is expanded into its regular translation
permutation on the LxL replicas; this is a lifted product, not a binary
Kronecker product of fully expanded A and B.

Physical columns: VV(j1,j2,t) followed by CC(i1,i2,t), each t=uL+v.
X rows(i1,j2,t) contain VV(j1,j2,t+a_i1j1) and
CC(i1,i2,t+m-b_i2j2). Z rows(j1,i2,s) contain VV(j1,j2,s+b_i2j2)
and CC(i1,i2,s+m-a_i1j1). A given X/Z row pair has the same replica
coincidence condition through VV and CC: s-t=a-b=(m-b)-(m-a).
These two contributions cancel over GF2 for every A/B pair and replica,
including aliased small periods. Thus Hx Hz^T=0. No distance statement
follows from that identity or from small memory/decoder performance.

Rows have weight10. Each VV physical column has degree3 in each half;
each CC column has degree7. There are58L^2 qubits and21L^2 rows per half.
Source tensor orders are X(j2,i1), Z(i2,j1), VV(j2,j1), CC(i2,i1);
explicit pair-coordinate swaps map them to retained orders. A second
independent Eq58 polynomial Kronecker expansion checks this bijection.
The independent checker reconstructs every physical column backwards from
its incident checks and independently transcribed source facts, rather than
importing the forward constructor. It verifies both source complements,
coordinate predecessors and every paired displacement, complete GF2 ranks,
both full logical quotients/pairing and actual logical upper words. Physical
product checks use full typed stabilizer RREF in2n coordinates before
merging Xq/Zq support, preserving Pauli types. No hidden physical partition
was found. Main/all pinned library same(n,k) scans found no peers; ordinary
direct/swapped row-space duplicate checks still run in the full inventory.
No arbitrary column-permutation equivalence theorem is claimed.

| L | n | actual k | rank per half | initial actual basis upper X,Z |
|---:|---:|---:|---:|---|
|2|232|88|72|4,2|
|4|928|280|324|12,4|
|5|1450|424|513|10,10|
|7|2842|808|1017|14,14|
|10|5800|1624|2088|70,20|

Actual basis words are independently syndrome/quotient/detector verified;
they are not minima. Source Table2 Code7 lists distance<=16 and thanks a
contributor for estimations. Record it as a published upper estimate until
an actual <=16 physical word is materialized and checked. Initial basis20
alone does not reproduce that source upper; the later Linux CC word16
now does, after independent GF2 verification. No individual exact d is
published for the smaller original specializations in this source; absence
of a value does not establish a globally open problem. Retain all easy/poor
results without reselection, including the period2 upper2 control.

## Reproduction and gates

```
python3 scripts/codegen/spatially_coupled.py --all --out data/matrices/untiered --certificates optimization/experiments/GH-188/raw/certificates
python3 scripts/codegen/validate_spatially_coupled.py --out optimization/experiments/GH-188/raw/construction.json
python3 tests/test_codegen_spatially_coupled.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```
Fresh directories reproduce all20matrix+5complete-certificate bytes;
existing files are never overwritten.13new tiny units include twenty
fixed-seed random finite column/cancellation checks, source/parameter/
logical/complement/wrong-commuting-basis/stabilizer-word/Pauli-type mutants,
noncyclic deck action, byte reproduction and CLI default/selection guards.
Prior34units retain original workloads, including HGP default12 and the
original triangular COLOR6 selection. No solver or support-distance search
on the Mac; generation and algebra only. Linux source
615470fa26f6be950a4738a6244a33640da2c04b, library run40915696103/job123595188679
SUCCESS:47units/full construction/inventory comparison and all20matrix+
5complete-certificate byte regeneration. Ordinary source CI40915695967/
job123595188171 SUCCESS. Full raw identities/logs/actual words retained in
GH-188/raw/actions/default; local actual audit replay byte-identical.

| n | MaxSAT60s | CC60s | Scientific / numeric status |
|---:|---|---|---|
|232|2|2|cross-checked exact2; numeric PASS|
|928|4|4|cross-checked exact4; numeric PASS|
|1450|8|8|cross-checked exact8; numeric PASS|
|2842|[6,14]|14|CC-only14 PLAUSIBLE; numeric PASS|
|5800|no numeric fields|16|CC-only16 PLAUSIBLE; numeric INCOMPLETE|

All actual supplied/printed words pass independent GF2. Source n5800 upper16
actual-word gate now PASS, while its MaxSAT numeric gate stays INCOMPLETE.
Two frozen unexecuted MaxSAT proof/numeric jobs reference verified physical
uppers14/16,6hCPU+600swall/4GiB each, serial seed0/verbose/pinned yfclab2,
requiring PI-allocated confirmed-free core. Aggregate12hCPU/12h20mwall are
configured limits, not ETA; no server job run. No stem/tier/solver/default/
main/gh-pages/QDistSAT change or PR. Held next-source APM witness discrepancy
and remaining pin-code construction gap are separate research records;
neither alters these SC inputs or their validated source-instance identity.
