#!/usr/bin/env python3
"""Independent column and finite-GF2 audit of SC-HGP; no constructor imports."""
import argparse
import hashlib
import json
from pathlib import Path
from validate_css import basis,read_code,validate
from verify_css_witness import verify_witness


def require(b,msg):
    if not b:raise ValueError(msg)
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):
    ans=[]
    while w:
        v=w&-w;ans.append(v.bit_length()-1);w^=v
    return ans


def physical_components(n,hx,hz):
    # Keep Pauli types through unique RREF; merge Xq/Zq only on physical support.
    p=basis(hx+[w<<n for w in hz])
    for a in sorted(p):
        for b in p:
            if b>a and (p[b]>>a)&1:p[b]^=p[a]
    parent=list(range(n))
    def root(i):
        while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
        return i
    for w in p.values():
        qs={q%n for q in support(w)}
        if qs:
            q0=next(iter(qs))
            for q in qs:parent[root(q)]=root(q0)
    return len({root(q) for q in range(n)})


def expected_columns(c):
    L,M=c['periods'];a,b=c['partition_A'],c['partition_B'];ra,rb=len(a),len(b);na,nb=len(a[0]),len(b[0]);m1,m2=c['memory'];G=L*M
    # Extract digits independently by integer division/subtraction.
    def offsets(d):u=d//(m2+1);return u,d-u*(m2+1)
    def predecessor(u,v,d,complement=False):
        x,y=offsets(d)
        if complement:x,y=m1-x,m2-y
        return ((u-x)%L)*M+(v-y)%M
    cols=[]
    for j1 in range(na):
        for j2 in range(nb):
            for u in range(L):
                for v in range(M):
                    xx=sum(1<<((i1*nb+j2)*G+predecessor(u,v,a[i1][j1])) for i1 in range(ra))
                    zz=sum(1<<((j1*rb+i2)*G+predecessor(u,v,b[i2][j2])) for i2 in range(rb))
                    cols.append((xx,zz))
    for i1 in range(ra):
        for i2 in range(rb):
            for u in range(L):
                for v in range(M):
                    xx=sum(1<<((i1*nb+j2)*G+predecessor(u,v,b[i2][j2],True)) for j2 in range(nb))
                    zz=sum(1<<((j1*rb+i2)*G+predecessor(u,v,a[i1][j1],True)) for j1 in range(na))
                    cols.append((xx,zz))
    return cols


