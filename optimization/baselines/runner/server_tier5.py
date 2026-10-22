#!/usr/bin/env python3
"""Baseline re-record (main c914ef5; first used for main cbb0642) Tier 5 on yfclab2 (adapted from GH-124/GH-130 S1/runner/s1_tier5.py).
Every tier5 code x {no-card, card-mto} once, default seed and flags, all at once, one pinned core each, 4 GB cap,
wall limit 21600 s via -cpu-lim (runner backstop at limit + 600 s). Every output line is written with its elapsed
time; timestamped c d_lb / c d_ub events are recorded, withdrawn bounds honoured, and every answer and bound is
checked against the stem ({d} / {lb}to{ub} / ge{lb}).
usage: server_tier5.py --bin BIN --cpus 0-53 --out DIR [--limit 21600]"""
import argparse, glob, json, os, re, signal, subprocess, threading, time

ap = argparse.ArgumentParser()
ap.add_argument('--bin', required=True); ap.add_argument('--cpus', required=True); ap.add_argument('--out', required=True)
ap.add_argument('--limit', type=int, default=21600); ap.add_argument('--modes', nargs='+', default=['no-card', 'card-mto'])
a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
cpus = []
for part in a.cpus.split(','):
    lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
assert all(0 <= c <= 89 for c in cpus), cpus   # allowed cores 0-89 (another session uses 100-123)
stems = sorted(os.path.basename(p)[:-7] for p in glob.glob('data/matrices/tier5/*_Hx.txt'))
jobs = [(s, m) for s in stems for m in a.modes]
assert len(jobs) <= len(cpus), (len(jobs), len(cpus))


def bounds(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge'): return int(f[2:]), None
    x, y = f.split('to'); return int(x), int(y)


res = []; lock = threading.Lock()


def one(job, cpu):
    s, m = job
    t0 = time.monotonic(); start = time.time()
    cmd = ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--', a.bin, f'-{m}', f'-cpu-lim={a.limit}',
           f'data/matrices/tier5/{s}']
    log = open(f'{a.out}/{s}.{m}.log', 'w', buffering=1)
    log.write(f'# start {start:.3f} cpu {cpu} cmd: ' + ' '.join(cmd) + '\n')
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, text=True,
                         start_new_session=True)
    killed = [False]

    def backstop():
        killed[0] = True
        try: os.killpg(p.pid, signal.SIGKILL)
        except ProcessLookupError: pass
    tm = threading.Timer(a.limit + 600, backstop); tm.start()
    lbs = []; ubs = []; result = None; withdrawn = []; status = []
    for line in p.stdout:
        e = time.monotonic() - t0; log.write(f'{e:10.1f}\t{line}')
        mm = re.match(r'c d_(lb|ub): (\d+|-)\s*$', line)
        if mm:
            if mm.group(2) == '-': withdrawn.append((round(e, 1), mm.group(1)))
            else: (lbs if mm.group(1) == 'lb' else ubs).append((round(e, 1), int(mm.group(2))))
        if line.startswith('o '): result = (round(e, 1), int(line.split()[1]))
        if line.startswith('c status') or line.startswith('s '): status.append(line.strip())
    _, st, ru = os.wait4(p.pid, 0); tm.cancel(); wall = time.monotonic() - t0
    rc = os.waitstatus_to_exitcode(st)
    lo, hi = bounds(s); bad = []
    if result and (result[1] < lo or (hi is not None and result[1] > hi)): bad.append(f'solved {result[1]} outside stem [{lo},{hi}]')
    if hi is not None and any(x > hi for _, x in lbs): bad.append('lb above stem upper bound')
    if any(x < lo for _, x in ubs): bad.append('ub below stem lower bound')
    final_lb = None if withdrawn else max([x for _, x in lbs], default=None)
    final_ub = None if withdrawn else min([x for _, x in ubs], default=None)
    rec = dict(stem=s, mode=m, cpu=cpu, rc=rc, wall=round(wall, 1), utime=round(ru.ru_utime, 1), maxrss_kb=ru.ru_maxrss,
               start=round(start, 1), result=result, final_lb=final_lb, final_ub=final_ub, lb_events=lbs, ub_events=ubs,
               withdrawn=withdrawn, status=status, runner_killed=killed[0], science_ok=not bad, issues=bad)
    with lock:
        res.append(rec)
        json.dump(dict(limit=a.limit, bin=a.bin, modes=a.modes, results=res), open(f'{a.out}/results.json', 'w'), indent=1)
        print(f'{s} {m} cpu{cpu}: {wall:.0f}s result {result} lb {final_lb} ub {final_ub} ok {not bad}', flush=True)


ths = [threading.Thread(target=one, args=(j, c)) for j, c in zip(jobs, cpus)]
[t.start() for t in ths]; [t.join() for t in ths]
bad = sum(not r['science_ok'] for r in res)
open(f'{a.out}/RUNNER_DONE', 'w').write(f'{time.time():.0f} {len(res)} runs; science problems {bad}\n')
print('done', len(res), 'runs; science problems:', bad)
