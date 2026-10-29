#!/usr/bin/env python3
"""Bounded static matrix/coordinate peer checks; no distance search or solver.

An unsuccessful finite map list does NOT prove arbitrary inequivalence.
"""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
import tempfile
from radial import generate
from validate_radial import certify
from validate_css import equal_space,read_code,validate

ROOT=Path(__file__).resolve().parents[2]


def compare(n,m,nn,peer,r,s):
    if n!=nn:return dict(same_nk=False)
    direct=equal_space(m[0],peer[0]) and equal_space(m[1],peer[1])
    swapped=equal_space(m[0],peer[1]) and equal_space(m[1],peer[0])
    tested=0;found=None;N=n//2
    for a,b,transpose,sign,halfswap in itertools.product(itertools.permutations(range(r)),itertools.permutations(range(r)),[False,True],[-1,1],[False,True]):
        p=[]
        for q in range(n):
            half,local=divmod(q,N);base,h=divmod(local,s);i,j=divmod(base,r)
            x,y=(b[j],a[i]) if transpose else (a[i],b[j])
            p.append((half^halfswap)*N+(x*r+y)*s+(sign*h)%s)
        require=len(set(p))==n
        if not require:raise ValueError('nonbijective candidate map')
        transformed=[[sum(((w>>q)&1)<<p[q] for q in range(n)) for w in rows] for rows in m[:2]];tested+=1
        for swap in [False,True]:
            if all(equal_space(transformed[i],peer[i^swap]) for i in [0,1]):found=dict(physical_permutation=p,swap=swap);break
        if found:break
    return dict(same_nk=True,direct_rowspace=direct,swapped_rowspace=swapped,coordinate_maps_tested=tested,verified_physical_map=found,
        arbitrary_column_equivalence='CONFIRMED_EQUIVALENT' if direct or swapped or found else 'UNRESOLVED_NOT_PROVED_INEQUIVALENT')


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args()
    c=json.loads((ROOT/'scripts/codegen/radial_peer_case.json').read_text())
    with tempfile.TemporaryDirectory() as d:
        d=Path(d);stem=generate(c,d);n,m=read_code(d,stem);certificate=certify(c,n,m)
        nn,peer=read_code(ROOT/'data/matrices/tier0','BB_90_8_10');assert validate(nn,peer)['k']==c['k'];result=compare(n,m,nn,peer,c['r'],c['s'])
        result.update(source_case=c,actual_construction=certificate,source_input_sha256={kind:hashlib.sha256((d/f'{stem}_{kind}.txt').read_bytes()).hexdigest() for kind in ['Hx','Hz','Gx','Gz']},peer='data/matrices/tier0/BB_90_8_10',benchmark_added=False,policy='No duplicate/suspected copy added; source90 is comparison-only, not rejected after distance screening')
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(result['arbitrary_column_equivalence'],result['coordinate_maps_tested'])


if __name__=='__main__':main()
