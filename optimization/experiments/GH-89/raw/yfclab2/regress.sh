set -x
T="taskset -c 0-63,128-191"
O=../gh89-results/regress
$T bash scripts/smoke_test.sh > $O/smoke.txt 2>&1; echo "smoke rc=$?"
$T python3 -B scripts/test_partition_soft_literals.py > $O/partition_py.txt 2>&1; echo "partition_py rc=$?"
F="-Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG"
L="build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz"
$T g++ $F tests/test_partition_soft_literals.cc $L -o build/test_partition_soft_literals > $O/cc1.txt 2>&1 && $T timeout 20s build/test_partition_soft_literals > $O/partition_oracle.txt 2>&1; echo "partition_oracle rc=$?"
$T g++ $F tests/test_incremental_probes.cc $L -o build/test_incremental_probes > $O/cc2.txt 2>&1 && $T build/test_incremental_probes 100000 > /dev/null 2> $O/inc_probes.err; echo "inc_probes rc=$?"
$T g++ $F tests/test_incremental_symbreak.cc $L -o build/test_incremental_symbreak > $O/cc3.txt 2>&1 && $T build/test_incremental_symbreak 100000 > /dev/null 2> $O/symbreak_inc.err; echo "symbreak_inc rc=$?"
echo DONE
