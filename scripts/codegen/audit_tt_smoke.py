#!/usr/bin/env python3
"""Independent retained-log identities, interval consistency and actual-word audit."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from smoke_untiered import parse_claim
from validate_css import read_code
from verify_css_witness import verify_witness


def require(ok,msg):
    if not ok:raise ValueError(msg)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def assess(c,n,m,construction,logs):
    # Reference range constrains contradiction review, never fills raw fields.
    words=list(construction['independently_checked_uppers']);engines={}
    for w in words:
        verify_witness(n,m,w['half'],w['support']);require(len(w['support'])==w['weight'],'basis upper weight')
    for engine,raw in logs.items():
        result=parse_claim(raw,('exact '+str(c['published_exact']) if c['published_exact'] is not None else '<= '+str(c['reference_upper'])),n);engines[engine]=result
        if result['ub'] is not None:require(result['ub']>=c['reference_lower'],'reported upper contradicts reference lower')
        for a in re.findall(r'^o (\d+)\s*$',raw,re.M):require(int(a)>=c['reference_lower'],'exact contradicts reference lower')
        for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
            qs=list(map(int,match.group(2).split()));verify_witness(n,m,match.group(1),qs)
            words.append(dict(engine=engine,half=match.group(1),weight=len(qs),support=qs))
    require(all(w['weight']>=c['reference_lower'] for w in words),'actual word contradicts reference lower')
    for w in words:
        half_exact=c.get('published_'+w['half']+'_exact')
        require(half_exact is None or w['weight']>=half_exact,'actual word contradicts source exact half')
    uppers=[v['ub'] for v in engines.values() if v['ub'] is not None]+[w['weight'] for w in words]
    lowers=[v['lb'] for v in engines.values() if v['lb'] is not None]
    require(not lowers or max(lowers)<=min(uppers),'engines/actual word disagree')
    for engine,r in engines.items():
        if r['status']=='SOLVED':require(any(w['weight']==r['ub'] for w in words),'exact result lacks actual minimum word')
    exact=len(engines)==2 and all(r['status']=='SOLVED' for r in engines.values())
    numeric=all(r['lb'] is not None and r['ub'] is not None for r in engines.values())
    return dict(stem=construction['stem'],reference_range=[c['published_lb'],c['published_ub']],published_exact=c['published_exact'],published_upper=c['published_ub'],engines=engines,
        actual_verified_upper=min(w['weight'] for w in words),actual_verified_half_uppers={h:min(w['weight'] for w in words if w['half']==h) for h in ['X','Z']},source_half_claims={k:c[k] for k in ['published_X_upper','published_X_exact','published_Z_exact']},witnesses=words,
        source_upper_word_gate=('NOT_APPLICABLE' if c['published_ub'] is None else 'PASS' if min(w['weight'] for w in words)<=c['published_ub'] else 'INCOMPLETE'),
        numeric_smoke_gate='PASS' if numeric else 'INCOMPLETE',
        scientific_status=('CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if exact else 'PUBLISHED_EXACT_REPRODUCED_ONE_ENGINE_AND_GF2' if c['published_exact'] is not None and any(r['status']=='SOLVED' for r in engines.values()) else 'PLAUSIBLE_SEARCH_BOUNDS'),
        independent_lower_corrob=min(lowers) if len(lowers)==2 else None)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for key in ('maxsat','cc','construction','out'):ap.add_argument('--'+key,type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/tt_cases.json'));a=ap.parse_args()
    constructions={r['n']:r for r in json.loads(a.construction.read_text())};out=[]
    for c in json.loads(a.cases.read_text()):
        stem=constructions[c['n']]['stem'];n,m=read_code(a.matrices,stem);logs={};identities=[]
        for engine,directory in [('maxsat',a.maxsat),('cc',a.cc)]:
            meta=json.loads((directory/(stem+'.json')).read_text());raw=(directory/(stem+'.log')).read_text()
            require(set(meta['input_sha256'])=={'Hx','Hz','Gx','Gz'},'incomplete input identity')
            require(all(sha(a.matrices/(stem+'_'+kind+'.txt'))==v for kind,v in meta['input_sha256'].items()),'input identity changed')
            require('-cpu-lim=60' in meta['cmd'] and ('-engine=cc' in meta['cmd'])==(engine=='cc'),'engine/limit mismatch')
            identities.append((meta['source_head'],meta['binary_sha256']))
            result=parse_claim(raw,('exact '+str(c['published_exact']) if c['published_exact'] is not None else '<= '+str(c['reference_upper'])),n)
            require(all(meta[k]==v for k,v in result.items()) and meta['rc'] in (0,1) and (meta['rc']==0)==(result['status']=='SOLVED'),'metadata/exit/raw result disagree')
            logs[engine]=raw
        require(len(set(identities))==1,'cross-engine source/binary mismatch')
        r=assess(c,n,m,constructions[c['n']],logs);r.update(source_head=identities[0][0],binary_sha256=identities[0][1]);out.append(r)
    a.out.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))


if __name__=='__main__':main()
