#!/usr/bin/env python3
"""Cross-check actual quantum outputs with two finite matrix-certificate verifiers.

Published cubic formulas and original rectangular extensions stay distinct.
"""
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
    for name in ('maxsat','cc','construction','independent','out'):ap.add_argument('--'+name,type=Path,required=True)
    ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/toric4d_cases.json'))
    args=ap.parse_args();proof=json.loads(args.independent.read_text());lookup={r['stem']:r for r in proof['results']};results=[]
    receipts={r['stem']:r for r in json.loads(args.construction.read_text())}
    if proof['certificate_sha256']!=hashlib.sha256(args.construction.read_bytes()).hexdigest():raise ValueError('certificate identity mismatch')
    for c in json.loads(args.cases.read_text()):
        stem=f'TOR_{c["n"]}_6_unknown';n,m=read_code(args.matrices,stem);independent=lookup[stem];d=independent['verified_exact_d']
        if d!=c['d'] or d!=receipts[stem]['derived_exact_d']:raise ValueError('independent certificate mismatch')
        engines={};sources=set();binaries=set();witnesses=[];exacts=[]
        for word in receipts[stem]['witnesses']:
            verify_witness(n,m,word['half'],word['support'])
            if len(word['support'])!=d or word['weight']!=d:raise ValueError('certificate upper word weight mismatch')
            witnesses.append(dict(engine='independent-matrix-certificate',**word))
        for kind,digest in independent['input_sha256'].items():
            if hashlib.sha256((args.matrices/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest:raise ValueError('independent certificate input mismatch')
        for engine,directory in (('maxsat',args.maxsat),('cc',args.cc)):
            meta=json.loads((directory/f'{stem}.json').read_text());raw=(directory/f'{stem}.log').read_text()
            result=parse(raw,c['d'],exact=False)
            if result!={k:meta[k] for k in result}:raise ValueError('engine raw/JSON mismatch')
            if ('-engine=cc' in meta['cmd'])!=(engine=='cc'):raise ValueError('wrong engine argv')
            if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:raise ValueError('incomplete engine input identities')
            if any(hashlib.sha256((args.matrices/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest for kind,digest in meta['input_sha256'].items()):
                raise ValueError('engine input identity mismatch')
            sources.add(meta['source_head']);binaries.add(meta['binary_sha256'])
            if (result['lb'] is not None and result['lb']>d) or (result['ub'] is not None and result['ub']<d):
                raise ValueError('SCIENTIFIC MISMATCH: quantum bounds contradict independent matrix exact proof')
            for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
                support=list(map(int,match.group(2).split()));verify_witness(n,m,match.group(1),support)
                if len(support)<d:raise ValueError('SCIENTIFIC MISMATCH: quantum word below matrix proof')
                witnesses.append(dict(engine=engine,half=match.group(1),support=support,weight=len(support)))
            if result['status']=='SOLVED':
                answer=int(re.findall(r'^o (\d+)\s*$',raw,re.M)[-1])
                if answer!=d:raise ValueError('SCIENTIFIC MISMATCH: quantum exact answer contradicts matrix proof')
                exacts.append(answer)
            engines[engine]=result
        if len(sources)!=1 or len(binaries)!=1:raise ValueError('engines source or binary mismatch')
        status=('CROSS_CHECKED_MATRIX_CERTIFICATES_AND_TWO_ENGINES' if len(exacts)==2 else
                'CROSS_CHECKED_MATRIX_CERTIFICATES_AND_ONE_ENGINE' if len(exacts)==1 else
                'INDEPENDENT_MATRIX_CERTIFICATES_COMPLETE')
        results.append(dict(stem=stem,published_family_exact_d=c['d'] if c['claim']=='exact' else None,rectangular_upper_claim=c['d'] if c['claim']=='upper' else None,derived_quantum_d=d,
            independent_method=independent['method'],engines=engines,witnesses=witnesses,scientific_status=status,
            numeric_smoke_gate='PASS' if all(r['lb'] is not None and r['ub'] is not None for r in engines.values()) else 'INCOMPLETE',
            source_head=next(iter(sources)),binary_sha256=next(iter(binaries))))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
