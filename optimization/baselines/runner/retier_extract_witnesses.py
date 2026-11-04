#!/usr/bin/env python3
"""For each library code (codes.json groups untiered/pr*) and each tier-5 code, print one GF(2)-verified word of the
lightest weight found in its CC logs (witness lines or bundled basis rows), re-checked here from scratch.
usage: extract_witnesses.py RUNDIR > witnesses.txt  (format: STEM TYPE WEIGHT SOURCE_LOG TAG: q1 q2 ...)"""
import glob, json, os, re, sys
sys.argv = [sys.argv[0], sys.argv[1]]
root = sys.argv[1]
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'retier_verify_witnesses.py')).read().split('for f in sys.argv[2:]:')[0])
codes = json.load(open(os.path.join(root, 'codes.json')))
for c in codes:
    best = None
    for f in sorted(glob.glob(os.path.join(root, 'logs', c['stem'] + '.cc*.log')) + glob.glob(os.path.join(root, 'extra*/logs', c['stem'] + '.cc*.log'))):
        wits = []
        for l in open(f):
            m = re.search(r'\tc witness (X|Z)([^:]*): ([\d ]+)\s*$', l)
            if m: wits.append((m.group(1), m.group(2).strip(), [int(x) for x in m.group(3).split()]))
        for t, k in (('X', 'Gz'), ('Z', 'Gx')):
            for g in load(c['path'], k): wits.append((t, 'basis ' + k, [i for i in range(g.bit_length()) if g >> i & 1]))
        cc = code(c['path'])
        for t, tag, sup in wits:
            e = sum(1 << q for q in set(sup))
            other, bsame = (cc['Hz'], cc['bx']) if t == 'X' else (cc['Hx'], cc['bz'])
            if all(bin(e & h).count('1') % 2 == 0 for h in other) and not in_span(bsame, e) and len(set(sup)) == len(sup):
                if best is None or len(sup) < best[2]: best = (t, tag, len(sup), os.path.relpath(f, root), sorted(sup))
    if best: print(c['stem'], best[0], best[2], best[3], best[1] + ':', ' '.join(map(str, best[4])))
