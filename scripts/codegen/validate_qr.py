#!/usr/bin/env python3
"""Independent physical incidence/polynomial/correlation QR certificate; no solver.

Uses Euler's criterion rather than squaring enumeration, set polynomial Euclid
rather than a circulant-rank construction, literal integer correlation and the
physical CSS kernel dimension. Imports neither generator nor logical builder.
"""
import argparse
import hashlib
import json
from pathlib import Path
from validate_css import read_code,validate,basis,equal_space,dot,contains
from verify_css_witness import verify_witness

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('qr_cases.json').read_text())


def require(ok,message):
    if not ok:raise ValueError(message)


def remainder(a,b):
    aa={i for i in range(a.bit_length()) if (a >> i)&1}
    bb={i for i in range(b.bit_length()) if (b >> i)&1}
    require(bool(bb),'zero polynomial divisor')
    while aa and max(aa)>=max(bb):
        shift=max(aa)-max(bb);aa.symmetric_difference_update({j+shift for j in bb})
    return sum(1 << i for i in aa)


def gcd(a,b):
    while b:a,b=b,remainder(a,b)
    return a


def correlation(support,n):
    counts=[0]*n
    for a in support:
        for b in support:counts[(a-b)%n]+=1
    return counts


def floor_bound(n):
    # Every nontrivial word is odd and congruent3 mod4; the off-diagonal
    # differences must cover all n-1 nonzero residues.
    return next(w for w in range(3,n+1,4) if w*(w-1)>=n-1)


def reconstruct(n):
    require(type(n) is int and 7<=n<=3000 and n%8==7
            and all(n%a for a in range(2,n)),'not a binary prime CSS QR length')
    q=[a for a in range(1,n) if pow(a,(n-1)//2,n)==1]
    require(len(q)==(n-1)//2 and 2 in q and n-1 not in q,'source residue hypotheses fail')
    support=[0]+q;e=sum(1 << i for i in support)
    require({2*i%n for i in support}==set(support),'not a cyclic binary idempotent')
    counts=correlation(support,n)
    require(not any(c%2 for c in counts),'cyclic cross-correlation is nonzero')
    require(len(support)%4==0,'cyclic generators are not doubly even')
    g=gcd(e,(1 << n)|1);degree=g.bit_length()-1;rank=n-degree
    require(rank==(n-1)//2,'polynomial ideal dimension mismatch')
    polynomial_basis=[g << i for i in range(rank)]
    # Independent least-pivot Gaussian selection preserves first physical
    # shifts while the constructor uses the greatest pivot.
    selected=[];shifts=[];low={}
    for shift in range(n):
        row=sum(1 << ((i+shift)%n) for i in support);reduced=row
        while reduced:
            pivot=(reduced&-reduced).bit_length()-1
            if pivot in low:reduced^=low[pivot]
            else:low[pivot]=reduced;selected.append(row);shifts.append(shift);break
    require(equal_space(polynomial_basis,selected),'cyclic incidence and polynomial ideal differ')
    return selected,dict(selected_shifts=shifts,idempotent_support=support,
        polynomial_generator=g,polynomial_degree=degree,rank=rank,
        integer_cyclic_correlation=counts,certificate_lower=floor_bound(n))


def physical_certificate(n,hx,hz):
    expected,proof=reconstruct(n)
    require(hx==expected and hz==expected,'stored physical QR row/coordinate/order mismatch')
    require(len(basis(hx))==(n-1)//2 and equal_space(hx,hz),'physical stabilizer dimension differs')
    require(all(bin(h).count('1')%4==0 for h in hx),'physical span not doubly even')
    require(not any(dot(a,b) for a in hx for b in hz),'CSS commutation differs')
    allones=(1 << n)-1
    require(all(not dot(allones,row) for row in hx),'odd detector outside kernel')
    require(not contains(basis(hx),allones),'odd detector is a stabilizer')
    # rank(H)=(n-1)/2 and H self-orthogonal with even rows imply
    # ker(H)=rowspace(H) direct-sum <allones>. Literal cyclic correlation
    # implies h*reverse(h')=0 for every pair of cyclic generators.
    # Thus v*reverse(v)=allones for every nontrivial v=allones+h.
    proof.update(physical_kernel_coset='rowspace(H) + allones',
                 every_logical_weight_mod4=3,all_odd_logical_autocorrelation='allones',
                 soundness='wt(v)*(wt(v)-1)>=n-1 from all nonzero difference coefficients',
                 search_bounds_unchanged=True)
    return proof


def audit_case(case,directory):
    stem=f'QR_{case["n"]}_1_unknown';n,matrices=read_code(directory,stem)
    require(n==case['n'] and case['k']==1,'frozen dimension differs')
    result=validate(n,matrices);hx,hz,gx,gz=matrices
    proof=physical_certificate(n,hx,hz)
    require(proof['certificate_lower']==case['published_lower'],'frozen source floor differs')
    words=[]
    for half,rows in [('X',gx),('Z',gz)]:
        for word in rows:
            support=[i for i in range(n) if (word >> i)&1]
            verify_witness(n,matrices,half,support)
            words.append(dict(half=half,weight=len(support),support=support,origin='actual logical basis'))
    # Small correctness control only: exhaust the actual 2048-element coset,
    # independently of either native search. No large-case distance search.
    exact=None
    if n==23:
        coset=[(1 << n)-1]
        for row in hx:coset += [w^row for w in coset]
        lightest=min(coset,key=lambda w:bin(w).count('1'))
        exact=bin(lightest).count('1')
        require(exact==case['published_exact']==7,'Golay source control mismatch')
        for half in ('X','Z'):
            support=[i for i in range(n) if (lightest >> i)&1]
            verify_witness(n,matrices,half,support)
            words.append(dict(half=half,weight=exact,support=support,origin='tiny2048coset independent exhaustive anchor'))
    require(all(w['weight']>=proof['certificate_lower'] and w['weight']%4==3 for w in words),
            'actual word contradicts physical lower/congruence proof')
    # A transitive prime cyclic code with full support is indecomposable:
    # components form equal-size imprimitivity blocks, so only1 or n; n
    # singleton components would give full coordinate space, contradicting rank.
    result.update(id=case['id'],stem=stem,certificate=proof,actual_words=words,
        tiny_anchor_independent_exact=exact,canonical_support_components=[n],
        connectedness_proof='prime transitive cyclic full-support code, nonzero proper rank excludes singletons',
        identity_physical_XZ=True,actual_verified_upper=min(w['weight'] for w in words),
        input_sha256={kind:hashlib.sha256((directory/(stem+'_'+kind+'.txt')).read_bytes()).hexdigest()
                      for kind in ('Hx','Hz','Gx','Gz')})
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--out',type=Path,required=True)
    a=ap.parse_args();out=[audit_case(c,a.dir) for c in CASES]
    a.out.write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps([{k:v for k,v in r.items() if k not in ('actual_words','certificate','input_sha256')}
                      for r in out],indent=2))


if __name__=='__main__':main()
