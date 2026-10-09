#!/usr/bin/env python3
"""GH-85 independent checker for `distqldpc -symbreak-report` (per CSS half).

Half X: Hpar = Hz, Glog = Gx.  Half Z: Hpar = Hx, Glog = Gz.
A kept permutation pi must satisfy pi(rs Hpar) = rs Hpar and pi(rs [Hpar;Glog]) = rs [Hpar;Glog].
For every code and half this script
  1. rebuilds every generator reported by the binary from its description (own index-map code),
     checks it is a permutation and re-verifies both row-space equalities with Python-int GF(2)
     elimination (rank equality + every permuted row reduces to zero)  -> soundness;
  2. independently enumerates the same generic candidate family, verifies each candidate and
     compares the accepted set with the binary's generator list           -> same detection;
  3. recomputes orbits (union-find) and compares orbit count, representatives and sizes.
It never uses code names. Usage: verify_half_autos.py BINARY OUT_DIR  (run from repo root).
"""
import json, re, subprocess, sys
from pathlib import Path

def load(path):
    rows = []
    for line in open(path):
        if line.lstrip().startswith('#'):
            continue
        bits = [c for c in line if c in '01']
        if bits:
            rows.append(bits)
    n = len(rows[0])
    assert all(len(r) == n for r in rows)
    return n, [sum(1 << i for i, b in enumerate(r) if b == '1') for r in rows]

class Span:
    def __init__(self, vecs):
        self.piv = {}
        for v in vecs:
            v = self.red(v)
            if v:
                self.piv[v.bit_length() - 1] = v
    def red(self, v):
        while v:
            h = v.bit_length() - 1
            if h not in self.piv:
                return v
            v ^= self.piv[h]
        return 0

def apply(pi, v):
    out, i = 0, 0
    while v:
        if v & 1:
            out |= 1 << pi[i]
        v >>= 1; i += 1
    return out

