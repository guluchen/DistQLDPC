#!/usr/bin/env python3
"""GH-152 Tier 1 repeat (preregistered after the first panel, whose Tier 1 cells sit at the process floor and whose
identical-search cells varied by up to 12 %): for one code, seeds 0-4 x 5 repetitions, old (-engine=cc -cc-stats -seed=S)
and new (+ -cc-aut=on) run back to back on the SAME pinned core (interleaved, order alternating per repetition), 4 GB cap.
Wall time as in the queue runner (process start to exit). Decision: median over the 25 runs per arm; ratio new/old per
cell; tier geomean < 1 and no cell > 1.25. usage: tier1_repeat.py BIN CORE CODE OUT.jsonl"""
import json, subprocess, sys, time, statistics
BIN, CORE, CODE, OUT = sys.argv[1:5]
stem = CODE.split('/')[-1]
rows = []
with open(OUT, 'a') as fh:
    for rep in range(5):
        for seed in range(5):
            arms = [('old', []), ('new', ['-cc-aut=on'])]
            if (rep + seed) % 2: arms.reverse()
            for arm, extra in arms:
                cmd = ['taskset', '-c', CORE, 'prlimit', '--as=4294967296', '--', BIN, '-engine=cc', '-cc-stats', f'-seed={seed}'] + extra + ['-cpu-lim=1800', CODE]
                t = time.perf_counter()
                p = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
                w = time.perf_counter() - t
                o = [l for l in p.stdout.splitlines() if l.startswith('o ')]
                rec = dict(stem=stem, arm=arm, seed=seed, rep=rep, wall=round(w, 6), rc=p.returncode, o=int(o[-1].split()[1]) if o else None)
                rows.append(rec); fh.write(json.dumps(rec) + '\n'); fh.flush()
mo = statistics.median(r['wall'] for r in rows if r['arm'] == 'old'); mn = statistics.median(r['wall'] for r in rows if r['arm'] == 'new')
print(f'{stem}: old median {mo*1000:.2f} ms, new median {mn*1000:.2f} ms, ratio {mn/mo:.3f}, answers {sorted(set(r["o"] for r in rows))}')
