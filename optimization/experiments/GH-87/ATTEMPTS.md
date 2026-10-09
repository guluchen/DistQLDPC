# GH-87 attempts log

1. Candidate `4766d31` (Z half marked absent, GH-73 driver otherwise literal). Mac checks
   (`raw/mac-4766d31-superseded/run1.log`): smoke, partition fixture/oracle PASS; `-joint`
   and `-no-dualskip` traces 6/6 IDENTICAL to 72d1fe1 / GH-73; dual-map checker ALL_PASS.
   yfclab2 Linux: same regressions/traces PASS; science sweep started 19:19 and was stopped
   by this agent after 8 lines (all OK) because the traces revealed the phase-2b re-find
   (PROPOSAL.md Amendment A1); raw files of that attempt kept on yfclab2 in
   `~/mac-agent-20261009/gh87-results/aborted-01/` (not evidence for the amended candidate).
   Note: a `pkill -f` pattern matched the ssh shell itself; the harness and its orphaned
   baseline children were then killed by PID (all owned by this agent).
2. Amended candidate (A1): phase-2b cap U-1 when the Z half is eliminated and the X half
   holds the incumbent. All Tier0 checks rerun from scratch on this source.
