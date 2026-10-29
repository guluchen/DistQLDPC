#!/usr/bin/env python3
"""Original first-seed Gallager(3,4) factors and ordinary same-factor HGP.

GPL-3.0-or-later. Published mathematics only; no external constructor/matrices.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('gallager_hgp_cases.json')


def permutation(n,seed,block):
    if type(n)!=int or n<1 or type(seed)!=int or seed<0 or block not in (0,1,2):raise ValueError('invalid permutation specification')
    p=list(range(n))
    if block==0:return p
    for i in range(n-1,0,-1):
        attempt=0;limit=(1<<256)-((1<<256)%(i+1))
        while True:
            label=f'distqldpc-gallager-v1|n={n}|seed={seed}|block={block}|i={i}|attempt={attempt}'
            value=int.from_bytes(hashlib.sha256(label.encode('ascii')).digest(),'big')
            if value<limit:break
            attempt+=1
        j=value%(i+1);p[i],p[j]=p[j],p[i]
    return p


def factor(c):
    n=c['classical_n']
    if type(n)!=int or n<4 or n%4 or c['j']!=3 or c['check_weight']!=4:raise ValueError('expected a Gallager(3,4) length divisible by4')
    permutations=[permutation(n,c['seed'],b) for b in range(3)]
    raw=[sum(1<<q for q in p[i:i+4]) for p in permutations for i in range(0,n,4)]
    pivots={};selected=[];rows=[]
    for i,original in enumerate(raw):
        row=original
        while row:
            pivot=row.bit_length()-1
            if pivot in pivots:row^=pivots[pivot]
            else:pivots[pivot]=row;selected.append(i);rows.append(original);break
    if 'permutations' in c and c['permutations']!=permutations:raise ValueError('frozen permutation mismatch')
    if 'selected_rows' in c and c['selected_rows']!=selected:raise ValueError('frozen sparse-row basis mismatch')
    return raw,rows,selected,permutations


def checks(c):
    raw,h,selected,permutations=factor(c);n=c['classical_n'];r=len(h);N=n*n+r*r;hx=[];hz=[]
    if c.get('n',N)!=N or c.get('k',(n-r)**2)!=(n-r)**2:raise ValueError('frozen quantum dimensions mismatch')
    columns=[[i for i,row in enumerate(h) if (row>>v)&1] for v in range(n)]
    for check,row in enumerate(h):
        support=[v for v in range(n) if (row>>v)&1]
        for v in range(n):
            hx.append(sum(1<<(a*n+v) for a in support)^sum(1<<(n*n+check*r+t) for t in columns[v]))
    for v in range(n):
        for check,row in enumerate(h):
            support=[a for a in range(n) if (row>>a)&1]
            hz.append(sum(1<<(v*n+a) for a in support)^sum(1<<(n*n+t*r+check) for t in columns[v]))
    return N,(n-r)**2,hx,hz


def generate(c,out):
    N,k,hx,hz=checks(c);stem=f'HGP_{N}_{k}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# original Gallager(3,4) HGP; {kind}; classical_n={c["classical_n"]}; seed={c["seed"]}; Gallager1963 Sec2.2; Tillich-Zemor0903.0566v2\n'+
            ''.join(' '.join(str((row>>q)&1) for q in range(N))+'\n' for row in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);group=ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--all',action='store_true');group.add_argument('--classical-n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');args=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if args.all or c['classical_n']==args.classical_n]
    if not cases:ap.error('unknown fixed classical length')
    for c in cases:print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
