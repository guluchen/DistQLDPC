#!/usr/bin/env python3
"""Audit actual search results against independently checked finite SL2 quantum Margulis words."""
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
    for key in ('maxsat','cc','construction','out'):ap.add_argument('--'+key,type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/quantum_margulis_cases.json'))
    ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-187/raw/certificates'))
    args=ap.parse_args();proofs={r['stem']:r for r in json.loads(args.construction.read_text())};results=[]
    for c in json.loads(args.cases.read_text()):
        stem=f'QMC_{c["n"]}_{c["k"]}_unknown';n,m=read_code(args.matrices,stem);proof=proofs[stem];cap=proof['independent_overall_upper']
        if proof['parameter_sha256']!=hashlib.sha256(json.dumps(c,sort_keys=True,separators=(',',':')).encode()).hexdigest():raise ValueError('independent parameter identity mismatch')
        cert=json.loads((args.certificates/f'{stem}.json').read_text())
        if proof['certificate_sha256']!=hashlib.sha256(json.dumps(cert,sort_keys=True,separators=(',',':')).encode()).hexdigest():raise ValueError('finite SL2/integral-generator/regular-action certificate identity mismatch')
        witnesses=[]
        for w in proof['independently_checked_uppers']:
            verify_witness(n,m,w['half'],w['support'])
            if w['weight']!=len(w['support']):raise ValueError('independent upper weight mismatch')
            witnesses.append(dict(engine='independent-supplied-basis-upper',**w))
        if min(w['weight'] for w in witnesses)!=cap:raise ValueError('independent upper summary mismatch')
        engines={};sources=set();binaries=set();exacts=[]
        for engine,directory in (('maxsat',args.maxsat),('cc',args.cc)):
            meta=json.loads((directory/f'{stem}.json').read_text());raw=(directory/f'{stem}.log').read_text();result=parse(raw,c['published_exact'] or cap,exact=c['published_exact'] is not None)
            if result!={k:meta[k] for k in result}:raise ValueError('raw/JSON result mismatch')
            if ('-engine=cc' in meta['cmd'])!=(engine=='cc'):raise ValueError('engine argv mismatch')
            if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:raise ValueError('incomplete input identity')
            for kind,digest in meta['input_sha256'].items():
                if hashlib.sha256((args.matrices/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest:raise ValueError('input identity mismatch')
            sources.add(meta['source_head']);binaries.add(meta['binary_sha256'])
            for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
                support=list(map(int,match.group(2).split()));verify_witness(n,m,match.group(1),support)
                witnesses.append(dict(engine=engine,half=match.group(1),support=support,weight=len(support)))
            if result['status']=='SOLVED':exacts.append(int(re.findall(r'^o (\d+)\s*$',raw,re.M)[-1]))
            engines[engine]=result
        if len(sources)!=1 or len(binaries)!=1:raise ValueError('source/binary mismatch')
        lower=max([r['lb'] for r in engines.values() if r['lb'] is not None]+[0])
        upper=min([r['ub'] for r in engines.values() if r['ub'] is not None]+[w['weight'] for w in witnesses])
        if lower>upper or any(not lower<=d<=upper for d in exacts) or len(set(exacts))>1:raise ValueError('SCIENTIFIC MISMATCH: searches and independently verified words disagree')
        if exacts and not any(w['weight']==exacts[0] for w in witnesses):raise ValueError('exact answer lacks a verified minimum word')
        status=('CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if len(exacts)==2 else
                'PLAUSIBLE_ONE_ENGINE_EXACT' if exacts else 'NO_EXACT_RESULT')
        results.append(dict(stem=stem,individually_published_distance=c['published_exact'],independent_upper=cap,engines=engines,witnesses=witnesses,
            scientific_status=status,lower_bound_status='CROSS_CHECKED_COMPLETE_EXACT_PROOF' if len(exacts)==2 else 'PLAUSIBLE_PENDING_INDEPENDENT_LOWER_PROOF',
            numeric_smoke_gate='PASS' if all(r['lb'] is not None and r['ub'] is not None for r in engines.values()) else 'INCOMPLETE',
            source_head=next(iter(sources)),binary_sha256=next(iter(binaries))))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
