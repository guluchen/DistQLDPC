#!/usr/bin/env python3
"""Independent dense Kronecker-shift reconstruction, no generator imports."""
import argparse
import json
from itertools import combinations
from pathlib import Path
from validate_css import read_code,validate,load,basis,contains

ROOT=Path(__file__).resolve().parents[2]


def shift(length,exponent):
    # A one-dimensional permutation matrix, independently exponentiated.
    perm=list(range(1,length))+[0]
    power=list(range(length))
    for _ in range(exponent%length):power=[perm[i] for i in power]
    return [[int(j==power[i]) for j in range(length)] for i in range(length)]


def reconstruct(case):
    l,m=case['l'],case['m'];v=l*m
    blocks=[]
    for polynomial in (case['A'],case['B']):
        block=[[0]*v for _ in range(v)]
        for a,b in polynomial:
            sx,sy=shift(l,a),shift(m,b)
            for i in range(l):
                for j in range(l):
                    if not sx[i][j]:continue
                    for r in range(m):
                        for s in range(m):block[i*m+r][j*m+s] ^= sy[r][s]
        blocks.append(block)
    a,b=blocks
    hx=[sum(bit << j for j,bit in enumerate(a[i]+b[i])) for i in range(v)]
    hz=[sum(bit << j for j,bit in enumerate([b[t][i] for t in range(v)]+[a[t][i] for t in range(v)])) for i in range(v)]
    return hx,hz


def parity_profile(rows):
    # A row space contains an odd word iff at least one spanning row is odd.
    return any(bin(r).count('1')%2 for r in rows)


def logical_up_to_four(n,parity,stabilizers):
    """Exhaust all supports <=4 via pairs of supports <=2, without a solver.

    Every word of weight <=4 splits into two subsets of size <=2. The two
    subsets have the same syndrome iff their symmetric difference is closed.
    The stabilizer membership test excludes degenerate zero-syndrome words.
    """
    columns=[sum(((r >> q)&1) << j for j,r in enumerate(parity)) for q in range(n)]
    span=basis(stabilizers);buckets={0:[0]}
    for size in (1,2):
        for support in combinations(range(n),size):
            mask=syndrome=0
            for q in support:mask ^= 1 << q;syndrome ^= columns[q]
            for previous in buckets.get(syndrome,[]):
                word=mask ^ previous
                if word and not contains(span,word):return word
            buckets.setdefault(syndrome,[]).append(mask)
    return None


def certify(case,directory):
    stem=f'BB_{case["n"]}_{case["k"]}_unknown'
    n,matrices=read_code(directory,stem)
    if tuple(matrices[:2])!=reconstruct(case):raise ValueError('Kronecker incidence mismatch')
    result=validate(n,matrices)
    if (n,result['k'])!=(case['n'],case['k']):raise ValueError('dimension mismatch')
    peers=[]
    entries=sorted((ROOT/'data/matrices').glob('tier[0-5]/*_Hx.txt'))+sorted(directory.glob('*_Hx.txt'))
    for p in entries:
        if p.resolve()==(directory/f'{stem}_Hx.txt').resolve():continue
        if p.name.split('_')[1:3]!=[str(n),str(case['k'])]:continue
        _,x=load(p);_,z=load(p.with_name(p.name.replace('_Hx.txt','_Hz.txt')))
        ours=sorted(map(parity_profile,matrices[:2]));theirs=sorted(map(parity_profile,(x,z)))
        evidence={'path':str(p.relative_to(ROOT)),
                  'our_odd_row_space_profile':ours,'peer_odd_row_space_profile':theirs}
        if ours==theirs:
            own_short=[logical_up_to_four(n,a,b) for a,b in (matrices[:2],matrices[1::-1])]
            peer_short=[logical_up_to_four(n,a,b) for a,b in ((x,z),(z,x))]
            if any(w is not None for w in own_short) or all(w is None for w in peer_short):
                raise ValueError(f'same-(n,k) permutation equivalence unresolved: {p}')
            evidence.update(our_both_half_distance_lower_bound=5,
                            peer_logical_supports=[[q for q in range(n) if (w >> q)&1]
                                                   if w is not None else None for w in peer_short])
        evidence['verdict']='INEQUIVALENT_UNDER_ANY_COLUMN_PERMUTATION_AND_XZ_SWAP'
        peers.append(evidence)
    return dict(stem=stem,**result,kronecker_incidence='PASS',
                same_n_k_permutation_invariants=peers)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--output',type=Path)
    args=ap.parse_args()
    cases=json.loads(Path(__file__).with_name('weight8_bb_cases.json').read_text())
    content=json.dumps([certify(c,args.dir) for c in cases],indent=2)+'\n'
    if args.output:args.output.write_text(content)
    print(content,end='')


if __name__=='__main__':main()
