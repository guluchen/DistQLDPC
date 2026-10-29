#!/usr/bin/env python3
"""Original PK2021 QC GHP/LP references. GPL-3.0-or-later; NOTICE source credit."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('reference_ghp_cases.json')


def build(c):
    l,m,A,b=c['l'],c['m'],c['A'],c['b']
    if type(l)!=int or l<2 or type(m)!=int or m<1 or c['n']!=2*m*l:raise ValueError('invalid dimensions')
    if len(A)!=m or any(len(row)!=m for row in A):raise ValueError('base matrix shape')
    if any(e is not None and (type(e)!=int or not 0<=e<l) for row in A for e in row):raise ValueError('invalid base monomial')
    if not b or len(set(b))!=len(b) or any(type(e)!=int or not 0<=e<l for e in b):raise ValueError('invalid scalar support')
    hx=[];hz=[];N=m*l
    for i in range(m):
        for r in range(l):
            x=sum(1<<(j*l+(r-e)%l) for j,e in enumerate(A[i]) if e is not None)
            x|=sum(1<<(N+i*l+(r-e)%l) for e in b)
            z=sum(1<<(i*l+(r+e)%l) for e in b)
            z|=sum(1<<(N+j*l+(r+A[j][i])%l) for j in range(m) if A[j][i] is not None)
            hx.append(x);hz.append(z)
    return 2*N,hx,hz


def generate(c,out):
    n,hx,hz=build(c);stem=f'LP_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        (out/f'{stem}_{kind}.txt').write_text(f'# original PK2021 QC GHP {c["id"]}; {kind}; arXiv1904.02703v3 AppendixB; block-major first-column convention\n'+''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--n',type=int);g.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not cases:ap.error('unknown frozen reference')
    for c in cases:print(generate(c,a.out),flush=True)


if __name__=='__main__':main()
