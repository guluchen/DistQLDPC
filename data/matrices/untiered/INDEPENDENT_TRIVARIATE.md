# Independent three-cycle bicycle inputs (GH-197)

Original reconstruction of Galimova, [2603.17703v1](https://arxiv.org/abs/2603.17703v1),
Eq5/Table1 self-dual prescription A=1+x+y+z, B=A^T on Z_L^3. Proposed
prefix ITB is provenance, not a disjoint mathematical family assertion.

| L | stem | actual both-half rank | source exact | initial actual GF2 upper |
|---:|---|---:|---|---:|
|3|ITB_54_14_unknown|20|5|5|
|4|ITB_128_20_unknown|54|8|8|
|5|ITB_250_26_unknown|112|not individually published|17|
|7|ITB_686_38_unknown|324|not individually published|14|
|9|ITB_1458_50_unknown|704|not individually published|65|
|11|ITB_2662_62_unknown|1300|not individually published|121|

All6periods frozen in issue197 before generation. Original k comes from
actual finite binary rank, not an assumed formula. Source5/8 labels are
exact claims and must be reproduced, not relabeled heuristic. Original
periods have unconfirmed exact distance; absence in one paper is not proof
of global openness. Retain poor/easy results; do not replace instances after
observing bounds. Initial upper words do not establish growing distance.

```
python3 scripts/codegen/itb.py --all --out /tmp/itb-rebuilt
python3 scripts/codegen/validate_itb.py --out /tmp/itb-construction.json
python3 tests/test_codegen_itb.py
python3 optimization/experiments/GH-197/raw/review_pinned_inventory.py
```

All24matrices reproduce byte for byte; full logical bases use unchanged
compute_logicals.py --method bitset. Independent inverse physical columns
AND separate explicit Kronecker/transpose construction agree with every
actual matrix. Full commutation/ranks/k/logical quotient/pairing, physical
X/Z identity/three independent cyclic maps, typed stabilizer connectivity
and actual basis words pass.18new+34prior units;30untiered/81total inventory
PASS.35pinned main/library inventories have no same(n,k)peer after actual
original ranks; same-n Haah/BB/TOR/TN inputs differ in actual k. Three group
generators alone would not prove physical CSS inequivalence. No copy added.

Source Eq5 Hx=[A B],Hz=[B^T A^T] fixes actual inputs and gives HxHz^T=AB+BA.
The following source prose adds transposes in this expansion; this is a
recorded algebraic typo, not an input convention we silently adopt. In this
specialization Hx=Hz and actual commutation is checked independently.
No external ILP/Stim/QDistRnd or author code used. Source paper perpetual
license; original mathematics-only GPL3+ implementation/data, no author
matrix files or paper text/images redistributed. Attribution NOTICE,
finite soundness MODIFICATIONS; PDFpages3-5 visually checked and SHA receipt
retained. Source asymmetric CRT-equivalent cyclic examples not added merely
to count coordinate labels. No asymptotic/growing-distance/good-code claim.

One-time Linux plan:6MaxSAT+6CC serial60CPU/90wall/4GiB/defaultseed/pinned
allocated CPU,20min workflow cap. Source exact anchors must reproduce with
actual words; missing numeric fields INCOMPLETE. New lower/exact PLAUSIBLE
until independent implementation/search and actual GF2 witness confirmation.
No invented source-upper-word targets for originals, no repeated scientific
CI for timeouts/fullsuite/sweep/timing adoption. Heavy proof/numeric gates
become guarded unexecuted yfclab2 jobs; no core allocated. All untiered on
work branch, no solver/default/tier/name/QDistSAT/main/PR change. Linux pending.
