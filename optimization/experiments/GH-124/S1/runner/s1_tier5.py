#!/usr/bin/env python3
"""GH-124 S1 Tier 5 on yfclab2 (adapted from ~/mac-agent-20261009/tier5_server.py).

Every tier5 code once with ARGS (default: -engine=cc -v), all at once, one pinned core each, 4 GB cap, wall limit
21600 s via -cpu-lim. Every output line is written with its elapsed time (s since start). Records the timestamped
c d_lb / c d_ub events, honours withdrawn bounds ('c d_lb: -' after a CC trap), and checks every answer and bound
against the stem ({d} / {lb}to{ub} / ge{lb}) and against the adjudicated values (GH-124 ADJUDICATION.md).
usage: s1_tier5.py --bin BIN --cpus 64-89 --out DIR [--limit 21600] [--args -engine=cc -v]
"""
import argparse, glob, json, os, re, signal, subprocess, threading, time

ap = argparse.ArgumentParser()
ap.add_argument('--bin', required=True); ap.add_argument('--cpus', required=True); ap.add_argument('--out', required=True)
ap.add_argument('--limit', type=int, default=21600); ap.add_argument('--args', nargs='*', default=['-engine=cc', '-v'])
a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
cpus = []
for part in a.cpus.split(','):
    lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
assert all(0 <= c <= 123 for c in cpus)
stems = sorted(os.path.basename(p)[:-7] for p in glob.glob('data/matrices/tier5/*_Hx.txt'))
assert len(stems) <= len(cpus), (len(stems), len(cpus))
ADJ = {'BB_360_12_17to24': 24, 'LP_1054_140_17to32': 20, 'LP_1428_184_ge17': 24, 'LP_1768_224_ge17': 22,
       'TN_252_2_17to28': 21}


def bounds(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge'): return int(f[2:]), None
    x, y = f.split('to'); return int(x), int(y)


res = []; lock = threading.Lock()


def one(s, cpu):
    t0 = time.monotonic(); start = time.time()
    cmd = ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--', a.bin] + a.args + \
          [f'-cpu-lim={a.limit}', f'data/matrices/tier5/{s}']
    log = open(f'{a.out}/{s}.cc.log', 'w', buffering=1)
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
        m = re.match(r'c d_(lb|ub): (\d+|-)\s*$', line)
        if m:
            if m.group(2) == '-': withdrawn.append((round(e, 1), m.group(1)))
            else: (lbs if m.group(1) == 'lb' else ubs).append((round(e, 1), int(m.group(2))))
        if line.startswith('o '): result = (round(e, 1), int(line.split()[1]))
        if line.startswith('c status') or line.startswith('s '): status.append(line.strip())
    rc = p.wait(); tm.cancel(); wall = time.monotonic() - t0
    lo, hi = bounds(s); bad = []
    if result and (result[1] < lo or (hi is not None and result[1] > hi)): bad.append(f'solved {result[1]} outside stem [{lo},{hi}]')
    if hi is not None and any(x > hi for _, x in lbs): bad.append('lb above stem upper bound')
    if any(x < lo for _, x in ubs): bad.append('ub below stem lower bound')
    if s in ADJ:
        if result and result[1] != ADJ[s]: bad.append(f'solved {result[1]} != adjudicated {ADJ[s]}')
        if any(x > ADJ[s] for _, x in lbs): bad.append('lb above adjudicated d')
        if any(x < ADJ[s] for _, x in ubs): bad.append('ub below adjudicated d')
    final_lb = None if withdrawn else max([x for _, x in lbs], default=None)
    final_ub = None if withdrawn else min([x for _, x in ubs], default=None)
    rec = dict(stem=s, args=a.args, cpu=cpu, rc=rc, wall=round(wall, 1), start=round(start, 1), result=result,
               final_lb=final_lb, final_ub=final_ub, lb_events=lbs, ub_events=ubs, withdrawn=withdrawn,
               status=status, runner_killed=killed[0], science_ok=not bad, issues=bad)
    with lock:
        res.append(rec)
        json.dump(dict(limit=a.limit, bin=a.bin, args=a.args, results=res), open(f'{a.out}/results.json', 'w'), indent=1)


ths = [threading.Thread(target=one, args=(s, c)) for s, c in zip(stems, cpus)]
[t.start() for t in ths]; [t.join() for t in ths]
bad = sum(not r['science_ok'] for r in res)
open(f'{a.out}/RUNNER_DONE', 'w').write(f'{time.time():.0f} {len(res)} runs; science problems {bad}\n')
print('done', len(res), 'runs; science problems:', bad)
