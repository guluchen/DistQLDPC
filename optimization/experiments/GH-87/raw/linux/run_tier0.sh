#!/bin/sh
# GH-87 Linux Tier0 (correctness only). Repo root: ~/mac-agent-20261009/cand87 (783527a, amended candidate A1)
R=~/mac-agent-20261009; C=$R/frozen/gh87/cand/distqldpc; B=$R/frozen/gh73n/base/distqldpc; G=$R/gh87-gh73ref/bin/distqldpc; O=$R/gh87-results
cd $R/cand87
echo "== host $(hostname) $(date)"; sha256sum $C $B $G tier0_science.py 2>/dev/null; sha256sum $R/tier0_science.py
mkdir -p $O/regress-linux
bash scripts/smoke_test.sh $C > $O/regress-linux/smoke.txt 2>&1; echo smoke=$?
python3 -B scripts/test_partition_soft_literals.py > $O/regress-linux/partition_py.txt 2>&1; echo partition_py=$?
g++ -Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG tests/test_partition_soft_literals.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o build/test_partition_soft_literals && timeout 20s build/test_partition_soft_literals > $O/regress-linux/partition_oracle.txt 2>&1; echo partition_oracle=$?
sh optimization/experiments/GH-87/traces.sh $B $G $C $O/traces-linux
echo "== science start $(date)"
python3 -B $R/tier0_science.py --base $B --cand $C --out $O/tier0-science-01 --limit 60 --jobs 4 > $O/tier0-science-01.log 2>&1; echo science=$?
tail -1 $O/tier0-science-01.log
python3 -B optimization/experiments/GH-87/posthoc_science.py $O/tier0-science-01/science.json > $O/posthoc.txt 2>&1; echo posthoc=$?
mkdir -p $O/dual-v-linux; for c in BB_90_8_10 BB_108_8_10 GB_144_12_8 BB_144_12_12 GB_144_12_12; do $C -v -cpu-lim=120 $c > $O/dual-v-linux/$c.cand.txt 2>&1; echo "$c $(grep -E "CSS interleave: X half cap [0-9]+ lb [0-9]+ optimize" $O/dual-v-linux/$c.cand.txt) $(grep "^o " $O/dual-v-linux/$c.cand.txt)"; done
echo "== done $(date)"
