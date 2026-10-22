#!/usr/bin/env python3
"""Baseline re-record (main c914ef5): quiet-host gate around mac_serial.py (the Mac may be shared with another session).
Before every job it waits until no foreign process uses > 50% CPU in two checks 10 s apart (and logs the wait), then
runs that single job through mac_serial.py unchanged (timing = monotonic wall around wait4, 2 GB group-RSS watchdog)
and appends its TSV line to RESULTS. A sampler thread logs every 20 s the foreign processes above 50% CPU
("epoch count name:pcpu ...", own solver process group excluded) to SAMPLES; JOBLOG gets "id start end" epochs so
runs that overlapped foreign load can be found and re-run afterwards.
Run under caffeinate -i -s.  usage: mac_gated.py JOBS.jsonl RESULTS.tsv SAMPLES.txt JOBLOG.txt"""
import json, os, subprocess, sys, tempfile, threading, time

JOBS, RESULTS, SAMPLES, JOBLOG = sys.argv[1:5]
SERIAL = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'mac_serial.py')
cur = {'serial': None}


def foreign():
    out = subprocess.run(['ps', '-axo', 'pid=,ppid=,pgid=,pcpu=,comm='], capture_output=True, text=True).stdout
    rows = []
    for l in out.splitlines():
        f = l.split(None, 4)
        if len(f) == 5: rows.append((int(f[0]), int(f[1]), int(f[2]), float(f[3]), os.path.basename(f[4])))
    own_pg = {pid for pid, ppid, _, _, _ in rows if cur['serial'] is not None and ppid == cur['serial']}
    me = os.getpid()
    return [(n, c) for pid, ppid, pg, c, n in rows
            if c > 50 and pg not in own_pg and pid not in (me, cur['serial']) and n != 'ps']


def sampler(stop):
    with open(SAMPLES, 'a', buffering=1) as f:
        while not stop.wait(20):
            fo = foreign()
            f.write(f'{time.time():.0f} {len(fo)} ' + ' '.join(f'{n}:{c:.0f}' for n, c in fo) + '\n')


stop = threading.Event(); threading.Thread(target=sampler, args=(stop,), daemon=True).start()
jobs = [l for l in open(JOBS) if l.strip()]
for line in jobs:
    j = json.loads(line); waited = 0; t0 = time.time()
    while True:
        if not foreign():
            time.sleep(10)
            if not foreign(): break
        time.sleep(30); waited += 1
    with tempfile.NamedTemporaryFile('w', suffix='.jsonl', delete=False) as tf:
        tf.write(line); tmp = tf.name
    start = time.time()
    p = subprocess.Popen([sys.executable, '-I', SERIAL, tmp], stdout=subprocess.PIPE, text=True)
    cur['serial'] = p.pid
    out, _ = p.communicate(); cur['serial'] = None; os.unlink(tmp)
    end = time.time()
    with open(RESULTS, 'a') as f: f.write(out)
    with open(JOBLOG, 'a') as f: f.write(f'{j["id"]}\t{start:.1f}\t{end:.1f}\twaited {time.time() - t0 - (end - start):.0f}s\n')
stop.set()
open(RESULTS + '.DONE', 'w').write(f'{time.time():.0f} {len(jobs)} jobs\n')
