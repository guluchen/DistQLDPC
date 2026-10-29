#!/usr/bin/env python3
"""Independent chain columns, weighted gauge constraints, full GF2 and upper word.

No constructor or third-party imports. No distance support search.
GPL-3.0-or-later.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
from validate_css import basis,contains,read_code,validate
from verify_css_witness import verify_witness


def support(word):
    out=[]
    while word:
        b=word&-word;out.append(b.bit_length()-1);word^=b
    return out


def columns(c):
    nb,mb,L=(c[k] for k in ('base_n','base_m','L'));v=nb*L
    by_bit=[[] for _ in range(nb)];by_check=[[] for _ in range(mb)]
    for r,b,t in c['edges']:by_bit[b].append((r,t));by_check[r].append((b,t))
    hx=[0]*(mb*L);hz=[0]*(nb*L)
    for q in range((nb+mb)*L):
        if q<v:
            b,j=divmod(q,L)
            for r,t in by_bit[b]:hx[r*L+(j+t)%L]^=1<<q
            for edge in (j,(j-1)%L):hz[b*L+edge]^=1<<q
        else:
            r,j=divmod(q-v,L)
            for site in (j,(j+1)%L):hx[r*L+site]^=1<<q
            for b,t in by_check[r]:hz[b*L+(j-t)%L]^=1<<q
    return hx,hz


def gauge(c):
    """Weighted disjoint sets, independent from constructor's BFS potentials."""
    nb,mb,L=(c[k] for k in ('base_n','base_m','L'));parent=list(range(nb+mb));delta=[0]*(nb+mb);residues=[];cycle_edges=[]
    def find(x):
        if parent[x]==x:return x,0
        r,d=find(parent[x]);delta[x]=(delta[x]+d)%L;parent[x]=r
        return r,delta[x]
    for i,(r,b,t) in enumerate(c['edges']):
        rb,db=find(mb+b);rr,dr=find(r)
        if rb!=rr:parent[rb]=rr;delta[rb]=(dr-db-t)%L
        else:residues.append((t-dr+db)%L);cycle_edges.append(i)
    if len({find(i)[0] for i in range(nb+mb)})!=1:raise ValueError('disconnected base')
    return dict(cycle_gcd=math.gcd(L,*residues),cycle_residues=residues,cycle_edge_indices=cycle_edges,
                cycle_rank=len(residues),nonzero_cycles=sum(t!=0 for t in residues))


def components(n,rows):
    parent=list(range(n))
    def root(x):
        while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
        return x
    for row in rows:
        s=support(row)
        for q in s[1:]:parent[root(q)]=root(s[0])
    groups={}
    for q in range(n):groups.setdefault(root(q),[]).append(q)
    return sorted(groups.values(),key=lambda x:x[0])


def reduced(rows):
    p=basis(rows)
    for a in sorted(p):
        for b in p:
            if b>a and (p[b]>>a)&1:p[b]^=p[a]
    return [p[a] for a in sorted(p)]


def certify(c,n,m):
    nb,mb,L,ell=(c[k] for k in ('base_n','base_m','L','ell'));hx,hz,gx,gz=m
    base=[int(s,16) for s in c['base_rows_hex']]
    if len(base)!=mb or len(basis(base))!=mb or any(w>>nb or bin(w).count('1')!=4 for w in base):raise ValueError('base shape/row degree/full rank failed')
    if any(sum((w>>b)&1 for w in base)!=3 for b in range(nb)):raise ValueError('base column degree failed')
    if len({sum(((w>>b)&1)<<r for r,w in enumerate(base)) for b in range(nb)})!=nb:raise ValueError('duplicate base columns')
    if L!=ell*ell or ell<3 or ell%2!=1:raise ValueError('fiber is not an odd square')
    if len(c['edges'])!=3*nb or {(r,b) for r,b,t in c['edges']}!={(r,b) for r,row in enumerate(base) for b in support(row)}:raise ValueError('twist incidence differs from base')
    if any(not 0<=t<L or t%ell for r,b,t in c['edges']):raise ValueError('twists outside permitted subgroup')
    gg=gauge(c)
    if gg['cycle_gcd']!=ell or gg['cycle_rank']!=3*nb-(nb+mb)+1:raise ValueError('twists are removable or subgroup incomplete')
    if n!=(nb+mb)*L or n!=c['n'] or (hx,hz)!=columns(c):raise ValueError('actual chain columns mismatch')
    result=validate(n,m)
    if result['k']!=nb-mb or result['k']!=c['k'] or result['rank_Hx']!=mb*L or result['rank_Hz']!=nb*L-(nb-mb):raise ValueError('bundle ranks/dimensions mismatch')
    if any(bin(w).count('1')!=6 for w in hx) or any(bin(w).count('1')!=5 for w in hz):raise ValueError('bundle check weights differ')
    for rows,expected in ((hx,[3]*(nb*L)+[2]*(mb*L)),(hz,[2]*(nb*L)+[4]*(mb*L))):
        degree=Counter(q for w in rows for q in support(w))
        if [degree[q] for q in range(n)]!=expected:raise ValueError('physical degree mismatch')
        if len(components(n,rows))!=1:raise ValueError('disconnected Tanner graph')
    if len(components(n,reduced(hx)+reduced(hz)))!=1:raise ValueError('hidden stabilizer direct sum')
    # Chain projection to the base: horizontal cells map to their base bit;
    # vertical cells vanish. E0 sites map to their base check. E2 vanishes.
    for q in range(n):
        projected=0
        for i,row in enumerate(hx):
            if (row>>q)&1:projected^=1<<(i//L)
        expected=sum(((w>>(q//L))&1)<<r for r,w in enumerate(base)) if q<nb*L else 0
        if projected!=expected:raise ValueError('base boundary chain projection fails')
    for row in hz:
        projected=0
        for q in support(row):
            if q<nb*L:projected^=1<<(q//L)
        if projected:raise ValueError('two-cell chain projection fails')
    order=[b*L+(j+1)%L for b in range(nb+mb) for j in range(L)]
    move=lambda w:sum(1<<order[q] for q in support(w))
    if any({move(w) for w in rows}!=set(rows) for rows in (hx,hz)):raise ValueError('fiber translation not an actual automorphism')
    base_coordinate=next(b for b in range(nb) if not contains(basis(base),1<<b))
    word=list(range(base_coordinate*L,(base_coordinate+1)*L));verify_witness(n,m,'X',word)
    result.update(stem=f'FBC_{n}_{c["k"]}_unknown',base_shape=[mb,nb],fiber_length=L,
                  base_rank=mb,gauge=gg,physical_and_rowspace_connected=True,
                  fiber_translation_verified=True,base_chain_projection_verified=True,
                  independently_checked_upper=dict(half='X',base_coordinate=base_coordinate,support=word,weight=L),
                  source_individual_distance=None,scientific_status='VALID_FINITE_BUNDLE_WITH_VERIFIED_UPPER_ONLY',
                  input_parameters_sha256=hashlib.sha256(json.dumps(c,sort_keys=True,separators=(',',':')).encode()).hexdigest())
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('fiber_bundle_cases.json'));ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text()):
        n,m=read_code(args.dir,f'FBC_{c["n"]}_{c["k"]}_unknown');results.append(certify(c,n,m))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
