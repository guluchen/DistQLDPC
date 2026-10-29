# Repeated-cyclic CSS hyperbicycle inputs (GH-205)

Kovalev and Pryadko, Phys. Rev. A88,012311(2013),
[arXiv1212.6703v2](https://arxiv.org/abs/1212.6703v2), Eq19/Theorem9/Examples5–6.
This is a multi-block lifted-product specialization, not a disjoint-family
count. Only chi=1 and even c are implemented. Source G_X/G_Z are stabilizers;
repository Gx/Gz are complete logical quotient bases, respectively Z/X type.

The first row of the ordinary c*n_i circulant has support h_i. Its contiguous
n_i-square top-row blocks give a_j and b_j. Stabilizer rows and each physical
sector use the tuple (b,s,a), with s in Z_c. Eq19 uses +j in Hx and -j with
transposed local blocks in Hz. Swapping tensor coordinates or dropping these
transposes changes the prescription. Independently enumerated original cyclic
incidences reconstruct every physical matrix entry.

For each ordinary circulant and transpose, the validator computes its whole
kernel with scalar set elimination and enumerates every nonzero word (only
dimension3 or5). Every word repeats over c blocks. It checks the full repeated
symmetry, dimensions, and exclusion of weight-one words from the sum-block
rowspaces and their transposes. These are the finite Theorem9 hypotheses.
That theorem gives K=2*k1*k2 and 2*d/c <= D <= d for minimum ordinary factor
distance d. A source-construction bound is kept separate from observed solver
bounds. New finite exact/lower claims remain PLAUSIBLE until independently
cross-checked; a logical word alone proves an upper bound.

| Fixed case | c | Physical N | K | Construction interval | Initial actual Gx/Gz word weights |
|---|---:|---:|---:|---|---|
| source900 | 2 | 900 | 50 | 14..14; published Example6 exact14 | 14/14 |
| original1800 | 4 | 1800 | 50 | 14..28 | 28/14 |
| original2700 | 6 | 2700 | 50 | 14..42 | 42/14 |
| original420 | 2 | 420 | 30 | 8..8; theorem application, not a named source case | 8/11 |
| original840 | 4 | 840 | 30 | 8..16 | 16/11 |
| original1260 | 6 | 1260 | 30 | 8..24 | 24/11 |

These are actual basis words, not claimed half minima. Parameters were fixed
in issue205 before generation and remain unchanged after easy outcomes.
Same-(n,k) peers are absent from40 pinned main/library refs. Full canonical
stabilizer support components are connected; no disconnected repetition copies
are counted as additional coverage. Arbitrary asymptotic distance growth,
decoding performance and physical equivalence to unreviewed codes are not claimed.

```
python3 scripts/codegen/hyperbicycle.py --all --out /tmp/hyperbicycle-new
python3 scripts/codegen/validate_hyperbicycle.py --dir /tmp/hyperbicycle-new --out /tmp/hyperbicycle-audit.json
python3 tests/test_codegen_hyperbicycle.py
```

The generator refuses overwrites and checks actual dimensions/commutation
before creating any file. Logical construction uses the repository's bitset
method. The independent auditor imports neither constructor nor logical
builder. The generic smoke helper's new `range lo hi` reference check rejects
contradictions but never inserts endpoints into missing or weaker raw results.
Its default HGP selection, scientific solver and solver defaults are unchanged.

The paper's arXiv perpetual distribution license is not reused as a software
or matrix license. Original scripts and generated matrices are GPL3+;
no author implementation/matrix or paper text/images are redistributed.
All cases are untiered on a work branch. Linux run40961747658 passes53units,
all24byte reproductions and all12numeric smokes. N420/840/1260 both-engine
global distances8/11/11 have GF2 minimum words. N900/1800/2700 CC14 and MaxSAT
[9,14] retain provisional new search results and3unexecuted MaxSAT jobs;
published source900exact14 remains a known control. A general tiny-alias XOR
regression subsequently raises unit coverage to54 without changing frozen
matrices or construction evidence. Full report and server package live in
optimization/experiments/GH-205/. GH200/GH202 stay held.
