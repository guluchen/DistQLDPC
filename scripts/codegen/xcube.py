#!/usr/bin/env python3
"""Original periodic link-qubit X-cube matrices and disjoint logical certificates."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('xcube_cases.json')


def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):
    out=[]
    while w:b=w&-w;out.append(b.bit_length()-1);w^=b
    return out

def rank(rows):
    p={}
    for w in rows:
        while w:
            q=w.bit_length()-1
            if q in p:w^=p[q]
            else:p[q]=w;break
    return len(p)


def build(c):
    L=c['L'];V=L**3;vertices=list(itertools.product(range(L),repeat=3));index={v:i for i,v in enumerate(vertices)}
    def q(axis,v):return axis*V+index[tuple(x%L for x in v)]
    hx=[];hz=[]
    for v in vertices:
        cube=0
        for axis in range(3):
            other=[i for i in range(3) if i!=axis]
            for a,b in itertools.product(range(2),repeat=2):
                u=list(v);u[other[0]]+=a;u[other[1]]+=b;cube^=1<<q(axis,u)
        hx.append(cube)
        for normal in range(3):
            star=0
            for axis in range(3):
                if axis==normal:continue
                u=list(v);u[axis]-=1;star^=(1<<q(axis,v))|(1<<q(axis,u))
            hz.append(star)
    X=[];Z=[]
    for axis in range(3):
        a,b=[i for i in range(3) if i!=axis]
        def line(u,v):
            w=0
            for t in range(L):
                p=[0]*3;p[axis]=t;p[a]=u;p[b]=v;w|=1<<q(axis,p)
            return w
        for u,v in [(0,j) for j in range(L)]+[(j,0) for j in range(1,L)]:
            base=line(u,v);reps=[base]
            for uu,vv in zip([j for j in range(L) if j!=u],[j for j in range(L) if j!=v]):reps.append(line(uu,v)^line(u,vv)^line(uu,vv))
            X.append(dict(axis=axis,transverse=[u,v],support=support(base),equivalent_supports=list(map(support,reps))))
        for varying,fixed in [(a,j) for j in range(L)]+[(b,j) for j in range(1,L)]:
            reps=[];other=b if varying==a else a
            for layer in range(L):
                w=0
                for t in range(L):
                    p=[0]*3;p[axis]=layer;p[varying]=t;p[other]=fixed;w|=1<<q(axis,p)
                reps.append(w)
            Z.append(dict(axis=axis,varying_axis=varying,fixed=fixed,support=support(reps[0]),equivalent_supports=list(map(support,reps))))
    n=3*V;k=n-rank(hx)-rank(hz)
    if (n,k)!=(c['n'],c['k']):raise ValueError('actual/source dimension mismatch')
    return dict(case=c,parameter_sha256=digest(c),n=n,k=k,rank_Hx=rank(hx),rank_Hz=rank(hz),vertices=vertices,edge_order='axis-major, lexicographic positive-axis start vertex',cube_order='lexicographic origin',star_order='lexicographic vertex then normal0,1,2',detectors=dict(X=X,Z=Z)),hx,hz


def generate(c,out,certificates):
    cert,hx,hz=build(c);n,k=c['n'],c['k'];stem=f'XCB_{n}_{k}_unknown'
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ['Hx','Hz','Gx','Gz']) or (certificates/f'{stem}.json').exists():raise FileExistsError('refusing to overwrite matrix/certificate')
    out.mkdir(parents=True,exist_ok=True);certificates.mkdir(parents=True,exist_ok=True)
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        with (out/f'{stem}_{kind}.txt').open('w') as f:
            f.write(f'# original periodic link-qubit X-cube L={c["L"]}; {kind}; arXiv1603.04442v1; GH-190\n')
            for w in rows:f.write(' '.join(str((w>>q)&1) for q in range(n))+'\n')
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    (certificates/f'{stem}.json').write_text(json.dumps(cert,indent=2)+'\n');return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--all',action='store_true');g.add_argument('--n',type=int);ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--certificates',type=Path,required=True);a=ap.parse_args();cs=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not cs:ap.error('unknown frozen size')
    for c in cs:print(generate(c,a.out,a.certificates),flush=True)


if __name__=='__main__':main()
