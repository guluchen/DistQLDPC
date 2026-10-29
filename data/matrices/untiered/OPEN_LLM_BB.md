# Open-distance weight-five CSS BB targets (GH-177)

## Source and selection

Juan Cruz-Benito, *Large Language Model-Guided Discovery of Weight-Five
Bivariate Bicycle Codes*, [arXiv:2610.06623v1](https://arxiv.org/abs/2610.06623v1),
CSS construction/support split, CC BY4.0. Numeric catalogue/provenance from
[qiskit-community/qcode-discovery](https://github.com/qiskit-community/qcode-discovery)
commit da9178fd65ffc2eec3dab46089f9879eb02d4b23, Apache2.0. The retained
six-record extract remains under its source Apache2.0 terms; full source
license is in GH-177/raw/SOURCE-APACHE-2.0.txt. Our scripts and generated
matrices are original GPL-3.0-or-later. Changes: original mathematical matrix
reconstruction, physical ordering/logical bases, independent validation,
selection and benchmark packaging. No third-party constructor/decoder/solver
implementation, paper prose or images copied or executed.

The PI requested unknown exact distances after GH-176. All six targets were
nonexact at their source presentation-CLASS level, source-connected CSS,
model-attributed and outside the fixed safety net. One per distinct source
size is selected by largest class endpoint-minus-lower gap, then larger
endpoint/smallerk, retaining source order for ties. No own distance search,
seed sweep or easy-instance selection was used. Selection covers517 eligible
presentations in the pinned numeric catalogue, SHA256
 a5f398de84652b49c11300c69e99af81fedff22361b8af2e52f431dba9772934.
This is a weight-five/discovery-provenance BB specialization, not a disjoint
mathematical family. Non-CSS PBB and disconnected proposals are excluded.

| n,k | Source ID | Source lower | Reported endpoint | Endpoint semantics |
|---|---|---:|---:|---|
|120,4|CS-0687c929|5|10|decoder estimate only|
|162,4|CS-0a81f585|5|9|supported source upper|
|180,4|CS-0d018ae6|5|14|decoder estimate only|
|384,4|CL-015c0d4f|5|16|decoder estimate only|
|420,4|CL-9fbce668|5|22|supported source upper|
|432,4|CL-f5754da6|5|23|supported source upper|

The lower5 is published evidence, not our independently certified bound.
A decoder scalar without a retained operator is NOT a rigorous upper bound.
The three other endpoints have source evidence, but our physical witnesses
are still checked independently. Exact/source estimates/own results remain
separate. Source class IDs, numeric parameters, model aliases and program
source HASHES are retained; no generated program source is imported.

## Original construction and full algebra

On Z/l times Z/m, label a physical site x*m+y; left qubits precede right.
Each monomial translates a check row(x,y) to column(x+a,y+b). Construct
Hx=[A B], Hz=[B^T A^T] with support sizes2+3 (either block orientation).
Translation commutativity implies Hx Hz^T=AB+BA=0 over GF(2).
Independent physical-column construction uses inverse Hx incidence and
forward Hz incidence, swapping A/B between left/right qubits. Every actual
file is compared to these columns. Check weight5, k=n-rankHx-rankHz=4,
complete logical quotients and nonsingular Gx Gz^T are verified. Logicals
use the unchanged compute_logicals.py --method bitset, independently checked.
Actual row-set tests verify translations and the weight-preserving involutive
XZ map left(x,y)<->right(-x,-y).

## Basis-independent component check: soundness

Raw Tanner connectedness alone can be misleading if check generators mix
independent factors. For each stabilizer row space compute its unique fully
reduced GF(2) echelon basis, then join physical columns appearing together
in a reduced row, for BOTH Hx and Hz. The connected components of this union
are the finest physical partition over which the CSS stabilizer splits.

Every reduced row is contained in one resulting component, so each row space
is the direct sum of its component restrictions. Conversely, suppose any
physical partition splits a row space (it is closed under projection onto
each block). It has a basis confined to these blocks; elimination between
rows with disjoint supports never mixes blocks, so the unique reduced basis
also has every row confined to one block. Hence no splitting partition can
separate two columns joined by a reduced row. Apply this to both CSS spaces:
the union is exactly the finest simultaneous partition. A single component
therefore rules out a hidden direct sum under any generator-basis change.
This is a finite stabilizer-support statement, not a distance theorem or a
claim about unrestricted entangling Clifford equivalence.

Tests check invariance under random row operations, every physical bipartition
for tiny random spaces against actual projection membership, and a mutant
whose raw Tanner graph is connected only because it mixes four independent
factors. All six actual inputs have one row-space component of size n.
No pruning rule, bound or solver change is introduced.

## Reproduction and observation semantics

```
python3 scripts/codegen/select_open_llm_bb.py --catalogue /path/to/weight5_publication_catalogue.jsonl --out /tmp/selected-cases.json --selected-source /tmp/source-records.json
python3 scripts/codegen/open_llm_bb.py --all --out /tmp/open-llm-rebuilt
python3 scripts/codegen/validate_open_llm_bb.py --out /tmp/open-llm-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/open-llm-inventory.json
python3 tests/test_codegen_open_llm_bb.py
```

Selection refuses a different catalogue SHA. Compare selected output and
all24 generated files byte-identically. Same(n,k) row spaces, including XZ
swap, are compared across all tiered/untiered entries. Pending library branch
peers are also inspected; none has the same(n,k) as these six fixed inputs.
All prior24 rows/96 matrix bytes and51 tiered inputs are preserved.

Manifest claims explicitly distinguish `estimate N` from `<= N`. Existing
exact/upper parsing remains unchanged. Estimate parsing checks observed
internal consistency and physical n, and does not impose the estimate as a
hard upper bound. The audit compares all engines/bounds and GF(2)-verifies
actual printed words. It reports estimate relations without overwriting the
source. A contradicted supported bound or published positive lower claim is
a scientific escalation; an independently disproved decoder estimate is a
scientific finding requiring review, not an automatic constructor failure.
Missing numeric output is never filled from a source value.

Mac runs generation, algebra and tiny units only. Linux performs selected
serial60sCPU per case/engine,4GiB,90swall and one pinned runner-affinity CPU.
No author/third-party distance solver or paid cloud is used. New one-engine
exact/lower claims remain PLAUSIBLE; two-engine complete proofs plus GF(2)
words provide independent confirmation. Heavier jobs are prepared for yfclab2
without execution/core allocation. Keep unknown stems until PI naming/tiering.
See GH-177/REPORT.md for actual results, identities and retained raw records.
