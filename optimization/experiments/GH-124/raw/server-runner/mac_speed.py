#!/usr/bin/env python3
"""Serial Mac runs of -engine=cc for the server/Mac speed ratio (GH-124 S0d).
Each run: one process (plus the binary's forked child), process-group RSS polled every 0.25 s and killed above
2 GB (status MEMOUT). Run the whole script under `caffeinate -i -s`.
usage: mac_speed.py BIN REPO OUTDIR REPS CODE..."""
import json, os, signal, subprocess, sys, time

BIN, REPO, OUT, REPS = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
codes = sys.argv[5:]
os.makedirs(OUT, exist_ok=True)
CAP_KB = 2 * 1024 * 1024


def group_rss_kb(pgid):
    out = subprocess.run(["ps", "-A", "-o", "pgid=,rss="], capture_output=True, text=True).stdout
    return sum(int(r) for g, r in (l.split() for l in out.splitlines() if l.strip()) if int(g) == pgid)


for rep in range(1, REPS + 1):
    for code in codes:
        extra = os.environ.get("EXTRA", "").split()
        tag = os.environ.get("TAG", "")
        i = f"mac_{os.path.basename(code)}{tag}_rep{rep}"
        cmd = [BIN, code, "-engine=cc", "-cc-stats", "-cpu-lim=3600", "-cc-trace=" + os.path.join(OUT, i + ".trace")] + extra
        t0 = time.monotonic(); peak = 0; status = "done"
        with open(os.path.join(OUT, i + ".log"), "w") as lf:
            lf.write("# cmd: " + " ".join(cmd) + "\n"); lf.flush()
            p = subprocess.Popen(cmd, cwd=REPO, stdout=lf, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                                 start_new_session=True)
            while p.poll() is None:
                rss = group_rss_kb(p.pid); peak = max(peak, rss)
                if rss > CAP_KB:
                    os.killpg(p.pid, signal.SIGKILL); status = "MEMOUT"; p.wait(); break
                time.sleep(0.25)
        wall = time.monotonic() - t0
        rec = dict(id=i, code=code, rc=p.returncode, wall=round(wall, 3), peak_rss_kb=peak, status=status,
                   end=round(time.time(), 3))
        with open(os.path.join(OUT, "results.jsonl"), "a") as f:
            f.write(json.dumps(rec) + "\n")
        print(json.dumps(rec), flush=True)
