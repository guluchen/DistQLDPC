"""Ordinary Linux correctness CI only; no benchmark or fixed-server claim."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,re,shutil,signal,subprocess,sys,time
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='f06ac3de230362935a23d0faeff1350708651d7d'
SOLVER_SHA='c1360169ca4066e69e2c5ea64f86fd36deb41e5a1db76697b7874f007c873afc'
FIXTURE_SHA='ae851ec8bb80b3a638c40184d5203259ecade373e5598df2c79dbd7d12eb52d4'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf8')
def load(n,p):
    s=importlib.util.spec_from_file_location(n,p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
def proc(pid):
    try:
        s=Path('/proc',str(pid),'stat').read_text();v=s[s.rfind(')')+2:].split()
        return dict(pid=pid,group=int(v[2]),session=int(v[3]),birth=int(v[19]))
    except (FileNotFoundError,ProcessLookupError):return None
def members(sid):return [r for p in Path('/proc').iterdir() if p.name.isdigit() and (r:=proc(int(p.name))) and r['session']==sid]
def main():
    ap=argparse.ArgumentParser()
    for n in ['package','support','out','prerequisite']:ap.add_argument('--'+n,type=Path,required=True)
    for n in ['manifest-sha','support-manifest-sha','prerequisite-sha']:ap.add_argument('--'+n,required=True)
    a=ap.parse_args();assert sys.platform=='linux' and os.getuid()!=0 and sys.dont_write_bytecode and os.environ.get('PYTHONDONTWRITEBYTECODE')=='1'
    assert not any(n in os.environ for n in ['CC','CXX','CPP','CFLAGS','CXXFLAGS','CPPFLAGS','LDFLAGS','MAKEFLAGS','GNUMAKEFLAGS','MAKEFILES','MFLAGS','MAKEOVERRIDES','CPATH','C_INCLUDE_PATH','CPLUS_INCLUDE_PATH','OBJC_INCLUDE_PATH','GCC_EXEC_PREFIX','COMPILER_PATH','LIBRARY_PATH','GCC_COMPARE_DEBUG','GCC_COMPARE_DEBUG_SECOND','LD_PRELOAD','LD_LIBRARY_PATH','LD_AUDIT','PYTHONPATH','PYTHONHOME'])
    package=a.package.resolve();support=a.support.resolve();out=a.out.resolve();assert not out.exists()
    start=time.monotonic();deadline=start+540;pins={};current=None;leader=None;cleanup_errors=[]
    original_affinity=os.sched_getaffinity(0)
    assert sha(a.prerequisite)==a.prerequisite_sha;pins[str(a.prerequisite.resolve())]=a.prerequisite_sha
    prior=json.loads(a.prerequisite.read_text())
    assert prior['verdict']=='PASS' and prior['actual_run_id'] and prior['candidate_solver_sha']==SOLVER_SHA and prior['original_fixture_sha']==FIXTURE_SHA
    assert prior['targeted_cases']==11 and prior['partition_cases']==80 and prior['no_conflict_cases']==1 and prior['raw_audit_verified'] is True
    for root,digest,kind in [(package,a.manifest_sha,'package'),(support,a.support_manifest_sha,'support')]:
        path=root/'manifest.json';assert sha(path)==digest;pins[str(path)]=digest
        data=json.loads(path.read_text());files=data['files'] if kind=='package' else data
        if kind=='package':assert data['baseline']==BASE and data['candidate']==CAND
        assert {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file()}==set(files)|{'manifest.json'}
        for n,h in files.items():
            p=(root/n).resolve();assert p.is_relative_to(root) and sha(p)==h;pins[str(p)]=h
    assert sha(__file__)==pins[str((support/'ci.py').resolve())]
    assert sha(package/'candidate/src/solver/Solver.cc')==SOLVER_SHA and sha(package/'fixtures/mandatory-original.wcnf')==FIXTURE_SHA
    def identities():
        for p,h in pins.items():assert sha(p)==h,'Recorded identity changed: '+p
        for root in [package,support]:assert not any(p.suffix=='.pyc' or p.name=='__pycache__' for p in root.rglob('*'))
        assert time.monotonic()<deadline,'Aggregate CI deadline reached'
    identities();science=load('gh58_ci_science',support/'science.py');corpus=load('gh58_ci_corpus',support/'corpus.py')
    out.mkdir(parents=True);summary=dict(status='INCONCLUSIVE',Tier0='NOT_COMPLETE',performance='NOT_MEASURED',controlled_runtime=False,baseline=BASE,candidate=CAND,prerequisite=prior)
    def owned():
        if current is None:return []
        now=proc(current.pid)
        if now is not None:assert leader and now['birth']==leader['birth'],'Reused leader PID; no signaling'
        rows=members(current.pid);assert not rows or leader,'Unconfirmed session ownership'
        return rows
    def cleanup():
        for sig,seconds in [(signal.SIGTERM,2),(signal.SIGKILL,5)]:
            for pg in sorted({r['group'] for r in owned()}):
                fresh=[r for r in owned() if r['group']==pg]
                if not fresh:continue
                assert pg!=os.getpgrp(),'Refuse runner group signaling'
                try:os.killpg(pg,sig)
                except ProcessLookupError:pass
            until=time.monotonic()+seconds
            while time.monotonic()<until:
                if current is not None:current.poll()
                if not owned():break
                time.sleep(.05)
            if not owned():break
        assert not owned(),'Owned process remained'
    def run(argv,cwd,label,limit):
        nonlocal current,leader
        identities();assert not owned();argv=list(map(str,argv));record=dict(argv=argv,cwd=str(cwd),label=label,limit=limit)
        try:
            with (out/(label+'.stdout')).open('wb') as stdout,(out/(label+'.stderr')).open('wb') as stderr:
                current=subprocess.Popen(argv,cwd=cwd,stdout=stdout,stderr=stderr,start_new_session=True);leader=proc(current.pid)
                assert leader and leader['session']==leader['group']==current.pid;record['leader']=leader
                current.wait(timeout=min(limit,max(.01,deadline-time.monotonic())));record['returncode']=current.returncode
                # Authenticate a returned solver crash before later identity or
                # cleanup errors can mask it. Watchdog/external termination
                # takes the exception path without an authenticated completion.
                name=Path(argv[0]).name
                if name in ('maxcdcl','distqldpc') or name.endswith('-test-only'):
                    allowed=(10,20) if name=='maxcdcl' else (0,1)
                    if current.returncode not in allowed:
                        record['science_reject']=True
                        raise science.ScienceError('Actual returned solver crash/invalid rc '+label+' rc='+str(current.returncode))
        except science.ScienceError as e:record['science_error']=str(e);raise
        except BaseException as e:record['engineering_error']=repr(e);raise
        finally:
            try:cleanup();record['owned_empty']=True
            except BaseException as e:record['cleanup_error']=repr(e);cleanup_errors.append(repr(e))
            save(out/(label+'.command.json'),record)
        assert record.get('owned_empty') and not record.get('cleanup_error')
        identities()
        try:return record['returncode'],(out/(label+'.stdout')).read_bytes().decode('utf8'),(out/(label+'.stderr')).read_bytes().decode('utf8')
        except UnicodeDecodeError as e:
            name=Path(argv[0]).name
            if name in ('maxcdcl','distqldpc') or name.endswith('-test-only'):
                raise science.ScienceError('Invalid scientific UTF8 '+label) from e
            raise RuntimeError('Invalid engineering UTF8 '+label) from e
    def checked(argv,cwd,label,limit):
        rc,text,error=run(argv,cwd,label,limit)
        if rc!=0:
            if label.endswith('-dump') or label.startswith('smoke-'):raise science.ScienceError('Output/dump/smoke failed '+label+' rc='+str(rc))
            raise RuntimeError('Engineering setup/build/link failed '+label+' rc='+str(rc))
        return text
    def pin(p):
        p=Path(p).resolve();h=sha(p);assert str(p) not in pins or pins[str(p)]==h;pins[str(p)]=h
        if p.read_bytes()[:4]==b'\x7fELF' and p.stat().st_mode&0o111:
            text=checked(['/usr/bin/ldd',p],out,p.name+'-link-'+str(len(pins)),10);assert 'not found' not in text
            deps=[]
            for line in text.splitlines():
                m=re.search(r'=>\s+(/\S+)',line) or re.match(r'\s*(/\S+)',line)
                if not m:continue
                dep=Path(m.group(1)).resolve();h=sha(dep);assert str(dep) not in pins or pins[str(dep)]==h;pins[str(dep)]=h;deps.append(dict(path=str(dep),sha256=h))
            assert deps;save(out/(p.name+'-dependencies.json'),deps)
    def terminate(s,f):raise RuntimeError('External CI termination '+str(s))
    signal.signal(signal.SIGTERM,terminate);signal.signal(signal.SIGINT,terminate)
    try:
        compiler=Path(shutil.which('g++')).resolve();make=Path(shutil.which('make')).resolve()
        for p in [compiler,make,Path(sys.executable).resolve(),Path('/usr/bin/ldd')]:pins[str(p)]=sha(p)
        version=checked([compiler,'--version'],out,'compiler-version',10)
        assert 'g++' in version,'GNU compiler required (engineering gate)'
        save(out/'preexecution.json',dict(package_sha=a.manifest_sha,support_sha=a.support_manifest_sha,prerequisite_sha=a.prerequisite_sha,compiler=str(compiler),compiler_version=version,source_only_package=True,ordinary_CI=True,performance=False,original_affinity=sorted(original_affinity)))
        sources={};binaries={};standalone={};objects={}
        for v in ['baseline','candidate']:
            source=out/v;shutil.copytree(package/v,source);sources[v]=source
            data=source/'data/matrices';data.mkdir(parents=True)
            for p in (package/'inputs').iterdir():shutil.copyfile(p,data/p.name)
            for p in source.rglob('*'):
                if p.is_file():pins[str(p.resolve())]=sha(p)
            objects[v]={n:source/'build'/(n+'.o') for n in ['SimpSolver','Solver','Options','System']}
            checked([make,'-j1','CXX='+str(compiler),*[str(p.relative_to(source)) for p in objects[v].values()]],source,'build-engine-'+v,180)
            for p in objects[v].values():pin(p)
            save(out/(v+'-consumed-engine-objects.json'),{str(p):sha(p) for p in objects[v].values()})
            for name in ['distqldpc','maxcdcl']:
                checked([make,'-j1','CXX='+str(compiler),'bin/'+name],source,'link-'+v+'-'+name,60);pin(source/'bin'/name)
            binaries[v]=source/'bin/distqldpc';standalone[v]=source/'bin/maxcdcl'
        result=corpus.execute(run,checked,pin,sources,binaries,standalone,objects,package/'fixtures',package/'inputs',out,science,compiler)
        result['production_rebuilt']=True  # Ordinary CI builds; server adapter reuses fixed binaries.
        identities();summary.update(status='FULL_CORRECTNESS_CI_PASS',Tier0='CI_PASS',counts=result,science_correct=True,original_known_failure='RETAINED_EXPECTED_FAIL_NOT_WAIVED',new_baseline='NOT_DESIGNATED')
    except science.ScienceError as e:summary.update(status='SCIENTIFIC_REJECT',Tier0='REJECT',science_reject=True,science_reason=str(e))
    except science.CoverageGap as e:summary.update(status='INCONCLUSIVE',coverage_reason=str(e))
    except BaseException as e:summary.update(status='INCONCLUSIVE',engineering_reason=repr(e))
    finally:
        try:cleanup();summary['owned_empty']=True
        except BaseException as e:summary.update(owned_empty=False,cleanup_error=repr(e))
        summary['cleanup_errors']=cleanup_errors;summary['actual_restore']=os.sched_getaffinity(0)==original_affinity
        try:identities();summary['identity_valid']=True
        except BaseException as e:summary.update(identity_valid=False,identity_error=repr(e))
        summary['valid_evidence']=bool(summary.get('owned_empty') and not cleanup_errors and summary['actual_restore'] and summary.get('identity_valid'))
        if not summary['valid_evidence'] and not summary.get('science_reject'):summary['status']='INCONCLUSIVE'
        save(out/'consumed-pins.json',pins);save(out/'summary.json',summary)
        save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json'})
        print(json.dumps(summary),flush=True)
    return 0 if summary['status']=='FULL_CORRECTNESS_CI_PASS' and summary['valid_evidence'] else 1
if __name__=='__main__':sys.exit(main())
