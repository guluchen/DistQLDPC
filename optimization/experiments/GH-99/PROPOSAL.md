# GH-99 PROPOSAL: S0, skip base-satisfied watchers in MaxCDCL lookahead propagation

Issue: https://github.com/guluchen/DistQLDPC/issues/99 (hub #15).
Agent/session: Mac engine-optimization agent, 2026-10-10. Scope: implementation and Tier0 correctness only. Tier1+ timing is run by the coordinator.
Base: GH-95 restructured engine `ae95b17` (search-identical to main `7eadd54`).
Branch: `experiment/gh-99-lk-base-satisfied`.
Written before any engine code was changed.

## Evidence

From GH-98 PROFILE.md (main 7eadd54): lookahead takes 82-85% of runtime. In `propagateForLK`, 28-92% of all
long-watcher visits land on a watcher whose blocker is already true at a level <= `decisionLevel()`, that is, true
before the lookahead round began. The original loop handles such a watcher with exactly one action, `*j++ = *i++`,
so these visits do no useful work.

A counter-only measurement on this base, made before this proposal (30 s runs, same cases as GH-98), checks whether the
skip information can be thrown away after every lookahead call. Here a "base" is one value of
(LOOKAHEAD, trailRecord, decisionLevel):

| case | long visits | base-satisfied | of these, in the first scan of that literal within the same base | scans per literal per base |
|---|---:|---:|---:|---:|
| GB_144_12_12 no-card | 6.64e9 | 6.13e9 (92.4%) | 3.51e9 (57%) | 1.64 |
| LP_544_80_12 card-mto | 4.16e9 | 2.98e9 (71.6%) | 1.46e9 (49%) | 1.92 |
| TN_144_2_13 no-card | 0.155e9 | 0.086e9 (55.7%) | 0.048e9 (56%) | 1.64 |
| LP_340_56_8 no-card | 0.134e9 | 0.037e9 (27.8%) | 0.018e9 (48%) | 1.83 |

**Decision D1.** A scheme scoped to a single lookahead call would recover only about half of the skippable visits,
because a literal is scanned only about 1.6-1.9 times per call. The skip metadata therefore has to stay valid
**across lookahead calls and search steps**, until a level it depends on is undone. That is the level-epoch design
described in the issue.

## Design

### Terminology
- `ws = watches[p]`: the long-clause watch list scanned when `p` becomes true. Binary watches are not touched.
- During lookahead, `D = decisionLevel()` is the base level. Lookahead assigns literals at `D+1`
  (`uncheckedEnqueueForLK`).
- A watcher `w` in `ws` is **base-satisfied** if `value(w.blocker) == l_True` and `level(var(w.blocker)) <= D`.
- **Recorded set** `R_p`: the base-satisfied watchers of `ws` that are currently remembered as skippable.
- Per-literal metadata `M_p = {g, Lmax, stamp}` (plus the variant data below):
  - `g`: copy of the global epoch `lkGlobalEpoch` when the metadata was started.
  - `Lmax`: the highest blocker level in `R_p`.
  - `stamp`: `lkLevelStamp[Lmax]` at the time `Lmax` was last raised.
- `lkLevelStamp[L]` is per decision level. **It is renewed (`++counter`) for every level that `cancelUntil` undoes.**
  `lkLevelStamp[0]` never changes. Renewing on undo rather than on creation also covers code that creates levels
  without `newDecisionLevel()` (`SimpSolver.cc` pushes `trail_lim` directly).
- `M_p` is **valid** iff `g == lkGlobalEpoch && Lmax <= decisionLevel() && lkLevelStamp[Lmax] == stamp`.
  An invalid `M_p` is reset to empty (`R_p = {}`, `Lmax = 0`, `stamp = lkLevelStamp[0]`, `g = lkGlobalEpoch`) the
  next time `propagateForLK` scans `p`. Once `M_p` is invalid it can never become valid again: undoing level `Lmax`
  renews its stamp, and stamps are never reused.

### Variant S0-exact (search byte-identical to 7eadd54): in-place runs
- The watch list is never reordered. `R_p` is a sorted list of runs `(start, len)` of consecutive recorded watchers,
  given in post-compaction positions of `ws`.
- `propagateForLK` scans `ws` as alternating segments and runs. Segments use the original loop body unchanged. For
  a run, the scan does `memmove(j, i, len)` only if earlier compaction left `j < i` (otherwise it just skips ahead),
  writes the run's new start `j - ws`, and advances both pointers by `len`.
