# GH-127 S0: orbit-seed split + unit lower-bound ladder (MaxSAT absorbs CC, step 1)

Issue #127, branch `experiment/gh-127-orbit-split-ladder` from main abd1770. Mac (Apple M6, 12 CPUs), at most
2 solver processes at a time, 2 GB RSS watchdog per process (`scripts/runjobs.py`), every batch under
`caffeinate -i -s`. Single runs, no formal timing: wall times are indicative only; conflicts are the work count.
Candidate binary frozen outside the build tree: `frozen127/distqldpc`
(sha256 `611141de5a17782a9e735c53d1a00de89bb807720899ffbcb09d2fb1cdd37e87`); main: `frozen-main-abd1770/distqldpc`
(sha256 `d5ea7253...c239`).

## 1. What changed

Only `src/core/distqldpc.cc` (plus README / MODIFICATIONS.md). `src/solver` (MaxCDCL) and `src/cc` untouched.
All new behaviour is off by default.

| Flag | Default | Meaning |
|---|---|---|
| `-orbit-split=off\|on\|auto[:K]` | `off` | `on`: every MaxSAT probe (Phase 1 feasibility, Phase 2a tie-break feasibility, Phase 2b optimise) of a half with verified GH-85 orbits O_1..O_k is solved as k fresh-solver subproblems. Subproblem i adds unit clauses x_{r_i} = 1 and x_q = 0 for q in O_1..O_{i-1}, and **no** GH-85 orbit-chain clauses. `auto[:K]`: split only halves with k <= K (default K = 4), else main's orbit-chain clauses. |
| `-lb-ladder=doubling\|unit[:K]` | `doubling` | `unit[:K]`: Phase 1 caps double up to K (default 16; a non-power-of-two K is itself a cap), then K+1, K+2, ... |

Design details:

- **Subproblem order**: orbits by decreasing size, ties by increasing representative (the orbit minimum). The first
  subproblem therefore covers every logical that meets the largest orbit; later subproblems are more constrained
  (more zeroed qubits). On all bundled split codes (BB/GB: 2 orbits of n/2; LP: 34 equal orbits; TN: 36 equal orbits)
  sizes are equal, so the order is by representative.
- **Feasibility**: stop at the first FOUND; NONE only if all k subproblems are NONE.
- **Optimise**: min over subproblems; after an OPT v, later subproblems are capped strictly at v-1, and the loop stops
  when v equals the half's proven lower bound.
- **Per-subproblem lower bounds** `split_lb[i]` (NONE at cap c -> c+1; OPT v -> v; build-time empty -> infinity):
  a subproblem already refuted at the current cap is skipped (`subskips`), and max(half lb, split_lb[i]) is the
  subproblem's `initLB`. A shared GH-107 lb is a lower bound of every subproblem optimum, so it is valid there too.
- **Bounds**: subproblem solver LBs are not half bounds, so every subproblem runs with `boundsHideLB`; after a
  non-hidden call (Phase 2a/2b) the driver emits the half's LB (min over subproblems, capped as main's call would
  be) only if it raises the last emitted LB. UBs from subproblems are real logicals and are emitted as in main.
- If every subproblem is empty at build time the half is empty (main's `HALF_INFEASIBLE`); one empty subproblem is
  only a NONE of that subproblem (`h.exists` is not touched).
- **Composability**: works with `-dualmode=share` (both halves split, lbs shared), `-dualmode=skip` (X half split),
  `-dualmode=off`. With `-no-symbreak` or a trivial verified group there are no orbits: the half keeps main's path
  (`-v` prints `c orbit-split X: no verified orbits (...)`). The flags are MaxSAT tuning flags (refused with
  `-engine=cc` like the cardinality flags) and are refused with `-joint` / `-roundingsat`.
- **Logs** (only when a flag is set): `c orbit-split X: k orbits -> k subproblems ...`, one
  `c orbit-split: ... sub i/k ...` line per subproblem, the half's aggregate `c CSS interleave:` line (main's format
  plus `[orbit-split k subproblems]`), `c lb-ladder: ...`, and with `-v -dualshare-stats` an extra
  `c gh127 stats:` line (subproblem calls / skips).

