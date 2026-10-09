"""Disabled 90-second outer watchdog; owns only its new child session."""
from pathlib import Path
import argparse,hashlib,json,os,signal,subprocess,sys,time
ASSIGNMENT='HOST_SLOT_NOT_ASSIGNED'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def proc(pid):
 try:
  s=Path('/proc',str(pid),'stat').read_text();f=s[s.rfind(')')+2:].split()
  return dict(pid=pid,group=int(f[2]),session=int(f[3]),birth=int(f[19]))
 except (FileNotFoundError,ProcessLookupError):return None
def members(sid):
 return [r for p in Path('/proc').iterdir() if p.name.isdigit() and (r:=proc(int(p.name))) is not None and r['session']==sid]
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--assignment',required=True);ap.add_argument('--source-sha',required=True);ap.add_argument('--launcher-sha',required=True);a=ap.parse_args()
 assert ASSIGNMENT!='HOST_SLOT_NOT_ASSIGNED' and a.assignment==ASSIGNMENT
 assert sha(__file__)==a.launcher_sha and sha(Path(__file__).with_name('run.py'))==a.source_sha
 assert sys.platform=='linux' and os.geteuid()!=0 and sys.dont_write_bytecode and os.environ.get('PYTHONDONTWRITEBYTECODE')=='1'
 assert os.sched_getaffinity(0)=={102};original=os.sched_getaffinity(0)
 prefix=Path.home()/'GH58-backtrace-01.launcher';paths=[Path(str(prefix)+s) for s in ['.stdout','.stderr','.json']]
 assert not any(p.exists() for p in paths)
 report=dict(assignment=ASSIGNMENT,deadline_seconds=90,cleanup_seconds=[3,5],state='STARTING',actions=[]);child=None;leader=None
 def save():paths[2].write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
 def owned():
  now=proc(child.pid)
  if now is not None and leader is not None:assert now['birth']==leader['birth'],'Reused leader; no signaling'
  rows=members(child.pid);assert not rows or leader is not None,'Unconfirmed session birth'
  return rows
 def cleanup():
  for sig,seconds in [(signal.SIGTERM,3),(signal.SIGKILL,5)]:
   for pg in sorted({r['group'] for r in owned()}):
    fresh=[r for r in owned() if r['group']==pg]
    if not fresh:continue
    try:os.killpg(pg,sig);report['actions'].append(dict(signal=int(sig),group=pg,members=fresh))
    except ProcessLookupError:pass
   end=time.monotonic()+seconds
   while time.monotonic()<end:
    child.poll()
    if not owned():break
    time.sleep(.05)
   if not owned():break
  child.poll();report['remaining']=owned();report['owned_empty']=not report['remaining'];save()
 def terminated(s,f):raise RuntimeError('External launcher termination '+str(s))
 signal.signal(signal.SIGTERM,terminated);signal.signal(signal.SIGINT,terminated)
 try:
  argv=[sys.executable,'-B',str(Path(__file__).with_name('run.py')),'--assignment',a.assignment,'--source-sha',a.source_sha];report['argv']=argv;save()
  with paths[0].open('wb') as stdout,paths[1].open('wb') as stderr:
   child=subprocess.Popen(argv,stdout=stdout,stderr=stderr,start_new_session=True);leader=proc(child.pid)
   assert leader and leader['group']==leader['session']==child.pid
   report.update(leader=leader,state='RUNNING');save();deadline=time.monotonic()+90
   while child.poll() is None:
    if time.monotonic()>=deadline:raise subprocess.TimeoutExpired(argv,90)
    time.sleep(.05)
   report.update(state='CHILD_EXITED',returncode=child.returncode);cleanup()
 except BaseException as e:
  report.update(state='INCONCLUSIVE',error=repr(e))
  if child is not None:
   try:cleanup()
   except BaseException as e:report['cleanup_error']=repr(e)
 finally:
  report['actual_affinity']=sorted(os.sched_getaffinity(0));report['actual_restore']=os.sched_getaffinity(0)==original
  report['source_identity_post']=sha(__file__)==a.launcher_sha and sha(Path(__file__).with_name('run.py'))==a.source_sha
  report['valid_transport']=bool(report['state']=='CHILD_EXITED' and report.get('returncode')==0 and report.get('owned_empty') and report['actual_restore'] and report['source_identity_post'] and not report.get('cleanup_error'))
  save();print(json.dumps(report),flush=True)
 return 0 if report['valid_transport'] else 1
if __name__=='__main__':sys.exit(main())
