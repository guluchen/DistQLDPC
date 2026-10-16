#!/usr/bin/env python3
"""Run a list of jobs (JSON lines: {"cmd": [...], "out": path, "cwd": dir}) with at most P concurrent
processes, each watched for RSS (process group sum) <= 2 GB; killed if exceeded. Writes stdout+stderr
to out, and out + '.meta' with exit code, wall, peak rss."""
import json, os, signal, subprocess, sys, time

LIMIT_KB = 2 * 1024 * 1024  # 2 GB

def group_rss_kb(pgid):
    try:
        out = subprocess.run(["ps", "-A", "-o", "pgid=,rss="], capture_output=True, text=True).stdout
    except Exception:
        return 0
    tot = 0
    for line in out.splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[0] == str(pgid):
            tot += int(parts[1])
    return tot

def main():
    jobs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
    P = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    running = []
    idx = 0
    while idx < len(jobs) or running:
        while idx < len(jobs) and len(running) < P:
            j = jobs[idx]; idx += 1
            f = open(j["out"], "wb")
            p = subprocess.Popen(j["cmd"], cwd=j.get("cwd"), stdout=f, stderr=subprocess.STDOUT,
                                 stdin=subprocess.DEVNULL, start_new_session=True)
            running.append({"p": p, "f": f, "j": j, "t0": time.time(), "peak": 0, "killed": False})
        time.sleep(0.05)
        for r in list(running):
            p = r["p"]
            rss = group_rss_kb(p.pid)
            r["peak"] = max(r["peak"], rss)
            if rss > LIMIT_KB and not r["killed"]:
                os.killpg(p.pid, signal.SIGKILL); r["killed"] = True
            if p.poll() is not None:
                r["f"].close()
                with open(r["j"]["out"] + ".meta", "w") as m:
                    json.dump({"rc": p.returncode, "wall": time.time() - r["t0"], "peak_rss_kb": r["peak"],
                               "killed_rss": r["killed"], "cmd": r["j"]["cmd"]}, m)
                running.remove(r)

if __name__ == "__main__":
    main()
