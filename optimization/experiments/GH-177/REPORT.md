# GH-177: source-open LLM-discovered weight5 CSS BB targets

Status: CONSTRUCTION_ALL_NUMERIC_AND_TWO_ENGINE_EXACT_GATES_PASS.
Issue https://github.com/guluchen/DistQLDPC/issues/177; hub15 claim6497563591.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/open-llm-bb-library; source ff8f73e1156b84ea5f52ceaa7a3f9246d80a6c2e
(tree b45fe138de411d7f2bb1b9ae311c0b36204d44ca; data3a91c089fd2175d61ca91c0b6d72662fda7b1f2c).
No PR requested; main integration remains a PI decision.

## Proposals, scope and source

1. CHOSEN: six weight5 CSS BB source-open targets with explicit LLM discovery
   provenance. Expected: practical100..432 sizes and unknown distances, no
   easy-instance/solve-time selection. Risks: source class exactness, hidden
   direct sums, transposes, treating decoder estimates as certified bounds.
2. General homological products/fiber bundles: genuine remaining family gaps,
   but explicit finite parameter extraction needs further work.
3. Larger nonabelian group algebra open targets: useful larger-size coverage;
   source/equivalence review remains to perform.

Prior GH164..176 reports, literature survey and full coverage ledger reviewed.
PI explicitly prioritized unknown exact distances after GH176. Fresh open
issues/remote branches had no competing LLM/weight5 topic. This fills a BB
weight/provenance specialization, not a new independent mathematical family.
Source Cruz-Benito2610.06623v1 CSS construction/support split (paper CC BY4.0), numeric catalogue
qcode-discovery@da9178fd65ffc2eec3dab46089f9879eb02d4b23 (Apache2.0).
Source license/full six-record extract retained, attribution/changes in NOTICE.
No author/third-party implementation or external distance solver used.

Selection replay from pinned numeric catalogue SHA256
 a5f398de84652b49c11300c69e99af81fedff22361b8af2e52f431dba9772934:
source-connected/class-nonexact/model-attributed CSS, excluding fixed safety
net, PBB and disconnected rows.517 eligible presentations; one per distinct
size with largest source class endpoint gap, then endpoint/smallerk and
stable source order for ties. No own distance search/seed resampling.
Source IDs CS-0687c929,CS-0a81f585,CS-0d018ae6,CL-015c0d4f,CL-9fbce668,
CL-f5754da6. All k4, source lower5; endpoints10/9/14/16/22/23, only9/22/23
supported source upper evidence. Other values are decoder scalars only.

## Local validation and commands

```
python3 scripts/codegen/select_open_llm_bb.py --catalogue /tmp/qcode-weight5-publication-catalogue.jsonl --out scripts/codegen/open_llm_bb_cases.json --selected-source optimization/experiments/GH-177/raw/selected-source-records.json
python3 scripts/codegen/open_llm_bb.py --all --out data/matrices/untiered
python3 scripts/codegen/validate_open_llm_bb.py --out optimization/experiments/GH-177/raw/construction.json
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 tests/test_codegen_open_llm_bb.py
python3 scripts/codegen/open_llm_bb.py --all --out /tmp/gh177-fresh
```

Mac generation/algebra/tiny units only, no solver/source support search.
Independent physical columns and GF2 commutation/ranks/complete logicals/full
pairing; actual dual/translation maps; raw Tanner connectedness and unique-
reduced-basis component proof all pass on six actual inputs. Written proof
in OPEN_LLM_BB.md.11 new tests include20 tiny random polynomial constructions,
24 random row-basis changes, all bipartitions for20 tiny random row-space
pairs, a mixed-generator direct-sum mutant, invalid transpose/logicals and
parser mutant showing a decoder estimate must not cap an observed distance.
Prior34 units pass, total45. All24 new matrix files byte-reproduced.
30untiered+51tiered inventory; prior24 manifest rows/96 matrix bytes unchanged.
No same(n,k) peer across main or pending library branches, pinned refs retained.
No solver/build/tiered/default change; existing exact/supported-upper collector
claims retain their output semantics. New explicitly labelled estimate claims
only enforce observed consistency/physical n and actual word checks.

## Linux plan and scientific interpretation

