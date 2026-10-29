# GH-184: closed higher-genus static4.8.10 color CSS open targets

Status: CONSTRUCTION_AND_ACTUAL_WORD_AUDIT_PASS; two exact distances
cross-checked; one numeric gate and five engine-proof completions remain.
No exact/lower distance inferred from a cover, source geometry or basis word.
Issue https://github.com/guluchen/DistQLDPC/issues/184; hub15 claim6500161639.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/closed-color-library; data8ecb7dd45e660ea040b573454c5ed51bd763c70b;
Linux source44039a47ece3e0637184784440c46d48053b503e.
No PR requested; no solver/build/default/tiered/QDistSAT/main change.

## Three proposals and choice

1. CHOSEN: finite closed4.8.10 static color CSS from original Wythoff
   source-quotient bases and deterministic connected integer cyclic covers.
   Expected: genuine closed higher-genus topology gap and initially unknown
   finite distances across practical sizes. Risks: reflection/group regularity,
   local manifold/color/orientation, primitive cover/chain identities, false
   static/Floquet k/d transfer and duplicate/disconnected-copy counting.
2.3D stabilizer color/colex: genuine missing finite geometry, source extraction
   and independent local/rank checks still needed. Not implemented here.
3.Explicit certified expander-factor HGP/practical good qLDPC: stronger finite
   source hypothesis gap persists; prior finite Gallager/bundle examples do
   not establish it. Not implemented here.

Fresh open issues/fetched remotes show no competing closed-color/colex topic.
GH181/GH183 solver work and server cores untouched. Prior GH165 quotient
ambiguity1920 stays held for PI; only unaffected rows1–3 are used. Prior
GH182 completed source/peer/upper-word gates/final CI; its two numeric and
seven proof jobs remain open. Prior GH153..182 records/coverage/literature
reviewed. This is a construction/library round, not Tier1..5 adoption or a
performance claim; shared CI timings diagnostic only.

## Source boundaries and fixed finite selection

Bombin–Martin-Delgado quant-ph/0605138v3 Eqs1–3 supplies static face-X/face-Z
color CSS and k=4-2chi. Higgott–Breuckmann2308.03750v2 SecII.1–II.3 supplies
finite reflection/Wythoff tiling mathematics; published PRX Quantum5,040327
is CC BY4.0, arXiv nonexclusive. Breuckmann–Terhal1506.04029v2 TableI rows
1–3 supplies finite oriented quotient parameters, reused from own GH165
bounded relation enumerator. See CLOSED_COLOR.md/NOTICE for authors, titles,
versions/DOIs/attribution and license boundaries. Only mathematics and own
code: no author implementation, matrix file, paper prose/images or external
group/distance solver copied, redistributed or executed. Original GPL3+.
Nonexclusive/IEEE paper distribution is not imputed to source software/data.

Static k=4g, NOT source Floquet k=2g. Source embedded/circuit distances,
decoder estimates and noise models are never inserted as static CSS distance
claims. Original finite covers are explicitly marked as such; no asserted
published individual exact distance for any of these six inputs. No source
geometric floor/ceiling expression is used as a lower/exact proof.

Fixed source edge parameters60/160/360 produce Wythoff bases n240/640/1440,
genus4/9/19. Fixed q2/5/10 covers of n240 give n480/1200/2400,genus7/16/31.
Sorted full ladder n240/480/640/1200/1440/2400; static k16/28/36/64/76/124,
actual per-half ranks112/226/302/568/682/1138. Prefix COLOR retains topology/
provenance, not a new disjoint family count. Unknown stems remain unchanged.
No distance/word-weight/solve-time screening, resampling or replacement.

Actual initial supplied-basis upper words8/8/12/8/16/8 are independently
GF2-verified, not minima. Single primitive covers do NOT guarantee growing
distance: q2/5/10 already have actual upper8, retained as finite controls
rather than silently choosing another cohomology class after observing it.
This finite specialization is not claimed to provide an asymptotic growing-
distance or good-qLDPC family. Other genuine family/size gaps stay open.

## Soundness, independent validation and reproduction

