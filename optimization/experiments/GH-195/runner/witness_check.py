#!/usr/bin/env python3
"""GH-195 independent GF(2) witness check (no DistQLDPC code, no external solver). For every -cc-trace file: each
FOUND line (half level verdict nodes seconds support...) and each UB-SEARCH line (half level UB-SEARCH iters seconds
support...) gives a support x. Check, in the half's own convention (X half: H = Hz, trivial = rs Hx; Z half: H = Hx,
trivial = rs Hz): H x = 0, x not in the row space of the same-type stabilizers, and |x| = the stated weight (FOUND:
the level; UB-SEARCH: the number printed after the half tag). The witness of the final answer must have weight d.
usage: witness_check.py MATRIXROOT TRACE...   (code stem taken from the trace file name ans.STEM.variant.trace)"""
import glob, re, sys

def load(path):
    rows = []
    for line in open(path):
        t = line.split()
        if t: rows.append(int(''.join(t[::-1]), 2) if set(t) <= {'0', '1'} else None)
    return rows

def basis(rows):
    b = {}
    for r in rows:
        while r:
            h = r.bit_length() - 1
            if h in b: r ^= b[h]
            else: b[h] = r; break
    return b

def in_span(b, x):
    while x:
        h = x.bit_length() - 1
        if h not in b: return False
        x ^= b[h]
    return True

root = sys.argv[1]; ok = bad = 0; cache = {}
for tr in sys.argv[2:]:
    stem = tr.split('/')[-1].split('.')[1]
    if stem not in cache:
        base = glob.glob(f'{root}/tier*/{stem}_Hx.txt')[0][:-7]
        Hx, Hz = load(base + '_Hx.txt'), load(base + '_Hz.txt')
        cache[stem] = dict(X=(Hz, basis(Hx)), Z=(Hx, basis(Hz)))
    d = None; final = []
    for line in open(tr):
        if line.startswith('# d '): d = int(line.split()[2])
        t = line.split()
        if len(t) >= 6 and t[2] in ('FOUND', 'UB-SEARCH'):
            half, w = t[0], int(t[1]); sup = [int(v) for v in t[5:]]
            x = 0
            for q in sup: x |= 1 << q
            H, B = cache[stem][half]
            good = len(sup) == w and bin(x).count('1') == w and all(bin(h & x).count('1') % 2 == 0 for h in H) and not in_span(B, x)
            if good: ok += 1; final.append(w)
            else: bad += 1; print('BAD', tr, line.strip()[:120])
    if d is not None and d >= 0 and final and min(final) != d:
        bad += 1; print('BAD final', tr, 'd', d, 'min witness', min(final))
print(f'witness_check: {ok} witnesses ok, {bad} bad, {len(sys.argv) - 2} traces')
