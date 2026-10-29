#!/usr/bin/env python3
"""Independent physical columns and layer-major tensor-order GHP checks.

No constructor/logical-builder imports. Original GPL-3.0-or-later.
"""
import argparse
import hashlib
import json
from pathlib import Path
from validate_css import basis,dot,equal_space,read_code,validate
from verify_css_witness import verify_witness


def require(ok,msg):
    if not ok:raise ValueError(msg)
def support(w):return [q for q in range(w.bit_length()) if (w>>q)&1]
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()


def parameters(c):
    l,m,A,b=c['l'],c['m'],c['A'],c['b']
    require(type(l)==int and l>=2 and type(m)==int and m>0 and c['n']==2*l*m,'invalid dimensions')
    require(len(A)==m and all(len(row)==m for row in A),'base shape')
    require(all(e is None or type(e)==int and 0<=e<l for row in A for e in row),'invalid monomial')
    require(b and len(b)==len(set(b)) and all(type(e)==int and 0<=e<l for e in b),'scalar support')
    return l,m,A,set(b)


def reconstruct(c):
    l,m,A,b=parameters(c);N=l*m;out=[[0]*N for _ in range(2)]
    for q in range(2*N):
        half,local=divmod(q,N);j,h=divmod(local,l)
        if not half:
            xx=[i*l+(h+A[i][j])%l for i in range(m) if A[i][j] is not None]
            zz=[j*l+(h-e)%l for e in b]
        else:
            xx=[j*l+(h+e)%l for e in b]
            zz=[i*l+(h-A[j][i])%l for i in range(m) if A[j][i] is not None]
        for axis,roots in enumerate([xx,zz]):
            for r in roots:out[axis][r]|=1<<q
    return out


def layer_major(c):
    l,m,A,b=parameters(c);N=l*m;out=[[0]*N for _ in range(2)]
    # Explicit P^e tensor |i><j| in layer-major coordinates, then pull back
    # by q=half*N+h*m+j <-> half*N+j*l+h and r=s*m+i <-> i*l+s.
    for r in range(N):
        s,i=divmod(r,m)
        for t in range(l):
            for j in range(m):
                if A[i][j] is not None and (s-t)%l==A[i][j]:out[0][r]|=1<<(t*m+j)
                if i==j and (s-t)%l in b:out[0][r]|=1<<(N+t*m+j)
                if i==j and (t-s)%l in b:out[1][r]|=1<<(t*m+j)
                if A[j][i] is not None and (t-s)%l==A[j][i]:out[1][r]|=1<<(N+t*m+j)
    p=[half*N+j*l+h for half in range(2) for h in range(l) for j in range(m)]
    return [[sum(((rows[s*m+i]>>q)&1)<<p[q] for q in range(2*N)) for i in range(m) for s in range(l)] for rows in out]


def permute(w,p):return sum(((w>>q)&1)<<r for q,r in enumerate(p))


def physical_components(n,hx,hz):
    b=basis(hx+[r<<n for r in hz])
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
            first=next(iter(qs))
            for q in qs:p[root(q)]=root(first)
    return len({root(q) for q in range(n)})


def certify(c,n,matrices):
    hx,hz,gx,gz=matrices;l,m,A,b=parameters(c);N=l*m
    require(n==c['n'] and [hx,hz]==reconstruct(c),'actual source/physical columns differ')
    require([hx,hz]==layer_major(c),'source tensor-coordinate pullback differs')
    result=validate(n,matrices);require(result['k']==c['k'],'source k mismatch')
    require(len(hx)==len(hz)==N and result['rank_Hx']==result['rank_Hz']==(n-c['k'])//2,'source ranks/counts')
    require(all(len(support(w))==6 for w in hx+hz),'source row degree6')
    require(all(sum((w>>q)&1 for w in rows)==3 for q in range(n) for rows in [hx,hz]),'source column degree3')
    require(len(set(hx))==len(set(hz))==N,'duplicate check row')
    require(physical_components(n,hx,hz)==1,'typed physical product partition')
    shift=[(q//l)*l+(q%l+1)%l for q in range(n)]
    require(all(equal_space(rows,[permute(w,shift) for w in rows]) for rows in [hx,hz]),'cyclic lift automorphism')
    words=[]
    for half,logical in [('X',gz),('Z',gx)]:
        word=min(logical,key=lambda w:(len(support(w)),w));qs=support(word);verify_witness(n,matrices,half,qs)
        words.append(dict(half=half,basis='computed quotient basis; upper only',weight=len(qs),support=qs))
    return dict(stem=f'LP_{n}_{c["k"]}_unknown',**result,parameter_sha256=digest(c),independent_source_columns=True,
        layer_major_pullback=True,source_row_column_degrees=[6,3],typed_physical_rowspace_connected=True,
        cyclic_lift_automorphism=True,published_lb=c['published_lb'],published_ub=c['published_ub'],published_exact=None,
        independent_overall_upper=min(w['weight'] for w in words),independently_checked_uppers=words)


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/reference_ghp_cases.json'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=[]
    for c in json.loads(a.cases.read_text()):
        stem=f'LP_{c["n"]}_{c["k"]}_unknown';n,m=read_code(a.matrices,stem);out.append(certify(c,n,m));print(stem,'PASS',flush=True)
    a.out.write_text(json.dumps(out,indent=2)+'\n')


if __name__=='__main__':main()
