# GH-177: source-open LLM-discovered weight5 CSS BB targets

Status: CONSTRUCTION_PASS; Linux selected smoke pending.
Issue https://github.com/guluchen/DistQLDPC/issues/177; hub15 claim6497563591.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/open-llm-bb-library; source commit recorded after push.
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
Validation: local45units/construction/regeneration pass; Linux pending.
Results: own solver results pending, source distances all nonexact at selection.
Unresolved: Linux numeric/word gates; broader coverage gaps still open.
Scientific semantics changed: no.
PI action required: yes for integration, naming/tiering and server allocation
if needed; independent library work continues meanwhile.
