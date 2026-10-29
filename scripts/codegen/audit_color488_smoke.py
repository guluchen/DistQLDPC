#!/usr/bin/env python3
"""Audit exact-vs-estimated triangular4.8.8 exact claims, actual words and internal-engine identity."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from smoke_untiered import parse
from validate_css import read_code
from verify_css_witness import verify_witness


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--maxsat',type=Path,required=True)
    ap.add_argument('--cc',type=Path,required=True)
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/color488_cases.json'))
    ap.add_argument('--construction',type=Path,default=Path('optimization/experiments/GH-172/raw/construction.json'))
    args=ap.parse_args();results=[]
    construction={r['stem']:r for r in json.loads(args.construction.read_text())}
    for c in json.loads(args.cases.read_text()):
        if c['claim'] not in ('exact','upper'):raise ValueError('unsupported reference claim')
        stem=f'COLOR_{c["n"]}_{c["k"]}_unknown';n,m=read_code(args.matrices,stem)
        engines={};witnesses=[];sources=set();binaries=set();exacts=[]
        # These independently reconstructed physical supports establish upper
        # bounds only. Never use them to fill missing engine numeric fields.
        for word in construction[stem]['witnesses']:
            if word['label']!='right boundary':continue
            verify_witness(n,m,word['half'],word['support'])
            if len(word['support'])!=word['weight'] or word['weight']!=c['d']:raise ValueError('boundary upper mismatch')
            witnesses.append(dict(engine='independent-wedge-boundary',half=word['half'],support=word['support'],weight=word['weight']))
        for engine,directory in (('maxsat',args.maxsat),('cc',args.cc)):
            meta=json.loads((directory/(stem+'.json')).read_text());raw=(directory/(stem+'.log')).read_text()
            result=parse(raw,c['d'],exact=c['claim']=='exact')
            if result!={k:meta[k] for k in result}:raise ValueError('raw/JSON result mismatch')
            if ('-engine=cc' in meta['cmd'])!=(engine=='cc'):raise ValueError('engine argv mismatch')
            if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:raise ValueError('incomplete identities')
            for kind,digest in meta['input_sha256'].items():
                if hashlib.sha256((args.matrices/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest:
                    raise ValueError('input identity mismatch')
            sources.add(meta['source_head']);binaries.add(meta['binary_sha256'])
            for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
                half=match.group(1);support=list(map(int,match.group(2).split()));verify_witness(n,m,half,support)
                if c['claim']=='exact' and len(support)<c['d']:raise ValueError('witness contradicts exact reference')
                witnesses.append(dict(engine=engine,half=half,support=support,weight=len(support)))
            if result['status']=='SOLVED':exacts.append(int(re.findall(r'^o (\d+)\s*$',raw,re.M)[-1]))
            engines[engine]=result
        if len(sources)!=1 or len(binaries)!=1:raise ValueError('engines used different source/binary')
        lower=max([r['lb'] for r in engines.values() if r['lb'] is not None]+[0])
        upper=min([r['ub'] for r in engines.values() if r['ub'] is not None]+[w['weight'] for w in witnesses]+[n])
        if lower>upper or any(not lower<=d<=upper for d in exacts) or len(set(exacts))>1:
            raise ValueError('engine/witness results disagree')
        if exacts and not any(w['weight']==exacts[0] for w in witnesses):
            raise ValueError('exact answer lacks a verified minimum-weight word')
        status='NO_NEW_EXACT_RESULT'
        if exacts:
            status='CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if len(exacts)==2 else 'PLAUSIBLE_PENDING_INDEPENDENT_COMPLETION'
        # Heuristic literature estimates are not independent lower-bound proofs.
        numeric_gate='PASS' if all(r['lb'] is not None and r['ub'] is not None for r in engines.values()) else 'INCOMPLETE'
        results.append(dict(stem=stem,published_claim=c['claim'],published_d=c['d'],engines=engines,
                            witnesses=witnesses,scientific_status=status,numeric_smoke_gate=numeric_gate,
                            reference_exact_reproduced=bool(exacts) if c['claim']=='exact' else None,
                            reference_upper_witness_reproduced=any(w['weight']<=c['d'] for w in witnesses) if c['claim']=='upper' else None,
                            source_head=next(iter(sources)),binary_sha256=next(iter(binaries))))
    content=json.dumps(results,indent=2)+'\n';args.out.write_text(content);print(content,end='')


if __name__=='__main__':main()
