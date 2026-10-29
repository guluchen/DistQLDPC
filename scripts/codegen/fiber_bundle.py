#!/usr/bin/env python3
"""Original finite circle bundles, Hastings-Haah-O'Donnell2009.03921v2 Def2.11.

GPL-3.0-or-later. Published mathematics only; no external code/matrix files.
No asymptotic theorem or finite exact distance is asserted.
"""
import argparse
from collections import Counter,deque
import json
import math
from pathlib import Path
import subprocess
import sys
from validate_css import basis

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('fiber_bundle_cases.json')
MASK=(1<<64)-1


class Random64:
    def __init__(self,seed):self.state=seed&MASK
    def word(self):
        self.state=(self.state+0x9e3779b97f4a7c15)&MASK;z=self.state
        z=((z^(z>>30))*0xbf58476d1ce4e5b9)&MASK;z=((z^(z>>27))*0x94d049bb133111eb)&MASK
        return z^(z>>31)
    def below(self,n):
        if n<1:raise ValueError('positive range required')
        ceiling=((1<<64)//n)*n
        while True:
            w=self.word()
            if w<ceiling:return w%n
    def shuffle(self,items):
        for j in range(len(items)-1,0,-1):
            k=self.below(j+1);items[j],items[k]=items[k],items[j]


def support(word):
    out=[]
    while word:
        b=word&-word;out.append(b.bit_length()-1);word^=b
    return out


def base_connected(n,rows):
    seen={0}
    while True:
        expanded=set(seen)
        for row in rows:
            s=set(support(row))
            if s&seen:expanded|=s
        if expanded==seen:return len(seen)==n
        seen=expanded


def derive_base(c):
    n,m=c['base_n'],c['base_m']
    if n%4 or m!=3*n//4 or n<8:raise ValueError('base must be(3,4)-biregular')
    rng=Random64(c['base_seed']);rejections=Counter()
    for sample in range(10000):
        stubs=[r for r in range(m) for _ in range(4)];rng.shuffle(stubs)
        columns=[tuple(sorted(stubs[3*j:3*j+3])) for j in range(n)]
        if any(len(set(col))!=3 for col in columns):rejections['parallel_edge']+=1;continue
        if len(set(columns))!=n:rejections['duplicate_column']+=1;continue
        rows=[sum(1<<j for j,col in enumerate(columns) if r in col) for r in range(m)]
        if len(basis(rows))!=m:rejections['rank_deficient']+=1;continue
        if not base_connected(n,rows):rejections['disconnected']+=1;continue
        return rows,dict(sample=sample,rejections=dict(rejections))
    raise ValueError('no structurally admissible base within frozen limit')


def cycle_residues(n,m,L,edges):
    adjacent=[[] for _ in range(n+m)]
    for r,c,t in edges:
        adjacent[r].append((m+c,-t));adjacent[m+c].append((r,t))
    potential=[None]*(m+n);potential[0]=0;queue=deque([0])
    while queue:
        u=queue.popleft()
        for v,t in adjacent[u]:
            if potential[v] is None:potential[v]=(potential[u]+t)%L;queue.append(v)
    if any(v is None for v in potential):raise ValueError('base graph disconnected')
    residues=[(t-potential[r]+potential[m+c])%L for r,c,t in edges]
    return residues,math.gcd(L,*residues)


def derive(c):
    n,m,L,ell=(c[k] for k in ('base_n','base_m','L','ell'))
    if L!=ell*ell or ell<3 or ell%2!=1:raise ValueError('odd square fiber required')
    base,replay=derive_base(c);rng=Random64(c['twist_seed'])
    for sample in range(10000):
        edges=[[r,j,ell*rng.below(ell)] for r,row in enumerate(base) for j in support(row)]
        residues,gcd=cycle_residues(n,m,L,edges)
        if gcd!=ell:continue
        return base,edges,dict(base=replay,twist_sample=sample,cycle_residue_gcd=gcd,
                               nonzero_cycle_residues=sum(t!=0 for t in residues))
    raise ValueError('no primitive subgroup twist within frozen limit')


def parameters(c):
    base,edges,replay=derive(c)
    if 'base_rows_hex' in c and (c['base_rows_hex']!=[format(r,'x') for r in base] or c['edges']!=edges or c['replay']!=replay):
        raise ValueError('frozen base/twist parameters differ from first-admissible replay')
    return base,edges,replay


def checks(c,base=None,edges=None):
    if base is None or edges is None:base,edges,_=parameters(c)
    nb,mb,L=(c[k] for k in ('base_n','base_m','L'));horizontal=nb*L;hx=[];hz=[]
    by_row=[[] for _ in range(mb)];by_column=[[] for _ in range(nb)]
    for r,b,t in edges:by_row[r].append((b,t));by_column[b].append((r,t))
    for r in range(mb):
        for j in range(L):
            row=(1<<(horizontal+r*L+j))^(1<<(horizontal+r*L+(j-1)%L))
            for b,t in by_row[r]:row^=1<<(b*L+(j-t)%L)
            hx.append(row)
    for b in range(nb):
        for j in range(L):
            row=(1<<(b*L+j))^(1<<(b*L+(j+1)%L))
            for r,t in by_column[b]:row^=1<<(horizontal+r*L+(j+t)%L)
            hz.append(row)
    return (nb+mb)*L,hx,hz


def generate(c,out):
    base,edges,replay=parameters(c);n,hx,hz=checks(c,base,edges)
    if n!=c['n'] or c['k']!=c['base_n']-c['base_m']:raise ValueError('frozen dimensions disagree')
    stem=f'FBC_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# original finite circle bundle; {kind}; base={c["base_n"]},{c["base_m"]}; L={c["L"]}; arXiv2009.03921v2 Def2.11\n'+''.join(' '.join(str((r>>q)&1) for q in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');args=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if args.all or c['n']==args.n]
    if not cases:ap.error('unknown frozen case')
    for c in cases:print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
