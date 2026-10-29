#!/usr/bin/env python3
"""Retained-log/actual-word/source-guard replay; no solver execution."""
import hashlib
import json
from pathlib import Path
import re
import sys
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
from validate_css import read_code,validate
from verify_css_witness import verify_witness
from smoke_untiered import parse_claim


def main():
    raw=Path(__file__).parent;directory=raw/'actions/failed-source-smoke/schreier-maxsat';matrices=ROOT/'data/matrices/untiered/quarantine/GH-202'
    names=sorted(p.stem for p in directory.glob('*.log'))
    if names!=['TN_180_26_unknown','TN_500_42_unknown']:raise ValueError('unexpected run selection; no silent extra attempts')
    if list((directory.parent/'schreier-cc').glob('*')):raise ValueError('unexpected CC execution after failed source gate')
    results=[]
    for stem in names:
        text=(directory/(stem+'.log')).read_text();meta=json.loads((directory/(stem+'.json')).read_text());n,m=read_code(matrices,stem);validate(n,m)
        if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:raise ValueError('missing input identity')
        for kind,digest in meta['input_sha256'].items():
            if hashlib.sha256((matrices/(stem+'_'+kind+'.txt')).read_bytes()).hexdigest()!=digest:raise ValueError('actual input changed')
        result=parse_claim(text,'unknown',n) # extract observed result, NEVER change published claim.
        if meta['rc']!=0 or result['status']!='SOLVED':raise ValueError('retained raw/exit disagreement')
        words=[]
        for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',text,re.M):
            support=list(map(int,match[2].split()));verify_witness(n,m,match[1],support)
            words.append(dict(half=match[1],support=support,weight=len(support)))
        if not any(w['weight']==result['ub'] for w in words):raise ValueError('raw exact answer lacks actual verified minimum word')
        strict_failed=False
        try:parse_claim(text,'exact 6',n)
        except ValueError:strict_failed=True
        if strict_failed!=(stem=='TN_500_42_unknown'):raise ValueError('retained source comparison changed')
        results.append(dict(stem=stem,parsed_raw_result=result,source_reference_exact=6,actual_verified_words=words,
            source_head=meta['source_head'],binary_sha256=meta['binary_sha256'],raw_meta_keys=sorted(meta),
            source_exact_guard_raised=strict_failed,
            scientific_status='SOURCE_LABEL_REPRODUCTION_HOLD_PLAUSIBLE_ONE_ENGINE_EXACT8' if strict_failed else 'PUBLISHED_EXACT_REPRODUCED_ONE_ENGINE_AND_GF2'))
    if len({(r['source_head'],r['binary_sha256']) for r in results})!=1:raise ValueError('source/binary identity mismatch')
    out=raw/'source-distance-hold.json';out.write_text(json.dumps(results,indent=2)+'\n');print('PASS retained source6 versus raw8 hold, actual GF2 words, no extra runs')


if __name__=='__main__':main()