One unchanged solver build;45units, full inventory/construction byte checks,
24-file regeneration. Six selected default MaxSAT and six CC runs, serial
60sCPU each,4GiB address cap,90swall, one allocated pinned runner-affinity core,
default seed,20min job cap. No sweeps/repeated diagnostic CI, Mac solver,
paid cloud, external solver, server execution or performance/Tier1..5 claim.
Medians/seed ranges not applicable to single diagnostic smokes.
Retain all raw output/argv/source/binary/input SHA including failures/timeouts.
Audit actual words in GF2 and compare observed bounds/answers between engines.
Published lower/support-upper disagreements escalate scientifically; decoder
estimates stay estimates and never fill numeric output or impose a hard upper.
An independently disproved estimate requires scientific review without silently
rewriting source facts. New one-engine exact/lower results remain PLAUSIBLE;
two complete engine proofs plus actual words can cross-check exact results.
Heavier completion becomes an unexecuted frozen yfclab2 package needing a
PI-allocated free core. No renaming/tiering/QDistSAT/main integration.

## Completion fields

What changed: six initially source-open weight5 CSS BB targets, reproducible
selection/generator, source attribution and independent algebra/components.
Validation: local+Linux45units/construction/regeneration, all numeric/actual-word
and source/binary/input audits PASS; retained audit replays byte-identically.
Results: both-engine exact10/9/12/16/22/23 with GF2 words; all source
classes were nonexact at selection, source estimates/uppers remain separate.
Unresolved: none for this batch's engine proofs; broader coverage gaps,
main integration/tiering and other branches' heavy jobs remain open.
Scientific semantics changed: no.
PI action required: yes for integration, naming/tiering and server allocation
if needed; independent library work continues meanwhile.


## Retained Linux results and verdict

Library [40880415723](https://github.com/guluchen/DistQLDPC/actions/runs/40880415723),
job123470111730 SUCCESS; source CI40880415568 job123470111054 SUCCESS.
Source ff8f73e1156b84ea5f52ceaa7a3f9246d80a6c2e; unchanged solver binary
SHA25668f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
Ubuntu24.04 hosted Linux, Python3.12.3,c++13.3.0,pinnedCPU0,serial,default
seed,60sCPU/90swall/4GiB per call. Complete raw log600902 characters and
all engine logs/JSON/CSV/environment identities retained under
raw/actions/default/. Audit replay is byte-identical using actual local files.
No supplemental/repeated CI solver call, Mac solver, external solver or
performance claim. All12 calls complete and all numeric gates pass.

| n | Source endpoint (class nonexact at selection) | MaxSAT | CC | Independent conclusion |
|---:|---|---:|---:|---|
|120|estimate10|10|10|exact10 with GF2 words|
|162|supported upper9|9|9|exact9 with GF2 words|
|180|estimate14|12|12|exact12 with GF2 words|
|384|estimate16|16|16|exact16 with GF2 words|
|420|supported upper22|22|22|exact22 with GF2 words|
|432|supported upper23|23|23|exact23 with GF2 words|

All observed exact answers/bounds and actual minimum-weight logicals agree
between two independently implemented internal searches and Python GF2
verification. The newly exact results therefore have independent completion,
not a one-engine PLAUSIBLE claim. No supported source bound or published
positive lower is contradicted. Every source endpoint has an own word at
that value or better. CS-0d018ae6 (n180,k4,classTC-dfb9cfae85) improves its
historical decoder estimate14 to exact12; do not confuse this selected
polynomial pair with the paper's DIFFERENT headline exact180,4,14 code.
Source metadata remains untouched in the manifest/case/extract; numeric
fields record actual solver output only. Unknown stems still await PI naming.

No heavier completion package is needed here: zero unresolved engine proofs
and no server resources allocated/executed. Existing other-branch heavy jobs
and incomplete numeric gates remain open; do not claim full goal completion.
Verdict: six source-open targets collected AND all six exact distances
cross-checked within selected short checks. Next genuine family research:
finite circle-fiber bundles under2009.03921v2 Definition2.11, original small
full-rank sparse bases and nonremovable twists, with no asymptotic-good-code
claim. The general homological-product/explicit-expander/closed-color/good-
qLDPC ledger gaps remain active under the unknown-distance priority.


Explicit headline distinction: both presentations use lattice(10,9), but the
selected pair is A=1+xy^3, B=1+x^2y^8+x^3y. The headline pair is
A=1+x^2y^2+x^5y, B=1+x^3y^3. Their source colored-Tanner class IDs differ;
the pinned numeric source marks the selected class nonexact and headline
class exact14. raw/headline-distinction.json records IDs and polynomials.
Headline14 remains an attributed source claim, not an external solver run
or a newly audited exact distance in this batch. No claim that it changed.
