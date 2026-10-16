#!/usr/bin/env python3
"""GH-127 S0 identity: default path of the candidate vs frozen main abd1770.
For every tier0+tier1 code x {-no-card, -card-mto}: main -v, candidate -v, candidate -v with the explicit
default flags (-orbit-split=off -lb-ladder=doubling), and quiet runs of both. Serial (one solver process at a
time), RSS watchdog 2 GB. A -v difference is re-run up to 3 times per binary (parent/child pipe interleaving
is run-to-run nondeterministic in main too, see GH-124 S0); the case passes if some candidate log equals some
main log byte for byte.
Usage: identity.py CAND_BIN MAIN_BIN REPO OUT_TXT"""
import hashlib, os, subprocess, sys, threading, time

cand, main, repo, out_path = sys.argv[1:5]
LIMIT = 2 * 1024 ** 3
codes = []
for t in ("tier0", "tier1"):
    d = os.path.join(repo, "data/matrices", t)
    codes += sorted({f[:-7] for f in os.listdir(d) if f.endswith("_Hx.txt")})


def run(cmd):
    p = subprocess.Popen(cmd, cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    buf = []
    th = threading.Thread(target=lambda: buf.append(p.stdout.read()))
    th.start()
    while p.poll() is None:
        try:
            rss = int(subprocess.run(["ps", "-o", "rss=", "-p", str(p.pid)], capture_output=True, text=True).stdout.strip() or 0) * 1024
        except ValueError:
            rss = 0
        if rss > LIMIT:
            p.kill()
        time.sleep(0.1)
    th.join()
    return buf[0]


h = lambda b: hashlib.sha256(b).hexdigest()[:16]
lines = ["# GH-127 S0 identity: candidate %s (sha256 %s) vs frozen main abd1770 %s (sha256 %s)" % (
    cand, hashlib.sha256(open(cand, "rb").read()).hexdigest(), main, hashlib.sha256(open(main, "rb").read()).hexdigest()),
    "# columns: code mode | -v default | -v -orbit-split=off -lb-ladder=doubling | quiet default | tries | sha256(main -v)"]
bad = 0
for code in codes:
    for mode in ("-no-card", "-card-mto"):
        lim = "-cpu-lim=600"
        mains, cands, cexp = [], [], []
        for attempt in range(3):
            mains.append(run([main, "-v", mode, lim, code]))
            cands.append(run([cand, "-v", mode, lim, code]))
            cexp.append(run([cand, "-v", "-orbit-split=off", "-lb-ladder=doubling", mode, lim, code]))
            ok1 = any(c == m for c in cands for m in mains)
            ok2 = any(c == m for c in cexp for m in mains)
            if ok1 and ok2:
                break
        mq = run([main, mode, lim, code])
        cq = run([cand, mode, lim, code])
        r = ["identical" if ok1 else "DIFFERENT", "identical" if ok2 else "DIFFERENT",
             "identical" if mq == cq else "DIFFERENT"]
        if "DIFFERENT" in r:
            bad += 1
        lines.append("%s %s | %s | %d | %s" % (code, mode, " | ".join(r), len(mains), h(mains[0])))
        print(lines[-1], flush=True)
lines.append("# %d cases, %d with a difference" % (2 * len(codes), bad))
open(out_path, "w").write("\n".join(lines) + "\n")
print(lines[-1])
sys.exit(1 if bad else 0)
