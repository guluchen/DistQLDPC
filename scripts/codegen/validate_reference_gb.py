#!/usr/bin/env python3
"""Independent physical-column, set-polynomial and actual logical GB audit.

No constructor/logical-builder imports. Original GPL-3.0-or-later.
"""
import argparse
import hashlib
import json
from pathlib import Path
from validate_css import basis,equal_space,read_code,validate
from verify_css_witness import verify_witness


def require(ok,msg):
    if not ok:raise ValueError(msg)
def support(w):return [q for q in range(w.bit_length()) if (w>>q)&1]
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()


def remainder(a,b):
    a=set(a);b=set(b);require(b,'zero polynomial divisor')
    while a and max(a)>=max(b):
        t=max(a)-max(b);a.symmetric_difference_update(x+t for x in b)
    return a


def gcd(a,b):
    a,b=set(a),set(b)
    while b:a,b=b,remainder(a,b)
    return a


def reconstruct(c):
    l=c['l'];out=[]
    require(type(l)==int and l>=2 and c['n']==2*l,'invalid source length')
    for key in ('a','b'):
        require(c[key] and len(c[key])==len(set(c[key])) and all(type(e)==int and 0<=e<l for e in c[key]),'invalid source support')
    for half in (0,1):
        rows=[0]*l
        for q in range(2*l):
            block,h=divmod(q,l);s=c[('a','b')[block]] if not half else c[('b','a')[block]]
            # First-column source convention: column h meets roots h+e;
            # transpose meets h-e. Enumerate incidence from physical columns.
            for e in s:rows[(h-e if half else h+e)%l]|=1<<q
        out.append(rows)
    return out


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


def certify(c,n,m):
    hx,hz,gx,gz=m;l=c['l'];require(n==c['n'] and [hx,hz]==reconstruct(c),'actual matrix/source columns differ')
    r=validate(n,m);g=gcd(gcd(c['a'],c['b']),{0,l});degree=max(g)
    require(r['k']==c['k']==2*degree and r['rank_Hx']==r['rank_Hz']==l-degree,'source polynomial/binary dimensions disagree')
    w=len(c['a'])+len(c['b']);require(all(len(support(v))==w for v in hx+hz),'check row weight')
    for rows,degrees in [(hx,[len(c['a']),len(c['b'])]),(hz,[len(c['b']),len(c['a'])])]:
        require(len(set(rows))==l,'duplicate check row')
        require(all(sum((row>>q)&1 for row in rows)==degrees[q//l] for q in range(n)),'physical column degree')
    shift=[(q//l)*l+(q%l+1)%l for q in range(n)]
    dual=[(1-q//l)*l+(-q%l)%l for q in range(n)]
    require(all(equal_space(rows,[permute(v,shift) for v in rows]) for rows in [hx,hz]),'cyclic automorphism')
    require(equal_space(hz,[permute(v,dual) for v in hx]) and equal_space(hx,[permute(v,dual) for v in hz]),'XZ physical involution')
    require(physical_components(n,hx,hz)==1,'typed physical stabilizer product partition')
    words=[]
    for half,logical in [('X',gz),('Z',gx)]:
        word=min(logical,key=lambda v:(len(support(v)),v));qs=support(word);verify_witness(n,m,half,qs)
        words.append(dict(half=half,basis='computed quotient basis; upper only',weight=len(qs),support=qs))
    return dict(stem=f'GB_{n}_{c["k"]}_unknown',**r,parameter_sha256=digest(c),independent_source_columns=True,
        common_divisor_support=sorted(g),source_check_weight=w,typed_physical_rowspace_connected=True,
        verified_XZ_weight_preserving_involution=True,published_lb=c['published_lb'],published_ub=c['published_ub'],
        published_exact=None,independent_overall_upper=min(w['weight'] for w in words),independently_checked_uppers=words)


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/reference_gb_cases.json'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=[]
    for c in json.loads(a.cases.read_text()):
        stem=f'GB_{c["n"]}_{c["k"]}_unknown';n,m=read_code(a.matrices,stem);out.append(certify(c,n,m));print(stem,'PASS',flush=True)
    a.out.write_text(json.dumps(out,indent=2)+'\n')


if __name__=='__main__':main()
