#!/usr/bin/env python3
"""GH-217 interleaved re-measurement (from GH-206 tier1_repeat.py) for floor-dominated cells (Tier 0/1) and short Tier 5
cells. Every (code, seed, rep) runs the arms main, A, B round-robin (so that slow phases of the machine hit every arm) on one
pinned core with the 4 GB cap; the value per (code, seed) is the median over the repetitions, then the median over seeds.
usage: rep.py MAIN CAND CORE REPS SEEDS LIMIT OUT.jsonl STEM...   (from a worktree root; SEEDS = 1 means the default seed only)"""
import glob, json, math, os, resource, statistics as st, subprocess, sys, time
MAIN, CAND, CORE, REPS, SEEDS, LIMIT, OUT = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5]), sys.argv[6], sys.argv[7]
ARMS = {'main': (MAIN, []), 'A': (CAND, []), 'B': (CAND, ['-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak'])}
recs = []
with open(OUT, 'w') as fh:
    for stem in sys.argv[8:]:
        code = glob.glob(f'data/matrices/*/{stem}_Hx.txt')[0][:-7]
        for seed in range(SEEDS):
            for rep in range(REPS):
                for arm, (b, extra) in ARMS.items():
                    cmd = ['taskset', '-c', CORE, 'prlimit', '--as=4294967296', '--', b, '-engine=cc', '-cc-stats'] + \
                          ([f'-seed={seed}'] if SEEDS > 1 else []) + extra + [f'-cpu-lim={LIMIT}', code]
                    r0 = resource.getrusage(resource.RUSAGE_CHILDREN); t0 = time.monotonic()
                    p = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
                    wall = time.monotonic() - t0; r1 = resource.getrusage(resource.RUSAGE_CHILDREN)
                    ans = [l for l in p.stdout.splitlines() if l.startswith('o ')]
                    rec = dict(stem=stem, seed=seed, rep=rep, arm=arm, wall=wall, utime=r1.ru_utime - r0.ru_utime, rc=p.returncode,
                               o=ans[-1] if ans else None)
                    fh.write(json.dumps(rec) + '\n'); fh.flush(); recs.append(rec)
g = lambda v: math.exp(sum(map(math.log, v)) / len(v))
print('| Code | main wall | A wall | A/main | B wall | B/main | A/main user | B/main user | answers |')
print('|---|---:|---:|---:|---:|---:|---:|---:|---|')
rat = {'A': [], 'B': []}
for stem in sys.argv[8:]:
    c = {}
    for arm in ARMS:
        c[arm] = tuple(st.median([st.median([r[k] for r in recs if r['stem'] == stem and r['arm'] == arm and r['seed'] == s]) for s in range(SEEDS)])
                       for k in ('wall', 'utime'))
    ans = sorted(set(r['o'] for r in recs if r['stem'] == stem))
    for a in ('A', 'B'): rat[a].append(c[a][0] / c['main'][0])
    print(f"| {stem} | {c['main'][0]:.4f} | {c['A'][0]:.4f} | {c['A'][0]/c['main'][0]:.3f} | {c['B'][0]:.4f} | {c['B'][0]/c['main'][0]:.3f} | "
          f"{c['A'][1]/max(c['main'][1],1e-9):.3f} | {c['B'][1]/max(c['main'][1],1e-9):.3f} | {ans} |")
print(f"\ngeomean wall ratio: A {g(rat['A']):.3f} (max {max(rat['A']):.3f}), B {g(rat['B']):.3f} (max {max(rat['B']):.3f}); "
      f"{len(recs)} runs, rc != 0: {sum(r['rc'] != 0 for r in recs)}")
