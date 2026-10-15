#!/usr/bin/env python3
"""GH-124 S0 smoke: run bin/distqldpc -engine=cc (serially, one process at a time) on every code of the
given tiers in both card modes and check 'o N' against the stem's distance.

Usage: smoke_cc.py [--bin bin/distqldpc] [--cpu-lim 300] [--out DIR] [--extra=FLAG ...] [--modes M1,M2] [--tag T] tier0 ...
Writes DIR/smoke_<tiers>.tsv and DIR/raw/<code>_<mode>.log. Memory: the CC engine needs a few MB; the
parent's -cpu-lim is the wall limit, and each run is additionally capped with RLIMIT_AS = 2 GB where the OS
supports it (macOS does not enforce RLIMIT_AS; RSS is reported from wait4)."""
import argparse, os, re, resource, subprocess, sys, time

ap = argparse.ArgumentParser()
ap.add_argument("--bin", default="bin/distqldpc")
ap.add_argument("--cpu-lim", type=int, default=300)
ap.add_argument("--out", default="optimization/experiments/GH-124/S0")
ap.add_argument("--extra", action="append", default=[])
ap.add_argument("--modes", default="-no-card,-card-mto")
ap.add_argument("--tag", default="", help="suffix for the TSV name and the raw-log directory")
ap.add_argument("tiers", nargs="+")
a = ap.parse_args()

raw = os.path.join(a.out, "raw" + ("_" + a.tag if a.tag else ""))
os.makedirs(raw, exist_ok=True)
rows, bad = [], 0
for tier in a.tiers:
    d = os.path.join("data/matrices", tier)
    stems = sorted(f[:-7] for f in os.listdir(d) if f.endswith("_Hx.txt"))
    for stem in stems:
        m = re.match(r"^[A-Z]+_\d+_\d+_(\d+)$", stem)
        expect = int(m.group(1)) if m else None
        for mode in a.modes.split(","):
            cmd = [a.bin, "-engine=cc", mode, "-cpu-lim=%d" % a.cpu_lim] + a.extra + [stem]
            t0 = time.time()
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            _, status, ru = os.wait4(p.pid, 0)
            out = p.stdout.read().decode()
            dt = time.time() - t0
            rss_mb = ru.ru_maxrss / (1024 * 1024 if sys.platform == "darwin" else 1024)
            got = None
            for line in out.splitlines():
                if line.startswith("o "):
                    got = int(line.split()[1])
            ok = got is not None and (expect is None or got == expect)
            if not ok:
                bad += 1
            rows.append((tier, stem, mode, expect, got, "%.3f" % dt, "%.1f" % rss_mb, "OK" if ok else "MISMATCH"))
            with open(os.path.join(raw, "%s%s.log" % (stem, mode)), "w") as f:
                f.write("$ " + " ".join(cmd) + "\n" + out)
            print("\t".join(str(x) for x in rows[-1]), flush=True)
name = os.path.join(a.out, "smoke_%s%s.tsv" % ("_".join(a.tiers), "_" + a.tag if a.tag else ""))
with open(name, "w") as f:
    f.write("tier\tstem\tmode\texpected_d\tgot\twall_s\tmax_rss_mb\tverdict\n")
    for r in rows:
        f.write("\t".join(str(x) for x in r) + "\n")
print("%d runs, %d mismatches -> %s" % (len(rows), bad, name))
sys.exit(1 if bad else 0)
