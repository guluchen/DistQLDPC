#!/usr/bin/env python3
"""Independent graph-cycle and quantum-witness certificates for GH-154 inputs."""
from collections import deque
import argparse
import json
from pathlib import Path

import hgp_cycle as construction
import validate_css as css


def shortest_cycle(vertices, edges):
    adjacency = [[] for _ in range(vertices)]
    index = {edge:i for i,edge in enumerate(edges)}
    for a,b in edges:
        adjacency[a].append(b); adjacency[b].append(a)
    best = None
    for a,b in edges:
        parent = {a:None}; q = deque([a])
        while q and b not in parent:
            x = q.popleft()
            for y in adjacency[x]:
                if (x,y) in ((a,b),(b,a)) or y in parent:
                    continue
                parent[y] = x
                q.append(y)
        if b not in parent:
            continue
        support = [index[(a,b)]]
        x = b
        while parent[x] is not None:
            y = parent[x]
            support.append(index[tuple(sorted((x,y)))])
            x = y
        support.sort()
        if best is None or (len(support),support)<(len(best),best):
            best = support
    if best is None:
        raise ValueError('graph has no cycle')
    return best


def verify_one(name, directory):
    v,edges = construction.graph(name)
    e = len(edges)
    cycle = shortest_cycle(v,edges)
    d = len(cycle)
    if d != construction.EXPECTED[name][2]:
        raise ValueError('girth differs from expected source parameters')
    n, k = e*e+(v-1)**2, (e-v+1)**2
    stem = f'HGP_{n}_{k}_unknown'
    actual_n,(hx,hz,gx,gz) = css.read_code(directory,stem)
    if actual_n != n:
        raise ValueError('unexpected quantum matrix width')
    j = cycle[0]
    supports = {'Z':[i*e+j for i in cycle], 'X':[j*e+i for i in cycle]}
    words = {half:sum(1<<i for i in supp) for half,supp in supports.items()}
    for half,parity,stab,detector in (('Z',hx,hz,gz),('X',hz,hx,gx)):
        word = words[half]
        if any(css.dot(word,h) for h in parity):
            raise ValueError('witness not in kernel')
        if css.contains(css.basis(stab),word):
            raise ValueError('witness is a stabilizer')
        if not any(css.dot(word,g) for g in detector):
            raise ValueError('logical detector missed witness')
    if css.dot(words['X'],words['Z']) != 1:
        raise ValueError('witness pair has even overlap')
    return dict(stem=stem,graph=name,vertices=v,edges=e,n=n,k=k,
                girth=d,classical_cycle_support=cycle,quantum_supports=supports,
                quantum_witness_weights={'X':d,'Z':d},
                checks='PASS zero syndromes, non-stabilizer membership, logical detectors, odd pairing')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--output',type=Path,required=True)
    args = ap.parse_args()
    reports = [verify_one(name,args.dir) for name in construction.LADDER]
    text = json.dumps(reports,indent=2)+'\n'
    args.output.write_text(text)
    print(text,end='')


if __name__ == '__main__':
    main()
