#!/usr/bin/env python3
"""Replay all pinned same-(n,k) inventories; no network or solver invocation."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
from validate_css import read_code,validate,equal_space

def main():
    raw=Path(__file__).parent
    refs=json.loads((raw/'peer-refs.json').read_text())
    cases=json.loads((ROOT/'scripts/codegen/tile_cases.json').read_text());out=[];seen=set()
    for ref in refs:
        paths=subprocess.check_output(['git','ls-tree','-r','--name-only',ref['sha'],'data/matrices'],cwd=ROOT,text=True).splitlines()
        for p in paths:
            if not p.endswith('_Hx.txt'):continue
            stem=Path(p).name[:-7];parts=stem.split('_')
            for c in cases:
                if parts[1:3]!=[str(c['n']),str(c['k'])]:continue
                entry=subprocess.check_output(['git','show',ref['sha']+':'+p],cwd=ROOT)
                key=(stem,hashlib.sha256(entry).hexdigest())
                if key in seen:continue
                seen.add(key)
                with tempfile.TemporaryDirectory() as d:
                    dd=Path(d);hashes={}
                    for kind in ['Hx','Hz','Gx','Gz']:
                        pp=p[:-6]+kind+'.txt';rr=subprocess.check_output(['git','show',ref['sha']+':'+pp],cwd=ROOT)
                        (dd/Path(pp).name).write_bytes(rr);hashes[kind]=hashlib.sha256(rr).hexdigest()
                    n,m=read_code(dd,stem);val=validate(n,m)
                    nn,own=read_code(ROOT/'data/matrices/untiered',f'TILE_{c["n"]}_{c["k"]}_unknown')
                    if (n,val['k'])!=(nn,c['k']):raise ValueError('peer dimensions disagree')
                    direct=equal_space(own[0],m[0]) and equal_space(own[1],m[1])
                    swap=equal_space(own[0],m[1]) and equal_space(own[1],m[0])
                    if direct or swap:raise ValueError('duplicate peer')
                    out.append(dict(case=f'TILE_{c["n"]}_{c["k"]}_unknown',peer=stem,ref=ref,path=p,sha256=hashes,direct=direct,swap=swap,checks=val))
    if len(out)!=1 or out[0]['peer']!='TN_288_8_unknown':raise ValueError('new peer requires permutation review')
    r=dict(ref_count=len(refs),scope='all tier0..5 and untiered same-n-k code inventories at pinned main/library refs; content-identical peers deduplicated',peers=out,permutation_review='tanner-peer-review.json proves sole peer inequivalent')
    expected=json.loads((raw/'cross-branch-review.json').read_text())
    if r!=expected:raise ValueError('pinned inventory receipt changed')
    print('PASS',len(refs),'pinned refs and sole physically inequivalent TN288 peer')

if __name__=='__main__':main()
