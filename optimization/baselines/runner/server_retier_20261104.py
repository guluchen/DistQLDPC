#!/usr/bin/env python3
"""Re-tier panel 2026-11-04 (main 02879a93) on yfclab2: one dynamic queue over every code in codes.json.

Configurations: maxsat-no-card, maxsat-card-mto (default MaxSAT engine, the policy's two cardinality modes),
cc (-engine=cc, default CC rules, -v for witnesses), ccopt (-engine=cc -v + opt-in full rule set).
Every process: taskset -c CORE prlimit --as=4294967296 -- BIN ... -seed=S -cpu-lim=L PATH  (stdin /dev/null).
One process per pinned core.  Cores: the set in allowed_cores.txt (re-read every loop) minus cores that another
process is pinned to (Cpus_allowed_list with <= 16 cpus, any user) minus cores > 30 % busy in /proc/stat.
Seed 0 of MaxSAT runs with the 6 h limit (the MaxSAT child ignores -cpu-lim; only the parent's deadline differs),
so it serves both as the panel's seed 0 (time > 5000 s counts as a timeout) and as the Tier 5 run.
Rules: tiers 0-4 + new codes: MaxSAT seeds 1,2 at 5000 s; seeds 3,4 only when <= 1 of seeds 0-2 timed out
(otherwise the 5-seed median is >= 5000 s anyway); CC seeds 0-2 at 5000 s; new codes: CC opt-in seeds 0-2,
CC 6 h when CC seed 0 times out.  Tier 5: MaxSAT seed 0 (6 h) per mode, seeds 1-4 at 5000 s if seed 0 solved
within 5000 s; CC 6 h seed 0.
Files: results.jsonl (one record per finished run), logs/<id>.log (elapsed-stamped output), ALERTS
(any answer/bound outside a claim or two different solved answers), load.txt (per-minute load sample).
Control: STOP (start nothing new), allowed_cores.txt."""
import json, os, re, signal, subprocess, threading, time

BIN = os.path.abspath('../frozen/server-main-02879a93/distqldpc')
OPT = ['-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv', '-cc-roworder=auto']
CFG = {'maxsat-no-card': ['-no-card'], 'maxsat-card-mto': ['-card-mto'], 'cc': ['-engine=cc', '-v'],
       'ccopt': ['-engine=cc', '-v'] + OPT}
PANEL = 5000; LONG = 21600
codes = {c['stem']: c for c in json.load(open('codes.json'))}
os.makedirs('logs', exist_ok=True)
lock = threading.Lock()
done = {}          # id -> record
for l in open('results.jsonl') if os.path.exists('results.jsonl') else []:
    r = json.loads(l); done[r['id']] = r
queue = []         # (prio, order, job)
queued = set(); running = {}   # id -> (core, job)
order = [0]


def jid(stem, cfg, seed, lim): return f'{stem}.{cfg}.s{seed}.L{lim}'


def add(stem, cfg, seed, lim, prio):
    i = jid(stem, cfg, seed, lim)
    if i in queued or i in done: return
    queued.add(i); order[0] += 1
    queue.append((prio, order[0], dict(id=i, stem=stem, cfg=cfg, seed=seed, limit=lim)))
    queue.sort(key=lambda x: (x[0], x[1]))


def n_of(stem): return int(stem.split('_')[1])


def is_new(c): return not c['group'].startswith('t')


def easy(c):
    return (c['group'] in ('t0', 't1', 't2')) or (is_new(c) and n_of(c['stem']) <= 250)


def initial():
    for s, c in sorted(codes.items(), key=lambda kv: -n_of(kv[0])):
        e = easy(c); p5 = 0 if e else 2
        for m in ('maxsat-no-card', 'maxsat-card-mto'):
            add(s, m, 0, LONG, 0 if e else 1)
            if c['group'] != 't5':
                for sd in (1, 2): add(s, m, sd, PANEL, p5)
        if c['group'] == 't5':
            add(s, 'cc', 0, LONG, 1)
        else:
            for sd in (0, 1, 2): add(s, 'cc', sd, PANEL, p5)
        if is_new(c):
            for sd in (0, 1, 2): add(s, 'ccopt', sd, PANEL, p5)


