#!/usr/bin/env python3
"""Audit both internal engines, actual witnesses and claim semantics (GH-160)."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from smoke_untiered import parse
from validate_css import basis,contains,dot,read_code


def verify_witness(n,matrices,half,support):
    if not support or len(set(support))!=len(support) or min(support)<0 or max(support)>=n:
        raise ValueError('invalid witness support')
    hx,hz,gx,gz=matrices
    parity,stab,detectors=(hz,hx,gx) if half=='X' else (hx,hz,gz)
    word=sum(1 << q for q in support)
    if any(dot(word,r) for r in parity) or contains(basis(stab),word):
        raise ValueError('witness is not a nontrivial logical')
    if not any(dot(word,r) for r in detectors):raise ValueError('witness has no logical detector')


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--maxsat',type=Path,required=True)
    ap.add_argument('--cc',type=Path,required=True)
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-160/raw/construction-witnesses.json'))
    args=ap.parse_args();results=[]
    for cert in json.loads(args.certificates.read_text()):
        stem=cert['stem'];n,m=read_code(args.matrices,stem);engines={};witnesses=[];source=set();binaries=set()
        verify_witness(n,m,'X',cert['cycle_witness']['support'])
        witnesses.append(dict(origin='independent cycle',**cert['cycle_witness']))
        for engine,directory in (('maxsat',args.maxsat),('cc',args.cc)):
            meta=json.loads((directory/f'{stem}.json').read_text())
            raw=(directory/f'{stem}.log').read_text()
            result=parse(raw,cert['verified_cycle_ub'],exact=False)
            if result!={k:meta[k] for k in ('lb','ub','status')}:raise ValueError('raw/JSON result mismatch')
            if ('-engine=cc' in meta['cmd']) != (engine=='cc'):raise ValueError('wrong engine argv')
            for kind,digest in meta['input_sha256'].items():
                if hashlib.sha256((args.matrices/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest:
                    raise ValueError('matrix identity mismatch')
            source.add(meta['source_head']);binaries.add(meta['binary_sha256'])
            for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
                half=match.group(1);support=list(map(int,match.group(2).split()))
                verify_witness(n,m,half,support)
                witnesses.append(dict(origin=engine,half=half,support=support,weight=len(support)))
            engines[engine]=result
        if len(source)!=1 or len(binaries)!=1:raise ValueError('engines use different source or binary')
        lower=max(r['lb'] or 1 for r in engines.values())
        upper=min([w['weight'] for w in witnesses]+[r['ub'] for r in engines.values() if r['ub'] is not None])
        if lower>upper:raise ValueError('engine bounds contradict verified witnesses')
        exacts=[r['lb'] for r in engines.values() if r['status']=='SOLVED']
        if exacts and (min(exacts)!=max(exacts) or not lower<=exacts[0]<=upper):
            raise ValueError('engine exact result contradiction')
        scientific_status='PLAUSIBLE_PENDING_INDEPENDENT_COMPLETION'
        if len(exacts)==2:
            if not any(w['weight']==exacts[0] for w in witnesses):
                raise ValueError('exact result lacks independently verified minimum-weight witness')
            scientific_status='CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS'
        results.append(dict(stem=stem,engines=engines,scientific_status=scientific_status,
                            witnesses=witnesses,source_head=next(iter(source)),binary_sha256=next(iter(binaries))))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
