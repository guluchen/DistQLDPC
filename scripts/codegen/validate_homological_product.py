#!/usr/bin/env python3
"""Independent column action, actual product, canonical logicals and GF2 words.

No constructor, factor distance search or third-party implementation imports.
GPL-3.0-or-later.
"""
import argparse
import hashlib
import json
from pathlib import Path
from validate_css import basis,dot,read_code,validate
from verify_css_witness import verify_witness


def support(w):
    out=[]
    while w:
        b=w&-w;out.append(b.bit_length()-1);w^=b
    return out


def act(rows,v):return sum(dot(r,v)<<i for i,r in enumerate(rows))


def column(rows,j):return sum(((r>>j)&1)<<i for i,r in enumerate(rows))


def tensor(a,b,width):return sum(1<<(i*width+j) for i in support(a) for j in support(b))


def factor(c,f):
    M,H=c['M'],c['H'];R=(M-H)//2
    if not 1<=H<M or (M-H)%2:raise ValueError('invalid factor dimensions')
    u,inv,delta=([int(s,16) for s in f[k]] for k in ('U','inverse','delta'))
    if any(len(rows)!=M or any(w<0 or w>>M for w in rows) for rows in (u,inv,delta)):raise ValueError('factor outside physical width')
    for j in range(M):
        e=1<<j
        if act(u,act(inv,e))!=e or act(inv,act(u,e))!=e:raise ValueError('factor inverse identity fails')
        dj=1<<(j-R) if H+R<=j<M else 0
        if act(delta,column(u,j))!=act(u,dj):raise ValueError('factor conjugacy delta U=U D fails')
        if act(delta,column(delta,j)):raise ValueError('factor is not nilpotent')
    if len(basis(delta))!=R:raise ValueError('factor rank mismatch')
    return u,inv,delta


def reconstruct(c):
    M=c['M'];left,right=[factor(c,f) for f in c['factors']];a,b=left[2],right[2];N=M*M
    hx=[0]*N;hz=[]
    for q in range(N):
        i,j=divmod(q,M);col=0
        for r in support(column(a,i)):col^=1<<(r*M+j)
        for s in support(column(b,j)):col^=1<<(i*M+s)
        hz.append(col)
        for r in support(col):hx[r]^=1<<q
    return hx,hz,left,right


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
    return list(p.values())


def certify(c,n,m):
    hx,hz,gx,gz=m;M,H=c['M'],c['H'];xx,zz,left,right=reconstruct(c)
    if n!=c['n'] or n!=M*M or (hx,hz)!=(xx,zz):raise ValueError('actual product physical columns mismatch')
    result=validate(n,m);rank=(n-H*H)//2
    if result['k']!=H*H or result['k']!=c['k'] or result['rank_Hx']!=rank or result['rank_Hz']!=rank:raise ValueError('product rank/homology mismatch')
    if len(components(n,hx))!=1 or len(components(n,hz))!=1 or len(components(n,reduced(hx)+reduced(hz)))!=1:raise ValueError('disconnected product/stabilizer factor')
    z=[tensor(column(left[0],i),column(right[0],j),M) for i in range(H) for j in range(H)]
    x=[tensor(left[1][i],right[1][j],M) for i in range(H) for j in range(H)]
    if any(dot(w,r) for w in z for r in hx) or any(dot(w,r) for w in x for r in hz):raise ValueError('canonical logical syndrome fails')
    for i,a in enumerate(z):
        for j,b in enumerate(x):
            if dot(a,b)!=int(i==j):raise ValueError('canonical logical pairing is not identity')
    if len(basis(hz+z))!=rank+H*H or len(basis(hx+x))!=rank+H*H:raise ValueError('canonical logical quotient incomplete')
    weights=[bin(w).count('1') for w in hx+hz];factor_weights=[max(bin(w).count('1') for rows in (f[2],[column(f[2],j) for j in range(M)]) for w in rows) for f in (left,right)]
    if max(weights)>sum(factor_weights) or max(weights)>2*M:raise ValueError('tensor check-weight bound fails')
    words=[]
    for half,rows in (('X',x),('Z',z)):
        word=min(rows,key=lambda w:(bin(w).count('1'),w));s=support(word);verify_witness(n,m,half,s)
        words.append(dict(half=half,support=s,weight=len(s)))
    result.update(stem=f'HPC_{n}_{c["k"]}_unknown',factor_dimensions=[M,H,(M-H)//2],
                  factor_inverse_conjugacy_nilpotence_verified=True,canonical_pairing_identity=True,
                  canonical_logical_count=H*H,canonical_bases_sha256={k:hashlib.sha256(('\n'.join(format(w,'x') for w in rows)+'\n').encode()).hexdigest() for k,rows in (('X',x),('Z',z))},
                  physical_and_rowspace_connected=True,observed_check_weight_range=[min(weights),max(weights)],
                  factor_max_row_column_weights=factor_weights,theoretical_check_weight_bound=2*M,
                  individually_published_distance=None,independently_checked_uppers=words,independent_overall_upper=min(w['weight'] for w in words),
                  parameter_sha256=hashlib.sha256(json.dumps(c,sort_keys=True,separators=(',',':')).encode()).hexdigest(),
                  scientific_status='VALID_FINITE_SINGLE_SECTOR_CSS_WITH_UPPER_WORDS_ONLY')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('homological_product_cases.json'));ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text()):
        n,m=read_code(args.dir,f'HPC_{c["n"]}_{c["k"]}_unknown');results.append(certify(c,n,m))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