- Absorption: while scanning a segment, a watcher that turns out to be base-satisfied is added to the output run list
  at its post-compaction position. This covers the blocker-true fast path and the two paths where the loop rewrites
  `blocker` to a true literal. Adjacent runs are merged. The output run list is written each scan and copied back
  into `R_p`.
- Early stop (conflict or `falseVar`): the original copies the rest of `ws`. Runs after `i` keep their content and
  shift by `-(i - j)`.
- Main `propagate()` compacts `watches[p]` when `p` is assigned in the search, which would move the runs. In exact
  mode it therefore invalidates `M_p` for each `p` it processes (one store per propagated literal). Main propagate
  does about 1/20 of the lookahead volume, so the lost reuse is small.

### Variant S0-fast (search changes through watch order): prefix layout
- `ws` is kept as `[recorded prefix | active suffix]`, with `M_p.plen` = prefix length. `propagateForLK` starts at
  `ws + plen` with `j = i`, so the prefix is never touched and nothing is memmoved.
- Absorption: a base-satisfied watcher found in the suffix is swapped into slot `plen` and `plen++`. The suffix
  watcher previously at `plen` moves to the compaction slot `j`. This reorders active watchers, which is why the
  search changes. It stays sound, because watch order never affects correctness.
- Main `propagate()` and the inprocessing scanners need no special handling here. Every prefix watcher has a true
  blocker (invariant I1), so a scan from position 0 copies the prefix onto itself (`j == i` until after the
  prefix). The global events below still apply.

### Invariants and proof sketch
- **I1 (truth).** While `M_p` is valid, every recorded watcher `w` has `value(w.blocker) == l_True`, with
  `level(var(w.blocker)) <= Lmax`.
  - When `w` is recorded, its blocker is true at level `l <= D`, and `Lmax >= l`.
  - In this engine, a variable assigned at level `l` becomes unassigned only in these ways:
    1. `cancelUntil(L)` with `L < l`. This also undoes level `Lmax >= l`, so `lkLevelStamp[Lmax]` is renewed and
       `M_p` is invalid.
    2. `cancelUntilBeginning`, which removes part of level 0. It bumps `lkGlobalEpoch`.
    3. Resets of a trail suffix starting at `trailRecord`: `lookbackResetTrail`, `simplelookback`, the lookahead
       end-of-round loops, `hardenForRestart`, `hardenFromQuasiSoftConflict`, `detectInitConflicts`,
       `simplelookbackResetTrail`, and `cancelUntilTrailRecord{,1,2}`. These only undo assignments made after
       `trailRecord` by the same procedure. Lookahead and preprocessing assign at `D+1`, which is never recorded
       because recording requires level `<= D`. Inprocessing (vivification and probing at level 0) never runs while
       `propagateForLK` is active, and its scanners and resets bump `lkGlobalEpoch` anyway.
    4. `newAuxiVar` recycling a dynamic variable. It bumps `lkGlobalEpoch` (rare).
- **I2 (immutability and position).** While `M_p` is valid, no recorded watcher is modified. In exact mode each one
  sits exactly at its recorded run position; in fast mode the prefix occupies `[0, plen)`.
  - Watch lists are changed by the following, each covered:
    1. `propagateForLK`: skips recorded watchers and moves runs as whole blocks.
    2. Main `propagate`: exact mode invalidates `p`. In fast mode it only visits prefix watchers via the
       blocker-true branch, by I1, with `j == i`.
    3. `simplePropagate` and `simplepropagateForLK`: bump the global epoch.
    4. `detachClause`, strict or lazy (`smudge` followed by a later `cleanAll` or `clean`): invalidates both lists
       `~c[0]` and `~c[1]` holding the clause's watchers. This covers `removeClause`, `reduceDB*`,
       `removeSatisfied`, `simplify`, `removeLearntClauses`, `reduceClause` (strict detach plus re-attach),
       iset-clause removal, and SimpSolver strengthening.
    5. `relocAll` (garbage collection): bumps the global epoch.
    6. List `clear()`: `newAuxiVar` bumps the global epoch. `SimpSolver::eliminate` runs before search, and
       `solve_()` bumps the global epoch on entry.
    7. `attachClause` and watcher moves (`watches[~c[1]].push`): append only, so existing positions do not change.
