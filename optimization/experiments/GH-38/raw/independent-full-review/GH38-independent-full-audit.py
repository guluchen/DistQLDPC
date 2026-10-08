from pathlib import Path
import json,hashlib,re,itertools,subprocess
r=Path(__file__).parent;o=r/'GH38-windows-tier0-01';repo=r/'GH38-CLANG';rec=repo/'optimization/experiments/GH-38'
load=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
identity=load(o/'identity.json');summary=load(o/'summary.json')
assert summary['valid_run'] and summary['Tier0']=='LOCAL_PASS'
assert identity['candidate']=='09d432f99f37bd2592bcb820475eee3e8ddbff4a'
assert identity['runner_sha256']=='ac13d8063b569b343cf59f610c2838c608b45bf92f8ea9782b0ba837823d5a00'
raw=load(o/'SHA256.json')
for name,want in raw.items():assert sha(o/name)==want,name
for name,want in identity['source_hashes'].items():assert sha(repo/name)==want,name
for name,want in identity['support_hashes'].items():assert sha(rec/name)==want,name
for name,want in load(o/'pretest-binary-hashes.json').items():assert sha(Path(name))==want,name
assert load(o/'overlay-before.json')==load(o/'overlay-after.json')
assert load(o/'owned-cleanup-56.json')['remaining']==[]
assert load(o/'POST-EXIT.json')['exact_matching_runner_absent']
assert all(summary['cleanup'][x] is True for x in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
assert subprocess.check_output(['git','-C',str(repo),'diff','24572d6',identity['candidate'],'--','src'])==b''
for name,want in identity['preimport_support_hashes'].items():
 p=rec/name if name!='windows_cpu_window.py' else r/'DistQLDPC/optimization/experiments/E004/windows_cpu_window.py'
 assert sha(p)==want,name
base=r/'E004-windows-tier2-02/E004-server-package/baseline'
for name,want in identity['input_hashes'].items():assert sha(base/'data/matrices'/name)==want,name
def fields(text,truth,complete):
 pats={'lb':r'^c\s+d_lb:\s*(.*?)\s*$','ub':r'^c\s+d_ub:\s*(.*?)\s*$','d':r'^c\s+d\s*:\s*(.*?)\s*$','objective':r'^o(?:\s+(.*?))?\s*$'}
 for k,p in pats.items():
  vals=re.findall(p,text,re.M)
  if complete:assert vals and vals[-1]==str(truth),(k,vals)
  for v in vals:
   if v=='-' and k in ['lb','ub']:continue
   if not complete and k=='d' and v=='UNKNOWN':continue
   assert re.fullmatch(r'\d+',v),(k,v)
   x=int(v);assert x<=truth if k=='lb' else x==truth if k=='d' else x>=truth
def bits(p):return [sum(int(x)<<i for i,x in enumerate(line.split())) for line in p.read_text().splitlines() if line.strip() and not line.startswith('#')]
def span(a):
 s={0}
 for x in a:s|={t^x for t in s}
 return s
tr={}
for stem,n in [('css1',1),('css4',4),('css5',5)]:
 hx,hz,gx,gz=[bits(o/'tier0'/(stem+'_'+s+'.txt')) for s in ['Hx','Hz','Gx','Gz']]
 tr[stem]=min((x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if all((h&z).bit_count()%2==0 for h in hx) and all((h&x).bit_count()%2==0 for h in hz) and (any((g&z).bit_count()%2 for g in gx) or any((g&x).bit_count()%2 for g in gz)))
 assert tr[stem] in [1,2]
science=0;dumps=0;pms=0;timeouts=0
commands=list(o.rglob('*.command.json'))
for p in commands:
 c=load(p);label=p.name.removesuffix('.command.json');text=p.with_name(label+'.stdout').read_text(encoding='utf8');err=p.with_name(label+'.stderr').read_bytes()
 assert c['owned_descendants_remaining']==[],label
 if label.startswith('css') and not label.endswith('-dump'):
  assert c['returncode']==0 and not err;fields(text,tr[label.split('-')[0]],True);science+=1
 elif label.startswith('smoke-'):
  assert c['returncode']==0 and not err;fields(text,2,True);science+=1
 elif label.startswith('timeout-'):
  assert c['returncode']==1 and not err;fields(text,8,False)
  statuses=re.findall(r'^c status:\s*(.+)$',text,re.M)
  assert re.findall(r'^s\s+(.+)$',text,re.M)==['UNKNOWN'] and len(statuses)==1 and statuses[0]=='TIMEOUT (child killed after -cpu-lim)'
  assert not re.search(r'^o\b',text,re.M)
  assert re.findall(r'^c\s+d\s*:\s*(.*?)\s*$',text,re.M)==['UNKNOWN'];timeouts+=1
 elif label.startswith('pms-'):
  rawpath=c['argv'][-1];wp=Path('C:/'+rawpath[len('/cygdrive/c/'):]) if rawpath.startswith('/cygdrive/c/') else Path(rawpath)
  lines=[x.split() for x in wp.read_text().splitlines() if x.strip() and not x.startswith('c')];_,_,n,nc,top=lines[0];n=int(n);top=int(top)
  cs=[(int(x[0]),list(map(int,x[1:-1]))) for x in lines[1:]]
  sat=lambda ls,a:any(bool(a&(1<<(abs(l)-1)))==(l>0) for l in ls)
  opt=min(sum(w for w,ls in cs if w<top and not sat(ls,a)) for a in range(1<<n) if all(sat(ls,a) for w,ls in cs if w==top))
  vals=re.findall(r'optimal:\s*([^,\r\n]*)',text);assert vals and all(v.strip()==str(opt) for v in vals)
  assert c['returncode'] in [10,20] and re.findall(r'^s\s+(.+)$',text,re.M)==[{10:'SATISFIABLE',20:'UNSATISFIABLE'}[c['returncode']]];pms+=1
for stem in tr:
 for mode in ['no-card','card-mto']:
  assert (o/'tier0'/f'{stem}-{mode}-baseline.wcnf').read_bytes()==(o/'tier0'/f'{stem}-{mode}-candidate.wcnf').read_bytes();dumps+=1
assert (science,dumps,pms,timeouts)==(16,6,8,4)
resources=load(o/'resources.json');assert all(x['eligible'] for x in resources)
assert all(x['mask']==identity['selection']['mask'] and x['priority_class']==32768 for v in load(o/'descendants.json') for x in v['records'])
result={'status':'INDEPENDENT_LOCAL_TIER0_SCIENCE_PROVENANCE_PASS','support':identity['candidate'],'raw_files_verified':len(raw),'command_records':len(commands),'complete_science':science,'WCNF_pairs':dumps,'PMS_oracles':pms,'genuine_timeouts':timeouts,'source_baseline_identical':True,'all_interim_bounds_checked':True,'cleanup_and_actual_exit':True,'actual_binary_hashes':load(o/'pretest-binary-hashes.json'),'resource_samples':len(resources),'resource_flags':sum(x['core_contention_detected'] for x in resources),'limit':'No performance, no deterministic post-model timeout in this registered scope; hosted exact production source check must independently be retained before Tier1.'}
(r/'GH38-independent-full-audit.json').write_text(json.dumps(result,indent=2),encoding='utf8',newline='\n')
print(json.dumps(result))
