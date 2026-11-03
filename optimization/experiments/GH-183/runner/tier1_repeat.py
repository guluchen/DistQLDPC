#!/usr/bin/env python3
"""GH-183 Tier 1 re-measurement. The Tier 1 cells (LP_340, LP_442) run in 0.02-0.04 s wall with 0.006-0.014 s user time:
the wall time is the process floor, and single runs vary 0.025 <-> 0.035 s between runs of the same binary. Here every
(code, seed, arm) runs REPS times, round-robin over the arms (so that slow phases of the machine hit every arm), on one
pinned core with the 4 GB cap; the cell value per seed is the median over the repetitions, then the median over seeds 0-4
as in the panel. Reports wall and user time ratios vs main and vs tb.
usage: tier1_repeat.py MAIN CAND CORE REPS OUT.jsonl   (from a worktree root)"""
import glob, json, math, os, resource, statistics as st, subprocess, sys, time
MAIN, CAND, CORE, REPS, OUT = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), sys.argv[5]
TB = '-cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak'
ARMS = {'main': (MAIN, []), 'tb': (CAND, [TB]), 'tbmrv': (CAND, [TB + ',mrv']), 'tbmrvbfs': (CAND, [TB + ',mrv', '-cc-roworder=bfs']),
        'tbmrvbfsa': (CAND, [TB + ',mrv', '-cc-roworder=bfs', '-cc-tbbase=asc'])}
codes = [f[:-7] for f in sorted(glob.glob('data/matrices/tier1/*_Hx.txt'))]
recs = []
with open(OUT, 'w') as fh:
    for code in codes:
        for seed in range(5):
            for rep in range(REPS):
                for arm, (b, extra) in ARMS.items():
                    cmd = ['taskset', '-c', CORE, 'prlimit', '--as=4294967296', '--', b, '-engine=cc', '-cc-stats', f'-seed={seed}'] + extra + ['-cpu-lim=60', code]
                    r0 = resource.getrusage(resource.RUSAGE_CHILDREN); t0 = time.monotonic()
                    p = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
                    wall = time.monotonic() - t0; r1 = resource.getrusage(resource.RUSAGE_CHILDREN)
                    ans = [l for l in p.stdout.splitlines() if l.startswith('o ')]
                    rec = dict(stem=os.path.basename(code), seed=seed, rep=rep, arm=arm, wall=wall, utime=r1.ru_utime - r0.ru_utime,
                               rc=p.returncode, o=ans[-1] if ans else None)
                    fh.write(json.dumps(rec) + '\n'); recs.append(rec)
g = lambda v: math.exp(sum(map(math.log, v)) / len(v))
print('| Code | arm | wall: median over seeds of per-seed medians (s) | user (s) | wall ratio vs main | vs tb | user ratio vs main | vs tb | answers |')
print('|---|---|---:|---:|---:|---:|---:|---:|---|')
cell = {}
for code in codes:
    stem = os.path.basename(code)
    for arm in ARMS:
        w = st.median([st.median([r['wall'] for r in recs if r['stem'] == stem and r['arm'] == arm and r['seed'] == s]) for s in range(5)])
        u = st.median([st.median([r['utime'] for r in recs if r['stem'] == stem and r['arm'] == arm and r['seed'] == s]) for s in range(5)])
        cell[(stem, arm)] = (w, u)
    for arm in ARMS:
        w, u = cell[(stem, arm)]; wm, um = cell[(stem, 'main')]; wt, ut = cell[(stem, 'tb')]
        ans = sorted(set(r['o'] for r in recs if r['stem'] == stem and r['arm'] == arm))
        print(f'| {stem} | {arm} | {w:.4f} | {u:.4f} | {w/wm:.3f} | {w/wt:.3f} | {u/um:.3f} | {u/ut:.3f} | {ans} |')
print('\nTier 1 geomean of wall ratios (2 cells):')
for arm in ARMS:
    if arm == 'main': continue
    vm = [cell[(os.path.basename(c), arm)][0] / cell[(os.path.basename(c), 'main')][0] for c in codes]
    vt = [cell[(os.path.basename(c), arm)][0] / cell[(os.path.basename(c), 'tb')][0] for c in codes]
    print(f'  {arm}: vs main {g(vm):.3f} (max {max(vm):.3f}), vs tb {g(vt):.3f} (max {max(vt):.3f})')
print(f'{len(recs)} runs, rc != 0: {sum(r["rc"] != 0 for r in recs)}')
