#!/usr/bin/env python3
"""Independent physical incidence and finite Theorem9 hypothesis audit (GPL3+).

No constructor, logical builder, solver or external algebra package imported.
Classical complete kernel enumeration is limited to tiny dimension <=12.
"""
import argparse
import json
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).parent))
from validate_css import basis, contains, dot, load, read_code, validate

ROOT = Path(__file__).resolve().parents[2]
CASES = json.loads(Path(__file__).with_name('hyperbicycle_cases.json').read_text())


def independent_checks(case):
    """Enumerate each original cyclic incidence, including boundary carries."""
    a,b,c = case['n1'],case['n2'],case['c']
    if case['chi'] != 1:
        raise ValueError('chi1 audit only')
    v = a*b*c
    hx,hz = [0]*v,[0]*v
    def ix(t,s,u):
        return (t*c+s)*a+u
    for t in range(b):
        for s in range(c):
            for u in range(a):
                r=ix(t,s,u)
                for e in case['h1']:
                    carry,col = divmod(u+e,a)
                    hx[r] ^= 1 << ix(t,(s+carry)%c,col)
                    # The transpose incidence goes from an original column
                    # to all rows which hit that column, retaining its carry.
                    row=(u-e)%a
                    shift=(row+e)//a
                    hz[r] ^= 1 << (v+ix(t,(s-shift)%c,row))
                for e in case['h2']:
                    carry,col = divmod(t+e,b)
                    hx[r] ^= 1 << (v+ix(col,(s+carry)%c,u))
                    row=(t-e)%b
                    shift=(row+e)//b
                    hz[r] ^= 1 << ix(row,(s-shift)%c,u)
    return 2*v,hx,hz


def set_kernel(rows, n):
    """Scalar set Gauss-Jordan, independent of packed logical generation."""
    mat=[{i for i in range(n) if (row >> i)&1} for row in rows]
    lead=[]
    for col in range(n):
        p=next((j for j in range(len(lead),len(mat)) if col in mat[j]),None)
        if p is None:
            continue
        k=len(lead)
        mat[k],mat[p]=mat[p],mat[k]
        for j in range(len(mat)):
            if j!=k and col in mat[j]:
                mat[j] ^= mat[k]
        lead.append(col)
    free=[j for j in range(n) if j not in lead]
    result=[]
    for j in free:
        support={j}
        support.update(p for p,row in zip(lead,mat) if j in row)
        result.append(sum(1 << p for p in support))
    return result


def words(generators):
    if not generators or len(generators)>12:
        raise ValueError('classical complete enumeration requires dimension1..12')
    result=[0]
    for g in generators:
        result += [w^g for w in result]
    if len(set(result))!=len(result):
        raise ValueError('dependent classical kernel basis')
    return result[1:]


def classical(n,c,h):
    length=n*c
    rows=[sum(1 << ((r+e)%length) for e in h) for r in range(length)]
    transposed=[sum(((r >> j)&1) << i for i,r in enumerate(rows)) for j in range(length)]
    summaries=[]
    for matrix in (rows,transposed):
        ker=set_kernel(matrix,length)
        all_words=words(ker)
        if any(dot(r,w) for r in matrix for w in all_words):
            raise ValueError('classical kernel equation failed')
        if len(ker)!=length-len(basis(matrix)) or len(ker)!=max(h):
            raise ValueError('classical dimension mismatch')
        mask=(1 << n)-1
        if any(any(((w >> (i*n))&mask)!=(w&mask) for i in range(c)) for w in all_words):
            raise ValueError('kernel does not have the complete repeated symmetry')
        summaries.append({'dimension':len(ker),'complete_nonzero_words':len(all_words),
                          'distance':min(bin(w).count('1') for w in all_words)})
    # Sum_j a_j is exactly the small circulant. Its rowspace and transpose
    # must exclude every weight-one word (Theorem9 hypothesis, not distance search).
    small=[sum(1 << ((r+e)%n) for e in h) for r in range(n)]
    smallt=[sum(((r >> j)&1) << i for i,r in enumerate(small)) for j in range(n)]
    if any(contains(basis(m),1 << j) for m in (small,smallt) for j in range(n)):
        raise ValueError('weight-one word in the required classical generator space')
    if any(x['distance']%c for x in summaries):
        raise ValueError('nonintegral repeated classical distance')
    return {'n':n,'c':c,'original_and_transpose':summaries,
            'small_distance':summaries[0]['distance']//c,
            'full_repeated_kernel':True,'sum_block_and_transpose_minimum_at_least2':True}


