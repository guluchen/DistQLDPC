#!/usr/bin/env python3
"""Replay retained solver logs and materialized witnesses; never run a solver."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from smoke_untiered import parse_claim
from validate_css import read_code
from verify_css_witness import verify_witness


def require(condition,message):
    if not condition:
        raise ValueError(message)


def claim(case):
    lo,hi=case['conditional_construction_interval']
    return f'range {lo} {hi}'


def assess(case,n,matrices,construction,logs):
    words=[]
    for half,word in zip(('Z','X'),construction['actual_basis_words_GxGz']):
        verify_witness(n,matrices,half,word['support'])
        require(len(word['support'])==word['weight'],'basis support/weight disagree')
        words.append(dict(half=half,origin='actual logical basis',**word))
    results={}
    for engine,raw in logs.items():
        results[engine]=parse_claim(raw,claim(case),n)
        for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
            support=list(map(int,match.group(2).split()))
            verify_witness(n,matrices,match.group(1),support)
            words.append(dict(half=match.group(1),origin=engine,support=support,weight=len(support)))
    lo,hi=case['conditional_construction_interval']
    require(all(w['weight']>=lo for w in words),'actual word contradicts construction lower')
    actual=min(w['weight'] for w in words)
    lowers=[r['lb'] for r in results.values() if r['lb'] is not None]
    uppers=[r['ub'] for r in results.values() if r['ub'] is not None]+[actual]
    require(not lowers or max(lowers)<=min(uppers),'engine bounds/actual word disagree')
    for result in results.values():
        if result['status']=='SOLVED':
            require(any(w['weight']==result['ub'] for w in words),'exact result lacks actual minimum word')
    exact=len(results)==2 and all(r['status']=='SOLVED' for r in results.values())
    return dict(stem=construction['stem'],reference_construction_interval=[lo,hi],
                published_named_exact=case['reference_exact'] if case['id']=='source900' else None,
                original_finite_theorem_target=case['reference_exact'] if case['id']!='source900' else None,
                engines=results,actual_verified_upper=actual,
                actual_verified_half_uppers={h:min(w['weight'] for w in words if w['half']==h) for h in ('X','Z')},
                witnesses=words,source_construction_upper_word_gate='PASS' if actual<=hi else 'INCOMPLETE',
                numeric_smoke_gate='PASS' if len(results)==2 and all(r['lb'] is not None and r['ub'] is not None for r in results.values()) else 'INCOMPLETE',
                scientific_status='CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if exact else 'PLAUSIBLE_SEARCH_BOUNDS; construction theorem hypotheses independently audited',
                independent_search_lower_corrob=min(lowers) if len(lowers)==2 else None)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for key in ('maxsat','cc','construction','out'):
        ap.add_argument('--'+key,type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/hyperbicycle_cases.json'))
    a=ap.parse_args()
    constructions={c['id']:c for c in json.loads(a.construction.read_text())['cases']}
    output=[]
    for case in json.loads(a.cases.read_text()):
        construction=constructions[case['id']];stem=construction['stem']
        n,matrices=read_code(a.matrices,stem)
        logs={};identities=[]
        for engine,directory in (('maxsat',a.maxsat),('cc',a.cc)):
            directory=directory/stem
            meta=json.loads((directory/(stem+'.json')).read_text())
            raw=(directory/(stem+'.log')).read_text()
            require(set(meta['input_sha256'])=={'Hx','Hz','Gx','Gz'},'incomplete input identity')
            for kind,digest in meta['input_sha256'].items():
                require(hashlib.sha256((a.matrices/(stem+'_'+kind+'.txt')).read_bytes()).hexdigest()==digest,'matrix identity mismatch')
            require('-cpu-lim=60' in meta['cmd'] and ('-engine=cc' in meta['cmd'])==(engine=='cc'),'engine/CPU limit mismatch')
            result=parse_claim(raw,claim(case),n)
            require(all(meta[k]==v for k,v in result.items()),'metadata/raw mismatch')
            require(meta['rc'] in (0,1) and (meta['rc']==0)==(result['status']=='SOLVED'),'exit/raw result mismatch')
            identities.append((meta['source_head'],meta['binary_sha256']))
            logs[engine]=raw
        require(len(set(identities))==1,'source/binary mismatch across engines')
        result=assess(case,n,matrices,construction,logs)
        result.update(source_head=identities[0][0],binary_sha256=identities[0][1])
        output.append(result)
    a.out.write_text(json.dumps(output,indent=2)+'\n')
    print(json.dumps([{k:v for k,v in x.items() if k!='witnesses'} for x in output],indent=2))


if __name__=='__main__':
    main()
