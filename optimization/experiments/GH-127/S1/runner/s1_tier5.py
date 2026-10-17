#!/usr/bin/env python3
"""GH-127 S1 Tier 5 on yfclab2 (adapted from GH-124/S1/runner/s1_tier5.py).

Every tier5 code x {-no-card, -card-mto} once with one variant flag (default seed), all at once, one pinned core
each, 4 GB cap, limit 21600 s via -cpu-lim. Quiet runs (no -v) so the live c d_lb / c d_ub lines print; every
output line is written with its elapsed time (s since start) and the start epoch is in the log header. Records the
timestamped bound events and checks every answer and bound against the stem ({d} / {lb}to{ub} / ge{lb}).
usage: s1_tier5.py --bin BIN --cpus 64-115 --out DIR --tag A --flags=-lb-ladder=unit:8 [--limit 21600]
"""
import argparse, glob, json, os, re, signal, subprocess, threading, time

ap = argparse.ArgumentParser()
ap.add_argument('--bin', required=True); ap.add_argument('--cpus', required=True); ap.add_argument('--out', required=True)
ap.add_argument('--tag', required=True); ap.add_argument('--flags', required=True)
ap.add_argument('--limit', type=int, default=21600)
a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
flags = a.flags.split()
cpus = []
for part in a.cpus.split(','):
    lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
assert all(0 <= c <= 123 for c in cpus)
stems = sorted(os.path.basename(p)[:-7] for p in glob.glob('data/matrices/tier5/*_Hx.txt'))
jobs = [(s, m) for s in stems for m in ('no-card', 'card-mto')]
assert len(jobs) <= len(cpus), (len(jobs), len(cpus))


def bounds(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge'): return int(f[2:]), None
    x, y = f.split('to'); return int(x), int(y)


res = []; lock = threading.Lock()


def one(job, cpu):
    s, mode = job
    t0 = time.monotonic(); start = time.time()
    cmd = ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--', a.bin] + flags + \
          [f'-{mode}', f'-cpu-lim={a.limit}', f'data/matrices/tier5/{s}']
    log = open(f'{a.out}/{s}.{a.tag}.{mode}.log', 'w', buffering=1)
    log.write(f'# start {start:.3f} ({time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(start))}) cpu {cpu} cmd: '
              + ' '.join(cmd) + '\n')
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, text=True,
                         start_new_session=True)
    killed = [False]

    def backstop():
        killed[0] = True
        try: os.killpg(p.pid, signal.SIGKILL)
        except ProcessLookupError: pass
    tm = threading.Timer(a.limit + 600, backstop); tm.start()
    lbs = []; ubs = []; result = None; withdrawn = []
    for line in p.stdout:
        e = time.monotonic() - t0; log.write(f'{e:10.1f}\t{line}')
        m = re.match(r'c d_(lb|ub): (\d+|-)\s*$', line)
        if m:
            if m.group(2) == '-': withdrawn.append((round(e, 1), m.group(1)))
            else: (lbs if m.group(1) == 'lb' else ubs).append((round(e, 1), int(m.group(2))))
        if line.startswith('o '): result = (round(e, 1), int(line.split()[1]))
    rc = p.wait(); tm.cancel(); wall = time.monotonic() - t0
    lo, hi = bounds(s); bad = []
    if result and (result[1] < lo or (hi is not None and result[1] > hi)): bad.append(f'solved {result[1]} outside stem [{lo},{hi}]')
    if hi is not None and any(x > hi for _, x in lbs): bad.append('lb above stem upper bound')
    if any(x < lo for _, x in ubs): bad.append('ub below stem lower bound')
    lv = [x for _, x in lbs]; uv = [x for _, x in ubs]
    if any(y < x for x, y in zip(lv, lv[1:])): bad.append('lb sequence decreases')
    if any(y > x for x, y in zip(uv, uv[1:])): bad.append('ub sequence increases')
    final_lb = None if withdrawn else max(lv, default=None)
    final_ub = None if withdrawn else min(uv, default=None)
    rec = dict(stem=s, mode=mode, tag=a.tag, flags=flags, cpu=cpu, rc=rc, wall=round(wall, 1), start=round(start, 1),
               result=result, final_lb=final_lb, final_ub=final_ub, lb_events=lbs, ub_events=ubs, withdrawn=withdrawn,
               runner_killed=killed[0], science_ok=not bad, issues=bad)
    with lock:
        res.append(rec)
        json.dump(dict(limit=a.limit, bin=a.bin, tag=a.tag, flags=flags, results=res),
                  open(f'{a.out}/results.json', 'w'), indent=1)
        print(f'{time.strftime("%H:%M:%S")} {s} {mode}: {wall:.0f}s result {result} lb {final_lb} ub {final_ub}', flush=True)


ths = [threading.Thread(target=one, args=(j, c)) for j, c in zip(jobs, cpus)]
[t.start() for t in ths]; [t.join() for t in ths]
bad = sum(not r['science_ok'] for r in res)
open(f'{a.out}/RUNNER_DONE', 'w').write(f'{time.time():.0f} {len(res)} runs; science problems {bad}\n')
print('done', len(res), 'runs; science problems:', bad)
