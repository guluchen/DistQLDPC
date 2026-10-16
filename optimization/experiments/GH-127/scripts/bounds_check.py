#!/usr/bin/env python3
"""GH-127: anytime-bound check of quiet runs (CODE.CFG.MODE.log): every live 'c d_lb: x' <= d <= every 'c d_ub: y',
the d_lb sequence is non-decreasing and the d_ub sequence non-increasing; d = the run's 'o d' (must equal the expected
d from the stem or --expect FILE). Usage: bounds_check.py LOGDIR [--expect FILE]"""
import glob, os, re, sys
exp = {}
if "--expect" in sys.argv:
    for l in open(sys.argv[sys.argv.index("--expect") + 1]):
        p = l.split()
        if len(p) == 2 and p[1].isdigit():
            exp[p[0]] = int(p[1])
n = bad = 0
for f in sorted(glob.glob(os.path.join(sys.argv[1], "*.log"))):
    code = os.path.basename(f).rsplit(".", 3)[0]
    t = open(f).read()
    m = re.search(r"^o (\d+)$", t, re.M)
    e = exp.get(code)
    if e is None and code.rsplit("_", 1)[-1].isdigit():
        e = int(code.rsplit("_", 1)[-1])
    lbs = [int(x) for x in re.findall(r"^c d_lb: (\d+)$", t, re.M)]
    ubs = [int(x) for x in re.findall(r"^c d_ub: (\d+)$", t, re.M)]
    probs = []
    if not m or int(m.group(1)) != e: probs.append("d %s expected %s" % (m.group(1) if m else None, e))
    if e is not None:
        if any(x > e for x in lbs): probs.append("lb above d")
        if any(y < e for y in ubs): probs.append("ub below d")
    if lbs != sorted(lbs): probs.append("lb not monotone %s" % lbs)
    if ubs != sorted(ubs, reverse=True): probs.append("ub not monotone %s" % ubs)
    n += 1
    if probs:
        bad += 1
        print(os.path.basename(f), "; ".join(probs))
print("%d runs, %d with a problem" % (n, bad))
