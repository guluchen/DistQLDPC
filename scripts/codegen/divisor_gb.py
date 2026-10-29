#!/usr/bin/env python3
"""Original cyclic GB construction from Lu et al. arXiv:2608.09115v3.

GPL-3.0-or-later. Mathematical source supports credited under CC BY 4.0.
No external generator, matrices or distance software copied or executed.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('divisor_gb_cases.json')


def polynomial(support,l):
    if not isinstance(l,int) or l<1:raise ValueError('invalid cyclic length')
    if len(set(support))!=len(support) or any(type(x)!=int or not 0<=x<l for x in support):
        raise ValueError('invalid or duplicate polynomial support')
    return sum(1<<x for x in support)


def remainder(a,b):
    if not b:raise ValueError('zero divisor')
    while a and a.bit_length()>=b.bit_length():a^=b<<(a.bit_length()-b.bit_length())
    return a


def gcd(a,b):
    while b:a,b=b,remainder(a,b)
    return a


def product(a,b,l):
    result=0
    while b:
        if b&1:result^=a
        b>>=1;a<<=1
    return remainder(result,(1<<l)|1)


def supports(c):
    l=c['l'];g=polynomial(c['g'],l);out=[]
    for name,lift in (('a','u'),('b','v')):
        explicit=polynomial(c[name],l) if name in c else None
        derived=product(g,polynomial(c[lift],l),l) if lift in c else None
        if explicit is not None and derived is not None and explicit!=derived:
            raise ValueError('published polynomial and lift disagree')
        value=explicit if explicit is not None else derived
        if value is None:raise ValueError('missing polynomial')
        out.append(value)
    return out


def checks(c):
    l=c['l'];a,b=supports(c);g=gcd(gcd(a,b),(1<<l)|1)
    if g!=polynomial(c['g'],l) or c['n']!=2*l or c['k']!=2*(g.bit_length()-1):
        raise ValueError('source gcd/dimensions disagree')
    def rows(left,right,sign):
        result=[]
        for r in range(l):
            value=0
            for block,p in enumerate((left,right)):
                for e in range(l):
                    if (p>>e)&1:value ^= 1<<(block*l+(r+sign*e)%l)
            result.append(value)
        return result
    return 2*l,rows(a,b,-1),rows(b,a,1)


def generate(c,out):
    n,hx,hz=checks(c);stem=f'GB_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{k}.txt').exists() for k in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError('refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# original cyclic GB; {kind}; Lu-Guo-Liu-Yang arXiv2608.09115v3; {c["source"]}\n'+
            ''.join(' '.join(str((r>>q)&1) for q in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--n',type=int);g.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');args=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if args.all or c['n']==args.n]
    if not cases:ap.error('unknown fixed reference')
    for c in cases:print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
