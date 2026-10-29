# Finite planar tile CSS inputs (GH-194)

Four frozen cases reproduce the planar boundary prescription of Steffan,
Choe, Breuckmann, Pereira and Eberhardt, *Tile Codes: High-Efficiency Quantum
Codes on a Lattice with Boundary*, [2504.09171v1](https://arxiv.org/abs/2504.09171v1).
Proposed prefix TILE identifies provenance, not a disjoint mathematical family.

| stem | box B | bulk L | actual ranks Hx/Hz | published distance status |
|---|---:|---:|---|---|
| TILE_288_8_unknown | 3 | 10 | 140/140 | Table I exact12; reproduction pending |
| TILE_512_18_unknown | 4 | 13 | 247/247 | separate weight10 example upper23; exact unconfirmed |
| TILE_1152_18_unknown | 4 | 21 | 567/567 | original finite size, no inherited source distance |
| TILE_2592_18_unknown | 4 | 33 | 1287/1287 | original finite size, no inherited source distance |

Fixed before rank/distance observations; all four remain even if easy or poor.
The last two are size controls and unresolved-distance targets, not a claim
that distance grows. Source Table I exact labels are not heuristic estimates.
An unconfirmed individual distance is not evidence of global openness.

## Reproduction and independent checks

```
python3 scripts/codegen/tile.py --all --certificates /tmp/tile-certificates --out /tmp/tile-matrices
python3 scripts/codegen/validate_tile.py --out /tmp/tile-construction.json
python3 scripts/codegen/review_tile_peers.py --out /tmp/tile-peer.json
python3 tests/test_codegen_tile.py
```

All four matrices per code are reproducible. Logicals use the unchanged
compute_logicals.py --method bitset. Independent validation uses separately
transcribed blue tiles, reverse physical column incidences, infinite Laurent
overlap parity, finite boundary intersections and prescribed pruning, full
actual ranks/commutation/logical quotients/pairing and typed physical
stabilizer connectivity. Every actual basis upper word is GF(2)-checked.
Initial basis uppers15/46/93/292 are upper bounds, never exact distances.
Complete qubit/anchor/pruning certificates are in GH-194/raw/certificates.
Soundness arguments and mutant coverage are documented in MODIFICATIONS.md.

Against 33 pinned main/library refs, sole same-(n,k) peer is TN_288_8_unknown
at 2cb22f295d161e9a2d29f58df1672c8c2799d732. Full GF(2) peer checks pass.
Exact weight1/2/3 counts of the full typed stabilizer spaces differ, proving
inequivalence under arbitrary physical column permutation and global X/Z
swap. This does not rely on provisional Tanner lower bounds or a quantum
logical-distance search. Raw pinned inventories/hashes/proof receipt retained.
CI fetches only that pinned peer commit for deterministic proof replay.

Physical edges are H/V lower-left endpoints in a B by B cell box. Blue T2
swaps orientation and reflects both coordinates through B-1. Red X anchors
extend above/below the L by L bulk; blue Z anchors extend left/right.
Physical H/V origins occupy 0..L+B-2 in both coordinates. Delete qubits
unsupported by either check type, then empty rows. No periodic boundaries.
The chosen cases delete zero columns, but a tiny fixture checks actual
pruning and catches removing it. No arbitrary X/Z metric map is presumed.

## Provenance and resource boundary

The paper is CC BY-NC-SA4.0. These are original GPL-3.0-or-later mathematical
reconstructions; no author software, matrix files, paper prose or images
are redistributed. Source PDF hash and visually reviewed pages2-4 retained
as a receipt, not the PDF itself. NOTICE credits all authors/construction.
No external distance solver or author communication.

Linux short-check plan: four MaxSAT and four CC attempts, each once, serial
60 CPU seconds, 90-second wall backstop, 4GiB, default seed, pinned allocated
CI CPU; workflow total cap15minutes. Check published exact12 and source23
with actual verified words. Preserve missing numeric fields as INCOMPLETE;
new stronger search bounds remain PLAUSIBLE until independent confirmation.
No scientific rerun to complete timeouts. Heavy proof/numeric/source-word
work becomes explicit unexecuted yfclab2 jobs; no server core is allocated.
All additions remain untiered on the work branch, with no solver/default/
tier/name/QDistSAT/main changes. Terminal evidence will be recorded in the
manifest and GH-194/REPORT.md without source-filled raw bounds.
