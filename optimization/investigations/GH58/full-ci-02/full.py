"""Disabled GH58 full native correctness gate; targeted actual PASS required."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,re,shutil,signal,sys,time
ASSIGNMENT='HOST_SLOT_NOT_ASSIGNED'
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
    for n in ['package','out','runtime','targeted','support']:ap.add_argument('--'+n,type=Path,required=True)
    for n in ['assignment','manifest-sha','targeted-catalog-sha','support-manifest-sha']:ap.add_argument('--'+n,required=True)
    a=ap.parse_args();assert ASSIGNMENT!='HOST_SLOT_NOT_ASSIGNED' and a.assignment==ASSIGNMENT
    assert sys.platform=='linux' and os.getuid()==1004 and os.getsid(0)==os.getpid()
    assert sys.dont_write_bytecode and os.environ.get('PYTHONDONTWRITEBYTECODE')=='1'
    overrides=['CC','CXX','CPP','CFLAGS','CXXFLAGS','CPPFLAGS','LDFLAGS','MAKEFLAGS','GNUMAKEFLAGS','MAKEFILES','MFLAGS','MAKEOVERRIDES','CPATH','C_INCLUDE_PATH','CPLUS_INCLUDE_PATH','OBJC_INCLUDE_PATH','GCC_EXEC_PREFIX','COMPILER_PATH','LIBRARY_PATH','GCC_COMPARE_DEBUG','GCC_COMPARE_DEBUG_SECOND','LD_PRELOAD','LD_LIBRARY_PATH','LD_AUDIT','PYTHONPATH','PYTHONHOME']
    assert not any(n in os.environ for n in overrides),'Present environment override (values not logged)'
    package=a.package.resolve();out=a.out.resolve();home=Path.home().resolve()
    assert out.parent==home and not out.exists()
    manifest_path=package/'manifest.json';assert sha(manifest_path)==a.manifest_sha
    manifest=json.loads(manifest_path.read_text());assert manifest['baseline']==BASE and manifest['candidate']==CAND and manifest['assignment']!='HOST_SLOT_NOT_ASSIGNED'
    pins={str(manifest_path):a.manifest_sha}
    for n,h in manifest['files'].items():
        p=(package/n).resolve();assert p.is_relative_to(package) and p.is_file() and sha(p)==h;pins[str(p)]=h
    assert {str(p.relative_to(package)) for p in package.rglob('*') if p.is_file()}==set(manifest['files'])|{'manifest.json'}
    support=a.support.resolve();support_manifest=support/'manifest.json'
    assert sha(support_manifest)==a.support_manifest_sha
    support_files=json.loads(support_manifest.read_text());pins[str(support_manifest)]=a.support_manifest_sha
    assert {str(p.relative_to(support)) for p in support.rglob('*') if p.is_file()}==set(support_files)|{'manifest.json'}
    for n,h in support_files.items():
        p=(support/n).resolve();assert p.is_relative_to(support) and sha(p)==h;pins[str(p)]=h
    assert sha(__file__)==support_files['full.py']
    targeted=a.targeted.resolve();assert targeted.parent==home and sha(targeted/'SHA256.json')==a.targeted_catalog_sha
    pins[str(targeted/'SHA256.json')]=a.targeted_catalog_sha
    target_catalog=json.loads((targeted/'SHA256.json').read_text())
    for n,h in target_catalog.items():
        p=(targeted/n).resolve();assert p.is_relative_to(targeted) and sha(p)==h;pins[str(p)]=h
    target_summary=json.loads((targeted/'summary.json').read_text())
    assert target_summary['status']=='TARGETED_PASS_NOT_FULL_TIER0' and target_summary['valid_evidence']
    assert target_summary['science_correct'] and target_summary['targeted_cases']==11 and target_summary['partition_cases']==80 and target_summary['no_conflict_cases']==1
    assert target_summary['candidate']==CAND and target_summary['baseline']==BASE and target_summary['solver_sha']==SOLVER_SHA
    assert target_summary['assignment']==manifest['assignment']
    assert json.loads((targeted/'preexecution.json').read_text())['manifest_sha']==a.manifest_sha
    target_objects=json.loads((targeted/'consumed-engine-object-pins.json').read_text())
    target_binaries=json.loads((targeted/'binary-pins.json').read_text())
    assert len(target_objects)==4
    for path,h in {**target_objects,**target_binaries}.items():
        assert Path(path).resolve().is_relative_to(targeted) and sha(path)==h;pins[path]=h

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
    guard_module=load('gh58_guard',support/'guard.py');science=load('gh58_science',support/'science.py')
    assert not any(p.suffix=='.pyc' or p.name=='__pycache__' for p in list(package.rglob('*'))+list(support.rglob('*')))
    source_pins={};objects={};binaries={};window=None
    def identities():
        for p,h in {**pins,**source_pins,**objects,**binaries}.items():assert sha(p)==h,'Recorded identity changed: '+p
        assert not any(p.suffix=='.pyc' or p.name=='__pycache__' for p in list(package.rglob('*'))+list(support.rglob('*')))
    def critical():
        for p,h in runtime['critical_files'].items():assert sha(p)==h,'Critical runtime changed: '+p
    identities();proof=guard_module.lease();out.mkdir(mode=0o700)
    summary=dict(status='INCONCLUSIVE',Tier0='NOT_COMPLETE',Tier1='NOT_RUN',performance='NOT_MEASURED',baseline=BASE,candidate=CAND,solver_sha=SOLVER_SHA,assignment=ASSIGNMENT)
    save(out/'preexecution.json',dict(manifest_sha=a.manifest_sha,runtime_sha=RUNTIME_SHA,baseline_raw_sha=RAW_SHA,full_runtime=len(runtime['files']),baseline_raw_files=len(json.loads((t0/'SHA256.json').read_text())),lease=proof,scope='Full correctness only; authenticated targeted PASS prerequisite; original failing baseline never relabelled PASS',targeted_catalog_sha=a.targeted_catalog_sha,support_manifest_sha=a.support_manifest_sha))
    records=[];pms_records=[];coverage=[]
    def termination(s,f):raise RuntimeError('External signal '+str(s))
    signal.signal(signal.SIGTERM,termination);signal.signal(signal.SIGINT,termination)
    try:
        window=guard_module.Guard(out,identities,critical,4200)
        sources={};binaries_by_version={};standalone={};engine_objects={}
        for version,src in [('baseline',package/'baseline'),('candidate',package/'candidate')]:
            source=out/version;shutil.copytree(src,source);sources[version]=source
            data=source/'data/matrices';data.mkdir(parents=True)
            for p in (package/'inputs').iterdir():shutil.copyfile(p,data/p.name)
            for p in source.rglob('*'):
                if p.is_file():source_pins[str(p)]=sha(p)
            original_source=t0/'baseline' if version=='baseline' else targeted/'candidate'
            binaries_by_version[version]=original_source/'bin/distqldpc'
            standalone[version]=original_source/'bin/maxcdcl'
            engine_objects[version]={n:original_source/'build'/(n+'.o') for n in ['SimpSolver','Solver','Options','System']}
            for p in [binaries_by_version[version],standalone[version],*engine_objects[version].values()]:
                assert str(p) in pins,'Consumed production object/binary absent authenticated prior raw catalogue'
                assert sha(p)==pins[str(p)];objects[str(p)]=pins[str(p)]
        save(out/'consumed-original-production-pins.json',objects)
        def run(argv,cwd,label,limit):
            try:rc,stdout,stderr=window.run(argv,cwd,label,limit)
            except BaseException:
                if window.commands and window.commands[-1].get('label')==label:
                    row=window.commands[-1];name=Path(argv[0]).name
                    if (name in ('maxcdcl','distqldpc') or name.endswith('-test-only')) and 'returncode' in row:
                        allowed=(10,20) if name=='maxcdcl' else (0,1)
                        if row['returncode'] not in allowed:
                            raise science.ScienceError('Actual returned solver crash/invalid rc '+label+' rc='+str(row['returncode']))
                raise
            try:text=stdout.decode('utf8');error=stderr.decode('utf8')
            except UnicodeDecodeError as e:
                name=Path(argv[0]).name
                if name in ('maxcdcl','distqldpc') or name.endswith('-test-only'):
                    raise science.ScienceError('Invalid scientific UTF8 '+label) from e
                raise RuntimeError('Invalid engineering UTF8 '+label) from e
            return rc,text,error
        def checked(argv,cwd,label,limit):
            rc,text,error=run(argv,cwd,label,limit)
            if rc!=0:
                if label.endswith('-dump') or label.startswith('smoke-'):
                    raise science.ScienceError('Original output/dump/smoke failed '+label+' rc='+str(rc))
                raise RuntimeError('Engineering setup/build/link failed '+label+' rc='+str(rc))
            return text
        def link_proof(binary,label):
            text=checked(['/usr/bin/ldd',binary],out,label,10);dependencies=[]
            assert 'not found' not in text
            for line in text.splitlines():
                m=re.search(r'=>\s+(/\S+)',line) or re.match(r'\s*(/\S+)',line)
                if not m:continue
                p=Path(m.group(1));r=str(p.resolve());assert r in runtime['files'] and sha(p)==runtime['files'][r]
                dependencies.append(dict(path=str(p),resolved=r,sha256=sha(p)))
            assert dependencies;save(out/(label+'.dependencies.json'),dependencies)
        def pin(p):
            p=Path(p);h=sha(p);assert str(p) not in binaries or binaries[str(p)]==h
            binaries[str(p)]=h
            if p.read_bytes()[:4]==b'\x7fELF' and p.stat().st_mode&0o111:link_proof(p,p.name+'-ELF-link')
        corpus=load('gh58_full_corpus',support/'corpus.py')
        for version in sources:
            link_proof(binaries_by_version[version],version+'-app-ELF-link')
            link_proof(standalone[version],version+'-Main-ELF-link')
        result=corpus.execute(run,checked,pin,sources,binaries_by_version,standalone,engine_objects,package/'fixtures',package/'inputs',out,science,runtime['compiler'])
        identities();save(out/'new-test-only-pins.json',binaries)
        summary.update(status='FULL_TIER0_LOCAL_PASS',Tier0='LOCAL_PASS',science_correct=True,counts=result,original_known_failure='RETAINED_EXPECTED_FAIL_NOT_WAIVED',new_baseline='NOT_DESIGNATED',performance='NOT_MEASURED')
    except science.ScienceError as error:summary.update(status='SCIENTIFIC_REJECT',Tier0='REJECT',science_reject=True,science_reason=str(error))
    except science.CoverageGap as error:summary.update(status='INCONCLUSIVE',Tier0='INCONCLUSIVE',coverage_reason=str(error))
    except BaseException as error:summary.update(status='INCONCLUSIVE',Tier0='INCONCLUSIVE',engineering_reason=repr(error))
    finally:
        if window is not None:
            try:
                summary['cleanup']=window.close()
                summary['cleanup_valid']=bool(summary['cleanup'].get('owned_empty') and summary['cleanup'].get('actual_restore') and not any(k in summary['cleanup'] for k in ['cleanup_error','restore_error','lease_error']))
            except BaseException as error:summary.update(cleanup_valid=False,cleanup_error=repr(error))
        try:identities();full_runtime();summary['identity_valid']=True
        except BaseException as error:summary.update(identity_valid=False,identity_error=repr(error))
        summary['valid_evidence']=bool(summary.get('cleanup_valid') and summary.get('identity_valid'))
        if not summary['valid_evidence'] and not summary.get('science_reject'):summary.update(status='INCONCLUSIVE',Tier0='INCONCLUSIVE')
        save(out/'summary.json',summary);save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json'})
        print(json.dumps(summary),flush=True)
    return 0 if summary['valid_evidence'] and summary['status']=='FULL_TIER0_LOCAL_PASS' else 1
if __name__=='__main__':sys.exit(main())
