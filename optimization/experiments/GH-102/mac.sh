#!/bin/bash
# GH-102 Mac Tier0 correctness checks (serial, one solver process at a time; no timing claims).
# Every command runs under the PI-mandated 2 GB per-process(-group) cap via capped.py (memlimit.run).
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
BIN=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/gh102/bin
cd "$W/cand102"; E=optimization/experiments/GH-102; O=$E/raw/mac; mkdir -p $O
K="python3 -B $E/capped.py"
CF="-Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG"
OBJS="build/SimpSolver.o build/Solver.o build/Options.o build/System.o"
echo "start $(date)"; shasum -a 256 $BIN/cand $BIN/gh89 $BIN/gh94 $BIN/main7e $BIN/base72 bin/distqldpc
echo "smoke $($K $O/smoke.txt 1200 bash scripts/smoke_test.sh $BIN/cand) $(tail -1 $O/smoke.txt)"
echo "partition_py $($K $O/partition_py.txt 1200 python3 -B scripts/test_partition_soft_literals.py) $(tail -1 $O/partition_py.txt)"
c++ -Wno-reserved-user-defined-literal $CF tests/test_partition_soft_literals.cc $OBJS -lz -o build/test_partition_soft_literals > $O/oracle_build.txt 2>&1; echo "oracle_build=$?"
echo "partition_oracle $($K $O/partition_oracle.txt 60 build/test_partition_soft_literals) $(grep GH58_PARTITION_ORACLE $O/partition_oracle.txt)"
for t in test_incremental_probes test_incremental_symbreak test_incremental_dualshare; do
  c++ -Wno-reserved-user-defined-literal $CF tests/$t.cc $OBJS -lz -o build/$t > $O/$t.build.txt 2>&1; echo "$t build=$?"
  # stdout (engine log) is discarded by the test's own redirection inside capped.py's capture; the verdict is on stderr
  echo "$t $($K $O/$t.20000.txt 7200 bash -c "./build/$t 20000 2>&1 >/dev/null") $(tail -1 $O/$t.20000.txt)"
done
echo "mutants:"; TMPDIR=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad bash $E/mutants.sh 2000 $O/test_incremental_dualshare.mutations.txt
bash $E/reports.sh $BIN/cand $BIN/gh94 $O
bash $E/workcounts.sh $BIN/cand $O/workcounts
bash $E/traces.sh $BIN $O/traces
echo "MAC_DONE $(date)"
