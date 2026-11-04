cd ~/mac-agent-20261009/gh217-bb3e2ef
F=~/mac-agent-20261009/frozen; M=$F/server-gh217-main-02879a9/distqldpc; C=$F/server-gh217-bb3e2ef/distqldpc; G=$F/server-gh157-c3c315d/distqldpc
busy=$(ps -eo psr,pcpu | awk '$1>=80 && $1<=103 && $2>5 {print $1}' | sort -un | tr '\n' ' '); echo "busy cores 80-103: $busy"
R=~/mac-agent-20261009/gh217-runs/lbauto; mkdir -p $R
python3 - $R/jobs.jsonl $C <<'P'
import json, sys
out, C = sys.argv[1], sys.argv[2]
with open(out, 'w') as f:
    for s in ['TN_648_10_22to32', 'TN_648_14_9to28', 'TN_468_4_17to29', 'TN_496_2_27to30']:
        for arm, extra in [('A', []), ('A-lbauto0', ['-cc-lb-auto=0'])]:
            f.write(json.dumps(dict(id=f'la.{s}.{arm}', bin=C, args=['-engine=cc', '-cc-stats'] + extra, code=f'data/matrices/tier5/{s}', stem=s,
                                    tier='tier5', arm=arm, seed=0, limit=21600)) + '\n')
P
nohup python3 optimization/experiments/GH-217/runner/gh217_queue.py --bin $C --cpus 80,81,83,86-90 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
R2=~/mac-agent-20261009/gh217-runs/speed; mkdir -p $R2
OLDR=-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge
python3 - $R2/jobs.jsonl $M $C $G $OLDR <<'P'
import json, sys
out, M, C, G, OLDR = sys.argv[1:6]
arms = [('gh157-c3c315d', G, [OLDR]), ('main', M, []), ('cand-old', C, [OLDR, '-cc-roworder=index']), ('gh157-c3c315d-b', G, [OLDR])]
with open(out, 'w') as f:
    for arm, b, extra in arms:
        f.write(json.dumps(dict(id=f'sp.TN_360_4_23to24.{arm}', bin=b, args=['-engine=cc', '-cc-stats'] + extra, code='data/matrices/tier5/TN_360_4_23to24',
                                stem='TN_360_4_23to24', tier='tier5', arm=arm, seed=0, limit=2400)) + '\n')
P
nohup python3 optimization/experiments/GH-217/runner/gh217_queue.py --bin $C --cpus 91,93-95 --jobs $R2/jobs.jsonl --out $R2 > $R2/queue.out 2>&1 < /dev/null &
sleep 3; ps -eo psr,args | awk '$2 ~ /frozen\/server-gh/ {print $1, $2, $(NF-1)}' | sort -un | awk '$1>=80'
