#!/usr/bin/env python3
"""Original three-cycle bicycle matrices from source mathematics; GPL3+."""
import argparse
import itertools
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('itb_cases.json')


def rank(rows):
    pivots={}
    for w in rows:
        while w:
            j=w.bit_length()-1
            if j in pivots:w^=pivots[j]
            else:pivots[j]=w;break
    return len(pivots)


def build(c):
    L=c['L']
    if type(L)!=int or L<2 or c['n']!=2*L**3:raise ValueError('invalid torus')
    for key in ['A','B']:
        if not c[key] or len(c[key])!=len({tuple(e) for e in c[key]}) or any(len(e)!=3 or any(type(a)!=int or not 0<=a<L for a in e) for e in c[key]):raise ValueError('invalid polynomial support')
    vertices=list(itertools.product(range(L),repeat=3));index={p:i for i,p in enumerate(vertices)};N=L**3;out=[]
    for half in [0,1]:
        rr=[]
        for p in vertices:
            w=0
            for block,key in enumerate(['A','B'] if not half else ['B','A']):
                for e in c[key]:
                    v=tuple((p[j]+(1 if not half else -1)*e[j])%L for j in range(3));w^=1<<(block*N+index[v])
            rr.append(w)
        out.append(rr)
    k=2*N-rank(out[0])-rank(out[1])
    if c.get('expected_k') is not None and k!=c['expected_k']:raise ValueError('SCIENTIFIC source k mismatch')
    if k<=0:raise ValueError('frozen finite case encodes no qubit; retain as scientific hold')
    return 2*N,*out,k


def generate(c,out):
    n,hx,hz,k=build(c);stem=f'ITB_{n}_{k}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{key}.txt').exists() for key in ['Hx','Hz','Gx','Gz']):raise FileExistsError('refusing overwrite')
    for key,rows in [('Hx',hx),('Hz',hz)]:
        (out/f'{stem}_{key}.txt').write_text(f'# original ITB {c["id"]}; {key}; arXiv2603.17703v1 Eq5; row-RIGHT convention\n'+''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--L',type=int);g.add_argument('--all',action='store_true');ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=ap.parse_args();cases=[c for c in json.loads(CASES.read_text()) if a.all or c['L']==a.L]
    if not cases:ap.error('unknown frozen period')
    for c in cases:print(generate(c,a.out),flush=True)


if __name__=='__main__':main()
