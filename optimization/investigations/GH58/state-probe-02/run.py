"""Disabled: one unchanged native baseline solve; no candidate/build/performance."""
from pathlib import Path
import argparse,hashlib,json,os,re,signal,subprocess,sys,time
ASSIGNMENT='HOST_SLOT_NOT_ASSIGNED'
FIXTURE_SHA='ae851ec8bb80b3a638c40184d5203259ecade373e5598df2c79dbd7d12eb52d4'
BIN_SHA='86db7efcf42388e76a8fe9e2afc2bfff417ad55d296ce5dc59c2ff84bde32d09'
RAW_SHA='ecf1f127d1d6f130fa99d954220e10f70a8accec5b6d7d01de2b14ab1118deeb'
RUNTIME_SHA='940fce2a7063e8f6c3fce44fe1e013d194712a7ed9b05873dc2a89ad61accd8a'
GDB_SHA='3832cc070ae1716e322105d3b39fb398695e5f031c9d39224cf227a8c2b889f6'
HELPER_SHA='0bf26454f93bdb2d1d3973d212f141c1e3af174c4954d35df2ab98abddee0229'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,d):p.write_text(json.dumps(d,indent=2)+'\n',encoding='utf8')
def cpus(s):
 out=set()
 for x in s.strip().split(','):
  if not x:continue
  a,b=(list(map(int,x.split('-'))) if '-' in x else [int(x)]*2);out.update(range(a,b+1))
 return out
def proc(pid):
 try:
  s=Path('/proc',str(pid),'stat').read_text();f=s[s.rfind(')')+2:].split()
  return dict(pid=pid,group=int(f[2]),session=int(f[3]),birth=int(f[19]))
 except (FileNotFoundError,ProcessLookupError):return None
def members(sid):
 return [r for p in Path('/proc').iterdir() if p.name.isdigit() and (r:=proc(int(p.name))) is not None and r['session']==sid]
def group_members(pg):
 return [r for p in Path('/proc').iterdir() if p.name.isdigit() and (r:=proc(int(p.name))) is not None and r['group']==pg]
def lease():
 root=Path('/sys/fs/cgroup');g=root/'distqldpc-bench';helper=Path('/usr/local/sbin/distqldpc-cpu-run')
 st=helper.stat();assert st.st_uid==0 and not st.st_mode&0o022 and sha(helper)==HELPER_SHA
 assert os.getuid()==1004 and os.sched_getaffinity(0)=={102}
 assert Path('/proc/self/cgroup').read_text().strip()=='0::/distqldpc-bench'
 assert next(x for x in Path('/proc/self/status').read_text().splitlines() if x.startswith('NoNewPrivs:')).split()[-1]=='1'
 fields={n:(g/n).read_text().strip() for n in ['cpuset.cpus.partition','cpuset.cpus.effective','cpuset.cpus.exclusive.effective']}
 assert fields['cpuset.cpus.partition']=='isolated' and cpus(fields['cpuset.cpus.effective'])==cpus(fields['cpuset.cpus.exclusive.effective'])=={102,230}
 assert {102,230}<=cpus((root/'cpuset.cpus.isolated').read_text()) and not {102,230}&cpus((root/'cpuset.cpus.effective').read_text())
 for p in root.iterdir():
  if p!=g and (p/'cpuset.cpus.effective').exists():assert not {102,230}&cpus((p/'cpuset.cpus.effective').read_text())
 return dict(uid=os.getuid(),affinity=sorted(os.sched_getaffinity(0)),fields=fields,host_exclusive=False)
