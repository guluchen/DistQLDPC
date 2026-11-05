#!/usr/bin/env python3
"""GH-225 lb reproduction runner (copy of the GH-225 queue runner with the core range changed to 64-95; GH-225 queue runner copied from GH-217 / GH-206 / GH-183 / GH-162; GH-162 added an optional "env" dict and an optional "bin" per job;
GH-225 adds the idle check below) for yfclab2 (one process per pinned core, 4 GB cap, jobs from a JSON-lines file).

Job: {"id", "args": [...solver flags...], "code": "data/matrices/tierT/STEM", "stem", "tier", "limit"}.
Every process: taskset -c CORE prlimit --as=4294967296 -- BIN ARGS -cpu-lim=LIMIT CODE   (stdin /dev/null).
Jobs are taken in file order by whichever core is free. stdout is read live; every line is logged with its elapsed
time; c d_lb / c d_ub / o events are recorded with their time. Backstop kill at LIMIT + 600 s. Science check: an
answer must lie in the stem's range ({d} / {lb}to{ub} / ge{lb}), every lb <= the stem's upper value, every ub >= the
stem's lower value. GH-225 idle check (coordinator 2026-11-05): before each launch on core c, c and its SMT sibling
c+128 are sampled for 1 s from /proc/stat; if either is more than 10 % busy, the core is skipped for 60 s (the job stays
queued for any core). Every launch records the busy fraction of c / c+128 and the list of cores in 64-127 / 192-255 that
were more than 50 % busy (our own runs included). usage: gh225lb_queue.py --bin BIN --cpus 64-95 --jobs JOBS.jsonl --out DIR
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
assert all(64 <= c <= 95 for c in cpus)   # GH-225 lb reproduction: yfclab2 logical CPUs 64-95 only (coordinator 2026-11-05)
jobs = [json.loads(l) for l in open(a.jobs) if l.strip()]
done_ids = set()
if os.path.exists(f'{a.out}/results.jsonl'):
    for l in open(f'{a.out}/results.jsonl'):
        try: done_ids.add(json.loads(l)['id'])
        except Exception: pass
jobs = [j for j in jobs if j['id'] not in done_ids]
q = queue.Queue(); [q.put(j) for j in jobs]
lock = threading.Lock(); res = []


def snap():
    d = {}
    for l in open('/proc/stat'):
        if l.startswith('cpu') and l[3].isdigit():
            f = l.split(); v = list(map(int, f[1:])); d[int(f[0][3:])] = (sum(v), v[3] + v[4])
    return d


def busy(sec=1.0):
    x = snap(); time.sleep(sec); y = snap(); out = {}
    for c in y:
        t = y[c][0] - x[c][0]; out[c] = round(1 - (y[c][1] - x[c][1]) / t, 2) if t else 0.0
    return out


def busy_list(b): return [c for c in sorted(b) if (64 <= c <= 127 or 192 <= c <= 255) and b[c] > 0.5]


def bounds(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge'): return int(f[2:]), None
    if f == 'unknown': return 1, None   # GH-217: untiered stems
    x, y = f.split('to'); return int(x), int(y)


def run(j, cpu, idle):
    lim = j['limit']
    cmd = ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--', j.get('bin', a.bin)] + j['args'] + [f'-cpu-lim={lim}', j['code']]
    log = open(f'{a.out}/logs/{j["id"]}.log', 'w', buffering=1)
    t0 = time.monotonic(); start = time.time()
    log.write(f'# start {start:.3f} cpu {cpu} idle-check {json.dumps(idle)} cmd: ' + ' '.join(cmd) + '\n')
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
               status=status, levels=levels, runner_killed=killed[0], science_ok=not bad, issues=bad, idle_check=idle)
    with lock:
        res.append(rec)
        with open(f'{a.out}/results.jsonl', 'a') as f: f.write(json.dumps(rec) + '\n')
        print(f'{j["id"]} cpu{cpu}: {wall:.2f}s o {result} ok {not bad}', flush=True)


def worker(cpu):
    while True:
        if q.empty(): return
        b = busy()
        if b[cpu] > 0.10 or b[cpu + 128] > 0.10:
            with lock:
                with open(f'{a.out}/skips.log', 'a') as f: f.write(f'{time.time():.0f} skip cpu {cpu}: {b[cpu]} / sibling {b[cpu + 128]}\n')
            time.sleep(60); continue
        idle = dict(cpu=b[cpu], sibling=b[cpu + 128], busy=busy_list(b))
        try: j = q.get_nowait()
        except queue.Empty: return
        try: run(j, cpu, idle)
        except Exception as e:
            with lock:
                with open(f'{a.out}/results.jsonl', 'a') as f: f.write(json.dumps(dict(id=j['id'], cpu=cpu, error=repr(e))) + '\n')


json.dump(dict(bin=a.bin, cpus=cpus, njobs=len(jobs), jobs_file=a.jobs, started=time.time(), busy_at_start=busy_list(busy(2.0))),
          open(f'{a.out}/config.json', 'w'), indent=1)
ts = [threading.Thread(target=worker, args=(c,)) for c in cpus]
[t.start() for t in ts]; [t.join() for t in ts]
bad = sum(not r.get('science_ok', False) for r in res)
open(f'{a.out}/RUNNER_DONE', 'w').write(f'{time.time():.0f} {len(res)} runs; science problems {bad}\n')
print('done', len(res), 'runs; science problems', bad)
