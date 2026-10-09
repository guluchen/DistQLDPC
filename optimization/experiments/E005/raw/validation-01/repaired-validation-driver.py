"""One-worker E005 correctness/build validation; timings are not benchmarks."""
import argparse, hashlib, importlib.util, itertools, json, os, re, subprocess, sys, time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'E004'))
from windows_cpu_window import Window, ticks

root=Path.cwd(); candidate=root/'E005-SLS'
prior=root/'E004-windows-tier2-02'; pkg=prior/'E004-server-package'
ap=argparse.ArgumentParser();ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
runtime=root/'E004-windows-runtime/cygwin'; out=args.out.resolve()
out.mkdir(exist_ok=False)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
save=lambda name,value:(out/name).write_text(json.dumps(value,indent=2),encoding='utf8',newline='\n')
manifest=json.loads((pkg/'manifest.json').read_text(encoding='utf8'))
for rel,digest in manifest['files'].items(): assert sha(pkg/rel)==digest
assert sha(pkg/'baseline/bin/distqldpc.exe')=='22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815'
assert (runtime/'etc/setup/installed.db').read_bytes()==(Path(__file__).resolve().parents[1]/'E004/raw/windows-setup-2026-10-08/installed.db').read_bytes()
os.environ['PATH']=str(runtime/'bin')+os.pathsep+os.environ['PATH']
os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
def cyg(value):
 value=str(value).replace('\\','/')
 for prefix in ['-dump-wcnf=']:
  if value.startswith(prefix):return prefix+cyg(value[len(prefix):])
 return '/cygdrive/'+value[0].lower()+value[2:] if len(value)>2 and value[1]==':' else value
window=Window(True,0x8000) # correctness only: no quiet-core performance claim
resources=[]; process=None
def run(cmd,label,cwd=candidate,timeout=90):
 global process
 cmd=list(map(str,cmd)); actual=[cmd[0]]+list(map(cyg,cmd[1:]))
 with (out/(label+'.stdout')).open('w',encoding='utf8') as so,(out/(label+'.stderr')).open('w',encoding='utf8') as se:
  start=time.monotonic(); last=start; window.previous=ticks()
  process=subprocess.Popen(actual,cwd=cwd,stdout=so,stderr=se)
  while process.poll() is None:
   time.sleep(.25)
   if time.monotonic()-last>=2:
    resources.append(window.observe(label)); save('resources.json',resources); last=time.monotonic()
    if not resources[-1]['eligible']: raise RuntimeError('Spare-capacity guard: '+label)
   if time.monotonic()-start>timeout: raise RuntimeError('Watchdog: '+label)
 save(label+'.command.json',dict(argv=actual,cwd=str(cwd),returncode=process.returncode))
 text=(out/(label+'.stdout')).read_text(encoding='utf8')
 return subprocess.CompletedProcess(actual,process.returncode,text,(out/(label+'.stderr')).read_text(encoding='utf8'))
