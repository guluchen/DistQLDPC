#!/usr/bin/env python3
"""Independent finite edge columns, Laurent commutation and boundary/pruning audit.

No constructor/logical-builder imports. Original GPL-3.0-or-later.
"""
import argparse
from collections import Counter
import hashlib
import itertools
import json
from pathlib import Path
from validate_css import basis,read_code,validate
from verify_css_witness import verify_witness


def require(ok,msg):
    if not ok:raise ValueError(msg)
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):return [q for q in range(w.bit_length()) if (w>>q)&1]


def reconstruct(c):
    B,L=c['B'],c['L'];require(type(B)==int and B>=2 and type(L)==int and L>=1,'invalid box/layout');b=B-1;S=L+b
    stencils=[]
    for keys in [('H','V'),('ZH','ZV')]:
        tile=set()
        for t,key in zip(['H','V'],keys):
            require(len(c[key])==len({tuple(p) for p in c[key]}),'duplicate tile edge')
            for p in c[key]:
                require(len(p)==2 and all(type(a)==int and 0<=a<B for a in p),'edge outside allowed T1 box')
                tile.add((t,*p))
        stencils.append(tile)
    X,Z=stencils;require(Z=={('V' if t=='H' else 'H',b-x,b-y) for t,x,y in X},'source blue partner/T2 mismatch')
    # Count infinite translated overlaps as Laurent coefficients, independent
    # of physical finite row enumeration. Every relative coefficient is even.
    overlaps=Counter((a-c,b-d) for t,a,b in X for u,c,d in Z if t==u)
    require(all(v%2==0 for v in overlaps.values()),'infinite tile overlap parity')
    xa=[(x,y) for x in range(L) for y in range(-b,L+b)];za=[(x,y) for x in range(-b,L+b) for y in range(L)]
    # An X box has wholly physical x extent; a Z box wholly physical y extent.
    # Their nonempty rectangular intersection is therefore wholly physical.
    require(all(0<=x and x+b<S for x,y in xa) and all(0<=y and y+b<S for x,y in za),'opposite boundary intersection leaves physical domain')
    physical=[(t,x,y) for t in ['H','V'] for x in range(S) for y in range(S)];columns=[];keep=[];removed=[]
    xset,zset=set(xa),set(za)
    for p in physical:
        t,h,k=p;ix=sorted(xa.index((h-u,k-v)) for tt,u,v in X if tt==t and (h-u,k-v) in xset)
        iz=sorted(za.index((h-u,k-v)) for tt,u,v in Z if tt==t and (h-u,k-v) in zset)
        if ix and iz:keep.append(p);columns.append((ix,iz))
        else:removed.append(p)
    rows=[[0]*len(xa),[0]*len(za)]
    for q,incidence in enumerate(columns):
        for axis,roots in enumerate(incidence):
            for r in roots:rows[axis][r]|=1<<q
    aa=[];out=[]
    for rr,anchors in zip(rows,[xa,za]):
        aa.append([list(a) for a,w in zip(anchors,rr) if w]);out.append([w for w in rr if w])
    return out,[list(p) for p in keep],[list(p) for p in removed],aa


def physical_components(n,hx,hz):
    b=basis(hx+[w<<n for w in hz])
    for i in sorted(b):
        for j in b:
            if j>i and (b[j]>>i)&1:b[j]^=b[i]
    p=list(range(n))
    def root(q):
        while p[q]!=q:p[q]=p[p[q]];q=p[q]
        return q
    for w in b.values():
        qs={q%n for q in support(w)}
        if qs:
            a=next(iter(qs))
            for q in qs:p[root(q)]=root(a)
    return len({root(q) for q in range(n)})


def certify(c,cert,n,m):
    expected,qubits,removed,anchors=reconstruct(c);hx,hz,gx,gz=m
    require(cert['case']==c and cert['parameter_sha256']==digest(c),'certificate parameter identity')
    require(n==len(qubits)==c['n'] and [hx,hz]==expected,'actual physical columns/boundary/pruning differ')
    require(cert['qubits']==qubits and cert['removed_qubits']==removed and [cert['Xanchors'],cert['Zanchors']]==anchors,'certificate physical inventory or surviving anchors differ')
    require(cert['prepruning_qubits']==2*(c['L']+c['B']-1)**2,'prepruning inventory')
    result=validate(n,m);require(result['k']==c['k'],'actual source/layout k differs')
    require(len(hx)==len(hz)==c['L']*(c['L']+2*(c['B']-1)) and result['rank_Hx']==len(hx) and result['rank_Hz']==len(hz),'actual finite check counts/ranks')
    require(physical_components(n,hx,hz)==1,'typed physical stabilizer product partition')
    words=[]
    for half,logical in [('X',gz),('Z',gx)]:
        w=min(logical,key=lambda v:(len(support(v)),v));qs=support(w);verify_witness(n,m,half,qs);words.append(dict(half=half,basis='computed full quotient basis; upper only',weight=len(qs),support=qs))
    return dict(stem=f'TILE_{n}_{c["k"]}_unknown',**result,parameter_sha256=digest(c),certificate_sha256=digest(cert),independent_source_edge_columns=True,
        infinite_laurent_overlap_even=True,boundary_intersections_physical=True,pruning_checked=True,removed_qubits=len(removed),typed_physical_rowspace_connected=True,
        published_exact=c['published_exact'],published_upper=c['published_upper'],reference_upper=c['reference_upper'],independent_overall_upper=min(w['weight'] for w in words),independently_checked_uppers=words)


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/tile_cases.json'));ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-194/raw/certificates'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=[]
    for c in json.loads(a.cases.read_text()):
        stem=f'TILE_{c["n"]}_{c["k"]}_unknown';n,m=read_code(a.matrices,stem);cert=json.loads((a.certificates/(stem+'.json')).read_text());out.append(certify(c,cert,n,m));print(stem,'PASS',flush=True)
    a.out.write_text(json.dumps(out,indent=2)+'\n')


if __name__=='__main__':main()
