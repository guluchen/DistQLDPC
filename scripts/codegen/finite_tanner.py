#!/usr/bin/env python3
"""Original finite-group Quantum Tanner lift, Mian et al2608.12509v1 Eq34.

Actions explicitly follow Leverrier-Rozendaal-Zemor2512.20532v1 Eq2:
lambda_a rowg columna*g; rho_b rowg colg*b^-1. No external constructor code.
GPL-3.0-or-later; numerical source inputs credited under MIT in NOTICE.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('finite_tanner_cases.json')


def multiply(a,b):
    # Permutations act on the right, matching the published GAP cycle labels.
    return tuple(b[a[i]] for i in range(len(a)))


def inverse(a):
    out=[0]*len(a)
    for i,v in enumerate(a):out[v]=i
    return tuple(out)


def permutation(text,degree):
    cycles=re.findall(r'\(([^()]*)\)',text)
    if ''.join('('+c+')' for c in cycles)!=text:raise ValueError('invalid cycle syntax')
    p=list(range(degree));used=set()
    for c in cycles:
        if not c:continue
        vals=[int(v)-1 for v in c.split(',')]
        if len(set(vals))!=len(vals) or any(v<0 or v>=degree or v in used for v in vals):raise ValueError('cycles must be disjoint')
        used.update(vals)
        for a,b in zip(vals,vals[1:]+vals[:1]):p[a]=b
    return tuple(p)


def group_data(case):
    degree=max(map(int,re.findall(r'\d+',','.join(case['A']+case['B']))),default=1)
    a=[permutation(t,degree) for t in case['A']];b=[permutation(t,degree) for t in case['B']]
    found={tuple(range(degree))};todo=list(found)
    for g in todo:
        for h in a+b:
            product=multiply(g,h)
            if product not in found:
                found.add(product);todo.append(product)
                if len(found)>case['group_order']:raise ValueError('group larger than reference')
    group=sorted(found)
    if len(group)!=case['group_order']:raise ValueError('group order mismatch')
    return group,a,b


def local_pair(h,g,perm):
    length=len(perm)
    if sorted(perm)!=list(range(1,length+1)) or any(len(row)!=length for row in h+g):raise ValueError('local dimensions/permutation')
    if any(v not in (0,1) for row in h+g for v in row):raise ValueError('nonbinary local input')
    if any(sum(a*b for a,b in zip(x,z))%2 for x in h for z in g):raise ValueError('local duality broken')
    return [[row[i-1] for i in perm] for row in h],[[row[i-1] for i in perm] for row in g]


def checks(case):
    group,a,b=group_data(case);index={g:i for i,g in enumerate(group)};p=len(group);na=len(a);nb=len(b)
    ha,ga=case['H_A'],case['G_A'];hb,gb=case['H_B'],case['G_B']
    h1a,g1a=local_pair(ha,ga,case['pi_A']);h1b,g1b=local_pair(hb,gb,case['pi_B'])
    left=[[index[multiply(t,g)] for g in group] for t in a]
    right=[[index[multiply(g,inverse(t))] for g in group] for t in b]
    def lifted(rows_a,rows_b,use_left,use_right):
        rows=[]
        for ra in rows_a:
            for rb in rows_b:
                support=[(i,j) for i,x in enumerate(ra) if x for j,y in enumerate(rb) if y]
                for g in range(p):
                    row=0
                    for i,j in support:
                        h=left[i][g] if use_left else g
                        if use_right:h=right[j][h]
                        row ^= 1 << ((i*nb+j)*p+h)
                    rows.append(row)
        return rows
    hx=lifted(ha,gb,False,False)+lifted(h1a,g1b,True,True)
    hz=lifted(ga,h1b,False,True)+lifted(g1a,hb,True,False)
    n=na*nb*p
    if n!=case['n']:raise ValueError('length differs from source')
    return n,hx,hz


def generate(case,out):
    n,hx,hz=checks(case);stem=f'TN_{n}_{case["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# finite-group Tanner lift; {kind}; arXiv2608.12509v1 Eq34; group {case["group"]}\n'+
            ''.join(' '.join(str((r>>q)&1) for q in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--n',type=int);g.add_argument('--all',action='store_true');ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not cases:ap.error('unknown fixed reference')
    for c in cases:print(generate(c,a.out),flush=True)


if __name__=='__main__':main()