Full proofs in CLOSED_COLOR.md: actual finite regular right action plus
every commuting left translation; reflection automorphism/involution;
semidirect source reflections and exact local orders; independent two-color
orbit faces versus constructor ribbon darts; every closed oriented face,
edge, circular vertex link and face coloring; Euler genus; canonical integer
tree/cotree cocycle with exact face closure and primitive period1; all cover
vertex/edge/face neighborhoods and fibers; explicit integer boundary
projection and transfer identities. No count-only/congruence-only shortcut.

Actual Hx=Hz=face incidence, even face sizes/intersections prove CSS
commutation; actual ranks and both complete logical quotient bases/full
pairing verified independently. All color sums give the all-ones vector,
with exactly two dependencies per half confirmed by rank. Identity on
physical qubits exchanges X/Z and preserves weight, not absolute distance.
Unique reduced stabilizer-basis support has one coordinate component for
each case, excluding physical direct sums hidden by mixed check rows.
Actual basis words checked for syndrome/stabilizer exclusion/logical detection.

Commands:
```
python3 scripts/codegen/closed_color.py --all --out data/matrices/untiered --certificates optimization/experiments/GH-184/raw/certificates
python3 scripts/codegen/validate_closed_color.py --out optimization/experiments/GH-184/raw/construction.json
python3 tests/test_codegen_closed_color.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 scripts/codegen/closed_color.py --all --out /tmp/gh184-fresh --certificates /tmp/gh184-fresh-certificates
```

Mac generation/algebra/tiny units only, serial small-memory bitsets.13new
units cover complete finite certificates, wrong source relation/action,
wrong reflection, face orientation/color, nonclosing integral voltage,
zero-voltage disconnected cover, nonzero/nonprimitive composite cover,
actual matrix mutation, stabilizer-as-upper rejection, hidden direct sum
under mixed rows, explicit six-case CLI selection and exact matrix/certificate
byte reproduction/overwrite refusal. Prior34 units pass,47total. Existing
triangular color CLI unit now explicitly selects its original six stems,
so adding another COLOR specialization does not accidentally broaden that
smoke workload. Default HGP selection and invalid-family-stem rejection hold.

Initial unit-test failure compared in-memory tuple-valued dual steps with
JSON-loaded list values; no matrix/topology mismatch. Corrected to exact
serialized JSON byte comparison, preserving the stronger artifact guarantee.
Original failed output retained as raw/unit-tests-first-failed.log; final
unit output passes. No source input or scientific expectation changed.

All24 matrices and6 complete group/cell/voltage certificates reproduced byte
for byte. Prior24 manifest rows/96 matrix files and all51 tiered inputs
preserved; branch30untiered/81total inventory. Fresh all-main/pending-library
same(n,k) scan finds no peer; direct/swapped rowspace duplicate checks pass.
Certificates/cases and all actual matrix hashes bind the retained evidence.

## Preregistered Linux gates and heavier completion path

One unchanged build,47units, full inventory/construction comparisons,24matrix
and6certificate byte regeneration. Six selected default MaxSAT and six CC
calls,serial60sCPU/90swall/4GiB/one pinned allocated runner CPU/defaultseed,
20min total job cap. No broad/repeated/supplemental scientific CI, Mac solver
or source-distance support search, paid-cloud substitute or timing claim.
No seed medians/ranges apply to single diagnostic short calls.

Retain every raw output/failure/timeout and source/binary/input identity,
GF2-check all actual words and compare every interval/answer between engines
and independently verified physical uppers. Missing stdout fields remain
unavailable/INCOMPLETE, never filled from source formulas, basis upper or
other engine. New one-engine exact/stronger lower results remain PLAUSIBLE
until independent completion. A genuine semantic contradiction stops for
PI scientific review, not an adjusted claim, input or hidden failed cell.

Long work becomes frozen unexecuted yfclab2 jobs6hCPU+600swall/4GiB/serial
seed0/explicit PI-allocated confirmed-free core/nohup/nullstdin. No core
allocated or server job executed. No final name/tier/QDistSAT/main/default/
solver/PR change. Remaining prior numeric/proof jobs and broad goal stay open.

## Completion fields

