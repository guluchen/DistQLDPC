#!/usr/bin/env python3
"""Independent carryless-field/root-syndrome/dual-polynomial CSS audit (GPL3+).

Does not import constructor, logical builder or any distance solver. It
derives the generator by a one-dimensional algebraic kernel, not root products.
"""
import argparse
from functools import lru_cache
import json
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).parent))
from validate_css import basis,contains,dot,equal_space,read_code,validate
from verify_css_witness import verify_witness

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('bch_cases.json').read_text())


def remainder(a,b):
    if b<=0:raise ValueError('invalid polynomial modulus')
    while a.bit_length()>=b.bit_length():a^=b << (a.bit_length()-b.bit_length())
    return a


def product(a,b):
    terms=[i for i in range(b.bit_length()) if (b >> i)&1]
    out=0
    for i in terms:out^=a << i
    return out


def gcd(a,b):
    while b:a,b=b,remainder(a,b)
    return a


def irreducible(p):
    m=p.bit_length()-1
    if m<2 or p<=0 or not p&1:return False
    x=2;power=x
    for i in range(1,m+1):
        power=remainder(product(power,power),p)
        if i<=m//2 and gcd(power^x,p)!=1:return False
    return power==x


@lru_cache(None)
def field_table(m,p):
    if not 2<=m<=12 or p.bit_length()!=m+1 or not irreducible(p):
        raise ValueError('independent field irreducibility failed')
    table=[];seen=set();element=1
    for _ in range((1 << m)-1):
        if element==0 or element in seen:raise ValueError('independent primitive-element order failed')
        seen.add(element);table.append(element)
        element=remainder(product(element,2),p)
    if element!=1 or len(seen)!=(1 << m)-1:raise ValueError('incomplete nonzero field group')
    return tuple(table)


def source_parity(case):
    n,m,p,delta=(case[k] for k in ('n','m','primitive_polynomial','delta'))
    if n%2==0 or not 2<=delta<n or ((1 << m)-1)%n:
        raise ValueError('invalid binary cyclic source parameters')
    table=field_table(m,p)
    stride=((1 << m)-1)//n
    powers=[table[(stride*i)%len(table)] for i in range(n)]
    if len(set(powers))!=n:raise ValueError('root order differs from length')
    # Scalar binary coordinates of sum_i c_i beta^(j*i)=0 for each
    # consecutive source root j; every physical column is checked explicitly.
    rows=[]
    for j in range(1,delta):
        row=[0]*m
        for i in range(n):
            value=powers[(i*j)%n]
            for t in range(m):
                if (value >> t)&1:row[t] |= 1 << i
        rows+=row
    return rows


def kernel(rows,n):
    matrix=[{i for i in range(n) if (r >> i)&1} for r in rows]
    pivots=[]
    for col in range(n):
        pos=next((i for i in range(len(pivots),len(matrix)) if col in matrix[i]),None)
        if pos is None:continue
        k=len(pivots);matrix[k],matrix[pos]=matrix[pos],matrix[k]
        for i in range(len(matrix)):
            if i!=k and col in matrix[i]:matrix[i]^=matrix[k]
        pivots.append(col)
    result=[]
    for free in (j for j in range(n) if j not in pivots):
        support={free}|{col for col,row in zip(pivots,matrix) if free in row}
        result.append(sum(1 << i for i in support))
    return result


def reconstruct(case):
    n=case['n'];rows=source_parity(case);r=len(basis(rows))
    candidates=kernel([row & ((1 << (r+1))-1) for row in rows],r+1)
    if len(candidates)!=1 or candidates[0].bit_length()!=r+1:
        raise ValueError('minimal root polynomial is not uniquely monic of degree rank')
    g=[(candidates[0] >> i)&1 for i in range(r+1)]
    # Independent ordinary coefficient-list long division of X^n+1 by g.
    remaining=[0]*(n+1);remaining[0]=remaining[n]=1
    quotient=[0]*(n-r+1)
    for d in range(n,r-1,-1):
        if remaining[d]:
            quotient[d-r]=1
            for j,coefficient in enumerate(g):remaining[d-r+j]^=coefficient
    if any(remaining):raise ValueError('root-derived generator does not divide X^n+1')
    reciprocal=list(reversed(quotient))
    dual=sum(v << i for i,v in enumerate(reciprocal))
    checks=[dual << i for i in range(r)]
    if not equal_space(checks,rows):raise ValueError('root syndrome and reciprocal-dual spaces disagree')
    return checks,rows,candidates[0]


