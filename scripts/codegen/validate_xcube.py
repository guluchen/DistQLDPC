#!/usr/bin/env python3
"""Independent edge-incidence and complete disjoint-coset detector proof."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
from validate_css import basis,contains,dot,read_code,validate
from verify_css_witness import verify_witness


def require(b,msg):
    if not b:raise ValueError(msg)
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):
    out=[]
    while w:b=w&-w;out.append(b.bit_length()-1);w^=b
    return out

def pack(n,qs):
    require(qs and len(qs)==len(set(qs)) and min(qs)>=0 and max(qs)<n,'invalid materialized support')
    return sum(1<<q for q in qs)


def detector_family(n,records,parity,stabilizer,k,L):
    require(len(records)==k,'detectors incomplete');base=[pack(n,r['support']) for r in records];s=basis(stabilizer)
    require(len(basis(stabilizer+base))==len(s)+k,'detector quotient basis incomplete')
    for r,b in zip(records,base):
        require(not any(dot(b,h) for h in parity),'detector outside kernel')
        reps=r['equivalent_supports'];require(len(reps)==L,'disjoint representative count')
        used=0
        for qs in reps:
            w=pack(n,qs);require(not used&w,'representative supports overlap');used|=w
            require(contains(s,w^b),'representative outside detector stabilizer coset')
            require(not any(dot(w,h) for h in parity),'representative outside kernel')
    return base


def physical_components(n,hx,hz):
    p=basis(hx+[w<<n for w in hz])
    for a in sorted(p):
        for b in p:
            if b>a and (p[b]>>a)&1:p[b]^=p[a]
    parent=list(range(n))
    def root(q):
        while parent[q]!=q:parent[q]=parent[parent[q]];q=parent[q]
        return q
    for w in p.values():
        qs={q%n for q in support(w)}
        if qs:
            first=next(iter(qs))
            for q in qs:parent[root(q)]=root(first)
    return len({root(q) for q in range(n)})


def certify(c,cert,n,m):
    L=c['L'];V=L**3;k=6*L-3;hx,hz,gx,gz=m
    require(L in [3,5,7,9] and L%2 and (n,c['n'],c['k'])==(3*V,3*V,k),'source odd-L dimensions')
    require(cert['case']==c and cert['parameter_sha256']==digest(c),'case/certificate identity')
    vertices=[(u,v,w) for u in range(L) for v in range(L) for w in range(L)]
    require(vertices==[tuple(v) for v in cert['vertices']] and len(hx)==V and len(hz)==3*V,'source vertex/check inventory')
    require(all(len(support(w))==12 for w in hx) and all(len(support(w))==4 for w in hz),'source cube/star check weight')
    def vertex(v):return ((v[0]%L)*L+v[1]%L)*L+v[2]%L
    actual=[[0]*n for _ in range(2)]
    for e,rows in enumerate([hx,hz]):
        for row,w in enumerate(rows):
            for q in support(w):actual[e][q]|=1<<row
    for q in range(n):
        axis=q//V;v=vertices[q%V];other=[j for j in range(3) if j!=axis];end=list(v);end[axis]+=1
        origins=[]
        for mask in range(4):
            o=list(v)
            for j,a in enumerate(other):o[a]-=(mask>>j)&1
            origins.append(vertex(o))
        xx=sum(1<<o for o in origins)
        zz=sum(1<<(3*vertex(p)+normal) for p in [v,end] for normal in other)
        require((actual[0][q],actual[1][q])==(xx,zz),'actual edge column/source endpoints differ at '+str(q))
    result=validate(n,m)
    require(result['k']==k and (result['rank_Hx'],result['rank_Hz'])==(V-3*L+2,2*V-3*L+1),'actual ranks/odd-L source k')
    require((cert['n'],cert['k'],cert['rank_Hx'],cert['rank_Hz'])==(n,k,result['rank_Hx'],result['rank_Hz']),'rank certificate identity')
    X,Z=cert['detectors']['X'],cert['detectors']['Z'];ix=iz=0
    for axis in range(3):
        a,b=[j for j in range(3) if j!=axis]
        for u,v in [(0,j) for j in range(L)]+[(j,0) for j in range(1,L)]:
            r=X[ix];ix+=1;require((r['axis'],r['transverse'])==(axis,[u,v]),'source X detector label')
            def physical_pairs(pairs):return [q for q in range(axis*V,(axis+1)*V) if (vertices[q%V][a],vertices[q%V][b]) in pairs]
            reps=[physical_pairs({(u,v)})]+[physical_pairs({(uu,v),(u,vv),(uu,vv)}) for uu,vv in zip([j for j in range(L) if j!=u],[j for j in range(L) if j!=v])]
            require(r['support']==reps[0] and r['equivalent_supports']==reps,'source X line/triple-line coordinates')
        for varying,fixed in [(a,j) for j in range(L)]+[(b,j) for j in range(1,L)]:
            r=Z[iz];iz+=1;require((r['axis'],r['varying_axis'],r['fixed'])==(axis,varying,fixed),'source Z detector label')
            other=b if varying==a else a
            reps=[[q for q in range(axis*V,(axis+1)*V) if vertices[q%V][axis]==layer and vertices[q%V][other]==fixed] for layer in range(L)]
            require(r['support']==reps[0] and r['equivalent_supports']==reps,'source Z ribbon/layer coordinates')
    xb=detector_family(n,X,hz,hx,k,L);zb=detector_family(n,Z,hx,hz,k,L)
    pairing=[sum(dot(x,z)<<j for j,z in enumerate(zb)) for x in xb];require(len(basis(pairing))==k,'detector pairing incomplete')
    require(physical_components(n,hx,hz)==1,'hidden typed physical product partition')
    uppers=[]
    for half,rows in [('X',X),('Z',Z)]:
        qs=rows[0]['support'];verify_witness(n,m,half,qs);require(len(qs)==L,'upper word does not meet lower certificate');uppers.append(dict(half=half,basis='independent complete geometric detector basis',zero_based_row=0,weight=L,support=qs))
    return dict(stem=f'XCB_{n}_{k}_unknown',**result,parameter_sha256=digest(c),certificate_sha256=digest(cert),independent_edge_columns=True,full_detector_quotients_and_pairing=True,
        all_disjoint_coset_families=True,representatives_per_detector=L,typed_physical_rowspace_connected=True,disjoint_detector_lower=dict(X=L,Z=L),independent_overall_lower=L,
        independent_overall_upper=L,independently_checked_uppers=uppers,published_exact=None)


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/xcube_cases.json'));ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-190/raw/certificates'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();results=[]
    for c in json.loads(a.cases.read_text()):
        stem=f'XCB_{c["n"]}_{c["k"]}_unknown';n,m=read_code(a.matrices,stem);cert=json.loads((a.certificates/f'{stem}.json').read_text());results.append(certify(c,cert,n,m));print(stem,'PASS',flush=True)
    a.out.write_text(json.dumps(results,indent=2)+'\n')


if __name__=='__main__':main()
