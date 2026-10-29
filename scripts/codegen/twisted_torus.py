#!/usr/bin/env python3
"""Original quotient-lattice BB generator (GH-159), GPL-3.0-or-later.

Liang et al., arXiv:2503.03827v3 Tables 1-4, Eqs.(3)-(5).
No external code or matrices copied. The exponent called d in the paper
is called e here to distinguish it from the claimed distance.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
CASES = json.loads(Path(__file__).with_name('twisted_torus_cases.json').read_text())


def reduce_site(x,y,h,w,s):
    if h <= 0 or w <= 0:
        raise ValueError('lattice h and w must be positive')
    q,x = divmod(x,w)
    return x,(y-q*s)%h


def checks(case):
    h,w,s = (case[k] for k in ('h','w','s'))
    if h <= 0 or w <= 0:
        raise ValueError('lattice h and w must be positive')
    v = h*w
    f = [(0,0),(1,0),(case['a'],case['b'])]
    g = [(0,0),(0,1),(case['c'],case['e'])]
    def row(x,y,terms):
        packed = 0
        for block,poly,sign in terms:
            for dx,dy in poly:
                xx,yy = reduce_site(x+sign*dx,y+sign*dy,h,w,s)
                # XOR is required if monomials coincide in the quotient.
                packed ^= 1 << (block*v+xx*h+yy)
        return packed
    hx = [row(x,y,[(0,f,1),(1,g,1)]) for x in range(w) for y in range(h)]
    hz = [row(x,y,[(0,g,-1),(1,f,-1)]) for x in range(w) for y in range(h)]
    return 2*v,hx,hz


def generate(case,out):
    n,hx,hz = checks(case)
    if n != case['n']:
        raise ValueError('case n disagrees with lattice area')
    stem = f'BB_{n}_{case["k"]}_unknown'
    out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError(f'{stem}: refusing to overwrite matrices')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(
            f'# twisted-torus BB; {kind}; arXiv:2503.03827v3 Table {case["table"]}; (0,{case["h"]}),({case["w"]},{case["s"]})\n'+
            ''.join(' '.join(str((r >> j)&1) for j in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--n',type=int,choices=[c['n'] for c in CASES])
    group.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    args = ap.parse_args()
    for case in CASES if args.all else [c for c in CASES if c['n']==args.n]:
        print(generate(case,args.out),flush=True)


if __name__ == '__main__':
    main()
