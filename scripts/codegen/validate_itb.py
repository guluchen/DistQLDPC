#!/usr/bin/env python3
"""Independent source column and Kronecker audits; no constructor imports."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
from validate_css import basis,equal_space,read_code,validate
from verify_css_witness import verify_witness


def require(ok,msg):
    if not ok:raise ValueError(msg)
def support(w):return [q for q in range(w.bit_length()) if (w>>q)&1]
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()


def reconstruct(c):
    L=c['L'];N=L**3;require(type(L)==int and L>=2 and c['n']==2*N,'invalid torus')
    for key in ['A','B']:
        require(c[key] and len(c[key])==len({tuple(e) for e in c[key]}) and all(len(e)==3 and all(type(a)==int and 0<=a<L for a in e) for e in c[key]),'invalid source support')
    vertices=list(itertools.product(range(L),repeat=3));inv={p:i for i,p in enumerate(vertices)};out=[]
    for axis in [0,1]:
        rows=[0]*N
        for q in range(2*N):
            block,h=divmod(q,N);p=vertices[h];key=(['A','B'] if axis==0 else ['B','A'])[block]
            for e in c[key]:
                root=tuple((p[j]+(-1 if axis==0 else 1)*e[j])%L for j in range(3));rows[inv[root]]^=1<<q
        out.append(rows)
    return out


def kron(a,na,b,nb):return [sum(wb<<(j*nb) for j in support(wa)) for wa in a for wb in b]
def transpose(rows,n):return [sum(((w>>q)&1)<<r for r,w in enumerate(rows)) for q in range(n)]


def tensor_source(c):
    L=c['L'];I=[1<<q for q in range(L)];S=[1<<((q+1)%L) for q in range(L)]
    x=kron(kron(S,L,I,L),L*L,I,L);y=kron(kron(I,L,S,L),L*L,I,L);z=kron(kron(I,L,I,L),L*L,S,L);N=L**3
    A=[(1<<q)^x[q]^y[q]^z[q] for q in range(N)];B=transpose(A,N)
    return [[a|(b<<N) for a,b in zip(A,B)],[b|(a<<N) for b,a in zip(transpose(B,N),transpose(A,N))]]


def permute(w,p):return sum(((w>>q)&1)<<r for q,r in enumerate(p))


def components(n,hx,hz):
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
    L=c['L'];N=L**3;hx,hz,gx,gz=m
    require(c['A']==[[0,0,0],[1,0,0],[0,1,0],[0,0,1]] and c['B']==[[0,0,0],[L-1,0,0],[0,L-1,0],[0,0,L-1]],'frozen self-dual source polynomial differs')
    require(n==c['n'] and [hx,hz]==reconstruct(c)==tensor_source(c),'actual physical columns/source tensor differ')
    r=validate(n,m);require(c['expected_k'] is None or r['k']==c['expected_k'],'SCIENTIFIC source k mismatch')
    require(hx==hz and equal_space(hx,hz),'actual self-dual XZ identity')
    require(all(len(support(w))==8 for w in hx+hz),'source check weight')
    v=list(itertools.product(range(L),repeat=3));index={p:i for i,p in enumerate(v)};maps=[]
    for axis in range(3):
        pp=[]
        for q in range(n):
            block,h=divmod(q,N);point=list(v[h]);point[axis]=(point[axis]+1)%L;pp.append(block*N+index[tuple(point)])
        require(len(set(pp))==n and all(equal_space(rr,[permute(w,pp) for w in rr]) for rr in [hx,hz]),'cyclic physical map')
        orbit=0
        for _ in range(L):orbit=pp[orbit]
        require(orbit==0 and len({index[tuple((a if j==axis else 0) for j in range(3))] for a in range(L)})==L,'generator order')
        maps.append(pp)
    require(all(maps[a][maps[b][q]]==maps[b][maps[a][q]] for a in range(3) for b in range(3) for q in range(n)),'axis action not commuting')
    # Coordinates enumerate every independently translated vertex: faithful Z_L^3.
    require(len(index)==N,'faithful full three-cycle vertex inventory')
    comp=components(n,hx,hz);require(comp==1,'typed physical stabilizer product partition; hold rather than add disconnected copies')
    words=[]
    for half,rows in [('X',gz),('Z',gx)]:
        w=min(rows,key=lambda x:(len(support(x)),x));qs=support(w);verify_witness(n,m,half,qs);require(len(qs)>=c['reference_lower'],'SCIENTIFIC actual word below source exact')
        words.append(dict(half=half,basis='computed full quotient basis; upper only',weight=len(qs),support=qs))
    return dict(stem=f'ITB_{n}_{r["k"]}_unknown',**r,L=L,parameter_sha256=digest(c),independent_physical_columns=True,separate_tensor_source=True,actual_self_dual_XZ_identity=True,faithful_three_cycle_maps=True,typed_physical_rowspace_connected=True,published_exact=c['published_exact'],published_upper=c['published_ub'],independent_overall_upper=min(w['weight'] for w in words),independently_checked_uppers=words)


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/itb_cases.json'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=[]
    for c in json.loads(a.cases.read_text()):
        matches=list(a.matrices.glob(f'ITB_{c["n"]}_*_unknown_Hx.txt'));require(len(matches)==1,'missing or ambiguous actual dimension stem');stem=matches[0].name[:-7];n,m=read_code(a.matrices,stem);r=certify(c,n,m);require(r['stem']==stem,'stem actual k mismatch');out.append(r);print(stem,'PASS',flush=True)
    a.out.write_text(json.dumps(out,indent=2)+'\n')


if __name__=='__main__':main()
