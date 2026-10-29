#!/usr/bin/env python3
"""Independent physical-column BB construction and actual graph/chain cover checks.

Published mathematics only, no constructor imports or distance search.
GPL-3.0-or-later.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
from validate_css import read_code,validate


def independent_columns(c):
    l,m=c['l'],c['m'];v=l*m
    if any(type(z)!=int or z<1 for z in (l,m)):raise ValueError('invalid lattice')
    for key in ('A','B'):
        if len(c[key])!=4 or len({(a%l,b%m) for a,b in c[key]})!=4:raise ValueError('monomials collide')
    hx=[0]*v;hz=[0]*v
    for q in range(2*v):
        side,t=divmod(q,v);x,y=divmod(t,m)
        # Inverse incidence of a physical qubit, not check-row construction.
        for a,b in c['A' if side==0 else 'B']:
            hx[((x-a)%l)*m+(y-b)%m]^=1<<q
        for a,b in c['B' if side==0 else 'A']:
            hz[((x+a)%l)*m+(y+b)%m]^=1<<q
    return hx,hz


def support(word):
    out=[]
    while word:
        bit=word&-word;out.append(bit.bit_length()-1);word^=bit
    return out


def incidence(n,rows):
    columns=[[] for _ in range(n)]
    for i,row in enumerate(rows):
        for q in support(row):columns[q].append(i)
    return columns


def connected(n,rows):
    parents=list(range(n))
    def root(q):
        while parents[q]!=q:parents[q]=parents[parents[q]];q=parents[q]
        return q
    for row in rows:
        s=support(row)
        for q in s[1:]:parents[root(q)]=root(s[0])
    return len({root(q) for q in range(n)})==1


def check_cover(cover,base,crows,brows):
    l,m=cover['l'],cover['m'];bl,bm=base['l'],base['m'];v=l*m;bv=bl*bm
    if l%bl or m%bm:raise ValueError('lattice is not a base multiple')
    h=v//bv
    if cover['h']!=h:raise ValueError('wrong cover multiplicity')
    for key in ('A','B'):
        if Counter((a%bl,b%bm) for a,b in cover[key])!=Counter((a%bl,b%bm) for a,b in base[key]):
            raise ValueError('monomial projection differs from base')
    rmap=[(t//m%bl)*bm+(t%m)%bm for t in range(v)]
    qmap=[side*bv+rmap[t] for side in range(2) for t in range(v)]
    if set(Counter(rmap).values())!={h} or set(Counter(qmap).values())!={h}:raise ValueError('projection fiber size mismatch')
    # Degree1 boundary: Hx; degree2 boundary: Hz^T. Both actual incidences
    # are locally bijective, on check vertices AND physical qubit vertices.
    for rows,base_rows in zip(crows,brows):
        if len(rows)!=v or len(base_rows)!=bv:raise ValueError('check inventory mismatch')
        for i,row in enumerate(rows):
            mapped=[qmap[q] for q in support(row)]
            if len(mapped)!=len(set(mapped)) or sorted(mapped)!=support(base_rows[rmap[i]]):
                raise ValueError('check neighborhood is not bijective')
        cols=incidence(2*v,rows);base_cols=incidence(2*bv,base_rows)
        for q,neighbors in enumerate(cols):
            mapped=[rmap[i] for i in neighbors]
            if len(mapped)!=len(set(mapped)) or sorted(mapped)!=base_cols[qmap[q]]:
                raise ValueError('qubit neighborhood is not bijective')
        # Explicit binary projection and all-fiber transfer boundary identities.
        # Projection of each column and transfer of each base column are
        # checked independently from row-list equality above.
        for q,neighbors in enumerate(cols):
            projected=0
            for i in neighbors:projected^=1<<rmap[i]
            expected=sum(1<<i for i in base_cols[qmap[q]])
            if projected!=expected:raise ValueError('chain projection fails')
        for bq in range(2*bv):
            transferred=0
            for q,pq in enumerate(qmap):
                if pq==bq:
                    for i in cols[q]:transferred^=1<<i
            expected=sum(1<<i for i,bi in enumerate(rmap) if bi in base_cols[bq])
            if transferred!=expected:raise ValueError('chain transfer fails')
        for i,row in enumerate(rows):
            projected=0
            for q in support(row):projected^=1<<qmap[q]
            if projected!=base_rows[rmap[i]]:raise ValueError('transposed chain projection fails')
        for bi in range(bv):
            transferred=0
            for i,pi in enumerate(rmap):
                if pi==bi:transferred^=rows[i]
            expected=sum(1<<q for q,bq in enumerate(qmap) if bq in support(base_rows[bi]))
            if transferred!=expected:raise ValueError('transposed chain transfer fails')
    # pi*T = (h mod2)I in degrees0/1/2. This is not a claim that even
    # covers preserve nontrivial homology or obey the paper's conjecture.
    if any((count%2)!=(h%2) for count in Counter(qmap).values()):raise ValueError('projection/transfer composition fails')
    return dict(h=h,base_n=2*bv,base_shape=[bl,bm],cover_shape=[l,m],
                neighborhood_bijections=6*v,projection_fibers_verified=True,
                chain_projection=True,chain_transfer=True,projection_transfer_scalar=h%2,
                projected_check_rows=rmap,projected_qubits=qmap)


def certify(c,base,n,matrices):
    hx,hz,gx,gz=matrices;l,m=c['l'],c['m'];v=l*m
    if n!=c['n'] or n!=2*v or (hx,hz)!=independent_columns(c):raise ValueError('actual physical columns differ')
    result=validate(n,matrices)
    if result['k']!=c['k'] or c['k']!=14:raise ValueError('published dimensions mismatch')
    if any(bin(row).count('1')!=8 for row in hx+hz):raise ValueError('checks not weight8')
    if any(len(s)!=4 for rows in (hx,hz) for s in incidence(n,rows)):raise ValueError('qubit half degree not4')
    if any(not connected(n,rows) for rows in (hx,hz)):raise ValueError('disconnected input')
    order=[(1-side)*v+((-x)%l)*m+(-y)%m for side in range(2) for x in range(l) for y in range(m)]
    permute=lambda word,p:sum(1<<p[q] for q in support(word))
    if len(set(order))!=n or any(order[order[q]]!=q for q in range(n)):raise ValueError('dual map invalid')
    if {permute(r,order) for r in hx}!=set(hz) or {permute(r,order) for r in hz}!=set(hx):raise ValueError('actual duality failed')
    for axis in (0,1):
        p=[side*v+((x+(axis==0))%l)*m+(y+(axis==1))%m for side in range(2) for x in range(l) for y in range(m)]
        if any({permute(r,p) for r in rows}!=set(rows) for rows in (hx,hz)):raise ValueError('translation failed')
    cover=check_cover(c,base,(hx,hz),independent_columns(base))
    result.update(stem=f'BB_{n}_{c["k"]}_unknown',claim=c['claim'],claimed_d=c['d'],table=c['table'],
                  row_weight=8,column_degree_per_half=4,connected_both_halves=True,dual_map_verified=True,
                  translations_verified=2,cover=cover,source='arXiv2511.13560v3 Tables7/8')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('covering_bb_cases.json'))
    ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();spec=json.loads(args.cases.read_text());results=[]
    for c in spec['cases']:
        n,m=read_code(args.dir,f'BB_{c["n"]}_{c["k"]}_unknown');results.append(certify(c,spec['bases'][c['base']],n,m))
    text=json.dumps(results,indent=2)+'\n';args.output.write_text(text);print(text,end='')


if __name__=='__main__':main()
