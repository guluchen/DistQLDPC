#!/usr/bin/env python3
"""Replay QR engine logs, source identities and physical GF2 words only."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from smoke_untiered import parse_claim
from validate_css import read_code
from verify_css_witness import verify_witness


def require(ok,message):
    if not ok:raise ValueError(message)


def claim(case):
    return ('exact '+str(case['published_exact']) if case['published_exact'] is not None
            else '>= '+str(case['published_lower']))


def assess(case,n,matrices,construction,logs):
    words=list(construction['actual_words']);results={};answers={}
    for word in words:
        verify_witness(n,matrices,word['half'],word['support'])
        require(word['weight']==len(word['support']),'construction word/support mismatch')
    for engine,raw in logs.items():
        results[engine]=parse_claim(raw,claim(case),n)
        exacts=list(map(int,re.findall(r'^o (\d+)\s*$',raw,re.M)))
        if exacts:answers[engine]=exacts[-1]
        for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
            support=list(map(int,match.group(2).split()))
            verify_witness(n,matrices,match.group(1),support)
            words.append(dict(half=match.group(1),weight=len(support),support=support,origin=engine))
    require(all(w['weight']>=case['published_lower'] for w in words),'actual word contradicts source lower')
    actual=min(w['weight'] for w in words)
    lowers=[r['lb'] for r in results.values() if r['lb'] is not None]+list(answers.values())
    uppers=[r['ub'] for r in results.values() if r['ub'] is not None]+[actual]
    require(not lowers or max(lowers)<=min(uppers),'search/exact/actual-word bounds contradict')
    for value in answers.values():
        require(any(w['weight']==value for w in words),'exact result lacks actual minimum word')
    if case['published_exact'] is not None:
        require(not lowers or max(lowers)<=case['published_exact'],'search contradicts source exact')
    exact=len(results)==2 and len(answers)==2 and len(set(answers.values()))==1
    numeric=len(results)==2 and all(r['lb'] is not None and r['ub'] is not None for r in results.values())
    reported_word=all(r['ub'] is None or actual<=r['ub'] for r in results.values())
    target=case['published_exact']
    return dict(stem=construction['stem'],published_lower=case['published_lower'],published_exact=target,
                engines=results,explicit_exact_answers=answers,
                confirmed_exact=next(iter(answers.values())) if exact else None,
                actual_verified_upper=actual,actual_verified_half_uppers={h:min(w['weight'] for w in words if w['half']==h) for h in ('X','Z')},
                witnesses=words,numeric_smoke_gate='PASS' if numeric else 'INCOMPLETE',
                reported_upper_word_gate='PASS' if reported_word else 'INCOMPLETE',
                source_upper_word_gate='NOT_APPLICABLE' if target is None else 'PASS' if actual<=target else 'INCOMPLETE',
                scientific_status='CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if exact else
                'PUBLISHED_EXACT_REPRODUCED_ONE_ENGINE_AND_GF2' if target is not None and answers else
                'PLAUSIBLE_SEARCH_BOUNDS; source-construction lower independently checked',
                independent_search_lower_corrob=min(lowers) if len(results)==2 and all(r['lb'] is not None for r in results.values()) else None)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for name in ('maxsat','cc','construction','out'):ap.add_argument('--'+name,type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/qr_cases.json'))
    a=ap.parse_args();constructions={c['id']:c for c in json.loads(a.construction.read_text())};out=[]
    for case in json.loads(a.cases.read_text()):
        construction=constructions[case['id']];stem=construction['stem']
        n,matrices=read_code(a.matrices,stem);logs={};identities=[]
        for engine,root in (('maxsat',a.maxsat),('cc',a.cc)):
            directory=root/stem;raw=(directory/(stem+'.log')).read_text()
            meta=json.loads((directory/(stem+'.json')).read_text())
            require(set(meta['input_sha256'])=={'Hx','Hz','Gx','Gz'},'incomplete input identity')
            for kind,digest in meta['input_sha256'].items():
                require(hashlib.sha256((a.matrices/(stem+'_'+kind+'.txt')).read_bytes()).hexdigest()==digest,'input SHA mismatch')
            result=parse_claim(raw,claim(case),n)
            require(all(meta[k]==v for k,v in result.items()),'raw/metadata mismatch')
            require('-cpu-lim=60' in meta['cmd'] and ('-engine=cc' in meta['cmd'])==(engine=='cc'),'engine/limit mismatch')
            require(meta['rc'] in (0,1) and (meta['rc']==0)==(result['status']=='SOLVED'),'exit/result mismatch')
            identities.append((meta['source_head'],meta['binary_sha256']));logs[engine]=raw
        require(len(set(identities))==1,'cross-engine source/binary mismatch')
        result=assess(case,n,matrices,construction,logs)
        result.update(source_head=identities[0][0],binary_sha256=identities[0][1]);out.append(result)
    a.out.write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps([{k:v for k,v in r.items() if k!='witnesses'} for r in out],indent=2))


if __name__=='__main__':main()
