#!/usr/bin/env python3
"""GH-133 S0 Mac analysis: per code old vs new wall, answer, per-level nodes/time (from -cc-stats). usage: analyze_s0mac.py DIR"""
import glob, os, re, sys, collections
D = sys.argv[1]
res = {}
for l in open(f'{D}/results.tsv'):
    f = l.rstrip('\n').split('\t')
    if len(f) < 5: continue
    res[f[0]] = dict(rc=int(f[1]), wall=float(f[2]), rss=float(f[3]), ans=f[4], memkill=len(f) > 5)
def levels(path):
    out = {}
    for l in open(path, errors='replace'):
        m = re.match(r'c cc-stats: (\w) level (\d+) (\w+) nodes (\d+) seeds (\d+) closed (\d+) nocand (\d+) packprune (\d+)(?: parprune (\d+) leaf1 (\d+) leaf2 (\d+))? time ([\d.]+)s', l)
        if m: out[(m.group(1), int(m.group(2)))] = dict(verdict=m.group(3), nodes=int(m.group(4)), time=float(m.group(12)), leaf2=int(m.group(11) or 0), parprune=int(m.group(9) or 0))
    return out
codes = sorted(set(k.rsplit('.', 1)[0] for k in res), key=lambda c: (int(c[1]), c))
print('| Tier | Code | old wall s | new wall s | ratio | answers (old/new) | top levels old nodes -> new nodes (time s) |')
print('|---:|---|---:|---:|---:|---|---|')
for c in codes:
    o, n = res.get(c + '.old'), res.get(c + '.new')
    lo = levels(f'{D}/{c}.old.log') if o else {}; ln = levels(f'{D}/{c}.new.log') if n else {}
    keys = sorted(set(lo) | set(ln), key=lambda k: (k[1], k[0]))[-4:]
    det = '; '.join(f'{h}{w}: {lo[(h,w)]["nodes"] if (h,w) in lo else "-"}->{ln[(h,w)]["nodes"] if (h,w) in ln else "skip/-"} ({lo[(h,w)]["time"] if (h,w) in lo else "-"}/{ln[(h,w)]["time"] if (h,w) in ln else "-"})' for h, w in keys)
    ratio = f'{n["wall"]/o["wall"]:.3f}' if o and n else '-'
    print(f'| {c[1]} | {c[3:]} | {o["wall"] if o else "-"} | {n["wall"] if n else "-"} | {ratio} | {o["ans"] if o else "-"}/{n["ans"] if n else "-"} | {det} |')
