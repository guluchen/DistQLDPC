#!/usr/bin/env python3
"""GH-128 tier0-4 runs: search identity of -p1skip=on vs off (and vs main), answers, bounds, wall times.

Every job runs `BIN [FLAGS] -v -dualshare-stats -MODE [-seed=S] -cpu-lim=LIM data/matrices/tierT/STEM` and records:
wall, rc, the answer (`o d`), the final `c d_lb` / `c d_ub`, the search fingerprint (every `c CSS interleave:` probe
line in order plus the `c dualshare stats` line without the GH-128 `p1skips` field: probe kind, cap, lb, result and
the per-half conflict totals), and the `c p1skip:` lines (where the skip triggered).
Server: --cpus 52-59 pins one job per core with `taskset -c CORE prlimit --as=4294967296 --`.
Mac:    --cpus serial runs one job at a time under an RSS watchdog (2 GB), meant to be wrapped in caffeinate -i -s.
usage: s128_runs.py --jobs jobs.jsonl --out DIR --cpus 52-59|serial
jobs.jsonl lines: {"id":..., "arm":"off|on|main", "bin":..., "flags":[...], "tier":T, "stem":..., "mode":"no-card",
                   "seed":S, "limit":L}
"""
import argparse, json, os, queue, re, signal, subprocess, sys, threading, time

ap = argparse.ArgumentParser()
ap.add_argument('--jobs', required=True); ap.add_argument('--out', required=True); ap.add_argument('--cpus', required=True)
a = ap.parse_args()
os.makedirs(a.out + '/logs', exist_ok=True)
jobs = [json.loads(l) for l in open(a.jobs) if l.strip()]
serial = a.cpus == 'serial'
cpus = []
if not serial:
    for part in a.cpus.split(','):
        lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
    assert all(0 <= c <= 59 for c in cpus), 'GH-128 uses only cores 0-59'
MEM = 2 * 1024 ** 3 if serial else 4 * 1024 ** 3


def stem_d(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge'): return int(f[2:]), None
    x, y = f.split('to'); return int(x), int(y)


def run(job, cpu):
    seed = [f"-seed={job['seed']}"] if job.get('seed') else []
    base = [job['bin']] + job['flags'] + ['-v', '-dualshare-stats', '-' + job['mode']] + seed + \
           [f"-cpu-lim={job['limit']}", f"data/matrices/tier{job['tier']}/{job['stem']}"]
    cmd = base if serial else ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--'] + base
    t0 = time.monotonic()
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                         start_new_session=True)
    out = []
    th = threading.Thread(target=lambda: out.append(p.stdout.read())); th.start()
    memout = False; peak = 0
    while p.poll() is None:
        if serial:
            try:
                r = subprocess.run(['ps', '-A', '-o', 'pgid=,rss='], capture_output=True, text=True).stdout.split('\n')
                rss = sum(int(x.split()[1]) for x in r if x.split() and int(x.split()[0]) == p.pid) * 1024
            except Exception:
                rss = 0
            peak = max(peak, rss)
            if rss > MEM:
                memout = True
                try: os.killpg(p.pid, signal.SIGKILL)
                except ProcessLookupError: pass
        if time.monotonic() - t0 > job['limit'] + 300:
            try: os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError: pass
        time.sleep(0.05)
    th.join(); wall = time.monotonic() - t0
    txt = out[0].decode('utf-8', 'replace')
    open(f"{a.out}/logs/{job['id']}.log", 'w').write('# cpu %s cmd: %s\n' % (cpu, ' '.join(cmd)) + txt)
    probes = [l for l in txt.splitlines() if l.startswith('c CSS interleave:')]
    stats = [re.sub(r' p1skips \d+', '', l) for l in txt.splitlines() if l.startswith('c dualshare stats:')]
    skips = [l for l in txt.splitlines() if l.startswith('c p1skip:')]
    res = re.findall(r'^o (\d+)', txt, re.M)
    lbs = [int(x) for x in re.findall(r'^c d_lb: (\d+)', txt, re.M)]
    ubs = [int(x) for x in re.findall(r'^c d_ub: (\d+)', txt, re.M)]
    lo, hi = stem_d(job['stem']); bad = []
    r = int(res[-1]) if res else None
    if r is not None and (r < lo or (hi is not None and r > hi)): bad.append(f'answer {r} outside stem [{lo},{hi}]')
    if hi is not None and any(x > hi for x in lbs): bad.append('lb above stem d')
    if any(x < lo for x in ubs): bad.append('ub below stem d')
    if any(y < x for x, y in zip(lbs, lbs[1:])): bad.append('lb decreases')
    if any(y > x for x, y in zip(ubs, ubs[1:])): bad.append('ub increases')
    import hashlib
    fp = hashlib.sha256('\n'.join(probes + stats).encode()).hexdigest()[:16]
    return dict(job, cpu=cpu, wall=round(wall, 3), rc=p.returncode, memout=memout, peak_rss=peak, result=r,
                final_lb=max(lbs) if lbs else None, final_ub=min(ubs) if ubs else None, fingerprint=fp,
                n_probes=len(probes), stats=stats[0] if stats else None, p1skip_lines=skips, ok=not bad and not memout,
                issues=bad, cmd=' '.join(cmd))


lock = threading.Lock(); resf = open(f'{a.out}/results.jsonl', 'a')
done_ids = set()
if os.path.exists(f'{a.out}/results.jsonl'):
    for l in open(f'{a.out}/results.jsonl'):
        try: done_ids.add(json.loads(l)['id'])
        except Exception: pass
q = queue.Queue()
for j in jobs:
    if j['id'] not in done_ids: q.put(j)


def worker(cpu):
    while True:
        try: j = q.get_nowait()
        except queue.Empty: return
        rec = run(j, cpu)
        with lock:
            resf.write(json.dumps(rec) + '\n'); resf.flush()
            print(f"{time.strftime('%H:%M:%S')} {j['id']}: {rec['wall']:.1f}s o={rec['result']} fp={rec['fingerprint']} "
                  f"skips={len(rec['p1skip_lines'])} ok={rec['ok']}", flush=True)


ths = [threading.Thread(target=worker, args=(c,)) for c in (cpus if not serial else [None])]
[t.start() for t in ths]; [t.join() for t in ths]
open(f'{a.out}/RUNNER_DONE', 'w').write(time.strftime('%Y-%m-%d %H:%M:%S') + '\n')
print('done', flush=True)
