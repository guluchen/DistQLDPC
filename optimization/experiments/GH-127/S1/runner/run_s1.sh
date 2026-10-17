#!/bin/bash
# GH-127 S1 driver on yfclab2 (run from the candidate worktree ~/mac-agent-20261009/gh127-32583fd).
# Tier 5 A (52 cells, cores 64-115) starts together with the tier0-4 seed panel (cores 0-63,116-119 = 68 cores);
# Tier 5 B (52 cells, cores 0-51) starts when the panel has finished. At most 120 pinned cores in use.
set -u
W=$HOME/mac-agent-20261009
BIN=$W/frozen/server-gh127-32583fd/distqldpc
R=$W/results/gh127-s1
RUN=$W/gh127-32583fd/optimization/experiments/GH-127/S1/runner
mkdir -p $R
cd $W/gh127-32583fd
echo "$(date '+%F %T') start; bin $(sha256sum $BIN)" >> $R/driver.log
python3 -u $RUN/s1_tier5.py --bin $BIN --cpus 64-115 --out $R/tier5_A --tag A --flags=-lb-ladder=unit:8 \
    > $R/tier5_A.out 2>&1 &
T5A=$!
python3 -u $RUN/s1_panel.py --bin $BIN --tiers 4 3 2 1 0 --cpus 0-63,116-119 --out $R/panel > $R/panel.out 2>&1
echo "$(date '+%F %T') panel done" >> $R/driver.log
python3 -u $RUN/s1_tier5.py --bin $BIN --cpus 0-51 --out $R/tier5_B --tag B --flags=-lb-ladder=unit:4 \
    > $R/tier5_B.out 2>&1
echo "$(date '+%F %T') tier5 B done" >> $R/driver.log
wait $T5A
echo "$(date '+%F %T') tier5 A done; all done" >> $R/driver.log
touch $R/ALL_DONE
