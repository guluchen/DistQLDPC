"""Complete pending H010 local smoke/pilot/timeout checks, without retraining."""
import hashlib,importlib.util,json,os,re,shutil,subprocess,sys,time
from pathlib import Path
root=Path.cwd().resolve();tree=root/'GH16-PGO';prior=root/'GH16-windows-preparation-04';out=root/'GH16-windows-tier0-followup-01';out.mkdir(exist_ok=False)
rt=root/'E004-windows-runtime/cygwin/bin';pkg=root/'E004-windows-tier2-02/E004-server-package'
sys.path.insert(0,str(root/'DistQLDPC/optimization/experiments/E004'))
from windows_cpu_window import Window,ticks
save=lambda n,v:(out/n).write_text(json.dumps(v,indent=2),encoding='utf8',newline='\n')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
shutil.copy2(Path(__file__),out/'executed-driver.py')
os.environ['PATH']=str(rt)+os.pathsep+os.environ['PATH'];os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
binaries={v:prior/(v+'.exe') for v in ['baseline','default-off','candidate']}
for v,p in binaries.items():assert sha(p)==json.loads((prior/'binary-hashes.json').read_text())[v]
assert json.loads((prior/'profile-completeness.json').read_text())['status']=='PASS'
manifest=json.loads((pkg/'manifest.json').read_text())
for rel,digest in manifest['files'].items():assert sha(pkg/rel)==digest,rel
def cyg(x):
 s=str(x).replace('\\','/')
 return '/cygdrive/'+s[0].lower()+s[2:] if len(s)>2 and s[1]==':' else s
w=None;process=None;resources=[];summary={'status':'INCONCLUSIVE','performance':'NOT_RUN','hosted':'PENDING'}
def run(cmd,label,timeout=70):
 global process
 actual=[str(cmd[0])]+[cyg(x) for x in cmd[1:]];print('START '+label,flush=True)
 w.previous=ticks();time.sleep(1);row=w.observe(label+'-preflight');resources.append(row);save('resources.json',resources)
 if not row['eligible']:raise RuntimeError('Capacity guard '+label)
 save(label+'.command.json',{'argv':actual,'cwd':str(tree),'returncode':None})
 start=last=time.monotonic()
 with (out/(label+'.stdout')).open('w',encoding='utf8') as so,(out/(label+'.stderr')).open('w',encoding='utf8') as se:
  process=subprocess.Popen(actual,cwd=tree,stdout=so,stderr=se)
  while process.poll() is None:
   time.sleep(.25)
   if time.monotonic()-last>=2:
    row=w.observe(label);resources.append(row);save('resources.json',resources);last=time.monotonic()
    if not row['eligible']:raise RuntimeError('Capacity guard '+label)
   if time.monotonic()-start>timeout:raise RuntimeError('Watchdog '+label)
 save(label+'.command.json',{'argv':actual,'cwd':str(tree),'returncode':process.returncode})
 return subprocess.CompletedProcess(actual,process.returncode,(out/(label+'.stdout')).read_text(),(out/(label+'.stderr')).read_text())
try:
 w=Window(True,0x8000);save('environment.json',{'affinity':w.selection,'prior':str(prior),'binary_sha256':{v:sha(p) for v,p in binaries.items()},'baseline_archive_sha256':sha(root/'GH16-baseline-source.tar'),'tools_sha256':{n:sha(rt/n) for n in ['g++.exe','gcov.exe','make.exe','bash.exe']},'source_sha256':{str(p.relative_to(tree)):sha(p) for p in (tree/'src').rglob('*') if p.is_file()},'qdistsat_manifest':manifest})
 p=run([rt/'bash.exe','-n',tree/'scripts/pgo_train_build.sh'],'shell-syntax');assert p.returncode==0,p.stderr
 for v,b in binaries.items():
  p=run([rt/'bash.exe',tree/'scripts/smoke_test.sh',b],'smoke-'+v,timeout=15);assert p.returncode==0,p.stdout+p.stderr
 spec=importlib.util.spec_from_file_location('pilot',pkg/'qdistsat/benchmarks/compare_distqldpc_binaries.py');pilot=importlib.util.module_from_spec(spec);sys.modules['pilot']=pilot;spec.loader.exec_module(pilot)
 original=subprocess.run;rows=[]
 for stem in ['LP_136_32_4','BB_108_8_10']:
  for mode,flag in pilot.CONFIGS:
   pair=[]
   for v in ['baseline','candidate']:
    def captured(cmd,**kwargs):return run(cmd,'pilot-'+stem+'-'+mode+'-'+v)
    subprocess.run=captured
    try:r=pilot.run_one(binaries[v],pilot.matrix_prefix(pkg/'qdistsat/data',stem),stem,mode,flag,45)
    finally:subprocess.run=original
    pair.append(r)
   assert all(r.returncode==0 and r.d is not None and not r.timed_out for r in pair),'Pilot incomplete/crash'
   assert pair[0].semantic_result==pair[1].semantic_result,'SCIENCE_MISMATCH QDistSAT'
   rows.append({'stem':stem,'mode':mode,'runs':[vars(r) for r in pair]});save('cross-repo.json',rows)
 for v,b in binaries.items():
  for mode in ['no-card','card-mto']:
   p=run([b,'-cpu-lim=1','-'+mode,pkg/'baseline/data/matrices/BB_108_8_10'],'timeout-'+v+'-'+mode,timeout=20)
   assert p.returncode==1 and 's UNKNOWN' in p.stdout and 'c status: TIMEOUT' in p.stdout,'SCIENCE_MISMATCH timeout '+p.stdout
   assert not re.search(r'^o\s+\d+\s*$',p.stdout,re.M),'SCIENCE_MISMATCH timeout optimum'
   assert all(int(v)<=10 for v in re.findall(r'^c\s+d_lb:\s*(\d+)',p.stdout,re.M)),'SCIENCE_MISMATCH lower bound'
   assert all(int(v)>=10 for v in re.findall(r'^c\s+d_ub:\s*(\d+)',p.stdout,re.M)),'SCIENCE_MISMATCH upper bound'
 summary.update(status='PASS',local_tier0='PASS',reason='prior valid engine profiles/hook absence/CSS/WCNF plus smoke, pinned actual PGO candidate cross-repo pilot and unchanged timeout results; hosted checks still required')
except AssertionError as e:
 summary.update(status='REJECTED',reason=str(e));raise
except Exception as e:
 summary.update(reason=repr(e));raise
finally:
 if process is not None and process.poll() is None:
  p=subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],capture_output=True,text=True);save('kill.json',vars(p));process.wait(timeout=15)
 if w is not None:save('cleanup.json',w.close())
 save('summary.json',summary);print(json.dumps(summary),flush=True)
