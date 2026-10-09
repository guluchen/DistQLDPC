#!/bin/bash
# Retest builds on yfclab2 (NUMA node 0 only, <= 8 processes, one build at a time).
set -u
T="taskset -c 0-63,128-191"
RT=~/mac-agent-20261009/retest
RES=~/mac-agent-20261009/retest-results
for n in gh34-litvals gh21-o2 gh48-isa-v2 gh20-watch-tail gh64-prefetch h007-lto gh16-pgo; do
  cd $RT/$n || continue
  mkdir -p $RES/$n
  echo "=== $n $(git rev-parse HEAD) start $(date -Is)"
  case $n in
    h007-lto) $T make -j1 LTO=1 > $RES/$n/build.log 2>&1; rc=$? ;;
    gh16-pgo) $T bash scripts/pgo_train_build.sh $RES/$n/pgo-evidence > $RES/$n/build.log 2>&1; rc=$? ;;
    *) $T make -j8 > $RES/$n/build.log 2>&1; rc=$? ;;
  esac
  echo "=== $n build rc=$rc end $(date -Is) $(sha256sum bin/distqldpc 2>/dev/null)"
done
echo ALLDONE
