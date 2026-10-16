#!/usr/bin/env python3
"""GH-127: markdown tables from the summarize.py TSVs.
Usage: tables.py correctness TSV...        -> pass/fail per (set, cfg, mode)
       tables.py work CFGS TSV...           -> per code x mode: conflicts (ratio to default) and wall per cfg"""
import csv, os, sys
from collections import OrderedDict, defaultdict


def load(paths):
    rows = []
    for p in paths:
        for r in csv.DictReader(open(p), delimiter="\t"):
            r["set"] = os.path.basename(p)[:-4]
            rows.append(r)
    return rows


if sys.argv[1] == "correctness":
    rows = load(sys.argv[2:])
    agg = OrderedDict()
    for r in rows:
        k = (r["set"], r["cfg"], r["mode"])
        a = agg.setdefault(k, [0, 0, []])
        a[0] += 1
        if r["ok"] == "PASS":
            a[1] += 1
        else:
            a[2].append("%s=%s" % (r["code"], r["ok"] or r["status"]))
    print("| set | config | mode | runs | PASS | not PASS |")
    print("|---|---|---|---|---|---|")
    for (s, c, m), (n, p, bad) in sorted(agg.items()):
        print("| %s | %s | %s | %d | %d | %s |" % (s, c, m, n, p, ", ".join(bad) or "-"))
else:
    cfgs = sys.argv[2].split(",")
    rows = load(sys.argv[3:])
    D = {}
    order = OrderedDict()
    for r in rows:
        D[(r["code"], r["mode"], r["cfg"])] = r
        order[(r["code"], r["mode"])] = 1
    print("| code | mode | " + " | ".join("%s conflicts (x def) / wall s" % c for c in cfgs) + " |")
    print("|---|---|" + "---|" * len(cfgs))
    for (code, mode) in order:
        base = D.get((code, mode, "default"))
        cells = []
        for c in cfgs:
            r = D.get((code, mode, c))
            if r is None:
                cells.append("n/a")
                continue
            conf, wall = r["conflicts"], r["wall_s"]
            st = "" if r["status"] == "OK" else " **%s**" % r["status"]
            ratio = ""
            if base and c != "default" and base["conflicts"].isdigit() and conf.isdigit() and int(base["conflicts"]) > 0:
                ratio = " (%.2f)" % (int(conf) / int(base["conflicts"]))
            cells.append("%s%s / %s%s" % (conf, ratio, wall, st))
        print("| %s | %s | %s |" % (code, mode, " | ".join(cells)))
