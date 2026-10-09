# GH-85 attempts log

1. Mac Tier0 script run 1 (`raw/mac/run1.log`): `scripts/smoke_test.sh` and the `-v` trace loop
   received binary paths containing spaces unquoted (workspace path "Application Support"), so
   smoke exited 127 and every trace file was an error message (hence "DIFFER", no `o` lines).
   Partition fixture, oracle and per-half automorphism check (quoted path) were valid and passed.
   Not a candidate failure. Fixed by space-free symlinks to the same frozen binaries; run 2
   (`raw/mac/run2.log`) repeated smoke and traces only: all PASS / IDENTICAL.
