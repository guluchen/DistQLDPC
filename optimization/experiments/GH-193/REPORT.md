# GH-193: finite quantum radial LP ladder

Status: LINUX_AND_SOURCE_WORD_GATES_PASS; largest MaxSAT numeric/independent lower proofs INCOMPLETE.
Issue https://github.com/guluchen/DistQLDPC/issues/193; hub6504943810.
Branch codex/radial-library from remotely verified main
6083e662c621f3b66defd434cfae31a028d483c4. No PR/main integration.
Previous goal turn made progress: GH192 added2QC GHP/LP interval references,
retained full Linux evidence/audit replay, froze3proof+1source-word jobs,
pushed ea7a8ba7 and finalCI40929090230 SUCCESS. B3 source46 word remains
INCOMPLETE; CC strongest24 PLAUSIBLE. No server execution/rename.
Goal remains active, prioritizing unknown exact distances and real gaps.

## Proposal/source/frozen parameters

CHOSEN: explicit radial lifted-product prescription, sourceD2 plus original
modulus ladder; useful missing LP specialization/size range, risk source
shift/tensor/conjugate-transpose/rank-qualification/source-estimate errors.
DEFERRED planar tile CSS needs exact boundaries/proof-status review;
DEFERRED multivariate/trivariate prescriptions need z=xy/independent factors/
CRT/Haah/GB/BB equivalence review. Prior records/coverage read, current open
issues and both branch pages checked; no competing radial topic.32pinned
refs have no same(n,k) peer for four added cases. No external author contact.

Scruby–Hillmann–Roffe2406.14445v2 latest20Apr2026, PRX Quantum7,020310,
DOI10.1103/67xf-zdjb, Eq8/SecII/AppC/D. Full title/authors/credit NOTICE.
Primary PDFp16 D1/D2 rendered/visually checked; same as HTML Eq26/27,
source SHA256 in raw/source-review.json. Paper perpetual license, original
mathematics-only GPL3+ implementation/matrices; no author code/files/prose/
images or external distance program. AppC explicitly discusses distance
estimates; do not promote numerical20 to exact ground truth. SecII v2
qualifies expected dependencies as high-probability and checks binary ranks;
we retain that qualification and check every actual finite rank.

Fixed before any generated ranks/distance: r4,s11/29/47/79,n352/928/1504/2528;
A1=[[10,10,1,6],[4,7,5,2],[8,10,6,9],[1,6,0,6]],
A2=[[9,5,8,3],[5,4,1,0],[0,4,6,10],[2,8,4,2]].
Only s11 is sourceD2; other moduli original, no inherited d20/growth/memory/
single-shot claim. No selection/replacement after easy/poor observations.
Expected k18 verified, not presumed. Source90r3s5 D1 is peer-review-only,
fixed matrices in radial_peer_case.json; BB_90_8_10 is a known same(n,k) peer.
Its full source algebra/logicals/words pass; no direct/swapped rowspace or
288finite coordinate-map match. Arbitrary column equivalence UNRESOLVED,
not proof of inequivalence; no second benchmark/manifest row. This is not
post-distance rejection. Raw peer90-review receipt/log/hash retained.

## Local gates and finite upper soundness

Constructor row translations agree with independently enumerated physical
columns and separate spoke-major Kronecker/pullback. Source rows shift
RIGHT, not the PK first-column sign. Prime/r<=s/all no-four-cycle differences/
exponent rank AND actual classical binary ranks pass. Full actual quantum
commutation/ranks/k/logical quotients/pairing/typed physical stabilizer
connectivity/cyclic spoke automorphism pass. No assumed XZ metric map.
Classical dimensions3each; each binary rank41/113/185/313. Both-half quantum
ranks167/455/743/1255 and k18 all cases. General ring upper words22/58/94/158
have actual kernels/quotients/detectors and odd physical pairing. Written
library-only soundness in MODIFICATIONS.md; no solver/pruning bound rule.

```
python3 scripts/codegen/radial.py --all
python3 scripts/codegen/validate_radial.py --out optimization/experiments/GH-193/raw/construction.json
python3 scripts/codegen/review_radial_peer.py --out optimization/experiments/GH-193/raw/peer90-review.json
python3 tests/test_codegen_radial.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```
17newunits include25randomtiny coordinate/commutation/ring-word checks,
source/transpose/commuting-wrong-matrix/logical/entry/girth/rank/parameter/
audit mutants,16matrix byte reproduction/overwrite/CLI/defaultHGP12/LP4
selections and peer90exclusion. Tiny full-exponent-rank/no-four-cycle matrix
[[2,1,1],[1,1,3],[1,3,2]] over7 has extra actual binary dependencies;
the test catches removing the qualified binary-rank gate. This is algebra,
not a new quantum distance result.28untiered/79inventory pass; no direct/
swapped duplicate. Prior24rows/300matrix files and solver/build unchanged.
Mac algebra/generation/tiny tests only, no solver/support-distance search.

## Preregistered Linux gates

One unchanged build,17new+34prior units/full construction/inventory compare,
16matrix byte regeneration. Four MaxSAT+four CC attempts, serial60sCPU/
90swall/4GiB/defaultseed/pinned allocated Actions CPU,15min cap. Source90
is not run as an added benchmark. Retain full raw logs/argv/source/binary/
input identities and actual GF2 words. Source352 numerical20 upper target
and general verified ring bounds stay separate from raw fields. Missing
numeric or source-word gates INCOMPLETE, no synthetic source-filled values.
New strongest lower/exact PLAUSIBLE until independent implementation/search
plus actual words. No repeated scientific CI for timeouts/full tiers/seed
sweeps/timing adoption. Heavy proof/numeric/source-word gates freeze6hCPU+
600swall/4GiB/seed0/verbose/serial pinned explicit PI-allocated confirmed-free
yfclab2/nohup/nullstdin jobs; separate supplemental flags if needed. Limits
not ETA; no allocated core/server execution or paid-cloud substitute.

