# GH-121 PIB v2: why v1 slowed TN_250 solution finding, and the v2 variant (`-pib=4`)

Branch `experiment/gh-121-pib` (v1 = 3405c7d). All runs on the Mac, at most 4 solver processes at a
time, 2 GB RSS watchdog (never triggered), wall limits via `-cpu-lim`. Runs that are compared were run
side by side under the same load, but loads differ between tables (3-4 concurrent solvers), so wall
times here are indicative only; the comparisons rest on counts (conflicts, propagations, phases).

## Summary

* **The TN_250 card-mto regression is mostly search luck, plus a real but smaller v1 defect.** In a
  feasibility probe the solver finds a solution only at some point inside one of its alternating
  LRB / VSIDS phases (budgets of 20M, 20M, 40M, 40M, 80M ... propagations). With the default seed main finds
  the first X cap 16 solution early in LRB phase 1 (8.8M propagations, 30 s). Under a light perturbation
  (`-pib-seed`, which changes only the engine's 1 % lookahead-threshold sampling) main needs 48-86M
  propagations (253-561 s, two seeds > 596 s) on 6 of 7 seeds. Main's 30 s is the lucky outlier, and
  v1's 737 s is not the only anomaly.
* **v1 still finds solutions later than main**: over 7 seeds v1 needs 62-123M propagations (median
  75M vs main 50M; all found in LRB phase 2 or later). **The cause is the generic lookahead's iset memory, which a PIB prune skips.**
  After a generic lookahead success the engine keeps the literals of the isets it found in
  `conflLits`. The next lookahead tries those literals first (`pickAuxiVar`), and their `activityLB`
  is bumped (`bumpConflVars`). A v1 PIB prune (12 % of all conflicts in the probe) returns before that,
  so the next generic iset search starts from stale seeds. Restoring the memory with the PIB isets
  (`-pib=4`) makes the solver find the X cap 16 solution in LRB phase 1 on 5 of 7 seeds (median 14.7M
  propagations), against main 1 of 7 and v1 0 of 7. v2 needs fewer propagations than v1 on 7 of 7 seeds.
  Each half alone (`-pib=6` conflLits, `-pib=7` activityLB) helps only partly (2 of 5 seeds each).
* Hypotheses (a)-(d) from the task: (a) activity bumping: rejected (no-bump `-pib=3` does not find in
  > 393 s and needs 1.57x the conflicts of v1 on the X cap 8 refutation probe). (b) long/weak PIB learnts:
  rejected (PIB learnts are shorter and have lower LBD than generic soft learnts). (c) threshold
  bookkeeping: rejected (lookahead skip rate, success rate and conflicts per lookahead equal main's).
  (d) phase saving: not changed by PIB and not needed to explain the data (the v2 fix leaves phases
  untouched).
* **v2 = `-pib=4`** keeps v1's refutation gain (TN_250 Z cap 14 NONE probe: main 2.58M conflicts / 413 s,
  v1 2.47M / 356 s, v2 2.31M / 333 s), passes all 28 tier0+tier1 correctness runs (with `-pib-check`,
  0 check failures). On the TN_250 card-mto full solve (3 runs side by side) it takes main 1115 s, v1 2398 s,
  **v2 908 s**; with `-pib-seed=12345` main 1557 s, v1 1340 s, v2 1355 s (all `o 15`).
* **v1's large gains on GB_144_12_12 and LP_544_80_12 no-card are also largely default-seed luck.** Over
  4-5 seeds the geometric mean conflict ratio v1/main is 0.89 / 0.82 (GB card-mto / no-card) and 1.43
  (LP_544 no-card), instead of the default seed's 0.50 / 0.46 / 0.72. v2 is better than v1 on every one
  of the 7 case/mode pairs measured over seeds (v2/main 0.58, 0.78, 0.90, 0.72, 0.97, 1.10, 1.00).
* **Recommendation:** time `-pib=4`. Because these instances are dominated by solution-finding luck,
  time them over a few `-pib-seed` values (main = the same binary without `-pib*`, or `-pib-seed=X`
  alone) rather than with the default seed only.

## Tools added (diagnosis only)

* `-pib-diag`: per probe (and at each LRB/VSIDS phase end), counters split by conflict kind
  (hard / generic soft / PIB): count, mean learnt size, LBD, backjump length, decision level, unit
  learnts; generic-success and PIB reason sizes; decisions on qubit vars. Search unchanged.
* `-pib-seed=X`: sets the engine `random_seed` (default 91648253). The only random draw in the
  search is the 1 % sampling of the lookahead threshold, so this is a light perturbation.
* `-pib-probe=X|Z:CAP:LB`: runs only that feasibility probe (the probe is a fresh solver, so its search
  is identical to the same probe inside a full solve: X cap 16 main reproduces 297301 conflicts).
* Search identity re-checked: binary without PIB flags = main 398054e, `-pib` = v1 3405c7d
  (byte-identical `-v` logs, timing lines removed, on BB_108_8_10, LP_340_56_8, GB_144_12_8 x
  {no-card, card-mto}).

## 1. The X cap 16 feasibility probe of TN_250_10_15 card-mto (default seed)

Columns: `-pib-diag` counters for the whole probe. `gen` = generic soft conflicts (lookahead / pure
soft), `pib` = PIB conflicts; size / LBD / bj = mean learnt size, LBD, backjump levels.

| config | time to FOUND | conflicts | hard | gen | pib | gen size / LBD / bj | pib size / LBD / bj | hard size / LBD / bj | lookahead calls at generic point | skipped (lb==1 or lb>thres) | LK success / LOOKAHEAD |
|---|---|---|---|---|---|---|---|---|---|---|---|
| main | 30 s (LRB phase 1, 8.8M UP) | 297301 | 3946 | 293355 | 0 | 43.2 / 33.4 / 1.13 | - | 31.3 / 18.8 / 3.35 | 383109 | 323150 (0.84) | 0.764 |
| v1 `-pib` | 737 s (LRB phase 3, 122.8M UP) | 4268373 | 25580 | 3746491 | 496302 | 38.2 / 31.1 / 1.10 | 36.2 / 25.1 / 1.62 | 38.0 / 22.2 / 2.52 | 5660347 | 4788182 (0.85) | 0.749 |
| v2 `-pib=4` | 55 s (LRB phase 1, 14.7M UP) | 473043 | 5104 | 384860 | 83079 | 41.2 / 33.1 / 1.10 | 34.8 / 24.6 / 1.68 | 34.0 / 20.1 / 3.08 | 621933 | 529989 (0.85) | 0.751 |

Reason sizes: generic success 58-64 involved literals + 7 false soft literals; PIB 27 row literals
+ 9 false soft literals (lb 8.1 on average). On the smaller X cap 8 probe (NONE): main 24516 conflicts,
v1 23516 (PIB learnts 22.9 / LBD 16.9 vs generic 38.5 / 30.5), `-pib=3` 36849, `-pib=4` 20723.

Reading: (b) PIB learnts are not long or weak; they are shorter and have lower LBD than the generic ones.
(c) The adaptive lookahead threshold behaves like main's: the same share of lookahead calls is skipped
(0.84-0.85), the same success rate (0.75-0.76), and about 0.75-0.78 conflicts per lookahead. The
difference is not per-conflict behaviour but how many conflicts are needed before the probe reaches a
solution, i.e. where in the phase schedule the solution is hit.

## 2. Solution finding is phase-quantised and has a heavy tail (seed study, X cap 16 probe)

Time is from probe start (3-4 solvers concurrent); `L1` = found in LRB phase 1, `V2` = VSIDS phase 2,
etc.; `M` = cumulative main-search propagations (the phase budget unit; load-independent).

| config | seed default | seed 12345 | seed 777777 | seed 31415926 | seed 2718281 | found in LRB phase 1 |
|---|---|---|---|---|---|---|
| main | 30 s L1 8.8M | 561 s V2 85.9M | 253 s L2 47.7M | 261 s L2 48.8M | > 596 s (> 80.8M) | 1/5 |
| v1 `-pib` | 737 s L3 122.8M | 464 s V2 86.9M | 316 s L2 63.0M | 377 s L2 75.2M | 299 s L2 61.7M | 0/5 |
| **v2 `-pib=4`** | 55 s L1 14.7M | 49 s L1 13.8M | 74 s L1 19.3M | 9 s L1 3.2M | 223 s L2 47.5M | **4/5** |
| `-pib=6` (conflLits only) | 216 s L2 45.4M | 281 s L2 55.7M | 62 s L1 16.5M | 336 s L2 65.4M | 44 s L1 12.3M | 2/5 |
| `-pib=7` (activityLB only) | 317 s L2 64.5M | 43 s L1 13.0M | 24 s L1 8.0M | 361 s L2 76.2M | > 600 s (> 80.1M) | 2/5 |
| `-pib=3` (no bump) | > 393 s (> 40.0M) | | | | | 0/1 |
| `-pib=5` (3 + 4) | 341 s L2 58.6M | | | | | 0/1 |

Two more seeds (run later, 1 probe at a time beside three TN_250 solves):

| config | seed 1001 | seed 2002 |
|---|---|---|
| main | 270 s L2 50.3M | > 600 s (> 81.3M) |
| v1 `-pib` | 375 s L2 72.7M | 367 s L2 79.1M |
| v2 `-pib=4` | 244 s L2 50.2M | 18 s L1 6.7M |

Over all 7 seeds: found in LRB phase 1 main 1/7, v1 0/7, v2 5/7; median propagations to FOUND main
50.3M, v1 75.2M, v2 14.7M. Per seed, v2 needs fewer propagations than v1 on 7 of 7 seeds, and fewer than
main on 5 of 7 (one tie at 50.2M vs 50.3M; main better with the default seed).

At equal budget, LRB phase 1 runs about 20 % faster in wall time with PIB (v1 75 s vs main 91 s for 20M
propagations). So v1 loses because it needs more propagations, not because each one costs more.

## 3. Mechanism

`lookahead()` ends a generic success with `resetConflicts(nbIsets)` (all iset literals go into
`conflLits`), pushes the last iset's literals, and calls `bumpConflVars()` (an `activityLB` bump of
every `conflLits` var). The next `lookahead()` copies `conflLits` into `lastConflLits`, and
`pickAuxiVar()` tests those literals first, before the `activityLB` heap. A v1 PIB prune returns from
`lookahead()` before the generic search, so `conflLits` keeps whatever the last generic lookahead left,
possibly many conflicts earlier, and no `activityLB` bump happens. 88 % of the conflicts in the probe are
generic lookahead successes. Their isets (and hence the learnt soft clauses that steer the CDCL search)
depend on that seed order, so the search trajectory changes. v2 sets, at each PIB prune,
`conflLits = {softLits[u] : u in U}` over the lb rows used (the PIB isets) and bumps them exactly as a
generic success would. The data cannot separate "stale seeds hurt" from "PIB isets are good seeds".
v2 also finds earlier than main on most seeds, which suggests the second.

