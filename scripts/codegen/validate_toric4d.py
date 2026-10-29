#!/usr/bin/env python3
"""Independent column-boundaries and disjoint homologous-detector certificate.

No generator/logical-builder imports or distance search. GPL-3.0-or-later.
"""
import argparse
from itertools import combinations,product
import json
import math
from pathlib import Path
from validate_css import basis,contains,dot,read_code,validate
from verify_css_witness import verify_witness


def grid(shape):
    if len(shape)!=4 or any(type(L)!=int or L<2 for L in shape):raise ValueError('invalid4-torus sides')
    V=math.prod(shape);points=[]
    for label in range(V):
        coords=[0]*4;t=label
        for a in range(3,-1,-1):coords[a]=t%shape[a];t//=shape[a]
        points.append(tuple(coords))
    return points


def label(x,shape):
    t=0
    for a,L in enumerate(shape):t=t*L+x[a]%L
    return t


def reconstruct(shape):
    points=grid(shape);V=len(points);pairs=list(combinations(range(4),2));triples=list(combinations(range(4),3))
    hx=[0]*(4*V);hz=[0]*(4*V)
    for block,(a,b) in enumerate(pairs):
        for t,x in enumerate(points):
            q=block*V+t
            # Boundary of one physical face gives its four incident edge rows.
            for direction,step in ((a,None),(a,b),(b,None),(b,a)):
                y=list(x)
                if step is not None:y[step]+=1
                hx[direction*V+label(y,shape)]^=1<<q
            # Pull back to the four cubes containing this face.
            for c in range(4):
                if c in (a,b):continue
                cube=triples.index(tuple(sorted((a,b,c))))
                for shift in (0,-1):
                    y=list(x);y[c]+=shift;hz[cube*V+label(y,shape)]^=1<<q
    return hx,hz


def detector_families(shape):
    points=grid(shape);V=len(points);fibers=[];planes=[]
    for block,pair in enumerate(combinations(range(4),2)):
        complement=tuple(a for a in range(4) if a not in pair)
        kinds=[]
        for fixed in (pair,complement):
            rows=[]
            for values in product(*(range(shape[a]) for a in fixed)):
                rows.append(sum(1<<(block*V+t) for t,x in enumerate(points) if all(x[a]==value for a,value in zip(fixed,values))))
            kinds.append(rows)
        fibers.append(kinds[0]);planes.append(kinds[1])
    return fibers,planes


def packing_certificate(n,parity,stabilizer,logical,families):
    """Inputs are validated CSS quotient bases; check a lower bound directly.

    Each family is pairwise disjoint and equal modulo parity row space.
    Full pairing rank makes at least one family detect every nontrivial word.
    """
    k=len(logical);pivots=basis(parity);refs=[];counts=[]
    if n-len(pivots)-len(basis(stabilizer))!=k:raise ValueError('certificate quotient dimension mismatch')
    if len(families)!=k:raise ValueError('incomplete detector family count')
    for family in families:
        if not family:raise ValueError('empty detector family')
        reference=family[0];union=0
        if any(dot(reference,r) for r in stabilizer):raise ValueError('reference detector has syndrome')
        for word in family:
            if word<=0 or word>>n:raise ValueError('detector outside physical columns')
            if union&word:raise ValueError('detector supports not disjoint')
            union|=word
            if not contains(pivots,word^reference):raise ValueError('detectors not homologous in actual check space')
        refs.append(reference);counts.append(len(family))
    pairing=[sum(dot(row,v)<<j for j,v in enumerate(logical)) for row in refs]
    if len(basis(pairing))!=k:raise ValueError('detectors do not cover the full logical quotient')
    return dict(lower_bound=min(counts),family_counts=counts,pairing_rank=k,pairing_rows=pairing,
                disjoint=True,homologous_mod_actual_checks=True,
                families=[[[q for q in range(n) if (word>>q)&1] for word in family] for family in families])


def dual_map(shape):
    points=grid(shape);V=len(points);pairs=list(combinations(range(4),2));order=[]
    for pair in pairs:
        complement=tuple(a for a in range(4) if a not in pair)
        block=pairs.index(complement)
        for x in points:
            y=list(x)
            for a in complement:y[a]-=1
            order.append(block*V+label(y,shape))
    if len(set(order))!=6*V:raise ValueError('dual map not a permutation')
    return order


