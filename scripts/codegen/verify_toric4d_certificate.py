#!/usr/bin/env python3
"""Standalone receipt checker: column syndromes, low-pivot GF2, set packing.

No imports from the constructor, primary verifier, logical builder or solvers.
Verifies actual matrix distances from a finite certificate; no support search.
GPL-3.0-or-later.
"""
import argparse
import hashlib
import json
from pathlib import Path


def load_matrix(path):
    width=None;rows=[]
    for line in path.read_text().splitlines():
        if not line.strip() or line.lstrip().startswith('#'):continue
        tokens=line.split()
        if width is None:width=len(tokens)
        if len(tokens)!=width or any(t not in ('0','1') for t in tokens):raise ValueError('malformed binary matrix')
        rows.append(sum(1<<q for q,t in enumerate(tokens) if t=='1'))
    if not rows:raise ValueError('empty matrix')
    return width,rows


def low_basis(rows):
    pivots={}
    for word in rows:
        while word:
            p=(word&-word).bit_length()-1
            if p in pivots:word^=pivots[p]
            else:pivots[p]=word;break
    return pivots


def in_space(word,pivots):
    while word:
        p=(word&-word).bit_length()-1
        if p not in pivots:return False
        word^=pivots[p]
    return True


def columns(n,rows):
    out=[0]*n
    for i,row in enumerate(rows):
        while row:
            bit=row&-row;q=bit.bit_length()-1;out[q]|=1<<i;row^=bit
    return out


def syndrome(word,cols):
    result=0
    while word:
        bit=word&-word;result^=cols[bit.bit_length()-1];word^=bit
    return result


def support_word(support,n):
    if not support or len(set(support))!=len(support) or any(type(q)!=int or not 0<=q<n for q in support):raise ValueError('invalid support receipt')
    return sum(1<<q for q in support)


def check_half(n,parity,stabilizer,logical,receipt):
    p=low_basis(parity);s=low_basis(stabilizer);k=n-len(p)-len(s)
    if k<=0 or len(logical)!=k or len(low_basis(stabilizer+logical))!=len(s)+k:
        raise ValueError('logical quotient is not complete')
    if any(syndrome(w,columns(n,parity)) for w in logical):raise ValueError('logical syndrome')
    families=receipt['families'];refs=[];counts=[];dual_columns=columns(n,stabilizer)
    if len(families)!=k:raise ValueError('receipt omits a logical class')
    for family in families:
        if not family:raise ValueError('empty receipt family')
        reference=support_word(family[0],n);seen=set()
        if syndrome(reference,dual_columns):raise ValueError('detector reference syndrome')
        for support in family:
            word=support_word(support,n);current=set(support)
            if seen.intersection(current):raise ValueError('packing receipt overlaps')
            seen.update(current)
            if not in_space(word^reference,p):raise ValueError('packing receipt lacks homology relation')
        refs.append(reference);counts.append(len(family))
    pairing=[sum((bin(w&v).count('1')%2)<<i for i,v in enumerate(logical)) for w in refs]
    if len(low_basis(pairing))!=k:raise ValueError('packing receipt pairing incomplete')
    lower=min(counts)
    if receipt['lower_bound']!=lower or receipt['family_counts']!=counts or receipt['pairing_rank']!=k:
        raise ValueError('packing summary not supported by receipt')
    return lower


def check_code(receipt,directory):
    stem=receipt['stem'];kinds=('Hx','Hz','Gx','Gz');paths=[directory/f'{stem}_{kind}.txt' for kind in kinds]
    loaded=[load_matrix(p) for p in paths]
    if len({n for n,rows in loaded})!=1:raise ValueError('matrix width mismatch')
    n=loaded[0][0];hx,hz,gx,gz=[rows for n,rows in loaded];cx=columns(n,hx);cz=columns(n,hz)
    if any(syndrome(w,cx) for w in hz):raise ValueError('CSS commutator nonzero')
    k=n-len(low_basis(hx))-len(low_basis(hz))
    if k!=6 or n!=receipt['n'] or receipt['k']!=k:raise ValueError('actual quantum dimensions disagree')
    if len(low_basis([sum((bin(a&b).count('1')%2)<<j for j,b in enumerate(gz)) for a in gx]))!=k:
        raise ValueError('logical pairing singular')
    lowerZ=check_half(n,hx,hz,gx,receipt['lower_certificates']['Z'])
    lowerX=check_half(n,hz,hx,gz,receipt['lower_certificates']['X'])
    upper={}
    for witness in receipt['witnesses']:
        half=witness['half'];word=support_word(witness['support'],n)
        if half not in ('X','Z') or witness['weight']!=len(witness['support']):raise ValueError('invalid upper witness')
        parity,stab=(cz,hx) if half=='X' else (cx,hz)
        if syndrome(word,parity) or in_space(word,low_basis(stab)):raise ValueError('upper word is not logical')
        upper[half]=min(upper.get(half,n),len(witness['support']))
    if set(upper)!={'X','Z'} or lowerX!=upper['X'] or lowerZ!=upper['Z']:raise ValueError('lower/upper receipts do not certify both halves')
    d=min(lowerX,lowerZ)
    if receipt['derived_exact_d']!=d:raise ValueError('exact d differs from complete receipt')
    return dict(stem=stem,n=n,k=k,verified_exact_d=d,verified_dX=lowerX,verified_dZ=lowerZ,
                method='standalone low-pivot/column-syndrome/set-packing receipt verification',
                input_sha256={kind:hashlib.sha256(p.read_bytes()).hexdigest() for kind,p in zip(kinds,paths)})


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--certificate',type=Path,default=Path('optimization/experiments/GH-175/raw/construction.json'))
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    rows=[check_code(r,args.matrices) for r in json.loads(args.certificate.read_text())]
    out=dict(certificate_sha256=hashlib.sha256(args.certificate.read_bytes()).hexdigest(),results=rows)
    text=json.dumps(out,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
