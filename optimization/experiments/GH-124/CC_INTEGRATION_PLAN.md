# CC integration plan: what DistQLDPC takes from Qubitserf (next optimization round)

- Date: 2026-10-15
- Base: main 398054e (GH-107). The read-only checkout `main-new` is at 9f394bb, which only adds a baselines commit.
- Status: proposal only. Nothing has been implemented, no repository was modified, and nothing was pushed.
- Inputs:
  - `ext/QUBITSERF_REPORT.md`
  - three candidate designs: hybrid, ccfirst, native
  - three judgements: performance, correctness, moat
  - the verification work in progress under `ext/verify/`
- Round ID: GH-1xx, to be registered as an issue. S2a and S2b get their own IDs.

## 0. Plain answer to the PI: "Can we learn from Qubitserf and use it to improve our solver?"

Yes, but what we should take from Qubitserf is its search idea, not its code or its speed.

**Qubitserf as shipped is not faster than our main.** Single-threaded it loses to main on 6 of the 9 tier2-4 codes and solves none of the 26 tier5 codes in 30 minutes.

**What is worth taking is its search skeleton.** This is the Dumer-Kovalev-Pryadko connected-cluster (CC) level search, published in 2017. It searches each CSS half one weight level at a time and grows Tanner-connected clusters. It is exact because a minimum-weight logical is always connected.

**Our prototype adds three things Qubitserf does not have.** The three additions are:

- a disjoint odd-check packing bound;
- sibling exclusion;
- our own verified symmetry: GH-85 orbits used as seeds, and the GH-107 XZ-dual map, which lets us search only one half.

**With these, a roughly 300-line prototype grows about 3x per distance level instead of about 6x.** On one core it:

- solves every tier1-4 code in at most 80 s, which is 10-850x faster than main;
- reproduces our four solved tier5 codes in seconds to minutes;
- claims five new exact tier5 distances. Their upper bounds are independently verified witnesses. Their lower bounds are still being checked.

**The plan.** We write our own CC engine inside DistQLDPC, clean-room and with no Qubitserf code:

- It becomes the exact engine for sparse CSS codes.
- MaxCDCL stays as the fallback for codes where CC is weak (for example toric or surface codes, where every qubit touches only 2 checks), and in a later round it runs alongside CC as the upper-bound engine.
- Every lower bound must be auditable: a trace, a separately written checker, and cross-checks against our own MaxSAT halves.

**Adoption.** Nothing is adopted before Tier 5, and no benchmark stem is renamed before you accept the certification evidence.

**Where the differentiation comes from.** Not from the CC algorithm, which anyone can copy. It comes from four things together, which are much harder to copy:

- the verified combination with our symmetry and duality infrastructure;
- certified lower bounds;
- running MaxSAT alongside CC with sound bound sharing;
- the new results.

## 1. What this round builds on

**Qubitserf `cc`** (MIT, commit ab96b9c):

- It is an exact Dumer-Kovalev-Pryadko (DKP) search.
- It has no budget pruning, no duplicate elimination, no use of symmetry, no witness output and no proof log.
- Its per-level growth is 4.5-6x.
- On tier2-4 it beats main on 3 of 9 codes. On tier5 it reaches lower bounds of only 10-15 in 30 minutes.

**Prototype** (`ext/qs-scripts/cc_proto.cpp`, our own code; adds sibling exclusion, packing and orbit seeds):

- Per-level growth is 2.6-3.8x.
- Tier1-4: at most 80 s on one core.
- Solved tier5 codes, on the Mac: LP_714 in 21 s, LP_1020 in 1.5 s, TN_216 in 595 s, TN_180 in 853 s. The TN_180 run did not use orbits.
- Claimed new values: BB_360 d=24, TN_252 d=21, LP_1054 d=20, LP_1428 d=24, LP_1768 d=22, plus new lower bounds for the 13 other open codes.

**Verification status on 2026-10-15:**

- Upper bounds: all 9 witnesses passed an independent GF(2) check (`ext/verify/witness-gf2/check_witnesses.log`: VALID for each, "ALL OK"). The upper bounds therefore hold.
- Lower bounds: not yet verified. Two clean-room reimplementations are running:
  - `ext/verify/reimpl-A` and `reimpl-B` were written without reading the prototype;
  - reimpl-B takes its orbits from main's own `-symbreak-report`.
- Implementation, orbit and search audits are also running.
- Until these finish, this plan treats the five values and the 13 new lower bounds as **unverified**.

**GH-121** put the packing bound inside MaxCDCL's lookahead.

- It was faster on many codes but lost TN solution finding (TN_216, TN_250 no-card).
- Lesson: do not perturb MaxCDCL's lookahead or its iset memory. Put a structural lower bound outside the engine.

**Main 398054e on Tier 5:**

- It solves 7 of 52 cells.
- The lower bound stalls at 17 or 9, because Phase 1 doubles the cap from 16 to 32 (and from 8 to 16).

**Facts the judges checked against the code:**

- Dual maps are verified for all BB and GB codes, including BB_360, BB_756, BB_864 and BB_1080. No LP or TN code has one.
- All 49 bundled codes pass the CC selector gate (minimum mean qubit degree 2.67, maximum check weight 16).
- A MaxCDCL probe can be sliced only through `asynch_interrupt`: the phase loop at `Solver.cc:6707` ignores `withinBudget`.
- An interrupted optimize probe would be misread as HALF_OPT (`Solver.cc:6861-6865/6887` against `distqldpc.cc:953-955`).
- MaxCDCL's search has no time-dependent logic.

