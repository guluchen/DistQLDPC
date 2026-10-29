#!/usr/bin/env python3
"""Independent source columns, tensor blocks/metachecks and full CSS audit."""
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
    dims=c['dims'];require(len(dims)==3 and all(type(d)==int and d>=2 for d in dims),'invalid torus');v=list(itertools.product(*(range(d) for d in dims)));index={p:i for i,p in enumerate(v)};N=len(v);require(c['n']==3*N,'invalid n')
    for key in ['A','B','C']:
        require(c[key] and len(c[key])==len({tuple(e) for e in c[key]}) and all(len(e)==3 and all(type(a)==int and 0<=a<d for a,d in zip(e,dims)) for e in c[key]),'invalid source support')
    hx=[0]*N;hz=[0]*(3*N);mz=[0]*N
    # Incidences are enumerated from data or check columns, independently
    # of the constructor's translated rows. The source uses FIRST columns.
    table=[{1:'C',2:'B'},{0:'C',2:'A'},{0:'B',1:'A'}]
    for q in range(3*N):
        block,h=divmod(q,N);p=v[h]
        for e in c[['A','B','C'][block]]:
            root=tuple((p[j]+e[j])%dims[j] for j in range(3));hx[index[root]]^=1<<q
            root=tuple((p[j]-e[j])%dims[j] for j in range(3));mz[index[root]]^=1<<q
        for kind,lookup in enumerate(table):
            if block not in lookup:continue
            for e in c[lookup[block]]:
                root=tuple((p[j]-e[j])%dims[j] for j in range(3));hz[kind*N+index[root]]^=1<<q
    return hx,hz,mz


def kron(a,na,b,nb):return [sum(wb<<(j*nb) for j in support(wa)) for wa in a for wb in b]
def transpose(rows,n):return [sum(((w>>q)&1)<<i for i,w in enumerate(rows)) for q in range(n)]


def tensor_source(c):
    dims=c['dims'];N=c['n']//3;polys=[]
    for key in ['A','B','C']:
        rows=[0]*N
        for e in c[key]:
            factors=[[1<<((r-a)%d) for r in range(d)] for d,a in zip(dims,e)]
            term=kron(kron(factors[0],dims[0],factors[1],dims[1]),dims[0]*dims[1],factors[2],dims[2])
            rows=[a^b for a,b in zip(rows,term)]
        polys.append(rows)
    A,B,C=polys;At,Bt,Ct=[transpose(p,N) for p in polys]
    hx=[a|(b<<N)|(cc<<(2*N)) for a,b,cc in zip(A,B,C)]
    hz=[(cc<<N)|(b<<(2*N)) for cc,b in zip(Ct,Bt)]+[cc|(a<<(2*N)) for cc,a in zip(Ct,At)]+[b|(a<<N) for b,a in zip(Bt,At)]
    mz=[a|(b<<N)|(cc<<(2*N)) for a,b,cc in zip(At,Bt,Ct)]
    return hx,hz,mz


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


def permute(w,p):return sum(((w>>q)&1)<<r for q,r in enumerate(p))


def check_meta(hz,mz):
    for w in mz:
        acc=0
        for i in support(w):acc^=hz[i]
        require(acc==0,'metacheck redundancy violated')


def certify(c,n,m):
    hx,hz,gx,gz=m;expected=reconstruct(c);require(expected==tensor_source(c) and [hx,hz]==list(expected[:2]),'actual source columns/tensor block transpose differs');mz=expected[2];N=n//3
    require(n==c['n'] and len(hx)==N and len(hz)==3*N,'source block shapes')
    result=validate(n,m);require(result['k']==c['k'],'SCIENTIFIC source k mismatch')
    require(all(len(support(w))==9 for w in hx) and all(len(support(w))==6 for w in hz),'source row weights')
    check_meta(hz,mz)
    require(len(basis(mz))==result['rank_Hx'],'actual metacheck/source inversion rank')
    dims=c['dims'];v=list(itertools.product(*(range(d) for d in dims)));index={p:i for i,p in enumerate(v)};maps=[]
    for axis,d in enumerate(dims):
        perm=[]
        for q in range(n):
            block,h=divmod(q,N);p=list(v[h]);p[axis]=(p[axis]+1)%d;perm.append(block*N+index[tuple(p)])
        require(len(set(perm))==n and all(equal_space(rr,[permute(w,perm) for w in rr]) for rr in [hx,hz]),'cyclic physical stabilizer map')
        q=0;seen=set()
        for _ in range(d):seen.add(q);q=perm[q]
        require(q==0 and len(seen)==d,'actual axis order');maps.append(perm)
    require(all(maps[a][maps[b][q]]==maps[b][maps[a][q]] for a in range(3) for b in range(3) for q in range(n)),'cyclic maps not commuting')
    require(components(n,hx,hz)==1,'typed physical stabilizer product partition; hold instead of disconnected copies')
    words=[]
    for half,rows in [('X',gz),('Z',gx)]:
        w=min(rows,key=lambda x:(len(support(x)),x));qs=support(w);verify_witness(n,m,half,qs);require(len(qs)>=c['reference_lower'],'SCIENTIFIC actual word below source global exact')
        exact=c.get('published_'+half+'_exact');require(exact is None or len(qs)>=exact,'SCIENTIFIC actual word below published exact half')
        words.append(dict(half=half,basis='computed complete quotient basis; upper only',weight=len(qs),support=qs))
    return dict(stem=f'TT_{n}_{c["k"]}_unknown',**result,parameter_sha256=digest(c),independent_physical_columns=True,separate_tensor_block_source=True,metacheck_redundancy_verified=True,rank_metacheck=len(basis(mz)),faithful_cyclic_maps=True,typed_physical_rowspace_connected=True,assumed_XZ_metric_map=False,published_exact=c['published_exact'],published_upper=c['published_ub'],published_X_upper=c['published_X_upper'],independent_overall_upper=min(w['weight'] for w in words),independently_checked_uppers=words)


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/tt_cases.json'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=[]
    for c in json.loads(a.cases.read_text()):
        stem=f'TT_{c["n"]}_{c["k"]}_unknown';n,m=read_code(a.matrices,stem);out.append(certify(c,n,m));print(stem,'PASS',flush=True)
    a.out.write_text(json.dumps(out,indent=2)+'\n')


if __name__=='__main__':main()
