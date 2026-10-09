# GH-60 result — REJECT / NOT ADOPTED (general); mechanism real, net effect search-dependent

| Field | Value |
|---|---|
| Agent / issue / PR | mac-lkprefix-20261009 / #60 / draft #61 |
| Hypothesis | GH-60-A keep the conflict-independent lookahead prefix (B trail saving, C layout control unselected) |
| Baseline / candidate | 24572d6 / production src 2a42eca (tree a0e4cbe6) |
| Reached tier | Tier1 (REJECT); no Tier2/3 |
| Tier0 | PASS: invariant-check build, 50 codes x 4 modes science sweep, 3000-instance exhaustive oracle (post-hoc corrected contract), hosted CI + cross-repo match YES |
| Tier1 | 208/208 correct; OFF geomean 0.939, MTO 0.970; 6 cells -3..-32%, 2 cells +45%/+54%, all non-overlapping and replicated |
| Disposition | REJECT / NOT ADOPTED as a general change |

## Learning for the next agent
1. Full lookahead resets waste work: ~92% of lookahead enqueues are undone, 39–44% are
   re-derivations; keeping the conflict-independent prefix cuts per-lookahead propagation
   10–16% on every Tier1 case, with all correctness checks passing.
2. Any change to lookahead state/order changes which isets are found, and that moves the
   search tree by +-30–40%, swamping the saving. Pure work-saving ideas in lookahead need
   to keep the iset sequence identical (search-preserving), or be judged as heuristics.
3. The direction is case- and mode-specific (GB144 OFF and LP238 MTO regress, the other
   six cells gain, LP340 looked strongly positive informally). Same pattern as GH22 and
   E006: no evidence of a universal gain.
4. Process: freeze binaries outside build trees (one aborted sweep); `maxcdcl` oracle must
   use unit softs and the `optimal:` statistic (GH-22 contract); search-changing
   candidates need a bound-soundness Tier1 runner, preregistered.

## Possible follow-ups (each a new experiment)
- Search-preserving variant: keep the prefix only when the next probes would re-derive it
  in the same order (e.g. replay saved literals in original order before new picks).
- Investigate why GB144 OFF/LP238 MTO grow the tree (iset count/LB distribution per
  lookahead) before any specialization; no silent per-family switching.
