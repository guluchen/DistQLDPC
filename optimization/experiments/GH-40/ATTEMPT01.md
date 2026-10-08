# GH40 first Tier0 attempt: engineering INCONCLUSIVE

Assignment6067129925 / support35bdff71800c38db48b1f7c9501b8a6a0c5e14d7 /
driver521f5b585c84b578659e7970384e93be4df1bc92142cc77217c8ce9ed39997fa /
session42919 exited1. Original baseline full build/debug Solver/first release
ternary fixture build succeeded. That fixture emitted10 complete cases then
failed its setup assertion `one target watcher`; no candidate build/fixture,
scientific solve, opportunity diagnostic or performance run occurred.

Cause: deleted-prefix fixture removes a clause, intentionally leaving its marked
watcher in the dirty list until production propagateForLK.cleanAll. The setup
then tried to change the current watcher's blocker while incorrectly asserting
the entire dirty vector contained exactly one watcher. This is fixture misuse,
not an observed scientific mismatch or proof of a candidate defect.

Original runner summary marked generic fixture failure SCIENCE REJECTED. Those
exact raw bytes are retained unchanged; independent AUDIT.json corrects the
experiment interpretation to ENGINEERING_INCONCLUSIVE and explains the cause.
Nothing is silently overwritten or promoted. Actual CPU14/sibling15/mask16384,
priority32768; only runner25572 beforeclose and absent afterward. All4 actual
restoration flags true/finalmask65535/Normal32; source/input/support/runtime
postpins passed. Released hub6067190706 before any repair/retention.

Source-only fixture repair locates exactly one watcher with the target CRef,
changes only that blocker's value and permits intentional pending dead entries.
Production17line specialization unchanged. Driver is disabled again. An explicit
FAIL/rc2 fixture oracle/setup failure now demands engineering review rather than
automatic scientific rejection; non-oracle crashes/state mismatches remain
STOP REJECT. A valid actual scientific mismatch is still an immediate rejection.

Original full raw/source/object/binary archive and all hashes retained under
raw/windows-attempt-01. Retried tests require fresh named assignment and fresh
output; no retry or performance promotion from this failed attempt.
