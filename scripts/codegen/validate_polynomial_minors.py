#!/usr/bin/env python3
"""Independent literal-incidence/convolution/Smith/logical minor-CSS checks.

No constructor, logical-builder or solver import. Polynomial arithmetic uses
coefficient lists, physical entries use explicit row/column displacement.
"""
import argparse
from itertools import zip_longest,combinations
import hashlib
import json
from pathlib import Path
from validate_css import read_code,validate,basis,equal_space,dot
from verify_css_witness import verify_witness

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('polynomial_minors_cases.json').read_text())


def require(ok,message):
    if not ok:raise ValueError(message)


def trim(a):
    a=a.copy()
    while a and not a[-1]:a.pop()
    return a


def xor(a,b):return trim([x^y for x,y in zip_longest(a,b,fillvalue=0)])


def polynomial(support,n):
    out=[0]*n
    for i in support:
        require(type(i) is int and i>=0,'invalid coefficient exponent');out[i%n]^=1
    return trim(out)


def multiply(a,b):
    if not a or not b:return []
    out=[0]*(len(a)+len(b)-1)
    for i,x in enumerate(a):
        if x:
            for j,y in enumerate(b):
                if y:out[i+j]^=1
    return trim(out)


def divide(a,b):
    require(bool(b),'zero polynomial divisor');r=trim(a);q=[0]*max(0,len(r)-len(b)+1)
    while len(r)>=len(b):
        shift=len(r)-len(b);q[shift]^=1
        for j,bit in enumerate(b):r[j+shift]^=bit
        r=trim(r)
    return trim(q),r


def gcd(*values):
    result=[]
    for v in values:
        v=trim(v)
        while v:result,v=v,divide(result,v)[1]
    return result


def cyclic_product(a,b,n):
    out=[0]*n
    for i,x in enumerate(a):
        if x:
            for j,y in enumerate(b):
                if y:out[(i+j)%n]^=1
    return trim(out)


def bits(a):return sum(v << i for i,v in enumerate(a))


def source(case):
    n=case['lift'];require(type(n) is int and 1<n<=1000 and n%2==1,'odd lift range required')
    require(case.get('t',0)==0 and case.get('q',[0])==[0],'wrong frozen specialization')
    a,b,c=[polynomial(case[k],n) for k in ('a','b','c')]
    require(all((a,b,c)),'zero source polynomial')
    pairs=[(b,b,a,c),(a,b,c,c),(a,a,b,c)]
    raw=[xor(multiply(u,v),multiply(w,z)) for u,v,w,z in pairs]
    minors=[xor(cyclic_product(u,v,n),cyclic_product(w,z,n)) for u,v,w,z in pairs]
    require(any(minors),'all minors vanish')
    modulus=[1]+[0]*(n-1)+[1]
    gamma1=gcd(a,b,c);gamma2=gcd(*raw);quotient,rem=divide(gamma2,gamma1)
    require(not rem,'Smith divisor chain failed')
    d1=gcd(gamma1,modulus);d2=gcd(quotient,modulus);g1=gcd(*minors,modulus)
    rx=2*n-(len(d1)-1)-(len(d2)-1);rz=n-(len(g1)-1)
    k=3*n-rx-rz
    require(k==(len(d1)-1)+2*(len(g1)-1)==case['k']>0,'generic Smith/odd-lift/frozen dimension mismatch')
    for row in ([a,b,c],[c,a,b]):
        total=[]
        for p,m in zip(row,minors):total=xor(total,cyclic_product(p,m,n))
        require(not total,'Laplace syzygy failed')
    return [a,b,c],minors,dict(gamma1=bits(gamma1),gamma2=bits(gamma2),
        smith1_with_modulus=bits(d1),smith2_with_modulus=bits(d2),minor_gcd_with_modulus=bits(g1),
        predicted_rank_Hx=rx,predicted_rank_Hz=rz,predicted_k=k)


def reconstruct(case):
    n=case['lift'];p,minors,receipt=source(case);hx=[]
    for row in (p,[p[2],p[0],p[1]]):
        for i in range(n):
            # C(p^T)[i,u]=p[i-u]; C(minor)[i,u]=minor[u-i].
            hx.append(sum(1 << (j*n+(i-e)%n) for j,a in enumerate(row)
                          for e,bit in enumerate(a) if bit))
    hz=[sum(1 << (j*n+(i+e)%n) for j,m in enumerate(minors)
            for e,bit in enumerate(m) if bit) for i in range(n)]
    return hx,hz,receipt


def components(spaces,n):
    parents=list(range(n))
    def find(i):
        while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
        return i
    for rows in spaces:
        canonical=basis(rows)
        for p in sorted(canonical):
            for q in canonical:
                if q>p and (canonical[q] >> p)&1:canonical[q]^=canonical[p]
        for row in canonical.values():
            support=[]
            while row:
                bit=row&-row;support.append(bit.bit_length()-1);row^=bit
            for j in support[1:]:parents[find(j)]=find(support[0])
    sizes={}
    for i in range(n):p=find(i);sizes[p]=sizes.get(p,0)+1
    return sorted(sizes.values())