**Basis-row upper bound U0.** U0 is the minimum weight of the Gx and Gz rows. Computed today from `data/matrices/tier5`:

| Code(s) | U0 | Main's ub (unsolved cells) |
|---|---|---|
| TN_252 | 28 | 28, no-card cell only |
| BB_360 | 30 | 24 |
| TN_180 | 20 | 19, card-mto cell only |
| LP_1054 | 26 | none |
| LP_1428 | 42 | none |
| LP_1768 | 74 | none |
| TN_648_10 | 52 | none (52 is already in the stem) |
| Other TN codes | 32-68 | none |
| BB_756 / BB_864 / BB_1080 | 52 / 108 / 66 | none |

Apart from the 7 solved cells, main has an upper bound in only those 4 unsolved cells: BB_360 in both modes, the TN_252 no-card cell and the TN_180 card-mto cell.

## 2. Three proposals

**P1. CC-Ladder Hybrid** (key `hybrid`).

- What: inside the forked child, Phase 1's doubling is replaced by a CC lower-bound ladder for each CSS half. The ladder goes up one weight level at a time and uses packing, exclusion, GH-85 orbit seeds and a single-half search under GH-107. MaxCDCL stays as the upper-bound and witness engine: it runs linear descent probes (cap U-1) and shares the core through a read-only yield hook. One monotone, witness-verified bound writer feeds the unchanged pipe.
- Expected effect:
  - Tier1-4: 10-1000x faster.
  - Tier5: 16 of 52 cells solved, against 7 for main.
  - The anytime lower bound rises in unit steps, and there is an anytime upper bound on every code.
- Risk:
  - Largest first-stage surface: an engine patch, a scheduler and the interrupt trap.
  - The fixed 20% MaxSAT share is overhead on every benchmark cell, up to 1.25x slower than pure CC.
  - Interleaving driven by the clock is harder to test.

**P2. CCX, a CC-first engine** (key `ccfirst`).

- What: a self-contained CC engine becomes the default exact engine for each half of a sparse code. A structural selector (qubit degree, check weight, density) chooses it. Main's MaxSAT path stays byte-identical as the fallback, and later becomes a budgeted upper-bound helper. Lower bounds are made auditable with a canonical trace and an independent checker.
- Expected effect: the fastest option, since there is no MaxSAT share.
  - Same Tier1-4 gains as P1.
  - Widest Tier-5 margins: LP_1428 still solves within 6 h for a server/Mac speed ratio up to about 7.2.
- Risk:
  - Lowest engineering risk, since `src/solver` is untouched.
  - Weakest differentiation story: the algorithm is published, and MaxCDCL is sidelined on every benchmark.
  - No upper bound before the exact level, so the TN_252 no-card ub would go from 28 to '-' unless U0 is emitted.

**P3. ClusterCDCL** (key `native`).

- What: MaxCDCL itself is taught to search like CC:
  - orbit-representative seeds, with orbit closure learned lazily (replacing the GH-85 chain clauses);
  - decisions only on qubits of an odd check;
  - no-goods learned from closed clusters that are not logicals;
  - an incremental packing bound at every node, with GH-121 v2's iset-memory fix;
  - unit cap steps above cap 8.
- Expected effect: the hardest to imitate. By its own estimate, though, it is only 0.2-1.4x of main's time on Tier1-4 and 3-30x slower than native CC. Its Tier-5 lower-bound gains come mostly from the step schedule.
- Risk: the highest of the three:
  - about 2k lines inside the engine;
  - 17 direct unassignment sites that must keep the incremental parity state in sync;
  - GH-121's TN regressions;
  - lower bounds from CDCL reasoning that are not certified;
  - an encoding change that needs PI sign-off;
  - as specified, its `setConfBudget` side probe livelocks.

## 3. Scores and selection

| Lens | P1 hybrid | P2 ccfirst | P3 native |
|---|---:|---:|---:|
| performance | 8 | 8 | 4 |
| correctness / certification | 7 | 8 | 4 |
| moat / maintainability | 8 | 7 | 4 |
| **total (of 30)** | **23** | **23** | **12** |
| ranked first by | performance, moat | correctness | none |

**Selected: P1, the CC-Ladder Hybrid**, built in P2's order.

- P1 and P2 tie on total score. The tie is broken by first-place rankings: P1 is first under two of the three lenses.
- All three judges independently recommended the same staging:
  - first ship the hybrid's `cc-only` mode, which is exactly P2's first stage: a separate module, no engine patch, and a byte-identical MaxSAT fallback;
  - then add MaxSAT co-scheduling as its own round.
- So this round's hypothesis is the CC engine itself. Co-scheduling (S2a) and CC speed work (S2b) are later, separately registered rounds that each re-enter at Tier 0.
- P3 is kept as S3 research. It contributes the step cap schedule for the MaxSAT path and its MW-invariant proof discipline.

**Ideas grafted onto the selected design:**

