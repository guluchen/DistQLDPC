# GH-60 attempt log (all attempts retained)

## tier0-science-01 — ABORTED by the runner (process error, no results)
The Tier0 science sweep was started against `bin/distqldpc` of candidate 54f5f18
(sha256 06bfa459…). While it ran, I rebuilt the same worktree to add a check-build-only
event counter; `make clean` removed and replaced `bin/distqldpc` (new sha256 225e5423…,
different only through debug line info). The sweep was killed immediately; no comparison
had completed (console empty). Not a scientific result.
Fix: from now on every Tier0/Tier1 binary is copied to a frozen directory outside any
build tree and its SHA256 is checked before and after each run.
