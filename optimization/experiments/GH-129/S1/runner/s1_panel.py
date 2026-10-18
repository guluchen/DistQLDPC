#!/usr/bin/env python3
"""GH-129 S1 seed panel on yfclab2 (adapted from GH-124 S1/runner/s1_panel.py).

One binary (the candidate d1f3f41; without -frontier it is byte-identical to main abd1770). Arms per (case, seed S):
  main-nc  = -no-card  -seed=S          main-mto = -card-mto -seed=S
  cand-nc  = -no-card  -seed=S -frontier=on    cand-mto = -card-mto -seed=S -frontier=on
Every process: taskset -c CORE prlimit --as=4294967296 -- BIN ARGS -cpu-lim=LIMIT data/matrices/tierT/STEM
One process per core; the four arms of a (case, seed) are queued back to back so they run concurrently.
Cases are queued longest first. The runner kills a process group at LIMIT + 600 s as a backstop.
usage: s1_panel.py --bin BIN --tiers 4 3 2 1 --cpus 116-123 --out DIR
"""
import argparse, glob, json, os, re, signal, subprocess, threading, time, queue

ap = argparse.ArgumentParser()
ap.add_argument('--bin', required=True)
ap.add_argument('--tiers', nargs='+', default=['4', '3', '2', '1'])
ap.add_argument('--seeds', nargs='+', default=['0', '1', '2', '3', '4'])
ap.add_argument('--cpus', required=True)
ap.add_argument('--out', required=True)
a = ap.parse_args()
os.makedirs(a.out + '/logs', exist_ok=True)
LIMIT = {'0': 600, '1': 1800, '2': 1800, '3': 1800, '4': 5000}
# main 398054e server medians (slower mode), used only to order the queue
ORDER = {'TN_250_10_15': 3091, 'BB_288_12_18': 919, 'LP_544_80_12': 521, 'TN_144_2_13': 362, 'GB_144_12_12': 131,
         'TN_200_10_10': 129, 'BB_144_14_14': 73, 'LP_442_68_10': 46, 'TN_108_2_12': 30}
ARMS = [('main-nc', ['-no-card']), ('main-mto', ['-card-mto']),
        ('cand-nc', ['-no-card', '-frontier=on']), ('cand-mto', ['-card-mto', '-frontier=on'])]
cpus = []
for part in a.cpus.split(','):
    lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
assert all(64 <= c <= 123 for c in cpus) and len(cpus) <= 60   # GH-129: cores 64-123 only

cases = []
for t in a.tiers:
    for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt')):
        cases.append((t, os.path.basename(f)[:-7]))
cases.sort(key=lambda c: (-int(c[0]), -ORDER.get(c[1], 0)))
jobs = [(t, s, seed, arm, flags) for t, s in cases for seed in a.seeds for arm, flags in ARMS]
q = queue.Queue(); [q.put(j) for j in jobs]
res = []; lock = threading.Lock()


def stem_d(stem):
    f = stem.split('_')[3]
    return int(f) if f.isdigit() else None


def run(job, cpu):
    t, s, seed, arm, flags = job
    lim = LIMIT[t]; rid = f'{s}.{arm}.s{seed}'
    cmd = ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--', a.bin] + flags + \
          [f'-seed={seed}', f'-cpu-lim={lim}', f'data/matrices/tier{t}/{s}']
    log = f'{a.out}/logs/{rid}.log'
    t0 = time.monotonic(); start = time.time(); killed = [False]
    with open(log, 'w') as lf:
        lf.write('# cmd: ' + ' '.join(cmd) + '\n'); lf.flush()
        p = subprocess.Popen(cmd, stdout=lf, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                             start_new_session=True)

        def backstop():
            killed[0] = True
            try: os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError: pass
        tm = threading.Timer(lim + 600, backstop); tm.start()
        _, status, ru = os.wait4(p.pid, 0)
        tm.cancel()
    wall = time.monotonic() - t0
    rc = os.waitstatus_to_exitcode(status)
    txt = open(log).read().splitlines()
    o = [l for l in txt if l.startswith('o ')]
    result = int(o[-1].split()[1]) if o else None
    lbs = [int(m.group(1)) for l in txt for m in [re.match(r'c d_lb: (\d+)$', l)] if m]
    ubs = [int(m.group(1)) for l in txt for m in [re.match(r'c d_ub: (\d+)$', l)] if m]
    withdrawn = any(re.match(r'c d_(lb|ub): -$', l) for l in txt)
    d = stem_d(s); issues = []
    if result is not None and result != d: issues.append(f'answer {result} != stem d {d}')
    if any(x > d for x in lbs): issues.append('lb above stem d')
    if any(x < d for x in ubs): issues.append('ub below stem d')
    solved = result is not None and result == d
    timeout = result is None
    rec = dict(tier=int(t), case=s, arm=arm, seed=int(seed), cpu=cpu, limit=lim, wall=round(wall, 3),
               utime=round(ru.ru_utime, 3), maxrss_kb=ru.ru_maxrss, rc=rc, result=result, solved=solved,
               timeout=timeout, final_lb=max(lbs, default=None), final_ub=min(ubs, default=None),
               withdrawn=withdrawn, runner_killed=killed[0], science_ok=not issues, issues=issues,
               start=round(start, 3), cmd=' '.join(cmd))
    with lock:
        res.append(rec)
        with open(f'{a.out}/results.jsonl', 'a') as f: f.write(json.dumps(rec) + '\n')
        print(f'{rid} cpu{cpu}: {wall:.2f}s o {result} ok {not issues}', flush=True)


def worker(cpu):
    while True:
        try: job = q.get_nowait()
        except queue.Empty: return
        try: run(job, cpu)
        except Exception as e:
            with lock:
                with open(f'{a.out}/results.jsonl', 'a') as f:
                    f.write(json.dumps(dict(job=list(job[:4]), cpu=cpu, error=repr(e))) + '\n')


json.dump(dict(bin=a.bin, cpus=cpus, limits=LIMIT, seeds=a.seeds, arms=ARMS, njobs=len(jobs)),
          open(f'{a.out}/config.json', 'w'), indent=1)
ts = [threading.Thread(target=worker, args=(c,)) for c in cpus]
[t.start() for t in ts]; [t.join() for t in ts]
bad = sum(not r['science_ok'] for r in res)
open(f'{a.out}/RUNNER_DONE', 'w').write(f'{time.time():.0f} {len(res)} runs; science problems {bad}\n')
print('done', len(res), 'runs; science problems', bad)
