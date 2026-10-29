#!/usr/bin/env python3
"""Original length-3 tricycle CSS matrices; source mathematics in NOTICE."""
import argparse
import itertools
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('tt_cases.json')
PAIRS=[[(1,'C'),(2,'B')],[(0,'C'),(2,'A')],[(0,'B'),(1,'A')]]


def build(c):
    dims=c['dims']
    if len(dims)!=3 or any(type(d)!=int or d<2 for d in dims) or c['n']!=3*dims[0]*dims[1]*dims[2]:raise ValueError('invalid source torus')
    for key in ['A','B','C']:
        if not c[key] or len(c[key])!=len({tuple(e) for e in c[key]}) or any(len(e)!=3 or any(type(a)!=int or not 0<=a<d for a,d in zip(e,dims)) for e in c[key]):raise ValueError('invalid polynomial support')
    vertices=list(itertools.product(*(range(d) for d in dims)));index={p:i for i,p in enumerate(vertices)};N=len(vertices)
    def rows(parts,sign):
        return [sum(1<<(block*N+index[tuple((p[j]+sign*e[j])%dims[j] for j in range(3))]) for block,key in parts for e in c[key]) for p in vertices]
    hx=rows(list(enumerate(['A','B','C'])),-1);hz=[]
    for parts in PAIRS:hz.extend(rows(parts,1))
    return 3*N,hx,hz


def generate(c,out):
    n,hx,hz=build(c);stem=f'TT_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{key}.txt').exists() for key in ['Hx','Hz','Gx','Gz']):raise FileExistsError('refusing overwrite')
    for key,rows in [('Hx',hx),('Hz',hz)]:
        (out/f'{stem}_{key}.txt').write_text(f'# original TT {c["id"]}; {key}; arXiv2508.08191v3 Eq13-14; FIRST-COLUMN convention\n'+''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--n',type=int);g.add_argument('--all',action='store_true');ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=ap.parse_args();cases=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not cases:ap.error('unknown frozen source case')
    for c in cases:print(generate(c,a.out),flush=True)


if __name__=='__main__':main()
