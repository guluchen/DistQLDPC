#!/usr/bin/env python3
"""Independent reverse-shuffle, set elimination and HGP column incidence.

GPL-3.0-or-later. No generator/logical-builder imports or distance search.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
from validate_css import basis,contains,equal_space,read_code,validate
from verify_css_witness import verify_witness


def factors(c):
    n=c['classical_n'];ps=c['permutations']
    if n%4 or n<4 or c['j']!=3 or c['check_weight']!=4 or len(ps)!=3 or ps[0]!=list(range(n)):
        raise ValueError('invalid Gallager partition specification')
    for block,p in enumerate(ps):
        if sorted(p)!=list(range(n)):raise ValueError('not a permutation')
        if block==0:continue
        restored=p[:]
        # Undo the constructor's descending shuffle in ascending order.
        for i in range(1,n):
            attempt=0;bound=2**256-(2**256%(i+1))
            while True:
                label='distqldpc-gallager-v1|n={}|seed={}|block={}|i={}|attempt={}'.format(n,c['seed'],block,i,attempt)
                value=int(hashlib.sha256(label.encode('ascii')).hexdigest(),16)
                if value<bound:break
                attempt+=1
            j=value%(i+1);restored[i],restored[j]=restored[j],restored[i]
        if restored!=list(range(n)):raise ValueError('permutation differs from frozen seed/hash stream')
    raw=[set(p[t:t+4]) for p in ps for t in range(0,n,4)]
    pivots={};indices=[]
    for i,original in enumerate(raw):
        row=set(original)
        while row:
            pivot=min(row)
            if pivot in pivots:row.symmetric_difference_update(pivots[pivot])
            else:pivots[pivot]=row;indices.append(i);break
    if indices!=c['selected_rows'] or len(indices)!=c['rank_classical']:
        raise ValueError('independent sparse-row selection/rank disagreement')
    rows=[raw[i] for i in indices]
    return raw,rows


def reconstruct(c):
    raw,h=factors(c);n=c['classical_n'];r=len(h);N=n*n+r*r
    x=[0]*(r*n);z=[0]*(n*r)
    for q in range(N):
        if q<n*n:
            a,b=divmod(q,n)
            for check,row in enumerate(h):
                if a in row:x[check*n+b]|=1<<q
                if b in row:z[a*r+check]|=1<<q
        else:
            a,b=divmod(q-n*n,r)
            for v in h[b]:x[a*n+v]|=1<<q
            for v in h[a]:z[v*r+b]|=1<<q
    return x,z


def connected(n,rows):
    parent=list(range(n))
    def root(x):
        while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
        return x
    for row in rows:
        if isinstance(row,int):support=[i for i in range(n) if (row>>i)&1]
        else:support=list(row)
        for i in support[1:]:parent[root(i)]=root(support[0])
    return len({root(i) for i in range(n)})==1


def transpose_word(word,n,r):
    out=0
    for q in range(n*n+r*r):
        if not (word>>q)&1:continue
        if q<n*n:a,b=divmod(q,n);p=b*n+a
        else:a,b=divmod(q-n*n,r);p=n*n+b*r+a
        out|=1<<p
    return out


def certify(c,N,matrices):
    n=c['classical_n'];raw,h=factors(c);r=len(h);hx,hz,gx,gz=matrices
    if (hx,hz)!=reconstruct(c):raise ValueError('HGP matrix differs from independent physical columns')
    result=validate(N,matrices)
    if (N,result['k'])!=(c['n'],c['k']) or N!=n*n+r*r or result['k']!=(n-r)**2:
        raise ValueError('HGP dimensions differ from actual classical rank')
    if result['rank_Hx']!=r*n or result['rank_Hz']!=r*n:raise ValueError('quantum check rank mismatch')
    if any(len(s)!=4 for s in raw) or any(sum(q in s for s in raw)!=3 for q in range(n)):
        raise ValueError('raw factor is not(3,4)-regular')
    rawbits=[sum(1<<q for q in s) for s in raw];hbits=[sum(1<<q for q in s) for s in h]
    if not equal_space(rawbits,hbits) or len(basis(hbits))!=r or any(len(s)!=4 for s in h):
        raise ValueError('row selection changes code or sparsity')
    if not connected(n,raw) or not connected(n,h) or not connected(N,hx) or not connected(N,hz):
        raise ValueError('disconnected fixed realization; do not silently resample')
    if set(transpose_word(row,n,r) for row in hx)!=set(hz):raise ValueError('explicit X/Z tensor swap failed')
    span=basis(hbits);j=next(i for i in range(n) if not contains(span,1<<i))
    word=sum(1<<(i*n+j) for i in range(n));dual=transpose_word(word,n,r);witnesses=[]
    for half,w in (('Z',word),('X',dual)):
        support=[q for q in range(N) if (w>>q)&1];verify_witness(N,matrices,half,support)
        if len(support)!=n:raise ValueError('algebraic upper witness mismatch')
        witnesses.append(dict(half=half,support=support,weight=len(support)))
    result.update(stem=f'HGP_{N}_{result["k"]}_unknown',classical_n=n,classical_rank=r,
                  classical_dimension=n-r,raw_row_count=len(raw),selected_rows=c['selected_rows'],
                  raw_row_weight=4,raw_column_weight=3,
                  selected_column_degrees=dict(sorted(Counter(sum(q in row for row in h) for q in range(n)).items())),
                  quantum_row_weights=dict(sorted(Counter(bin(row).count('1') for row in hx+hz).items())),
                  connected=True,XZ_tensor_swap=True,algebraic_upper_witnesses=witnesses,
                  factor_raw_supports=[sorted(s) for s in raw],factor_sparse_supports=[sorted(s) for s in h],
                  individually_published_distance=None,verified_algebraic_ub=n)
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('gallager_hgp_cases.json'))
    ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();out=[]
    for c in json.loads(args.cases.read_text()):
        N,m=read_code(args.dir,f'HGP_{c["n"]}_{c["k"]}_unknown');out.append(certify(c,N,m))
    text=json.dumps(out,indent=2)+'\n';args.output.write_text(text);print(text,end='')


if __name__=='__main__':main()
