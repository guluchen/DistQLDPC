#!/usr/bin/env python3
"""GH-124 S0d/S0e job runner for yfclab2.

One thread per assigned core; each core runs its own job list sequentially, every process as
  taskset -c CORE prlimit --as=4294967296 -- BIN CODE ARGS -cpu-lim=CAP [-cc-trace=OUT/ID.trace]
The binary's -cpu-lim (wall clock) is the cap; the runner kills the process group at CAP + 600 s as a backstop.
usage: runner.py BIN JOBS.jsonl OUTDIR
job: {"id": str, "core": int, "cap": int, "code": path prefix, "args": [..], "trace": bool}
"""
import json, os, signal, subprocess, sys, threading, time

BIN, JOBS, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(OUT, exist_ok=True)
jobs = [json.loads(l) for l in open(JOBS) if l.strip()]
allowed = set(range(0, 64))
for j in jobs:
    assert j["core"] in allowed, j
ids = [j["id"] for j in jobs]
assert len(ids) == len(set(ids)), "duplicate job ids"
lock = threading.Lock()
by_core = {}
for j in jobs:
    by_core.setdefault(j["core"], []).append(j)


def record(rec):
    with lock:
        with open(os.path.join(OUT, "results.jsonl"), "a") as f:
            f.write(json.dumps(rec) + "\n")


def run(j):
    log = os.path.join(OUT, j["id"] + ".log")
    cmd = ["taskset", "-c", str(j["core"]), "prlimit", "--as=4294967296", "--", BIN, j["code"]] + j["args"] + \
          ["-cpu-lim=%d" % j["cap"]]
    if j.get("trace"):
        cmd.append("-cc-trace=" + os.path.join(OUT, j["id"] + ".trace"))
    with open(os.path.join(OUT, j["id"] + ".started"), "w") as f:
        f.write(" ".join(cmd) + "\n%.3f\n" % time.time())
    t0 = time.monotonic(); start = time.time(); killed = False
    with open(log, "w") as lf:
        lf.write("# cmd: " + " ".join(cmd) + "\n")
        lf.flush()
        p = subprocess.Popen(cmd, stdout=lf, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                             start_new_session=True)
        while True:
            pid, status, ru = os.wait4(p.pid, os.WNOHANG)
            if pid == p.pid:
                break
            if time.monotonic() - t0 > j["cap"] + 600 and not killed:
                killed = True
                try:
                    os.killpg(p.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            time.sleep(0.2)
    wall = time.monotonic() - t0
    rc = os.waitstatus_to_exitcode(status)
    rec = dict(id=j["id"], core=j["core"], cap=j["cap"], code=j["code"], args=j["args"], rc=rc,
               wall=round(wall, 3), maxrss_kb=ru.ru_maxrss, utime=round(ru.ru_utime, 3),
               start=round(start, 3), end=round(time.time(), 3), runner_killed=killed)
    record(rec)
    os.rename(os.path.join(OUT, j["id"] + ".started"), os.path.join(OUT, j["id"] + ".done"))


def worker(core):
    for j in by_core[core]:
        try:
            run(j)
        except Exception as e:  # keep the queue going; record the failure
            record(dict(id=j["id"], core=core, error=repr(e)))


threads = [threading.Thread(target=worker, args=(c,)) for c in sorted(by_core)]
for t in threads:
    t.start()
for t in threads:
    t.join()
with open(os.path.join(OUT, "RUNNER_DONE"), "w") as f:
    f.write("%.3f %d jobs\n" % (time.time(), len(jobs)))
