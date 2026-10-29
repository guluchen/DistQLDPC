#!/usr/bin/env python3
"""Original finite periodic SC-HGP generator, Yang-Calderbank2305.00137v6 Eq58/89.

No source implementation/matrix files used. Decimal partition labels use
base(memory2+1), NOT a cyclic lift. Full physical output is ordinary binary.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('spatially_coupled_cases.json')


def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()


def rank(rows):
    p={}
    for w in rows:
        while w:
            q=w.bit_length()-1
            if q in p:w^=p[q]
            else:p[q]=w;break
    return len(p)


def build(c):
    l1,l2=c['periods'];m1,m2=c['memory'];pa,pb=c['partition_A'],c['partition_B'];r1,r2=len(pa),len(pb);n1,n2=len(pa[0]),len(pb[0]);G=l1*l2
    if any(len(row)!=n1 for row in pa) or any(len(row)!=n2 for row in pb):raise ValueError('ragged partition')
    if min(l1,l2)<=0 or min(m1,m2)<0 or any(not 0<=d<(m1+1)*(m2+1) for row in pa+pb for d in row):raise ValueError('invalid memory/period/label')
    a=[[divmod(d,m2+1) for d in row] for row in pa];b=[[divmod(d,m2+1) for d in row] for row in pb]
    def shift(t,uv):return ((t//l2+uv[0])%l1)*l2+(t%l2+uv[1])%l2
    hx=[];hz=[];cc=n1*n2*G
    for i in range(r1):
        for j in range(n2):
            for t in range(G):
                w=0
                for x in range(n1):w^=1<<((x*n2+j)*G+shift(t,a[i][x]))
                for y in range(r2):w^=1<<(cc+(i*r2+y)*G+shift(t,(m1-b[y][j][0],m2-b[y][j][1])))
                hx.append(w)
    for x in range(n1):
        for y in range(r2):
            for t in range(G):
                w=0
                for j in range(n2):w^=1<<((x*n2+j)*G+shift(t,b[y][j]))
                for i in range(r1):w^=1<<(cc+(i*r2+y)*G+shift(t,(m1-a[i][x][0],m2-a[i][x][1])))
                hz.append(w)
    n=(n1*n2+r1*r2)*G;k=n-rank(hx)-rank(hz)
    if c['n']!=n or ('k' in c and c['k']!=k):raise ValueError('actual finite dimension differs')
    cert=dict(case=c,parameter_sha256=digest(c),n=n,k=k,rank_Hx=rank(hx),rank_Hz=rank(hz),row_order_X='(i1,j2,t)',row_order_Z='(j1,i2,t)',qubit_order='VV(j1,j2,t),CC(i1,i2,t)',coordinate_order='t=u*L2+v',source_equation=89)
    return cert,hx,hz


def generate(c,out,certificates):
    cert,hx,hz=build(c);n,k=cert['n'],cert['k'];stem=f'SC_{n}_{k}_unknown'
    if k<=0:raise ValueError('no logical qubits')
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')) or (certificates/f'{stem}.json').exists():raise FileExistsError('refusing to overwrite existing matrices/certificate')
    out.mkdir(parents=True,exist_ok=True);certificates.mkdir(parents=True,exist_ok=True)
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        with (out/f'{stem}_{kind}.txt').open('w') as f:
            f.write(f'# original periodic SC-HGP Eq58/89; periods={c["periods"]}; {kind}; arXiv2305.00137v6; GH-188\n')
            for w in rows:f.write(' '.join(str((w>>q)&1) for q in range(n))+'\n')
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    (certificates/f'{stem}.json').write_text(json.dumps(cert,indent=2)+'\n');return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--certificates',type=Path,required=True);args=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if args.all or c['n']==args.n]
    if not cases:ap.error('unknown frozen size')
    for c in cases:print(generate(c,args.out,args.certificates),flush=True)


if __name__=='__main__':main()
