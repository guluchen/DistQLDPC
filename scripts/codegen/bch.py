#!/usr/bin/env python3
"""Original binary dual-containing CSS BCH reconstruction (GPL-3.0-or-later).

Aly--Klappenecker--Sarvepalli quant-ph/0604102v1 Theorem19. Original finite
field/polynomial mathematics, no author program or matrices. Dense CSS, not LDPC.
"""
import argparse
from functools import lru_cache
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from validate_css import basis,dot

CASES=json.loads(Path(__file__).with_name('bch_cases.json').read_text())


def gf_mul(a,b,p):
    out=0;degree=p.bit_length()-1
    while b:
        if b&1:out^=a
        b>>=1;a<<=1
        if a & (1 << degree):a^=p
    return out


def gf_pow(a,e,p):
    out=1
    while e:
        if e&1:out=gf_mul(out,a,p)
        a=gf_mul(a,a,p);e//=2
    return out


@lru_cache(None)
def primitive_cycle(m,p):
    if type(m) is not int or not 2<=m<=12 or type(p) is not int or p<=0 or p.bit_length()!=m+1 or not p&1:
        raise ValueError('degree2..12 monic odd primitive polynomial required')
    value=1;seen=set();cycle=[]
    for _ in range((1 << m)-1):
        if value==0 or value in seen:raise ValueError('x does not generate the full nonzero field')
        seen.add(value);cycle.append(value)
        value<<=1
        if value & (1 << m):value^=p
    if value!=1 or len(seen)!=(1 << m)-1:raise ValueError('invalid complete field cycle')
    return tuple(cycle)


def first_primitive(m):
    for p in range((1 << m)|1,1 << (m+1),2):
        try:primitive_cycle(m,p)
        except ValueError:continue
        return p
    raise ValueError('no primitive polynomial')


def roots(n,delta):
    defining=set()
    for j in range(1,delta):
        value=j
        while value not in defining:
            defining.add(value);value=2*value%n
    return sorted(defining)


def divide(numerator,denominator):
    if denominator<=0:raise ValueError('zero polynomial divisor')
    quotient=0
    while numerator and numerator.bit_length()>=denominator.bit_length():
        shift=numerator.bit_length()-denominator.bit_length()
        quotient^=1 << shift;numerator^=denominator << shift
    return quotient,numerator


def checks(case):
    n,m,p,delta=(case[k] for k in ('n','m','primitive_polynomial','delta'))
    if type(n) is not int or not 1<n<=3000 or n%2==0 or not 2<=delta<n:
        raise ValueError('odd length2..3000 and valid designed distance required')
    primitive_cycle(m,p)
    if ((1 << m)-1)%n:raise ValueError('length does not divide field multiplicative order')
    order=next((i for i in range(1,m+1) if pow(2,i,n)==1),None)
    maximum=n*((1 << ((m+1)//2))-1)//((1 << m)-1)
    if order!=m or not (1 << (m//2))<n or delta>maximum:
        raise ValueError('frozen Theorem19 dimension/dual-containing range not satisfied')
    defining=roots(n,delta)
    if set(defining)&{(-i)%n for i in defining}:raise ValueError('defining roots meet their negatives')
    beta=gf_pow(2,((1 << m)-1)//n,p)
    powers=[1]
    for _ in range(n-1):powers.append(gf_mul(powers[-1],beta,p))
    if len(set(powers))!=n or gf_mul(powers[-1],beta,p)!=1:
        raise ValueError('beta does not have order n')
    # Low coefficient first; the complete Frobenius-closed root product
    # descends from GF(2^m)[X] to GF(2)[X].
    coefficients=[1]
    for j in defining:
        result=[0]*(len(coefficients)+1)
        for i,a in enumerate(coefficients):
            result[i]^=gf_mul(a,powers[j],p);result[i+1]^=a
        coefficients=result
    if any(x not in (0,1) for x in coefficients):raise ValueError('root product is not binary')
    g=sum(x << i for i,x in enumerate(coefficients))
    h,remainder=divide((1 << n)|1,g)
    if remainder:raise ValueError('BCH generator does not divide X^n+1')
    degree=h.bit_length()-1
    dual=sum(((h >> i)&1) << (degree-i) for i in range(degree+1))
    rank=len(defining)
    checks=[dual << j for j in range(rank)]
    if len(basis(checks))!=rank or any(dot(a,b) for a in checks for b in checks):
        raise ValueError('dual generator rank or self-orthogonality failed')
    k=n-2*rank
    if k!=case['k'] or rank!=m*(delta//2):
        raise ValueError('actual dimension differs from frozen reference; stop before writes')
    return n,checks,checks[:],dict(defining=defining,beta=beta,generator_polynomial=g,
                                  dual_generator_polynomial=dual,rank=rank,k=k,delta_max=maximum)


def generate(case,out):
    n,hx,hz,receipt=checks(case)
    stem=f'BCH_{n}_{receipt["k"]}_unknown'
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError('refusing overwrite '+stem)
    out.mkdir(parents=True,exist_ok=True)
    for kind,rows in (('Hx',hx),('Hz',hz)):
        with (out/f'{stem}_{kind}.txt').open('w') as f:
            f.write(f'# CSS BCH {case["id"]}; {kind}; quant-ph0604102v1 Theorem19; delta{case["delta"]}; dense CSS\n')
            for row in rows:f.write(' '.join(str((row >> j)&1) for j in range(n))+'\n')
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset',
                    '--dir',str(out),stem],check=True)
    return dict(stem=stem,**receipt)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    group=ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--all',action='store_true')
    group.add_argument('--case',choices=[c['id'] for c in CASES])
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--receipt',type=Path)
    a=ap.parse_args();receipts=[]
    for case in CASES if a.all else [c for c in CASES if c['id']==a.case]:
        receipt=generate(case,a.out);receipts.append(receipt);print(receipt['stem'],flush=True)
    if a.receipt:a.receipt.write_text(json.dumps(receipts,indent=2)+'\n')


if __name__=='__main__':main()
