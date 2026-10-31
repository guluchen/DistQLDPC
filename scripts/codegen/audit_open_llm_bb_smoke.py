#!/usr/bin/env python3
"""Audit open-source distance claims without promoting decoder estimates, actual words and internal-engine identity."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from smoke_untiered import parse_claim
from validate_css import read_code
from verify_css_witness import verify_witness


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--maxsat',type=Path,required=True)
    ap.add_argument('--cc',type=Path,required=True)
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/open_llm_bb_cases.json'))
    args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text())['cases']:
        if c['claim'] not in ('estimate','upper'):raise ValueError('unsupported reference claim')
        stem=f'BB_{c["n"]}_{c["k"]}_unknown';n,m=read_code(args.matrices,stem)
        engines={};witnesses=[];sources=set();binaries=set();exacts=[]
        for engine,directory in (('maxsat',args.maxsat),('cc',args.cc)):
            meta=json.loads((directory/(stem+'.json')).read_text());raw=(directory/(stem+'.log')).read_text()
            claim=('<= ' if c['endpoint_supported'] else 'estimate ')+str(c['endpoint'])
            result=parse_claim(raw,claim,n)
            if result!={k:meta[k] for k in result}:raise ValueError('raw/JSON result mismatch')
            if ('-engine=cc' in meta['cmd'])!=(engine=='cc'):raise ValueError('engine argv mismatch')
            if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:raise ValueError('incomplete identities')
            for kind,digest in meta['input_sha256'].items():
                if hashlib.sha256((args.matrices/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest:
                    raise ValueError('input identity mismatch')
            sources.add(meta['source_head']);binaries.add(meta['binary_sha256'])
            for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
                half=match.group(1);support=list(map(int,match.group(2).split()));verify_witness(n,m,half,support)
                if len(support)<c['published_lower']:raise ValueError('SCIENTIFIC MISMATCH: word contradicts published positive lower claim')
                witnesses.append(dict(engine=engine,half=half,support=support,weight=len(support)))
            if result['status']=='SOLVED':exacts.append(int(re.findall(r'^o (\d+)\s*$',raw,re.M)[-1]))
            engines[engine]=result
        if len(sources)!=1 or len(binaries)!=1:raise ValueError('engines used different source/binary')
        lower=max([r['lb'] for r in engines.values() if r['lb'] is not None]+[0])
        upper=min([r['ub'] for r in engines.values() if r['ub'] is not None]+[w['weight'] for w in witnesses]+[n])
        if lower>upper or any(not lower<=d<=upper for d in exacts) or len(set(exacts))>1:
            raise ValueError('engine/witness results disagree')
        if upper<c['published_lower'] or any(d<c['published_lower'] for d in exacts):raise ValueError('SCIENTIFIC MISMATCH: observed result contradicts published positive lower claim')
        if exacts and not any(w['weight']==exacts[0] for w in witnesses):
            raise ValueError('exact answer lacks a verified minimum-weight word')
        status='NO_NEW_EXACT_RESULT'
        if exacts:
            status='CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if len(exacts)==2 else 'PLAUSIBLE_PENDING_INDEPENDENT_COMPLETION'
        # Heuristic literature estimates are not independent lower-bound proofs.
        numeric_gate='PASS' if all(r['lb'] is not None and r['ub'] is not None for r in engines.values()) else 'INCOMPLETE'
        at_endpoint=any(w['weight']<=c['endpoint'] for w in witnesses)
        if c['endpoint_supported'] and any(d>c['endpoint'] for d in exacts):raise ValueError('SCIENTIFIC MISMATCH: supported source upper contradicted')
        relation=('OWN_WORD_AT_OR_BELOW_ENDPOINT' if at_endpoint else
                  'CROSS_CHECKED_EXACT_EXCEEDS_DECODER_ESTIMATE' if len(exacts)==2 and exacts[0]>c['endpoint'] else
                  'PROVISIONAL_LOWER_EXCEEDS_DECODER_ESTIMATE' if lower>c['endpoint'] else
                  'ENDPOINT_NOT_REPRODUCED_BY_OWN_WORD')
        results.append(dict(stem=stem,presentation_id=c['presentation_id'],source_class_id=c['class_id'],
                            published_lower=c['published_lower'],published_endpoint=c['endpoint'],endpoint_supported=c['endpoint_supported'],
                            source_was_class_nonexact=True,engines=engines,witnesses=witnesses,
                            scientific_status=status,numeric_smoke_gate=numeric_gate,
                            lower_bound_status='CROSS_CHECKED_COMPLETE_EXACT_PROOF' if len(exacts)==2 else 'PLAUSIBLE_PENDING_INDEPENDENT_LOWER_PROOF',
                            reported_endpoint_relation=relation,own_word_at_source_endpoint=at_endpoint,
                            source_head=next(iter(sources)),binary_sha256=next(iter(binaries))))
    content=json.dumps(results,indent=2)+'\n';args.out.write_text(content);print(content,end='')


if __name__=='__main__':main()
