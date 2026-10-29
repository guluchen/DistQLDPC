#!/usr/bin/env python3
"""Audit published exact claims, raw engine evidence and GF(2) witnesses."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from smoke_untiered import parse
from validate_css import basis,contains,dot,read_code


def verify_witness(n,matrices,half,support):
    if half not in ('X','Z') or not support or len(set(support))!=len(support) or min(support)<0 or max(support)>=n:
        raise ValueError('invalid witness support/half')
    hx,hz,gx,gz=matrices
    parity,stab,detectors=(hz,hx,gx) if half=='X' else (hx,hz,gz)
    word=sum(1 << q for q in support)
    if any(dot(word,r) for r in parity) or contains(basis(stab),word):
        raise ValueError('witness is not a nontrivial logical')
    if not any(dot(word,r) for r in detectors):raise ValueError('no logical detector')


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--maxsat',type=Path,required=True)
    ap.add_argument('--cc',type=Path,required=True)
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/weight8_bb_cases.json'))
    ap.add_argument('--family',default='BB',help='stem prefix of this batch')
    ap.add_argument('--independent',type=Path,help='optional independent surface-oracle witnesses')
    args=ap.parse_args();results=[]
    independent={r['stem']:r for r in json.loads(args.independent.read_text())} if args.independent else {}
    for case in json.loads(args.cases.read_text()):
        if case.get('status','READY_FOR_VALIDATION')!='READY_FOR_VALIDATION':continue
        stem=f'{args.family}_{case["n"]}_{case["k"]}_unknown';n,m=read_code(args.matrices,stem)
        engines={};witnesses=[];sources=set();binaries=set();exacts=[]
        if args.independent:
            record=independent[stem]
            for key,half in (('primal_Z','Z'),('dual_X','X')):
                support=record[key]['support'];verify_witness(n,m,half,support)
                if len(support)!=record[key]['distance'] or len(support)<case['d']:
                    raise ValueError('independent witness contradicts distance')
                witnesses.append(dict(engine='independent-surface-oracle',half=half,support=support,weight=len(support)))
        for engine,directory in (('maxsat',args.maxsat),('cc',args.cc)):
            meta=json.loads((directory/f'{stem}.json').read_text());raw=(directory/f'{stem}.log').read_text()
            result=parse(raw,case['d'])
            if result!={k:meta[k] for k in ('lb','ub','status')}:raise ValueError('raw/JSON mismatch')
            if ('-engine=cc' in meta['cmd'])!=(engine=='cc'):raise ValueError('engine argv mismatch')
            if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:raise ValueError('incomplete matrix identities')
            for kind,digest in meta['input_sha256'].items():
                if hashlib.sha256((args.matrices/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest:
                    raise ValueError('matrix identity mismatch')
            sources.add(meta['source_head']);binaries.add(meta['binary_sha256'])
            for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
                half=match.group(1);support=list(map(int,match.group(2).split()))
                verify_witness(n,m,half,support)
                if len(support)<case['d']:raise ValueError('witness contradicts published distance')
                witnesses.append(dict(engine=engine,half=half,support=support,weight=len(support)))
            answers=list(map(int,re.findall(r'^o (\d+)\s*$',raw,re.M)))
            if result['status']=='SOLVED':
                if not answers or set(answers)!={case['d']}:raise ValueError('exact answer mismatch')
                exacts.append(engine)
            engines[engine]=result
        if len(sources)!=1 or len(binaries)!=1:raise ValueError('source/binary mismatch between engines')
        lower=max([r['lb'] for r in engines.values() if r['lb'] is not None]+[1])
        upper=min([r['ub'] for r in engines.values() if r['ub'] is not None]+[w['weight'] for w in witnesses]+[n])
        if lower>upper:raise ValueError('contradictory engine intervals')
        # A checked logical of weight d is an engine-independent upper bound.
        # Each engine independently certifies its lower bound on identical inputs;
        # the current CLI need not re-emit a witness found by exact CC search.
        if exacts and not any(w['weight']==case['d'] for w in witnesses):
            raise ValueError('exact result lacks a GF(2)-verified minimum-weight witness')
        results.append(dict(stem=stem,published_exact_d=case['d'],engines=engines,witnesses=witnesses,
                            verification='CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if len(exacts)==2 else 'INCOMPLETE_INDEPENDENT_REPRODUCTION',
                            source_head=next(iter(sources)),binary_sha256=next(iter(binaries))))
    content=json.dumps(results,indent=2)+'\n';args.out.write_text(content);print(content,end='')


if __name__=='__main__':main()
