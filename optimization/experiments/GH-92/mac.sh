#!/bin/bash
# GH-92 Mac Tier0 correctness checks (serial, one solver process; no timing).
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
BIN=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/gh92/bin
cd "$W/cand92"; E=optimization/experiments/GH-92; O=$E/raw/mac; mkdir -p $O
echo "start $(date)"; shasum -a 256 $BIN/cand $BIN/gh85 $BIN/gh87 $BIN/base
bash scripts/smoke_test.sh $BIN/cand > $O/smoke.txt 2>&1; echo "smoke=$? $(tail -1 $O/smoke.txt)"
python3 -B scripts/test_partition_soft_literals.py > $O/partition_py.txt 2>&1; echo "partition_py=$? $(tail -1 $O/partition_py.txt)"
c++ -Wno-reserved-user-defined-literal -Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG tests/test_partition_soft_literals.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o build/test_partition_soft_literals > $O/oracle_build.txt 2>&1; echo "oracle_build=$?"
perl -e "alarm 20; exec @ARGV" build/test_partition_soft_literals > $O/partition_oracle.txt 2>&1; echo "partition_oracle=$? $(grep GH58_PARTITION_ORACLE $O/partition_oracle.txt)"
sh $E/reports.sh $BIN/cand $O
sh $E/traces.sh $BIN $O/traces
echo "MAC_DONE $(date)"
