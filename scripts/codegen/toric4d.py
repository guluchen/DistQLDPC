#!/usr/bin/env python3
"""Original periodic4D face-qubit CSS construction, arXiv1609.00510v2 Sec2.

GPL-3.0-or-later. Published mathematics only; no external code/matrices.
"""
import argparse
from itertools import combinations,product
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('toric4d_cases.json')


def checks(shape):
    if len(shape)!=4 or any(type(L)!=int or L<2 for L in shape):raise ValueError('four integer side lengths>=2 required')
    points=list(product(*(range(L) for L in shape)));V=len(points);index={x:i for i,x in enumerate(points)}
    faces=list(combinations(range(4),2));face_index={p:i for i,p in enumerate(faces)}
    def move(x,a,s):return tuple((t+s)%shape[i] if i==a else t for i,t in enumerate(x))
    hx=[];hz=[]
    for a in range(4):
        for x in points:
            row=0
            for b in range(4):
                if a==b:continue
                block=face_index[tuple(sorted((a,b)))]
                for origin in (x,move(x,b,-1)):row^=1<<(block*V+index[origin])
            hx.append(row)
    for axes in combinations(range(4),3):
        for x in points:
            row=0
            for pair in combinations(axes,2):
                other=next(a for a in axes if a not in pair)
                for origin in (x,move(x,other,1)):row^=1<<(face_index[pair]*V+index[origin])
            hz.append(row)
    return 6*V,hx,hz


def generate(c,out):
    n,hx,hz=checks(c['shape'])
    if n!=c['n'] or c['k']!=6:raise ValueError('frozen dimensions disagree')
    stem=f'TOR_{n}_6_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# original periodic4D toric; {kind}; shape={",".join(map(str,c["shape"]))}; arXiv1609.00510v2 Sec2\n'+
            ''.join(' '.join(str((row>>q)&1) for q in range(n))+'\n' for row in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');args=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if args.all or c['n']==args.n]
    if not cases:ap.error('unknown fixed side vector')
    for c in cases:print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
