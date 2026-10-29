# Upper-only trivariate tricycle inputs (GH-198)

Original mathematical reconstruction of Jacob, McLauchlan and Browne,
[2508.08191v3](https://arxiv.org/abs/2508.08191v3), Eqs5-14/TableV.
Proposed prefix TT identifies the length-3 construction/provenance, not a
disjoint-family assertion relative to homological/Koszul products.

| stem | torus | ranks Hx/Hz | source global distance | source X reference | initial actual X/Z word uppers |
|---|---|---|---|---|---|
|TT_72_6_unknown|4,3,2|22/44|exact6|exact12|14/8|
|TT_588_9_unknown|7,7,4|193/386|<=14|<=73|112/70|
|TT_648_12_unknown|6,6,6|212/424|<=14|<=72|108/18|
|TT_735_18_unknown|7,7,5|239/478|<=14|<=80|120/20|
|TT_840_9_unknown|8,7,5|277/554|<=16|absent|160/128|
|TT_1029_18_unknown|7,7,7|337/674|<=16|absent|96/24|

All6source cases fixed in issue198 before generation, no post-result
replacement. Only one648 presentation to cover distinct sizes without
quantity inflation. Five exact distances unconfirmed in the reviewed source;
not a proof of global openness. Source upper estimates are not our checked
words, lower bounds or circuit distances. Source72Zexact6/Xexact12 remain
separate; global exact6 reproduction does not itself reproduce exactX12.

```
python3 scripts/codegen/tt.py --all --out /tmp/tt-rebuilt
python3 scripts/codegen/validate_tt.py --out /tmp/tt-construction.json
python3 tests/test_codegen_tt.py
python3 optimization/experiments/GH-198/raw/review_pinned_inventory.py
```

Independent reverse physical columns AND separate Kronecker/actual-transpose
block construction agree with every matrix. All actual commutation/ranks/k/
logical quotient bases/pairing/metacheck redundancy/physical cyclic maps/
typed stabilizer connectivity/actual words PASS.18new+34prior units;24matrix
byte reproduction;30untiered/81total inventory.36pinned main/library refs
have no same(n,k)peer. Full logicals use unchanged compute_logicals.py
--method bitset. Metachecks audit redundancy only, never replace Gx/Gz.
No presumed qubit X/Z duality for these asymmetric halves.

SourceFIRST-COLUMN convention S[i,j]=delta(i,j+1) is followed explicitly,
not the preceding ITB row-RIGHT convention. Full soundness MODIFICATIONS.
Source CC BY4.0 credited with license link in NOTICE; original GPL3+ math
reconstruction, no author source/matrix files or paper text/images copied.
Primary PDFp3/p19 visually checked and SHA receipt retained. No external
Distm4ri/BP-OSD/QDistRnd/CSSLO program or author communication. No imported
single-shot/decoder/threshold/gate theorem or toric-layout claim.

One-time6MaxSAT+6CC Linux plan: serial60CPU/90wall/4GiB/defaultseed/pinned
allocatedCPU,20mincap. Preserve raw/source/input/binary identities and every
actual word. Source exact mismatch or actual word below a source exact half
escalates. Missing raw numeric/source-word gates stay INCOMPLETE; never
source-filled. New lower/exact PLAUSIBLE until independent confirmation.
Heavy proof/numeric/source-overall-word work becomes unexecuted guarded
yfclab2 jobs. All untiered/work branch; no core allocation/solver/default/
tier/name/QDistSAT/main/PR change. Linux and all numeric/source-global-word gates PASS.

## Retained Linux results

| n,k | MaxSAT raw [lb,ub] | CC raw [lb,ub] | actual GF(2) upper | status |
|---|---|---|---|---|
|72,6|[6, 6] SOLVED|[6, 6] SOLVED|6|cross-checked two engines + GF(2)|
|588,9|[14, 14] SOLVED|[14, 14] SOLVED|14|cross-checked two engines + GF(2)|
|648,12|[14, 14] SOLVED|[14, 14] SOLVED|14|cross-checked two engines + GF(2)|
|735,18|[14, 14] SOLVED|[14, 14] SOLVED|14|cross-checked two engines + GF(2)|
|840,9|[10, 16] BOUNDED|[16, 16] SOLVED|16|CC exact16 PLAUSIBLE; independent lower10|
|1029,18|[10, 16] BOUNDED|[16, 16] SOLVED|16|CC exact16 PLAUSIBLE; independent lower10|

52units and24matrix byte reproduction PASS. Complete evidence and byte-identical
audit replay in GH-198/raw/actions/default/. Source55d5b01a; library run40946335182
job123702566399 and ordinaryCI40946335166 SUCCESS. Three source-upper-only
cases now have global14 cross-checked by two complete engines plus actual
GF(2) minimum words. Two CC16 results remain PLAUSIBLE with independent
MaxSAT lower10. Separate actual X/Z upper words12/6,110/14,108/14,72/14,
156/16,96/16; source larger X claims remain literature references.
Two unexecuted MaxSAT proof jobs, total12CPUh/12h20wall limits, not ETA.
No source-word or CC completion jobs needed. All stems stay unknown/untiered
until PI approves integration/tiering.
