#!/usr/bin/env python3
"""Original Bravyi-Hastings1311.0885v1 finite single-sector CSS products.

GPL-3.0-or-later; mathematics only, no external code or matrices copied.
Checks need not have constant weight; U similarity does NOT preserve weight.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys
from validate_css import basis

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('homological_product_cases.json')
MASK=(1<<64)-1


class Random64:
    def __init__(self,seed):self.state=seed&MASK
    def word(self):
        self.state=(self.state+0x9e3779b97f4a7c15)&MASK;z=self.state
        z=((z^(z>>30))*0xbf58476d1ce4e5b9)&MASK;z=((z^(z>>27))*0x94d049bb133111eb)&MASK
        return z^(z>>31)


def support(w):
    out=[]
    while w:
        b=w&-w;out.append(b.bit_length()-1);w^=b
    return out


def multiply(a,b):
    out=[]
    for row in a:
        w=0
        for j in support(row):w^=b[j]
        out.append(w)
    return out


def inverse(rows):
    n=len(rows)
    if any(r<0 or r>>n for r in rows):raise ValueError('matrix outside square width')
    a=rows[:];b=[1<<i for i in range(n)]
    for i in range(n):
        pivot=next((j for j in range(i,n) if (a[j]>>i)&1),None)
        if pivot is None:return None
        a[i],a[pivot]=a[pivot],a[i];b[i],b[pivot]=b[pivot],b[i]
        for j in range(n):
            if j!=i and (a[j]>>i)&1:a[j]^=a[i];b[j]^=b[i]
    return b


def transpose(rows,n):
    out=[0]*n
    for i,row in enumerate(rows):
        for j in support(row):out[j]|=1<<i
    return out


def canonical(M,H):
    if H<1 or M<=H or (M-H)%2:raise ValueError('M=H+2R with positive H,R required')
    R=(M-H)//2
    return [1<<(i+R) if H<=i<H+R else 0 for i in range(M)]


def factor(rng,M,H):
    d=canonical(M,H)
    for sample in range(10000):
        u=[rng.word()&((1<<M)-1) for _ in range(M)];inv=inverse(u)
        if inv is None:continue
        delta=multiply(multiply(u,d),inv)
        return dict(U=[format(w,'x') for w in u],inverse=[format(w,'x') for w in inv],delta=[format(w,'x') for w in delta],singular_draws=sample)
    raise ValueError('no invertible factor within frozen limit')


def product_rows(left,right):
    M=len(left);K=len(right);rows=[]
    for i in range(M):
        for j in range(K):
            w=0
            for a in support(left[i]):w^=1<<(a*K+j)
            for b in support(right[j]):w^=1<<(i*K+b)
            rows.append(w)
    return rows


def component_count(n,rows):
    parent=list(range(n))
    def root(q):
        while parent[q]!=q:parent[q]=parent[parent[q]];q=parent[q]
        return q
    for row in rows:
        s=support(row)
        for q in s[1:]:parent[root(q)]=root(s[0])
    return len({root(q) for q in range(n)})


def reduced(rows):
    pivots=basis(rows)
    for p in sorted(pivots):
        for q in pivots:
            if q>p and (pivots[q]>>p)&1:pivots[q]^=pivots[p]
    return list(pivots.values())


def derive(c):
    M,H=c['M'],c['H'];canonical(M,H);left=Random64(c['left_seed']);right=Random64(c['right_seed']);rejected=[]
    for pair in range(1000):
        factors=[factor(left,M,H),factor(right,M,H)]
        a,b=([int(s,16) for s in f['delta']] for f in factors);x=product_rows(a,b);z=transpose(x,M*M)
        counts=[component_count(M*M,rows) for rows in (x,z,reduced(x)+reduced(z))]
        if counts==[1,1,1]:return factors,dict(pair_sample=pair,rejected=rejected,accepted_component_counts=counts)
        # Retain every structurally rejected pair, including its full matrices.
        # Never evaluate or select on distance, word weights or solve time.
        rejected.append(dict(pair_sample=pair,factors=factors,component_counts=counts))
    raise ValueError('no connected product within frozen structural limit')


def parameters(c):
    factors,replay=derive(c)
    if 'factors' in c and (factors!=c['factors'] or replay!=c['replay']):raise ValueError('frozen first-admissible factors changed')
    return factors,replay


def checks(c,factors=None):
    if factors is None:factors,_=parameters(c)
    a,b=([int(s,16) for s in f['delta']] for f in factors);rows=product_rows(a,b);n=len(rows)
    return n,rows,transpose(rows,n)


def generate(c,out):
    n,hx,hz=checks(c)
    if n!=c['n'] or n!=c['M']**2 or c['k']!=c['H']**2:raise ValueError('frozen dimensions mismatch')
    stem=f'HPC_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# original single-sector homological product; {kind}; M={c["M"]}; H={c["H"]}; arXiv1311.0885v1 Eq13\n'+''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');args=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if args.all or c['n']==args.n]
    if not cases:ap.error('unknown frozen input')
    for c in cases:print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
