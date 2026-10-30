#!/usr/bin/env python3
"""Original two-row/three-block polynomial-minor CSS construction (GPL3+).

Nourozi--Smarandache--Mitchell2610.19459v1, Eq10/11,Thm5,TablesI/II.
Physical circulants have coefficient first row and RIGHT-shifted later rows.
No source program/matrices or external distance solver used.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASE_PATH=Path(__file__).with_name('polynomial_minors_cases.json')


def poly(support,n):
    value=0
    for i in support:
        if type(i) is not int or i<0:raise ValueError('invalid polynomial exponent')
        value ^= 1 << (i%n)
    return value


def rotate(p,shift,n):
    shift%=n
    return ((p << shift)|(p >> (n-shift)))&((1 << n)-1)


def product(a,b,n):
    out=0
    while b:
        bit=b&-b;out^=rotate(a,bit.bit_length()-1,n);b^=bit
    return out


def remainder(a,b):
    if not b:raise ValueError('zero divisor')
    while a and a.bit_length()>=b.bit_length():a^=b << (a.bit_length()-b.bit_length())
    return a


def gcd(*values):
    out=0
    for value in values:
        while value:out,value=value,remainder(out,value)
    return out


def transpose(p,n):return sum(((p >> i)&1) << ((-i)%n) for i in range(n))


def basis(rows):
    bb={}
    for row in rows:
        while row:
            pivot=row.bit_length()-1
            if pivot in bb:row^=bb[pivot]
            else:bb[pivot]=row;break
    return bb


def checks(case):
    n=case['lift']
    if type(n) is not int or not 1<n<=1000 or n%2!=1 or case.get('t',0)!=0 or case.get('q',[0])!=[0]:
        raise ValueError('frozen odd lift<=1000,t0,q1 prescription required')
    a,b,c=[poly(case[key],n) for key in ('a','b','c')]
    if not all((a,b,c)):raise ValueError('zero source entry')
    minors=[product(b,b,n)^product(a,c,n),product(a,b,n)^product(c,c,n),
            product(a,a,n)^product(b,c,n)]
    if not any(minors):raise ValueError('all minors vanish')
    if product(a,minors[0],n)^product(b,minors[1],n)^product(c,minors[2],n):
        raise ValueError('first Laplace identity failed')
    if product(c,minors[0],n)^product(a,minors[1],n)^product(b,minors[2],n):
        raise ValueError('second Laplace identity failed')
    modulus=(1 << n)|1;g=gcd(a,b,c,modulus);g1=gcd(*minors,modulus)
    k=(g.bit_length()-1)+2*(g1.bit_length()-1)
    if 'k' in case and k!=case['k']:raise ValueError('frozen polynomial dimension mismatch; stop before writes')
    if k<=0:raise ValueError('zero logical dimension')
    hx=[]
    for row in ([a,b,c],[c,a,b]):
        hx += [sum(rotate(transpose(p,n),i,n) << (j*n) for j,p in enumerate(row)) for i in range(n)]
    hz=[sum(rotate(p,i,n) << (j*n) for j,p in enumerate(minors)) for i in range(n)]
    rx,rz=len(basis(hx)),len(basis(hz))
    if 3*n-rx-rz!=k or rx!=2*n-(g.bit_length()-1)-(g1.bit_length()-1) or rz!=n-(g1.bit_length()-1):
        raise ValueError('actual ranks disagree with polynomial source dimension; stop before writes')
    if 'source_ranks' in case and [rx,rz]!=case['source_ranks']:
        raise ValueError('source ranks differ; stop and escalate')
    return 3*n,hx,hz,dict(id=case['id'],stem=f'PM_{3*n}_{k}_unknown',n=3*n,k=k,
        lift=n,rank_Hx=rx,rank_Hz=rz,g=g,g1=g1,minors=minors,
        row_weights_Hx=sorted({bin(r).count('1') for r in hx}),
        row_weights_Hz=sorted({bin(r).count('1') for r in hz}))


def generate(case,out):
    n,hx,hz,receipt=checks(case);stem=receipt['stem']
    if any((out/(stem+'_'+kind+'.txt')).exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError('refusing overwrite '+stem)
    out.mkdir(parents=True,exist_ok=True)
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        with (out/(stem+'_'+kind+'.txt')).open('w') as f:
            f.write(f'# Polynomial-minor CSS {case["id"]}; {kind}; block-major; right circulants; 2610.19459v1 Eq10/11\n')
            for row in rows:f.write(' '.join(str((row >> j)&1) for j in range(n))+'\n')
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset',
                    '--dir',str(out),stem],check=True)
    return receipt


def main():
    cases=json.loads(CASE_PATH.read_text())
    ap=argparse.ArgumentParser(description=__doc__)
    choice=ap.add_mutually_exclusive_group(required=True)
    choice.add_argument('--all',action='store_true');choice.add_argument('--case',choices=[c['id'] for c in cases])
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--receipt',type=Path)
    a=ap.parse_args();results=[generate(c,a.out) for c in cases if a.all or c['id']==a.case]
    text=json.dumps(results,indent=2)+'\n'
    if a.receipt:a.receipt.write_text(text)
    else:print(text,end='')


if __name__=='__main__':main()