| Idea | Source | Where |
|---|---|---|
| Verified basis-row upper bound U0 emitted at t=0. It removes ccfirst's only Tier-5 ub regression (TN_252: U0 = 28 = main's ub). | performance judge, hybrid | S1 (PI confirm, §11) |
| Separate module; `src/solver` untouched; `-engine=maxsat` byte-identical to main | ccfirst | S1 |
| `-cc-seed` relabeling of qubits and checks, so a deterministic engine has meaningful 5-seed medians | ccfirst | S1 |
| Mutation tests (no restore of the forbidden set, `>=` instead of `>`, orbit seeds without excluding earlier orbits, stop rule without the lb check) | ccfirst | S0 |
| Double witness check: rowspace test independent of Glog, plus a pi(witness) check under the dual map | ccfirst | S1 |
| Stop rule / hit-level skip: if half A hits at w and half B has lb >= w, then d = w | both | S1 |
| Always-on trap: any lb_h > U, or lb_h > ub_h, gives RESULT -1 and an escalation; plus a startLevel assert | correctness judge, hybrid | S1 |
| A single, monotone, witness-verified bound writer | hybrid | S1 (v1), S2a (v2) |
| HALF_INTERRUPTED classified before ret / lastOptimalCost are read; slicing only through `asynch_interrupt` | hybrid | S2a |
| Read-only yield hook, plus J1 linear upper-bound descent starting from U0 | hybrid | S2a |
| Resumable explicit-stack CC, interleaving the X and Z halves at the candidate hit level (TN_252: about 27G instead of 46G nodes) | performance judge | S2b |
| Canonical event-hash trace, an independent `cc_check`, per-prune certificates for tier0-3 | ccfirst + hybrid | certification track |
| MaxSAT cross-check probes with no initLB taken from CC | correctness judge | S0, S1 |
| Clean-room write with fresh names; DKP citation plus a Qubitserf acknowledgment in NOTICE | moat judge | S0 |
| Unit cap steps above 16, only on the MaxSAT path | native | side round |
| Use TN_180's 36 verified orbits; expectations that account for the process floor | performance judge | §7 |

## 4. Round proposal (policy format)

- **Round:** GH-1xx-S1, "CC-first exact engine for sparse CSS halves".
- **Hypothesis.** For sparse CSS halves, a connected-cluster level search proves lower bounds and finds minimum-weight logicals much faster than MaxCDCL's interleaved bound loop, with scientific semantics unchanged. The search uses the disjoint odd-check packing bound, sibling exclusion, GH-85 orbit seeds and a GH-107 single-half search.
- **Intended change:**
  - a new module `src/cc/`;
  - one dispatch branch in the forked child;
  - a CC driver that emits through the existing pipe.
  - The MaxSAT path and `src/solver` are untouched.
- **Expected effect:** see §7. Briefly:
  - Tier1-4 cells are 10-1000x faster, capped near the 0.018 s process floor on Tier 0-1;
  - Tier 5 goes from 7 to an expected 16 of 52 cells solved (8 of them depend on the lower-bound claims being verified);
  - Tier-5 lower bounds rise from 17 or 9 to about 20-26.
- **Correctness risk.** A rule or implementation bug in CC would give a lower bound that is too high, and therefore a wrong distance. The mitigations are in §8.
- **Prior experiments read:**
  - GH-73 (CSS split), GH-85 (orbits), GH-87 and GH-107 (dual map and lower-bound sharing);
  - GH-121 (packing inside the lookahead; lost TN solution finding);
  - GH-106 (fresh vs incremental solver);
  - TIER4-PROBE;
  - the Qubitserf study.
- **Scientific semantics changed: no.**
  - Unchanged: the same half instances F_h, the same d = min(dX, dZ), the same output lines (`c d_lb`, `c d_ub`, `c d`, `o N`, `c status: TIMEOUT`), and the same timeout behaviour, since the parent's SIGKILL path is untouched.
  - Declared visible differences:
    - one `c d_lb` line per completed level;
    - an initial `c d_ub` from U0 (PI to confirm);
    - `-card-*` flags have no effect on codes routed to CC, so the two mode cells compute the same thing.

## 5. Design of the selected candidate

### 5.1 Process, files, flags

**Process model.** `main()` calls `solve_in_child_fork()` (`distqldpc.cc:1398-1437`), and this is unchanged: the parent, the pipe protocol, the SIGKILL at `-cpu-lim` and the output format stay as they are. Inside the child, the dispatch at `distqldpc.cc:1421-1430` gains one branch:

- `engine = (-engine=auto) ? select_engine(...) : forced value`;
- `maxsat` calls `min_distance_css_interleaved()` unchanged;
- `cc` calls the new `min_distance_css_cc()`.

**New files:**

- `src/cc/cc_half.{h,cc}`: the level search;
- `src/cc/cc_driver.cc`: the level loop, bound algebra and emission;
- `src/cc/cc_trace.cc`;
- `tests/test_cc_engine.cc`;
- `tools/cc_check.cc` (certification track).

**Existing code reused read-only:**

- the matrix loader;
- `find_half_symmetry` (751-782): `orbit_of`, `reps`, the verified generators;
- `find_dual_maps` (988-1019): it additionally stores `perm`, and its report output stays byte-identical;
- `Gf2Basis` (583-617);
- `pipe_bound` (964-969) and `pipe_write_result` (157-166).

**Flags:**

- `-engine=auto|cc|maxsat` and `-engine-report`;
- `-cc=excl,pack,orbf[,mrv,psort,lazy]`;
- `-cc-seed=N`;
- `-cc-trace=PATH`;
- `-ub-basis=on|off`;
- `-seed=N`, the MaxCDCL `random_seed` on the MaxSAT path, needed for main's 5-seed panel.

Existing flags map naturally: `-no-symbreak` means min-index seeds, and `-dualmode=off` means both halves are searched.

**Clean-room rule.**

- `src/cc` is written from §5.2 and DKP 2017, with fresh identifiers.
- `cc_proto.cpp` is used only as a black-box reference for node counts. Its header says it mirrors Qubitserf's `cc.cpp` structure, so its source is not ported.
- NOTICE cites DKP 2017 and acknowledges Qubitserf as a studied reference, with its MIT copyright line.
- MODIFICATIONS.md stays unchanged in S1, because `src/solver` is untouched.

