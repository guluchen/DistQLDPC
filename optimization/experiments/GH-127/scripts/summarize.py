#!/usr/bin/env python3
"""GH-127: summarize runjobs.py logs (CODE.CFG.MODE.log + .meta) into a TSV.
Columns: code cfg mode rc status d lb ub wall_s peak_rss_mb probes conflicts subprobes subskips expected ok
expected = distance from the stem name (last _N) when numeric, else from --expect FILE (stem<TAB>d).
Usage: summarize.py LOGDIR OUT.tsv [--expect FILE]"""
import argparse, glob, json, os, re

ap = argparse.ArgumentParser()
ap.add_argument("logdir"); ap.add_argument("out"); ap.add_argument("--expect")
a = ap.parse_args()
exp = {}
if a.expect:
    for line in open(a.expect):
        p = line.split()
        if len(p) >= 2 and p[1].lstrip("-").isdigit():
            exp[p[0]] = int(p[1])
rows = []
for log in sorted(glob.glob(os.path.join(a.logdir, "*.log"))):
    base = os.path.basename(log)[:-4]
    code, cfg, mode = base.rsplit(".", 2)
    meta = {}
    if os.path.exists(log + ".meta"):
        meta = json.load(open(log + ".meta"))
    txt = open(log, errors="replace").read()
    m = re.search(r"^o (\d+)$", txt, re.M)
    d = int(m.group(1)) if m else None
    status = "OK" if d is not None else ("TIMEOUT" if "TIMEOUT" in txt else ("MEMOUT" if meta.get("killed_rss") else "UNKNOWN"))
    lbs = re.findall(r"^c d_lb: (\S+)$", txt, re.M)
    ubs = re.findall(r"^c d_ub: (\S+)$", txt, re.M)
    st = re.search(r"dualshare stats: .* probes X (\d+) Z (\d+) conflicts X (\d+) Z (\d+)", txt)
    g = re.search(r"gh127 stats: split X (\d+) Z (\d+) subprobes X (\d+) Z (\d+) subskips X (\d+) Z (\d+)", txt)
    probes = int(st.group(1)) + int(st.group(2)) if st else ""
    confl = int(st.group(3)) + int(st.group(4)) if st else ""
    if not st:   # timeout: no stats line; sum the per-call conflict counters that were printed
        cs = re.findall(r"^c orbit-split: .*\(conflicts (\d+)\)$", txt, re.M)
        if cs:
            confl = "%d+" % sum(int(x) for x in cs)
    subp = int(g.group(3)) + int(g.group(4)) if g else ""
    subs = int(g.group(5)) + int(g.group(6)) if g else ""
    e = exp.get(code)
    if e is None:
        t = code.rsplit("_", 1)[-1]
        e = int(t) if t.isdigit() else None
    ok = "" if e is None or d is None else ("PASS" if d == e else "FAIL")
    if d is None and e is not None:
        ok = status
    rows.append([code, cfg, mode, meta.get("rc", ""), status, d if d is not None else "", lbs[-1] if lbs else "",
                 ubs[-1] if ubs else "", "%.3f" % meta["wall"] if "wall" in meta else "",
                 "%.0f" % (meta.get("peak_rss_kb", 0) / 1024.0), probes, confl, subp, subs, e if e is not None else "", ok])
with open(a.out, "w") as f:
    f.write("\t".join("code cfg mode rc status d lb ub wall_s peak_rss_mb probes conflicts subprobes subskips expected ok".split()) + "\n")
    for r in rows:
        f.write("\t".join(str(x) for x in r) + "\n")
n = len(rows); bad = [r for r in rows if r[-1] not in ("PASS", "")]
print("%d runs, %d PASS, %d not PASS" % (n, sum(1 for r in rows if r[-1] == "PASS"), len(bad)))
for r in bad:
    print("  ", "\t".join(str(x) for x in r))
