# GH-186: original finite DHLV edge-qubit Tanner chains

Status: CONSTRUCTION_AND_LOCAL_BINARY_CHAIN_PASS; Linux gates pending.
Issue https://github.com/guluchen/DistQLDPC/issues/186; hub claim6501781585.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/dhlv-library. No PR requested; no main integration.

## Three proposals and choice

1. CHOSEN: finite DHLV edge-qubit Tanner chain prescription, with original
   fixed dihedral/local-code choices. Fills a distinct chain construction
   gap while individual exact distances remain separate from source claims.
   Risks: endpoint labels/inverses, edge versus face physical coordinates,
   square path cancellation, incorrect k/weight or asymptotic conclusions.
2. Certified-expander growing-distance HGP factors: separate remaining source
   and hypothesis gap, not supplied by earlier finite Gallager controls.
3. Cubical cosheaf/qLTC inputs: new source2609.20780v1 has impractical local
   lengths in its fixed displayed specialization; no smaller surrogate is
   claimed to inherit its theorem.

Prior GH153..185 records/coverage and literature reviewed. GH185 has six
cross-checked exact values and one unexecuted proof completion. Earlier
numeric/proof jobs and GH1651920 source ambiguity remain open. Fresh fetched
main/remotes and open issue scan show no competing DHLV topic; GH181/GH183
solver branches and server cores untouched. This is a finite library round,
not a solver adoption/Tier1..5 or performance claim.

## Source, fixed parameters and scientific boundary

Dinur–Hsieh–Lin–Vidick2206.07750v1, Sec2.4/2.7/3.1 Eq6, Lemma3.1;
CC BY4.0. Full authors/title/link/attribution and original specializations
stated in NOTICE and DHLV.md. No author code, matrix files, paper prose or
images copied; no external group/distance solver. Original GPL3+.

Before distance observation, freeze six dihedral cases and every local
matrix/generator order in #186. Control rotation_order3, degree3, HA111,
HB110/011. Other rotation orders4/6/8/10/14 have degree7, binary Hamming
parity columns1..7 and the fixed four-row dual parity matrix. Ordered A/B
formulas and complete entries in dhlv_cases.json. Actual k was computed by
GF2 rank after these geometric/local choices, not used for selection:
n108/784/1176/1568/1960/2744,k10/40/50/48/58/66. No replacement, resampling
or support/distance screening. Actual supplied-basis uppers4/8/6/28/10/34
are independently GF2-verified, not minima. Poor/easy results stay retained.

No published individual exact d is asserted for these original finite
specializations; absence does not establish a globally open research
problem. They represent the DHLV finite chain prescription but do NOT
certify its additional asymptotic expansion/robustness/decoder hypotheses.
We implement no decoder and do not declare the certified-expander/good-code
gap closed. Prefix DHLV records provenance, not disjointness from products.
Expanded binary bit weight is the actual Pauli weight, never geometric
edge-block weight. No identity X/Z metric duality is assumed.

## Written soundness, independent checks and reproduction

DHLV.md proves every square's two paths at each corner separately equal
HA[:,a] tensor HB[:,b], hence cancel in GF2. Full actual group action is
checked by independent faithful polygon permutations against the builder's
group formula. Every ordered four-part edge/square, endpoint label/stalk,
left-right square closure, generating symmetry/distinctness/connectedness,
regularity and full star is checked. At both endpoints an edge uses the
same label, not its inverse. The four-part version needs no two-part TNC
restriction. Actual d1 physical columns are reconstructed from endpoint
tensor maps; actual d2 columns from edge full stars rather than constructor
square assembly. All eight individual tensor paths per square are verified
from actual retained binary matrices before global commutation checks.

Complete logical quotient bases/kernel/stabilizer exclusion/full pairing,
actual ranks/k and finite counting lower bound, actual upper words and
reduced stabilizer-space coordinate connectivity pass. The latter excludes
physical direct sums hidden by mixed check rows. Every published pending
library branch/main pinned-ref scan has no same(n,k) peer. All prior24rows/
96matrices and51tiered inputs preserved; this branch30untiered/81total.

Commands:
```
python3 scripts/codegen/dhlv.py --all --out data/matrices/untiered --certificates optimization/experiments/GH-186/raw/certificates
python3 scripts/codegen/validate_dhlv.py --out optimization/experiments/GH-186/raw/construction.json
python3 tests/test_codegen_dhlv.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```

Mac generation/algebra/tiny units only; no solver/support distance searches.
15new tests pass, including actual group/source symmetry, edge/square/full
star/stalk/endpoint-inverse/actual binary column mutants, changed commuting
square-row basis rejected as wrong incidence, false stabilizer upper and
mixed hidden direct-sum mutants. Full24matrix+6complete-certificate fresh
byte reproduction/overwrite guard passes. Prior34units pass,49total. The
original six triangular COLOR CLI cases remain explicit; HGP default12 and
invalid-family stem rejection preserved. DHLV added as an explicit smoke
family selector only, no default/binary change. Raw local evidence retained.

## Preregistered Linux gates and heavy path

One unchanged build,49units, full inventory/construction comparison and
24matrix/6full-certificate regeneration. Explicit six default MaxSAT plus
six CC calls, serial defaultseed,60sCPU/90swall/4GiB each, one pinned
allocated ephemeral-runner CPU;20min job cap. No broad/repeated/supplemental
scientific CI, Mac solver or paid-cloud substitute. Shared CI times are
diagnostic, no seed-median performance decision applies to single smokes.

Retain raw logs/JSON/CSV/environment/source/binary/input hashes, independently
GF2-check every printed and supplied-basis word and compare all intervals/
exacts. Missing fields remain unavailable/INCOMPLETE, never filled from a
basis word/another engine/source. Every exact answer needs an actual verified
minimum word. Any contradiction stops for PI scientific review; new
one-engine exact/lower values stay PLAUSIBLE pending independent completion.

Heavy work becomes a frozen unexecuted yfclab2 package:6hCPU+600swall/4GiB,
serial defaultseed, pinned PI-allocated confirmed-free core, nohup/nullstdin,
actual-word/other-engine contradiction guards and full identities. No core
allocated/server job executed. No solver/build/default/tiered/name/QDistSAT/
main/gh-pages/PR change; independent construction continues meanwhile.

## Completion fields

What changed: six original reproducible finite DHLV edge-qubit inputs,
complete group/edge/square/local-chain certificates, independent soundness,
provenance and bounded validation gates.
Validation performed:49local units, full finite group/action/incidence/
actual binary-chain/GF2/logicals/upper-word/rowspace/inventory checks,
24matrix+6complete-certificate byte reproduction.
Results: construction passes; Linux terminal numeric/actual-result gates pending.
Unresolved: Linux gates and any proof completion packages, prior jobs,
certified-expander/good-code/cosheaf research gaps and PI integration.
Scientific semantics changed:no.
PI action required:yes for integration/final names/tiers/server allocation;
routine independent construction and validation continue.
