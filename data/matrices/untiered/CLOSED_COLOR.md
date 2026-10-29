# Closed higher-genus4.8.10 STATIC color CSS inputs (GH-184)

## Sources, ownership and scientific scope

H. Bombin and M.A. Martin-Delgado, *Topological Quantum Distillation*,
Phys.Rev.Lett.97,180501(2006), DOI10.1103/PhysRevLett.97.180501,
[quant-ph/0605138v3](https://arxiv.org/abs/quant-ph/0605138v3), Eqs1–3:
static face-X/face-Z color CSS. Paper arXiv assumed/nonexclusive distribution
is not software/matrix permission; no original text, images, matrices or
implementation are copied/redistributed. Original scripts/matrices GPL3+.

O. Higgott and N.P. Breuckmann, *Constructions and Performance of Hyperbolic
and Semi-Hyperbolic Floquet Codes*, PRX Quantum5,040327(2024),
DOI10.1103/PRXQuantum.5.040327,
[2308.03750v2](https://arxiv.org/abs/2308.03750v2), SecII.1–II.3,
provides reflection-group/Wythoff tiling mathematics. Published article
CC BY4.0, https://creativecommons.org/licenses/by/4.0/ ; arXiv nonexclusive.
Attribution here covers mathematical reconstruction; no paper prose/images
or author software/data redistributed. The STATIC CSS code uses both face
Paulis, k=4g. Source Floquet k=2g, embedded/circuit distances, circuit models
and decoding estimates are NOT static CSS claims and are never imported.

N.P. Breuckmann and B.M. Terhal, *Constructions and Noise Threshold of
Hyperbolic Surface Codes*, IEEE Trans.Inf.Theory62,3731–3744(2016),
DOI10.1109/TIT.2016.2555700,
[1506.04029v2](https://arxiv.org/abs/1506.04029v2), TableI rows1–3,
supplies finite oriented quotient parameters. Own bounded enumerator reused
from GH165; no third-party group or distance software. The GH165 n1920
orientation ambiguity stays held for PI and is not used or resolved here.

These original finite static specializations/covers have no asserted published
individual exact d. Prefix COLOR retains provenance/topology, not an extra
disjoint family count. Covers are fixed before any solver run; no distance,
word-weight or solve-time screening/resampling. A single primitive cyclic
cover does NOT guarantee growing distance: the fixed q2/5/10 cases already
have actual supplied-basis upper8, retained as finite controls, not advertised
as a growing-distance family. All distances/stems/tiering await their actual
scientific gates and PI decisions; no QDistSAT mirror/main integration.

| source edge parameter | q | n | genus | static k | rank per half | actual initial basis upper |
|---:|---:|---:|---:|---:|---:|---:|
|60|1|240|4|16|112|8|
|60|2|480|7|28|226|8|
|160|1|640|9|36|302|12|
|60|5|1200|16|64|568|8|
|360|1|1440|19|76|682|16|
|60|10|2400|31|124|1138|8|

## Finite reflection and Wythoff construction

The oriented presentation has r^5=s^4=(rs)^2=1 and the pinned TableI
normal words and their reflected words. Only the three unaffected source
rows are used. An original bounded relation enumerator produces the finite
right action G of order2E; every inverse and defining relation holds at
every state. A second implementation uses a different traversal order and
checks every commuting LEFT translation/permutation against every right
generator edge, proving regularity rather than merely accepting a transitive
permutation action of a presented group. No assumed external group table.

The source reflection phi sends r->r^-1,s->s^-1. Its actual permutation,
all action intertwining identities and phi^2=1 are verified. Form the
semidirect product G rtimes C2; vertices are(g,epsilon), with reflections
a=(r,1),b=(1,1),c=(s^-1,1). All three actual edge actions are involutions;
(ab),(bc),(ca) have orders5,4,2. Every vertex has three distinct neighbors.
Two-color orbits give faces of length10,8,4; the complementary edge color
labels each face. Parity epsilon pulls back orientation. Source bases have
n=4E=240/640/1440 and genus4/9/19.

The constructor enumerates oriented ribbon darts; the independent verifier
instead reconstructs pair-generator connected components. It verifies every
actual face boundary, distinct vertices/edges, adjacent colors, exactly two
oppositely oriented face uses of each edge, all three incident colors and
an actual circular link at EVERY vertex. Connectedness and negative Euler
characteristic are checked explicitly; no geometry drawing is treated as
proof of a closed orientable manifold.

## Original deterministic integral covers: proof

Fix the edge-ordered primal BFS spanning tree T. Choose the edge-ordered
dual BFS spanning tree S using only edges outside T. There are2g remaining
edges; choose the first e. Its dual edge plus its unique S path is a dual
cycle. Orient dual edges from the face with negative primal boundary sign
to the face with positive sign. The signed cycle defines integer edge
voltages alpha. Every oriented face sum is zero, since the dual cycle has
zero divergence. Alpha vanishes on T and alpha(e)=1.

For fixed q, vertex(v,t), t in Z/q, has label v*q+t. An oriented base edge
u<v lifts from(u,t) to(v,t+alpha_e). Exact face closure gives q simple face
lifts of unchanged length/color; every local vertex/edge/face neighborhood
projects bijectively. The primal fundamental cycle through e and T has
voltage1, which generates Z/q even for composite q. Hence the cover is
connected. Orientability and face colors pull back, Euler characteristic
multiplies by q, and genus becomes q(g-1)+1. This proves topology only,
not a quantum distance formula or an asymptotic growth guarantee.

The independent implementation checks the integer cycle/face sums, disjoint
actual trees, primitive period1, all actual sheet shifts and EVERY local
fiber, plus explicit integer boundary projection and transfer identities
P0*d1=d1*P1, P1*d2=d2*P2, d1*T1=T0*d1, d2*T2=T1*d2. It does not substitute
congruences, graph counts or a single representative neighborhood. Zero
voltage and nonzero/nonprimitive composite covers are rejected in units.

## Static CSS commutation, logicals and actual upper words

Qubits are final cellulation vertices. Hx=Hz=H, with each row the vertices
of one face. Face lengths4/8/10 are even. At a common vertex of two distinct
faces, the verified three-color circular link gives exactly one common edge.
Their common vertices therefore pair into disjoint common edges, so every
two face rows overlap evenly. Thus H*H^T=0 over GF2. This is also checked
entrywise through the independent algebra validator.

All three face-color sums equal the all-ones vertex vector, yielding two
row dependencies per half. Actual rank is F-2, checked without assuming
there are no additional dependencies, and k=n-2(F-2)=4-2chi=4g. Existing
compute_logicals.py supplies both full bases; independent checks prove
kernels, quotient extension ranks, rowspace exclusion and full-rank pairing.
Identity on physical qubits exchanges Hx/Hz and preserves weight, proving
X/Z distance equality only. No nonphysical GL transform is used for weights.

For each half materialize the lightest EXISTING supplied logical-basis row,
not combinations or supports, and independently check its syndrome,
stabilizer nonmembership and logical detector. This yields actual upper
words only; no lower/exact claim follows. All source/case/cellulation and
matrix identities are retained in the construction certificates and audit.

## Reproduction and evidence gates

```
python3 scripts/codegen/closed_color.py --all --out /tmp/closed-color-rebuilt --certificates /tmp/closed-color-certificates
python3 scripts/codegen/validate_closed_color.py --out /tmp/closed-color-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/closed-color-inventory.json
python3 tests/test_codegen_closed_color.py
```

The unique reduced stabilizer basis also has one coordinate component for
every case. This excludes a physical direct sum hidden by mixing check
rows: a direct-sum partition forces each unique reduced-basis row into one
block, and conversely its connected support blocks span independent
subspaces. A four-coordinate mixed-check mutant tests this invariant.

All24 matrix files and6 complete group/cell/voltage certificates must
reproduce byte for byte. Same(n,k) main/pending-library scan and direct/
swapped stabilizer-space checks find no peers. Do not count a suspected
column-permutation equivalent copy. Every printed solver word is independently
GF2-checked. New one-engine exact/stronger lower results remain PLAUSIBLE
until independent completion. Missing numeric stdout fields stay INCOMPLETE,
never filled by a source formula, actual basis upper or another engine.

Mac generation/algebra/tiny units only; selected Linux serial60sCPU/90swall/
4GiB/one pinned allocated runner CPU/default seed. Heavier work is an exact
unexecuted yfclab2 package requiring PI allocation/free-core confirmation.
No solver/default/build/tiered/QDistSAT/final-name/main/gh-pages/PR change.
Actual status and every failure/timeout: GH-184/REPORT.md and raw/.

## Retained Linux outcome

Both engines confirm exact8 at n240/480. CC-only exact12/8/16 at n640/
1200/1440 remain PLAUSIBLE pending independent completion; n2400 CC[2,8]
has an actual basis upper8 and default MaxSAT has no numeric fields
(INCOMPLETE).47local+Linux units, full construction/inventory/actual-word
audit and24matrix+6certificate byte reproduction pass. Five guarded server
jobs are packaged unexecuted. All raw identities/statuses in GH-184/REPORT.md.
