# GH-69 preregistration: lookahead ignores LOCAL-tier conflict-learnt clauses

Owner/session `mac-lkskip-20261009` (same Mac-host agent; round 4 after #34 INCONCLUSIVE, #60 REJECT, #67 REJECT; continuing per the user's instruction). Hub #15. Immutable baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`; not stacked. Hypothesis IDs GH-69-A/B/C. Host: Apple M6 Mac (user-authorised, sole runner); diagnostic, not controlled. Layout-noise floor on this host (#67): 0.2–0.4% per cell, GB144 OFF up to 2.1%.

## Evidence before proposing (baseline, scratch-only counters, no timing)
Split of `propagateForLK` work by clause kind (weighted cost = watcher visit + 3 x clause load + literal scan), 4 Tier1 cases x OFF/MTO:
- Conflict-learnt clauses currently in the LOCAL tier: **20–41% of lookahead cost** (27–57% of watcher visits), but only **0.16–0.36% of lookahead implications** and **6.8–16.7% of lookahead conflicts**.
- Original clauses: 97–99% of implications. Hardening / Sinz / iset clauses (also allocated LOCAL-marked): ~1% of cost.

## Three proposals (ranked)
**A (SELECTED) — lookahead ignores LOCAL-tier conflict-learnt clauses.** One header bit (`lkskip`, taken from the 24-bit LBD field, copied on relocation) is set only on clauses created by conflict learning (`analyze` path, `fixByLookahead`, the shortened-clause path at line ~3134). In `propagateForLK` only, a watched clause with `lkskip && mark()==LOCAL` is left untouched (watcher kept, no literal scan, no move, no implication/conflict). Clauses promoted to TIER2/CORE are used again automatically (mark changes); hardening, cardinality, iset and original clauses are never skipped. Main `propagate`, simple* lookahead and all learning/reduction are unchanged. Soundness: lookahead UP over a subset of valid clauses only weakens it; every inconsistent subset found is still a valid UP refutation, so lower bounds stay sound; lookahead assignments are always undone, so the skipped clauses' watch invariants hold again at real decision levels. Search CHANGES (some lookahead conflicts are lost -> possibly weaker LB and larger trees, the #60 risk). Origin: measurement-driven; related to watch-list prioritisation in B. Kaiser, R. Clausecker, M. Mavroskoufis, "Prioritised Unit Propagation by Partitioning the Watch Lists", PoS 2023, CEUR-WS Vol-3545 paper 2, and the core-first idea in J. Chen, "Core First Unit Propagation", arXiv:1907.01192 (prefers LBD<=7 clauses). Adapted, not copied: we drop the local tier from lookahead entirely rather than reorder.
**B (unselected) — prioritised instead of skipped**: separate watch lists so lookahead scans local learnts only after the rest is exhausted (closer to PriPro); avoids clause loads entirely but needs a second watch structure, tier-move bookkeeping and changes main-propagation order. Multi-day.
**C (unselected) — remove the parent's 10 ms polling latency** (`usleep(10000)` loop): blocking wait on the bounds pipe with the remaining deadline as timeout; search-identical, saves ~5 ms per run on average (0.2–0.75% on Tier1), at or below this host's noise floor.

Escalations for the PI, not implemented (listed for the joint adoption discussion): (i) code-automorphism symmetry breaking (#67-C); (ii) solving the CSS X-type and Z-type distances as two smaller instances (d = min(dX, dZ) for CSS codes): a formulation change of the MaxSAT encoding and bound reporting.

## Validation (preregistered in PROPOSAL.md)
Tier0 like #60: build/smoke; check build asserting skipped clauses are never reasons/conflicts in lookahead and watch invariants hold after each lookahead; 50 codes x 4 modes science sweep at 60 s (named distances, bound soundness, no candidate-only failures); 3000-instance unit-soft brute-force oracle (GH-22 contract); hosted CI + cross-repo. Tier1: 3+3 AB/BA/AB + 10 replication pairs with the bound-soundness runner from #60, unchanged GH16 judge. No Tier2 if any confirmed regression.

## Exact parameters (fixed before implementation)
- Binaries frozen read-only outside build trees before any run (lesson from GH-60).
- Check build `-DLKSKIP_CHECK`: in lookahead conflict analysis assert no reason/conflict clause has
  lkskip&&LOCAL; after each lookahead() return assert trail.size() <= trailRecord-at-entry... (all
  lookahead literals undone) and count skipped visits (exit handler, via `maxcdcl` on Tier1 dumps).
- Science sweep: GH-60 `tier0_science.py`, 60 s, 4 jobs. Oracle: GH-60 `fuzz2.py` (unit softs,
  GH-22 contract), 3000 instances, seeds 800000+.
- Tier1: GH-60 `tier1_mac_dist.py` (bound soundness instead of line identity), gate 3+3 + 10
  replication pairs. Unchanged GH16 judge; regression => REJECT, no Tier2.
