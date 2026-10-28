#!/usr/bin/env python3
"""Nonzero-rate HGP self-products of cubic-graph cycle codes (GH-154).

Original mathematical constructions only; no graph data/code copied.
GPL-3.0-or-later. Uses Tillich-Zemor arXiv:0903.0566v2, Theorem 1.
"""
import argparse
from itertools import combinations
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LADDER = ('k4', 'k33', 'petersen', 'heawood', 'desargues', 'tutte_coxeter')
EXPECTED = {'k4':(4,6,3), 'k33':(6,9,4), 'petersen':(10,15,5),
            'heawood':(14,21,6), 'desargues':(20,30,6), 'tutte_coxeter':(30,45,8)}


def graph(name):
    if name == 'k4':
        v, edges = 4, list(combinations(range(4),2))
    elif name == 'k33':
        v, edges = 6, [(a,b) for a in range(3) for b in range(3,6)]
    elif name in ('petersen','desargues'):
        pairs = list(combinations(range(5),2))
        base = [(i,j) for i,j in combinations(range(10),2) if set(pairs[i]).isdisjoint(pairs[j])]
        v, edges = (10,base) if name == 'petersen' else (20,[(a,10+b) for u,w in base for a,b in ((u,w),(w,u))])
    elif name == 'heawood':
        lines = sorted({tuple(sorted((a,b,a^b))) for a,b in combinations(range(1,8),2)})
        v, edges = 14, [(p-1,7+i) for i,line in enumerate(lines) for p in line]
    elif name == 'tutte_coxeter':
        points = list(combinations(range(6),2))
        lines = [line for line in combinations(range(15),3)
                 if len({x for i in line for x in points[i]}) == 6]
        v, edges = 30, [(p,15+i) for i,line in enumerate(lines) for p in line]
    else:
        raise ValueError(f'unknown graph: {name}')
    edges = sorted({tuple(sorted(e)) for e in edges})
    if (v,len(edges)) != EXPECTED[name][:2]:
        raise ValueError('unexpected graph dimensions')
    return v, edges


def factor(name):
    v, edges = graph(name)
    # Last incidence row is redundant for a connected graph; keep rows 0..V-2.
    h = [sum((1 << j) for j,e in enumerate(edges) if i in e) for i in range(v-1)]
    return len(edges), h


def product(columns, h):
    """[H x I | I x H^T], [I x H | H^T x I]; second index fastest."""
    m, r = columns, len(h)
    hx, hz = [], []
    for c in range(r):
        for v in range(m):
            left = sum(1 << (w*m+v) for w in range(m) if (h[c] >> w) & 1)
            right = sum(1 << (m*m+c*r+t) for t in range(r) if (h[t] >> v) & 1)
            hx.append(left | right)
    for v in range(m):
        for c in range(r):
            left = sum(1 << (v*m+w) for w in range(m) if (h[c] >> w) & 1)
            right = sum(1 << (m*m+t*r+c) for t in range(r) if (h[t] >> v) & 1)
            hz.append(left | right)
    return m*m+r*r, hx, hz


def generate(name, out):
    m,h = factor(name)
    n,hx,hz = product(m,h)
    k = (m-len(h))**2
    stem = f'HGP_{n}_{k}_unknown'
    out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError(f'{stem}: refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        with (out/f'{stem}_{kind}.txt').open('w') as f:
            f.write(f'# cycle-factor HGP graph={name}; {kind}; arXiv:0903.0566v2\n')
            for row in rows:
                f.write(' '.join(str((row>>i)&1) for i in range(n))+'\n')
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--graph',choices=LADDER)
    group.add_argument('--ladder',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    args = ap.parse_args()
    for name in LADDER if args.ladder else [args.graph]:
        print(generate(name,args.out),flush=True)


if __name__ == '__main__':
    main()
