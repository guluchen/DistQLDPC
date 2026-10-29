#!/usr/bin/env python3
"""Materialize finite logical-basis upper words omitted by timeout stdout.

GF(2) checks on supplied basis rows only: no combinations, support search,
external software, C++ solver invocation or assumptions about distance.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
from validate_css import read_code
from verify_css_witness import verify_witness


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    raw=Path(__file__).with_name('raw')/'actions/default';result=[]
    for c in json.loads((ROOT/'scripts/codegen/homological_product_cases.json').read_text()):
        stem=f'HPC_{c["n"]}_{c["k"]}_unknown';n,m=read_code(ROOT/'data/matrices/untiered',stem)
        meta=json.loads((raw/'homological_product-cc'/f'{stem}.json').read_text())
        for kind,digest in meta['input_sha256'].items():
            if hashlib.sha256((ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes()).hexdigest()!=digest:
                raise ValueError('retained matrix identity mismatch')
        words=[]
        # Gx lies in ker Hx and supplies physical Z words; Gz supplies X.
        for half,rows in (('X',m[3]),('Z',m[2])):
            i,w=min(enumerate(rows),key=lambda iw:(bin(iw[1]).count('1'),iw[0]))
            support=[q for q in range(n) if (w>>q)&1]
            verify_witness(n,m,half,support)
            words.append(dict(half=half,basis='Gz' if half=='X' else 'Gx',zero_based_row=i,support=support,weight=len(support)))
        log=(raw/'homological_product-cc'/f'{stem}.log').read_text()
        match=re.search(r'ub-basis: verified basis rows give UB (\d+) \(X (\d+), Z (\d+)\)',log)
        if not match or list(map(int,match.groups()))!=[min(w['weight'] for w in words)]+[w['weight'] for w in words]:
            raise ValueError('materialized words disagree with retained CC basis summary')
        result.append(dict(stem=stem,input_sha256=meta['input_sha256'],words=words,independent_basis_upper=min(w['weight'] for w in words),status='ACTUAL_GF2_WORDS_ONLY_NO_LOWER_OR_EXACT_PROOF'))
    args.out.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps([{k:r[k] for k in ('stem','independent_basis_upper')} for r in result],indent=2))


if __name__=='__main__':main()
