"""One-worker H010 builds/training/Tier0. Not a performance benchmark."""
import gzip, hashlib, itertools, json, os, re, shutil, subprocess, sys, tarfile, time
from pathlib import Path
root=Path.cwd().resolve(); tree=root/'GH16-PGO'; out=root/(sys.argv[1] if len(sys.argv)>1 else 'GH16-windows-preparation-01')
assert out.resolve().parent==root
runtime=root/'E004-windows-runtime/cygwin'
sys.path.insert(0,str(root/'DistQLDPC/optimization/experiments/E004'))
from windows_cpu_window import Window,ticks
out.mkdir(exist_ok=False)
shutil.copy2(Path(__file__),out/'executed-driver.py')
save=lambda n,v:(out/n).write_text(json.dumps(v,indent=2),encoding='utf8',newline='\n')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
os.environ['PATH']=str(runtime/'bin')+os.pathsep+os.environ['PATH']
os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1',GCOV_EXIT_AT_ERROR='1')
def cyg(v):
 s=str(v).replace('\\','/')
 for pre in ('PGO_DIR=','-dump-wcnf='):
  if s.startswith(pre):return pre+cyg(s[len(pre):])
 return '/cygdrive/'+s[0].lower()+s[2:] if len(s)>2 and s[1]==':' else s
window=None;process=None;resources=[];summary={'status':'INCONCLUSIVE','performance':'NOT_RUN'}
def run(argv,label,cwd=tree,timeout=300):
 global process
 actual=[str(argv[0])]+[cyg(v) for v in argv[1:]]
 print('START '+label,flush=True)
 window.previous=ticks();time.sleep(1)
 row=window.observe(label+'-preflight');resources.append(row);save('resources.json',resources)
 if not row['eligible']:raise RuntimeError('Resource preflight: '+label)
 start=time.monotonic();last=start
 save(label+'.command.json',{'argv':actual,'cwd':str(cwd),'returncode':None})
 with (out/(label+'.stdout')).open('w',encoding='utf8') as so,(out/(label+'.stderr')).open('w',encoding='utf8') as se:
  process=subprocess.Popen(actual,cwd=cwd,stdout=so,stderr=se)
  while process.poll() is None:
   time.sleep(.25)
   if time.monotonic()-last>=2:
    row=window.observe(label);resources.append(row);save('resources.json',resources);last=time.monotonic()
    if not row['eligible']:raise RuntimeError('Resource active guard: '+label)
   if time.monotonic()-start>timeout:raise RuntimeError('Watchdog: '+label)
 save(label+'.command.json',{'argv':actual,'cwd':str(cwd),'returncode':process.returncode})
 p=subprocess.CompletedProcess(actual,process.returncode,(out/(label+'.stdout')).read_text(encoding='utf8'),(out/(label+'.stderr')).read_text(encoding='utf8'))
 if p.returncode:raise RuntimeError('Command failed '+label+': '+p.stderr[-1800:])
 print('DONE '+label,flush=True)
 return p
def clean_generated():
 b=(tree/'build').resolve();assert b.parent==tree and not (tree/'build').is_symlink()
 if b.exists():shutil.rmtree(b)
 for name in ('distqldpc','distqldpc.exe','maxcdcl','maxcdcl.exe'):
  p=tree/'bin'/name;assert p.resolve().parent==tree/'bin'
  if p.exists():p.unlink()
def semantic(text):
 pats=[r'^c\s+d\s*:\s*(\d+)\s*$',r'^o\s+(-?\d+)\s*$',r'^c\s+d_lb:\s*(\d+)\s*$',r'^c\s+d_ub:\s*(\d+)\s*$']
 return tuple(int(re.findall(p,text,re.M)[-1]) if re.findall(p,text,re.M) else None for p in pats)
