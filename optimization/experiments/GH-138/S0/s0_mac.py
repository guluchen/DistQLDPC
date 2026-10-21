#!/usr/bin/env python3
"""GH-138 S0 Mac runs (runner copied from GH-133): CC old rules (excl,pack,orbf,parity,leaf) vs new rules (default, + overlap) with -cc-stats, 2 workers,
2 GB RSS cap per process group (watchdog), wall by monotonic clock. Jobs file: JSON lines {"id","cmd","out","limit"}.
usage: caffeinate -i -s python3 -I s0_mac.py JOBS.jsonl RESULTS.tsv [WORKERS=2]"""
import json, os, signal, subprocess, sys, threading, time, queue

CAP_KB = 2 * 1024 * 1024
jobs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
res_path = sys.argv[2]; W = int(sys.argv[3]) if len(sys.argv) > 3 else 2
q = queue.Queue(); [q.put(j) for j in jobs]; lock = threading.Lock()


def group_rss_kb(pgid):
    out = subprocess.run(['ps', '-axo', 'pgid=,rss='], capture_output=True, text=True).stdout
    return [int(f[1]) for f in (l.split() for l in out.splitlines()) if len(f) == 2 and int(f[0]) == pgid]


def run(j):
    with open(j['out'], 'wb') as fo:
        fo.write(('# cmd: ' + ' '.join(j['cmd']) + '\n').encode()); fo.flush()
        t0 = time.monotonic()
        p = subprocess.Popen(j['cmd'], stdout=fo, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, start_new_session=True)
        done = threading.Event(); mx = [0]; killed = [False]

        def watch():
            while not done.wait(0.2):
                for r in group_rss_kb(p.pid):
                    mx[0] = max(mx[0], r)
                    if r > CAP_KB and not killed[0]:
                        killed[0] = True
                        try: os.killpg(p.pid, signal.SIGKILL)
                        except ProcessLookupError: pass
                if time.monotonic() - t0 > j.get('limit', 1e9) + 300 and not killed[0]:   # backstop
                    killed[0] = True
                    try: os.killpg(p.pid, signal.SIGKILL)
                    except ProcessLookupError: pass
        th = threading.Thread(target=watch); th.start()
        _, st, ru = os.wait4(p.pid, 0)
        wall = time.monotonic() - t0
        done.set(); th.join()
    mx[0] = max(mx[0], ru.ru_maxrss // 1024)
    txt = open(j['out'], errors='replace').read().splitlines()
    o = [l for l in txt if l.startswith('o ')]
    line = '%s\t%d\t%.4f\t%.1f\t%s%s' % (j['id'], os.waitstatus_to_exitcode(st), wall, mx[0] / 1024.0,
                                        o[-1].split()[1] if o else 'TIMEOUT', '\tMEMKILL' if killed[0] else '')
    with lock:
        with open(res_path, 'a') as f: f.write(line + '\n')
        print(line, flush=True)


def worker():
    while True:
        try: j = q.get_nowait()
        except queue.Empty: return
        try: run(j)
        except Exception as e:
            with lock:
                with open(res_path, 'a') as f: f.write('%s\tERROR\t%r\n' % (j['id'], e))


ts = [threading.Thread(target=worker) for _ in range(W)]
[t.start() for t in ts]; [t.join() for t in ts]
open(res_path + '.DONE', 'w').write('%d\n' % time.time())
