#!/usr/bin/env python3
"""Independent literal AMC Eq27/28 audit, no generator/logical-builder import."""
import argparse
import json
from pathlib import Path
from validate_css import read_code, validate, basis, contains, dot, equal_space

ROOT=Path(__file__).resolve().parents[2]
# Actual source block layouts, A=0,B=1,C=2,D=3; None denotes zero.
R2=((2,1,0,None,None,None),(3,None,None,1,0,None),
    (None,3,None,2,None,0),(None,None,3,None,2,1))
R3=((1,0,None,None),(2,None,0,None),(None,2,1,None),
    (3,None,None,0),(None,3,None,1),(None,None,3,2))


def literal(l,exponents):
    hx=[]
    for blocks in R2:
        for g in range(l):
            row=0
            for col,axis in enumerate(blocks):
                if axis is not None:
                    for e in (0,exponents[axis]):row^=1<<(col*l+(g-e)%l)
            hx.append(row)
    # Direct column reading of source R3, with the *actual* transpose.
    hz=[]
    for t in range(4):
        for g in range(l):
            row=0
            for pair,blocks in enumerate(R3):
                axis=blocks[t]
                if axis is not None:
                    for e in (0,exponents[axis]):row^=1<<(pair*l+(g+e)%l)
            hz.append(row)
    return hx,hz


def metachecks(l,exponents):
    mx=[];mz=[]
    for g in range(l):
        x=z=0
        for block,e in enumerate(reversed(exponents)):
            for delta in (0,e):x^=1<<(block*l+(g-delta)%l)
        for block,e in enumerate(exponents):
            for delta in (0,e):z^=1<<(block*l+(g+delta)%l)
        mx.append(x);mz.append(z)
    return mx,mz


def relation(checks,rows):
    for row in checks:
        result=0
        while row:
            bit=row&-row;i=bit.bit_length()-1
            if i>=len(rows):raise ValueError('metacheck width')
            result^=rows[i];row^=bit
        if result:raise ValueError('metacheck does not annihilate actual checks')


def permute(rows,mapping):
    out=[]
    for row in rows:
        r=0
        while row:
            bit=row&-row;r^=1<<mapping[bit.bit_length()-1];row^=bit
        out.append(r)
    return out


def word(n,parity,stabilizer,rows,half):
    r=min(rows,key=lambda x:bin(x).count('1'))
    if not r or r>>n or any(dot(r,h) for h in parity) or contains(basis(stabilizer),r):
        raise ValueError('basis upper word is not a logical')
    support=[i for i in range(n) if (r>>i)&1]
    return dict(half=half,weight=len(support),support=support,basis='complete quotient basis; upper only')


def audit(case,directory):
    stem='AMC_%d_%d_unknown'%(case['n'],case['k']);n,m=read_code(directory,stem)
    result=validate(n,m);l=case['l'];e=case['exponents']
    if n!=6*l or result['k']!=case['k']:raise ValueError('source n/k mismatch')
    hx,hz,gx,gz=m
    if (hx,hz)!=literal(l,e):raise ValueError('actual matrices differ from literal source R2/R3T')
    if set(bin(r).count('1') for r in hx+hz)!={6}:raise ValueError('source row weight mismatch')
    mx,mz=metachecks(l,e);relation(mx,hx);relation(mz,hz)
    shift=[block*l+(g+1)%l for block in range(6) for g in range(l)]
    dual=[(5-block)*l+(-g)%l for block in range(6) for g in range(l)]
    if not equal_space(permute(hx,shift),hx) or not equal_space(permute(hz,shift),hz):raise ValueError('physical cyclic map fails')
    if not equal_space(permute(hx,dual),hz) or not equal_space(permute(hz,dual),hx):raise ValueError('physical XZ dual map fails')
    words=[word(n,hz,hx,gz,'X'),word(n,hx,hz,gx,'Z')]
    if case['published_exact'] is not None and min(w['weight'] for w in words)<case['published_exact']:
        raise ValueError('actual word contradicts source exact distance')
    result.update(stem=stem,source=case['source'],published_exact=case['published_exact'],
        published_estimate=case['published_estimate'],rank_Mx=len(basis(mx)),rank_Mz=len(basis(mz)),
        metachecks_complete=False,physical_cyclic_map='PASS',physical_XZ_map='PASS',
        initial_basis_words=words)
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered');p.add_argument('--out',type=Path);a=p.parse_args()
    results=[audit(c,a.dir) for c in json.loads(Path(__file__).with_name('amc_cases.json').read_text())]
    s=json.dumps(results,indent=2)+'\n'
    if a.out:a.out.write_text(s)
    print(s,end='')


if __name__=='__main__':main()
