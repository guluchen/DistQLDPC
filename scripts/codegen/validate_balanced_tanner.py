#!/usr/bin/env python3
"""Independent graph/cell-orbit differential reconstruction for GH-160.

No generator or logical-builder import. Reconstruct full product-cell
boundaries and quotient their anti-diagonal orbits rather than using blocks.
"""
import argparse
from collections import Counter
import csv
import json
from pathlib import Path
from validate_css import basis,contains,dot,read_code,validate


def reconstruct(length,labels):
    v=4*length
    # Enumerate pairs directly; different from the generator's offset walk.
    edges=[(x,y) for x in range(v) for y in range(x+1,v)
           if min(y-x,v-(y-x)) in (1,2,3,v//2)]
    m=len(edges);r=3*v
    edge_index={e:i for i,e in enumerate(edges)}
    adjacency=[[] for _ in range(m)]
    for e,(x,y) in enumerate(edges):
        for p,q in ((x,y),(y,x)):
            delta=(q-p)%v
            offset_to_column={1:0,2:1,3:2,v//2:3,v-3:4,v-2:5,v-1:6}
            column=labels[p%4][offset_to_column[delta]]
            adjacency[e].extend(3*p+b for b in range(3) if (column >> b)&1)
    def edge_step(e):
        x,y=edges[e]
        return edge_index[tuple(sorted(((x+4)%v,(y+4)%v)))]
    def check_step(q):return ((q//3+4)%v)*3+q%3
    def orbit_lookup(size,step):
        lookup={}
        for cell in range(size):
            cur=cell
            for h in range(length):
                pair=(cur,(-h)%length)
                if pair in lookup:raise ValueError('non-free or overlapping cell orbits')
                lookup[pair]=cell
                cur=step(cur)
            if cur != cell:raise ValueError('deck order mismatch')
        return lookup
    eo=orbit_lookup(m,edge_step);co=orbit_lookup(r,check_step)
    hx=[0]*r;hz=[]
    for e in range(m):
        # Boundary of [edge,vertex_0].
        for q in adjacency[e]:hx[co[(q,0)]] ^= 1 << e
        # Boundary of [edge,edge_0] in the full product, then quotient.
        support=(1 << eo[(e,0)]) ^ (1 << eo[(e,1)])
        for q in adjacency[e]:support ^= 1 << (m+co[(q,0)])
        hz.append(support)
    for q in range(r):
        # Boundary of [check,edge_0], whose endpoints are vertex_0,vertex_1.
        for j in (0,1):hx[co[(q,j)]] ^= 1 << (m+q)
    a=[sum(1 << e for e,inc in enumerate(adjacency) if q in inc) for q in range(r)]
    return edges,a,hx,hz


def certify(length,labels,n,matrices):
    edges,a,hx,hz=reconstruct(length,labels)
    if (hx,hz) != tuple(matrices[:2]):raise ValueError('independent cell-orbit differential mismatch')
    result=validate(n,matrices)
    if n != 26*length or result['k'] != 2 or len(basis(a)) != 12*length:
        raise ValueError('full-CSS/factor dimension mismatch; no gauge removal permitted')
    if any(x%4 == y%4 for x,y in edges):raise ValueError('quotient condition violated')
    v=4*length;idx={e:i for i,e in enumerate(edges)}
    seen=set();witness=None
    for e in range(len(edges)):
        if e in seen:continue
        orbit=[];cur=e
        for _ in range(length):
            orbit.append(cur);x,y=edges[cur]
            cur=idx[tuple(sorted(((x+4)%v,(y+4)%v)))]
        if cur != e or len(set(orbit)) != length:raise ValueError('edge action not free')
        seen.update(orbit)
        word=sum(1 << q for q in orbit)
        if any(dot(word,row) for row in hz):raise ValueError('cycle support not in parity kernel')
        if witness is None and not contains(basis(hx),word):witness=sorted(orbit)
    if witness is None:raise ValueError('no nontrivial cycle witness')
    if not any(dot(sum(1 << q for q in witness),g) for g in matrices[2]):
        raise ValueError('cycle not detected by logical basis')
    result.update(stem=f'BP_{n}_2_unknown',length=length,
                  factor_bits=len(edges),factor_checks=len(a),factor_rank=len(basis(a)),
                  check_weights={'Hx':dict(sorted(Counter(bin(x).count('1') for x in hx).items())),
                                 'Hz':dict(sorted(Counter(bin(x).count('1') for x in hz).items()))},
                  verified_cycle_ub=length,cycle_witness={'half':'X','support':witness,'weight':length},
                  checks='PASS independent full product orbits, factor/full CSS rank and GF(2) cycle witness')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--output',type=Path,required=True)
    args=ap.parse_args();results=[]
    for row in csv.DictReader((args.dir/'MANIFEST.csv').open()):
        if row['family']!='BP':continue
        p=json.loads(row['construction']);n,m=read_code(args.dir,row['stem'])
        result=certify(p['length'],p['labels'],n,m)
        if row['claimed_d'].split()[:2] != ['<=',str(result['verified_cycle_ub'])]:
            raise ValueError('manifest bound lacks matching cycle certificate')
        results.append(result)
    if not results:raise ValueError('no BP instances')
    text=json.dumps(results,indent=2)+'\n';args.output.write_text(text);print(text,end='')


if __name__=='__main__':main()