### 5.2 Level search for one half (H = Hpar, L = Glog, level w, precondition lb_h >= w)

**Seeds.**

- With orbits: the orbit representatives r_1 < ... < r_k. For seed r_i, every qubit of the earlier orbits O_1..O_{i-1} is forbidden.
- Without orbits: every qubit s, with all qubits q < s forbidden.

**Node (S included, F forbidden, rem = w - |S|):**

1. If |S| = w: report a hit iff syn(S) = 0 and L·S != 0.
2. If syn(S) = 0: dead end (closed cluster).
3. If some odd check has no candidate: dead end.
4. Greedy disjoint packing over the odd checks, scanned in index order. If the packing size exceeds rem: prune.
5. Branch on the lowest-index odd check. Its candidates are tried in ascending order. Each exhausted candidate joins F for its later siblings (sibling exclusion), and F is restored LIFO when the frame is popped.

**Canonical order.** These choices are pinned so that traces and node counts can be replayed: lowest-index odd check, ascending candidates, packing scanned in index order, and orbits in increasing representative order.

**Cost and memory.** About 100-250 ns per node. Memory is under 20 MB, against caps of 2 GB on the Mac and 4 GB on the server.

### 5.3 Driver policy

**Initial state.**

- U := U0 if `-ub-basis=on` (each basis row is verified as a nontrivial logical of its half), else U := infinity.
- lb_h := 1 for every half.

**Dual map verified** (all BB and GB codes):

- Search only one half.
- Mirror its lower bound to the other half.
- Check pi(witness) in the other half.

**Level loop.** For w = min_h lb_h, ... : for each active half with lb_h <= w < U (the half that was cheaper at the previous level goes first), run level w:

- NONE: set lb_h := w+1. If the global minimum rose, emit `LB`.
- FOUND: double-verify the witness and set U := w. If the other half has lb >= w, then d = w: skip that half's level w (the hit-level skip).

**Termination.** When min_h lb_h >= U: emit `LB U`, then `RESULT U OPTIMAL`, exactly as main does at 1202-1203.

**Traps.**

- startLevel asserts lb_h >= w.
- Any lb_h > U or lb_h > ub_h gives RESULT -1 and an escalation, never a value.

**Selector (static gate).** CC is used iff every existing half satisfies all of:

- mean qubit degree mu_h >= 2.5;
- maximum check weight <= 32;
- n < 64, or mean check weight <= n/8;
- n <= 16384.

Otherwise the code goes to MaxSAT, which is main. All 49 bundled codes go to CC. Toric, surface and dense codes go to MaxSAT; S0d may revise this.

### 5.4 Anytime output

**Lower bounds.** `c d_lb` advances by one per completed level instead of main's doubling sequence 2, 3, 5, 9, 17. Each level is atomic for the lower bound, so a level that is interrupted contributes nothing.

**Upper bounds.**

- `c d_ub` comes from U0 at t=0, then from CC hits.
- Every upper bound is a witness that has been verified twice: H v = 0 and Glog v != 0, then v is not in the rowspace of the same-type stabilizers.
- With `-v`, witnesses are printed as `c witness X|Z: q1 ...`.

**Timeouts.** These are unchanged: the parent kills the child, and the last bounds written to the pipe stand.

### 5.5 S2a co-scheduling (summary)

**Engine patch** (about 40 lines, documented in MODIFICATIONS.md and NOTICE):

- a read-only yield hook in `Solver::search`, polled every 256 decisions;
- an `onSolution` callback;
- an `interrupted()` accessor.

The hook never modifies solver state, so a hooked probe follows the same search path as an unhooked one; only its share of wall-clock time changes. This avoids GH-121's failure mode.

**`run_css_half` changes:**

- classify `HALF_INTERRUPTED` before reading `ret` or `lastOptimalCost`;
- `setBoundsPipe(-1)`, so the engine never writes bounds to the pipe;
- set `random_seed`.

**J1 job.** J1 = a first-solution probe at cap U-1 with initLB = lb_h, alternating between the halves and starting from U0.

**Share policy.**

- J1 runs only when CC's predicted cost for its current level exceeds 10% of the remaining budget, or when U - lb >= 3 after 5% of the budget. Tier1-4 cells therefore never pay the MaxSAT share.
- MaxSAT share is 10% by default, and 50% when packing is weak (b > 4.5, or a prune rate under 1% after 3 levels).
- These thresholds are preregistered from S0 and S1 data before S2a's Tier 5.

**Bound writer v2.** It is the only writer to the pipe, verifies every MaxSAT witness, and keeps the always-on trap: a verified witness lighter than some lb_h gives RESULT -1 and an escalation.

## 6. Staged plan and milestones

### S0: measurement and clean-room engine (default behaviour unchanged)

- **S0a, engine and tests.** `src/cc` with a forced `-engine=cc` mode that uses the existing pipe and output. Tests:
  - a brute-force oracle on random BB and HGP codes, planted-symmetry codes, planted-dual and near-miss codes, and toric codes with L <= 6 (n <= 18-24);
  - every subset of {excl, pack, orbf, mrv, lazy} must give the same verdict;
  - the 4 mutants must fail;
  - every witness must verify.