## 4. v2 definition (`-pib=4`)

v1 (`-pib`) unchanged; at each PIB prune at the generic point additionally (`Solver::pibPrune`):
`conflLits.clear()`; for every unassigned unit-soft var u of the lb used rows: `insertAuxiVarOrder(u)`,
`conflLits.push(softLits[u])`; then `bumpConflVars()`. Soundness is unaffected (only the lookahead's
heuristic order changes). Diagnosis variants: `-pib=3` v1 without VSIDS/LRB activity bumps in the
analysis of PIB conflicts, `-pib=5` = 3 + 4, `-pib=6` conflLits part of 4 only, `-pib=7` activityLB
part of 4 only.

## 5. Verification

### Correctness (tier0 + tier1, `-pib=4 -pib-check -pib-stats`, limit 280 s)

All 28 runs (14 codes x {no-card, card-mto}) PASS: `o N` equals d from the stem, `checkFails` 0 (every
PIB conflict and every analysed PIB learnt clause re-verified). The seed studies below also returned the
correct distance in every run (GB_144_12_12 12, LP_442_68_10 10, LP_544_80_12 12, TN_108_2_12 12; 90 of
90 runs over main / v1 / v2), and every TN_250 full solve returned `o 15`.

tier0+tier1 total conflicts vs main (S0 report numbers for main and v1): geomean v1/main 0.866,
v2/main 0.870, v2/v1 1.005; max v2/main 1.122 (TN_72_8_8 no-card), max v1/main 1.157.

