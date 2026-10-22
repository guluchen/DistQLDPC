#!/usr/bin/env python3
"""GH-146: independent check of the upper-bound witnesses (pure Python, no DistQLDPC code).

A witness file <stem>.<half>.w<W>.txt holds comment lines (# ...) and one line with the support: W distinct 0-based
qubit indices. For an X-type witness (half X) the checks are Hz e = 0 and e not in rowspace(Hx); for a Z-type witness
(half Z) Hx e = 0 and e not in rowspace(Hz). Then e is a nontrivial logical operator of the CSS code (Hx, Hz) and the
code distance satisfies d <= W. The script also checks the CSS condition Hx Hz^T = 0 and that e has odd overlap with
some row of the matching logical matrix (Gx for X, Gz for Z; the files' convention: X half = (Hz, Gx), Z half = (Hx, Gz)),
which must agree with the rank test. usage: verify_witnesses.py MATRIX_ROOT WITNESS_FILE..."""
import glob, os, sys


def load(path):
    rows = []
    for line in open(path):
        if line.startswith('#'): continue   # comment lines (logical-matrix headers)
        t = line.split()
        if not t: continue
        v = 0
        for i, x in enumerate(t):
            if x == '1': v |= 1 << i
            elif x != '0': raise ValueError(f'{path}: bad entry {x!r}')
        rows.append(v)
        n = len(t)
    return rows, n


def rank(rows):
    piv = {}   # leading bit -> row
    for r in rows:
        while r:
            h = r.bit_length() - 1
            if h in piv: r ^= piv[h]
            else: piv[h] = r; break
    return len(piv), piv


def in_span(piv, v):
    while v:
        h = v.bit_length() - 1
        if h not in piv: return False
        v ^= piv[h]
    return True


root = sys.argv[1]
ok_all = True
for wf in sys.argv[2:]:
    base = os.path.basename(wf)
    stem, half, wtag = base.split('.')[:3]
    sup = None
    for line in open(wf):
        if line.startswith('#') or not line.strip(): continue
        sup = [int(x) for x in line.split()]
    paths = {k: glob.glob(f'{root}/tier*/{stem}_{k}.txt') for k in ('Hx', 'Hz', 'Gx', 'Gz')}
    M = {k: load(p[0]) for k, p in paths.items()}
    n = M['Hx'][1]
    Hx, Hz, Gx, Gz = M['Hx'][0], M['Hz'][0], M['Gx'][0], M['Gz'][0]
    css = all(bin(a & b).count('1') % 2 == 0 for a in Hx for b in Hz)
    H, S, G = (Hz, Hx, Gx) if half == 'X' else (Hx, Hz, Gz)
    e = 0
    for q in sup: e |= 1 << q
    distinct = len(set(sup)) == len(sup) and all(0 <= q < n for q in sup)
    w = bin(e).count('1')
    par = all(bin(h & e).count('1') % 2 == 0 for h in H)
    _, piv = rank(S)
    nontriv = not in_span(piv, e)
    det = any(bin(g & e).count('1') % 2 for g in G)
    ok = css and distinct and w == int(wtag[1:]) and par and nontriv and det
    ok_all &= ok
    print(f'{base}: n {n}, weight {w}, CSS {css}, H e = 0 {par}, not in rowspace(S) {nontriv}, odd overlap with G {det} -> '
          + ('VALID: d <= %d' % w if ok else 'INVALID'))
print('ALL VALID' if ok_all else 'SOME INVALID')
sys.exit(0 if ok_all else 1)
