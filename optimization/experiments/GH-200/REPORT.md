# GH-200: coupled MM source-dimension discrepancy

Status: SOURCE_DIMENSION_HOLD; no accepted inputs or distance runs.
Issue200; hub6507829900. Branch codex/multivariate-multicycle-library from
main6083e662c621f3b66defd434cfae31a028d483c4. Previous goal turn PROGRESS:
GH1992adb6925 preserved all five cross-checked exact9/12/14/17/20, no heavy
jobs; finalCI40950402557 SUCCESS. Goal remains ACTIVE; this source-dependent
candidate batch requires PI review. No post-result case replacement.

## Frozen proposal and source

CHOSEN coupled four-variable t4 MM finite source-estimate ladder. DEFERRED
collapsed t5+ needs asymmetric degree/half review; DEFERRED non-Cayley
Schreier finite local views have exact-labelled controls, lower unknown-
distance priority. MM identifies finite provenance, not a disjoint family
from AMC/TOR4D/QHP/TT. No asymptotic finite-rate claim; issue title clarified
to higher-rate FINITE samples. Fresh104open issue/PR records and179branches
checked before claim; only completedGH199 overlap, no competing topic.

Mian-Gwilliam-Krastanov2601.18879v2, latest version confirmed against arXiv
submission history24May2026; PDFp10/11Eq85-86/94-102,p33TableIII,p35TableV
rendered and visually checked. Primary SHA256
0842d73c27734fc2dca5082f3499e9c78d544364fcc9d2c337ecb388e3ef195d.
https://arxiv.org/abs/2601.18879v2
https://arxiv.org/html/2601.18879v2
Perpetual-license paper; original GPL3+ math reconstruction only, no author
code/matrix or paper text/image copied; no external distance tools used.
No outside communication. Source tables retain exact-vs-randomized-method
labels; TableIII1000information-set numbers are estimates, not exhaustive
lower proofs. Source972paired27/26 retained separately; no exact mismatch
inferred from unequal randomized estimates.

Fixed in issue BEFORE generation:144k6dims3/2/2/2,TableV exact12 control;
324k12dims2/3/3/3,estimate20/20;432k12dims2/3/3/4,estimate27/27;
648k18dims3/9/2/2,estimate23/23;972k24dims3/3/3/6,estimate27/26.
Full unmodified F/G/H/I literals in scripts/codegen/mm_cases.json/issue200.
Preliminary38pinned-ref inventory review found no CLAIMED(n,k)peer, but
actual badcase648k12 would require renewed peer/equivalence review. No
completed duplicate gate is claimed for this failed batch.

## Observed discrepancy and independent checks

Generic subset-boundary constructor uses lexicographic pairs/triples,
positive first-column quotient-ring shifts, z-fastest group coordinates.
Source literal Px=partial2T, Pz=partial3 blocks fix physical basis. Initial
GF2/full logical tests yield actual ranks69/69,156/156,210/210,318/318,
474/474, hence actualk6/12/12/12/24. First assertion of equality with source
k failed at648; actual/full logical receipt raw/initial-gf2.json explicitly
marks source dimension FAIL there. No distance search or higher gate followed.

Primary PDFp33 and independent HTML agree on dims3/9/2/2 and all12monomials
for648. They match the frozen strings. Independent numeric supports in
raw/check_source648.py avoid the generator/parser/logical-builder imports.
It constructs all four dense lift matrices via direct coordinate differences,
then literal source4x6blocks with ACTUAL transposed coefficient matrices for
Hx. Its648Hx/Hz agree entrywise with every generated bit. Dense left-pivot
bytearray Gaussian elimination (separate from generic high-pivot bitset
elimination and the unchanged logical builder) gives318/318. Separate scalar
parity multiplication confirms HxHzT=0. Both computed logical bases contain
12rows and full quotient/pairing checks pass. Thus648-318-318=12, versus
source18. Full source/literal/dense/input identities raw/source648-independent.json.

This is a reproducible SOURCE DIMENSION DISCREPANCY, not a proof that a
paper theorem is false or identification of the intended source code. It
cannot be resolved by merely X/Z swapping or a simultaneous regular-
representation inversion/permutation, which preserve ranks. No ad hoc
polynomial edits, dimension reassignment, renamedk12code or borrowed distance23.
The published648claim is also in the latest abstract, so not a silent table-
only repair. PI source interpretation required before adoption/continuing
this frozen scientific batch; external author contact belongs to PI.

## Retention, guards and validation

All20initial candidate PCM files preserved under
 data/matrices/untiered/quarantine/GH-200/, with a prominent hold README.
Filenames record frozen SOURCE claims, not accepted parameters; none is
in MANIFEST.csv or flat untiered/tier test inventory. Entire batch held,
including other four dimension-consistent candidates; no easy replacement
or missing-case concealment. Original generation log retained. New generator
rank-derived-k guard refuses648 before writing; default path quarantine.
Independent diagnostic --emit-quarantine rebuilds all four648files byte-
identically to a NEW explicit directory using literal matrices and in-repo
logical builder. This is GF2 algebra, not a distance search.

10hold units PASS: frozen source row, independent every-entry comparison,
all five complete GF2/logical dimensions, recorded independent dense ranks,
pre-write k refusal/CLI and changed-k mutant, GF2 polynomial reduction/invalid
syntax,30tiny random commutation cases, corrupted matrix mutant, invalid
complex inputs. These checks establish the observed hold; they do NOT pass
full adoption/duplicate/Linux/distance/source-word gates. Existing300matrix
files and entire prior24row manifest are byte-identical; src/Makefile unchanged.
No server jobs or allocation, Actions scientific workload, parameter sweep,
paid cloud substitution or outside author communication.

```
python3 scripts/codegen/mm.py --all  # initial pre-guard generation, retained log
python3 optimization/experiments/GH-200/raw/check_source648.py
python3 optimization/experiments/GH-200/raw/check_source648.py --emit-quarantine /tmp/gh200-source648-new
python3 tests/test_codegen_mm_hold.py
python3 scripts/codegen/mm.py --n 648 --out /tmp/new  # expected SOURCE_DIMENSION_HOLD, writes nothing
```

## Completion fields

What changed: frozen five-case MM source proposal and original constructor;
independent source648literal/dense discrepancy reproduction,10guard tests,
quarantined raw candidate files and evidence. Accepted library additions:0.
Validation performed: full initialGF2/logicals; PDF/HTML/latest-source review;
independent literal/dense/scalar648checks;10units/30tiny random cases;
four648matrix byte reproduction; existingdata/solver preservation.
Results:source648k18 does not reproduce (actualk12/ranks318both). No distance
result or inherited23claim. No correctness mismatch hidden by reselection.
Unresolved: PI source interpretation; this batch's full duplicate/byte/Linux/
actual-word gates remain incomplete; prior global family/integration holds.
Scientific semantics changed:no.
PI action required:yes for source discrepancy handling; no author contact
or changes to parameters/stems/source claims will be made autonomously.