try:
 window=Window(True,0x8000)
 save('environment.json',{'affinity':window.selection,'invocation':sys.argv,'driver_sha256':sha(Path(__file__)),'baseline':'24572d6d09cce9a4a5faa58300a89e0feba9da6a','source_hashes':{str(p.relative_to(tree)):sha(p) for p in [tree/'Makefile',tree/'src/core/distqldpc.cc',tree/'src/solver/Solver.cc',tree/'src/solver/SimpSolver.cc']}})
 baseline=out/'baseline';baseline.mkdir()
 with tarfile.open(root/'GH16-baseline-source.tar') as t:t.extractall(baseline,filter='data')
 run([runtime/'bin/g++.exe','--version'],'compiler')
 run([runtime/'bin/make.exe','-j1','bin/distqldpc'],'build-baseline',cwd=baseline,timeout=420)
 shutil.copy2(baseline/'bin/distqldpc.exe',out/'baseline.exe')
 clean_generated()
 run([runtime/'bin/make.exe','-j1','PGO=off','bin/distqldpc'],'build-default-off',timeout=420)
 shutil.copy2(tree/'bin/distqldpc.exe',out/'default-off.exe')
 clean_generated()
 profile=tree/'pgo-data';assert not profile.exists(),'Do not merge stale training profiles'
 run([runtime/'bin/make.exe','-j1','PGO=generate','PGO_DIR='+str(profile),'bin/distqldpc'],'build-training',timeout=420)
 training=[]
 for stem,exact in [('LP_34_20_2',2),('LP_136_32_4',4)]:
  for mode in ['no-card','card-mto']:
   p=run([tree/'bin/distqldpc.exe','-v','-cpu-lim=120','-'+mode,stem],'train-'+stem+'-'+mode,timeout=135)
   assert semantic(p.stdout)==(exact,exact,exact,exact), 'Training science mismatch: '+p.stdout
   training.append({'stem':stem,'mode':mode,'result':semantic(p.stdout),'input_sha256':{suffix:sha(tree/'data/matrices'/f'{stem}_{suffix}.txt') for suffix in ['Hx','Hz','Gx','Gz']}})
 save('training.json',training)
 gcda=list(profile.glob('*.gcda'));assert len(gcda)==4, 'Missing engine profiles: '+str(gcda)
 for p in gcda:
  name=p.name.split('#')[-1];assert name in ('Solver.gcda','SimpSolver.gcda','Options.gcda','System.gcda'),name
  shutil.copy2(p,tree/'build'/name)
 p=run([runtime/'bin/gcov.exe','--json-format','-o','build','src/solver/Solver.cc'],'solver-coverage')
 reports=list(tree.glob('*.gcov.json.gz'));assert reports,'No gcov reports'
 functions=[]
 for p in reports:
  report=json.loads(gzip.decompress(p.read_bytes()));shutil.copy2(p,out/p.name)
  for f in report.get('files',[]):
   functions.extend(f.get('functions',[]))
 counts={n:sum(f.get('execution_count',0) for f in functions if n in f.get('demangled_name',f.get('name',''))) for n in ['Minisat::Solver::search','Minisat::Solver::propagate']}
 assert all(counts.values()), 'Solver counters missing/nonzero prerequisite: '+str(counts)
 save('profile-completeness.json',{'status':'PASS','counts':counts,'profiles':{p.name:sha(p) for p in gcda}})
 frozen={p.name:sha(p) for p in gcda}
 shutil.copytree(profile,out/'profiles');shutil.copytree(tree/'build',out/'training-build')
 clean_generated()
 run([runtime/'bin/make.exe','-j1','PGO=use','PGO_DIR='+str(profile),'bin/distqldpc'],'build-pgo-use',timeout=420)
 assert frozen=={p.name:sha(p) for p in profile.glob('*.gcda')},'Frozen profile changed'
 shutil.copy2(tree/'bin/distqldpc.exe',out/'candidate.exe')
 p=run([runtime/'bin/nm.exe',tree/'bin/distqldpc.exe'],'production-symbols')
 assert '__gcov_' not in p.stdout,'Training gcov hook/runtime in final binary'
 binaries={'baseline':out/'baseline.exe','default-off':out/'default-off.exe','candidate':out/'candidate.exe'}
 save('binary-hashes.json',{v:sha(p) for v,p in binaries.items()})
 def span(rows):
  s={0}
  for r in rows:s|={x^r for x in s}
  return s
 for stem,n,hx,hz,gx,gz in [('css1',1,[0],[0],[1],[1]),('css4',4,[15],[15],[3,5],[3,5]),('css5',5,[3],[3],[12,24,28],[12,24,28])]:
  exact=min((x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if not any((r&z).bit_count()%2 for r in hx) and not any((r&x).bit_count()%2 for r in hz) and (x not in span(hx) or z not in span(hz)))
  for suffix,rows in zip(['Hx','Hz','Gx','Gz'],[hx,hz,gx,gz]):(out/f'{stem}_{suffix}.txt').write_text(''.join(' '.join(str((r>>i)&1) for i in range(n))+'\n' for r in rows),encoding='utf8')
  for mode in ['no-card','card-mto']:
   dumps=[]
   for v,b in binaries.items():
    p=run([b,'-v','-cpu-lim=5','-'+mode,out/stem],stem+'-'+mode+'-'+v,timeout=15)
    assert semantic(p.stdout)==(exact,exact,exact,exact),'CSS science mismatch '+p.stdout
    dest=out/f'{stem}-{mode}-{v}.wcnf'
    run([b,'-dump-only','-'+mode,'-dump-wcnf='+str(dest),out/stem],stem+'-'+mode+'-'+v+'-dump',timeout=15);dumps.append(dest.read_bytes())
   assert len(set(dumps))==1,'Original WCNF changed'
 for v,b in binaries.items():
  run([runtime/'bin/bash.exe',tree/'scripts/smoke_test.sh',b],'smoke-'+v,timeout=15)
 summary.update(status='PASS',reason='build/profile completeness, production hook absence, exhaustive small CSS distances, identical original WCNFs and smoke; hosted/pilot/timeout checks pending',hosted='PENDING',tier0='PARTIAL_PASS')
except AssertionError as e:
 reason=str(e)
 scientific=any(x in reason for x in ('science mismatch','Original WCNF changed'))
 summary.update(status='REJECTED' if scientific else 'INCONCLUSIVE',reason=reason,semantic_mismatch=scientific);raise
except Exception as e:
 summary.update(reason=repr(e));raise
finally:
 if process is not None and process.poll() is None:
  p=subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],capture_output=True,text=True);save('kill.json',{'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr});process.wait(timeout=15)
 if window is not None:save('cleanup.json',window.close())
 save('summary.json',summary);print(json.dumps(summary),flush=True)