- **S0b, agreement with the prototype (black box).** Level verdicts and node counts must match the prototype logs (`ext/logs/proto_validate_orbf`, `proto_h2h`) on all 23 tier0-4 codes under the pinned canonical rules. Every difference must be explained.
- **S0c, identity.** `-engine=maxsat` (with the default seed) must give `-v` logs byte-identical to main 398054e on the 14 tier0+tier1 codes x 2 modes, i.e. 28 pairs, as in GH-121 S0.
- **S0d, measurements:**
  - ns per node, per-level growth b, the hit-level share of time, the Z/X cost ratio, the saving from the single-half search;
  - the server/Mac CC speed ratio on BB_288, TN_250 and LP_544 (yfclab2, pinned core);
  - selector calibration on generated toric and surface codes (L = 6..12) and dense codes, comparing CC with packing on, CC with packing off, and MaxSAT;
  - the variance across `-cc-seed` values.
- **S0e, in-repo reproduction of the five tier5 claims** on yfclab2, with traces, plus one rule-diverse configuration each (MRV branching; LP_1054 also without orbits). This is a third independent implementation next to reimpl-A and reimpl-B.
- **Exit gate.** All of the following must hold:
  - all tests pass;
  - verdicts agree on the 23 codes;
  - ns per node is within 1.5x of the prototype;
  - no refutation is open (§9);
  - the §7 expectation table has been rewritten with the S0d ratios and preregistered.
- **Effort:** 4-6 developer-days, about 1 Mac day, and 1-2 server days.

### S1: the round's candidate (`-engine=auto` as default in the candidate binary only)

**Contents:**

- the static selector;
- the CC driver of §5.3: orbit seeds, single half under the dual map, hit-level skip, cheaper half first;
- U0 behind `-ub-basis`;
- the traps and the startLevel assert;
- double witness verification;
- the monotone bound writer v1;
- `-cc-seed`;
- `-cc-trace` v1: per (half, level, seed), node and prune counts, a 64-bit event hash, and the verdict;
- `-engine-report`;
- `-v` witness lines;
- NOTICE update;
- `tests/test_cc_engine.cc`, run forked through the real pipe as in `tests/test_split_dualshare.cc`.

**Evaluation:** Tier 0 to Tier 5 as described in §7.

**Exit:** a Tier-5 pass, plus the certification bundle (§8.5) for any new value, plus PI sign-off. Then:

1. an adoption PR;
2. a baseline refresh (Mac tiers 0-4 and server tiers 0-5);
3. a re-tiering discussion with the PI.

**Effort:** 6-8 developer-days. Evaluation: Mac Tier 0-2 under 1 day, server 5-seed panels for Tier 1-4 1-2 days, and Tier 5 6 h plus queueing.

### S2a: co-scheduling round (new ID, re-enters at Tier 0, only after S1's Tier-5 result)

- **Hypothesis:** running the J1 MaxSAT upper-bound descent alongside the CC ladder in one process tightens anytime upper bounds on open codes, costs at most 1.25x of CC time on tier5, and costs nothing on tier1-4.
- **Contents:** §5.5, plus an interrupt fuzz test, oracle tests forced into the steady phase (warm phase 0, small deterministic quanta), and a deterministic quanta mode used for every test and replay.
- **Effort:** 7-9 developer-days.

### S2b: CC speed round (new ID, re-enters at Tier 0)

- **Search-identical changes:** incremental packing and candidate counters. The S1 canonical trace hashes must stay identical.
- **Interleaving:** the X and Z halves interleaved at the candidate hit level, in node slices on a resumable explicit stack.
- **Optional, each measured separately and default off:** MRV, psort, a pilot-tuned orbit order, and a dynamic handoff to MaxSAT (b >= 5) that carries the CC lower bound as initLB.
- **Effort:** 6-9 developer-days.

### Certification track (parallel, from S1 on)

- **`tools/cc_check`.** An independent checker that shares no code with `src/cc`. It may start from the reimpl-A or reimpl-B code, which was written without seeing the prototype. It:
  - re-derives and GF(2)-verifies the generators, orbits and dual map;
  - replays trace jobs per (half, level, seed[, first child]);
  - compares node counts and hashes.
- **Replay jobs** run on yfclab2, one pinned core and at most 4 GB per job.
- **Per-prune certificates** for tier0-3.

### Side round (small, independent)

Native's step cap schedule (`-phase1=steps:16`), applied **only** on the MaxSAT path: selector fallbacks and `-engine=maxsat`. It helps the anytime lower bound wherever MaxSAT is the engine. It does not touch BB_288 or TN_250, which rely on cheap cap-32 finds.

### S3: research (separate rounds, after adoption)

