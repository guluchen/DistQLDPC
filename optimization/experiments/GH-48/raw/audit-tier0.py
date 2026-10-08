from pathlib import Path
import json,hashlib,re,itertools,subprocess
root=Path(__file__).resolve().parent;o=root/'GH48-windows-tier0-01'
load=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
s=load(o/'summary.json');pre=load(o/'preexecution.json');raw=load(o/'SHA256.json')
assert pre['production_candidate']=='d27cf4d54bc08c6db4b2ffcebfe0372417bb13ef'
assert pre['assignment']=='https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069265947'
gate=load(o/'isa-gate.json');assert gate['cpuid']['compatible'] and gate['cpuid']['level']=='x86-64-v2'
assert gate['cpu']==load(o/'window.json')['selected_cpu']
assert s['valid_run'] and s['Tier0']=='LOCAL_PASS'
assert pre['record_head']=='5f9a4522ad53b480ec75fe3d38cf7d7bdd361c42'
assert pre['driver_sha256']=='fba3d71d83b874640e15ffb3dd532b3d771d801f5eb113f345d9160d539a37db'
for p,h in raw.items():assert sha(o/p)==h,p
for p,h in load(o/'artifact-pins.json').items():assert sha(Path(p))==h,p
assert load(o/'runtime-post-file-set.json')=={'pre_count':10216,'post_count':10216,'identical':True,'added':[],'removed':[]}
assert all(s['cleanup'][k] is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
assert len(load(o/'job-pids-before-release.json'))==1
assert load(o/'POST-EXIT.json')['exact_matching_runner_absent']
for p in o.glob('owned-cleanup-*.json'):
 x=load(p);assert x['remaining']==[] and x['confirmed']
def bits(p):return [sum(int(x)<<i for i,x in enumerate(line.split())) for line in p.read_text().splitlines() if line.strip() and not line.startswith('#')]
truth={}
for stem,n in [('css1',1),('css4',4),('css5',5)]:
 hx,hz,gx,gz=[bits(o/(stem+'_'+x+'.txt')) for x in ['Hx','Hz','Gx','Gz']]
 truth[stem]=min((x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if all((h&z).bit_count()%2==0 for h in hx) and all((h&x).bit_count()%2==0 for h in hz) and (any((g&z).bit_count()%2 for g in gx) or any((g&x).bit_count()%2 for g in gz)))
def fields(text,exact,complete):
 pats={'lb':r'^c\s+d_lb:\s*(.*?)\s*$','ub':r'^c\s+d_ub:\s*(.*?)\s*$','d':r'^c\s+d\s*:\s*(.*?)\s*$','objective':r'^o(?:\s+(.*?))?\s*$'}
 for k,p in pats.items():
  vals=re.findall(p,text,re.M)
  if complete:assert vals and vals[-1]==str(exact),(k,vals)
  for v in vals:
   if v=='-' and k in ['lb','ub']:continue
   if not complete and v=='UNKNOWN' and k=='d':continue
   assert re.fullmatch(r'\d+',v),(k,v)
   q=int(v);assert q<=exact if k=='lb' else q==exact if k=='d' else q>=exact
 for v in re.findall(r'^c\s+trying d:\s*(.*?)\s*$',text,re.M):assert re.fullmatch(r'\d+',v)
 if complete:assert not re.findall(r'^(?:s\s+|c status:)',text,re.M)
 else:
  assert re.findall(r'^s\s+(.*?)\s*$',text,re.M)==['UNKNOWN']
  comments=re.findall(r'^c status:\s*(.*?)\s*$',text,re.M);assert len(comments)==1 and comments[0].startswith('TIMEOUT')
  assert re.findall(r'^c\s+d\s*:\s*(.*?)\s*$',text,re.M)==['UNKNOWN'] and not re.search(r'^o(?:\s|$)',text,re.M)
science=0;smokes=0;pms=0;timeouts=0;pairs={};commands=list(o.glob('*.command.json'))
for p in commands:
 c=load(p);label=p.name.removesuffix('.command.json');t=p.with_name(label+'.stdout').read_text(encoding='utf8');e=p.with_name(label+'.stderr').read_bytes()
 assert c['owned_descendants_remaining']==[],label
 if label.startswith('css') and not label.endswith('-dump'):
  assert c['returncode']==0 and not e;fields(t,truth[label.split('-')[0]],True);science+=1
 elif label.startswith('smoke-'):
  assert c['returncode']==0 and not e and t.strip()=='DistQLDPC smoke validation passed';smokes+=1
 elif label.startswith('production-trace-'):
  exact=4 if 'LP_136' in label else 2
  assert c['returncode']==0 and not e;fields(t,exact,True);science+=1
 elif label.startswith('timeout-') or '-timeout-' in label:
  exact=8 if label.startswith('timeout-') else 2
  assert c['returncode']==1 and not e;fields(t,exact,False);science+=1;timeouts+=1
  u=re.findall(r'^c\s+d_ub:\s*(\d+)\s*$',t,re.M)
  if 'post-model' in label:assert u
  if 'pre-search' in label:assert not u
 elif label.startswith('pms-'):
  w=c['argv'][-1];p=Path('C:/'+w[len('/cygdrive/c/'):]) if w.startswith('/cygdrive/c/') else Path(w)
  ls=[x.split() for x in p.read_text().splitlines() if x.strip() and not x.startswith('c')];n=int(ls[0][2]);top=int(ls[0][4]);cs=[(int(x[0]),list(map(int,x[1:-1]))) for x in ls[1:]]
  sat=lambda clause,a:any(bool(a&(1<<(abs(l)-1)))==(l>0) for l in clause)
  opt=min(sum(w for w,cl in cs if w<top and not sat(cl,a)) for a in range(1<<n) if all(sat(cl,a) for w,cl in cs if w==top))
  vals=re.findall(r'optimal:\s*([^,\r\n]*)',t);assert vals and all(v.strip()==str(opt) for v in vals)
  status=re.findall(r'^s\s+(.*?)\s*$',t,re.M);assert c['returncode'] in [10,20] and status==[{10:'SATISFIABLE',20:'UNSATISFIABLE'}[c['returncode']]]
  stem,v=label.rsplit('-',1);pairs.setdefault(stem,{})[v]=(c['returncode'],status,[int(x.strip()) for x in vals]);pms+=1
assert (science,smokes,pms,timeouts)==(50,2,72,12),(science,smokes,pms,timeouts)
assert len(pairs)==36 and all(x['baseline']==x['candidate'] for x in pairs.values())
dumps=0
for stem in truth:
 for mode in ['no-card','card-sinz','card-mto','card-both-force','default']:
  assert (o/(stem+'-'+mode+'-baseline.wcnf')).read_bytes()==(o/(stem+'-'+mode+'-candidate.wcnf')).read_bytes();dumps+=1
assert dumps==15 and len(load(o/'science.json'))==50
res=load(o/'resources.json');assert all(x['eligible'] for x in res)
win=load(o/'window.json');assert win['original_affinity']==65535 and win['priority_class']==32768
for a in load(o/'descendants.json'):
 for x in a['records']:assert x['mask']==win['mask'] and x['priority_class']==32768
runtime=root/'E004-windows-runtime/cygwin';rt=load(root/'GH48-ISA-V2/optimization/experiments/GH-48/runtime-original.json')
for p,h in rt.items():assert sha(runtime/p)==h,p
assert {p.relative_to(runtime).as_posix() for p in runtime.rglob('*') if p.is_file()}==set(rt)
audit={'status':'LOCAL_TIER0_AUDIT_PASS','original_raw_files':len(raw),'commands':len(commands),'app_science_streams':50,'smoke_streams':2,'PMS_solves':72,'PMS_independent_cases':36,'WCNF_pairs':15,'genuine_timeouts':12,'all_interim_fields_checked':True,'runtime_files':len(rt),'resource_samples':len(res),'resource_flags':sum(x['core_contention_detected'] for x in res),'window':win,'binary_hashes':load(o/'binary-hashes.json'),'support':pre['record_head'],'driver_sha256':pre['driver_sha256'],'performance':'NOT_MEASURED','limitation':'No exclusive OS reservation; this correctness audit does not establish speedup or portable deployment; no binary build reproducibility claim.'}
(o/'AUDIT.json').write_text(json.dumps(audit,indent=2)+'\n',encoding='utf8');print(json.dumps(audit))
