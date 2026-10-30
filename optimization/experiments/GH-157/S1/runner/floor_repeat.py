#!/usr/bin/env python3
"""GH-157 process-floor repeat (the GH-152 Tier 1 repeat, generalised to two binaries; preregistered after the first panel,
whose LP cells sit at the process floor, 25-60 ms of which the search is a few ms): for one code, seeds 0-4 x 5 repetitions,
old (OLDBIN -engine=cc -cc-stats -seed=S OLDARGS) and new (NEWBIN ... NEWARGS) run back to back on the SAME pinned core
(interleaved, order alternating per repetition), 4 GB cap. Wall time from process start to exit. Decision: median over the
25 runs per arm; ratio new/old per cell. usage: floor_repeat.py OLDBIN 'OLDARGS' NEWBIN 'NEWARGS' CORE CODE OUT.jsonl"""
import json, subprocess, sys, time, statistics
OB, OA, NB, NA, CORE, CODE, OUT = sys.argv[1:8]
stem = CODE.split('/')[-1]
rows = []
with open(OUT, 'a') as fh:
    for rep in range(5):
        for seed in range(5):
            arms = [('old', OB, OA.split()), ('new', NB, NA.split())]
            if (rep + seed) % 2: arms.reverse()
            for arm, b, extra in arms:
                cmd = ['taskset', '-c', CORE, 'prlimit', '--as=4294967296', '--', b, '-engine=cc', '-cc-stats', f'-seed={seed}'] + extra + ['-cpu-lim=1800', CODE]
                t = time.perf_counter()
                p = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
                w = time.perf_counter() - t
                o = [l for l in p.stdout.splitlines() if l.startswith('o ')]
                rec = dict(stem=stem, arm=arm, seed=seed, rep=rep, wall=round(w, 6), rc=p.returncode, o=int(o[-1].split()[1]) if o else None, cmd=cmd)
                rows.append(rec); fh.write(json.dumps(rec) + '\n'); fh.flush()
mo = statistics.median(r['wall'] for r in rows if r['arm'] == 'old'); mn = statistics.median(r['wall'] for r in rows if r['arm'] == 'new')
print(f'{stem}: old median {mo*1000:.2f} ms, new median {mn*1000:.2f} ms, ratio {mn/mo:.3f}, answers {sorted(set(r["o"] for r in rows))}')
