#!/usr/bin/env python3
"""Ground-truth consistency check found during GH-79 offline analysis.

For every bundled code, each logical row g of Gx (Gz) is checked to be a nontrivial
logical: g commutes with every Hx (Hz) row and g is not in rowspace(Hz) (rowspace(Hx)),
by exact GF(2) reduction. Its weight is then an upper bound on the distance; a row
lighter than the distance named in the file stem means the name and the matrices disagree.
Usage: check_named_vs_rows.py <data/matrices>
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from conj_offline import load, echelon, reduce, wt

m = sys.argv[1]
codes = sorted({f.rsplit('_', 1)[0] for f in os.listdir(m) if f.endswith('_Hx.txt')})
bad = 0
for c in codes:
    Hx, n = load(f'{m}/{c}_Hx.txt'); Hz, _ = load(f'{m}/{c}_Hz.txt')
    Gx, _ = load(f'{m}/{c}_Gx.txt'); Gz, _ = load(f'{m}/{c}_Gz.txt')
    bx, bz = echelon(Hx, list(range(n))), echelon(Hz, list(range(n)))
    best = None
    for G, Hc, bs in ((Gx, Hx, bz), (Gz, Hz, bx)):
        for g in G:
            if all(bin(g & h).count('1') % 2 == 0 for h in Hc) and reduce(g, bs) != 0:
                best = wt(g) if best is None else min(best, wt(g))
    d = c.split('_')[-1]
    named = int(d) if d.isdigit() and not c.startswith(('xu_', 'PK_')) else None
    flag = named is not None and best is not None and best < named
    bad += flag
    print('%-22s named=%-5s lightest verified nontrivial logical row=%s%s' % (c, named, best, '  <-- BELOW NAMED DISTANCE' if flag else ''))
print('inconsistent codes:', bad)