def oracle(p):
 lines=[x.split() for x in p.read_text().splitlines() if x.strip() and not x.startswith('c')]
 h=lines.pop(0);assert h==['p','wcnf','10','28','14']
 clauses=[]
 for row in lines:
  v=list(map(int,row));assert v[-1]==0 and len(v)>=3 and all(1<=abs(x)<=10 for x in v[1:-1]);clauses.append((v[0],v[1:-1]))
 assert len(clauses)==28 and sum(w==14 for w,c in clauses)==15 and sum(w==1 and len(c)==1 for w,c in clauses)==13
 costs=[]
 for mask in range(1024):
  satisfied=lambda c:any(bool(mask&(1<<(abs(l)-1)))==(l>0) for l in c)
  if all(satisfied(c) for w,c in clauses if w==14):costs.append((sum(w for w,c in clauses if w<14 and not satisfied(c)),mask))
 best=min(x[0] for x in costs);assert best==5 and (5,472) in costs
 return dict(exact=best,witness=472,assignments_enumerated=1024,hard_satisfying_assignments=len(costs),source_soft_all_unit=True)
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--assignment',required=True);ap.add_argument('--source-sha',required=True);a=ap.parse_args()
 assert ASSIGNMENT!='HOST_SLOT_NOT_ASSIGNED' and a.assignment==ASSIGNMENT and sha(__file__)==a.source_sha
 assert sys.platform=='linux' and os.geteuid()!=0 and sys.dont_write_bytecode and os.environ.get('PYTHONDONTWRITEBYTECODE')=='1'
 assert not any(k in os.environ for k in ['LD_PRELOAD','LD_LIBRARY_PATH','PYTHONPATH','PYTHONHOME'])
 home=Path.home();t0=home/'GH41-linux-tier0-04';out=home/'GH58-state-probe-02';fixture=home/'GH46-family1-variant1.wcnf';inventory=home/'distqldpc-gh41-runtime-03.json'
 assert not out.exists();assert sha(fixture)==FIXTURE_SHA and sha(t0/'SHA256.json')==RAW_SHA and sha(inventory)==RUNTIME_SHA
 runtime=json.loads(inventory.read_text());assert str(Path(sys.executable).resolve())==runtime['python']
 raw=json.loads((t0/'SHA256.json').read_text());pins={}
 for n,h in raw.items():
  p=(t0/n).resolve();assert p.is_relative_to(t0);pins[str(p)]=h
 pins['/usr/bin/gdb']=GDB_SHA;assert sha('/usr/bin/gdb')==GDB_SHA
 pins.update(runtime['files']);pins.update({str(fixture):FIXTURE_SHA,str(inventory):RUNTIME_SHA,str(t0/'SHA256.json'):RAW_SHA,str(Path(__file__).resolve()):a.source_sha})
 def identities():
  for p,h in pins.items():assert sha(p)==h,'Identity changed: '+p
 start=time.monotonic();identities();assert time.monotonic()-start<90
 proof=lease();truth=oracle(fixture);binary=t0/'baseline/bin/maxcdcl';assert sha(binary)==BIN_SHA
 out.mkdir();save(out/'preexecution.json',dict(assignment=ASSIGNMENT,baseline='24572d6d09cce9a4a5faa58300a89e0feba9da6a',pins=pins,lease=proof,oracle=truth,build='NOT_RUN',candidate='NOT_RUN',performance='NOT_MEASURED'))
 original=os.sched_getaffinity(0);child=None;leader=None;result=dict(assignment=ASSIGNMENT,status='INCONCLUSIVE',candidate='NOT_RUN',performance='NOT_MEASURED',baseline_modified=False)
 def terminate(s,f):raise RuntimeError('External termination '+str(s))
 signal.signal(signal.SIGTERM,terminate);signal.signal(signal.SIGINT,terminate)
 try:
  assert time.monotonic()-start<90
  for p,h in runtime['critical_files'].items():assert sha(p)==h
  command=['/usr/bin/gdb','--nx','--nh','--batch','-iex','set auto-load off','-ex','set startup-with-shell off','-ex','set pagination off','-ex','set confirm off','-ex','run','-ex','bt 20','-ex','info registers rip rsp rbp','-ex','x/8i $pc','-ex','p $_siginfo.si_signo','-ex','set print elements 24','-ex','info registers rax rcx rdx rsi r8 r9 r10 r11 rbp','-ex','p this->qhead','-ex','p this->trail','-ex','p this->trail.data[this->qhead-1]','-ex','p this->assigns','-ex','p this->watches_bin.occs','-ex','p this->watches_bin.occs.data[this->trail.data[this->qhead-1].x]','-ex','p p','-ex','p k','-ex','p wbin','-ex','p $_siginfo','-ex','info proc status','-ex','quit','--args',str(binary),'-verb=1',str(fixture)];save(out/'command.json',dict(argv=command,cwd=str(t0/'baseline'),engineering_limit=15,assignment=ASSIGNMENT))
  with (out/'solve.stdout').open('wb') as stdout,(out/'solve.stderr').open('wb') as stderr:
   child=subprocess.Popen(command,cwd=t0/'baseline',stdout=stdout,stderr=stderr,process_group=0)
   leader=proc(child.pid);assert leader and leader['group']==child.pid and leader['session']==os.getsid(0);save(out/'child.json',leader)
   try:child.wait(timeout=15)
   except subprocess.TimeoutExpired:result['status']='ENGINEERING_TIMEOUT';raise
  rawtext=(out/'solve.stdout').read_bytes();rc=child.returncode
  try:text=rawtext.decode('utf8');utf8_valid=True
  except UnicodeDecodeError:text=rawtext.decode('utf8',errors='replace');utf8_valid=False
  segfault='Program received signal SIGSEGV' in text
  frames=re.findall(r'^#\d+\s+.*$',text,re.M)
  result.update(status='STATE_PROBE_CAPTURED_SIGSEGV' if utf8_valid and rc==0 and segfault and frames else 'DIAGNOSTIC_INCONCLUSIVE',debugger_returncode=rc,debugger_signal_SIGSEGV=segfault,frames=frames,utf8_valid=utf8_valid,science_pass=False,oracle=truth,scientific_classification='Original baseline anomaly unresolved; debugger exit is not a scientific answer')

 except BaseException as e:result['error']=repr(e)
 finally:
  result['owned_empty']=False;result['actual_restore']=False
  try:
   if child is not None:
    if child.poll() is None:
     now=proc(child.pid);assert leader and now==leader,'Changed owned leader; no signaling'
     os.killpg(child.pid,signal.SIGKILL);child.wait(timeout=5)
    result['remaining_owned_session_except_self']=[row for row in members(os.getsid(0)) if row['pid']!=os.getpid()];result['owned_empty']=not result['remaining_owned_session_except_self'];result['actual_debugger_returncode']=child.returncode
  except BaseException as e:result['cleanup_error']=repr(e)
  try:
   os.sched_setaffinity(0,original);result['actual_affinity']=sorted(os.sched_getaffinity(0));result['actual_restore']=os.sched_getaffinity(0)==original
  except BaseException as e:result['restore_error']=repr(e)
  try:identities();result['full_recorded_identity_post']=True;result['post_lease']=lease()
  except BaseException as e:result.update(full_recorded_identity_post=False,identity_error=repr(e))
  result['valid_evidence']=bool(result.get('owned_empty') and result['actual_restore'] and result.get('full_recorded_identity_post') and not result.get('cleanup_error') and not result.get('restore_error'))
  save(out/'result.json',result);save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json'})
  print(json.dumps(result),flush=True)
 return 0 if result['valid_evidence'] else 1
if __name__=='__main__':sys.exit(main())
