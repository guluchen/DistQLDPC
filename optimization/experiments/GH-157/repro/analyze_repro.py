#!/usr/bin/env python3
"""GH-157 reproduction analysis (from GH-152's): per run, the per-half EMPTY levels from the runner's timestamped
'c cc: <half> half level <w> EMPTY nodes N ... time T' lines; lb(t) = min over the searched halves of (largest level
completed EMPTY, all lower levels EMPTY too) + 1. A dual map (X half only) is detected from the -v line. usage:
analyze_repro.py LOG... (claimed lbs are given in CLAIM below)"""
import re, sys, os
CLAIM = {'TN_360_4_17to24': (23, 21103), 'TN_396_4_17to26': (23, 21564), 'TN_504_2_17to34': (24, 21150), 'TN_648_10_9to32': (22, 20712)}
for f in sys.argv[1:]:
    stem = os.path.basename(f).split('.')[1]
    halves = {'X': {}, 'Z': {}}; dual = False; found = None; final = None
    for l in open(f):
        m = re.match(r'\s*([\d.]+)\tc cc: (X|Z) half level (\d+) (EMPTY|FOUND) nodes (\d+) .*time ([\d.]+)s', l)
        if m: halves[m.group(2)][int(m.group(3))] = (m.group(4), float(m.group(1)), int(m.group(5)), float(m.group(6)))
        if 'searching the X half only' in l: dual = True
        m = re.match(r'\s*([\d.]+)\tc d_lb: (\d+)', l)
        if m: final = int(m.group(2))
    hs = ['X'] if dual else ['X', 'Z']
    def maxempty(h):
        w = 0
        while (w + 1) in halves[h] and halves[h][w + 1][0] == 'EMPTY': w += 1
        return w
    lb = min(maxempty(h) for h in hs) + 1
    claim, tclaim = CLAIM.get(stem, (None, None))
    tl = None
    if claim and lb >= claim:
        tl = max(halves[h][claim - 1][1] for h in hs)
    dec = '; '.join(f"{h}: {halves[h][claim-1][3]:.0f} s / {halves[h][claim-1][2]/1e9:.1f}G" for h in hs if claim and (claim - 1) in halves[h])
    nonempty = [(h, w) for h in hs for w, v in halves[h].items() if v[0] != 'EMPTY']
    print(f"| {stem} | {claim} | {lb} | {'REPRODUCED' if claim and lb >= claim else 'not yet'} | {tclaim} -> {tl if tl is None else round(tl)} | {dec} | non-EMPTY levels: {nonempty or 'none'} | final d_lb line: {final} |")