- **Equivalence.** In the original `propagateForLK`, by I1 and I2 a recorded watcher takes the blocker-true branch,
  whose only effect is `*j++ = *i++`. It enqueues nothing, conflicts with nothing, pushes nothing and writes no
  clause. Skipping it therefore leaves unchanged both the order of every non-skipped visit and every side effect.
  - In exact mode the run `memmove` writes the same bytes the per-watcher copies would have written, so after every
    scan the watch list is byte-identical to the original's. By induction, all solver state evolves identically,
    and the `-v` trace is byte-identical.
  - In fast mode each single scan produces the same enqueues and conflicts as the original scan on the same list.
    Only the order inside the list differs, which later changes the visit order: same logic, different search
    path.

### Switches
- Runtime mode `lkSkipMode`: 0 = off (the original `propagateForLK` body, verbatim), 1 = exact, 2 = fast.
  - `distqldpc`: `-no-lkskip` (mode 0), `-lkskip=exact`, `-lkskip=fast`.
  - `maxcdcl`: MiniSat option `-lkskip=<0..2>`.
  - The compile-time default `DISTQLDPC_LKSKIP_DEFAULT` decides which variant a binary runs without flags. Frozen
    binaries: `frozen99/exact` (default 1) and `frozen99/fast` (default 2).
- With mode 0, the only extra work is metadata bookkeeping (stamp renewals, invalidation stores), which never feeds
  back into the search. `-no-lkskip -v` is therefore required to be byte-identical to GH-95.
- `-DLKSKIP_SELFCHECK` (debug build) keeps a shadow copy of every literal's recorded watchers. On each later scan it
  checks that each skipped watcher (a) is identical to its shadow (`cref` and `blocker`) and (b) has a true blocker at
  level <= `decisionLevel()`. On a violation it prints `LKSKIP_SELFCHECK_FAIL` and aborts.
- `-DLKSKIP_STATS` (counter build) prints per-solve counters to stderr: long-watcher visits actually examined,
  skipped watchers, level checks, memmoved watchers, scans, and resets. Mode 0 counts the original loop, so a
  before/after comparison uses the same binary.

## Tier0 plan
1. Smoke, `scripts/test_partition_soft_literals.py`, and the `tests/test_partition_soft_literals.cc` oracle
   (`GH58_PARTITION_ORACLE_PASS cases=80`).
2. Self-check build, modes 1 and 2: 0 failures over 50 codes x {default, -no-card, -card-sinz, -card-mto},
   `-cpu-lim=20`.
3. `-no-lkskip -v` vs frozen95, 50 x 4, with the GH-95 rule: completed runs byte-identical, timed-out runs
   prefix-identical, only `detect_cpu` normalised (`GH-95/cmp_traces.py`).
4. S0-exact default `-v` vs frozen95: same rule, 50 x 4.
5. S0-fast: `tier0_science.py` sweep (50 x 4, 60 s, `--jobs 4`) vs main 7eadd54, with zero unsound bounds; maxcdcl
   fuzz oracle on a few hundred random unit-soft WCNFs, with the same `optimal:` as the GH-95 maxcdcl.
6. Work counts (informational) with the counter build at `-cpu-lim=30`: GB_144_12_12 no-card, LP_544_80_12 card-mto,
   TN_144_2_13 no-card, LP_340_56_8 no-card.
7. Cross-repo QDistSAT benchmark on `ci/xrepo-gh99`.

## Risks
- **Bookkeeping cost versus savings.**
  - Exact mode pays for run `memmove`s once compaction has started, plus rewriting the run list on every scan.
  - Both modes pay one extra `vardata` load (a level check) per non-recorded true-blocker visit, for absorption.
  - On LP_340-type cases, about 35% of visits are true blockers at the lookahead level. These pay the level check
    without being skippable. If work counts suggest a net loss, absorption can be limited, for example to the
    first scan after a reset. Wall-time is decided by the coordinator's Tier1.
- **Staleness.** As the search goes deeper, more watchers become base-satisfied. Absorption on every scan handles
  this, but it raises `Lmax`. A backtrack below `Lmax` then drops the whole `R_p`, including entries from shallow
  levels. Per-level segments would fix that, at more bookkeeping cost; this is not planned unless the counts show
  frequent resets.
- **Fast-mode search drift.** Fast mode changes the search through watch order. As in GH-60, the effect on Tier1 may
  be noisy in both directions, so fast mode is delivered as a secondary variant only.
- **Memory.** About 32 bytes of metadata per literal plus run vectors (exact mode), which is negligible next to the
  watch lists.
- **Missed invalidation site.** This is guarded by the self-check build over all 200 code x mode runs, and in exact
  mode also by byte-identical traces, which turn any missed site into a trace diff.