### TN_250_10_15 card-mto, full solve (limit 2600 s, the three runs side by side)

Elapsed seconds at the end of each probe (+ duration of the probe).

| probe | main (frozen-main398) | v1 (frozen121 `-pib`) | v2 (`-pib=4`) |
|---|---|---|---|
| X cap 16 feasibility | FOUND 16 at 36.2 | FOUND 16 at 763.7 | FOUND 16 at 57.5 |
| Z cap 16 feasibility | FOUND 16 at 122.5 (+86.3) | FOUND 16 at 943.7 (+180.0) | **FOUND 15** at 76.9 (+19.4) |
| X cap 15 feasibility | FOUND 15 at 290.7 (+168.2) | FOUND 15 at 1383.9 (+440.2) | - (not needed) |
| Z cap 14 feasibility | NONE at 714.0 (+423.3) | NONE at 1729.9 (+346.0) | - |
| Z cap 15 optimize | - | - | OPT 15 at 485.0 (+408.1) |
| X cap 15 optimize | OPT 15 at 1114.9 (+400.9) | OPT 15 at 2398.1 (+668.2) | OPT 15 at 907.8 (+422.8) |
| total | **1114.9 s, o 15** | **2398.1 s, o 15** | **907.8 s, o 15** |

v2's Z cap 16 probe happened to find a weight-15 logical, so the interleave skipped the X cap 15 /
Z cap 14 feasibility probes and went to the two optimisations. The refutation work (Z cap 14 NONE in
main/v1; the proof inside Z cap 15 optimize in v2) is 346-423 s in all three.