## Terminal Linux evidence

Dataddbf947872c6264d00181fdead2c0793c5938031;
sourcebada5e6e917e3b06f7db5c0c004111f22abce95b,
tree75097b36324135310d8af375187636c3869baed4.
[Library40931932802](https://github.com/guluchen/DistQLDPC/actions/runs/40931932802),
job123652333577 completed SUCCESS, all steps including audit/retention/upload.
Ordinary sourceCI40931932655 SUCCESS. Unchanged solver binary SHA256
68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
51units/full independent physical/pullback/classical+quantum ranks/logicals/
peer90/inventory comparisons and16matrix byte regeneration PASS. Exact
commands in source-pinned workflow. Eight one-time serial60sCPU/90swall/
4GiB/defaultseed/pinned allocated CPU attempts,15min cap. Shared timings
not performance/median/tier adoption evidence; no scientific CI repeats.

| stem | MaxSAT raw60s | CC raw60s | actual GF2 upper | numeric gate |
|---|---|---|---:|---|
|LP_352_18_unknown|[9,20]|[19,20]|20|PASS|
|LP_928_18_unknown|[9,26]|[22,58]|26|PASS|
|LP_1504_18_unknown|[9,26]|[22,26]|26|PASS|
|LP_2528_18_unknown|no numeric fields|[22,26]|26|INCOMPLETE|

Source352 numerical20 actual word reproduced in MaxSAT and CC (Z20).
Original finite cases have verified X26 words, including CC2528 X26 (and
prior Z46). Complete upper-word histories retained (including pre-pass
worse-than-basis words140/138 for928); actual kernels/stabilizer quotients/
detectors all verify. Reference upper-word gates all PASS. Strongest CC
lower19/22 remains PLAUSIBLE pending independent search/proof; no exact
result or certified improvement headline. No contradiction. Keep raw CC928
upper58 and empty MaxSAT2528 fields; do not substitute another engine's
upper26 or source/reference targets. Largest numeric INCOMPLETE remains.

All three larger fixed-modulus cases have actual upper26. These are useful
unknown-distance inputs and n-scaling controls, not evidence that d grows
with n. Retain the frozen cases without replacement or new source-growth/
single-shot/memory inference. Source90 remains comparison-only/unresolved,
not a new benchmark or a post-distance exclusion.

Durable raw/actions/default/job.log607114characters,22engine files
(4logs+4metadata+environment/results/DONE each engine),audit.json. Local
actual-word replay is byte-identical, no solver on Mac:
```
python3 scripts/codegen/audit_radial_smoke.py --maxsat optimization/experiments/GH-193/raw/actions/default/radial-maxsat --cc optimization/experiments/GH-193/raw/actions/default/radial-cc --construction optimization/experiments/GH-193/raw/construction.json --out /tmp/gh193-audit-replay.json
cmp /tmp/gh193-audit-replay.json optimization/experiments/GH-193/raw/actions/default/audit.json
```
Four default MaxSAT independent-proof jobs frozen in runner/jobs.jsonl;
largest also closes the missing numeric gate, not a second duplicate job.
Four CC exact-completion research jobs separately frozen in optional-cc-
jobs.jsonl; not the default queue and require explicit selection, not run
merely because distance is unknown. No supplemental source-word job needed.
All seed0/verbose/6hCPU+600swall/4GiB/serial pinned explicit PI-allocated
confirmed-free yfclab2/nohup/nullstdin. Each queue configured24hCPU/
24h40mwall LIMITS, not ETA (both48hCPU/49h20mwall). Actual reference
words20/26/26/26; case/job/argv/input/source/binary/other-engine/source-
reference/word contradiction guards. Required+optional dry-runs, Mac and
altered-argv refusal PASS without solver/output directory; CPU54 syntax
only. No allocated core/server run/paid cloud/repeat scientific CI.

Independent next-source work in NEXT_TILE_DESIGN.md identifies source
weight10 [[512,18,<=23]] (distinct from TableI exact labels), transcribes
PDF stencils, derives finite boundary/commutation checks and records
proposed size coverage and TN288k8 peer caution. No new tile issue/input or
implementation selected here. Prior source/proof/semantic holds remain.

## Completion fields

What changed:4reproducible radial LP inputs, source/rank/coordinate/logical/
upper-word proof/provenance, source90peer-only record, full Linux evidence,
4default proof/numeric jobs+separate4optional CC queue and next tile design.
Validation performed:51units/full finite hypotheses/actual classical+quantum
ranks/physical columns/pullback/logicals/words/typed space/32pinned refs,
16matrix byte reproduction,8bounded Linux attempts and byte-identical audit
replay. Prior24rows/300matrix files and solver/build preserved.
Results: actual uppers20/26/26/26, source20 word PASS; strongest CC lower
19/22 PLAUSIBLE, no exact result. Largest MaxSAT numeric INCOMPLETE.
Unresolved: independent lower proof, largest numeric gate, source90 arbitrary
equivalence; earlier packages/APM/stronger-hypothesis/PI integration items;
planar tiles and multivariate prescription coverage remain open.
Scientific semantics changed:no.
PI action required:yes for integration/tier/name/server allocation or prior
scientific hold; routine safe collection/research continues.