What changed: six original closed higher-genus static color CSS inputs,
reproducible source/group/cell/integral-cover construction, provenance,
independent full topology/chain/logical/actual-word evidence and library gates.
Validation: local47units, source regularity/reflection, every manifold/color/
cover/chain/rowspace/GF2/logical check,24matrix+6certificate byte regeneration,
full inventory/duplicate checks pass locally and on Linux; actual-word audit
replay byte-identical against local matrices/certificates.
Results: two-engine exact8 at n240/480; CC-only exact12/8/16 at n640/
1200/1440 remain PLAUSIBLE. n2400 CC[2,8] with actual upper8; MaxSAT
no numeric fields, INCOMPLETE.
Unresolved: n2400 default MaxSAT numeric gate and five engine-proof jobs
packaged unexecuted; broader3D-color/explicit-expander/
good-qLDPC coverage, prior incomplete jobs and PI integration.
Scientific semantics changed: no.
PI action required: yes for main integration/final names/tiers and any server
allocation; independent validation/construction continues meanwhile.


## Retained terminal Linux evidence and verdict

Library [40900677931](https://github.com/guluchen/DistQLDPC/actions/runs/40900677931),
job123541774247 SUCCESS; source CI40900677725/job123541773257 SUCCESS.
Source44039a47ece3e0637184784440c46d48053b503e; unchanged solver binary
SHA25668f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
Ubuntu24.04 hosted Linux,Python3.12.3,c++13.3.0,pinnedCPU0,serial defaultseed,
60sCPU/90swall/4GiB per call. Full job log485284 characters plus all engine
logs/JSON/CSV/environment/source/binary/input identities retained under
raw/actions/default/. Replay against actual local matrices/full certificates
is byte-identical. No repeated/supplemental scientific CI, Mac/external
solver, paid-cloud substitute or timing claim. A green collector does not
pass the missing n2400 numeric gate. No engine/actual-word contradiction.

| n | MaxSAT60s | CC60s | Numeric gate | Scientific status |
|---:|---|---|---|---|
|240|exact8|exact8|PASS|two engines+actual GF2 word|
|480|exact8|exact8|PASS|two engines+actual GF2 word|
|640|[10,12]|exact12|PASS|PLAUSIBLE, independent lower proof pending|
|1200|[6,8]|exact8|PASS|PLAUSIBLE, independent lower proof pending|
|1440|[4,16]|exact16|PASS|PLAUSIBLE, independent lower proof pending|
|2400|UNKNOWN,no numeric fields|[2,8]|INCOMPLETE|open; actual supplied-basis upper8|

Every printed physical word and supplied-basis upper passes independent GF2
syndrome/stabilizer/logical-detector checks. Two exact8 values have complete
two-engine independent confirmation. CC-only exact12/8/16 and unresolved
stronger lower results remain PLAUSIBLE; no name/source claim is changed.
No Floquet distance, group isomorphism, genus, primitive-cover property or
source geometric expression is used as an absolute distance proof. The
fixed cover upper8 controls are retained without reselection or advertising
growing d; largest case remains genuinely unresolved by these short calls.
Missing default MaxSAT fields stay empty, never filled by CC/basis/source.

Five frozen unexecuted yfclab2 jobs: MaxSAT n640/1200/1440/2400; CC n2400.
References12/8/16/8 are actual checked physical uppers, not asserted exact
answers. Each6hCPU+600swall/4GiB,serial seed0,explicit PI-allocated confirmed-
free core;30hCPU/30h50mwall aggregate LIMITS, not ETA. Dry-run/Mac/altered-
argv guards pass without solver invocation/output directory. Case/input/
argv/host/allocation/core, actual-upper/minimum-word and retained-other-
engine contradiction guards apply. No core allocated/server job executed;
no final name/tier/QDistSAT/main/default/solver/PR change.

Verdict: all six genuine closed static constructions/topology/chain/logical/
rowspace/actual-word gates pass; two exact distances cross-checked. Four
codes' independent proof completions and one default numeric gate remain
with five jobs. Broader coverage/validation/integration gaps remain; the
continuous goal is not complete. Next-source3D-color notes are research only,
not additional implemented or validated cases in this one-family package.