summary=dict(status='INCONCLUSIVE',reason='validation pending',performance='not measured')
try:
 save('environment.json',dict(invocation=sys.argv,affinity=window.selection,manifest=manifest,
      source_hashes={str(p.relative_to(candidate)):sha(p) for p in [candidate/'src/core/distqldpc.cc',candidate/'src/core/SlsWarmStart.h',candidate/'Makefile',candidate/'tests/sls_warm_probe.cc']},
      runtime_sha=sha(runtime/'etc/setup/installed.db')))
 p=run([runtime/'bin/g++.exe','--version'],'compiler'); assert p.returncode==0
 p=run([runtime/'bin/make.exe','-j1','bin/distqldpc'],'build-candidate',timeout=300)
 if p.returncode:raise RuntimeError('Build failed: '+p.stderr)
 p=run([runtime/'bin/g++.exe','-Isrc/solver','-O2','-std=gnu++11','tests/sls_warm_probe.cc','build/SimpSolver.o','build/Solver.o','build/Options.o','build/System.o','-lz','-o',out/'probe.exe'],'probe-build',timeout=120)
 if p.returncode:raise RuntimeError('Probe build failed: '+p.stderr)
 p=run([out/'probe.exe'],'probe',timeout=120); assert p.returncode==0 and 'SLS_PROBE_PASS' in p.stdout,p.stdout+p.stderr
 binaries={'baseline':pkg/'baseline/bin/distqldpc.exe','candidate':candidate/'bin/distqldpc.exe'}
 save('binary-hashes.json',{v:sha(p) for v,p in binaries.items()})
 def matrix(path,rows,n):path.write_text(''.join(' '.join(str((r>>i)&1) for i in range(n))+'\n' for r in rows),encoding='utf8')
 def semantic(text):
  pats=[r'^c\s+d\s*:\s*(\d+)\s*$',r'^o\s+(-?\d+)\s*$',r'^c\s+d_lb:\s*(\d+)\s*$',r'^c\s+d_ub:\s*(\d+)\s*$']
  return tuple(int(re.findall(p,text,re.M)[-1]) if re.findall(p,text,re.M) else None for p in pats)
 # Tiny independent stabilizer-span oracle, not benchmark-name ground truth.
 def span(rows):
  result={0}
  for r in rows: result|={x^r for x in result}
  return result
 fixtures=[('css1',1,[0],[0],[1],[1]),('css4',4,[15],[15],[3,5],[3,5]),('css5',5,[3],[3],[12,24,28],[12,24,28])]
 checks=[]
 for stem,n,hx,hz,gx,gz in fixtures:
  weights=[(x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if not any((r&z).bit_count()%2 for r in hx) and not any((r&x).bit_count()%2 for r in hz) and (x not in span(hx) or z not in span(hz))]
  exact=min(weights)
  for suffix,rows in zip(['Hx','Hz','Gx','Gz'],[hx,hz,gx,gz]):matrix(out/f'{stem}_{suffix}.txt',rows,n)
  for mode in ['no-card','card-mto']:
   dumped=[]
   for version,binary in binaries.items():
    p=run([binary,'-v','-cpu-lim=5','-'+mode,out/stem],stem+'-'+mode+'-'+version)
    assert p.returncode==0 and semantic(p.stdout)==(exact,exact,exact,exact),p.stdout+p.stderr
    if version=='candidate':
     m=re.search(r'c sls: .*verified-cap (-?\d+)',p.stdout); assert m
     if int(m[1])>=0:
      witness=re.search(r'c sls witness: ([01]+) ([01]+)',p.stdout); assert witness
      x,z=[sum(int(b)<<i for i,b in enumerate(bits)) for bits in witness.groups()]
      assert not any((r&z).bit_count()%2 for r in hx) and not any((r&x).bit_count()%2 for r in hz)
      assert (x not in span(hx) or z not in span(hz)) and (x|z).bit_count()==int(m[1])>=exact
    wcnf=out/f'{stem}-{mode}-{version}.wcnf'
    p=run([binary,'-dump-only','-dump-wcnf='+str(wcnf),out/stem],stem+'-'+mode+'-'+version+'-dump'); assert p.returncode==0,p.stderr
    dumped.append(wcnf.read_bytes())
   assert dumped[0]==dumped[1], 'CNF changed'
  checks.append(dict(fixture=stem,oracle_distance=exact,cnf_identical=True))
 for version,binary in binaries.items():
  p=run([runtime/'bin/bash.exe',candidate/'scripts/smoke_test.sh',binary],'smoke-'+version); assert p.returncode==0,p.stdout+p.stderr
 spec=importlib.util.spec_from_file_location('pilot',pkg/'qdistsat/benchmarks/compare_distqldpc_binaries.py')
 pilot=importlib.util.module_from_spec(spec);sys.modules['pilot']=pilot;spec.loader.exec_module(pilot)
 original_run=subprocess.run; rows=[]
 for stem in ['LP_136_32_4','BB_108_8_10']:
  for mode,flag in pilot.CONFIGS:
   pair=[]
   for version,binary in binaries.items():
    def captured(cmd,**kwargs):return run(cmd,'pilot-'+stem+'-'+mode+'-'+version,timeout=60)
    subprocess.run=captured
    try:r=pilot.run_one(binary,pilot.matrix_prefix(pkg/'qdistsat/data',stem),stem,mode,flag,45)
    finally:subprocess.run=original_run
    pair.append(r)
   assert all(r.returncode==0 and r.d is not None and not r.timed_out for r in pair)
   assert pair[0].semantic_result==pair[1].semantic_result,'QDistSAT mismatch'
   rows.append(dict(stem=stem,mode=mode,runs=[vars(r) for r in pair]));save('cross-repo.json',rows)
 for version,binary in binaries.items():
  for mode in ['no-card','card-mto']:
   p=run([binary,'-cpu-lim=1','-'+mode,pkg/'baseline/data/matrices/BB_108_8_10'],'timeout-'+version+'-'+mode,timeout=20)
   assert p.returncode==1 and 's UNKNOWN' in p.stdout and 'c status: TIMEOUT' in p.stdout,p.stdout
   assert semantic(p.stdout)[0:2]==(None,None)
   assert all(int(v)<=10 for v in re.findall(r'^c\s+d_lb:\s*(\d+)',p.stdout,re.M))
   assert all(int(v)>=10 for v in re.findall(r'^c\s+d_ub:\s*(\d+)',p.stdout,re.M))
 summary.update(status='PASS',reason='build, exhaustive SLS/CSS/cap checks, identical CNF, smoke, QDistSAT and timeout checks',checks=checks,hosted_cross_repo='pending PR check')
except AssertionError as e:
 summary.update(status='REJECTED',reason=str(e)); raise
except Exception as e:
 summary.update(reason=repr(e)); raise
finally:
 if process is not None and process.poll() is None:
  killed=subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],capture_output=True,text=True);save('kill.json',dict(returncode=killed.returncode,stdout=killed.stdout,stderr=killed.stderr));process.wait(timeout=15)
 save('cleanup.json',window.close());save('summary.json',summary)
 print(json.dumps(summary,indent=2),flush=True)
