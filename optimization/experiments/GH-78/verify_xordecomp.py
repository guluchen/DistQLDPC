#!/usr/bin/env python3
"""GH-78 independent checker for `distqldpc -xordecomp-report` output (Python int bitsets; no code
shared with the C++). For each code and half (X: Hpar=Hz, Glog=Gx; Z: Hpar=Hx, Glog=Gz):
  1. every reported generator is a permutation of range(n) mapping every Hpar row into
     rowspace(Hpar) (hence sigma(rowspace Hpar) = rowspace Hpar);
  2. closure of rowspace(Hpar) + chosen rows under the generators contains every Glog row
     iff the report says spans=yes; each chosen row is outside rowspace(Hpar);
  3. decision == decompose iff spans and 1 <= r <= RMAX and r < k;
  4. the greedy selection recomputed here (max closure gain, ties -> lowest row, for k <= 64;
     otherwise first row not yet spanned; stop after RMAX+1 picks) gives the same chosen rows.
Usage: verify_xordecomp.py REPORT_DIR [--rmax 4] [--data data/matrices] [--json OUT]
"""
import argparse, json, re, sys
from pathlib import Path

def load(path):
    rows = []
    for line in open(path):
        t = line.strip()
        if not t or t.startswith('#'):
            continue
        bits = [c for c in t if c in '01']
        rows.append(sum(1 << i for i, c in enumerate(bits) if c == '1'))
        n = len(bits)
    return n, rows

class Span:
    def __init__(self, other=None):
        self.piv = dict(other.piv) if other else {}
    def red(self, v):
        while v:
            h = v.bit_length() - 1
            p = self.piv.get(h)
            if p is None:
                return v
            v ^= p
        return 0
    def add(self, v):
        v = self.red(v)
        if v:
            self.piv[v.bit_length() - 1] = v
            return True
        return False
    def dim(self):
        return len(self.piv)

def perm_apply(p, v):
    o = 0
    while v:
        b = v & -v
        o |= 1 << p[b.bit_length() - 1]
        v ^= b
    return o

def closure(V, g, perms):
    W = Span(V); q = [g]
    while q:
        u = q.pop()
        if W.add(u):
            q.extend(perm_apply(p, u) for p in perms)
    return W

def parse(text):
    halves = {}
    for line in text.splitlines():
        m = re.match(r'c xordecomp ([XZ]) half: n=(\d+) k=(\d+) rank\(Hpar\)=(\d+) candidates=(\d+) verified_generators=(\d+) r=(>?)(\d+) spans=(yes|no) decision=(\S+)', line)
        if m:
            halves[m.group(1)] = dict(n=int(m.group(2)), k=int(m.group(3)), rank=int(m.group(4)), ngen=int(m.group(6)),
                                      aborted=m.group(7) == '>', r=int(m.group(8)), spans=m.group(9) == 'yes',
                                      decision=m.group(10), gens=[], perms=[], chosen=None)
            continue
        m = re.match(r'c xordecomp ([XZ]) generator: (.*)$', line)
        if m: halves[m.group(1)]['gens'].append(m.group(2)); continue
        m = re.match(r'c xordecomp ([XZ]) perm: (.*)$', line)
        if m: halves[m.group(1)]['perms'].append([int(x) for x in m.group(2).split()]); continue
        m = re.match(r'c xordecomp ([XZ]) chosen rows:(.*)$', line)
        if m: halves[m.group(1)]['chosen'] = [int(x) for x in m.group(2).split()]
    return halves

def check_half(h, n, H, G, rmax):
    errs = []
    k = len(G)
    if h['n'] != n or h['k'] != k: errs.append('n/k mismatch')
    R = Span()
    for r in H: R.add(r)
    if R.dim() != h['rank']: errs.append(f'rank {R.dim()} != reported {h["rank"]}')
    if len(h['perms']) != h['ngen'] or len(h['gens']) != h['ngen']: errs.append('generator count mismatch')
    for name, p in zip(h['gens'], h['perms']):
        if sorted(p) != list(range(n)): errs.append(f'{name}: not a permutation'); continue
        if any(R.red(perm_apply(p, r)) for r in H): errs.append(f'{name}: does not preserve rowspace(Hpar)')
    perms = h['perms']
    V = Span(R)
    for j in h['chosen']:
        if R.red(G[j]) == 0: errs.append(f'chosen row {j} in rowspace(Hpar)')
        V = closure(V, G[j], perms)
    spans = all(V.red(g) == 0 for g in G)
    if spans != h['spans']: errs.append(f'spans {spans} != reported {h["spans"]}')
    r = len(h['chosen'])
    dec = spans and 1 <= r <= rmax and r < k
    if dec != (h['decision'] == 'decompose'): errs.append(f'decision mismatch (r={r}, k={k}, spans={spans})')
    # recompute greedy selection
    V = Span(R); chosen = []
    if k > 1 and rmax > 0:
        while True:
            best, bestW = -1, None
            for j in range(k):
                if V.red(G[j]) == 0: continue
                W = closure(V, G[j], perms)
                if bestW is None or W.dim() > bestW.dim(): best, bestW = j, W
                if k > 64: break
            if best < 0: break
            chosen.append(best); V = bestW
            if len(chosen) > rmax: break
    if chosen != h['chosen']: errs.append(f'greedy recomputation {chosen} != reported {h["chosen"]}')
    return errs, dict(k=k, r=r, spans=spans, decompose=dec, generators=h['gens'], chosen=h['chosen'])

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('reports'); ap.add_argument('--rmax', type=int, default=4)
    ap.add_argument('--data', default='data/matrices'); ap.add_argument('--json')
    a = ap.parse_args(); D = Path(a.data); out = {}; bad = 0
    for rep in sorted(Path(a.reports).glob('*.report.txt')):
        stem = rep.name[:-len('.report.txt')]
        n, Hx = load(D / f'{stem}_Hx.txt'); _, Hz = load(D / f'{stem}_Hz.txt')
        _, Gx = load(D / f'{stem}_Gx.txt'); _, Gz = load(D / f'{stem}_Gz.txt')
        halves = parse(rep.read_text()); res = {}
        for tag, H, G in (('X', Hz, Gx), ('Z', Hx, Gz)):
            if tag not in halves: res[tag] = {'errors': ['missing half']}; bad += 1; continue
            errs, info = check_half(halves[tag], n, H, G, a.rmax)
            info['errors'] = errs; res[tag] = info; bad += bool(errs)
        out[stem] = res
        print(('OK  ' if not (res['X']['errors'] or res['Z']['errors']) else 'FAIL'), stem,
              *[f"{t}: k={res[t].get('k')} r={res[t].get('r')} gens={len(res[t].get('generators', []))} {'decompose' if res[t].get('decompose') else 'fallback'} {res[t]['errors'] or ''}" for t in 'XZ'], flush=True)
    if a.json: json.dump(out, open(a.json, 'w'), indent=1)
    print('ALL_OK' if bad == 0 else f'FAIL {bad}')
    return 1 if bad else 0

if __name__ == '__main__': sys.exit(main())
