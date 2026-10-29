#!/usr/bin/env python3
"""Original finite DHLV edge-qubit chain reconstruction (GH-186), GPL3+.

Mathematics: Dinur--Hsieh--Lin--Vidick 2206.07750v1, Sec2.4/2.7/3.1,
Eq6 and Lemma3.1 (CC BY4.0). No source implementation/matrix copied.
Finite specializations do not inherit unverified asymptotic guarantees.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('dhlv_cases.json')


def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()


def rank(rows):
    pivots={}
    for w in rows:
        while w:
            p=w.bit_length()-1
            if p in pivots:w^=pivots[p]
            else:pivots[p]=w;break
    return len(pivots)


def build(case):
    m=case['rotation_order'];elements=[(r,s) for r in range(m) for s in (0,1)];index={g:i for i,g in enumerate(elements)}
    def mul(a,b):
        r,s=a;t,u=b
        return ((r+(-1 if s else 1)*t)%m,s^u)
    table=[[index[mul(a,b)] for b in elements] for a in elements]
    A=[index[tuple(g)] for g in case['A']];B=[index[tuple(g)] for g in case['B']]
    HA,HB=case['HA'],case['HB'];ma,mb=len(HA),len(HB);delta=len(A);G=len(elements)
    if len(B)!=delta or any(len(row)!=delta for row in HA+HB):raise ValueError('local size mismatch')
    vertices=[[g,x,y] for g in range(G) for x in (0,1) for y in (0,1)];vi={tuple(v):i for i,v in enumerate(vertices)}
    edges=[];ei={};offset=0
    for axis,labels,width in [('A',A,mb),('B',B,ma)]:
        for side in (0,1):
            for g in range(G):
                for label,h in enumerate(labels):
                    target=table[h][g] if axis=='A' else table[g][h]
                    ends=[vi[(g,0,side)],vi[(target,1,side)]] if axis=='A' else [vi[(g,side,0)],vi[(target,side,1)]]
                    ei[(axis,side,g,label)]=len(edges)
                    edges.append(dict(axis=axis,side=side,base=g,label=label,ends=ends,width=width,offset=offset));offset+=width
    hx=[0]*(4*G*ma*mb)
    for e in edges:
        for q in range(e['width']):
            for v in e['ends']:
                for ia in range(ma):
                    for ib in range(mb):
                        bit=(q==ib and HA[ia][e['label']]) if e['axis']=='A' else (q==ia and HB[ib][e['label']])
                        if bit:hx[(v*ma+ia)*mb+ib]^=1<<(e['offset']+q)
    squares=[];hz=[]
    for g in range(G):
        for a,h in enumerate(A):
            ag=table[h][g]
            for b,k in enumerate(B):
                gb=table[g][k];agb=table[ag][k]
                es=[ei[('A',0,g,a)],ei[('A',1,gb,a)],ei[('B',0,g,b)],ei[('B',1,ag,b)]]
                vs=[vi[(g,0,0)],vi[(ag,1,0)],vi[(gb,0,1)],vi[(agb,1,1)]]
                word=0
                for edge in es:
                    e=edges[edge];column=HB if e['axis']=='A' else HA;label=b if e['axis']=='A' else a
                    for q,row in enumerate(column):
                        if row[label]:word^=1<<(e['offset']+q)
                squares.append(dict(base=g,a=a,b=b,vertices=vs,edges=es));hz.append(word)
    n=offset;k=n-rank(hx)-rank(hz)
    if n!=case['n'] or ('k' in case and k!=case['k']):raise ValueError('finite actual parameter mismatch')
    cert=dict(case=case,parameter_sha256=digest(case),elements=elements,multiplication=table,
              vertices=vertices,edges=edges,squares=squares,n=n,k=k,ma=ma,mb=mb)
    return cert,hx,hz


def generate(case,out,certificates):
    cert,hx,hz=build(case);n,k=cert['n'],cert['k'];stem=f'DHLV_{n}_{k}_unknown'
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')) or (certificates/f'{stem}.json').exists():raise FileExistsError('refusing to overwrite matrices/certificate')
    if k<=0:raise ValueError('no logical qubits')
    out.mkdir(parents=True,exist_ok=True);certificates.mkdir(parents=True,exist_ok=True)
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        (out/f'{stem}_{kind}.txt').write_text(f'# finite DHLV {case["id"]}; {kind}; arXiv2206.07750v1 Eq6; original GH-186\n'+''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    (certificates/f'{stem}.json').write_text(json.dumps(cert,indent=2)+'\n');return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--certificates',type=Path,required=True);args=ap.parse_args()
    selected=[c for c in json.loads(CASES.read_text()) if args.all or c['n']==args.n]
    if not selected:ap.error('unknown fixed size')
    for c in selected:print(generate(c,args.out,args.certificates),flush=True)


if __name__=='__main__':main()
