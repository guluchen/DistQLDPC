#!/usr/bin/env python3
"""Replay the one authorized CC500 observation, never execute a solver."""
import hashlib
import json
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).parent))
import cc500


def main():
    raw=cc500.RAW/'authorized-cc500'
    meta=json.loads((raw/'identity.json').read_text())
    cc500.require(meta['engine']=='cc' and meta['input_sha256']==cc500.EXPECTED,'frozen diagnostic identity changed')
    cc500.require(meta['source_head']=='bf892dbc5113804b65fe822756b7457320dda68e','diagnostic source changed')
    cc500.require(meta['original_src_tree']==cc500.ORIGINAL_SRC_TREE
                  and meta['original_makefile_blob']==cc500.ORIGINAL_MAKEFILE_BLOB,'original tree identities changed')
    cc500.require(meta['binary_sha256']==meta['original_binary_sha256'],'diagnosis used a different binary')
    cc500.require('-engine=cc' in meta['cmd'] and '-cpu-lim=60' in meta['cmd']
                  and '-seed=0' in meta['cmd'] and '-v' in meta['cmd']
                  and meta['cmd'][-1]=='data/matrices/untiered/quarantine/GH-202/'+cc500.STEM,
                  'diagnostic command changed')
    cc500.require(not meta['runner_backstop'],'diagnostic timed out at runner backstop')
    cc500.verify_solver_sources()
    result=cc500.assess((raw/'cc500.log').read_text(),meta['rc'])
    cc500.require(json.dumps(result,indent=2)+'\n'==(raw/'audit.json').read_text(),'retained diagnosis changed')
    receipt=Path(__file__).with_name('retained-sha256.json')
    for name,digest in json.loads(receipt.read_text()).items():
        path=cc500.ROOT/name
        cc500.require(hashlib.sha256(path.read_bytes()).hexdigest()==digest,'retained diagnostic file changed: '+name)
    print('PASS same4input hashes/samebinary: MaxSAT8 and authorizedCC8; source6 remains unreproduced; no new solver run')


if __name__=='__main__':main()
