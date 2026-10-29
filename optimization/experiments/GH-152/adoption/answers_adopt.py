#!/usr/bin/env python3
"""GH-152 adoption Tier 0 answer check: every tier0-3 code with the adoption binary, -engine=cc (default = -cc-aut=on)
and -engine=cc -cc-aut=off, 600 s each, on the given cores (one process per pinned core, 4 GB cap, stdin /dev/null).
The answer 'o D' must equal the stem's distance. usage: answers_adopt.py BIN OUTDIR CORES(e.g. 69-71)"""
import glob, json, os, subprocess, sys, threading, queue, time
BIN, OUT, CORES = sys.argv[1:4]
lo, _, hi = CORES.partition('-'); cores = list(range(int(lo), int(hi or lo) + 1))
os.makedirs(OUT, exist_ok=True)
jobs = queue.Queue()
for t in (3, 2, 1, 0):
    for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt')):
        stem = os.path.basename(f)[:-7]
        for arm, ex in (('default', []), ('aut-off', ['-cc-aut=off'])):
            jobs.put((t, stem, f[:-7], arm, ex))
lock = threading.Lock()
def worker(core):
    while True:
        try: t, stem, code, arm, ex = jobs.get_nowait()
        except queue.Empty: return
        cmd = ['taskset', '-c', str(core), 'prlimit', '--as=4294967296', '--', BIN, '-engine=cc'] + ex + ['-cpu-lim=600', code]
        t0 = time.monotonic()
        p = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
        w = time.monotonic() - t0
        o = [l for l in p.stdout.splitlines() if l.startswith('o ')]
        ans = int(o[-1].split()[1]) if o else None
        want = int(stem.split('_')[3])
        rec = dict(tier=t, stem=stem, arm=arm, args=cmd[6:], rc=p.returncode, answer=ans, stem_d=want, ok=(ans == want and p.returncode == 0), wall=round(w, 3))
        with lock:
            open(f'{OUT}/answers.jsonl', 'a').write(json.dumps(rec) + '\n')
            open(f'{OUT}/{stem}.{arm}.out', 'w').write(p.stdout + p.stderr)
ts = [threading.Thread(target=worker, args=(c,)) for c in cores]
[x.start() for x in ts]; [x.join() for x in ts]
recs = [json.loads(l) for l in open(f'{OUT}/answers.jsonl')]
print(f'{sum(r["ok"] for r in recs)}/{len(recs)} answers equal the stem'); print('DONE')
