#!/usr/bin/env python3
"""Original finite planar tile CSS matrices; mathematics credited in NOTICE."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('tile_cases.json')


def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):return [q for q in range(w.bit_length()) if (w>>q)&1]


def build(c):
    B,L=c['B'],c['L'];b=B-1;S=L+b
    if type(B)!=int or B<2 or type(L)!=int or L<1:raise ValueError('invalid box/layout')
    for key in ['H','V']:
        pts=c[key]
        if len(pts)!=len({tuple(p) for p in pts}) or any(len(p)!=2 or any(type(x)!=int or not 0<=x<B for x in p) for p in pts):raise ValueError('invalid tile support')
    X=[('H',x,y) for x,y in c['H']]+[('V',x,y) for x,y in c['V']]
    Z=[('V' if t=='H' else 'H',b-x,b-y) for t,x,y in X]
    qubits=[(t,x,y) for t in ['H','V'] for x in range(S) for y in range(S)];index={p:i for i,p in enumerate(qubits)}
    xa=[(x,y) for x in range(L) for y in range(-b,L+b)];za=[(x,y) for x in range(-b,L+b) for y in range(L)]
    def rows(tile,anchors):return [sum(1<<index[(t,x+u,y+v)] for t,x,y in tile if (t,x+u,y+v) in index) for u,v in anchors]
    hx,hz=rows(X,xa),rows(Z,za);xunion=zunion=0
    for w in hx:xunion|=w
    for w in hz:zunion|=w
    keep=support(xunion&zunion)
    def prune(rows,anchors):
        out=[];aa=[]
        for w,a in zip(rows,anchors):
            w=sum(((w>>q)&1)<<j for j,q in enumerate(keep))
            if w:out.append(w);aa.append(list(a))
        return out,aa
    hx,xa=prune(hx,xa);hz,za=prune(hz,za);removed=[list(p) for q,p in enumerate(qubits) if q not in set(keep)]
    cert=dict(case=c,parameter_sha256=digest(c),qubits=[list(qubits[q]) for q in keep],removed_qubits=removed,Xanchors=xa,Zanchors=za,prepruning_qubits=2*S*S)
    return len(keep),hx,hz,cert


def generate(c,out,certificates):
    n,hx,hz,cert=build(c)
    if n!=c['n']:raise ValueError('frozen source/layout n differs after prescribed pruning')
    stem=f'TILE_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True);certificates.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ['Hx','Hz','Gx','Gz']) or (certificates/(stem+'.json')).exists():raise FileExistsError('refusing overwrite')
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        (out/f'{stem}_{kind}.txt').write_text(f'# original planar tile {c["id"]}; {kind}; arXiv2504.09171v1; finite red-X/blue-Z boundaries\n'+''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    (certificates/(stem+'.json')).write_text(json.dumps(cert,indent=2)+'\n');return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--n',type=int);g.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--certificates',type=Path,required=True);a=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not cases:ap.error('unknown frozen case')
    for c in cases:print(generate(c,a.out,a.certificates),flush=True)


if __name__=='__main__':main()
