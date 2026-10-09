#!/bin/bash
# Retest Tier0 (non-trace part): smoke, partition regression, partition oracle.
# yfclab2, NUMA node 0 only, one candidate at a time.
set -u
T="taskset -c 0-63,128-191"
RT=~/mac-agent-20261009/retest
RES=~/mac-agent-20261009/retest-results
for n in gh34-litvals gh21-o2 gh48-isa-v2 gh20-watch-tail gh64-prefetch h007-lto gh16-pgo; do
  cd $RT/$n; o=$RES/$n; mkdir -p $o
  if [ $n = gh16-pgo ]; then $T make PGO=use PGO_DIR=$PWD/pgo-data bin/maxcdcl > $o/build-maxcdcl.log 2>&1; echo "$n maxcdcl(PGO=use) rc=$?"; fi
  $T bash scripts/smoke_test.sh > $o/smoke.log 2>&1; s=$?
  $T python3 -B scripts/test_partition_soft_literals.py > $o/partition_py.log 2>&1; p=$?
  extra=""; [ $n = h007-lto ] && extra="-flto=1"
  $T g++ -Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG $extra tests/test_partition_soft_literals.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o build/test_partition_soft_literals > $o/oracle_build.log 2>&1; ob=$?
  $T timeout 20s build/test_partition_soft_literals > $o/oracle.log 2>&1; orc=$?
  echo "$n smoke=$s partition_py=$p oracle_build=$ob oracle=$orc bin=$(sha256sum bin/distqldpc | cut -c1-64) maxcdcl=$(sha256sum bin/maxcdcl | cut -c1-64)"
done
echo ALLDONE