def panel_time(r):
    """time for the 5000 s panel: None if not solved within 5000 s"""
    if r.get('result') is None or r['wall'] > PANEL: return None
    return r['wall']


def followups(r):
    s = r['stem']; c = codes[s]; cfg = r['cfg']
    if cfg.startswith('maxsat'):
        if c['group'] == 't5':
            if r['seed'] == 0 and panel_time(r) is not None:
                for sd in (1, 2, 3, 4): add(s, cfg, sd, PANEL, 1.5)
            return
        ids = [jid(s, cfg, 0, LONG), jid(s, cfg, 1, PANEL), jid(s, cfg, 2, PANEL)]
        if all(i in done for i in ids):
            to = sum(panel_time(done[i]) is None for i in ids)
            if to <= 1:
                for sd in (3, 4): add(s, cfg, sd, PANEL, 1.5)
    if cfg == 'cc' and is_new(c) and r['seed'] == 0 and r['limit'] == PANEL and r.get('result') is None:
        add(s, 'cc', 0, LONG, 1)


def alert(msg):
    with open('ALERTS', 'a') as f: f.write(time.strftime('%F %T ') + msg + '\n')


solved_by = {}


def check(r):
    c = codes[r['stem']]; cl = c['claim']; issues = []
    lo, hi = cl.get('lo'), cl.get('hi')
    if r['result'] is not None:
        d = r['result']
        if lo is not None and d < lo: issues.append(f'answer {d} < claim lo {lo}')
        if hi is not None and d > hi: issues.append(f'answer {d} > claim hi {hi}')
        prev = solved_by.setdefault(r['stem'], {})
        prev[r['id']] = d
        if len(set(prev.values())) > 1: issues.append(f'different solved answers {sorted(set(prev.values()))}')
    if r['final_lb'] is not None and hi is not None and r['final_lb'] > hi: issues.append(f'lb {r["final_lb"]} > claim hi {hi}')
    if r['final_ub'] is not None and lo is not None and r['final_ub'] < lo: issues.append(f'ub {r["final_ub"]} < claim lo {lo}')
    for i in issues: alert(f'{r["id"]}: {i} (claim {cl["text"][:80]})')
    return issues


def run(job, core):
    c = codes[job['stem']]
    cmd = ['taskset', '-c', str(core), 'prlimit', '--as=4294967296', '--', BIN] + CFG[job['cfg']] + \
          [f'-seed={job["seed"]}', f'-cpu-lim={job["limit"]}', c['path']]
    t0 = time.monotonic(); start = time.time(); killed = [False]
    lbs, ubs, wd = [], [], []; result = None; status = []; wit = []; memout = False
    with open(f'logs/{job["id"]}.log', 'w', buffering=1) as lf:
        lf.write(f'# start {start:.3f} cpu {core} cmd: ' + ' '.join(cmd) + '\n')
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                             text=True, start_new_session=True, errors='replace')

        def backstop():
            killed[0] = True
            try: os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError: pass
        tm = threading.Timer(job['limit'] + 600, backstop); tm.start()
        for line in p.stdout:
            e = time.monotonic() - t0; lf.write(f'{e:10.1f}\t{line}')
            m = re.match(r'c d_(lb|ub): (\d+|-)\s*$', line)
            if m:
                if m.group(2) == '-': wd.append((round(e, 1), m.group(1)))
                else: (lbs if m.group(1) == 'lb' else ubs).append((round(e, 2), int(m.group(2))))
            if line.startswith('o '): result = int(line.split()[1])
            if line.startswith('c status') or line.startswith('s '): status.append(line.strip())
            if re.search(r'bad_alloc|[Oo]ut of memory|Cannot allocate|MEMOUT', line): memout = True
        _, st, ru = os.wait4(p.pid, 0); tm.cancel()
    wall = time.monotonic() - t0; rc = os.waitstatus_to_exitcode(st)
    if result is None and ru.ru_maxrss > 3_800_000: memout = True
    if result is None and rc not in (0, 1) and not any('TIMEOUT' in s for s in status) and wall < job['limit'] - 5:
        if ru.ru_maxrss > 3_000_000: memout = True
    rec = dict(job, core=core, wall=round(wall, 3), utime=round(ru.ru_utime, 2), maxrss_kb=ru.ru_maxrss, rc=rc,
               result=result, final_lb=None if any(w[1] == 'lb' for w in wd) else max([x for _, x in lbs], default=None),
               final_ub=None if any(w[1] == 'ub' for w in wd) else min([x for _, x in ubs], default=None),
               lb_events=lbs, ub_events=ubs, withdrawn=wd, status=status, memout=memout, runner_killed=killed[0],
               start=round(start, 1), cmd=' '.join(cmd))
    with lock:
        rec['issues'] = check(rec)
        done[job['id']] = rec; del running[job['id']]
        with open('results.jsonl', 'a') as f: f.write(json.dumps(rec) + '\n')
        followups(rec)


