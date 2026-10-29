#!/usr/bin/env python3
"""Read pinned mathematical JSON inputs only; never unpack/run source programs.

Original source files stay in the chosen external cache, not the library.
"""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.request
from validate_quaternary_pp import facts

COMMIT='04ad4795ad15cb89ee47b7868ff925c30b2fc731'


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--cache',type=Path,required=True);ap.add_argument('--fetch',action='store_true');ap.add_argument('--out',type=Path,required=True);a=ap.parse_args()
    cases=json.loads(Path(__file__).with_name('quaternary_pp_cases.json').read_text());a.cache.mkdir(parents=True,exist_ok=True);containers={};records=[]
    for c in cases:
        name=c['source_container']
        if name not in ('catalogue.json','proofs/noncyclic_pp.json'):raise ValueError('unrecognized mathematical source container')
        if name not in containers:
            path=a.cache/name
            if not path.exists():
                if not a.fetch:raise FileNotFoundError(path)
                url='https://raw.githubusercontent.com/yeon-lee/public-regular-logical-frames/'+COMMIT+'/'+name
                raw=urllib.request.urlopen(url,timeout=60).read(16777217)
            else:raw=path.read_bytes()
            if len(raw)>16777216 or hashlib.sha256(raw).hexdigest()!=c['source_sha256'] or hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()!=c['source_blob']:raise ValueError('source container identity differs')
            if not path.exists():path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(raw)
            containers[name]=json.loads(raw)
        source=containers[name]
        if name=='catalogue.json':
            obj=next(x for x in source['constructions'] if x['path']==c['source_record'])['code'];co=obj['construction']
            got=dict(C=co['coefficients'],E=co['exponents'],group_moduli=[obj['group']['order']],row_choices=co.get('row_choices',[[0,1]]*3),source_witness_Z=next(w['support'] for w in obj['witnesses'] if w['sector']=='Z'))
            if (obj['id'],obj['n'],obj['k'],obj['distance']['lower'],obj['distance']['upper'])!=(c['source_id'],c['n'],c['k'],c['d'],c['d']):raise ValueError('source catalogue identity/claim differs')
        else:
            obj=next(x['content'] for x in source['records'] if c['source_record'] in x['paths'])
            if obj['group']!='C16xC2' or (obj['n'],obj['k'])!=(512,128):raise ValueError('wrong product-group record')
            got=dict(C=obj['C'],E=obj['E'],group_moduli=[16,2],row_choices=[[0,1]]*3,source_witness_Z=obj['witness_Z'])
        if got!=facts(c) or hashlib.sha256(json.dumps(got,sort_keys=True,separators=(',',':')).encode()).hexdigest()!=c['parameter_projection_sha256']:raise ValueError('mathematical facts differ')
        records.append(dict(source_id=c['source_id'],container=name,virtual_record=c['source_record'],source_blob=c['source_blob'],source_sha256=c['source_sha256'],projection_sha256=c['parameter_projection_sha256'],result='PASS numeric facts only; external exact lower claims not verified here'))
    text=json.dumps(records,indent=2)+'\n';a.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
