#!/usr/bin/env python3
"""Original finite radial lifted products; GPL-3.0-or-later. NOTICE source credit."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('radial_cases.json')


def build(c):
    r,s=c['r'],c['s'];A,B=c['A1'],c['A2']
    if type(r)!=int or r<2 or type(s)!=int or s<2 or c['n']!=2*r*r*s:raise ValueError('invalid dimensions')
    for M in [A,B]:
        if len(M)!=r or any(len(row)!=r for row in M):raise ValueError('base shape')
        if any(type(e)!=int or not 0<=e<s for row in M for e in row):raise ValueError('invalid exponent')
    N=r*r*s;hx=[];hz=[]
    def q(i,j,v):return (i*r+j)*s+v%s
    for i in range(r):
        for j in range(r):
            for v in range(s):
                hx.append(sum(1<<q(k,j,v+A[i][k]) for k in range(r))|sum(1<<(N+q(i,k,v+B[j][k])) for k in range(r)))
                hz.append(sum(1<<q(i,k,v-B[k][j]) for k in range(r))|sum(1<<(N+q(k,j,v-A[k][i])) for k in range(r)))
    return 2*N,hx,hz


def generate(c,out):
    n,hx,hz=build(c);stem=f'LP_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        (out/f'{stem}_{kind}.txt').write_text(f'# original radial LP {c["id"]}; {kind}; arXiv2406.14445v2 Eq8; row-right circulants\n'+''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--n',type=int);g.add_argument('--all',action='store_true');ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not cases:ap.error('unknown frozen benchmark; peer-only D1 is not an added input')
    for c in cases:print(generate(c,a.out),flush=True)


if __name__=='__main__':main()
