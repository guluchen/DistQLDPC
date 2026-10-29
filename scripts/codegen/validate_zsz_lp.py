#!/usr/bin/env python3
"""Independent generator-permutation ZSZ-LP reconstruction, GPL-3.0-or-later.

No group-formula generator or logical-builder imports. Build elementary x/y
left/right permutations, apply powers in order, then assemble dense blocks.
"""
import argparse
import json
from pathlib import Path
from validate_css import read_code,validate,basis

ROOT=Path(__file__).resolve().parents[2]


def generators(case):
    a,b,q=case['l1'],case['l2'],case['q']
    if a<2 or b<2 or pow(q,b,a)!=1 or q%a==1:raise ValueError('nonabelian finite group required')
    points=[(i,j) for i in range(a) for j in range(b)];index={p:i for i,p in enumerate(points)}
    lx=[index[((i+1)%a,j)] for i,j in points]
    ly=[index[(q*i%a,(j+1)%b)] for i,j in points]
    rx=[index[((i+pow(q,j,a))%a,j)] for i,j in points]
    ry=[index[(i,(j+1)%b)] for i,j in points]
    for p in (lx,ly,rx,ry):
        if sorted(p)!=list(range(a*b)):raise ValueError('action not a permutation')
    if all(lx[ly[i]]==ly[lx[i]] for i in range(a*b)):raise ValueError('accidentally abelian action')
    for l in (lx,ly):
        for r in (rx,ry):
            if any(l[r[i]]!=r[l[i]] for i in range(a*b)):raise ValueError('left/right actions do not commute')
    return lx,ly,rx,ry


def polynomial(case,terms,left):
    l1,l2=case['l1'],case['l2'];size=l1*l2
    lx,ly,rx,ry=generators(case);matrix=[[0]*size for _ in range(size)]
    for a,b in terms:
        for col in range(size):
            row=col
            if left:
                for _ in range(b%l2):row=ly[row]
                for _ in range(a%l1):row=lx[row]
            else:
                for _ in range(a%l1):row=rx[row]
                for _ in range(b%l2):row=ry[row]
            matrix[row][col] ^= 1
    return matrix


def reconstruct(case):
    a,b=polynomial(case,case['a'],True),polynomial(case,case['b'],True)
    c,d=polynomial(case,case['c'],False),polynomial(case,case['dpoly'],False)
    size=len(a);zero=[0]*size
    trans=lambda m:[list(row) for row in zip(*m)]
    at,bt,ct,dt=map(trans,(a,b,c,d))
    hx=[a[i]+zero+b[i]+zero+ct[i] for i in range(size)]
    hx += [zero+a[i]+zero+b[i]+dt[i] for i in range(size)]
    hz=[c[i]+d[i]+zero+zero+at[i] for i in range(size)]
    hz += [zero+zero+c[i]+d[i]+bt[i] for i in range(size)]
    pack=lambda row:sum(bit << j for j,bit in enumerate(row))
    left=[pack(a[i]+b[i]) for i in range(size)];right=[pack(c[i]+d[i]) for i in range(size)]
    if len(basis(left))!=size or len(basis(right))!=size:raise ValueError('classical seed not full rank')
    return list(map(pack,hx)),list(map(pack,hz))


def certify(case,directory):
    stem=f'LP_{case["n"]}_{case["k"]}_unknown';n,m=read_code(directory,stem)
    if tuple(m[:2])!=reconstruct(case):raise ValueError('independent action/block incidence mismatch')
    result=validate(n,m)
    if (n,result['k'])!=(case['n'],case['k']) or n!=5*case['l1']*case['l2']:
        raise ValueError('published dimensions mismatch')
    if any(bin(row).count('1')!=9 for rows in m[:2] for row in rows):raise ValueError('row weight mismatch')
    columns=[sum((row >> q)&1 for row in m[0]) for q in range(n)]
    zcolumns=[sum((row >> q)&1 for row in m[1]) for q in range(n)]
    if set(columns)!={3,6} or set(zcolumns)!={3,6}:raise ValueError('qubit degree mismatch')
    return dict(stem=stem,**result,group_order=n//5,nonabelian=True,left_right_generator_commutation='PASS',
                classical_seed_ranks=[n//5,n//5],independent_permutation_incidence='PASS',
                check_row_weights=[9],qubit_degrees=sorted(set(columns)),published_claim=case['claim'],published_d=case['d'])


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--output',type=Path,required=True)
    args=ap.parse_args();cases=json.loads(Path(__file__).with_name('zsz_lp_cases.json').read_text())
    content=json.dumps([certify(c,args.dir) for c in cases],indent=2)+'\n';args.output.write_text(content);print(content,end='')


if __name__=='__main__':main()
