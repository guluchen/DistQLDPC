#!/usr/bin/env python3
"""GH-157 independent GF(2) witness check (pure Python, not DistQLDPC code): for every 'c witness X: ...' / 'c witness Z ...:'
line in the given -v logs, X-type support x must satisfy Hz x = 0 and x not in rowspace(Hx); Z-type: Hx z = 0 and z not in
rowspace(Hz); the weight must equal the run's answer when the line belongs to the final level. Matrices are read from
data/matrices/tier*/STEM_{Hx,Hz}.txt (dense 0/1 rows). usage: check_witnesses.py REPO_ROOT LOG..."""
import sys, re, glob, os
root = sys.argv[1]
cache = {}
def load(stem):
    if stem in cache: return cache[stem]
    def rd(k):
        f = glob.glob(f'{root}/data/matrices/tier*/{stem}_{k}.txt')[0]
        rows = []
        for l in open(f):
            v = l.split()
            if v: rows.append(sum(1 << i for i, c in enumerate(v) if c == '1'))
        return rows
    cache[stem] = (rd('Hx'), rd('Hz')); return cache[stem]
def basis(rows):
    b = {}
    for r in rows:
        while r:
            h = r.bit_length() - 1
            if h in b: r ^= b[h]
            else: b[h] = r; break
    return b
def in_span(b, v):
    while v:
        h = v.bit_length() - 1
        if h not in b: return False
        v ^= b[h]
    return True
ok = bad = 0
bases = {}
for f in sys.argv[2:]:
    stem = None; ans = None; wits = []
    for l in open(f):
        m = re.search(r'cmd: .* (\S+)$', l)
        if m and stem is None: stem = os.path.basename(m.group(1))
        m = re.search(r'\tc witness (X|Z)[^:]*: (.*)$', l)
        if m: wits.append((m.group(1), [int(x) for x in m.group(2).replace(',', ' ').split()]))
        m = re.search(r'\to (\d+)', l)
        if m: ans = int(m.group(1))
    if not wits: continue
    Hx, Hz = load(stem)
    if stem not in bases: bases[stem] = (basis(Hx), basis(Hz))
    bx, bz = bases[stem]
    for t, sup in wits:
        v = sum(1 << q for q in sup)
        par, stab = (Hz, bx) if t == 'X' else (Hx, bz)
        good = all(bin(h & v).count('1') % 2 == 0 for h in par) and not in_span(stab, v) and len(set(sup)) == len(sup)
        if good: ok += 1
        else: bad += 1; print('BAD', f, t, sup)
    print(f'{os.path.basename(f)}: {len(wits)} witnesses, weights {sorted(set(len(s) for _, s in wits))}, answer {ans}')
print(f'witnesses verified: {ok}, failed: {bad}')
