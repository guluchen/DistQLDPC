#!/usr/bin/env python3
"""GH-146 S0 (copied from GH-144 S0 finder_runs.py, unchanged logic): the -ub-pre finder alone on every bundled code (yfclab2; one process per pinned core, 4 GB cap).
Each job runs `BIN -v -ub-pre=S -seed=K CODE` and the process group is killed as soon as the pre-pass summary line
(`c ub-pre: U0 after ...` / `c ub-pre: no word ...`) has been printed, so only the pre-pass is measured (the MaxSAT
search that would follow is not run). Recorded per job: every verified word (half, weight, finder iteration, wall
seconds from the pre-pass start as printed by the binary), stop reason, U0, pre-pass seconds, iterations per half,
and the process wall time to the summary line (includes matrix parse, dual-map and symmetry detection).
usage: finder_runs.py --bin BIN --cpus 0-9,12 --budget 600 --seeds 0,1,2 [--tiers 2,3] [--extra '...'] --out DIR   (from a worktree root)"""
import argparse, glob, json, os, re, signal, subprocess, threading, time, queue
ap = argparse.ArgumentParser()
ap.add_argument('--bin', required=True); ap.add_argument('--cpus', required=True); ap.add_argument('--budget', required=True)
ap.add_argument('--seeds', default='0,1,2'); ap.add_argument('--out', required=True); ap.add_argument('--tiers', default='0,1,2,3,4,5')
ap.add_argument('--extra', default='', help='extra solver flags, space separated (e.g. "-ub-pre-hits=0 -ub-pre-plateau=1000000000")')
a = ap.parse_args()
os.makedirs(a.out + '/logs', exist_ok=True)
cpus = []
for part in a.cpus.split(','):
    lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
assert all(0 <= c <= 99 for c in cpus)
jobs = []
for t in map(int, a.tiers.split(',')):
    for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'), key=lambda p: -int(os.path.basename(p).split('_')[1])):
        stem = os.path.basename(f)[:-7]
        for s in map(int, a.seeds.split(',')):
            jobs.append(dict(id=f'{stem}.s{s}', stem=stem, tier=t, seed=s, code=f[:-7]))
jobs.sort(key=lambda j: -int(j['stem'].split('_')[1]))   # largest codes first
done = set()
if os.path.exists(f'{a.out}/results.jsonl'):
    for l in open(f'{a.out}/results.jsonl'):
        try: done.add(json.loads(l)['id'])
        except Exception: pass
q = queue.Queue(); [q.put(j) for j in jobs if j['id'] not in done]
lock = threading.Lock()
WORD = re.compile(r'^c ub-pre (X|Z): word of weight (\d+) \(iteration (\d+), wall ([0-9.]+)s\)')
SUM = re.compile(r'^c ub-pre: (U0|no word) after ([0-9.]+)s \(([^;]*); iterations X (\d+) Z (\d+), words X (\d+) Z (\d+)\)(?:: (\d+) \(X (-?\d+), Z (-?\d+)\))?')
def run(j, cpu):
    cmd = ['taskset', '-c', str(cpu), 'prlimit', '--as=4294967296', '--', a.bin, '-v', f'-ub-pre={a.budget}', f'-seed={j["seed"]}'] + a.extra.split() + [
           f'-cpu-lim={int(float(a.budget)) + 600}', j['code']]
    log = open(f'{a.out}/logs/{j["id"]}.log', 'w', buffering=1)
    log.write('# cpu %d cmd: %s\n' % (cpu, ' '.join(cmd)))
    t0 = time.monotonic()
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, text=True, start_new_session=True)
    words = []; summ = None; t_sum = None; warn = []
    for line in p.stdout:
        e = time.monotonic() - t0; log.write(f'{e:10.3f}\t{line}')
        m = WORD.match(line)
        if m: words.append(dict(half=m.group(1), w=int(m.group(2)), it=int(m.group(3)), t=float(m.group(4))))
        if line.startswith('warning') or line.startswith('error'): warn.append(line.strip())
        m = SUM.match(line)
        if m:
            summ = m; t_sum = e
            try: os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError: pass
            break
    try: os.killpg(p.pid, signal.SIGKILL)
    except ProcessLookupError: pass
    p.wait()
    rec = dict(id=j['id'], stem=j['stem'], tier=j['tier'], seed=j['seed'], cpu=cpu, budget=float(a.budget), words=words, warnings=warn)
    if summ:
        rec.update(pre_seconds=float(summ.group(2)), stop=summ.group(3), it_x=int(summ.group(4)), it_z=int(summ.group(5)),
                   words_x=int(summ.group(6)), words_z=int(summ.group(7)), u0=int(summ.group(8)) if summ.group(8) else None,
                   ub_x=int(summ.group(9)) if summ.group(9) else None, ub_z=int(summ.group(10)) if summ.group(10) else None,
                   proc_wall_to_summary=round(t_sum, 3))
    with lock:
        with open(f'{a.out}/results.jsonl', 'a') as f: f.write(json.dumps(rec) + '\n')
        print(j['id'], cpu, rec.get('u0'), rec.get('pre_seconds'), rec.get('stop'), flush=True)
def worker(cpu):
    while True:
        try: j = q.get_nowait()
        except queue.Empty: return
        try: run(j, cpu)
        except Exception as ex:
            with lock:
                with open(f'{a.out}/results.jsonl', 'a') as f: f.write(json.dumps(dict(id=j['id'], error=repr(ex))) + '\n')
json.dump(dict(bin=a.bin, cpus=cpus, budget=a.budget, seeds=a.seeds, extra=a.extra, started=time.time()), open(f'{a.out}/config.json', 'w'))
ts = [threading.Thread(target=worker, args=(c,)) for c in cpus]; [t.start() for t in ts]; [t.join() for t in ts]
open(f'{a.out}/RUNNER_DONE', 'w').write(f'{time.time():.0f}\n')
