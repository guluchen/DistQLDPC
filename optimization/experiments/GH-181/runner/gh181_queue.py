#!/usr/bin/env python3
"""GH-181 queue runner (copied from GH-162 / GH-152 / GH-138 / GH-133; optional "env" dict and optional "bin" per job) for yfclab2 (one process per pinned core, 4 GB cap, jobs from a JSON-lines file).

Job: {"id", "args": [...solver flags...], "code": "data/matrices/tierT/STEM", "stem", "tier", "limit"}.
Every process: taskset -c CORE prlimit --as=4294967296 -- BIN ARGS -cpu-lim=LIMIT CODE   (stdin /dev/null).
Jobs are taken in file order by whichever core is free. stdout is read live; every line is logged with its elapsed
time; c d_lb / c d_ub / o events are recorded with their time. Backstop kill at LIMIT + 600 s. Science check: an
answer must lie in the stem's range ({d} / {lb}to{ub} / ge{lb}), every lb <= the stem's upper value, every ub >= the
stem's lower value. usage: gh181_queue.py --bin BIN --cpus 105-123 --jobs JOBS.jsonl --out DIR
"""
import argparse, json, os, re, signal, subprocess, threading, time, queue

ap = argparse.ArgumentParser()
ap.add_argument('--bin', required=True); ap.add_argument('--cpus', required=True)
ap.add_argument('--jobs', required=True); ap.add_argument('--out', required=True)
a = ap.parse_args()
os.makedirs(a.out + '/logs', exist_ok=True)
cpus = []
for part in a.cpus.split(','):
    lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
assert all(4 <= c <= 23 for c in cpus)   # GH-181: cores 4-23 only (1-3: GH-162 cross-check; 24-63: GH-157 and another agent)
jobs = [json.loads(l) for l in open(a.jobs) if l.strip()]
done_ids = set()
if os.path.exists(f'{a.out}/results.jsonl'):
    for l in open(f'{a.out}/results.jsonl'):
        try: done_ids.add(json.loads(l)['id'])
        except Exception: pass
jobs = [j for j in jobs if j['id'] not in done_ids]
q = queue.Queue(); [q.put(j) for j in jobs]
lock = threading.Lock(); res = []


def bounds(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge'): return int(f[2:]), None
    x, y = f.split('to'); return int(x), int(y)


def run(j, cpu):
    lim = j['limit']
    cmd = ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--', j.get('bin', a.bin)] + j['args'] + [f'-cpu-lim={lim}', j['code']]
    log = open(f'{a.out}/logs/{j["id"]}.log', 'w', buffering=1)
    t0 = time.monotonic(); start = time.time()
    log.write(f'# start {start:.3f} cpu {cpu} cmd: ' + ' '.join(cmd) + '\n')
    env = dict(os.environ); env.update(j.get('env', {}))
    if j.get('env'): log.write('# env ' + json.dumps(j['env']) + '\n')
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, text=True, env=env,
                         start_new_session=True)
    killed = [False]

    def backstop():
        killed[0] = True
        try: os.killpg(p.pid, signal.SIGKILL)
        except ProcessLookupError: pass
    tm = threading.Timer(lim + 600, backstop); tm.start()
    lbs = []; ubs = []; result = None; withdrawn = []; status = []; levels = []
    for line in p.stdout:
        e = time.monotonic() - t0; log.write(f'{e:10.3f}\t{line}')
        m = re.match(r'c d_(lb|ub): (\d+|-)\s*$', line)
        if m:
            if m.group(2) == '-': withdrawn.append((round(e, 3), m.group(1)))
            else: (lbs if m.group(1) == 'lb' else ubs).append((round(e, 3), int(m.group(2))))
        if line.startswith('o '): result = (round(e, 3), int(line.split()[1]))
        if line.startswith('c status') or line.startswith('s ') or line.startswith('error') or line.startswith('warning'): status.append(line.strip())
        if line.startswith('c cc-stats: ') and ' level ' in line: levels.append(line.strip()[12:])
    _, st, ru = os.wait4(p.pid, 0); tm.cancel(); wall = time.monotonic() - t0
    rc = os.waitstatus_to_exitcode(st)
    lo, hi = bounds(j['stem']); bad = []
    if result and (result[1] < lo or (hi is not None and result[1] > hi)): bad.append(f'answer {result[1]} outside stem [{lo},{hi}]')
    if hi is not None and any(x > hi for _, x in lbs): bad.append('lb above stem upper value')
    if any(x < lo for _, x in ubs): bad.append('ub below stem lower value')
    if killed[0]: bad.append('runner backstop kill')
    if rc not in (0, 1) and not killed[0]: bad.append(f'rc {rc}')
    rec = dict(id=j['id'], stem=j['stem'], tier=j.get('tier'), arm=j.get('arm'), seed=j.get('seed'), mode=j.get('mode'),
               args=j['args'], cpu=cpu, limit=lim, rc=rc, wall=round(wall, 3), utime=round(ru.ru_utime, 3), maxrss_kb=ru.ru_maxrss,
               start=round(start, 3), result=result, solved=result is not None, final_lb=None if withdrawn else max([x for _, x in lbs], default=None),
               final_ub=None if withdrawn else min([x for _, x in ubs], default=None), lb_events=lbs, ub_events=ubs, withdrawn=withdrawn,
               status=status, levels=levels, runner_killed=killed[0], science_ok=not bad, issues=bad)
    with lock:
        res.append(rec)
        with open(f'{a.out}/results.jsonl', 'a') as f: f.write(json.dumps(rec) + '\n')
        print(f'{j["id"]} cpu{cpu}: {wall:.2f}s o {result} ok {not bad}', flush=True)


def worker(cpu):
    while True:
        try: j = q.get_nowait()
        except queue.Empty: return
        try: run(j, cpu)
        except Exception as e:
            with lock:
                with open(f'{a.out}/results.jsonl', 'a') as f: f.write(json.dumps(dict(id=j['id'], cpu=cpu, error=repr(e))) + '\n')


json.dump(dict(bin=a.bin, cpus=cpus, njobs=len(jobs), jobs_file=a.jobs, started=time.time()), open(f'{a.out}/config.json', 'w'), indent=1)
ts = [threading.Thread(target=worker, args=(c,)) for c in cpus]
[t.start() for t in ts]; [t.join() for t in ts]
bad = sum(not r.get('science_ok', False) for r in res)
open(f'{a.out}/RUNNER_DONE', 'w').write(f'{time.time():.0f} {len(res)} runs; science problems {bad}\n')
print('done', len(res), 'runs; science problems', bad)
