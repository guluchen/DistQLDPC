# Next-source research: APM witness discrepancy held for PI review

No APM family input has been added, no distance search run, no author
software/matrix file read/copied and no outside author contacted. These are
fixed published numeric-word algebra checks while the SC-HGP job ran.
This is a provenance/interpretation hold for the APM candidate, not a claim
that a published overall distance bound is false or a new exact distance.

Kenta Kasai, *Heuristic Search for Minimum-Distance Upper-Bound Witnesses in
Quantum APM-LDPC Codes*, [2604.15307v1](https://arxiv.org/html/2604.15307v1),
Sec3, Table2 C1, Examples7.7/7.8, Table3. Latest arXiv abstract/history checked
2026-10-30: v1 only. CC BY4.0. The corresponding primary PDF pp14/18 repeats
the same numeric data, so this is not only an HTML extraction difference.
Companion primary [2601.08824v4](https://arxiv.org/html/2601.08824v4), Sec3,
explicitly defines F[x,y]=1 iff f(x)=y. Follow-up Lemma5.2 instead writes
M e_t=e_(at+b), so we checked BOTH row/column conventions without choosing
one from its distance result. The source-specific direction must be explicit.

C1 has P216,J3,L12; retain the exact six F/G affine maps from its Table2.
The source matrices have blocks Hx[i,j]=F[j-i], Hx[i,6+j]=G[j-i],
Hz[i,j]=G[i-j]^T, Hz[i,6+j]=F[i-j]^T, indices modulo6, i0..2.
Under the explicit companion ROW convention, direct arithmetic gives ranks
646/646,k1300, commutation, and the published X weight10 support is a valid
kernel/nonstabilizer word. But the published Z weight10 support has22 odd
X-check overlaps. A separate explicit-set implementation gives the same22.
Column convention also commutes and has the same ranks, but both published
supports have nonzero syndromes(28 each); it does not resolve the mismatch.

A one-check counterexample makes the issue reviewable without any solver:
source Z contains(block11,t168). In X block-row0/within-row4, the block11
entry is G5:25*4+68=168 modulo216. No other coordinate of the published
Z support meets that row, giving odd overlap1. The complete22 offending
check coordinates are in raw/next-apm-fixed-Z-separate-set-check.json.
This is under the stated source ordering; a different intended coordinate
mapping might explain it, but must be documented/proved rather than silently
invented. The verified source X word still gives overall upper10 for this
row-convention code, so these checks do NOT refute that overall bound.

Reproduction (original arithmetic, no candidate generation/search):
```
python3 optimization/experiments/GH-188/source_checks/apm_c1_fixed_words.py
python3 optimization/experiments/GH-188/source_checks/apm_c1_set_syndrome.py
```
Both deterministic outputs are retained under raw/next-apm-*.json. Do not
silently replace the Z support, transfer its dZ claim or implement/adopt an
APM batch on an inferred convention before PI interpretation. AGENTS.md
scientific-boundary/escalation rules and the handoff govern this hold.
Other unambiguous library work can continue; this unresolved source item
remains visible in the coverage ledger. No outside communication.

## Additional genuine coverage gap found

Christophe Vuillot and Nikolas P. Breuckmann, *Quantum Pin Codes*,
[1906.11394v3](https://arxiv.org/html/1906.11394v3), IEEE TIT68,5955–5974(2022),
DOI10.1109/TIT.2022.3170846. This static CSS pin-relation prescription
strictly generalizes color-code/Reed-Muller examples; existing color inputs
do not implement arbitrary pin relations. Definitions1–3/Prop3 and chain
complex SecII-F3/V-B provide a mathematics-only route. Prop11 supplies a
lower bound after all relation hypotheses are verified, not for arbitrary
flags. TableVI complete-relation examples have matching known bounds and
are useful anchors, not unknown-distance headlines; chain-complex examples
are only upper-estimated in the source scatter plot. Practical finite
parameters, full relation checks, k/logical/source/duplicate audits and
original independent generators are still needed. Paper perpetual license:
copy no source files/prose/software, rebuild mathematics with attribution.
No instance selected/frozen or counted yet.