Second full solve with `-pib-seed=12345` (same binary for the three; side by side, plus one X cap 16
probe run):

| probe | main | v1 `-pib` | v2 `-pib=4` |
|---|---|---|---|
| X cap 16 feasibility | FOUND 16 at 564.9 | FOUND 16 at 468.5 | FOUND 16 at 51.9 |
| Z cap 16 feasibility | FOUND 16 at 569.8 (+4.9) | FOUND 16 at 667.0 (+198.5) | FOUND 16 at 195.0 (+143.1) |
| X cap 15 feasibility | FOUND 15 at 797.6 (+227.8) | FOUND 15 at 724.4 (+57.4) | FOUND 15 at 512.2 (+317.2) |
| Z cap 14 feasibility | NONE at 1184.1 (+386.5) | NONE at 1024.9 (+300.5) | NONE at 842.7 (+330.5) |
| X cap 15 optimize | OPT 15 at 1557.0 (+372.9) | OPT 15 at 1339.8 (+314.9) | OPT 15 at 1355.1 (+512.9) |
| total | **1557.0 s, o 15** | **1339.8 s, o 15** | **1355.2 s, o 15** |

Across the two seeds: main 1115 / 1557 s, v1 2398 / 1340 s, v2 908 / 1355 s. The probes that find a
solution vary a lot from seed to seed in every configuration (main's X cap 16: 36 s vs 565 s). The
refutation probe Z cap 14 varies little and is faster with PIB (main 423 / 387 s, v1 346 / 301 s, v2
331 s).

Refutation check, single probe (`-pib-probe=Z:14:9`, three side by side): main 2580163 conflicts,
69.4M UP, 412.7 s; v1 2473382, 77.5M, 356.1 s; v2 2306933, 71.2M, 332.8 s.

### Other cases: conflicts over seeds (default + `-pib-seed` 12345, 777777, 31415926 [, 2718281])

Total engine conflicts over all probes (thousands). Main = the same binary without PIB flags (search
identical to main 398054e for the default seed). Wall times are from 4 concurrent solvers and only
indicative. Every run returned the correct distance.

| case | mode | config | default | 12345 | 777777 | 31415926 | 2718281 | geomean conflicts (ratio to main) | geomean wall s |
|---|---|---|---|---|---|---|---|---|---|
| GB_144_12_12 | card-mto | main | 1670k | 1894k | 692k | 966k | 1167k | 1198k (1.00) | 77 |
| GB_144_12_12 | card-mto | v1 | 837k | 765k | 1082k | 1099k | 1784k | 1063k (0.89) | 54 |
| GB_144_12_12 | card-mto | v2 | 970k | 433k | 436k | 1162k | 733k | 690k (0.58) | 34 |
| GB_144_12_12 | no-card | main | 1211k | 985k | 722k | 1984k | 772k | 1057k (1.00) | 64 |
| GB_144_12_12 | no-card | v1 | 552k | 637k | 1651k | 563k | 1504k | 868k (0.82) | 40 |
| GB_144_12_12 | no-card | v2 | 1081k | 1721k | 436k | 838k | 544k | 819k (0.78) | 42 |
| LP_442_68_10 | card-mto | main | 206k | 235k | 259k | 144k | - | 206k (1.00) | 25 |
| LP_442_68_10 | card-mto | v1 | 159k | 261k | 128k | 459k | - | 222k (1.08) | 22 |
| LP_442_68_10 | card-mto | v2 | 138k | 305k | 211k | 131k | - | 184k (0.90) | 20 |
| LP_442_68_10 | no-card | main | 292k | 201k | 137k | 277k | - | 217k (1.00) | 27 |
| LP_442_68_10 | no-card | v1 | 139k | 290k | 171k | 141k | - | 176k (0.81) | 17 |
| LP_442_68_10 | no-card | v2 | 147k | 236k | 186k | 93k | - | 156k (0.72) | 17 |
| LP_544_80_12 | no-card | main | 1421k | 550k | 507k | 499k | - | 667k (1.00) | 112 |
| LP_544_80_12 | no-card | v1 | 1025k | 1329k | 434k | 1406k | - | 955k (1.43) | 120 |
| LP_544_80_12 | no-card | v2 | 453k | 1763k | 365k | 600k | - | 646k (0.97) | 100 |
| TN_108_2_12 | card-mto | main | 248k | 213k | 225k | 226k | - | 228k (1.00) | 12 |
| TN_108_2_12 | card-mto | v1 | 272k | 311k | 261k | 327k | - | 292k (1.28) | 13 |
| TN_108_2_12 | card-mto | v2 | 249k | 263k | 232k | 260k | - | 251k (1.10) | 12 |
| TN_108_2_12 | no-card | main | 207k | 208k | 194k | 195k | - | 201k (1.00) | 11 |
| TN_108_2_12 | no-card | v1 | 227k | 203k | 218k | 221k | - | 217k (1.08) | 10 |
| TN_108_2_12 | no-card | v2 | 198k | 197k | 193k | 216k | - | 201k (1.00) | 9 |

Default seed only (the coordinator's setting), v1 and v2 conflict ratios vs main: GB_144_12_12 card-mto
0.501 / 0.581, no-card 0.456 / 0.893; LP_442_68_10 card-mto 0.774 / 0.669, no-card 0.475 / 0.503;
TN_108_2_12 card-mto 1.095 / 1.003, no-card 1.096 / 0.954; LP_544_80_12 no-card 0.722 / 0.319. The
default seed favours v1 on GB_144_12_12 and main's default seed is unlucky on LP_544_80_12 no-card
(1421k conflicts vs 499-550k for the three other seeds). These single-seed ratios do not predict the
over-seed means.

## 6. Recommendation

Time `-pib=4` (v2). Over seeds it never does worse than v1 in the measured cases, and it removes the
TN_250 solution-finding regression. Keep `-pib` (v1) only as a reference. Because GB_144_12_12, LP_544_80_12
and TN_250_10_15 are dominated by where the solution is hit in the phase schedule, single default-seed
timings of either variant can differ from their typical behaviour by 2-20x. When a decision depends on
such instances, time them over 3-5 `-pib-seed` values for both main and the candidate.
