#!/usr/bin/env python3
"""GH-130 server identity sample: per-probe search identity of -frontier=auto against main's path (no flag) on
cells where auto picks off, and against -frontier=on on cells where auto picks on. -frontier-stats prints the
deterministic per-probe conflict/decision counts (stderr). Every process: taskset -c CORE prlimit --as=4294967296.
usage (cwd = worktree): ident_server.py --bin BIN --cpus 100-107 --out DIR"""
import argparse, os, queue, subprocess, threading
ap = argparse.ArgumentParser(); ap.add_argument('--bin', required=True); ap.add_argument('--cpus', required=True)
ap.add_argument('--out', required=True); a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
cpus = []
for part in a.cpus.split(','):
    lo, _, hi = part.partition('-'); cpus += list(range(int(lo), int(hi or lo) + 1))
assert all(0 <= c <= 123 for c in cpus)
OFF = [('2', 'TN_108_2_12', 1800), ('3', 'TN_200_10_10', 1800), ('3', 'TN_144_2_13', 1800), ('4', 'TN_250_10_15', 900),
       ('5', 'TN_180_2_17', 900), ('5', 'TN_216_4_18', 900), ('5', 'TN_504_2_ge17', 900), ('5', 'TN_684_2_ge9', 900)]
ON = [('2', 'BB_144_14_14', 1800), ('2', 'LP_442_68_10', 1800), ('3', 'GB_144_12_12', 1800), ('1', 'LP_238_44_6', 1800)]
jobs = []
for t, s, lim in OFF:
    for seed in ('0', '1') if t in '23' else ('0',):
        for mode in ('-no-card', '-card-mto'):
            for arm, fl in (('main', []), ('auto', ['-frontier=auto'])):
                jobs.append((f'{s}{mode}.s{seed}.{arm}', fl + [mode, f'-seed={seed}', '-frontier-stats', f'-cpu-lim={lim}', f'data/matrices/tier{t}/{s}']))
for t, s, lim in ON:
    for mode in ('-no-card', '-card-mto'):
        for arm, fl in (('on', ['-frontier=on']), ('auto', ['-frontier=auto'])):
            jobs.append((f'{s}{mode}.s0.{arm}', fl + [mode, '-frontier-stats', f'-cpu-lim={lim}', f'data/matrices/tier{t}/{s}']))
q = queue.Queue(); [q.put(j) for j in jobs]
def worker(c):
    while True:
        try: rid, args = q.get_nowait()
        except queue.Empty: return
        with open(f'{a.out}/{rid}.out', 'w') as o, open(f'{a.out}/{rid}.err', 'w') as e:
            subprocess.run(['taskset', '-c', str(c), 'prlimit', '--as=4294967296', '--', a.bin] + args, stdout=o, stderr=e, stdin=subprocess.DEVNULL)
ts = [threading.Thread(target=worker, args=(c,)) for c in cpus]; [t.start() for t in ts]; [t.join() for t in ts]
open(f'{a.out}/DONE', 'w').write(f'{len(jobs)} jobs\n')
