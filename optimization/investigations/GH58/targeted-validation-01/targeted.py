"""Disabled finite GH58 targeted correctness gate; no performance/adoption."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,re,shutil,signal,sys,time
ASSIGNMENT='https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6072184769'
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='f06ac3de230362935a23d0faeff1350708651d7d'
SOLVER_SHA='c1360169ca4066e69e2c5ea64f86fd36deb41e5a1db76697b7874f007c873afc'
RUNTIME_SHA='940fce2a7063e8f6c3fce44fe1e013d194712a7ed9b05873dc2a89ad61accd8a'
RAW_SHA='ecf1f127d1d6f130fa99d954220e10f70a8accec5b6d7d01de2b14ab1118deeb'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
def load(name,p):
    spec=importlib.util.spec_from_file_location(name,p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m

def main():
    ap=argparse.ArgumentParser()
    for n in ['package','out','runtime']:ap.add_argument('--'+n,type=Path,required=True)
    for n in ['assignment','manifest-sha']:ap.add_argument('--'+n,required=True)
    a=ap.parse_args();assert ASSIGNMENT!='HOST_SLOT_NOT_ASSIGNED' and a.assignment==ASSIGNMENT
    assert sys.platform=='linux' and os.getuid()==1004 and os.getsid(0)==os.getpid()
    assert sys.dont_write_bytecode and os.environ.get('PYTHONDONTWRITEBYTECODE')=='1'
    overrides=['CC','CXX','CPP','CFLAGS','CXXFLAGS','CPPFLAGS','LDFLAGS','MAKEFLAGS','GNUMAKEFLAGS','MAKEFILES','MFLAGS','MAKEOVERRIDES','CPATH','C_INCLUDE_PATH','CPLUS_INCLUDE_PATH','OBJC_INCLUDE_PATH','GCC_EXEC_PREFIX','COMPILER_PATH','LIBRARY_PATH','GCC_COMPARE_DEBUG','GCC_COMPARE_DEBUG_SECOND','LD_PRELOAD','LD_LIBRARY_PATH','LD_AUDIT','PYTHONPATH','PYTHONHOME']
    assert not any(n in os.environ for n in overrides),'Present environment override (values not logged)'
    package=a.package.resolve();out=a.out.resolve();home=Path.home().resolve()
    assert out.parent==home and not out.exists()
    manifest_path=package/'manifest.json';assert sha(manifest_path)==a.manifest_sha
    manifest=json.loads(manifest_path.read_text());assert manifest['baseline']==BASE and manifest['candidate']==CAND and manifest['assignment']==ASSIGNMENT
    pins={str(manifest_path):a.manifest_sha}
    for n,h in manifest['files'].items():
        p=(package/n).resolve();assert p.is_relative_to(package) and p.is_file() and sha(p)==h;pins[str(p)]=h
    assert {str(p.relative_to(package)) for p in package.rglob('*') if p.is_file()}==set(manifest['files'])|{'manifest.json'}
    assert sha(__file__)==manifest['files']['support/targeted.py']
    assert sha(package/'candidate/src/solver/Solver.cc')==SOLVER_SHA
    inventory=a.runtime.resolve();assert sha(inventory)==RUNTIME_SHA
    runtime=json.loads(inventory.read_text());assert runtime['schema_version']==2 and runtime['metadata_only'] is True
    assert str(Path(sys.executable).resolve())==runtime['python'] and runtime['gcc_version'].split('.')[0]=='13'
    assert runtime['critical_files'] and all(runtime['files'].get(p)==h for p,h in runtime['critical_files'].items())
    def full_runtime():
        for p,h in runtime['files'].items():assert sha(p)==h,'Runtime identity changed: '+p
    full_runtime();pins[str(inventory)]=RUNTIME_SHA
    t0=home/'GH41-linux-tier0-04';assert sha(t0/'SHA256.json')==RAW_SHA;pins[str(t0/'SHA256.json')]=RAW_SHA
    for n,h in json.loads((t0/'SHA256.json').read_text()).items():
        p=(t0/n).resolve();assert p.is_relative_to(t0) and sha(p)==h;pins[str(p)]=h
    pins[str(t0/'baseline/bin/maxcdcl')]='86db7efcf42388e76a8fe9e2afc2bfff417ad55d296ce5dc59c2ff84bde32d09'
    pins[str(t0/'baseline/bin/distqldpc')]='13e15ba78f1d7f96af7d54ba767d3e99fb23c8cf44109b9610f037d343051cf4'
    # All support and full runtime authenticated before custom module imports.
    guard_module=load('gh58_guard',package/'support/guard.py');science=load('gh58_science',package/'support/science.py')
    assert not any(p.suffix=='.pyc' or p.name=='__pycache__' for p in package.rglob('*'))
    source_pins={};objects={};binaries={};window=None
    def identities():
        for p,h in {**pins,**source_pins,**objects,**binaries}.items():assert sha(p)==h,'Recorded identity changed: '+p
        assert not any(p.suffix=='.pyc' or p.name=='__pycache__' for p in package.rglob('*'))
    def critical():
        for p,h in runtime['critical_files'].items():assert sha(p)==h,'Critical runtime changed: '+p
    identities();proof=guard_module.lease();out.mkdir(mode=0o700)
    summary=dict(status='INCONCLUSIVE',Tier0='NOT_COMPLETE',Tier1='NOT_RUN',performance='NOT_MEASURED',baseline=BASE,candidate=CAND,solver_sha=SOLVER_SHA,assignment=ASSIGNMENT)
    save(out/'preexecution.json',dict(manifest_sha=a.manifest_sha,runtime_sha=RUNTIME_SHA,baseline_raw_sha=RAW_SHA,full_runtime=len(runtime['files']),baseline_raw_files=len(json.loads((t0/'SHA256.json').read_text())),lease=proof,scope='Targeted repair validation only; original failing baseline never relabelled PASS'))
    records=[]
    def termination(s,f):raise RuntimeError('External signal '+str(s))
    signal.signal(signal.SIGTERM,termination);signal.signal(signal.SIGINT,termination)
    try:
        window=guard_module.Guard(out,identities,critical,900)
        source=out/'candidate';shutil.copytree(package/'candidate',source)
        for p in source.rglob('*'):
            if p.is_file():source_pins[str(p)]=sha(p)
        save(out/'source-pins.json',source_pins)
        compiler=runtime['compiler'];make=runtime['make'];obj_names=['SimpSolver','Solver','Options','System']
        build_deadline=time.monotonic()+300
        def command(argv,cwd,label,seconds):return window.run(argv,cwd,label,seconds)
        def checked(argv,cwd,label,seconds):
            rc,stdout,stderr=command(argv,cwd,label,seconds)
            if rc!=0:raise RuntimeError('Engineering build/link command failed '+label+' rc='+str(rc))
            return stdout.decode('utf-8')
        def build(argv,label):
            remaining=build_deadline-time.monotonic();assert remaining>0,'300s build budget expired'
            return checked(argv,source,label,min(remaining,300))
        # Original Make recipes, clean serial engine objects; pin before links.
        build([make,'-j1','CXX='+compiler,*['build/'+n+'.o' for n in obj_names]],'build-engine')
        for n in obj_names:objects[str(source/'build'/(n+'.o'))]=sha(source/'build'/(n+'.o'))
        save(out/'consumed-engine-object-pins.json',objects)
        build([make,'-j1','CXX='+compiler,'bin/maxcdcl'],'link-original-Main')
        main_binary=source/'bin/maxcdcl';binaries[str(main_binary)]=sha(main_binary)
        def link_proof(binary,label):
            text=checked(['/usr/bin/ldd',binary],out,label,10);dependencies=[]
            assert 'not found' not in text
            for line in text.splitlines():
                m=re.search(r'=>\s+(/\S+)',line) or re.match(r'\s*(/\S+)',line)
                if not m:continue
                p=Path(m.group(1));r=str(p.resolve());assert r in runtime['files'] and sha(p)==runtime['files'][r]
                dependencies.append(dict(path=str(p),resolved=r,sha256=sha(p)))
            assert dependencies;save(out/(label+'.dependencies.json'),dependencies)
        link_proof(main_binary,'main-ELF-link')
        fixture_rows=json.loads((package/'fixtures/targeted-oracles.json').read_text());assert len(fixture_rows)==11
        for index,row in enumerate(fixture_rows):
            p=package/'fixtures'/row['name'];truth=science.wcnf(p.read_bytes());assert sha(p)==row['sha256'] and truth==row['oracle']
            if index==0:
                assert row['name']=='mandatory-original.wcnf' and sha(p)=='ae851ec8bb80b3a638c40184d5203259ecade373e5598df2c79dbd7d12eb52d4'
                assert truth['exact']==5 and truth['assignments']==1024
            rc,stdout,stderr=command([main_binary,'-verb=1',p],source,'targeted-'+str(index),10)
            try:text=stdout.decode('utf-8')
            except UnicodeDecodeError as e:raise science.ScienceError('Invalid scientific UTF8') from e
            result=science.pms(rc,text,truth['exact']);records.append(dict(input=row,result=result,stderr_sha=hashlib.sha256(stderr).hexdigest()));save(out/'targeted-science.json',records)
            if index==0:
                save(out/'mandatory-regression.json',dict(candidate_correct=True,exact=5,result=result,original_failure='RETAINED_EXPECTED_FAIL_NOT_WAIVED',old_baseline_reexecuted=False))
        # Application build follows mandatory correctness; no extra source change.
        # Separate remaining link budget, not a second compiler configuration.
        checked([make,'-j1','CXX='+compiler,'bin/distqldpc'],source,'link-app',30)
        app_binary=source/'bin/distqldpc';binaries[str(app_binary)]=sha(app_binary);link_proof(app_binary,'app-ELF-link')
        flags=['-Isrc/solver','-Wall','-Wno-parentheses','-O3','-g','-D__STDC_LIMIT_MACROS','-D__STDC_FORMAT_MACROS','-DNDEBUG']
        probe=out/'partition-fixture'
        checked([compiler,*flags,package/'support/test_partition.cc',*[source/'build'/(n+'.o') for n in obj_names],'-lz','-o',probe],source,'partition-fixture-link',60)
        binaries[str(probe)]=sha(probe);link_proof(probe,'partition-ELF-link')
        rc,stdout,stderr=command([probe],out,'partition-fixture',20)
        science.need(rc==0,'Actual partition invariant fixture failed/crashed rc='+str(rc))
        try:text=stdout.decode('utf-8')
        except UnicodeDecodeError as e:raise science.ScienceError('Invalid partition fixture UTF8') from e
        science.need('GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1' in text,'Partition invariant/oracle terminal absent')
        science.need(not (out/'partition-fixture.stderr').read_bytes(),'Partition invariant fixture stderr')
        identities();save(out/'binary-pins.json',binaries)
        summary.update(status='TARGETED_PASS_NOT_FULL_TIER0',targeted_cases=11,partition_cases=80,no_conflict_cases=1,science_correct=True)
    except science.ScienceError as error:summary.update(status='SCIENTIFIC_REJECT',Tier0='REJECT',science_reject=True,science_reason=str(error))
    except BaseException as error:summary['engineering_reason']=repr(error)
    finally:
        if window is not None:
            try:
                summary['cleanup']=window.close()
                summary['cleanup_valid']=bool(summary['cleanup'].get('owned_empty') and summary['cleanup'].get('actual_restore') and not any(k in summary['cleanup'] for k in ['cleanup_error','restore_error','lease_error']))
            except BaseException as error:summary.update(cleanup_valid=False,cleanup_error=repr(error))
        try:identities();full_runtime();summary['identity_valid']=True
        except BaseException as error:summary.update(identity_valid=False,identity_error=repr(error))
        summary['valid_evidence']=bool(summary.get('cleanup_valid') and summary.get('identity_valid'))
        if not summary['valid_evidence'] and not summary.get('science_reject'):summary['status']='INCONCLUSIVE'
        save(out/'summary.json',summary);save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json'})
        print(json.dumps(summary),flush=True)
    return 0 if summary['valid_evidence'] and summary['status']=='TARGETED_PASS_NOT_FULL_TIER0' else 1
if __name__=='__main__':sys.exit(main())
