#!/usr/bin/env python3
"""Audit actual search results against independently checked Haah cubic CSS words."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from smoke_untiered import parse
from validate_css import read_code,validate,equal_space
from verify_css_witness import verify_witness


def verify_peer():
    root=Path('optimization/experiments/GH-182/raw/peer128');stem='BB_128_14_unknown'
    n,m=read_code(root,stem);check=validate(n,m)
    if (n,check['k'])!=(128,14):raise ValueError('peer dimensions mismatch')
    receipt=json.loads((root/'audit.json').read_text());sources=set();binaries=set();minimum=[]
    for engine in ('maxsat','cc'):
        meta=json.loads((root/(engine+'.json')).read_text());raw=(root/(engine+'.log')).read_text()
        if parse(raw,12,exact=True)!=dict(lb=12,ub=12,status='SOLVED') or meta['rc']!=0:raise ValueError('peer exact proof mismatch')
        if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:raise ValueError('incomplete peer identity')
        for kind,digest in meta['input_sha256'].items():
            if hashlib.sha256((root/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest:raise ValueError('peer matrix identity mismatch')
        sources.add(meta['source_head']);binaries.add(meta['binary_sha256'])
        for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
            support=list(map(int,match.group(2).split()));verify_witness(n,m,match.group(1),support);minimum.append(len(support))
    if sources!={receipt['source_head']} or len(binaries)!=1 or min(minimum)!=12:raise ValueError('peer source/binary/actual minimum word mismatch')
    return n,m,receipt


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for key in ('maxsat','cc','construction','out'):ap.add_argument('--'+key,type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/haah_cubic_cases.json'))
    args=ap.parse_args();peer_n,peer_m,peer_receipt=verify_peer();proofs={r['stem']:r for r in json.loads(args.construction.read_text())};results=[]
    for c in json.loads(args.cases.read_text()):
        stem=f'HCC_{c["n"]}_{c["k"]}_unknown';n,m=read_code(args.matrices,stem);proof=proofs[stem];cap=min([proof['independent_overall_upper']]+([c['published_upper']] if c['published_upper'] is not None else []))
        if proof['parameter_sha256']!=hashlib.sha256(json.dumps(c,sort_keys=True,separators=(',',':')).encode()).hexdigest():raise ValueError('independent parameter identity mismatch')
        witnesses=[]
        for w in proof['independently_checked_uppers']:
            verify_witness(n,m,w['half'],w['support'])
            if w['weight']!=len(w['support']):raise ValueError('independent upper weight mismatch')
            witnesses.append(dict(engine='independent-supplied-basis-upper',**w))
        if min(w['weight'] for w in witnesses)!=proof['independent_overall_upper']:raise ValueError('independent upper summary mismatch')
        engines={};sources=set();binaries=set();exacts=[]
        for engine,directory in (('maxsat',args.maxsat),('cc',args.cc)):
            meta=json.loads((directory/f'{stem}.json').read_text());raw=(directory/f'{stem}.log').read_text();result=parse(raw,cap,exact=False)
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
        if any(w['weight']<c['published_lower'] for w in witnesses) or any(r['ub'] is not None and r['ub']<c['published_lower'] for r in engines.values()):raise ValueError('SCIENTIFIC MISMATCH: actual physical word/result contradicts published lower claim')
        if lower>upper or any(not lower<=d<=upper for d in exacts) or len(set(exacts))>1:raise ValueError('SCIENTIFIC MISMATCH: searches and independently verified words disagree')
        if exacts and not any(w['weight']==exacts[0] for w in witnesses):raise ValueError('exact answer lacks a verified minimum word')
        status=('CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if len(exacts)==2 else
                'PLAUSIBLE_ONE_ENGINE_EXACT' if exacts else 'NO_EXACT_RESULT')
        equivalence=None
        if (n,c['k'])==(128,14):
            if (equal_space(m[0],peer_m[0]) and equal_space(m[1],peer_m[1])) or (equal_space(m[0],peer_m[1]) and equal_space(m[1],peer_m[0])):raise ValueError('duplicate peer stabilizer row spaces')
            light=min(witnesses,key=lambda w:w['weight'])
            if light['weight']>=12:raise ValueError('PENDING EQUIVALENCE: no strict distance invariant yet; retain candidate, no duplicate-coverage claim')
            equivalence=dict(peer=peer_receipt['stem'],proof='actual Haah word lighter than independently two-engine-confirmed peer distance12; physical permutations and XZ swap preserve overall distance',actual_Haah_word=light,peer_exact=12,peer_source=peer_receipt['source_head'])
        results.append(dict(stem=stem,same_n_k_peer_non_equivalence=equivalence,published_interval=[c['published_lower'],c['published_upper']],independent_upper=proof['independent_overall_upper'],engines=engines,witnesses=witnesses,
            source_upper_word_gate='PASS' if c['published_upper'] is None or any(w['weight']<=c['published_upper'] for w in witnesses) else 'INCOMPLETE',
            scientific_status=status,lower_bound_status='CROSS_CHECKED_COMPLETE_EXACT_PROOF' if len(exacts)==2 else 'PLAUSIBLE_PENDING_INDEPENDENT_LOWER_PROOF',
            numeric_smoke_gate='PASS' if all(r['lb'] is not None and r['ub'] is not None for r in engines.values()) else 'INCOMPLETE',
            source_head=next(iter(sources)),binary_sha256=next(iter(binaries))))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
