#!/usr/bin/env python3
"""GH-231 Tier 0 answer checks on the Mac (correctness only, no timing): runs the 'answers' jobs of make_jobs.py with W
parallel processes (at most 10, per the Mac rule), checks every final answer equals the stem's distance and every c d_lb /
c d_ub line lies on the right side of it, and that no c NATIVE-LB line reports a row-state mismatch.
usage: mac_answers.py JOBS.jsonl OUTDIR W   (from a worktree root)"""
import json, os, re, subprocess, sys, concurrent.futures as cf
jobs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]; out = sys.argv[2]; W = min(10, int(sys.argv[3]))
os.makedirs(out + '/logs', exist_ok=True)
def one(j):
    p = subprocess.run([j['bin']] + j['args'] + [f"-cpu-lim={j['limit']}", j['code']], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    open(f"{out}/logs/{j['id']}.log", 'w').write(p.stdout + p.stderr)
    f = j['stem'].split('_')[3]; d = int(f) if f.isdigit() else None
    o = re.findall(r'^o (\d+)$', p.stdout, re.M)
    lbs = [int(x) for x in re.findall(r'^c d_lb: (\d+)', p.stdout, re.M)]; ubs = [int(x) for x in re.findall(r'^c d_ub: (\d+)', p.stdout, re.M)]
    bad = []
    if not o: bad.append('no answer')
    elif d is not None and int(o[-1]) != d: bad.append(f'answer {o[-1]} != {d}')
    if d is not None and (any(x > d for x in lbs) or any(x < d for x in ubs)): bad.append('bound on the wrong side')
    if re.search(r'state_fails [1-9]', p.stderr): bad.append('row-state mismatch')
    if p.returncode != 0: bad.append(f'rc {p.returncode}')
    return dict(id=j['id'], stem=j['stem'], arm=j['arm'], mode=j['mode'], answer=o[-1] if o else None, ok=not bad, issues=bad)
with cf.ThreadPoolExecutor(W) as ex:
    res = list(ex.map(one, jobs))
with open(out + '/results.jsonl', 'w') as fh:
    for r in res: fh.write(json.dumps(r) + '\n')
bad = [r for r in res if not r['ok']]
print(f'{len(res)} runs, {len(bad)} bad'); [print(r) for r in bad]