def permute(word,order):return sum(((word>>q)&1)<<j for q,j in enumerate(order))


def connected(n,rows):
    parent=list(range(n))
    def root(x):
        while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
        return x
    for row in rows:
        support=[q for q in range(n) if (row>>q)&1]
        for q in support[1:]:parent[root(q)]=root(support[0])
    return len({root(q) for q in range(n)})==1


def certify(c,n,matrices):
    shape=c['shape'];V=math.prod(shape);hx,hz,gx,gz=matrices
    if (hx,hz)!=reconstruct(shape):raise ValueError('matrix differs from independent physical face columns')
    result=validate(n,matrices)
    if n!=6*V or n!=c['n'] or result['k']!=6 or c['k']!=6 or result['rank_Hx']!=3*V-3 or result['rank_Hz']!=3*V-3:
        raise ValueError('4D torus dimension/rank mismatch')
    if len(hx)!=4*V or len(hz)!=4*V or len(set(hx))!=4*V or len(set(hz))!=4*V:
        raise ValueError('cell inventory or duplicate rows')
    if any(bin(row).count('1')!=6 for row in hx+hz):raise ValueError('checks not weight6')
    if any(sum((r>>q)&1 for r in rows)!=4 for rows in (hx,hz) for q in range(n)):
        raise ValueError('face column degree not4')
    if not connected(n,hx) or not connected(n,hz):raise ValueError('disconnected quantum graph')
    dual=dual_map(shape)
    if {permute(row,dual) for row in hx}!=set(hz) or {permute(row,dual) for row in hz}!=set(hx):
        raise ValueError('explicit weight-preserving duality failed')
    points=grid(shape)
    for axis in range(4):
        order=[]
        for block in range(6):
            for x in points:
                y=list(x);y[axis]+=1;order.append(block*V+label(y,shape))
        if any({permute(row,order) for row in rows}!=set(rows) for rows in (hx,hz)):
            raise ValueError('axis translation not an automorphism')
    fibers,planes=detector_families(shape)
    zproof=packing_certificate(n,hx,hz,gx,fibers);xproof=packing_certificate(n,hz,hx,gz,planes)
    d=min(shape[a]*shape[b] for a,b in combinations(range(4),2))
    if zproof['lower_bound']!=d or xproof['lower_bound']!=d or c['d']!=d:raise ValueError('derived distance formula mismatch')
    # Primal planes are Z words; dual fibers are X words. They intersect once
    # in matched orientations and vanish in different orientation blocks.
    p=[f[0] for f in planes];f=[g[0] for g in fibers]
    if [[dot(a,b) for b in f] for a in p]!=[[int(i==j) for j in range(6)] for i in range(6)]:
        raise ValueError('canonical membrane pairing not identity')
    witnesses=[]
    for half,rows in (('Z',p),('X',f)):
        word=min(rows,key=lambda r:(bin(r).count('1'),r));support=[q for q in range(n) if (word>>q)&1]
        verify_witness(n,matrices,half,support)
        if len(support)!=d:raise ValueError('minimum-area word weight mismatch')
        witnesses.append(dict(half=half,support=support,weight=len(support)))
    result.update(stem=f'TOR_{n}_6_unknown',shape=shape,claim=c['claim'],claimed_d=c['d'],derived_exact_d=d,
                  lower_certificates=dict(X=xproof,Z=zproof),witnesses=witnesses,
                  row_weight=6,column_weight=4,connected_both_halves=True,dual_map_verified=True,
                  axis_translations_verified=4,canonical_membrane_pairing_rank=6,
                  scientific_status='INDEPENDENT_COLUMNS_AND_FULL_GF2_FIBER_CERTIFICATE')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('toric4d_cases.json'))
    ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text()):
        n,m=read_code(args.dir,f'TOR_{c["n"]}_6_unknown');results.append(certify(c,n,m))
    text=json.dumps(results,indent=2)+'\n';args.output.write_text(text);print(text,end='')


if __name__=='__main__':main()