def audit_case(case,directory):
    stem=f'PM_{3*case["lift"]}_{case["k"]}_unknown';n,matrices=read_code(directory,stem)
    require(n==3*case['lift'],'wrong width');hx,hz,gx,gz=matrices
    xx,zz,receipt=reconstruct(case)
    require(hx==xx and hz==zz,'actual source polynomial/transpose/physical incidence mismatch')
    result=validate(n,matrices)
    require([result['rank_Hx'],result['rank_Hz']]==[receipt['predicted_rank_Hx'],receipt['predicted_rank_Hz']],
            'actual binary rank differs from independent Smith calculation')
    if 'source_ranks' in case:require([result['rank_Hx'],result['rank_Hz']]==case['source_ranks'],'published ranks differ')
    weights=[sorted({bin(r).count('1') for r in rows}) for rows in (hx,hz)]
    if 'source_weights' in case:require(weights==[[w] for w in case['source_weights']],'source row weights differ')
    words=[]
    # Bundled Gx lies in ker(Hx); it detects X words but represents a Z word.
    # Source X logicals lie in ker(Hz) outside Hx. Both halves are audited.
    for half,rows in [('X',gz),('Z',gx)]:
        for row in rows:
            support=[i for i in range(n) if (row >> i)&1]
            verify_witness(n,matrices,half,support)
            words.append(dict(half=half,weight=len(support),support=support,origin='actual logical basis'))
    if 'source_word' in case:
        word=case['source_word'];verify_witness(n,matrices,word['half'],word['support'])
        require(len(word['support'])==word['weight'],'source word weight differs')
        words.append(dict(word,origin='published Eq23/24 physical source word'))
    tiny_exact=None
    if n==27:
        # Deterministic tiny correctness reference only. Exhaust both halves
        # below4 and find the first physical weight4 logical. Never expands
        # the local distance search to any of the larger library targets.
        for weight in range(1,5):
            for half,parity,stabilizer in [('X',hz,hx),('Z',hx,hz)]:
                bb=basis(stabilizer)
                for support in combinations(range(n),weight):
                    word=sum(1 << i for i in support)
                    if any(dot(word,h) for h in parity):continue
                    reduced=word
                    while reduced and reduced.bit_length()-1 in bb:reduced^=bb[reduced.bit_length()-1]
                    if reduced:
                        require(weight==case['published_exact']==4,'tiny source anchor mismatch')
                        verify_witness(n,matrices,half,list(support))
                        words.append(dict(half=half,weight=weight,support=list(support),origin='tiny27 exhaustive physical supports below4, then first weight4 logical'))
                        tiny_exact=weight;break
                if tiny_exact is not None:break
            if tiny_exact is not None:break
        require(tiny_exact==4,'no physical tiny source word4')
    # A fixed constructive word, not a distance/parameter search. Dividing
    # the first polynomial syzygy row by its ordinary common factor preserves
    # the exact Laplace identity. A shared factor of X^N+1 makes the primitive
    # row nontrivial; verify this on the actual physical files rather than
    # relying only on the polynomial argument.
    polynomials,_,_=source(case);factor=gcd(*polynomials)
    modulus=[1]+[0]*(case['lift']-1)+[1]
    if len(gcd(factor,modulus))>1:
        quotients=[divide(p,factor) for p in polynomials]
        require(not any(rem for _,rem in quotients),'primitive source row division failed')
        support=sorted(j*case['lift']+(-i)%case['lift']
                       for j,(p,_) in enumerate(quotients) for i,bit in enumerate(p) if bit)
        verify_witness(n,matrices,'X',support)
        words.append(dict(half='X',weight=len(support),support=support,
            origin='first primitive row syzygy divided by ordinary entry gcd; physical reflection; GF2 verified'))
    if case.get('published_lower') is not None:
        require(all(w['weight']>=case['published_lower'] for w in words),'actual word contradicts published exact/lower')
    cc=components([hx,hz],n)
    require(cc==[n],'frozen candidate decomposes; retain/report, do not substitute another lift')
    result.update(id=case['id'],stem=stem,lift=case['lift'],smith=receipt,row_weights_Hx_Hz=weights,
        independent_tiny_anchor_exact=tiny_exact,
        canonical_support_components=cc,physical_XZ_dual_map='not assumed; unequal ranks obstruct pure permutation XZ',
        actual_words=words,actual_verified_half_uppers={h:min(w['weight'] for w in words if w['half']==h) for h in ('X','Z')},
        actual_verified_upper=min(w['weight'] for w in words),
        input_sha256={kind:hashlib.sha256((directory/(stem+'_'+kind+'.txt')).read_bytes()).hexdigest() for kind in ('Hx','Hz','Gx','Gz')})
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--out',type=Path,required=True)
    a=ap.parse_args();results=[audit_case(c,a.dir) for c in CASES]
    a.out.write_text(json.dumps(results,indent=2)+'\n')
    print(json.dumps([{k:v for k,v in r.items() if k not in ('actual_words','input_sha256','smith')} for r in results],indent=2))


if __name__=='__main__':main()
