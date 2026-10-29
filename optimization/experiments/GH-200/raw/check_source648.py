#!/usr/bin/env python3
"""Independent literal PDFp33/Eq85-86 rank discrepancy reproduction.

No generator, GF2 library, logical builder or distance solver imports.
Only Python standard library. No logical-distance search.
"""
import argparse
import hashlib
from itertools import product
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[4]
DIMS=(3,9,2,2)
# Independently transcribed numerical supports, not parsed polynomial strings.
TERMS=(((2,4,1,1),(2,2,1,0),(1,5,1,1)),
       ((2,1,0,1),(1,7,1,1),(1,5,1,1)),
       ((1,5,1,1),(0,8,1,0),(0,0,1,0)),
       ((2,8,0,1),(1,8,1,1),(0,5,0,0)))
PZ=((1,2,3,None,None,None),(0,None,None,2,3,None),
    (None,0,None,1,None,3),(None,None,0,None,1,2))
PX=((2,1,None,0,None,None),(3,None,1,None,0,None),
    (None,3,2,None,None,0),(None,None,None,3,2,1))


def literal():
    vertices=list(product(*(range(l) for l in DIMS)));N=len(vertices)
    matrices=[]
    for terms in TERMS:
        matrices.append([bytearray(int(tuple((a-b)%l for a,b,l in zip(r,c,DIMS)) in terms)
                                   for c in vertices) for r in vertices])
    out=[]
    for layout,transposed in [(PX,True),(PZ,False)]:
        rows=[]
        for blocks in layout:
            for r in range(N):
                row=bytearray()
                for axis in blocks:
                    if axis is None:row.extend(bytearray(N))
                    elif transposed:row.extend(matrices[axis][c][r] for c in range(N))
                    else:row.extend(matrices[axis][r])
                rows.append(row)
        out.append(rows)
    return out


def dense_rank(original):
    rows=[bytearray(r) for r in original];rank=0;width=len(rows[0])
    for col in range(width):
        pivot=next((i for i in range(rank,len(rows)) if rows[i][col]),None)
        if pivot is None:continue
        rows[rank],rows[pivot]=rows[pivot],rows[rank]
        for i in range(rank+1,len(rows)):
            if rows[i][col]:rows[i]=bytearray(a^b for a,b in zip(rows[i],rows[rank]))
        rank+=1
        if rank==len(rows):break
    return rank


def read_actual(path):
    return [bytearray(int(x) for x in line.split()) for line in path.read_text().splitlines()
            if line.strip() and not line.startswith('#')]


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--emit-quarantine',type=Path,help='optional NEW diagnostic directory; never the flat accepted library')
    args=ap.parse_args()
    default=ROOT/'data/matrices/untiered/quarantine/GH-200'
    # Transitional original flat location is accepted only before quarantine.
    directory=default if default.exists() else ROOT/'data/matrices/untiered'
    hx,hz=literal();source_k=18;n=len(hx[0]);ranks=[dense_rank(hx),dense_rank(hz)]
    actual_k=n-sum(ranks)
    if args.emit_quarantine is not None:
        if args.emit_quarantine.resolve()==(ROOT/'data/matrices/untiered').resolve():
            raise ValueError('source discrepancy: cannot emit into accepted library')
        args.emit_quarantine.mkdir(parents=True,exist_ok=False)
        for kind,rows in [('Hx',hx),('Hz',hz)]:
            header='# original coupled MM t4; dims=3,9,2,2; %s; arXiv2601.18879v2 TableIII\n'%kind
            (args.emit_quarantine/('MM_648_18_unknown_'+kind+'.txt')).write_text(header+''.join(' '.join(map(str,r))+'\n' for r in rows))
        subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset',
                        '--dir',str(args.emit_quarantine),'MM_648_18_unknown'],check=True)
        for kind in ['Hx','Hz','Gx','Gz']:
            name='MM_648_18_unknown_'+kind+'.txt'
            if (args.emit_quarantine/name).read_bytes()!=(directory/name).read_bytes():
                raise ValueError('diagnostic byte reproduction differs: '+kind)
    identity={}
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        p=directory/('MM_648_18_unknown_'+kind+'.txt')
        if read_actual(p)!=rows:raise ValueError('literal independent matrix differs: '+kind)
        identity[kind]=hashlib.sha256(p.read_bytes()).hexdigest()
    # Separate explicit scalar parity check: no bitset dot-product helper.
    commutes=all(sum(x*y for x,y in zip(a,b))%2==0 for a in hx for b in hz)
    if not commutes:raise ValueError('literal CSS matrices do not commute')
    logical_counts={kind:len(read_actual(directory/('MM_648_18_unknown_'+kind+'.txt'))) for kind in ['Gx','Gz']}
    result=dict(source='2601.18879v2 PDFp33 TableIII; PDFp10 Eq85-86',dims=DIMS,
        independently_transcribed_supports=TERMS,shape=[len(hx),n],source_claimed_k=source_k,
        independent_dense_ranks=ranks,actual_rank_derived_k=actual_k,
        generated_logical_row_counts=logical_counts,entrywise_equal_to_subset_constructor=True,
        literal_scalar_commutation=commutes,matrix_sha256=identity,
        source_dimension_gate='FAIL' if actual_k!=source_k else 'PASS',
        interpretation='SOURCE_DIMENSION_DISCREPANCY_HOLD; not a distance result or proof that the paper theorem is false')
    out=Path(__file__).with_name('source648-independent.json');out.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))


if __name__=='__main__':main()
