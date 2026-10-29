#!/usr/bin/env python3
"""Original static4.8.8 CSS expansion, Shutty2609.21376v3 AppD mathematics.

GPL-3.0-or-later. No external source/circuit/matrix files copied.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('color488_cases.json')


def geometry(m):
    if type(m)!=int or m<1:raise ValueError('m must be a positive integer')
    right=-4*m-1
    sites=[(x,6+2*j) for j in range(4*m-1)
           for x in range(right-min(2*j+3,8*m-2*j-3)+1,right+1)]
    present=set(sites);faces=[]
    q=((0,0),(1,0),(0,2),(1,2));o=tuple((x,y) for x in range(4) for y in (0,2))
    u=((0,2),(1,2),(2,0),(2,2));v=((0,0),(1,0),(2,0),(2,2))
    def add(shape,x,y,required=False):
        face=frozenset((x+dx,y+dy) for dx,dy in shape)
        if not face<=present:
            if required:raise ValueError('specified boundary support is missing')
            return
        if face in faces:raise ValueError('duplicate face')
        faces.append(face)
    for x,y in sites:
        if (x-y)%4==3:add(q,x,y)
        if x%2==0 and (x-y)%4==0:add(o,x,y)
    for h in range(2*m-1):add(q,right-1,6+4*h,True)
    for h in range(m-1):add(u,-4*m-5-4*h,6+4*h,True)
    for h in range(m):add(v,-8*m+1+4*h,4*m+4+4*h,True)
    faces.sort(key=lambda f:(min(y for x,y in f),min(x for x,y in f),len(f),sorted(f)))
    return sites,faces


def checks(m):
    sites,faces=geometry(m);index={q:i for i,q in enumerate(sites)}
    rows=[sum(1<<index[q] for q in face) for face in faces]
    return len(sites),rows,rows[:]


def generate(c,out):
    m=c['m'];n,hx,hz=checks(m)
    if (n,c['k'],c['d'])!=(8*m*m-1,1,4*m-1) or c['n']!=n:raise ValueError('case formula mismatch')
    stem=f'COLOR_{n}_1_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# original triangular4.8.8 static CSS; {kind}; Shutty arXiv2609.21376v3 AppD; m={m}\n'+
            ''.join(' '.join(str((r>>q)&1) for q in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);group=ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--all',action='store_true');group.add_argument('--m',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');args=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if args.all or c['m']==args.m]
    if not cases:ap.error('select a fixed reference m (m1 Steane intentionally excluded)')
    for c in cases:print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