def candidates(n):
    """Independent re-implementation of the generic candidate family (desc -> perm)."""
    out = {}
    def add(desc, p):
        if p != list(range(n)) and p not in out.values():
            out[desc] = p
    for L in range(2, n + 1):
        if n % L:
            continue
        B = n // L
        add(f'blockshift L={L}', [(i // L) * L + (i % L + 1) % L for i in range(n)])
        add(f'stridedshift L={L}', [((i // B + 1) % L) * B + i % B for i in range(n)])
        for l in range(2, L):
            if L % l or L // l < 2:
                continue
            m = L // l
            add(f'2dshift-a L={L} ({l}x{m})', [(i // L) * L + (((i % L) // m + 1) % l) * m + (i % L) % m for i in range(n)])
            add(f'2dshift-b L={L} ({l}x{m})', [(i // L) * L + ((i % L) // m) * m + ((i % L) % m + 1) % m for i in range(n)])
    if n % 2 == 0:
        h = n // 2
        add('halfswap', [(i + h) % n for i in range(n)])
        add('halfswap-inverse Z_h', [(1 - i // h) * h + (h - i % h) % h for i in range(n)])
        for l in range(2, h):
            if h % l or h // l < 2:
                continue
            m = h // l
            res = []
            for i in range(n):
                g, side = i % h, i // h
                a, b = divmod(g, m)
                res.append((1 - side) * h + ((l - a) % l) * m + (m - b) % m)
            add(f'halfswap-inverse Z_{l} x Z_{m}', res)
    return out

def keeps(pi, spaces):
    for rows, sp, rank in spaces:
        for v in rows:
            if sp.red(apply(pi, v)):
                return False
    return True

def orbits(n, perms):
    par = list(range(n))
    def find(a):
        while par[a] != a:
            par[a] = par[par[a]]; a = par[a]
        return a
    for pi in perms:
        for i in range(n):
            a, b = find(i), find(pi[i])
            if a != b:
                par[max(a, b)] = min(a, b)
    root = [find(i) for i in range(n)]
    reps = [i for i in range(n) if root[i] == i]
    size = {r: root.count(r) for r in reps}
    return reps, size

def main():
    binary, out = sys.argv[1], Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
    stems = sorted({f.name.rsplit('_', 1)[0] for f in Path('data/matrices').glob('*_Hx.txt')})
    summary, ok_all = [], True
    for stem in stems:
        rep = subprocess.run([binary, '-symbreak-report', stem], capture_output=True, text=True, check=True).stdout
        (out / f'{stem}.report.txt').write_text(rep)
        M = {x: load(f'data/matrices/{stem}_{x}.txt') for x in ('Hx', 'Hz', 'Gx', 'Gz')}
        n = M['Hx'][0]
        cands = candidates(n)
        entry = {'stem': stem, 'n': n}
        for half, hp, gl in (('X', 'Hz', 'Gx'), ('Z', 'Hx', 'Gz')):
            bad = []
            H, G = M[hp][1], M[gl][1]
            if not G:
                entry[half] = {'absent': True}
                if f'c symbreak {half}: no logical rows' not in rep: bad.append('absent half not reported')
                continue
            spH, spHG = Span(H), Span(H + G)
            spaces = [(H, spH, len(spH.piv)), (H + G, spHG, len(spHG.piv))]
            head = re.search(rf'^c symbreak {half}: n=(\d+) candidates=(\d+) verified_generators=(\d+) orbits=(\d+)', rep, re.M)
            gens = re.findall(rf'^c symbreak {half}: generator: plain (.*)$', rep, re.M)
            if re.search(rf'^c symbreak {half}: generator: (?!plain )', rep, re.M): bad.append('non-plain generator reported')
            if int(head[1]) != n: bad.append('n mismatch')
            if int(head[2]) != len(cands): bad.append(f'candidate count {head[2]} != {len(cands)}')
            perms = []
            for desc in gens:
                if desc not in cands:
                    bad.append(f'unknown generator {desc}'); continue
                pi = cands[desc]
                assert sorted(pi) == list(range(n))
                if not keeps(pi, spaces): bad.append(f'generator {desc} FAILS half conditions')
                perms.append(pi)
            accepted = [d for d, pi in cands.items() if keeps(pi, spaces)]
            if accepted != gens: bad.append(f'accepted set differs: python={accepted} binary={gens}')
            reps, size = orbits(n, perms)
            if len(reps) != int(head[4]): bad.append(f'orbit count {len(reps)} != binary {head[4]}')
            line = re.search(rf'^c symbreak {half}: orbit reps \(size\):(.*)$', rep, re.M)
            bin_pairs = [tuple(map(int, re.fullmatch(r'(\d+)\((\d+)\)', x).groups())) for x in line[1].split()] if line else [(i, 1) for i in range(n)]
            if bin_pairs != [(r, size[r]) for r in reps]: bad.append('orbit representatives/sizes differ')
            hist = {}
            for r in reps: hist[size[r]] = hist.get(size[r], 0) + 1
            k = len(reps)
            entry[half] = {'generators': gens, 'orbits': k, 'orbit_size_histogram': {str(a): b for a, b in sorted(hist.items())},
                           'clause': 'none' if k == n else ('unit' if k == 1 else 'orbit-chain'),
                           'independent_check': 'PASS' if not bad else bad}
            ok_all &= not bad
            print(('PASS ' if not bad else 'FAIL ') + f'{stem} {half} n={n} gens={len(gens)} orbits={k} sizes={hist}', flush=True)
        summary.append(entry)
    json.dump({'binary': binary, 'all_pass': ok_all, 'codes': summary}, open(out / 'half_automorphisms.json', 'w'), indent=1)
    print('ALL_PASS' if ok_all else 'FAIL')
    return 0 if ok_all else 2

if __name__ == '__main__':
    sys.exit(main())
