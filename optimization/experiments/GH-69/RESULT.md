# GH-69 result — REJECT / NOT ADOPTED
Agent mac-lkskip-20261009, issue #69, draft PR #70, baseline 24572d6, candidate src 40d875f.
Tier0 PASS (check build, 50x4 science sweep, 3000-instance oracle, hosted CI + cross-repo match YES via
ci/xrepo-gh69). Tier1 REJECT: +25.5% OFF / +28.4% MTO, 7/8 cells reproducibly slower.
Learning: in this engine local-tier learnt clauses are what make 7–17% of lookahead conflicts possible;
removing them from lookahead weakens LB, lowers lookahead success, and grows the tree. Lookahead cost
should be reduced without dropping conflict sources (GH-60 lesson again: LB strength dominates).
Process note: draft PRs that conflict with main get no pull_request workflows; cross-repo checks were
dispatched on a one-commit branch (candidate tree parented on the baseline).
