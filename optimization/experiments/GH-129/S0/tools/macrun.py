#!/usr/bin/env python3
"""GH-129 Mac job runner: <= J concurrent processes, 2 GB RSS cap per job (process-group RSS poll,
status MEMOUT), wall timeout backstop. jobs.jsonl lines: {"id","cmd":[...],"cwd","out","err","timeout"}.
Appends results to results.jsonl: id, rc, status, wall, peak_rss_mb. Skips ids already in results."""
import json, os, signal, subprocess, sys, threading, time
jobs_path, res_path = sys.argv[1], sys.argv[2]
J = int(sys.argv[3]) if len(sys.argv) > 3 else 2
CAP_KB = 2048 * 1024
jobs = [json.loads(l) for l in open(jobs_path) if l.strip()]
done = set()
if os.path.exists(res_path):
    for l in open(res_path):
        try: done.add(json.loads(l)["id"])
        except Exception: pass
todo = [j for j in jobs if j["id"] not in done]
running = {}
def group_rss_kb(pgid):
    try:
        out = subprocess.run(["ps", "-A", "-o", "pgid=,rss="], capture_output=True, text=True).stdout
    except Exception:
        return 0
    s = 0
    for line in out.splitlines():
        p = line.split()
        if len(p) == 2 and p[0] == str(pgid): s += int(p[1])
    return s
def start(j):
    of = open(j["out"], "w"); ef = open(j.get("err", j["out"] + ".err"), "w")
    t0 = time.monotonic()
    p = subprocess.Popen(j["cmd"], cwd=j.get("cwd"), stdout=of, stderr=ef, stdin=subprocess.DEVNULL, start_new_session=True)
    r = dict(p=p, j=j, t0=t0, of=of, ef=ef, peak=0, status=None, t1=None)
    def w():
        p.wait(); r["t1"] = time.monotonic()
    threading.Thread(target=w, daemon=True).start()
    running[p.pid] = r
while todo or running:
    while todo and len(running) < J:
        start(todo.pop(0))
    time.sleep(0.2)
    for pid, r in list(running.items()):
        p = r["p"]
        rss = group_rss_kb(pid)
        r["peak"] = max(r["peak"], rss)
        el = time.monotonic() - r["t0"]
        if r["t1"] is None:
            if rss > CAP_KB and r["status"] is None:
                r["status"] = "MEMOUT"; os.killpg(pid, signal.SIGKILL)
            elif el > r["j"].get("timeout", 1e9) and r["status"] is None:
                r["status"] = "KILLED_TIMEOUT"; os.killpg(pid, signal.SIGKILL)
            continue
        try: os.killpg(pid, signal.SIGKILL)
        except Exception: pass
        r["of"].close(); r["ef"].close()
        rec = dict(id=r["j"]["id"], rc=p.returncode, status=r["status"] or "done", wall=round(r["t1"] - r["t0"], 4), peak_rss_mb=round(r["peak"] / 1024, 1))
        with open(res_path, "a") as f: f.write(json.dumps(rec) + "\n")
        del running[pid]
