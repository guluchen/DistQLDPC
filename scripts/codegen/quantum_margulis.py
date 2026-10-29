#!/usr/bin/env python3
"""Original finite SL(2,p) Margulis/2BGA reconstruction (GH-187), GPL3+.

Math: Pacenti--Chytas--Vasic2503.03936v3 Sec3/4 Eq8/10/11, CC BY4.0.
Original frozen conjugators, not author matrix reproductions. No distance search.
"""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('quantum_margulis_cases.json')


def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def multiply(a,b):
    x,y,z,w=a;X,Y,Z,W=b
    return (x*X+y*Z,x*Y+y*W,z*X+w*Z,z*Y+w*W)
def inverse(a):
    x,y,z,w=a
    if x*w-y*z!=1:raise ValueError('integral determinant is not one')
    return (w,-y,-z,x)
def rank(rows):
    p={}
    for w in rows:
        while w:
            b=w.bit_length()-1
            if b in p:w^=p[b]
            else:p[b]=w;break
    return len(p)


def build(case):
    p=case['prime'];eta=case['eta'];identity=(1,0,0,1)
    elements=[g for g in itertools.product(range(p),repeat=4) if (g[0]*g[3]-g[1]*g[2])%p==1]
    index={g:i for i,g in enumerate(elements)};G=len(elements)
    mod=lambda g:tuple(v%p for v in g)
    integral={key:[multiply(multiply(tuple(c),(1,eta,0,1)),inverse(tuple(c))) for c in case[key+'_conjugators']] for key in ('A','B')}
    supports={key:[index[mod(g)] for g in integral[key]] for key in integral}
    right=[[index[mod(multiply(g,elements[a]))] for g in elements] for a in supports['A']]
    left=[[index[mod(multiply(elements[b],g))] for g in elements] for b in supports['B']]
    inverse_right=[];inverse_left=[]
    for permutations,out in ((right,inverse_right),(left,inverse_left)):
        for permutation in permutations:
            inv=[None]*G
            for g,h in enumerate(permutation):inv[h]=g
            out.append(inv)
    hx=[];hz=[]
    for g in range(G):
        hx.append(sum(1<<permutation[g] for permutation in right)+sum(1<<(G+permutation[g]) for permutation in left))
        hz.append(sum(1<<permutation[g] for permutation in inverse_left)+sum(1<<(G+permutation[g]) for permutation in inverse_right))
    n=2*G;k=n-rank(hx)-rank(hz)
    if n!=case['n'] or ('k' in case and case['k']!=k):raise ValueError('actual finite dimension mismatch')
    cert=dict(case=case,parameter_sha256=digest(case),elements=elements,identity=index[identity],integral_generators=integral,support_indices=supports,
              right_A=right,left_B=left,inverse_right_A=inverse_right,inverse_left_B=inverse_left,n=n,k=k)
    return cert,hx,hz


def generate(case,out,certificates):
    cert,hx,hz=build(case);n,k=cert['n'],cert['k'];stem=f'QMC_{n}_{k}_unknown'
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')) or (certificates/f'{stem}.json').exists():raise FileExistsError('refusing to overwrite matrix/certificate')
    if k<=0:raise ValueError('no logical qubits')
    out.mkdir(parents=True,exist_ok=True);certificates.mkdir(parents=True,exist_ok=True)
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        (out/f'{stem}_{kind}.txt').write_text(f'# original finite Quantum Margulis p={case["prime"]}, eta={case["eta"]}; {kind}; arXiv2503.03936v3; GH-187\n'+''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    (certificates/f'{stem}.json').write_text(json.dumps(cert,indent=2)+'\n');return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--certificates',type=Path,required=True);args=ap.parse_args()
    selected=[c for c in json.loads(CASES.read_text()) if args.all or c['n']==args.n]
    if not selected:ap.error('unknown fixed size')
    for c in selected:print(generate(c,args.out,args.certificates),flush=True)


if __name__=='__main__':main()
