# GH-60 attempt log (all attempts retained)

## tier0-science-01 — ABORTED by the runner (process error, no results)
The Tier0 science sweep was started against `bin/distqldpc` of candidate 54f5f18
(sha256 06bfa459…). While it ran, I rebuilt the same worktree to add a check-build-only
event counter; `make clean` removed and replaced `bin/distqldpc` (new sha256 225e5423…,
different only through debug line info). The sweep was killed immediately; no comparison
had completed (console empty). Not a scientific result.
Fix: from now on every Tier0/Tier1 binary is copied to a frozen directory outside any
build tree and its SHA256 is checked before and after each run.

## fuzz-01 — HARNESS INVALID (oracle contract wrong), retained
Preregistered fuzz used unit AND binary soft clauses and judged the model written to the
result file. Both assumptions were wrong for this engine: (a) `maxcdcl` proves optimality
by ending with rc 20 / `s UNSATISFIABLE` and reports the optimum only in the `optimal:`
statistic (no model), and (b) binary soft clauses are outside the supported fragment
(DistQLDPC emits only unit softs). Result: baseline itself "WRONG" on 827/3000 and
crashing on 549 (cf. #58), candidate statistics essentially identical
(sat-ok 1501 base / 1507 cand / 1508 check). Not a candidate verdict.
Post-hoc correction (disclosed): fuzz2.py, unit soft clauses only, GH-22 `check_pms.py`
oracle contract, new seeds 700000+, same brute forcer.
