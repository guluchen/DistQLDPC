#!/bin/bash
# GH-87 Mac Tier0 checks; serial (1 solver process), waits while TIMING_LOCK exists before each solver step.
L=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
# space-free symlinks to frozen binaries: cand = frozen87/cand (4766d31), base = frozen73n/base (72d1fe1), gh73 = frozen73n/cand (a1585b4)
BIN=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/dualskip/bin
cd "$W/cand87"; O=optimization/experiments/GH-87/raw/mac; mkdir -p $O
wl() { while [ -e "$L" ]; do sleep 30; done; }
echo "start $(date)"; shasum -a 256 $BIN/cand $BIN/base $BIN/gh73
wl; bash scripts/smoke_test.sh $BIN/cand > $O/smoke.txt 2>&1; echo "smoke=$?"
wl; python3 -B scripts/test_partition_soft_literals.py > $O/partition_py.txt 2>&1; echo "partition_py=$?"
c++ -Wno-reserved-user-defined-literal -Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG tests/test_partition_soft_literals.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o build/test_partition_soft_literals
wl; perl -e "alarm 20; exec @ARGV" build/test_partition_soft_literals > $O/partition_oracle.txt 2>&1; echo "partition_oracle=$?"
sh optimization/experiments/GH-87/traces.sh $BIN/base $BIN/gh73 $BIN/cand $O/traces "$L"
wl; sh optimization/experiments/GH-87/reports.sh $BIN/cand $O/dualmaps > $O/dualmaps.log 2>&1; echo "dualmaps=$? $(tail -1 $O/dualmaps.log)"
echo "MAC_DONE $(date)"
