#!/usr/bin/env python3
"""Run jobs (JSON lines: {"id":..., "cmd":[...], "out":path}) with <= P parallel processes, a 2 GB RSS
watchdog per process (whole process group polled), stdout+stderr merged into out. Prints TSV id rc wall maxrss_mb."""
import json, os, signal, subprocess, sys, time
P = int(sys.argv[2]) if len(sys.argv) > 2 else 4
CAP_KB = 2 * 1024 * 1024
jobs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
cwd = os.environ.get("RUN_CWD", os.getcwd())
running = {}
results = []
def rss_by_pgid():
    out = subprocess.run(["ps", "-axo", "pgid=,rss="], capture_output=True, text=True).stdout
    d = {}
    for line in out.split("\n"):
        f = line.split()
        if len(f) == 2:
            pg, r = int(f[0]), int(f[1])
            d.setdefault(pg, []).append(r)
    return d
while jobs or running:
    while jobs and len(running) < P:
        j = jobs.pop(0)
        fo = open(j["out"], "wb")
        p = subprocess.Popen(j["cmd"], stdout=fo, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, cwd=cwd, start_new_session=True)
        running[p.pid] = (p, j, time.time(), fo, [0], [False])
    time.sleep(0.05)
    rs = rss_by_pgid()
    for pid in list(running):
        p, j, t0, fo, mx, killed = running[pid]
        for r in rs.get(pid, []):
            mx[0] = max(mx[0], r)
            if r > CAP_KB and not killed[0]:
                os.killpg(pid, signal.SIGKILL); killed[0] = True
        rc = p.poll()
        if rc is not None:
            fo.close()
            dt = time.time() - t0
            print("%s\t%d\t%.3f\t%.1f%s" % (j["id"], rc, dt, mx[0] / 1024.0, "\tMEMKILL" if killed[0] else ""), flush=True)
            del running[pid]