Soundness argument (also in MODIFICATIONS.md): for any half solution v let O_j be the first orbit (in the split
order) that meets supp(v), q in O_j cap supp(v), and g in the verified group with g(q) = r_j. Verified plain
automorphisms preserve feasibility, nontriviality, weight and every orbit, so g v is a half solution of the same
weight containing r_j and avoiding O_1..O_{j-1}, i.e. a solution of subproblem j. Hence for every w the half has a
solution of weight <= w iff some subproblem has one (OR for feasibility, min for optimise, NONE needs all k). The
split never coexists with the orbit-chain clauses.

### Choice of K for `auto`

- Orbit counts per half (identical for X and Z on every code; `-symbreak-report`):

| k per half | codes |
|---|---|
| 2 (two orbits of n/2) | BB_72, BB_90, GB_144_12_8, BB_108, BB_144_12_12, BB_144_14_14, GB_144_12_12, BB_288 |
| 34 | LP_136 (size 4), LP_238 (7), LP_340 (10), LP_442 (13), LP_544 (16) |
| 36 | TN_72_8_8 (size 2), TN_108 (3), TN_144 (4) |
| none (k = n) | LP_34, TN_36_8_3, TN_36_8_4, TN_54, TN_72_14_4, TN_200, TN_250 |
| random corpus | k = 1 (5 codes), 2 (61), 3 (7), 4 (12), 5 (6), 6 (17), none (12) |

- With k = 34/36 a refutation costs 34-36 fresh solvers. Measured: conflicts x1.6-3.0 on LP_238/LP_340 and
  x1.8-1.9 on TN_108, x2.4 on LP_442 no-card, x1.4-1.9 on TN_144 (the only near-neutral cases are LP_544 and
  LP_442 card-mto). Splitting large-k halves is not worth it.
- For k <= 6 the random corpus (batch 2, n <= 108) gave conflict ratios 0.33-0.39 (geomean) for `on` against
  default; the instances are small (thousands of conflicts).
- K = 4 keeps the per-refutation overhead at most 4 solvers and covers every bundled two-orbit code. No bundled code
  has 3 <= k <= 33, so on the tier sets `auto` = `on` for BB/GB and = default for LP/TN; K could be anywhere in
  2..33 without changing any tier result. K = 4 is a conservative pick. `auto:K` makes it a parameter.

## 2. Default path identity (`S0/identity_vs_main_abd1770.txt`)

`scripts/identity.py`: for each tier0+tier1 code x {`-no-card`, `-card-mto`}, main `-v`, candidate `-v`, candidate
`-v -orbit-split=off -lb-ladder=doubling`, and quiet runs of both.