- Our own verified automorphism discovery: colour refinement plus GF(2) verification, for the 8 TN codes without detected symmetry.
- Stronger packing bounds: fractional or matching-based.
- CC-informed MaxCDCL (P3's ideas), gated by P3's S0 port-versus-CC measurement and its stop/pivot rule.
- VeriPB-style proofs.

### Calendar

- About 2.5-3 weeks to an S1 adoption decision.
- About 6-8 weeks to the end of S2a and S2b.

## 7. Tier 0-5 evaluation plan

**Common rules:**

- Every timing run checks its answer against the stem.
- Mac: at most 2 GB per process, serial timing under `caffeinate -i -s`, at most 10 solver processes, and the timing lock.
- yfclab2: `prlimit --as=4294967296` and one pinned core per process.
- Both card modes are reported separately, even where they compute the same thing.
- The baselines are the recorded main 398054e tables (`optimization/baselines/README.md` for the Mac, `SERVER.md` for the server), plus a drift sample per cell.
- Raw logs go to `optimization/experiments/GH-1xx/raw/`.
- Tier placement follows PR #123: BB_144_14_14 is in tier2, BB_288_12_18 in tier3, and tier4 is TN_250_10_15 only.

**Gates:**

| Gate | Host | Runs / seeds | Limit | Baseline | Pass rule (preregistered) |
|---|---|---|---|---|---|
| Tier 0 | Mac + CI | default seed; all tests in §8.2 | 600 s | stems; Mac table | See the list below the table. |
| Tier 1-2 quick filter | Mac | default seed, 3 serial runs | 1800 s | Mac table + drift sample | Direction consistent with expectations and no cell above 1.25x. A filter only. |
| Tier 1-4 decisive | yfclab2 | 5 seeds per side, run concurrently on pinned cores (`seed_panel.py`). Candidate: `-cc-seed` default and 1-4. Main: the candidate binary with `-engine=maxsat -seed` default and 1-4, proven byte-identical in S0c. | T1-3 1800 s, T4 5000 s | concurrent main panel | For each tier and mode: geomean of median ratios < 1 and no cell above 1.25 (PR #123 default). |
| Tier 5 | yfclab2 | default seed, 1 run per cell, 52 cells at once | 21600 s | SERVER.md (main 398054e) + 2 drift cells (BB_360 lb-17 event, LP_714 card-mto) | Criteria listed below. |

**Tier 0 must show all of the following:**

- 100% correct answers;
- the QDistSAT cross-repo check (LP_136_32_4 and BB_108_8_10, `-no-card` and `-card-mto`) passes with both `-engine=auto` and `-engine=maxsat`, which keeps MaxSAT coverage in CI;
- no severe slowdown.

**Tier 5 criteria:**

- no semantic mismatch;
- all 7 cells that main solves are solved, with the same d;
- the lower bound is at least main's in every cell;
- the upper bound is at most main's wherever main has one;
- new exact values are reported only as "pending certification".

**Expected results.** These come from the prototype, after removing the waste that the S1 driver eliminates. They must be re-scaled with the S0d ratios before preregistration. Mac times; on Tier 0-1 the 0.018 s process floor caps the ratio.

| Tier | Code | main Mac no-card / card-mto (s) | S1 expected (Mac, s) | Expected ratio |
|---|---|---|---|---|
| 0 | 10 codes | 0.017-0.32 | <= 0.03 | 0.1-1.1 (cells at the floor are neutral) |
| 1 | BB_108_8_10 | 0.28 / 0.39 | 0.02-0.03 | ~0.1 |
| 1 | BB_144_12_12 | 0.25 / 0.55 | 0.03-0.05 | 0.05-0.2 |
| 1 | LP_238_44_6 | 0.39 / 0.38 | ~0.02 | ~0.05 |
| 1 | LP_340_56_8 | 1.48 / 1.56 | 0.02-0.03 | ~0.02 |
| 2 | LP_442_68_10 | 32.2 / 20.5 | ~0.03 | <= 0.002 |
| 2 | TN_108_2_12 | 9.6 / 11.0 | ~0.8 | 0.07-0.09 |
| 2 | BB_144_14_14 | 30.3 / 28.2 | 1.3-1.7 (one half) | ~0.05 |
| 3 | GB_144_12_12 | 60.2 / 100.7 | 0.2-0.4 (one half) | <= 0.007 |
| 3 | LP_544_80_12 | 219.5 / 50.8 | ~0.1 | <= 0.002 |
| 3 | TN_144_2_13 | 70.7 / 158.7 | 2.6-3.0 (X level 13 skipped) | 0.02-0.04 |
| 3 | TN_200_10_10 | 13.6 / 10.6 | 0.15-0.35 | 0.01-0.03 |
| 3 | BB_288_12_18 | 303.8 / 377.6 | 1.8-2.2 (one half) | ~0.006 |
| 4 | TN_250_10_15 | 1082 / 985 | 47-56 (no symmetry; X level 15 skipped) | 0.05-0.06 |

**Tier 5 expectations** (server, 6 h, both modes the same under CC). These assume a server/Mac CC ratio of about 2.5, to be replaced by S0d.

| Code(s) | main 398054e server (no-card / card-mto) | S1 expectation | Condition |
|---|---|---|---|
| LP_714_100_16 | 8752 / 5321 s | solved, <= ~60 s | |
| LP_1020_136_16 | 7159 / 8328 s | solved, ~5 s | |
| TN_216_4_18 | 16802 / 18346 s | solved, ~1500-1850 s | |
| TN_180_2_17 | 9837 s / TIMEOUT [17,19] | solved, <= ~2100 s (36 orbits not yet used in the estimate) | |
| BB_360_12_17to24 | TIMEOUT [17,24] both | d=24, ~3.8-4.7 ks (one half) | lower-bound claim holds |
| LP_1054_140_17to32 | TIMEOUT [17,-] | d=20, ~200-250 s | lower-bound claim holds |
| LP_1768_224_ge17 | TIMEOUT [9,-] | d=22, ~820-1000 s | lower-bound claim holds |
| LP_1428_184_ge17 | TIMEOUT [17,-] | d=24, ~7.5 ks (both halves) | claim holds; CC server/Mac ratio <= ~7 |
| TN_252_2_17to28 | TIMEOUT [17,28] / [17,-] | TIMEOUT [20, 28 from U0] | U0 approved |
| TN ge9 group (7) + TN_648_10 | TIMEOUT [9,-] | TIMEOUT [19-21, U0 32-64] | |
| TN ge17 group (6) | TIMEOUT [17,-] | TIMEOUT [21-23, U0 40-68] | |
| BB_756 / BB_864 / BB_1080 | TIMEOUT [17,-] | TIMEOUT [25-26, U0 52/108/66] | |

Expected solved cells: 16 of 52 (main: 7). The 8 cells for BB_360, LP_1054, LP_1768 and LP_1428 depend on the lower-bound verification.

## 8. Correctness safeguards

### 8.1 Proof obligations (written into the code and the experiment record)

**The theorem.** Let F_h = ker(H) \ ker([H; L]), as in `build_css_half`. If d_h >= w and some v in F_h has |v| = w, then the level search returns a hit. The proof:

- A minimum-weight logical is Tanner-connected.
- For a proper subset S of a minimum-weight e, syn(S) != 0. If syn(S) = 0, either S itself or e \ S would be a lighter logical.
- Every odd check holds at least one candidate qubit of e \ S.
- Disjoint packing: p checks need p distinct qubits of e \ S.
- Sibling exclusion keeps F disjoint from e: the first candidate of e that is tried is kept, and only earlier siblings, which are not in e, are excluded.
- Orbit seeds: every minimum-weight logical can be moved by a verified automorphism so that its first-met orbit contains r_i. This holds for **any** orbit order.

**Consequences for the driver.**

- A miss at level w, with lb_h >= w already proven, proves d_h >= w+1.
- Levels must be contiguous from a proven start.

**Additional obligations:**

- `-cc-seed` maps `orbit_of`, the representatives and the witness through the relabeling sigma consistently.
- Any non-default orbit order forbids orbits by orbit index in the chosen order, never by comparing representative labels.
- The explicit stack (S2b) reproduces the recursion's node counts and hashes exactly.
- Seeds come only from per-half automorphisms, never from the dual map pi.

### 8.2 Tests

- **Brute force:** exhaustive enumeration with n up to 18-24 over every rule subset; at least 200 random codes plus planted cases; and the `-cc-seed` values 1-4.
- **Mutation tests:** 4 or more mutants, and every one must fail.
- **Driver tests:** at least 500 instances run through the real fork and pipe. Each must give RESULT = brute force, every LB <= d <= every UB, and a monotone sequence of bounds.
- **S2a only:** interrupt fuzzing (no OPT or NONE classification after an interrupt), and the steady phase forced under the oracle.
- **Identity:** S0c, and `-engine=maxsat` in CI.

### 8.3 Runtime guards (always on)

- Double witness verification: Hv = 0 and Glog v != 0, then v not in the rowspace of the stabilizers (Gf2Basis), plus pi(v) when a dual map is used.
- The startLevel precondition assert.
- The lb_h <= U and lb_h <= ub_h traps, which give RESULT -1 and an escalation.
- The monotone single writer: no non-monotone or unverified line can reach the pipe.

### 8.4 How CC lower bounds are cross-checked

**(a) By our MaxSAT halves, with no CC information.**

- Fresh `run_css_half` probes at a strict cap w, first solution only, with no initLB taken from CC.
- On tier0-3 every level is checked: NONE for every w < d and FOUND at w = d, on both halves.
- On tier4-5 this is feasible only as far as MaxSAT reaches:
  - all levels on TN_250;
  - levels <= 16 on tier5, where main's recorded lb 17 is already a cap-16 NONE proof.
- A disagreement is an escalation in either direction:
  - CC NONE but MaxSAT FOUND (a verified witness) means a CC bug;
  - CC FOUND but MaxSAT NONE means a MaxSAT bug.
- Above cap 16 on tier5, MaxSAT cannot certify within any reasonable budget, and the plan does not pretend it can.
- In S2a, MaxSAT adds a witness-side trap: any verified MaxSAT witness lighter than a CC lb_h stops the run.

**(b) By independent implementations.** A level verdict counts as confirmed when at least two implementations that share no search code agree:

- reimpl-A and reimpl-B, clean-room and already running;
- the in-repo engine (S0e);
- `cc_check` replaying the canonical traces (node count and event hash).

**(c) By rule-diverse re-runs.** Each builds a different search tree:

- no orbits (feasible for LP_1054; for BB_360 and LP_1428, compare orbit and no-orbit verdicts at lower w as an audit of the orbit rule);
- MRV branching;
- both halves searched (`-dualmode=off`);
- `-cc-seed` relabelings;
- a reversed orbit order.

**(d) By known answers.** All 23 tier0-4 stems and the 4 solved tier5 codes, in every timing run.

**(e) Orbit provenance.** CC uses exactly main's `find_half_symmetry` generators, the same ones as the GH-85 clauses. `cc_check` and the orbit audit recompute them independently.

### 8.5 Certification bundle required before any stem rename (PI decision)

- the verified witness, with both checks;
- the in-repo CC result with its trace;
- agreement from at least one clean-room reimplementation;
- a `cc_check` replay, in full or as an audit sample;
- a rule-diverse re-run.

The new tier5 values are reported to the PI as "candidate distances" until the PI accepts this bundle.

## 9. If the ongoing verification refutes the prototype's lower bounds

| Finding | Meaning | Action |
|---|---|---|
| **A verified logical lighter than a claimed d is found** (e.g. weight 23 on BB_360) | A true refutation: some prototype rule or implementation is unsound | See the list below. |
| **The orbit audit finds a generator that does not preserve a half, or orbits that differ from main's** | Orbit seeds are unsound for that code. Main's GH-85 symmetry breaking may be affected too. | Escalate to the PI immediately, as a possible main correctness issue. Disable orbit seeds for that code family in CC. Re-check main's GH-85 answers on the affected codes with `-no-symbreak` where feasible. |
| **A reimplementation disagrees without a witness** (verdicts or node counts differ, and nobody produces a lighter logical) | A bug in one implementation, or different canonical rules | A "hit" without a verifiable witness is treated as a bug in that reimplementation. Node-count differences under the same rules are traced down to the first diverging node. The claim stays "unverified" until resolved, and S1 may proceed on tier0-4, where stems give the ground truth. |
| **Verification is inconclusive** (runs do not finish) | No information | The values stay "unverified prototype claims". S0e and the certification track continue. No stem is renamed. Tier-5 reporting uses "pending certification". |
| **Only the TN_252 claim fails** (it rests on the prototype's 4-thread run, the least validated path) | Most likely a bug in the threaded code path | Drop the TN_252 claim. S1 is single-threaded and is unaffected, provided that S0b and S0e still pass. |

**Actions for a true refutation:**

1. **Freeze the round at S0.** Nothing beyond the S0 measurement code is written.
2. **Escalate to the PI** with the witness. This is a scientific anomaly under AGENTS.md. No stem was ever renamed, so no ground truth is damaged.
3. **Root-cause** with an alive-path diagnosis: replay the failing level with the witness (and its orbit images) as the target, find the first node where the path is cut, and attribute it to a rule (orbit, packing, exclusion, or the closed-cluster rule) or to the implementation. Bisect by switching rules off.
4. **Add the code and witness as a permanent regression test.** Re-run S0a's oracle with the fix.
5. **Decide:**
   - **Implementation bug:** the in-repo clean-room engine must pass the witness test. All prototype-derived numbers (tier1-5 expectations) are re-measured with the fixed rules before anything is preregistered.
   - **Rule unsound in theory:** drop the rule. This should not happen given §8.1, but if it does, the proof has an error and the whole plan is re-reviewed. Re-estimate the growth b.
   - **Gains disappear** (e.g. growth back to about 6x): stop the CC plan and report that to the PI. Fall back to the side round (step schedule plus U0) and to the S3 MaxCDCL research.

## 10. How this answers the PI's goal of solver-level differentiation from MaxCDCL

1. **A second exact engine that MaxCDCL cannot express.**
   - MaxCDCL proves lower bounds by generic cardinality and lookahead reasoning, which discovers parity one check at a time.
   - The CC ladder refutes whole weight levels with a structural, parity-aware packing bound: 50-500x fewer nodes and growth of about 3x per level instead of about 6x.
   - GH-121 showed that this bound cannot simply be pushed into the lookahead without hurting TN solution finding. Keeping it outside the engine keeps MaxCDCL's behaviour intact.
2. **Integration with DistQLDPC's own verified infrastructure.** This is what Qubitserf's distance search does not use:
   - GF(2)-verified per-half automorphism orbits as seeds: 6-18x on LP, 10-16x on BB, 2.3-2.7x on TN;
   - the verified XZ-dual map, so one half suffices: 2x on BB and GB;
   - a sound bound algebra in which only facts about d_h cross between engines, never their symmetry reductions.
3. **MaxCDCL stays a working component.**
   - It is the fallback where packing is weak (toric/surface, dense).
   - In S2a it is the upper-bound engine, running alongside CC on the same core through a read-only hook with no lost work.
   - S3 brings CC structure into MaxCDCL itself, but only behind a measurement gate.
4. **Certified lower bounds.** Witness-verified upper bounds, replayable canonical traces, an independent checker, and per-prune certificates on small instances. Qubitserf, MaxCDCL and main emit no lower-bound certificates.
5. **Results.** If verified: up to 5 new exact tier5 distances, new lower bounds on about 18 open codes, and Tier1-4 speedups of 10-1000x.

**Honest limits.**

- The CC algorithm is published, and the packing bound is about 20 lines. Quantinuum could add it to Qubitserf quickly.
- Qubitserf also ships its own automorphism engine (`codeaut`, Leon/nauty) that it could wire into its distance search.
- Raw speed is therefore not a durable moat by itself.
- The durable part is the verified and certified combination, the results, and the pace of follow-on work:
  - our own automorphism discovery for TN codes without detected symmetry;
  - stronger packing bounds;
  - the S2a co-scheduling;
  - CC-informed MaxCDCL.
- This framing should be confirmed with the PI (§11, item 1).

## 11. PI decisions requested

1. **Approve the round's direction.** A CC-first exact engine becomes the default candidate for sparse codes, with MaxCDCL as fallback and, from S2a, as the upper-bound engine. Please confirm this counts as "deepening our solver" and not "replacing it".
2. **U0.** Emit the verified basis-row upper bound at t=0 (`-ub-basis=on`). The bound is valid, but it adds a `c d_ub` where main prints '-'. It is needed to keep TN_252 no-card at ub 28. Without it, that cell is the one declared ub regression, and the PI decides whether to accept it.
3. **Card modes.** Note that both card modes become the same computation on CC-routed codes.
4. **Re-tiering after adoption.** Tiers 1-4 would empty out and some tier5 codes would leave tier5. This is benchmark methodology, so it is escalated, not done by an agent.
5. **New distances.** Stems are renamed only after the §8.5 bundle and PI acceptance.
6. **NOTICE wording.** Approve citing DKP 2017 and acknowledging Qubitserf (MIT, studied, no code copied).

## 12. Status

- **What changed:** nothing in any repository. This document is the round proposal.
- **Validation performed:**
  - read the report, the designs and the judgements;
  - confirmed the cited line ranges in `main-new`;
  - computed U0 from `data/matrices/tier5`;
  - confirmed that the witness GF(2) log is all VALID.
- **Unresolved:** the prototype's lower bounds are still unverified (reimpl-A/B and the audits are running); the server/Mac CC ratio has not been measured yet (S0d).
- **Scientific semantics changed:** no.
- **PI action required:** yes, the items in §11. None of them blocks starting S0.
