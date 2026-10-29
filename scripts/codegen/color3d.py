#!/usr/bin/env python3
"""Original static 3-colex CSS reconstruction, GPL-3.0-or-later (GH-185).

Mathematics: Bombin--Martin-Delgado cond-mat/0607736v3 SecII.B/III.B,
AppendixB. Cube anchor: Vasmer--Browne 1801.04255v2 Fig12.
No author code or matrix files copied. No distance screening/search.
"""
import argparse
from collections import defaultdict
import hashlib
import itertools
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('color3d_cases.json')


def digest(value):
    return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()


def residues(adj,colors):
    seen=set();out=[]
    for start in range(len(adj)):
        if start in seen:continue
        comp=[start];seen.add(start)
        for u in comp:
            for color in colors:
                v=adj[u][color]
                if v not in seen:seen.add(v);comp.append(v)
        out.append(sorted(comp))
    return out


def build(case):
    """Column order: original cube, cube corner, ordered axis permutation.

    Cell ID=(position index)*8+direction mask; this distinguishes wrapping
    parallel cells at period two. A flag contains one cell of each rank.
    Deleting a rank pairs the two incident flags across that colored facet.
    """
    if case['kind']=='rp3':
        adj=[[u^flip for flip in (1,2,4,7)] for u in range(8)]
        flags=[];positions=[]
        cell_keys=[];cells=[];face_keys=[];faces=[]
        for color in range(4):
            for vs in residues(adj,[i for i in range(4) if i!=color]):
                cell_keys.append([color,len(cell_keys)]);cells.append(vs)
        for colors in itertools.combinations(range(4),2):
            for vs in residues(adj,colors):face_keys.append(list(colors));faces.append(vs)
    elif case['kind']=='periodic-cube-flags':
        L=case['periods']
        if len(L)!=3 or any(type(x)!=int or x<2 for x in L):raise ValueError('periods must be three integers >=2')
        positions=list(itertools.product(*(range(l) for l in L)));pid={p:i for i,p in enumerate(positions)}
        flags=[]
        for p in positions:
            for corner in range(8):
                for axes in itertools.permutations(range(3)):
                    flag=[];mask=0
                    for rank in range(4):
                        start=tuple((p[j]+int(bool(corner&(1<<j)) and not bool(mask&(1<<j))))%L[j] for j in range(3))
                        flag.append(8*pid[start]+mask)
                        if rank<3:mask|=1<<axes[rank]
                    flags.append(flag)
        adj=[[-1]*4 for _ in flags]
        for rank in range(4):
            facets=defaultdict(list)
            for v,flag in enumerate(flags):facets[tuple(flag[:rank]+flag[rank+1:])].append(v)
            for vs in facets.values():
                if len(vs)!=2:raise ValueError('flag facet not two-sided')
                u,v=vs;adj[u][rank]=v;adj[v][rank]=u
        bycell=defaultdict(list);bypair=defaultdict(list)
        for v,flag in enumerate(flags):
            for cell in flag:bycell[cell].append(v)
            for pair in itertools.combinations(flag,2):bypair[pair].append(v)
        cell_keys=sorted(bycell);cells=[bycell[key] for key in cell_keys]
        face_keys=sorted(bypair);faces=[bypair[key] for key in face_keys]
    else:raise ValueError('unknown construction')
    cert=dict(case=case,parameter_sha256=digest(case),positions=positions,flags=flags,
              adjacency=adj,cell_keys=cell_keys,cells=cells,face_keys=face_keys,faces=faces)
    return cert


def generate(case,out,certificates):
    stem=f'COLOR_{case["n"]}_{case["k"]}_unknown'
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')) or (certificates/f'{stem}.json').exists():
        raise FileExistsError('refusing to overwrite matrices or certificate')
    cert=build(case);n=len(cert['adjacency'])
    if n!=case['n']:raise ValueError('actual qubit count mismatch')
    out.mkdir(parents=True,exist_ok=True);certificates.mkdir(parents=True,exist_ok=True)
    for kind,rows in [('Hx',cert['cells']),('Hz',cert['faces'])]:
        content=[f'# static 3D color/colex {case["id"]}; {kind}; cond-mat/0607736v3; original GH-185\n']
        for vs in rows:
            support=set(vs);content.append(' '.join('1' if v in support else '0' for v in range(n))+'\n')
        (out/f'{stem}_{kind}.txt').write_text(''.join(content))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    (certificates/f'{stem}.json').write_text(json.dumps(cert,indent=2)+'\n')
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--certificates',type=Path,required=True);args=ap.parse_args()
    cases=json.loads(CASES.read_text());selected=[c for c in cases if args.all or c['n']==args.n]
    if not selected:ap.error('unknown fixed size')
    for case in selected:print(generate(case,args.out,args.certificates),flush=True)


if __name__=='__main__':main()
