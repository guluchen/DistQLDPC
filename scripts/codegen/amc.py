#!/usr/bin/env python3
"""Original cyclic AMC_2 construction from 2506.16910v3 Eqs27-31.

GPL-3.0-or-later. Mathematical reconstruction, no author implementation.
All source cases fixed in GH199 before generation. No distance search.
"""
import argparse
from itertools import combinations
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('amc_cases.json')


def boundary(l, exponents, degree):
    """First-column regular representation; source basis order D,C,B,A.

    Columns (j-subset, group element), rows ((j-1)-subset, group element).
    d(e_S,g)=sum_i M(a_i) e_(S minus i,g), with a_i=1+x^exponent.
    Over GF2 each double deletion cancels by commutation of translations.
    """
    if l<2 or len(exponents)!=4 or len(set(exponents))!=4 or any(
            not isinstance(e,int) or not 0<e<l for e in exponents):
        raise ValueError('four distinct nonzero cyclic exponents required')
    if degree not in (1,2,3,4):raise ValueError('degree outside four-complex')
    lo=list(combinations(range(4),degree-1));hi=list(combinations(range(4),degree))
    index={s:i for i,s in enumerate(lo)};rows=[0]*(len(lo)*l)
    exponents=list(reversed(exponents))
    for j,s in enumerate(hi):
        for axis in s:
            block=index[tuple(i for i in s if i!=axis)]
            for col in range(l):
                for delta in (0,exponents[axis]):
                    rows[block*l+(col+delta)%l]^=1<<(j*l+col)
    return len(hi)*l,rows


def transpose(width,rows):
    out=[0]*width
    for i,row in enumerate(rows):
        while row:
            bit=row&-row;out[bit.bit_length()-1]|=1<<i;row^=bit
    return len(rows),out


def checks(l, exponents):
    n,hx=boundary(l,exponents,2)
    width,rows=boundary(l,exponents,3)
    nn,hz=transpose(width,rows)
    assert n==nn==6*l
    return n,hx,hz


def generate(case,out):
    n,hx,hz=checks(case['l'],case['exponents'])
    if n!=case['n']:raise ValueError('source n disagrees with construction')
    stem='AMC_%d_%d_unknown'%(n,case['k'])
    paths=[out/(stem+'_'+kind+'.txt') for kind in ('Hx','Hz','Gx','Gz')]
    if any(p.exists() for p in paths):raise FileExistsError('refusing to overwrite '+stem)
    out.mkdir(parents=True,exist_ok=True)
    for kind,rows in (('Hx',hx),('Hz',hz)):
        header='# original AMC_2; l=%d; exponents=%s; %s; source %s\n'%(case['l'],','.join(map(str,case['exponents'])),kind,case['source'])
        (out/(stem+'_'+kind+'.txt')).write_text(header+''.join(
            ' '.join(str((r>>i)&1) for i in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    p=argparse.ArgumentParser(description=__doc__)
    g=p.add_mutually_exclusive_group(required=True);g.add_argument('--all',action='store_true');g.add_argument('--l',type=int)
    p.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=p.parse_args()
    cases=json.loads(CASES.read_text());selected=[c for c in cases if a.all or c['l']==a.l]
    if not selected:p.error('only the frozen source cases are supported')
    for case in selected:print(generate(case,a.out),flush=True)


if __name__=='__main__':main()