def parse_list(s):
    out = set()
    for part in s.replace(',', ' ').split():
        a, _, b = part.partition('-'); out |= set(range(int(a), int(b or a) + 1))
    return out


def foreign_pinned(mine):
    res = set()
    for d in os.listdir('/proc'):
        if not d.isdigit() or int(d) in mine: continue
        try:
            if not open(f'/proc/{d}/cmdline', 'rb').read(): continue   # kernel threads (per-cpu kworkers etc.)
            txt = open(f'/proc/{d}/status').read()
        except OSError: continue
        m = re.search(r'Cpus_allowed_list:\s*(\S+)', txt)
        if not m: continue
        cl = parse_list(m.group(1))
        if len(cl) <= 16: res |= cl
    return res


def descendants():
    kids = {}
    for d in os.listdir('/proc'):
        if not d.isdigit(): continue
        try: ppid = int(open(f'/proc/{d}/stat').read().rsplit(')', 1)[1].split()[1])
        except (OSError, IndexError, ValueError): continue
        kids.setdefault(ppid, []).append(int(d))
    out = set(); st = [os.getpid()]
    while st:
        x = st.pop(); out.add(x); st += kids.get(x, [])
    return out


def cpu_times():
    t = {}
    for l in open('/proc/stat'):
        m = re.match(r'cpu(\d+) (.*)', l)
        if m:
            v = list(map(int, m.group(2).split())); t[int(m.group(1))] = (sum(v), v[3] + v[4])
    return t


initial()
prev = cpu_times(); time.sleep(10); busy = {}
lastload = 0
while True:
    cur = cpu_times()
    for k in cur:
        tot = cur[k][0] - prev.get(k, (0, 0))[0]; idle = cur[k][1] - prev.get(k, (0, 0))[1]
        busy[k] = 1 - idle / tot if tot > 0 else 0
    prev = cur
    if time.time() - lastload > 60:
        lastload = time.time()
        with open('load.txt', 'a') as f:
            f.write(f'{time.strftime("%F %T")} load {open("/proc/loadavg").read().split()[0]} running {len(running)} '
                    f'queued {len(queue)} done {len(done)}\n')
    if os.path.exists('STOP'):
        if not running: break
        time.sleep(15); continue
    with lock:
        if not queue and not running: break
    try: allowed = parse_list(open('allowed_cores.txt').read())
    except OSError: allowed = set()
    used = {c for c, _ in running.values()}
    cand = sorted(c for c in allowed if c < 128 and c not in used)
    if cand and queue:
        fp = foreign_pinned(descendants())
        free = [c for c in cand if c not in fp and busy.get(c, 1) < 0.30]
        with lock:
            for core in free:
                if not queue: break
                _, _, job = queue.pop(0)
                running[job['id']] = (core, job)
                threading.Thread(target=run, args=(job, core), daemon=False).start()
    time.sleep(15)
open('RUNNER_DONE', 'w').write(f'{time.time():.0f} {len(done)} runs\n')