def source_hypotheses(case):
    n,m,delta=(case[k] for k in ('n','m','delta'))
    order=next((i for i in range(1,m+1) if pow(2,i,n)==1),None)
    maximum=n*((1 << ((m+1)//2))-1)//((1 << m)-1)
    if order!=m or not (1 << (m//2))<n or not 2<=delta<=maximum:
        raise ValueError('source Theorems3/10/19 hypotheses fail')
    defining=set()
    for j in range(1,delta):
        for e in range(m):defining.add(j*(1 << e)%n)
    if defining&{(-i)%n for i in defining}:
        raise ValueError('source defining set meets its negative; not dual-containing')
    if len(defining)!=m*(delta//2):raise ValueError('source defining-set dimension formula fails')
    return dict(order_n_2=order,delta_max=maximum,defining_set=sorted(defining),
                source_lower=delta,source_dual_lower=maximum+1,
                defining_negative_disjoint=True)


def components(rows,n):
    bb=basis(rows)
    for p in sorted(bb):
        for q in bb:
            if q>p and ((bb[q] >> p)&1):bb[q]^=bb[p]
    parents=list(range(n))
    def find(i):
        while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
        return i
    for row in bb.values():
        support=[j for j in range(n) if (row >> j)&1]
        for j in support[1:]:parents[find(j)]=find(support[0])
    counts={}
    for i in range(n):p=find(i);counts[p]=counts.get(p,0)+1
    return sorted(counts.values())


def audit_case(case,directory):
    stem=f'BCH_{case["n"]}_{case["k"]}_unknown'
    n,matrices=read_code(directory,stem);hx,hz,gx,gz=matrices
    expected,root_rows,g=reconstruct(case)
    if hx!=expected or hz!=expected:raise ValueError('actual physical dual-polynomial entries differ')
    result=validate(n,matrices)
    if result['k']!=case['k'] or len(root_rows)==0:raise ValueError('reference k mismatch')
    hypotheses=source_hypotheses(case)
    if result['rank_Hx']!=len(hypotheses['defining_set']):raise ValueError('source rank differs from actual rank')
    if not equal_space(hx,root_rows) or not equal_space(hz,root_rows):raise ValueError('root rowspace mismatch')
    parts=components(hx,n)
    if parts!=[n]:raise ValueError('disconnected canonical physical stabilizer support; retain and review')
    words=[]
    for half,logical in (('Z',gx),('X',gz)):
        word=min(logical,key=lambda w:bin(w).count('1'))
        support=[i for i in range(n) if (word >> i)&1]
        verify_witness(n,matrices,half,support)
        if len(support)<case['published_lower']:raise ValueError('actual word contradicts source lower')
        words.append(dict(half=half,weight=len(support),support=support,origin='actual logical basis'))
    if case['anchor_support'] is not None:
        for half in ('X','Z'):
            verify_witness(n,matrices,half,case['anchor_support'])
            words.append(dict(half=half,weight=len(case['anchor_support']),support=case['anchor_support'],origin='explicit cyclic subgroup construction'))
        if len(case['anchor_support'])!=case['published_exact'] or hypotheses['source_dual_lower']<=case['published_exact']:
            raise ValueError('anchor word/purity/exact source mismatch')
    weights=sorted({bin(row).count('1') for row in hx})
    return dict(id=case['id'],stem=stem,**result,hypotheses=hypotheses,
                root_derived_generator=g,physical_entries_and_root_rowspaces='PASS',
                identity_XZ_map='PASS identical actual Hx/Hz and complete logical quotients',
                components=parts,check_row_weight_range=[weights[0],weights[-1]],
                classification='dense binary CSS BCH; no LDPC/asymptotic claim',
                published_exact=case['published_exact'],actual_words=words,
                actual_basis_uppers_GxGz=[w['weight'] for w in words[:2]],
                actual_verified_upper=min(w['weight'] for w in words))


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--out',type=Path)
    a=ap.parse_args();results=[audit_case(case,a.dir) for case in CASES]
    text=json.dumps(results,indent=2)+'\n'
    if a.out:a.out.write_text(text)
    else:print(text,end='')


if __name__=='__main__':main()
