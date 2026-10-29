#!/usr/bin/env python3
"""Independent finite radial hypotheses, physical columns and tensor-order checks.

No constructor/logical-builder imports. Original GPL-3.0-or-later.
"""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
from validate_css import basis,dot,equal_space,read_code,validate
from verify_css_witness import verify_witness


def require(ok,msg):
    if not ok:raise ValueError(msg)
def support(w):return [q for q in range(w.bit_length()) if (w>>q)&1]
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()


def prime_rank(M,p):
    rows=[list(row) for row in M];rank=0
    for j in range(len(rows[0])):
        pivot=next((i for i in range(rank,len(rows)) if rows[i][j]%p),None)
        if pivot is None:continue
        rows[rank],rows[pivot]=rows[pivot],rows[rank];inv=pow(rows[rank][j]%p,p-2,p);rows[rank]=[x*inv%p for x in rows[rank]]
        for i in range(len(rows)):
            if i!=rank:
                t=rows[i][j]%p;rows[i]=[(x-t*y)%p for x,y in zip(rows[i],rows[rank])]
        rank+=1
    return rank


def parameters(c):
    r,s=c['r'],c['s'];A,B=c['A1'],c['A2']
    require(type(r)==int and r>=2 and type(s)==int and s>=2 and c['n']==2*r*r*s,'invalid source dimensions')
    for M in [A,B]:
        require(len(M)==r and all(len(row)==r for row in M),'base shape')
        require(all(type(e)==int and 0<=e<s for row in M for e in row),'exponent range/type')
    return r,s,A,B


def classical_facts(M,s):
    r=len(M);require(s>=2 and all(s%d for d in range(2,int(s**.5)+1)) and r<=s,'prime/r<=s')
    require(prime_rank(M,s)==r,'exponent rows dependent over prime field')
    require(all((M[i][j]-M[i][l]-M[k][j]+M[k][l])%s for i,k in itertools.combinations(range(r),2) for j,l in itertools.combinations(range(r),2)),'classical four-cycle')
    # Derive columns from each check/bit ring with source row-right convention.
    rows=[0]*(r*s)
    for j in range(r):
        for h in range(s):
            for i in range(r):rows[i*s+(h-M[i][j])%s]|=1<<(j*s+h)
    rank=len(basis(rows));require(rank==r*s-(r-1),'actual classical rank has extra dependencies; source high-probability qualifier matters')
    return dict(prime=s,exponent_rank=prime_rank(M,s),actual_binary_rank=rank,actual_classical_dimension=r*s-rank)


def reconstruct(c):
    r,s,A,B=parameters(c);N=r*r*s;out=[[0]*N for _ in range(2)]
    def row(i,j,v):return (i*r+j)*s+v%s
    for q in range(2*N):
        half,local=divmod(q,N);base,h=divmod(local,s);a,b=divmod(base,r)
        if not half:
            xx=[row(i,b,h-A[i][a]) for i in range(r)];zz=[row(a,j,h+B[b][j]) for j in range(r)]
        else:
            xx=[row(a,j,h-B[j][b]) for j in range(r)];zz=[row(i,b,h+A[a][i]) for i in range(r)]
        for axis,roots in enumerate([xx,zz]):
            for v in roots:out[axis][v]|=1<<q
    return out


def tensor_pullback(c):
    r,s,A,B=parameters(c);N=r*r*s;out=[[0]*N for _ in range(2)]
    # Independently instantiate Kronecker block entries in spoke-major order.
    # row=(v,i,j), column=(half,h,a,b), then pull back to base-major order.
    p=[half*N+(i*r+j)*s+h for half in range(2) for h in range(s) for i in range(r) for j in range(r)]
    for v in range(s):
        for i in range(r):
            for j in range(r):
                row=(v*r+i)*r+j
                for h in range(s):
                    for a in range(r):
                        if (h-v)%s==A[i][a]:out[0][row]|=1<<((h*r+a)*r+j)
                        if (v-h)%s==A[a][i]:out[1][row]|=1<<(N+(h*r+a)*r+j)
                    for b in range(r):
                        if (h-v)%s==B[j][b]:out[0][row]|=1<<(N+(h*r+i)*r+b)
                        if (v-h)%s==B[b][j]:out[1][row]|=1<<((h*r+i)*r+b)
    return [[sum(((rows[(v*r+i)*r+j]>>q)&1)<<p[q] for q in range(2*N)) for i in range(r) for j in range(r) for v in range(s)] for rows in out]


def permute(w,p):return sum(((w>>q)&1)<<j for q,j in enumerate(p))


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


def certify(c,n,m):
    r,s,A,B=parameters(c);hx,hz,gx,gz=m;facts=[classical_facts(M,s) for M in [A,B]]
    require(n==c['n'] and [hx,hz]==reconstruct(c),'actual radial physical columns/source differ')
    require([hx,hz]==tensor_pullback(c),'tensor/coordinate/conjugate-transpose pullback differs')
    result=validate(n,m);require(result['k']==c['k']==2*(r-1)**2,'actual quantum dimension/source conditions')
    require(len(hx)==len(hz)==r*r*s and result['rank_Hx']==result['rank_Hz']==(n-c['k'])//2,'actual rank/check count')
    require(all(len(support(w))==2*r for w in hx+hz),'row weight2r')
    require(all(sum((w>>q)&1 for w in rows)==r for q in range(n) for rows in [hx,hz]),'column degree r')
    require(physical_components(n,hx,hz)==1,'typed physical product partition')
    shift=[(q//s)*s+(q%s+1)%s for q in range(n)]
    require(all(equal_space(rows,[permute(w,shift) for w in rows]) for rows in [hx,hz]),'cyclic spoke automorphism')
    words=[]
    for half,logical in [('X',gz),('Z',gx)]:
        w=min(logical,key=lambda v:(len(support(v)),v));qs=support(w);verify_witness(n,m,half,qs);words.append(dict(half=half,basis='computed quotient basis; upper only',weight=len(qs),support=qs))
    X=[(0*r+j)*s+v for j in [0,r-1] for v in range(s)]
    Z=[(i*r+0)*s+v for i in [0,r-1] for v in range(s)]
    for half,qs in [('X',sorted(X)),('Z',sorted(Z))]:
        verify_witness(n,m,half,qs);require(len(qs)==2*s,'canonical ring-word bound');words.append(dict(half=half,basis='independent complete ring-pair word',weight=len(qs),support=qs))
    require(dot(sum(1<<q for q in X),sum(1<<q for q in Z))==1,'odd ring-pair intersection')
    return dict(stem=f'LP_{n}_{c["k"]}_unknown',**result,parameter_sha256=digest(c),classical=facts,
        independent_source_columns=True,spoke_major_tensor_pullback=True,typed_physical_rowspace_connected=True,
        cyclic_spoke_automorphism=True,source_rank_statement_qualified=True,published_exact=None,published_estimate=c['published_estimate'],
        reference_upper=c['reference_upper'],generic_ring_upper=2*s,independent_overall_upper=min(w['weight'] for w in words),independently_checked_uppers=words)


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/radial_cases.json'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=[]
    for c in json.loads(a.cases.read_text()):
        stem=f'LP_{c["n"]}_{c["k"]}_unknown';n,m=read_code(a.matrices,stem);out.append(certify(c,n,m));print(stem,'PASS',flush=True)
    a.out.write_text(json.dumps(out,indent=2)+'\n')


if __name__=='__main__':main()