def source_kronecker_columns(c):
    """Expand Eq58 in its source tensor order, then apply explicit bijections."""
    L,M=c['periods'];G=L*M;N=58*G;cols=[[0,0] for _ in range(N)]
    A={(i,j):(d//4,d%4) for i,row in enumerate(c['partition_A']) for j,d in enumerate(row)}
    B={(i,j):(d//4,d%4) for i,row in enumerate(c['partition_B']) for j,d in enumerate(row)}
    I7={(i,i):(0,0) for i in range(7)};I3={(i,i):(0,0) for i in range(3)}
    def barT(mat):return {(j,i):(3-u,3-v) for (i,j),(u,v) in mat.items()}
    def tensor(a,b,rb,cb):
        return {(ia*rb+ib,ja*cb+jb):(u+x,v+y) for (ia,ja),(u,v) in a.items() for (ib,jb),(x,y) in b.items()}
    # Source row orders (j2,i1) / (i2,j1), source columns (j2,j1)/(i2,i1).
    def physical(q):
        if q<49:return (q%7)*7+q//7
        q-=49;return 49+(q%3)*3+q//3
    for engine,blocks in enumerate(((tensor(I7,A,3,7),tensor(barT(B),I3,3,3)),(tensor(B,I7,7,7),tensor(I3,barT(A),7,3)))):
        for block,mat in enumerate(blocks):
            for (row,col),(du,dv) in mat.items():
                rr=(row%3)*7+row//3 if engine==0 else (row%7)*3+row//7
                qq=physical(col+(49 if block else 0))
                for u in range(L):
                    for v in range(M):
                        q=qq*G+((u+du)%L)*M+(v+dv)%M
                        cols[q][engine]^=1<<(rr*G+u*M+v)
    return [tuple(c) for c in cols]


def certify(c,cert,n,matrices):
    hx,hz,gx,gz=matrices
    A=((4,10,3,12,13,1,5),(7,8,8,11,7,11,3),(1,6,12,3,2,0,15))
    B=((4,11,13,12,7,3,12),(3,13,15,10,6,1,0),(4,1,5,7,14,15,3))
    require(tuple(map(tuple,c['partition_A']))==A and tuple(map(tuple,c['partition_B']))==B,'source Eq89 partition facts differ')
    require(c['memory']==[3,3] and c['periods'][0]==c['periods'][1] and c['periods'][0] in [2,4,5,7,10],'frozen source/memory/period selection differs')
    require(cert['case']==c and cert['parameter_sha256']==digest(c),'parameter/certificate identity differs')
    L,M=c['periods'];G=L*M;require(n==58*G and len(hx)==len(hz)==21*G,'physical size/check row mismatch')
    actual=[[0]*n for _ in range(2)]
    for e,rows in enumerate((hx,hz)):
        for i,w in enumerate(rows):
            require(len(support(w))==10,'check weight differs')
            for q in support(w):actual[e][q]|=1<<i
    columns=expected_columns(c)
    require(columns==source_kronecker_columns(c),'explicit source Eq58 tensor-order bijection differs')
    for q,(xx,zz) in enumerate(columns):
        require((actual[0][q],actual[1][q])==(xx,zz),'actual physical column/complement/inverse shift differs at '+str(q))
        require(len(support(xx))==len(support(zz))==(3 if q<49*G else 7),'physical column weight differs')
    # Every A/B edge pair has the same relative replica displacement through
    # VV and CC: a-b = (m-b)-(m-a), including modulo-period aliases.
    paths=0
    for ar in A:
        for av in ar:
            au,aw=av//4,av%4
            for br in B:
                for bv in br:
                    bu,bw=bv//4,bv%4
                    require(((au-bu)%L,(aw-bw)%M)==(((3-bu)-(3-au))%L,((3-bw)-(3-aw))%M),'two-path cancellation failed')
                    paths+=G
    result=validate(n,matrices)
    require((cert['n'],cert['k'],cert['rank_Hx'],cert['rank_Hz'])==(n,result['k'],result['rank_Hx'],result['rank_Hz']),'finite rank certificate differs')
    if 'k' in c:require(c['k']==result['k'],'frozen computed dimension differs')
    require(physical_components(n,hx,hz)==1,'physical stabilizer space has hidden product blocks')
    uppers=[]
    for half,kind,rows in [('X','Gz',gz),('Z','Gx',gx)]:
        i,w=min(enumerate(rows),key=lambda iw:len(support(iw[1])));qs=support(w);verify_witness(n,matrices,half,qs)
        uppers.append(dict(half=half,basis=kind,zero_based_row=i,weight=len(qs),support=qs))
    return dict(stem=f'SC_{n}_{result["k"]}_unknown',**result,parameter_sha256=digest(c),certificate_sha256=digest(cert),
        source_equation=89,periods=c['periods'],published_exact=None,published_upper_estimate=c['published_upper_estimate'],
        every_physical_column=True,source_kronecker_order_bijection=True,paired_commuting_paths=paths,full_typed_physical_space_connected=True,
        independently_checked_uppers=uppers,independent_overall_upper=min(w['weight'] for w in uppers))


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/spatially_coupled_cases.json'))
    ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-188/raw/certificates'));ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=[]
    for c in json.loads(args.cases.read_text()):
        stem=f'SC_{c["n"]}_{c["k"]}_unknown';n,m=read_code(args.matrices,stem);cert=json.loads((args.certificates/f'{stem}.json').read_text())
        out.append(certify(c,cert,n,m));print(stem,'PASS',flush=True)
    args.out.write_text(json.dumps(out,indent=2)+'\n')


if __name__=='__main__':main()
