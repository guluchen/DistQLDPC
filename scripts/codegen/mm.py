#!/usr/bin/env python3
"""Original coupled t=4 MM mathematics, arXiv2601.18879v2 Eqs85-86.

GPL-3.0-or-later; no author implementation or matrices. z fastest.
Fixed positive first-column regular representation of the quotient ring.
SOURCE_DIMENSION_HOLD (GH200): source648k18 reconstructs to k12.
Default output is quarantined; no library adoption or parameter repair.
"""
import argparse
from itertools import combinations,product
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('mm_cases.json')


def support(poly,dims):
    if len(dims)!=4 or any(not isinstance(l,int) or l<1 for l in dims):raise ValueError('four positive cyclic sizes required')
    terms=set()
    for monomial in poly.split('+'):
        e=[0]*4
        if monomial!='1':
            for token in monomial.split('*'):
                m=re.fullmatch(r'([wxyz])(?:\^([0-9]+))?',token)
                if not m:raise ValueError('invalid polynomial token')
                e['wxyz'.index(m[1])]+=int(m[2] or 1)
        term=tuple(x%l for x,l in zip(e,dims))
        if term in terms:terms.remove(term)
        else:terms.add(term)
    return sorted(terms)


def boundary(dims,polynomials,degree):
    if len(polynomials)!=4 or degree not in (1,2,3,4):raise ValueError('four-polynomial complex required')
    terms=[support(p,dims) for p in polynomials]
    vertices=list(product(*(range(l) for l in dims)));index={v:i for i,v in enumerate(vertices)};N=len(vertices)
    lo=list(combinations(range(4),degree-1));hi=list(combinations(range(4),degree));blocks={s:i for i,s in enumerate(lo)}
    rows=[0]*(len(lo)*N)
    for j,s in enumerate(hi):
        for axis in s:
            block=blocks[tuple(i for i in s if i!=axis)]
            for col,v in enumerate(vertices):
                for e in terms[axis]:
                    dest=tuple((x+y)%l for x,y,l in zip(v,e,dims))
                    rows[block*N+index[dest]]^=1<<(j*N+col)
    return len(hi)*N,rows


def transpose(width,rows):
    out=[0]*width
    for i,row in enumerate(rows):
        while row:
            bit=row&-row;out[bit.bit_length()-1]|=1<<i;row^=bit
    return len(rows),out


def checks(dims,polynomials):
    # Source row-vector matrices: Pz=partial3=column-boundary d2;
    # Px=partial2T=column-boundary d3T. Source explicit blocks fix the basis.
    n,hz=boundary(dims,polynomials,2)
    width,rows=boundary(dims,polynomials,3);nn,hx=transpose(width,rows)
    assert n==nn
    return n,hx,hz


def rank(rows):
    pivots={}
    for row in rows:
        while row:
            bit=row&-row
            if bit in pivots:row^=pivots[bit]
            else:pivots[bit]=row;break
    return len(pivots)


def generate(case,out):
    if any(len(support(p,case['dims']))!=case['terms'] for p in case['polynomials']):raise ValueError('source terms cancelled or count changed')
    n,hx,hz=checks(case['dims'],case['polynomials'])
    if n!=case['n']:raise ValueError('source n differs from construction')
    actual_k=n-rank(hx)-rank(hz)
    if actual_k!=case['k']:
        raise ValueError('SOURCE_DIMENSION_HOLD: source k=%d, reconstructed k=%d; no files written or parameters changed'%(case['k'],actual_k))
    stem='MM_%d_%d_unknown'%(n,case['k']);paths=[out/(stem+'_'+k+'.txt') for k in ['Hx','Hz','Gx','Gz']]
    if any(p.exists() for p in paths):raise FileExistsError('refusing to overwrite '+stem)
    out.mkdir(parents=True,exist_ok=True)
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        header='# original coupled MM t4; dims=%s; %s; arXiv2601.18879v2 Table%s\n'%(','.join(map(str,case['dims'])),kind,case['source_table'])
        (out/(stem+'_'+kind+'.txt')).write_text(header+''.join(' '.join(str((r>>i)&1) for i in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    p=argparse.ArgumentParser(description=__doc__);g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    p.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered/quarantine/GH-200');a=p.parse_args()
    selected=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not selected:p.error('only the frozen source cases are supported')
    for c in selected:print(generate(c,a.out),flush=True)


if __name__=='__main__':main()
