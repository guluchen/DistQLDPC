# DistQLDPC modifications to upstream code

This document lists changes made for the DistQLDPC project relative to
the embedded MaxCDCL MaxSAT engine (`src/solver/`). Upstream MaxCDCL is
MIT-licensed (see `src/solver/LICENSE`).

**Modifier:** Yu-Fang Chen <yfc@iis.sinica.edu.tw> (2025–2026)  
**Purpose:** QLDPC / CSS code minimum-distance computation via MaxSAT

---

## Application layer (`src/core/`)

New code, not derived from MaxCDCL.

### `src/core/distqldpc.cc`

| Area | Description |
|------|-------------|
| QLDPC encoding | MaxSAT formulation for stabilizer distance (Hx/Hz/Gx/Gz matrices) |
| Fork + pipe | Child runs solver; parent enforces wall-clock timeout (`-cpu-lim`) via `SIGKILL` |
| Bounds sync | Parent reads `TRY` / `LB` / `UB` / `RESULT` lines from pipe |
| Progress output | Default mode prints `c trying d:`, `c d_lb:`, `c d_ub:`, `c d:`, `o` |
| Quiet / debug | Default `verb=0`; child stdout to `/dev/null`; `-v` / `-debug` for solver log |
| CLI flags | `-no-card`, `-card-sinz`, `-card-mto`, `-card-both-force`, `-cpu-lim`, `-q` |
| Matrix path resolution (2026-10-11) | A bare code name resolves to `data/matrices/<code>` if its `_Hx.txt` exists there, else to the first of `data/matrices/tier0` … `tier5` containing it (benchmark matrices are organized in tier subdirectories, see `data/matrices/README.md`); a path containing `/` is used as given |
| Interleaved CSS split (GH-73, PI-approved 2026-10-09, experimental) | Default MaxCDCL path computes d = min(dX, dZ) by a global bound search over the X-type and Z-type halves (doubling feasibility probes, tie-break probes, ordered capped optimisation); only global bounds are forwarded; `-joint` keeps the original encoding |
| Per-half symmetry breaking (GH-85, interaction GH-73 x GH-75, experimental) | Split path only: candidate qubit permutations (GH-75 family) are kept for a CSS half only if GF(2) row-space checks prove they preserve rs(Hpar) and rs([Hpar;Glog]) of that half (plain maps only, no XZ-dual maps); optimum-preserving orbit clauses over the half variables (unit clause for transitive groups, orbit chain otherwise) in every oracle instance of that half. `-no-symbreak` = GH-73 split; `-symbreak-report` prints per-half generators/orbits; `-joint`, dumps and RoundingSat unchanged. See `optimization/experiments/GH-85/`. |
| Dual-half elimination (GH-87, extension of GH-73, experimental) | Split path only: if a qubit permutation (identity or GH-75 generic candidate family) is verified by GF(2) rank/row-space checks to map rs(Hz) onto rs(Hx) and rs([Hz;Gx]) onto rs([Hx;Gz]), then dX = dZ and the global bound search runs on the X half only (its bounds are global). `-no-dualskip` = GH-73 split; `-dualskip-report` prints the verified maps; `-joint`, dumps and RoundingSat unchanged. See `optimization/experiments/GH-87/`. |
| Dual-map bound sharing on the fresh-solver split (GH-107, port of GH-102's sharing to GH-92; experimental) | Split path only: with a verified XZ-dual map (detection as in GH-87), `-dualmode=share` (default) keeps both halves in the interleaved global bound search (fresh solver per probe) and writes every proven half lower bound into both halves (probes whose NONE is implied are skipped; UBs stay global; a shared lower bound above the incumbent refuses to answer). `-dualmode=skip` = GH-87/GH-92 X-half-only search; `-dualmode=off` (alias `-no-dualskip`) = GH-85 split; `-dualshare-stats` prints work counts. See `optimization/experiments/GH-107/`. |
| CC engine switch (GH-124 S0, experimental) | `-engine=maxsat` (default) leaves the search above unchanged (byte-identical `-v` logs); `-engine=cc` runs the connected-cluster level search of `src/cc/` on the same CSS split through the same pipe protocol and output; `-engine=auto` is a structural selector (not the default): CC unless a half's parity matrix has a row of weight > 32 or, for n >= 64, a mean row weight > n/4 (pre-S1 rule; every bundled code goes to CC). `-seed=N` (timing seeds): N > 0 sets `random_seed` of every MaxCDCL solver on the MaxSAT path from the application layer (the engine source is unchanged; N = 0 or no flag keeps main's search byte for byte) and equals `-cc-seed=N` with the CC engine. A CC no-answer stop sends `RESULT -1 TRAP` on the pipe, and the parent withdraws the bounds it had received (MaxSAT never sends it). `find_dual_maps` additionally keeps the verified qubit maps (its report output is unchanged). Flags: `-seed`, `-cc-rules`, `-cc-dual`, `-ub-basis`, `-cc-seed`, `-cc-trace`, `-cc-stats`, `-cc-mutant` and `-cc-schedule` (tests only). Conflicting combinations are rejected (exit 1): CC flags without `-engine=cc\|auto`; `-joint`, `-roundingsat`, the dumps and `-native-parity-opb` with `-engine=cc\|auto`; the cardinality flags and `-dualshare-stats` with `-engine=cc` (`-engine=auto` warns about the flags its choice ignores). See `optimization/experiments/GH-124/`. |
| Redundant-probe skip in the interleaved split (GH-128, experimental) | Split MaxSAT path only, flag `-p1skip=on\|off` (default `on` after the S1 evaluation; `off` = main abd1770's probe sequence byte for byte). With `on`, Phase 1 of `min_distance_css_interleaved` skips a half's feasibility probe when that half's proven lower bound (its own, or the GH-107 shared one) is already >= the global upper bound U, and the search finishes as soon as every existing half has lb >= U (global lb = U), reporting d = U with the usual `c d_lb` / `c d_ub` / `c d` / `o` lines; Phase 2a/2b already skip such halves through their `h.lb >= U` guards (unchanged), so once every half has lb >= U no Phase 2 probe runs either. Soundness: U is the weight of a logical found by an earlier probe, so U >= d = min(dX, dZ). A half H with lb(H) >= U contains no logical of weight < U, so no probe on H can lower U; a FOUND on H returns a weight >= U and a NONE only raises lb(H) further, and d = min(U, d of the other half) is unchanged either way. If every half has lb >= U, then min(dX, dZ) >= U >= d, hence d = U is proven by the bounds already in hand and any further probe is redundant. The skip removes probes only; it adds no probe kind, cap or bound, and every remaining probe runs on a fresh solver with the same inputs (per-instance solver state, GH-73), so the search before the skip point is identical and the reported bounds stay proven and monotone. On main's doubling caps a skip can occur only when the cap-2m feasibility probe finds a logical of weight exactly m+1 = lb (so d is 2, 3, 5, 9, 17, 33, ...). `-v` prints `c p1skip:` lines; `-dualshare-stats` adds a `p1skips` field only when the flag is on. See `optimization/experiments/GH-128/`. |

### `src/cc/` (GH-124, experimental; new code, not derived from MaxCDCL or any third-party code)

Optional engine, off by default (PI 2026-10-16): enable with `-engine=cc` (or `-engine=auto`); `-ub-basis` is on by default inside CC (`-ub-basis=off` disables it). Algorithm: Dumer-Kovalev-Pryadko connected clusters (IEEE TIT 2017); the skeleton was studied in Quantinuum's Qubitserf (MIT), no code copied. DistQLDPC additions and how to switch each one on or off are listed in README, "Connected-cluster (CC) engine".

| File | Description |
|------|-------------|
| `cc_half.h`, `cc_half.cc` | Exact connected-cluster (CC) level search for one CSS half (Dumer, Kovalev, Pryadko 2017): clusters grown from a seed along one odd parity row at a time; syndrome-free clusters below the level are dead ends (a nontrivial one is reported as an inconsistency); rules `excl` (sibling exclusion), `pack` (disjoint odd-row packing bound), `orbf` (orbit seeds from the GH-85 verified per-half orbits, replacing the index rule), `mrv` (fewest-candidate branching); uint64 bitsets with an incremental syndrome; `-cc-seed` relabeling; test-only mutants 1-3 (1 forbidden set not restored, 2 packing prune `>=`, 3 orbit seed rule off by one). |
| `cc_driver.h`, `cc_driver.cc` | Driver: start-up detector check (rank[H;G] + rank S = n and commutation), both halves interleaved level by level (cheaper half first) or one half under a verified XZ-dual map, stop rule (a hit at level w ends the run once the other half's lower bound is >= w), anytime `TRY`/`LB`/`UB`/`RESULT` lines, witness verification (H e = 0, independent GF(2) rank test against the same-type stabilizers, dual image check), its own check of the XZ-dual map (pi(rs Hz) = rs Hx and pi(rs Hx) = rs Hz), always-on traps (`RESULT -1 TRAP`, never a value; earlier bounds withdrawn), optional `-ub-basis`, `-cc-trace`, `-cc-stats`; test-only sequential schedule (`-cc-schedule=sequential`) and driver mutant 4 (stop rule without the other half's lower bound, run under the sequential schedule). |

Tests: `tests/test_cc_engine.cc` (`make test-cc`): brute-force oracle on random halves and random consistent CSS
codes (planted shifts, self-dual codes), every rule subset, relabeling seeds, the forked pipe driver (both
schedules), and the four mutants, each of which must change an answer. `tests/test_cc_flags.sh`
(`make test-cc-flags`): engine flag conflicts and invalid CC flag and `-seed` values are rejected, valid
combinations answer, `-engine=auto` decisions on sparse and generated dense codes, and bound withdrawal after a trap.
The MaxCDCL engine under `src/solver/` is unchanged by GH-124.

Fix round 1 (S0a): the S0 spec's literal mutants 3 ("orbit seeds without forbidding earlier orbits") and 4 ("stop
rule without checking the other half's lower bound") are equivalent mutants as built: the first only drops a
restriction, so every level verdict stays exact; the second skips a check that the lockstep pick order (lowest
lower bound first; a mirrored dual half has lb = w) always satisfies at a hit. Neither could ever change an answer,
so the S0a gate "every mutant must fail" could not be met. Mutant 3 is now the orbit-rule off-by-one (O_1..O_i
forbidden while r_i is searched) and mutant 4 runs under the sequential schedule, where the skipped check matters.

---

## MaxCDCL engine patches (`src/solver/`)

These are modifications to upstream MIT code. Original copyright headers
in each file are unchanged.

### `Solver.h` / `Solver.cc`

#### Retired soft literals after preprocessing partition (GH58)

After partition replaces a conflicting soft set with its existing aggregate
representative, remove inactive entries from both unit and non-unit soft-literal
lists. Previously only the unit list was compacted, allowing initial lookahead
to enqueue `lit_Undef` from a retired auxiliary member. Preserve the existing
representative clauses, derived-cost accounting and surviving order; rebuild
heaps when either list loses members. This is a downstream correctness repair,
not a change to MaxSAT costs or quantum-code distance semantics. See
`optimization/investigations/GH58/` for the original failure and validation.

#### Bounds pipe (search progress → parent process)

- `setBoundsPipe(int write_fd)` — attach write end of pipe
- `emitTryUpdate(uint64_t)` — write `TRY <n>\n` at start of each outer UB iteration
- `emitBoundsUpdate()` — write `LB <n>\n` / `UB <n>\n` on bound changes
- `getCostLB()` / `getCostUB()` — accessors for current bounds
- `hasCostLB()` / `hasCostUB()` — whether bounds are known
- Member: `bounds_pipe_w`

#### Best solution on timeout / interrupt

- `noteBestSolution(uint64_t unsatSoft)` — track improving incumbent
- `printBestSolution()` — print best MaxSAT assignment found so far
- `getLastOptimalCost()` — last proven optimal cost when search completes
- Members: `bestSolutionFound`, `bestSup`, `lastOptimalCost`

#### Cardinality encoding modes

- Enum `CardinalityEncMode`: `OFF`, `BOTH`, `SINZ`, `MTO`, `BOTH_FORCE`
- Member: `cardinalityEncMode` (default `BOTH`)
- `addCardinalityConstraints()` respects mode:
  - `OFF` — soft-conflict only, no Sinz/MTO CNF
  - `SINZ` / `MTO` — single encoding
  - `BOTH` — Sinz if active soft lits ≤ 100, always MTO
  - `BOTH_FORCE` — Sinz + MTO regardless of problem size

#### Solve loop hooks

- Call `emitTryUpdate(UB)` when testing a new upper-bound candidate
- Call `emitBoundsUpdate()` after LB/UB updates
- Call `noteBestSolution()` when a better incumbent is found

#### Multi-instance search controls (GH-73)

- `initLB`, `strictUB`, `startAtCap`, `stopAtFirstSolution`: a known lower bound, a hard cap, starting
  at the cap, and feasibility-only runs, used by the interleaved CSS split
- `boundsLbCap`, `boundsUbCap`, `boundsHideLB`: emitted bounds are capped/suppressed to stay global
- Former function-local `static` heuristic state in `search()`, `lookahead()` and
  `addCardinalityConstraints()` is now per-instance (identical behaviour for a single instance)

---

## Files not modified for DistQLDPC integration

The following are included from upstream with headers intact but without
DistQLDPC-specific functional changes (as of this document):

- `SimpSolver.h`, `SimpSolver.cc`
- `SolverTypes.h`, `Dimacs.h`
- `mtl/*`, `utils/*`
- Legacy entry points: `Main.cc`, `glucose_Main.cc` (not built by root Makefile)

If you add further patches, extend this file and mention them in `NOTICE`.

---

## Contributing patches back to upstream

DistQLDPC-specific integration code (fork, QLDPC encoding, CLI) belongs
in `src/core/` under GPL.

Generic solver improvements that could benefit MaxCDCL users may be
offered to upstream under MIT, consistent with `src/solver/LICENSE`.
