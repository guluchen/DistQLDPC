#!/usr/bin/env python3
"""Deterministic GF2 nullspace-column invariants for typed rowspace equivalence.

Counts weight1..3 STABILIZER rows via exact matroid column relations; no
quantum logical-distance search, solver, stochastic trials or timing claim.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
from validate_css import basis,dot,equal_space,read_code,validate

ROOT=Path(__file__).resolve().parents[2]
PEER_COMMIT='2cb22f295d161e9a2d29f58df1672c8c2799d732'


def invariant(n,rows):
    p=basis(rows)
    for i in sorted(p):
        for j in p:
            if j>i and (p[j]>>i)&1:p[j]^=p[i]
    K=[(1<<j)|sum(((w>>j)&1)<<i for i,w in p.items()) for j in range(n) if j not in p]
    if len(K)!=n-len(p) or any(dot(k,w) for k in K for w in rows):raise ValueError('incorrect orthogonal complement')
    sig=[sum(((w>>q)&1)<<j for j,w in enumerate(K)) for q in range(n)];counts=Counter(sig)
    one=counts[0];two=sum(v*(v-1)//2 for v in counts.values());three=0;suffix=Counter(sig)
    for j in range(n):
        suffix[sig[j]]-=1
        for i in range(j):three+=suffix[sig[i]^sig[j]]
    return [one,two,three]


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--out',type=Path,required=True);a=ap.parse_args()
    n,m=read_code(a.matrices,'TILE_288_8_unknown');own=validate(n,m)
    with tempfile.TemporaryDirectory() as d:
        d=Path(d);hashes={}
        for kind in ['Hx','Hz','Gx','Gz']:
            path=f'data/matrices/untiered/TN_288_8_unknown_{kind}.txt';raw=subprocess.check_output(['git','show',PEER_COMMIT+':'+path]);(d/Path(path).name).write_bytes(raw);hashes[kind]=hashlib.sha256(raw).hexdigest()
        nn,peer=read_code(d,'TN_288_8_unknown');other=validate(nn,peer)
        if (n,own['k'])!=(nn,other['k']):raise ValueError('peer dimensions disagree')
        direct=equal_space(m[0],peer[0]) and equal_space(m[1],peer[1]);swapped=equal_space(m[0],peer[1]) and equal_space(m[1],peer[0])
        left=[invariant(n,r) for r in m[:2]];right=[invariant(n,r) for r in peer[:2]]
        if direct or swapped or sorted(left)==sorted(right):raise ValueError('duplicate or unresolved column equivalence; do not accept a second copy')
        out=dict(stem='TILE_288_8_unknown',peer='TN_288_8_unknown',peer_commit=PEER_COMMIT,peer_sha256=hashes,direct_rowspace=direct,swapped_rowspace=swapped,
            invariant='exact full-typed-stabilizer-rowspace weight1/2/3 counts via orthogonal-complement column signatures',tile_XZ=left,peer_XZ=right,
            status='PROVED_INEQUIVALENT_UNDER_COLUMN_PERMUTATION_AND_GLOBAL_XZ_SWAP',logical_distance_search=False,used_provisional_peer_lower=False)
    a.out.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))


if __name__=='__main__':main()