def components(hx,hz,n):
    # Unique reduced bases eliminate fake couplings from redundant generators.
    def reduced(rows):
        bb=basis(rows)
        for p in sorted(bb):
            for q in bb:
                if q>p and ((bb[q] >> p)&1):
                    bb[q] ^= bb[p]
        return list(bb.values())
    parents=list(range(n))
    def find(x):
        while parents[x]!=x:
            parents[x]=parents[parents[x]]
            x=parents[x]
        return x
    for row in reduced(hx)+reduced(hz):
        support=[i for i in range(n) if (row >> i)&1]
        if support:
            for i in support[1:]:
                parents[find(i)]=find(support[0])
    sizes={}
    for i in range(n):
        p=find(i)
        sizes[p]=sizes.get(p,0)+1
    return sorted(sizes.values())


def audit_case(case,directory):
    stem=f'LP_{case["n"]}_{case["k"]}_unknown'
    n,matrices=read_code(directory,stem)
    nn,hx,hz=independent_checks(case)
    if n!=nn or matrices[:2]!=[hx,hz]:
        raise ValueError('physical stabilizer entry mismatch')
    result=validate(n,matrices)
    if result['k']!=case['k']:
        raise ValueError('reference k mismatch')
    factors=[classical(case['n1'],case['c'],case['h1']),
             classical(case['n2'],case['c'],case['h2'])]
    if case['c']%2 or case['chi']!=1:
        raise ValueError('Theorem9 requires the frozen even-c specialization')
    dims=[x['original_and_transpose'][0]['dimension'] for x in factors]
    d=min(x['distance'] for f in factors for x in f['original_and_transpose'])
    construction=[2*d//case['c'],d]
    if 2*d%case['c'] or 2*dims[0]*dims[1]!=result['k']:
        raise ValueError('Theorem9 dimension/integer-bound hypothesis mismatch')
    if construction!=case['conditional_construction_interval']:
        raise ValueError('frozen construction interval mismatch')
    parts=components(hx,hz,n)
    if parts!=[n]:
        raise ValueError('disconnected physical stabilizer space; retain and review')
    actual=[]
    for parity,stabilizer,logical in ((hx,hz,matrices[2]),(hz,hx,matrices[3])):
        word=min(logical,key=lambda w:bin(w).count('1'))
        if not word or any(dot(word,r) for r in parity) or contains(basis(stabilizer),word):
            raise ValueError('invalid logical word')
        weight=bin(word).count('1')
        if weight<construction[0]:
            raise ValueError('actual word contradicts construction lower bound')
        actual.append({'weight':weight,'support':[i for i in range(n) if (word >> i)&1]})
    return dict(id=case['id'],stem=stem,**result,factors=factors,
                theorem9_interval=construction,source_exact=case['reference_exact'],
                construction_bound_status='hypotheses independently checked; no new search-certified bound',
                components=parts,actual_basis_words_GxGz=actual,
                logical_note='Gx is Z-type; Gz is X-type; actual basis words are not minima')


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--out',type=Path)
    args=ap.parse_args()
    results=[audit_case(case,args.dir) for case in CASES]
    text=json.dumps({'construction':'arXiv1212.6703v2 Eq19/Theorem9','cases':results},indent=2)+'\n'
    if args.out:
        args.out.write_text(text)
    else:
        print(text,end='')


if __name__=='__main__':
    main()
