from pathlib import Path
import subprocess,json,hashlib
root=Path(__file__).resolve().parent
repo=root.parent/'GH48-ISA-V2'
merge='22d1af454adacb81446044d13d03de62e9b024d5'
production='d27cf4d54bc08c6db4b2ffcebfe0372417bb13ef'
base='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
def git(*args):return subprocess.check_output(['git','-c','gc.auto=0','-c','pack.threads=1','-C',str(repo),*args])
paths=git('ls-tree','-r','--name-only',production,'src').decode().splitlines()+['Makefile']
proof=[]
for p in paths:
 a=git('show',merge+':'+p);b=git('show',production+':'+p)
 assert a==b,p
 if p.startswith('src/'):assert a==git('show',base+':'+p),p
 proof.append({'path':p,'sha256':hashlib.sha256(a).hexdigest(),'merge_blob':git('rev-parse',merge+':'+p).decode().strip()})
expected='451d63d84f4d55472d6eba77500175eec12035c63f2b1637381b5739afe20c38'
assert hashlib.sha256((root/'artifact.zip').read_bytes()).hexdigest()==expected
result=json.loads((root/'extracted/result.json').read_text());gate=json.loads((root/'extracted/isa-gate.json').read_text())
assert gate['compatible'] and gate['level']=='x86-64-v2'
assert result['scientific_semantics_match'] and len(result['rows'])==4
for r in result['rows']:
 assert r['same_semantics']; truth=4 if r['stem']=='LP_136_32_4' else 10
 for v in ['baseline','candidate']:
  x=r[v];assert x['returncode']==0 and not x['timed_out']
  assert all(x[k]==truth for k in ['d_lb','d_ub','d','objective'])
log=(root/'job.log').read_text(encoding='utf-8')
assert 'Merge 5f9a4522ad53b480ec75fe3d38cf7d7bdd361c42 into '+base in log
assert log.index('{"compatible":true')<log.index('g++ -Isrc/solver -Wall')
audit={'status':'PASS','scope':'hosted source identity and eight final scientific results, no performance inference','merge':merge,'production':production,'baseline':base,'artifact_id':11580311686,'artifact_sha256':expected,'ordinary_ci':37846104241,'crossrepo_ci':37846104190,'job':113547252432,'gate':gate,'source_files':proof,'limitation':'Source Git blob equality does not assert Linux/Windows binary or build reproducibility.'}
(root/'audit.json').write_text(json.dumps(audit,indent=2)+'\n',encoding='utf-8')
print('HOSTED_SOURCE_SCIENCE_PASS',len(proof),'source files; 8 final results; no timing conclusion')
