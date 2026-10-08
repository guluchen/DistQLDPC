"""Disabled bounded outer launcher. Workers stay in its new child session.
Only that authenticated session is eligible for TERM/KILL cleanup.
"""
import argparse,hashlib,json,os,signal,subprocess,sys,time
from pathlib import Path
ASSIGNED_URL='HOST_SLOT_NOT_ASSIGNED'
def proc(pid):
    try:
        raw=Path('/proc',str(pid),'stat').read_text();f=raw[raw.rfind(')')+2:].split()
        return dict(pid=pid,group=int(f[2]),session=int(f[3]),birth=int(f[19]))
    except FileNotFoundError:return None
def members(sid):
    out=[]
    for p in Path('/proc').iterdir():
        if p.name.isdigit():
            r=proc(int(p.name))
            if r and r['session']==sid:out.append(r)
    return out
def main():
    ap=argparse.ArgumentParser()
    for name in ['package','out','runtime-inventory']:ap.add_argument('--'+name,type=Path,required=True)
    for name in ['run-assignment','manifest-sha','runtime-sha','support-sha']:ap.add_argument('--'+name,required=True)
    ap.add_argument('--cpu',type=int,required=True);ap.add_argument('--sibling',type=int,required=True)
    args=ap.parse_args();assert ASSIGNED_URL!='HOST_SLOT_NOT_ASSIGNED' and args.run_assignment==ASSIGNED_URL
    assert os.environ.get('PYTHONDONTWRITEBYTECODE')=='1' and sys.dont_write_bytecode,'Explicit read-only bytecode cache policy required'
    assert sys.platform=='linux' and os.geteuid()!=0
    package=args.package.resolve();out=args.out.resolve();assert out.parent==Path.home() and not out.exists()
    digest=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
    assert digest(package/'manifest.json')==args.manifest_sha
    manifest=json.loads((package/'manifest.json').read_text());assert manifest['support_head']==args.support_sha
    for name in ['server_tier0_correctness_launcher.py','server_tier0_correctness.py','server_tier0_correctness_supervisor.py','server_science.py']:
        assert digest(package/'support'/name)==manifest['files']['support/'+name]
    assert digest(__file__)==manifest['files']['support/server_tier0_correctness_launcher.py']
    assert digest(args.runtime_inventory)==args.runtime_sha
    inventory=json.loads(args.runtime_inventory.read_text());assert inventory['schema_version']==2 and inventory['identity_policy']=='FULL_PRE_IMPORT_AND_POST_RUN_CRITICAL_PER_COMMAND'
    assert inventory['cache_policy']=='DONTWRITE_BYTECODE_FULL_PRE_POST_EXISTING_PYC'
    assert not any(p.name=='__pycache__' or p.suffix=='.pyc' for p in package.rglob('*')),'Fresh package must contain no support bytecode caches'
    assert inventory['critical_files'] and all(inventory['files'].get(p)==v for p,v in inventory['critical_files'].items())
    assert str(Path(sys.executable).resolve())==inventory['python']
    for path,value in inventory['files'].items():assert digest(path)==value
    prefix=out.parent/(out.name+'.launcher');paths=[Path(str(prefix)+suffix) for suffix in ['.stdout','.stderr','.json']]
    assert not any(p.exists() for p in paths),'Fresh outer byte files required'
    argv=[sys.executable,'-B',str(package/'support/server_tier0_correctness.py'),*sys.argv[1:]]
    original=set(os.sched_getaffinity(0));assert args.cpu in original
    def termination(signum,frame):raise RuntimeError('External launcher termination '+str(signum))
    signal.signal(signal.SIGTERM,termination)
    child=None;leader=None;report=dict(assignment=args.run_assignment,argv=argv,outer_seconds=2760,state='STARTING',actions=[],classification='CORRECTNESS_CAPACITY_ONLY',performance='NOT_MEASURED')
    def save():paths[2].write_text(json.dumps(report,indent=2)+'\n')
    def owned():
        current=proc(child.pid)
        if leader is not None and current is not None and current['birth']!=leader['birth']:
            raise RuntimeError('Session leader reused; no signaling')
        rows=members(child.pid)
        if rows and leader is None:raise RuntimeError('Session birth unconfirmed; no signaling')
        return rows
    def cleanup():
        for sig,seconds in [(signal.SIGTERM,3),(signal.SIGKILL,5)]:
            for group in sorted({r['group'] for r in owned()}):
                fresh=[r for r in owned() if r['group']==group]
                if not fresh:continue
                try:os.killpg(group,sig);report['actions'].append(dict(signal=int(sig),group=group,members=fresh));save()
                except ProcessLookupError:pass
            end=time.monotonic()+seconds
            while time.monotonic()<end:
                child.poll()
                if not owned():break
                time.sleep(.05)
            if not owned():break
        child.poll();report['remaining']=owned();report['owned_empty']=not report['remaining'];save()
        if report['remaining']:raise RuntimeError('Outer owned session cleanup unconfirmed')
    try:
        os.sched_setaffinity(0,{args.cpu});save()
        with paths[0].open('wb') as stdout,paths[1].open('wb') as stderr:
            child=subprocess.Popen(argv,stdout=stdout,stderr=stderr,start_new_session=True)
            leader=proc(child.pid);report.update(pid=child.pid,leader=leader,state='RUNNING');save()
            deadline=time.monotonic()+2760
            while child.poll() is None:
                time.sleep(.1)
                if time.monotonic()>deadline:raise subprocess.TimeoutExpired(argv,2760)
            report.update(returncode=child.returncode,state='CHILD_EXITED')
            cleanup()
    except BaseException as error:
        report.update(state='INCONCLUSIVE',error=repr(error))
        if child is not None:
            try:cleanup()
            except BaseException as e:report['cleanup_error']=repr(e)
    finally:
        os.sched_setaffinity(0,original);report['actual_affinity']=sorted(os.sched_getaffinity(0))
        report['affinity_restored']=set(os.sched_getaffinity(0))==original
        try:
            assert digest(args.runtime_inventory)==args.runtime_sha
            for path,value in inventory['files'].items():assert digest(path)==value
            report['full_runtime_post_confirmed']=True
        except BaseException as error:report.update(full_runtime_post_confirmed=False,full_runtime_error=repr(error))
        report['valid_transport']=report.get('state')=='CHILD_EXITED' and report.get('returncode')==0 and report.get('owned_empty') and report['affinity_restored'] and report['full_runtime_post_confirmed']
        save();print(json.dumps(report),flush=True)
    return 0 if report.get('valid_transport') else 1
if __name__=='__main__':sys.exit(main())