**28/28 cases: all three comparisons byte-identical on the first try** (main's -v hashes equal the GH-124 S0 records).

Also: `make test-cc-flags` 129/129 checks pass, `scripts/smoke_test.sh` passes, and invalid values
(`-orbit-split=bogus`, `-lb-ladder=unit:0`) and conflicts (`-engine=cc -orbit-split=on`, `-joint -lb-ladder=unit`)
are rejected with exit 1 (`-engine=auto` warns, as for the other MaxSAT tuning flags).

## 3. Correctness

Every run below returned the expected distance (stem distance for tier codes, `-engine=cc` answer for random codes),
except one tier3 timeout (no wrong answer). Commands: `scripts/mkjobs.py` (exact argv in the job files under
`raw/`), each run `distqldpc -v -dualshare-stats CFG MODE -cpu-lim=LIM CODE`.

| set | configs | runs | result |
|---|---|---|---|
| tier0+tier1 (14 codes) x {no-card, card-mto} | on, auto, unit, both, unit:4, on+unit:4 | 168 | 168 PASS |
| tier2 (3 codes) x 2 modes | default, on, auto, unit, both, unit:4, on+unit:4 | 42 | 42 PASS |
| tier0-2 (17 codes) x 2 modes, composability | on+`-dualmode=skip`, on+`-dualmode=off`, on+`-no-symbreak`, on+unit:4+`-dualmode=skip` | 136 | 136 PASS |
| tier3 (5 codes) x 2 modes, `-cpu-lim=1800` | default, on, unit:4, on+unit:4 (+ unit, both on BB_288) | 44 | 43 PASS, **1 TIMEOUT** (BB_288 on, no-card: d_lb 17, d_ub 18, valid) |
| tier1-3 x 2 modes | unit:8 | 24 | 24 PASS |
| random batch 1: 60 codes (qc2, bb, lp, hgp, rnd; n <= 64, d 1-5) x 2 modes | default, on, auto, unit:2, on+unit:2, auto+unit:2 (+ on+skip, on+dualoff, on+nosym, on+unit:4+skip in card-mto) vs `-engine=cc` | 960 + 60 cc | 960/960 equal to CC |
| random batch 2: 45 codes (qc2, bb, lp; n <= 108, d 2-12) x 2 modes | default, on, auto, unit:2, on+unit:2 (+ on+skip, on+nosym, on+unit:4+skip in card-mto) vs `-engine=cc` | 585 + 45 cc | 585/585 equal to CC |
| anytime bounds (quiet runs, live `c d_lb` / `c d_ub` lines) | tier0-2 x 2 modes x {default, on, unit:4, on+unit:4}; random batch 2 x 2 modes x {default, on+unit:2, auto+unit:2} | 406 | 406 OK (§3.2) |

On tier3 the configs `auto`, `unit` and `both` were not all run: by construction `auto` = `on` on BB/GB (k = 2)
and = default on LP/TN (k = 34/36 > 4, or no orbits), and `unit` (K = 16) = default, `both` = `on` whenever d <= 16
(the Phase 1 caps 1, 2, 4, 8, 16 are the same). On tier0-2 these equalities hold exactly in the measured conflict
counts (every code, both modes). BB_288 (d = 18) is the only tier3 code where `unit`/`both` differ, and both were run.

Random corpus (`scripts/gen_random.py`, seeds 127 and 1127, Gx/Gz from `scripts/compute_logicals.py`; matrices in
`raw/random_codes.tar.gz`): qc2 = two-block circulant [A|B], bb = bivariate bicycle, lp = lifted products over Z_L
(3-6 blocks -> 3-6 orbits), hgp = hypergraph product of cyclic codes, rnd = unstructured (no symmetry; fallback
path). 66 of the 105 codes have a verified XZ-dual map (GH-107 sharing active). The subproblem-skip path
(`split_lb`) was exercised in 48 runs (e.g. GB_144_12_8).

### 3.1 BB_288 `on` no-card timeout (anomaly, not a correctness problem)

`raw/logs_key_lines.tar.gz` has the call sequence. Phase 1 is identical in shape (NONE up to cap 16, lb 17 by
sharing). At cap 32 the split subproblem returns a weight-32 logical (main: 26), the tie-break probes return 30
and 28 (main: 24 and 18), so Phase 2b must optimise from cap 28 instead of main's 18. In card-mto the same thing
happens and the optimise call costs 6.6 M conflicts (959 s, 2.5x main). With no-card it did not finish in 1800 s.
A rerun with `-cpu-lim=5400` (`S0/t5400.tsv`) finished: d = 18 after 1875 s (main: 311 s) and 14.07 M conflicts (main: 3.06 M), 13.1 M of them in the Z-half optimise call from cap 28; the run is deterministic (the same call sequence and conflict counts as the 1800 s run up to the cut). Forcing x_{r_1} = 1 changes which feasible solution the solver lands on first; here the first solutions
are much worse. With the unit ladder (`both`, unit:4) the first FOUND is at cap d = 18 and the case finishes
(471/440 s and 508/475 s).

### 3.2 Anytime bounds

`scripts/bounds_check.py` on 406 quiet runs (no `-v`, so the parent prints every live bound change): every
`c d_lb` <= d <= every `c d_ub`, the d_lb sequence never decreases, the d_ub sequence never increases, and the final
answer equals the stem distance / CC answer. Tier0-2: 136 runs (648 d_lb lines), 0 problems. Random batch 2:
270 runs, 0 problems. Default-config runs are included as the reference.

## 4. Work counts (tier1-3, single runs, conflicts and wall)

Cells: total conflicts over all solver calls (x ratio to default) / wall s. TIMEOUT conflicts are the sum of the
completed subproblem calls (lower bound). Main's Mac reference (398054e, 3-run medians) agrees with the default
column within noise (e.g. GB_144_12_12 60/101 s, LP_544 219/51 s, TN_144 71/159 s).

### 4.1 Split and the K = 16 ladder (the configurations named in the issue)

| code | mode | default conflicts (x def) / wall s | on conflicts (x def) / wall s | auto conflicts (x def) / wall s | unit conflicts (x def) / wall s | both conflicts (x def) / wall s |
|---|---|---|---|---|---|---|
| BB_108_8_10 | card-mto | 14553 / 0.449 | 12268 (0.84) / 0.368 | 12268 (0.84) / 0.371 | 14553 (1.00) / 0.445 | 12268 (0.84) / 0.369 |
| BB_108_8_10 | no-card | 11551 / 0.303 | 8555 (0.74) / 0.145 | 8555 (0.74) / 0.149 | 11551 (1.00) / 0.378 | 8555 (0.74) / 0.149 |
| BB_144_12_12 | card-mto | 13722 / 0.601 | 16372 (1.19) / 0.448 | 16372 (1.19) / 0.445 | 13722 (1.00) / 0.585 | 16372 (1.19) / 0.420 |
| BB_144_12_12 | no-card | 9903 / 0.303 | 14868 (1.50) / 0.437 | 14868 (1.50) / 0.448 | 9903 (1.00) / 0.292 | 14868 (1.50) / 0.453 |
| LP_238_44_6 | card-mto | 9630 / 0.442 | 25541 (2.65) / 0.805 | 9630 (1.00) / 0.448 | 9630 (1.00) / 0.448 | 25541 (2.65) / 0.822 |
| LP_238_44_6 | no-card | 10663 / 0.444 | 32459 (3.04) / 0.804 | 10663 (1.00) / 0.448 | 10663 (1.00) / 0.446 | 32459 (3.04) / 0.826 |
| LP_340_56_8 | card-mto | 23422 / 1.700 | 38754 (1.65) / 1.577 | 23422 (1.00) / 1.651 | 23422 (1.00) / 1.651 | 38754 (1.65) / 1.573 |
| LP_340_56_8 | no-card | 20219 / 1.590 | 49427 (2.44) / 1.729 | 20219 (1.00) / 1.583 | 20219 (1.00) / 1.563 | 49427 (2.44) / 1.728 |
| BB_144_14_14 | card-mto | 621318 / 28.791 | 657264 (1.06) / 31.163 | 657264 (1.06) / 31.406 | 621318 (1.00) / 29.004 | 657264 (1.06) / 31.348 |
| BB_144_14_14 | no-card | 658082 / 31.095 | 439198 (0.67) / 20.081 | 439198 (0.67) / 20.149 | 658082 (1.00) / 31.268 | 439198 (0.67) / 20.281 |
| LP_442_68_10 | card-mto | 205669 / 21.013 | 198548 (0.97) / 14.185 | 205669 (1.00) / 21.066 | 205669 (1.00) / 21.106 | 198548 (0.97) / 14.124 |
| LP_442_68_10 | no-card | 291609 / 33.110 | 690041 (2.37) / 76.725 | 291609 (1.00) / 33.247 | 291609 (1.00) / 33.170 | 690041 (2.37) / 76.856 |
| TN_108_2_12 | card-mto | 248276 / 11.310 | 465005 (1.87) / 16.135 | 248276 (1.00) / 11.337 | 248276 (1.00) / 11.350 | 465005 (1.87) / 16.104 |
| TN_108_2_12 | no-card | 207005 / 9.873 | 374205 (1.81) / 12.481 | 207005 (1.00) / 9.880 | 207005 (1.00) / 9.844 | 374205 (1.81) / 12.440 |
| BB_288_12_18 | card-mto | 3680505 / 385.202 | 8091614 (2.20) / 959.681 | n/a | 3689424 (1.00) / 373.943 | 4387645 (1.19) / 440.396 |
| BB_288_12_18 | no-card | 3057085 / 310.677 | 933572+ / 1800.017 **TIMEOUT** | n/a | 3130923 (1.02) / 321.253 | 4663692 (1.53) / 471.462 |
| GB_144_12_12 | card-mto | 1669862 / 103.025 | 1995997 (1.20) / 132.249 | n/a | n/a | n/a |
| GB_144_12_12 | no-card | 1210887 / 61.994 | 2428665 (2.01) / 140.150 | n/a | n/a | n/a |
| LP_544_80_12 | card-mto | 384552 / 51.998 | 390443 (1.02) / 40.998 | n/a | n/a | n/a |
| LP_544_80_12 | no-card | 1420652 / 225.292 | 1362694 (0.96) / 188.296 | n/a | n/a | n/a |
| TN_144_2_13 | card-mto | 2391535 / 161.921 | 3262471 (1.36) / 201.089 | n/a | n/a | n/a |
| TN_144_2_13 | no-card | 1150798 / 72.267 | 2136283 (1.86) / 127.323 | n/a | n/a | n/a |
| TN_200_10_10 | card-mto | 187743 / 10.820 | 187743 (1.00) / 10.750 | n/a | n/a | n/a |
| TN_200_10_10 | no-card | 242100 / 13.960 | 242100 (1.00) / 13.952 | n/a | n/a | n/a |

`n/a` on tier3: equal by construction (see §3): `auto` = `on` for BB/GB and = default for LP/TN; `unit` = default and `both` = `on` for d <= 16.

### 4.2 Smaller ladder thresholds (supplementary)

| code | mode | default conflicts (x def) / wall s | unit4 conflicts (x def) / wall s | unit8 conflicts (x def) / wall s | on_unit4 conflicts (x def) / wall s |
|---|---|---|---|---|---|
| BB_108_8_10 | card-mto | 14553 / 0.449 | 8581 (0.59) / 0.209 | 7044 (0.48) / 0.149 | 9952 (0.68) / 0.211 |
| BB_108_8_10 | no-card | 11551 / 0.303 | 8788 (0.76) / 0.135 | 6986 (0.60) / 0.134 | 6927 (0.60) / 0.148 |
| BB_144_12_12 | card-mto | 13722 / 0.601 | 24640 (1.80) / 0.957 | 22881 (1.67) / 0.890 | 23858 (1.74) / 0.824 |
| BB_144_12_12 | no-card | 9903 / 0.303 | 24659 (2.49) / 0.942 | 22876 (2.31) / 0.964 | 25732 (2.60) / 0.899 |
| LP_238_44_6 | card-mto | 9630 / 0.442 | 9567 (0.99) / 0.442 | 9630 (1.00) / 0.456 | 25308 (2.63) / 0.826 |
| LP_238_44_6 | no-card | 10663 / 0.444 | 7267 (0.68) / 0.369 | 10663 (1.00) / 0.455 | 32029 (3.00) / 0.821 |
| LP_340_56_8 | card-mto | 23422 / 1.700 | 35680 (1.52) / 2.598 | 23422 (1.00) / 1.652 | 75479 (3.22) / 2.462 |
| LP_340_56_8 | no-card | 20219 / 1.590 | 32243 (1.59) / 2.604 | 20219 (1.00) / 1.583 | 91820 (4.54) / 2.609 |
| BB_144_14_14 | card-mto | 621318 / 28.791 | 574748 (0.93) / 27.058 | 572596 (0.92) / 26.950 | 765712 (1.23) / 33.365 |
| BB_144_14_14 | no-card | 658082 / 31.095 | 734094 (1.12) / 33.244 | 731481 (1.11) / 33.076 | 649538 (0.99) / 27.863 |
| LP_442_68_10 | card-mto | 205669 / 21.013 | 107279 (0.52) / 10.950 | 83748 (0.41) / 8.765 | 207371 (1.01) / 10.956 |
| LP_442_68_10 | no-card | 291609 / 33.110 | 115146 (0.39) / 11.827 | 91046 (0.31) / 9.453 | 218589 (0.75) / 10.510 |
| TN_108_2_12 | card-mto | 248276 / 11.310 | 378144 (1.52) / 16.029 | 358866 (1.45) / 15.500 | 707071 (2.85) / 21.517 |
| TN_108_2_12 | no-card | 207005 / 9.873 | 350492 (1.69) / 15.295 | 330784 (1.60) / 14.795 | 697113 (3.37) / 20.944 |
| BB_288_12_18 | card-mto | 3680505 / 385.202 | 4162491 (1.13) / 408.226 | 4161407 (1.13) / 408.277 | 4859147 (1.32) / 474.761 |
| BB_288_12_18 | no-card | 3057085 / 310.677 | 3609733 (1.18) / 356.696 | 3608273 (1.18) / 356.393 | 5133878 (1.68) / 507.737 |
| GB_144_12_12 | card-mto | 1669862 / 103.025 | 255776 (0.15) / 10.401 | 253537 (0.15) / 10.387 | 176981 (0.11) / 7.495 |
| GB_144_12_12 | no-card | 1210887 / 61.994 | 284811 (0.24) / 11.531 | 283026 (0.23) / 11.430 | 196101 (0.16) / 7.699 |
| LP_544_80_12 | card-mto | 384552 / 51.998 | 404850 (1.05) / 53.445 | 384433 (1.00) / 51.138 | 592465 (1.54) / 52.542 |
| LP_544_80_12 | no-card | 1420652 / 225.292 | 409234 (0.29) / 54.935 | 389096 (0.27) / 52.816 | 623446 (0.44) / 54.333 |
| TN_144_2_13 | card-mto | 2391535 / 161.921 | 1852418 (0.77) / 110.676 | 1833112 (0.77) / 109.990 | 2281066 (0.95) / 103.556 |
| TN_144_2_13 | no-card | 1150798 / 72.267 | 1765169 (1.53) / 104.166 | 1745716 (1.52) / 103.475 | 2149008 (1.87) / 94.494 |
| TN_200_10_10 | card-mto | 187743 / 10.820 | 177893 (0.95) / 10.258 | 151465 (0.81) / 8.945 | 177893 (0.95) / 10.260 |
| TN_200_10_10 | no-card | 242100 / 13.960 | 172272 (0.71) / 9.660 | 144893 (0.60) / 8.363 | 172272 (0.71) / 9.604 |

### 4.3 Geomean ratios to default

```
geomean ratio to default over code x mode (timeouts counted at the 1800 s limit; conflicts over solved runs only)
t1 (n=8) | on wall 1.04 confl 1.57 ; auto wall 0.90 confl 1.01 ; unit wall 1.02 confl 1.00 ; both wall 1.05 confl 1.57 ; unit4 wall 1.10 confl 1.16 ; unit8 wall 0.96 confl 1.02 ; on_unit4 wall 1.29 confl 1.96
t2 (n=6) | on wall 1.12 confl 1.33 ; auto wall 0.95 confl 0.94 ; unit wall 1.00 confl 1.00 ; both wall 1.12 confl 1.33 ; unit4 wall 0.86 confl 0.90 ; unit8 wall 0.79 confl 0.82 ; on_unit4 wall 0.94 confl 1.44
t3 (n=10) | on wall 1.51 confl 1.33 ; auto wall 1.45 confl 1.20 ; unit wall 1.00 confl 1.00 ; both wall 1.22 confl 1.27 ; unit4 wall 0.57 confl 0.64 ; unit8 wall 0.55 confl 0.61 ; on_unit4 wall 0.55 confl 0.71
t2+t3 (n=16) | on wall 1.35 confl 1.33 ; auto wall 1.24 confl 1.09 ; unit wall 1.00 confl 1.00 ; both wall 1.18 confl 1.29 ; unit4 wall 0.67 confl 0.73 ; unit8 wall 0.63 confl 0.68 ; on_unit4 wall 0.67 confl 0.92
```

## 5. Findings

- **Orbit split (`on`)**: not promising as a default. It wins on some two-orbit codes (BB_108 0.74-0.84x conflicts;
  BB_144_14_14 no-card 0.67x conflicts and 20 s vs 31 s) and on wall for LP_442/LP_544 card-mto (smaller
  subproblems solve faster per conflict). It loses on GB_144_12_12 (1.2-2.0x conflicts, 1.3-2.3x wall), BB_288
  (2.5x / timeout), every TN code (1.4-1.9x) and LP_238/340 (1.6-3x). Tier2+3 geomean: wall 1.35x, conflicts 1.33x.
  The subproblem with the largest orbit does almost all the work; the others are nearly free (BB/GB: the second
  subproblem, which zeroes the left block, takes 0-300 conflicts). So the split acts mostly as a different (unit)
  symmetry-breaking clause plus a fresh solver, not as a decomposition, and the forced representative often makes
  the first solutions worse (BB_288).
- **`auto` (K = 4)**: = `on` on BB/GB, = default on LP/TN. Tier2+3 geomean wall 1.24x (driven by GB_144_12_12 and
  BB_288). Not promising on the tier sets as they stand.
- **Unit ladder K = 16 (`unit`, `both`)**: identical to doubling for d <= 16, so neutral on tier1-3 except BB_288,
  where it is neutral (1.00-1.02x conflicts) for `unit` and rescues the split (`both` 440/471 s vs `on` 960 s /
  timeout). Its purpose (Tier 5: lb rising 17, 18, 19, ... instead of jumping 17 -> 33) is not measurable on tier1-3.
- **Smaller ladder thresholds are the strongest result of the round**: unit:8 geomean wall 0.63x on tier2+3
  (conflicts 0.68x); unit:4 0.67x. Large wins where main's cap 16 (or 32) feasibility probe finds a poor logical and
  Phase 2 then descends: GB_144_12_12 6.5-10x (103 -> 10 s, 62 -> 11 s), LP_544 no-card 4.3x, LP_442 2.4-3.5x,
  TN_200 1.2-1.7x, TN_144 card-mto 1.5x. Losses where the extra refutations at d-1, d-2, ... cost more than the
  descent: TN_108 1.4-1.6x, TN_144 no-card 1.4x, BB_288 1.06-1.15x, BB_144_12_12 (tiny). on+unit:4 is 0.67x wall but
  0.92x conflicts.
- Suggested next step (not done here, needs a separate round): a 5-seed Tier 1-4 evaluation of `-lb-ladder=unit:8`
  (and unit:4), with `-orbit-split` left off; the split could be revisited only together with the step-2 branching.

## 6. Anomalies and notes

- BB_288 `on` no-card TIMEOUT at 1800 s (§3.1): split-induced poor first solutions, then an expensive optimise; with a 5400 s limit it returns d = 18 after 1875 s (6x main).
- `unit` with the default K = 16 is a no-op on every code with d <= 16 (all tier0-3 codes except BB_288).
- Random corpus distances are small (batch 1 d <= 5, batch 2 d <= 12); the unstructured family has d = 1 (fallback
  path check only). The random work counts are too small to rank configurations.
- Wall times are single runs with two processes in parallel; ratios within ~10% are noise.

## 7. Files

| Path | Content |
|---|---|
| `S0/identity_vs_main_abd1770.txt` | default-path identity record |
| `S0/*.tsv` | per-run summaries (code, cfg, mode, rc, status, d, lb, ub, wall, peak RSS, probes, conflicts, subproblem calls/skips, expected, verdict) |
| `S0/geomeans.txt` | §4.3 |
| `raw/jobs/*.jsonl` | exact job lists (argv) |
| `raw/logs_key_lines.tar.gz` | per-run key lines (`c CSS interleave`, `c orbit-split`, `c dualshare`, stats, bounds, result) |
| `raw/random_codes.tar.gz` | the 105 random codes (Hx, Hz, Gx, Gz) with orbit counts and CC answers |
| `scripts/` | `runjobs.py` (2-slot runner, 2 GB RSS watchdog), `mkjobs.py`, `summarize.py`, `tables.py`, `identity.py`, `gen_random.py`, `bounds_check.py` |
