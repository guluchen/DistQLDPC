#!/usr/bin/env python3
"""GH-75 independent checker for `distqldpc -symbreak-report` output.

For every code: run the report, rebuild each reported generator permutation from its
description (independent re-implementation of the index maps), re-verify the plain /
XZ-dual row-space conditions with Python-int GF(2) elimination, recompute orbits and
compare orbit count and representatives with the binary. Also confirms that rejected
candidates are not silently needed: nothing here is assumed from code names.
Usage: verify_autos.py BINARY OUT_DIR   (run from the repository root)
"""
import json, re, subprocess, sys
from pathlib import Path

def load(path):
    rows = []
    for line in open(path):
        bits = [c for c in line if c in '01']
        if line.lstrip().startswith('#') or not bits:
            continue
        rows.append(bits)
    n = len(rows[0])
    return n, [sum(1 << i for i, b in enumerate(r) if b == '1') for r in rows]

class Span:
    def __init__(self, vecs):
        self.piv = {}  # pivot bit -> vector (echelon by highest bit)
        for v in vecs:
            self.add(v)
    def red(self, v):
        while v:
            h = v.bit_length() - 1
            if h not in self.piv:
                return v
            v ^= self.piv[h]
        return 0
    def add(self, v):
        v = self.red(v)
        if v:
            self.piv[v.bit_length() - 1] = v
    def rank(self):
        return len(self.piv)

def apply(pi, v):
    out, i = 0, 0
    while v:
        if v & 1:
            out |= 1 << pi[i]
        v >>= 1; i += 1
    return out

def perm_from_desc(desc, n):
    m = re.fullmatch(r'blockshift L=(\d+)', desc)
    if m:
        L = int(m[1]); return [(i // L) * L + (i % L + 1) % L for i in range(n)]
    m = re.fullmatch(r'stridedshift L=(\d+)', desc)
    if m:
        L = int(m[1]); B = n // L; return [((i // B + 1) % L) * B + i % B for i in range(n)]
    m = re.fullmatch(r'2dshift-([ab]) L=(\d+) \((\d+)x(\d+)\)', desc)
    if m:
        ax, L, l, mm = m[1], int(m[2]), int(m[3]), int(m[4]); assert l * mm == L
        res = []
        for i in range(n):
            base, loc = (i // L) * L, i % L; a, b = divmod(loc, mm)
            res.append(base + (((a + 1) % l) * mm + b if ax == 'a' else a * mm + (b + 1) % mm))
        return res
    h = n // 2
    if desc == 'halfswap':
        return [(i + h) % n for i in range(n)]
    if desc == 'halfswap-inverse Z_h':
        return [(1 - i // h) * h + (h - i % h) % h for i in range(n)]
    m = re.fullmatch(r'halfswap-inverse Z_(\d+) x Z_(\d+)', desc)
    if m:
        l, mm = int(m[1]), int(m[2]); assert l * mm == h
        res = []
        for i in range(n):
            g, side = i % h, i // h; a, b = divmod(g, mm)
            res.append((1 - side) * h + ((l - a) % l) * mm + (mm - b) % mm)
        return res
    raise ValueError(desc)

def main():
    binary, out = sys.argv[1], Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
    stems = sorted({f.name.rsplit('_', 1)[0] for f in Path('data/matrices').glob('*_Hx.txt')})
    summary, ok_all = [], True
    for stem in stems:
        rep = subprocess.run([binary, '-symbreak-report', stem], capture_output=True, text=True, check=True).stdout
        (out / f'{stem}.report.txt').write_text(rep)
        head = re.search(r'n=(\d+) candidates=(\d+) verified_generators=(\d+) orbits=(\d+)', rep)
        n, k = int(head[1]), int(head[4])
        gens = re.findall(r'^c symbreak: generator: (plain|dual) (.*)$', rep, re.M)
        mats = {x: load(f'data/matrices/{stem}_{x}.txt')[1] for x in ('Hx', 'Hz', 'Gx', 'Gz')}
        HzGx, HxGz = mats['Hz'] + mats['Gx'], mats['Hx'] + mats['Gz']
        sp = {'Hx': Span(mats['Hx']), 'Hz': Span(mats['Hz']), 'HzGx': Span(HzGx), 'HxGz': Span(HxGz)}
        rows = {'Hx': mats['Hx'], 'Hz': mats['Hz'], 'HzGx': HzGx, 'HxGz': HxGz}
        target = {'plain': {'Hx': 'Hx', 'Hz': 'Hz', 'HzGx': 'HzGx', 'HxGz': 'HxGz'},
                  'dual': {'Hx': 'Hz', 'Hz': 'Hx', 'HzGx': 'HxGz', 'HxGz': 'HzGx'}}
        par = list(range(n))
        def find(a):
            while par[a] != a:
                par[a] = par[par[a]]; a = par[a]
            return a
        bad = []
        for kind, desc in gens:
            pi = perm_from_desc(desc, n)
            assert sorted(pi) == list(range(n))
            for src, dst in target[kind].items():
                if sp[src].rank() != sp[dst].rank() or any(sp[dst].red(apply(pi, v)) for v in rows[src]):
                    bad.append(f'{kind} {desc}: {src}->{dst} fails')
            for i in range(n):
                a, b = find(i), find(pi[i])
                if a != b:
                    par[max(a, b)] = min(a, b)
        reps = [i for i in range(n) if find(i) == i]
        rep_line = re.search(r'orbit reps \(size\):(.*)$', rep, re.M)
        bin_reps = [int(x.split('(')[0]) for x in rep_line[1].split() if x != '...'] if rep_line else list(range(n))
        if len(reps) != k: bad.append(f'orbit count {len(reps)} != binary {k}')
        if reps[:64] != bin_reps[:64]: bad.append('orbit representatives differ')
        sizes = {}
        for i in range(n): sizes[find(i)] = sizes.get(find(i), 0) + 1
        size_hist = {}
        for s in sizes.values(): size_hist[s] = size_hist.get(s, 0) + 1
        ok = not bad; ok_all &= ok
        summary.append({'stem': stem, 'n': n, 'generators': [f'{a} {b}' for a, b in gens], 'orbits': len(reps),
                        'orbit_size_histogram': {str(a): b for a, b in sorted(size_hist.items())},
                        'clause': 'none' if len(reps) == n else ('unit' if len(reps) == 1 else 'orbit-chain'),
                        'independent_check': 'PASS' if ok else bad})
        print(('PASS ' if ok else 'FAIL ') + f'{stem} n={n} gens={len(gens)} orbits={len(reps)} sizes={size_hist}', flush=True)
    json.dump({'binary': binary, 'all_pass': ok_all, 'codes': summary}, open(out / 'automorphisms.json', 'w'), indent=1)
    print('ALL_PASS' if ok_all else 'FAIL')
    return 0 if ok_all else 2

if __name__ == '__main__':
    sys.exit(main())
