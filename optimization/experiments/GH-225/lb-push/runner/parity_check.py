#!/usr/bin/env python3
"""Independent parity check (pure Python, no DistQLDPC code): if the GF(2) sum of all rows of H is the all-ones vector, every vector in ker H has even
weight, so odd levels can be skipped for that half. usage: parity_check.py MATRIX_PREFIX..."""
import sys
def rows(path):
    out = []
    for l in open(path):
        if l.startswith('#') or not l.strip(): continue
        out.append([int(x) for x in l.split()])
    return out
for p in sys.argv[1:]:
    for half, f in (('X half (H = Hz)', 'Hz'), ('Z half (H = Hx)', 'Hx')):
        r = rows(f'{p}_{f}.txt'); n = len(r[0]); s = [sum(c) % 2 for c in zip(*r)]
        print(f'{p.split("/")[-1]} {half}: n {n} rows {len(r)} column weights all odd: {all(s)}')
