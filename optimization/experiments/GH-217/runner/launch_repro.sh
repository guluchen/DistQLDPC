cd ~/mac-agent-20261009/gh217-bb3e2ef
F=~/mac-agent-20261009/frozen; R=~/mac-agent-20261009/gh217-runs/repro; mkdir -p $R
M=$F/server-gh217-main-02879a9/distqldpc; C=$F/server-gh217-bb3e2ef/distqldpc
: > $R/jobs.jsonl
for s in TN_468_4_17to29 TN_612_2_17to40 TN_648_14_9to28 TN_684_2_9to29; do
  code=data/matrices/tier5/$s
  echo "{\"id\": \"xc.$s.A.s1\", \"bin\": \"$C\", \"args\": [\"-engine=cc\", \"-cc-stats\", \"-seed=1\"], \"code\": \"$code\", \"stem\": \"$s\", \"tier\": \"tier5\", \"arm\": \"A-seed1\", \"seed\": 1, \"limit\": 30000}" >> $R/jobs.jsonl
  echo "{\"id\": \"xc.$s.main.s2\", \"bin\": \"$M\", \"args\": [\"-engine=cc\", \"-cc-stats\", \"-seed=2\"], \"code\": \"$code\", \"stem\": \"$s\", \"tier\": \"tier5\", \"arm\": \"main-seed2\", \"seed\": 2, \"limit\": 30000}" >> $R/jobs.jsonl
done
nohup python3 optimization/experiments/GH-217/runner/gh217_queue.py --bin $C --cpus 72-79 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
sleep 3; ps -eo psr,args | awk '$2 ~ /server-gh217-/ {print $1, $NF, $(NF-1)}' | sort -u
