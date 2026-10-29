#!/usr/bin/env python3
"""No-network pinned same-(n,k) inventory replay; missing objects are errors."""
import json
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[4]
def main():
    raw=Path(__file__).parent;refs=json.loads((raw/'peer-refs.json').read_text());cases=json.loads((raw/'construction.json').read_text());peers=[]
    for ref in refs:
        paths=subprocess.check_output(['git','ls-tree','-r','--name-only',ref['sha'],'data/matrices'],cwd=ROOT,text=True).splitlines()
        for p in paths:
            if p.endswith('_Hx.txt') and Path(p).name.split('_')[1:3] in [[str(c['n']),str(c['k'])] for c in cases]:peers.append(dict(ref=ref,path=p))
    if peers:raise ValueError('new same-n-k peer requires rowspace/permutation review: '+str(peers))
    result=dict(ref_count=len(refs),scope='tier0..5 and untiered inventories at pinned main/library refs',same_n_k_peers=peers)
    target=raw/'cross-branch-review.json'
    if target.exists() and json.loads(target.read_text())!=result:raise ValueError('inventory receipt differs')
    target.write_text(json.dumps(result,indent=2)+'\n');print('PASS',len(refs),'pinned refs; no same(n,k)peers')
if __name__=='__main__':main()
