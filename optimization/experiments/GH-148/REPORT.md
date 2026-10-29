# GH-148 report: stabilizer-overlap constraint as a native MaxCDCL propagator (`-stab-overlap=auto`)

Issue: https://github.com/guluchen/DistQLDPC/issues/148 (hub #15). Baseline: main `12b3e05` (PR #147). Candidate:
branch `experiment/gh-148-stab-overlap`. Evaluated binary `2b297b5` (Tiers 1-5), frozen on yfclab2 as
`frozen/server-gh148-2b297b5/distqldpc`, sha256 `933ae40b968b3f47...` (= `gh148-2b297b5/bin/distqldpc`, built from a
clean `2b297b5` tree); main = `frozen/server-main-12b3e05/distqldpc`, sha256 `c1780ce39b1f2038...`. Later commits
(`9848360`, `bb72973`, this one) change nothing outside `optimization/`. All timings on yfclab2 (2x EPYC 7742), one
pinned core per process (`taskset -c CORE prlimit --as=4294967296 --`, stdin `/dev/null`); the Mac only built and ran
tests. No external solver.

## Summary

| Field | Content |
|---|---|
| Hypothesis | Lee 2026: a minimum-weight logical x meets every same-type stabilizer row g in at most floor(\|g\|/2) qubits (else x + g is lighter). Adding "at most floor(\|g\|/2) of g's qubits are 1" to each MaxSAT half probe prunes the search without changing any probe answer. |
| Proposal (chosen of 3) | A: the constraint as a native "at most k" propagator in MaxCDCL on the split MaxSAT path (`Solver::setOverlapRows` / `ovPropagate`); `auto` activates row g in a probe of cap c iff c >= 2 (floor(\|g\|/2) + 1). Rejected: B (Phase 2 lb-ladder policy), C (stronger CC lower bound). |
| Prior references | GH-85 orbit symmetry breaking (compatibility argued in MODIFICATIONS.md), GH-107 sharing, GH-133 parity step, GH-144 `-ub-pre` (unaffected: they use only probe answers and verified weights); GH-146 (ub finder, merged after 12b3e05). |
| Diff summary | `src/solver/Solver.{h,cc}` (+124: native rows, cached reason/conflict clauses, relocation), `src/core/distqldpc.cc` (`-stab-overlap=off\|on\|auto`, `-stab-overlap-enc=native\|clauses\|bin\|seq`, GF(2) check Hpar g = 0 and Glog g = 0, duplicate removal), tests (Part G, flag checks), README / MODIFICATIONS / NOTICE. **Default `off`**: default path byte-identical to main. |
| Scientific semantics changed | No. Every probe answer (FOUND / NONE / OPT) is unchanged by the lemma (MODIFICATIONS.md, GH-148 paragraph); returned solutions are still elements of the half instance, so every ub is a verified weight; lbs come only from NONE probes. 0 semantic issues in every run. |
| Commands | candidate `distqldpc {-no-card\|-card-mto} -frontier-stats -stab-overlap=auto [-seed=S] -cpu-lim=L CODE`; main the same without `-stab-overlap` (main's recorded Tier 5 via `server_tier5.py` without `-frontier-stats`, which only prints probe statistics). Runner `runner/run_queue.py`, jobs `runner/make_jobs.py`, analysis `runner/analyze_panel.py`, `runner/analyze_t5final.py`. |
| Limits / environment | Tier 1-3 1800 s, Tier 4 5000 s, Tier 5 21600 s; 4 GB address-space cap; Tier 1-4 panels on cores 90-123 (both arms concurrent); Tier 5 on cores 0-53, all 54 cells at once (same cores and protocol as main 12b3e05's recorded Tier 5). Tier 5 peak RSS 478 MB. |
| Inputs | `data/matrices/tier0..tier5` at `12b3e05` (old stem names; rename map below). |
| Reached tier | **Tier 5 (all gates passed)** |
| Status | **PASS Tiers 0-5**; 5-seed adoption check (2026-10-29): **TN_216 regression confirmed** (seed-median 1.53x no-card, 1.39x card-mto, above the 1.25 cell rule); TN_144 1.09x / 1.08x. Draft adoption PR (default `auto`) open for a PI decision; not merged (see "Adoption check" at the end). |

## Gate verdicts

| Tier | Evidence | no-card | card-mto | Verdict |
|---:|---|---:|---:|---|
| 0 | `make test-cc` (300/200 and 1500/600 on yfclab2; Part G: driver with the constraints in 18 configurations on 200 random codes + rotated surface codes d 3-5: RESULT = enumeration, UB >= d, LBs monotone); mutants 1 (limit floor(\|g\|/2) - 1) and 2 (rows without the GF(2) check) give wrong answers as required; `make test-cc-flags` 329 checks; tier0 78/78 answers (auto, on, on+clauses); default and `-stab-overlap=off` logs = main (29/30 identical, the 30th differs only in main's own timing-dependent `ub-pre` print order) | - | - | **PASS** |
| 1 | 5 seeds; caps <= 8 < 10 on LP_340 / LP_442, so no row is ever active: per-probe sequence identical to main for every seed (identity rule) | 1.000 (measured 0.989) | 1.000 (measured 0.956) | **PASS (neutral, identical search)** |
| 2 | 5 seeds; BB_288 0.21x, LP_544 0.68-0.69x, others 0.92-0.98x; max cell 0.978 | 0.698 | 0.697 | **PASS** |
| 3 | 5 seeds; LP_714 0.82x / 0.93x; TN_144 1.096x / 1.067x (1.0-1.25: watch) | 0.949 | 0.994 | **PASS (watch TN_144)** |
| 4 | 5 seeds; TN_250 1572 -> 1227 s / 1381 -> 1187 s (medians) | 0.781 | 0.859 | **PASS** |
| 5 | 54 cells x 6 h, default seed, vs main 12b3e05's recorded Tier 5: solved 10 vs 6, no cell lost, final lb higher on 5 cells and never lower, ub identical on all 54, main's final lb reached sooner on 50/54 cells (later: TN_216 x2, TN_360 card-mto, TN_396 no-card); no semantic issue | see below | see below | **PASS (watch TN_216)** |

Tier 1-4 per-cell table with seed ranges: `S1/panel_table.md`; raw `S1/server/t1..t4.jsonl`, logs
`S1/server/panel_logs.tar.gz`. S0 exploration (encodings, `auto` cost model): `S0/s0_clauses_table.md`,
`S0/s0c_native_table.md`. Tier 0 evidence: `S0/server/tier0/`.

## Tier 5 (6 h, 54 cells)

Run: `run_queue.py --cpus 0-53 --jobs jobs_t5_full.jsonl` from the `2b297b5` worktree on yfclab2, 2026-10-28 13:34-19:34
CST, all 54 processes at once (one per core 0-53); 54/54 results, 0 runner errors, 0 backstop kills, 0 science
problems. Raw: `T5/server/t5final_results.jsonl` (timestamped lb/ub events), logs `T5/server/t5final_logs.tgz`.
Baseline: branch `baselines/main-12b3e05` (`cce2fbb8`), `optimization/baselines/raw/main-12b3e05/server_tier5_results.json`
(copy: `S1/server/main_12b3e05_tier5_results.json`; same server, cores 0-53, 4 GB, 6 h, default seed; summarized in
`main_server_reference.json`). Full table with e52d15b stem names: `T5/t5_table.md`.

**Deviation from the preregistration in #148:** two waves on cores 90-123 with 14 concurrent main drift controls were
registered. After the PI pause the run was redone as one 54-cell wave on cores 0-53 (the cores main's recorded Tier 5
used; 64-123 were reserved for another round) against main's recorded Tier 5 without drift controls (cached-baseline
rule, PI 2026-10-11). The stopped earlier attempt (`raw/t5_partial_*`, `S1/server/t5_wave1_partial.jsonl`,
`S0/server/s0_tier5_probe.jsonl`) is kept for the record and **not counted**.

Times in s; "result" is `d=X` with solve time or `timeout`; last column pair: time at which main and the candidate first
reached main's final lb.

| Code (12b3e05 stem) | Mode | main: result / lb / ub | cand: result / lb / ub | main's final lb: main @ s, cand @ s (ratio) | change |
|---|---|---|---|---|---|
| BB_360_12_24 | no-card | timeout / 18 / 24 | 10361 (d=24) / 24 / 24 | 18: 87, 10 (0.119) | SOLVED; lb 18->24 |
| BB_360_12_24 | card-mto | timeout / 18 / 24 | 10810 (d=24) / 24 / 24 | 18: 88, 10 (0.117) | SOLVED; lb 18->24 |
| BB_756_16_ge30 | no-card | timeout / 18 / 34 | timeout / 18 / 34 | 18: 696, 21 (0.0308) |  |
| BB_756_16_ge30 | card-mto | timeout / 18 / 34 | timeout / 18 / 34 | 18: 702, 15 (0.022) |  |
| BB_864_4_ge30 | no-card | timeout / 18 / 52 | timeout / 18 / 52 | 18: 903, 17 (0.0193) |  |
| BB_864_4_ge30 | card-mto | timeout / 18 / 52 | timeout / 18 / 52 | 18: 920, 17 (0.019) |  |
| BB_1080_4_ge30 | no-card | timeout / 18 / 70 | timeout / 18 / 70 | 18: 2689, 27 (0.00993) |  |
| BB_1080_4_ge30 | card-mto | timeout / 18 / 70 | timeout / 18 / 70 | 18: 3028, 27 (0.00886) |  |
| LP_1020_136_16 | no-card | 1270 (d=16) / 16 / 16 | 566 (d=16) / 16 / 16 | 16: 1270, 566 (0.446) |  |
| LP_1020_136_16 | card-mto | 1264 (d=16) / 16 / 16 | 566 (d=16) / 16 / 16 | 16: 1264, 566 (0.448) |  |
| LP_1054_140_20 | no-card | timeout / 18 / 20 | timeout / 18 / 20 | 18: 9365, 3167 (0.338) |  |
| LP_1054_140_20 | card-mto | timeout / 18 / 20 | timeout / 18 / 20 | 18: 9295, 3160 (0.34) |  |
| LP_1122_148_20 | no-card | timeout / 18 / 20 | 17410 (d=20) / 20 / 20 | 18: 5859, 3012 (0.514) | SOLVED; lb 18->20 |
| LP_1122_148_20 | card-mto | timeout / 18 / 20 | 17486 (d=20) / 20 / 20 | 18: 5853, 3018 (0.516) | SOLVED; lb 18->20 |
| LP_1428_184_24 | no-card | timeout / 18 / 24 | timeout / 18 / 24 | 18: 9581, 2110 (0.22) |  |
| LP_1428_184_24 | card-mto | timeout / 18 / 24 | timeout / 18 / 24 | 18: 9572, 2117 (0.221) |  |
| LP_1768_224_22 | no-card | timeout / 18 / 22 | timeout / 18 / 22 | 18: 16190, 3838 (0.237) |  |
| LP_1768_224_22 | card-mto | timeout / 18 / 22 | timeout / 18 / 22 | 18: 14616, 3828 (0.262) |  |
| LP_2610_744_16 | no-card | timeout / 10 / 16 | timeout / 10 / 16 | 10: 437, 430 (0.983) |  |
| LP_2610_744_16 | card-mto | timeout / 10 / 16 | timeout / 10 / 16 | 10: 438, 437 (0.996) |  |
| TN_180_2_17 | no-card | 6549 (d=17) / 17 / 17 | 6124 (d=17) / 17 / 17 | 17: 6549, 6124 (0.935) |  |
| TN_180_2_17 | card-mto | 11634 (d=17) / 17 / 17 | 6872 (d=17) / 17 / 17 | 17: 11634, 6872 (0.591) |  |
| TN_216_4_18 | no-card | 10818 (d=18) / 18 / 18 | 16988 (d=18) / 18 / 18 | 18: 10818, 16988 (1.57) |  |
| TN_216_4_18 | card-mto | 11593 (d=18) / 18 / 18 | 13345 (d=18) / 18 / 18 | 18: 11593, 13345 (1.15) |  |
| TN_252_2_21 | no-card | timeout / 17 / 21 | timeout / 17 / 21 | 17: 9602, 9519 (0.991) |  |
| TN_252_2_21 | card-mto | timeout / 17 / 21 | timeout / 17 / 21 | 17: 8678, 8493 (0.979) |  |
| TN_288_2_ge9 | no-card | timeout / 9 / 24 | timeout / 9 / 24 | 9: 16, 14 (0.854) |  |
| TN_288_2_ge9 | card-mto | timeout / 9 / 24 | timeout / 9 / 24 | 9: 12, 11 (0.948) |  |
| TN_324_4_ge9 | no-card | timeout / 9 / 25 | timeout / 9 / 25 | 9: 16, 14 (0.908) |  |
| TN_324_4_ge9 | card-mto | timeout / 9 / 25 | timeout / 9 / 25 | 9: 16, 16 (0.965) |  |
| TN_360_4_ge17 | no-card | timeout / 17 / 24 | timeout / 17 / 24 | 17: 5493, 5348 (0.974) |  |
| TN_360_4_ge17 | card-mto | timeout / 17 / 24 | timeout / 17 / 24 | 17: 5284, 5615 (1.06) |  |
| TN_396_4_ge17 | no-card | timeout / 17 / 27 | timeout / 17 / 27 | 17: 4445, 5094 (1.15) |  |
| TN_396_4_ge17 | card-mto | timeout / 17 / 27 | timeout / 17 / 27 | 17: 4296, 3941 (0.917) |  |
| TN_432_8_ge9 | no-card | timeout / 9 / 32 | timeout / 9 / 32 | 9: 30, 28 (0.91) |  |
| TN_432_8_ge9 | card-mto | timeout / 9 / 32 | timeout / 9 / 32 | 9: 29, 27 (0.909) |  |
| TN_468_4_ge17 | no-card | timeout / 17 / 33 | timeout / 17 / 33 | 17: 9211, 5540 (0.601) |  |
| TN_468_4_ge17 | card-mto | timeout / 17 / 33 | timeout / 17 / 33 | 17: 10697, 5024 (0.47) |  |
| TN_496_2_ge17 | no-card | timeout / 17 / 34 | timeout / 17 / 34 | 17: 10910, 9804 (0.899) |  |
| TN_496_2_ge17 | card-mto | timeout / 17 / 34 | timeout / 17 / 34 | 17: 12854, 9268 (0.721) |  |
| TN_504_2_ge17 | no-card | timeout / 17 / 45 | timeout / 17 / 45 | 17: 5238, 4643 (0.886) |  |
| TN_504_2_ge17 | card-mto | timeout / 17 / 45 | timeout / 17 / 45 | 17: 5096, 4692 (0.921) |  |
| TN_540_4_ge9 | no-card | timeout / 9 / 46 | timeout / 9 / 46 | 9: 38, 35 (0.913) |  |
| TN_540_4_ge9 | card-mto | timeout / 9 / 46 | timeout / 9 / 46 | 9: 35, 32 (0.91) |  |
| TN_576_2_ge9 | no-card | timeout / 9 / 54 | timeout / 9 / 54 | 9: 43, 40 (0.922) |  |
| TN_576_2_ge9 | card-mto | timeout / 9 / 54 | timeout / 9 / 54 | 9: 38, 35 (0.915) |  |
| TN_612_2_ge17 | no-card | timeout / 17 / 62 | timeout / 17 / 62 | 17: 4508, 3653 (0.81) |  |
| TN_612_2_ge17 | card-mto | timeout / 17 / 62 | timeout / 17 / 62 | 17: 4386, 3863 (0.881) |  |
| TN_648_10_9to52 | no-card | timeout / 9 / 65 | timeout / 9 / 65 | 9: 59, 56 (0.939) |  |
| TN_648_10_9to52 | card-mto | timeout / 9 / 65 | timeout / 9 / 65 | 9: 65, 63 (0.967) |  |
| TN_648_14_ge9 | no-card | timeout / 9 / 40 | timeout / 9 / 40 | 9: 76, 72 (0.952) |  |
| TN_648_14_ge9 | card-mto | timeout / 9 / 40 | timeout / 9 / 40 | 9: 65, 62 (0.953) |  |
| TN_684_2_ge9 | no-card | timeout / 9 / 31 | timeout / 17 / 31 | 9: 26, 25 (0.952) | lb 9->17 |
| TN_684_2_ge9 | card-mto | timeout / 9 / 31 | timeout / 9 / 31 | 9: 25, 24 (0.952) |  |

| Family | cells | solved main / cand | final lb higher / lower | ub lower / higher | time to main's final lb, cand/main: geomean (range) |
|---|---:|---:|---:|---:|---|
| BB | 8 | 0 / 2 | 2 / 0 | 0 / 0 | 0.027 (0.0089-0.12) |
| LP | 12 | 2 / 4 | 2 / 0 | 0 / 0 | 0.40 (0.22-1.00) |
| TN | 34 | 4 / 4 | 1 / 0 | 0 / 0 | 0.91 (0.47-1.57) |
| all | 54 | 6 / 10 | 5 / 0 | 0 / 0 | |

**Semantic checks (all pass).** For every candidate cell the answer lies in the stem range, every lb <= the stem's
upper value and every ub >= its lower value, against both the 12b3e05 stems and the e52d15b `{lb}to{ub}` stems (which
carry GH-146's tighter verified ubs, e.g. TN_648_10 <= 32, BB_756 <= 34); candidate lb <= main ub and candidate ub >=
main lb in every cell; solved answers equal the stems (BB_360 24, LP_1122 20, LP_1020 16, TN_180 17, TN_216 18) and
main's answers where both solved. No bounds crossing a stem, no wrong answer.

**Reading.** Upper bounds are identical everywhere (they come from the unchanged `-ub-pre` pass); the constraint acts on
the lower-bound probes. BB codes reach lb 18 8-110x sooner (BB_756/864/1080: 15-27 s instead of 696-3028 s) and BB_360
is solved by the MaxSAT path (d = 24, about 10 400-10 800 s); LP codes reach 18 2-4.5x sooner, LP_1122 is solved (d =
20, about 17 400 s), LP_1020 takes 0.45x; LP_2610 is unchanged (lb 10). The TN family is close to neutral (geomean
0.91): TN_180, TN_468 and TN_496 gain, TN_684 no-card gains a ladder step (lb 9 -> 17 at 20 523 s), but **TN_216 solves
1.57x (no-card) and 1.15x (card-mto) slower**, and TN_396 no-card / TN_360 card-mto reach 17 1.15x / 1.06x later.
These are single default-seed 6 h runs; GH-121 showed 2-20x seed spread on TN codes (main itself: TN_180 6549 vs
11634 s between the two modes), so TN_216 is listed as a watch cell together with Tier 3's TN_144 (1.07-1.10x), not as
a confirmed regression. Tier 5 gate (no lost cell, no lower lb, more solved cells, bounds reached sooner): PASS.

## Stem renames 12b3e05 -> e52d15b (17 tier5 stems; `S1/stems_12b3e05_to_e52d15b.tsv`)

BB_1080_4_ge30 -> BB_1080_4_30to48; BB_756_16_ge30 -> BB_756_16_30to34; BB_864_4_ge30 -> BB_864_4_30to40;
TN_288_2_ge9 -> TN_288_2_9to24; TN_324_4_ge9 -> TN_324_4_9to25; TN_360_4_ge17 -> TN_360_4_17to24;
TN_396_4_ge17 -> TN_396_4_17to26; TN_432_8_ge9 -> TN_432_8_9to29; TN_468_4_ge17 -> TN_468_4_17to29;
TN_496_2_ge17 -> TN_496_2_17to30; TN_504_2_ge17 -> TN_504_2_17to34; TN_540_4_ge9 -> TN_540_4_9to34;
TN_576_2_ge9 -> TN_576_2_9to37; TN_612_2_ge17 -> TN_612_2_17to40; TN_648_10_9to52 -> TN_648_10_9to32;
TN_648_14_ge9 -> TN_648_14_9to28; TN_684_2_ge9 -> TN_684_2_9to29. The other 10 tier5 stems are unchanged. This round
implies no stem change: no new distance, and no lb above the stems' lower values was proven.

## Recommendation

GH-148 passed Tiers 0-5 and is eligible for adoption; it is not merged. Adoption needs:
1. **A rebase onto main `e52d15b`** (GH-146's Stern finder default and the 17 stem renames). The change touches
   `Solver.{h,cc}` and the split path of `distqldpc.cc`, so the rebased binary re-enters Tier 0 (tests, mutants, tier0
   answers, default-path identity with e52d15b).
2. **A PI decision on the default.** The branch keeps `-stab-overlap=off` (default path byte-identical to main). The
   evidence supports `auto` as the default on the split MaxSAT path (Tier 2 0.70x, Tier 4 0.78-0.86x, Tier 5 +4 solved
   cells, 5 higher lbs, nothing lost). Whether the watch cells (TN_216 1.15-1.57x at Tier 5, TN_144 1.07-1.10x at
   Tier 3) need a 5-seed TN check first is also a PI call.
3. After a merge, re-record main's Tier 0-5 baselines (PI 2026-10-13 rule) and re-check tier placement: BB_360_12_24
   and LP_1122_148_20 become solvable within 6 h by MaxSAT, but above 5000 s, so they stay in Tier 5.

**Lessons for the next round.** A sound dominance constraint pays off where lower-bound probes are the bottleneck: on
BB and LP codes the lb-18 probes became cheap, and the open BB codes now stall at the next ladder step (from 18 to the
stems' 30, i.e. much larger caps), so the Phase 2 step policy (proposal B) is worth revisiting on top of this
constraint. On TN codes the constraint is close to neutral; the per-probe activation rule of `auto` is where to tune it.

## Adoption check (PI decision 2026-10-28)

The PI asked for a 5-seed confirmation of the two watch cells before an adoption PR, then a merge of current main and
a PR making `-stab-overlap=auto` the MaxSAT default (draft, PI decides; no merge).

**5-seed runs.** yfclab2, cores 0-39, one process per pinned core (`taskset -c CORE prlimit --as=4294967296 --`,
stdin `/dev/null`), all 40 processes at once, 2026-10-28 22:47 - 2026-10-29 03:09 CST. Main = `frozen/server-main-12b3e05`
(sha256 `c1780ce3...`), candidate = `frozen/server-gh148-2b297b5` (sha256 `933ae40b...`) with `-stab-overlap=auto`; both
arms `{-no-card|-card-mto} -seed=S -frontier-stats`, seeds 0-4, the two arms of a cell concurrently; limits TN_216 21600 s,
TN_144 1800 s (Tier 3 limit). 40/40 solved (TN_216 d = 18, TN_144 d = 13), 0 runner or science issues, peak RSS 132 MB.
Raw: `ADOPT/confirm5/` (`results.jsonl`, `logs.tgz`, `jobs_s5.jsonl`); runner `ADOPT/runner/run_queue_confirm5.py`
(= `runner/run_queue.py` with cores 0-39), table `ADOPT/runner/analyze_confirm5.py`. Median ratio = cand median / main median.

| Code | Mode | seed: main s / cand s (cand/main) | main median (range) | cand median (range) | median ratio | per-seed ratio range |
|---|---|---|---|---|---:|---|
| TN_216_4_18 | no-card | s0: 9282 / 13131 (1.41); s1: 8370 / 12519 (1.50); s2: 12897 / 14829 (1.15); s3: 12387 / 15009 (1.21); s4: 8700 / 14191 (1.63) | 9282 (8370-12897) | 14191 (12519-15009) | 1.529 | 1.15-1.63 |
| TN_216_4_18 | card-mto | s0: 9930 / 10418 (1.05); s1: 10724 / 13065 (1.22); s2: 10217 / 15678 (1.53); s3: 12485 / 15208 (1.22); s4: 8422 / 14220 (1.69) | 10217 (8422-12485) | 14220 (10418-15678) | 1.392 | 1.05-1.69 |
| TN_144_2_13 | no-card | s0: 70 / 82 (1.16); s1: 72 / 73 (1.02); s2: 75 / 78 (1.04); s3: 78 / 82 (1.05); s4: 88 / 295 (3.34) | 75 (70-88) | 82 (73-295) | 1.093 | 1.02-3.34 |
| TN_144_2_13 | card-mto | s0: 68 / 78 (1.15); s1: 73 / 77 (1.05); s2: 73 / 86 (1.19); s3: 327 / 81 (0.25); s4: 71 / 79 (1.10) | 73 (68-327) | 79 (77-86) | 1.084 | 0.25-1.19 |

**Verdict.** TN_216 is a confirmed regression, not seed noise: every one of the 10 seed pairs is slower (1.05-1.69x), and
the seed-median ratios 1.53x (no-card) and 1.39x (card-mto) exceed the 1.25 cell rule. TN_144 stays at 1.08-1.09x
(Tier 3: 1.10 / 1.07), inside the watch band. The PI's instruction was to stop before a PR in this case; the
coordinator then asked for a **draft** adoption PR that states the regression, so that the PI can weigh it against the
Tier 5 gains (MaxSAT solves BB_360 in both modes and LP_1122; BB reaches lb 18 in 15-27 s instead of 696-3028 s).

**Merge with main and Tier 0.** The branch now merges origin/main `123011df` (= e52d15b's solver source plus the HGP
matrix library and its CI; `git diff e52d15b 123011df -- src` is empty): GH-146's `-ub-isd=stern` default, the 17 tier5
stem renames, both flag rows kept. Tier 0 on yfclab2 cores 100-107 (`ADOPT/runner/t0.sh`, `t0b.sh`), for the merge
`bac9d9d` (run on its pre-amend twin `2dc6516`: same source, the amend only removed two stray doc/test lines) and the
adoption commit `0574792` (tested as `f7ad2e8`, the same tree before a message-only amend): build, `make test-cc` (Part G 3600 runs 0 bad, mutants 1 / 2 caught), `make test-cc-flags`
(369 / 376 checks, 0 failed), `scripts/smoke_test.sh` pass; tier0 answers with `-stab-overlap=auto|on|off` x both modes
78/78 equal to the stems; `-v` logs on tier0+1 x both modes vs `frozen/server-main-e52d15b`: merge default and
`-stab-overlap=off`, and adoption `-stab-overlap=off`, 30/30 identical after sorting the two `c ub-pre X/Z` lines of
each block (main itself prints them in either order: 4 X-first / 4 Z-first in 8 runs of TN_36_8_3; raw ident.py
26-28/30, every difference is that order); adoption default = merge `-stab-overlap=auto` 30/30 the same way
(`ADOPT/ident_mod_summary.txt`, `ADOPT/runner/ident_mod.py`). Evidence: `ADOPT/tier0_merge_bac9d9d/`,
`ADOPT/tier0_adopt_f7ad2e8/`.

**Diagnosis of TN_216 (existing logs only, no new runs; `ADOPT/runner/diag_tn216.py`).** Both arms run the same probe
sequence (caps 1, 2, 4, 8, 16, 17 per half; identical up to cap 8, where no TN row is active: |g| = 9, so `auto`
activates a row only at caps >= 2 (4 + 1) = 10). Per probe of caps 16-17, medians over 5 seeds:

| Mode | probe | conflicts cand/main (median, range) | time cand/main (median) | conflicts/s main -> cand (median) | overlap props per conflict | overlap-row conflicts / all conflicts |
|---|---|---|---|---|---:|---:|
| no-card | X cap 16 | 0.94 (0.76-1.18) | 0.95 | 2532 -> 2435 | 0.59 | 0.52 % |
| no-card | Z cap 16 | 1.10 (0.96-1.39) | 1.31 | 2178 -> 1941 | 0.48 | 0.37 % |
| no-card | X cap 17 | 1.02 (0.91-1.07) | 1.06 | 2099 -> 2010 | 0.55 | 0.53 % |
| no-card | Z cap 17 | 1.35 (1.28-1.95) | 1.74 | 1980 -> 1396 | 0.57 | 0.40 % |
| card-mto | X cap 16 | 0.99 (0.87-1.07) | 1.02 | 2526 -> 2456 | 0.54 | 0.53 % |
| card-mto | Z cap 16 | 1.03 (0.80-1.68) | 1.12 | 2156 -> 1974 | 0.49 | 0.41 % |
| card-mto | X cap 17 | 1.05 (0.83-1.10) | 1.16 | 2102 -> 1936 | 0.56 | 0.55 % |
| card-mto | Z cap 17 | 1.25 (1.03-1.56) | 1.56 | 1842 -> 1385 | 0.53 | 0.42 % |

no-card whole run: conflicts cand/main median 1.19 (1.04-1.30); time cand/main median 1.41 (1.15-1.63); per-conflict time cand/main median 1.18

card-mto whole run: conflicts cand/main median 1.10 (0.97-1.31); time cand/main median 1.22 (1.05-1.69); per-conflict time cand/main median 1.17

Readings. (1) The loss is concentrated in the Z-half refutations, above all the final `Z cap 17` NONE proof (lb 17 -> 18):
1.25-1.35x the conflicts and 1.56-1.74x the time; X-half probes are neutral (0.94-1.05x conflicts). (2) The
propagator rarely decides anything: about 0.5 overlap propagations per conflict and 0.4-0.5 % of the conflicts come
from an overlap row. (3) It still costs about 17 % per conflict (conflicts/s 1980 -> 1396 on `Z cap 17` no-card). The
cache of lazily built reason clauses saturates: `cached_clauses` 13608 = 108 rows x C(9, 5) = 126, i.e. the native
propagator ends up carrying the full binomial encoding of every weight-9 row as permanent clauses; on BB_360 (weight 6)
the cache stays at 2685 <= 180 x C(6, 4). The same saturation occurs on TN_180 (11340 = 90 x 126), which gained
(0.59-0.94x at Tier 5), and the overlap-conflict share is similar on winners and losers (TN_180 0.40-0.44 %, TN_216
0.37-0.51 %, BB_360 0.19-0.89 %, from the Tier 5 logs), so neither number alone separates them.

Hypotheses for a gate (next round, not tested):
- **H1, row-weight / cache budget.** Bound the propagator's overhead on heavy rows: for rows whose binomial size
  C(|g|, floor(|g|/2) + 1) is large (TN: 126 vs BB: 15), do not cache reason clauses (rebuild them on demand) or cap
  the cache per row, or raise the `auto` activation ratio for them (e.g. 3 instead of 2 for |g| >= 9: cap >= 15 still
  covers TN_216's 16-17, so the ratio alone may not suffice). Test on TN_216 / TN_180 / TN_468 / TN_144 first, since
  TN_180 and TN_468 gained with the same rows.
- **H2, structural density gate.** Enable the rows per half only when the Tanner 4-cycle density is below the
  `-frontier=auto` threshold (< 3 per row: all bundled BB/GB/LP halves, no TN half). This keeps every BB/LP gain of Tier
  2-5 by construction but gives up TN_180 / TN_468 / TN_684's gains; an lb-level gate (switch off above some lb) does
  not fit the data, since TN_216 loses and TN_180 gains at the same caps (16-17). Logging the time spent in
  `ovPropagate` per probe (to `-frontier-stats`) would give the cost signal an adaptive gate needs.

