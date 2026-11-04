#!/usr/bin/env python3
"""GH-224 interleaved A/B panel for yfclab2 (after GH-217 rep.py and gh217_queue.py).

A unit is (stem, mode, seed). One unit runs REPS rounds on one pinned core; each round runs every arm once, and the arm
order rotates from round to round (old,new / new,old / ...), so slow phases of the machine hit every arm. Units are
spread over the given cores (72-103 only). Before each unit, the worker samples its core c and the SMT sibling c+128 for
0.5 s (/proc/stat) and skips the core for 20 s if either is busier than 15 %. Every process:
    taskset -c C prlimit --as=4294967296 -- BIN ARM_ARGS MODE_ARGS -seed=S -cpu-lim=LIMIT CODE   (stdin /dev/null)
Wall time = time.monotonic() around the process; user/sys time from wait4. stdout is stored per run.

usage: interleave.py --arms ARMS.json --cpus 72-103 --reps 9 --seeds 5 --modes mto,nocard,cc --limit 600 --out DIR STEM...
  ARMS.json: {"old": ["/path/bin", [extra args]], "new": [...]}  (first arm = reference)
  modes: mto = default MaxSAT (both cardinality encodings), nocard = MaxSAT -no-card, cc = -engine=cc (CC defaults)
"""
import argparse, glob, json, os, queue, subprocess, threading, time

MODES = {'mto': [], 'nocard': ['-no-card'], 'cc': ['-engine=cc']}
ap = argparse.ArgumentParser()
ap.add_argument('--arms', required=True); ap.add_argument('--cpus', required=True)
ap.add_argument('--reps', type=int, default=9); ap.add_argument('--seeds', type=int, default=5)
ap.add_argument('--modes', default='mto,nocard,cc'); ap.add_argument('--limit', type=int, default=600)
ap.add_argument('--out', required=True); ap.add_argument('stems', nargs='+')
a = ap.parse_args()
arms = json.load(open(a.arms))
cpus = []
for part in a.cpus.split(','):
    lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
assert cpus and all(72 <= c <= 103 for c in cpus), 'GH-224: yfclab2 logical CPUs 72-103 only'
os.makedirs(a.out + '/tmp', exist_ok=True)
done = set()
if os.path.exists(f'{a.out}/results.jsonl'):
    for l in open(f'{a.out}/results.jsonl'):
        r = json.loads(l); done.add((r['stem'], r['mode'], r['seed']))


def code_of(stem):
    f = glob.glob(f'data/matrices/*/{stem}_Hx.txt')
    assert len(f) == 1, (stem, f)
    return f[0][:-7], os.path.basename(os.path.dirname(f[0]))


units = [(s, m, seed) for s in a.stems for m in a.modes.split(',') for seed in range(a.seeds) if (s, m, seed) not in done]
q = queue.Queue(); [q.put(u) for u in units]
lock = threading.Lock()


def stat():
    d = {}
    for l in open('/proc/stat'):
        if l.startswith('cpu') and l[3].isdigit():
            f = l.split(); v = list(map(int, f[1:])); d[int(f[0][3:])] = (sum(v), v[3] + v[4])
    return d


def busy(c):
    x = stat(); time.sleep(0.5); y = stat(); out = []
    for k in (c, c + 128):
        t = y[k][0] - x[k][0]; out.append(1 - (y[k][1] - x[k][1]) / t if t else 0.0)
    return max(out)


def run_one(cpu, b, args, code):
    cmd = ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--', b] + args + [f'-cpu-lim={a.limit}', code]
    fo, fe = f'{a.out}/tmp/{cpu}.out', f'{a.out}/tmp/{cpu}.err'
    with open(fo, 'w') as so, open(fe, 'w') as se:
        t0 = time.monotonic()
        p = subprocess.Popen(cmd, stdout=so, stderr=se, stdin=subprocess.DEVNULL)
        _, st, ru = os.wait4(p.pid, 0)
        wall = time.monotonic() - t0
    p.returncode = os.waitstatus_to_exitcode(st)
    return wall, p.returncode, ru, open(fo).read(), open(fe).read()


def worker(cpu):
    while True:
        try: u = q.get_nowait()
        except queue.Empty: return
        tries = 0
        while busy(cpu) > 0.15:
            tries += 1
            with lock:
                with open(f'{a.out}/skips.log', 'a') as f: f.write(f'{time.time():.0f} cpu {cpu} busy, unit {u}\n')
            time.sleep(20)
        stem, mode, seed = u
        code, tier = code_of(stem)
        names = list(arms)
        for rep in range(a.reps):
            order = names[rep % len(names):] + names[:rep % len(names)]
            for arm in order:
                b, extra = arms[arm]
                args = extra + MODES[mode] + [f'-seed={seed}']
                wall, rc, ru, out, err = run_one(cpu, b, args, code)
                o = [l for l in out.splitlines() if l.startswith('o ')]
                rec = dict(stem=stem, tier=tier, mode=mode, seed=seed, rep=rep, arm=arm, cpu=cpu, wall=round(wall, 6),
                           utime=round(ru.ru_utime, 4), stime=round(ru.ru_stime, 4), maxrss_kb=ru.ru_maxrss,
                           rc=rc, o=o[-1] if o else None, stdout=out, stderr=err[-2000:], start=time.time())
                with lock:
                    with open(f'{a.out}/results.jsonl', 'a') as f: f.write(json.dumps(rec) + '\n')
        with lock:
            print(f'{stem} {mode} s{seed} cpu{cpu} done', flush=True)


json.dump(dict(arms=arms, cpus=cpus, reps=a.reps, seeds=a.seeds, modes=a.modes, limit=a.limit, units=len(units),
               started=time.time()), open(f'{a.out}/config.json', 'w'), indent=1)
ts = [threading.Thread(target=worker, args=(c,)) for c in cpus]
[t.start() for t in ts]; [t.join() for t in ts]
open(f'{a.out}/RUNNER_DONE', 'w').write(f'{time.time():.0f} {len(units)} units\n')
print('done', len(units), 'units')
