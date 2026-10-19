#!/usr/bin/env python3
"""GH-124 S1 Mac quick check: run jobs (JSON lines {"id", "cmd", "out"}) strictly one at a time.
Wall = monotonic time around a blocking wait4 (no polling quantisation); a watchdog thread polls the process
group's RSS every 0.1 s and kills it above 2 GB. Prints TSV id rc wall maxrss_mb [MEMKILL].
Run under caffeinate -i -s.  usage: mac_serial.py JOBS.jsonl > results.tsv"""
import json, os, signal, subprocess, sys, threading, time

CAP_KB = 2 * 1024 * 1024
jobs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]


def group_rss_kb(pgid):
    out = subprocess.run(['ps', '-axo', 'pgid=,rss='], capture_output=True, text=True).stdout
    return [int(f[1]) for f in (l.split() for l in out.splitlines()) if len(f) == 2 and int(f[0]) == pgid]


for j in jobs:
    with open(j['out'], 'wb') as fo:
        t0 = time.monotonic()
        p = subprocess.Popen(j['cmd'], stdout=fo, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                             start_new_session=True)
        done = threading.Event(); mx = [0]; killed = [False]

        def watch():
            while not done.wait(0.1):
                for r in group_rss_kb(p.pid):
                    mx[0] = max(mx[0], r)
                    if r > CAP_KB and not killed[0]:
                        killed[0] = True
                        try: os.killpg(p.pid, signal.SIGKILL)
                        except ProcessLookupError: pass
        th = threading.Thread(target=watch); th.start()
        _, st, ru = os.wait4(p.pid, 0)
        wall = time.monotonic() - t0
        done.set(); th.join()
    mx[0] = max(mx[0], ru.ru_maxrss // 1024)  # macOS ru_maxrss is in bytes
    print('%s\t%d\t%.4f\t%.1f%s' % (j['id'], os.waitstatus_to_exitcode(st), wall, mx[0] / 1024.0,
                                   '\tMEMKILL' if killed[0] else ''), flush=True)
