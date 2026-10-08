"""Disabled GH41 capacity-only correctness Tier0; no Tier1 auto-advance or exclusivity claim."""
import argparse,hashlib,importlib.util,json,os,re,shutil,sys,time,signal
from pathlib import Path
ASSIGNED_URL='HOST_SLOT_NOT_ASSIGNED'
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='66cf8be5a4881643f2063471325e33cecaa0caf1'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):Path(p).write_text(json.dumps(v,indent=2)+'\n',encoding='utf8')
def load_module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
def main():
    ap=argparse.ArgumentParser()
    for name in ['package','out','runtime-inventory']:ap.add_argument('--'+name,type=Path,required=True)
    for name in ['run-assignment','manifest-sha','runtime-sha','support-sha']:ap.add_argument('--'+name,required=True)
    ap.add_argument('--cpu',type=int,required=True);ap.add_argument('--sibling',type=int,required=True)
    args=ap.parse_args();assert ASSIGNED_URL!='HOST_SLOT_NOT_ASSIGNED' and args.run_assignment==ASSIGNED_URL
    assert os.environ.get('PYTHONDONTWRITEBYTECODE')=='1' and sys.dont_write_bytecode,'Explicit read-only bytecode cache policy required'
    assert sys.platform=='linux' and os.geteuid()!=0,'Fresh unprivileged Linux run only'
    package=args.package.resolve();out=args.out.resolve()
    assert out.parent==Path.home() and not out.exists(),'Fresh direct user-home output'
    manifest_path=package/'manifest.json';assert sha(manifest_path)==args.manifest_sha
    manifest=json.loads(manifest_path.read_text());assert manifest['baseline']==BASE and manifest['candidate']==CAND
    assert manifest['support_head']==args.support_sha
    pins={str(manifest_path):args.manifest_sha}
    for name,digest in manifest['files'].items():
        p=(package/name).resolve();assert p.is_relative_to(package)
        assert sha(p)==digest,'Package identity changed: '+name;pins[str(p)]=digest
    assert sha(__file__)==manifest['files']['support/server_tier0_correctness.py'],'Executed driver differs from package'
    inventory_path=args.runtime_inventory.resolve();assert sha(inventory_path)==args.runtime_sha
    runtime=json.loads(inventory_path.read_text());assert runtime['metadata_only'] is True and runtime['schema_version']==2
    assert runtime['identity_policy']=='FULL_PRE_IMPORT_AND_POST_RUN_CRITICAL_PER_COMMAND'
    assert runtime['cache_policy']=='DONTWRITE_BYTECODE_FULL_PRE_POST_EXISTING_PYC'
    assert not any(p.name=='__pycache__' or p.suffix=='.pyc' for p in package.rglob('*')),'Fresh package must contain no support bytecode caches'
    assert runtime['critical_files'] and all(runtime['files'].get(p)==v for p,v in runtime['critical_files'].items())
    assert runtime['gcc_version'].split('.')[0]=='13' and runtime['build']=='NOT_RUN' and runtime['solver']=='NOT_RUN'
    assert str(Path(sys.executable).resolve())==runtime['python'],'Python runtime changed'
    pins[str(inventory_path)]=args.runtime_sha
    for path,digest in runtime['files'].items():assert sha(path)==digest,'Full runtime changed before import: '+path
    for path,digest in runtime['critical_files'].items():pins[path]=digest
    assert sha(package/'support/server_tier0_correctness_supervisor.py')==manifest['files']['support/server_tier0_correctness_supervisor.py'],'Correctness guard changed before import'
    # Package manifest + explicit assignment pin support before any module import.
    supervisor=load_module('gh41_linux_supervisor',package/'support/server_tier0_correctness_supervisor.py')
    science=load_module('gh41_linux_science',package/'support/server_science.py')
    assert supervisor.RUN_ASSIGNMENT==args.run_assignment,'Supervisor assignment not frozen'
    def termination(signum,frame):raise RuntimeError('External termination signal '+str(signum))
    signal.signal(signal.SIGTERM,termination)
    assert not any(os.environ.get(key) for key in ['CXX','CXXFLAGS','LDFLAGS','MAKEFLAGS','LD_PRELOAD','LD_LIBRARY_PATH'])
    os.environ['PATH']='/usr/bin:/bin';window=None;records=[];pms_records=[];coverage=[]
    summary=dict(status='INCONCLUSIVE',Tier0='NOT_RUN',Tier1='NOT_RUN',performance='NOT_MEASURED',
        classification='CORRECTNESS_CAPACITY_ONLY',exclusive=False,candidate=CAND,baseline=BASE,
        assignment=args.run_assignment,support_head=args.support_sha)
    compiler=runtime['compiler'];make=runtime['make'];source_pins={};binary_pins={}
    def full_runtime_identity():
        for path,digest in runtime['files'].items():assert sha(path)==digest,'Full runtime changed after run: '+path
    def identities():
        for p,digest in dict(pins,**source_pins,**binary_pins).items():assert sha(p)==digest,'Identity changed: '+p
    def run(argv,cwd,label,limit=20):
        identities();command=window.run(argv,cwd,limit,label);identities()
        text=(out/(label+'.stdout')).read_bytes().decode('utf8',errors='replace')
        error=(out/(label+'.stderr')).read_bytes().decode('utf8',errors='replace')
        return command['returncode'],text,error
    def checked(argv,cwd,label,limit=20):
        rc,text,error=run(argv,cwd,label,limit)
        if rc!=0:raise RuntimeError('Build/test setup command failed: '+label)
        return text
    def app_run(argv,cwd,label,exact,timeout=False):
        rc,text,error=run(argv,cwd,label)
        result=science.app(rc,text,exact,timeout=(timeout or rc==1));records.append(dict(label=label,result=result));save(out/'science.json',records)
        if rc==1 and not timeout:
            raise science.CoverageGap('Independently sound TIMEOUT prevents required complete science coverage: '+label)
        return rc,text,error
    def verify_link(binary,label):
        text=checked(['/usr/bin/ldd',binary],out,label)
        dependencies=[]
        for line in text.splitlines():
            match=re.search(r'=>\s+(/\S+)',line) or re.match(r'\s*(/\S+)',line)
            if not match:continue
            p=Path(match.group(1));resolved=str(p.resolve());assert resolved in runtime['files'],'Uninventoried loaded library: '+str(p)
            assert sha(p)==runtime['files'][resolved],'Loaded library changed';dependencies.append(dict(path=str(p),resolved=resolved,sha256=sha(p)))
        save(out/(label+'.dependencies.json'),dependencies)
    try:
        window=supervisor.CorrectnessCapacity(out,args.cpu,args.sibling,args.run_assignment,2700)
        save(out/'preexecution.json',dict(package_manifest_sha=args.manifest_sha,runtime_inventory_sha=args.runtime_sha,
            pins=pins,cpu=args.cpu,sibling=args.sibling,original_flags='Makefile unchanged O3; make -j1 CXX='+compiler,
            baseline=BASE,candidate=CAND,support_head=args.support_sha,assignment=args.run_assignment,
            runtime_identity_policy=runtime['identity_policy'],full_runtime_files=len(runtime['files']),critical_runtime_files=len(runtime['critical_files']),
            Tier1='NOT_RUN',exclusive=False,classification='CORRECTNESS_CAPACITY_ONLY',performance='NOT_MEASURED',science_target=52,PMS_target=162,helper_target=21840))
        shutil.copyfile(__file__,out/'executed-driver.py');shutil.copyfile(package/'support/server_tier0_correctness_supervisor.py',out/'executed-correctness-supervisor.py')
        shutil.copyfile(package/'support/server_science.py',out/'executed-science.py');shutil.copyfile(inventory_path,out/'runtime-inventory.json')
        shutil.copytree(package,out/'frozen-package')
        for p in (out/'frozen-package').rglob('*'):
            if p.is_file():source_pins[str(p)]=sha(p)
        sources={};binaries={};standalone={}
        for version in ['baseline','candidate']:
            source=out/version;shutil.copytree(package/version,source);sources[version]=source
            data=source/'data/matrices';data.mkdir(parents=True)
            for p in (package/'inputs').iterdir():shutil.copyfile(p,data/p.name)
            for p in source.rglob('*'):
                if p.is_file():source_pins[str(p)]=sha(p)
            checked([make,'-j1','CXX='+compiler,'bin/distqldpc','bin/maxcdcl'],source,'build-'+version,300)
            binaries[version]=source/'bin/distqldpc';standalone[version]=source/'bin/maxcdcl'
            for binary in [binaries[version],standalone[version]]:binary_pins[str(binary)]=sha(binary);verify_link(binary,version+'-'+binary.name+'-link')
        save(out/'binary-hashes.json',{v:sha(p) for v,p in binaries.items()})
        save(out/'standalone-hashes.json',{v:sha(p) for v,p in standalone.items()})
        objects=lambda source:[source/'build'/(name+'.o') for name in ['SimpSolver','Solver','Options','System']]
        helper_dir=sources['candidate']/'optimization/experiments/GH-41';helper_dir.mkdir(parents=True)
        helper=helper_dir/'test_witness.cc';shutil.copyfile(package/'support/test_witness.cc',helper)
        source_pins[str(helper)]=sha(helper);probe=out/'candidate-witness-fixture'
        checked([compiler,'-Isrc/solver','-O2','-std=gnu++11',helper,*objects(sources['candidate']),'-lz','-o',probe],sources['candidate'],'helper-build',120)
        binary_pins[str(probe)]=sha(probe);verify_link(probe,'helper-link')
        trace=checked([probe],out,'helper-trace',30)
        science.need('WITNESS_ORACLE_PASS cases=21840 plus_multirow' in trace,'Actual helper oracle terminal missing')
        science.need(not (out/'helper-trace.stderr').read_bytes(),'Actual helper unexpected stderr')
        fixtures=package/'fixtures'
        for stem in ['css1','css4','css5','css-fallback']:
            exact=science.css(stem,fixtures)
            for mode in ['no-card','card-sinz','card-mto','card-both','card-both-force']:
                dumps=[];semantics=[]
                for version,binary in binaries.items():
                    label=stem+'-'+mode+'-'+version
                    rc,text,error=app_run([binary,'-v','-cpu-lim=5','-'+mode,fixtures/stem],sources[version],label,exact)
                    semantics.append(records[-1]['result']);dump=out/(label+'.wcnf')
                    checked([binary,'-'+mode,'-dump-only','-dump-wcnf='+str(dump),fixtures/stem],sources[version],label+'-dump')
                    dumps.append(dump.read_bytes())
                science.need(dumps[0]==dumps[1] and semantics[0]==semantics[1],'CSS WCNF/output semantics changed')
                if mode!='card-mto':
                    before=(out/(stem+'-'+mode+'-baseline.stdout')).read_bytes()
                    after=(out/(stem+'-'+mode+'-candidate.stdout')).read_bytes()
                    cap_pattern=rb'^c (?:initial UB|provided UB|UB=\d+ fails)[^\r\n]*'
                    science.need(re.findall(cap_pattern,before,re.M)==re.findall(cap_pattern,after,re.M),'Non-MTO bound-search cap path changed')
        for version,binary in binaries.items():
            checked(['/usr/bin/bash',sources[version]/'scripts/smoke_test.sh',binary],sources[version],'smoke-'+version)
            for mode in ['no-card','card-mto']:
                label='production-1s-'+version+'-'+mode
                rc,text,error=run([binary,'-v','-'+mode,'-cpu-lim=1',package/'inputs/LP_340_56_8'],sources[version],label)
                result=science.app(rc,text,8,timeout=(rc==1));records.append(dict(label=label,result=result));save(out/'science.json',records)
                coverage.append(dict(kind='production-one-second',version=version,mode=mode,returncode=rc,actual_timeout=(rc==1),independently_correct_completion=(rc==0)))
                save(out/'production-timeout-coverage.json',[r for r in coverage if r.get('kind')=='production-one-second'])
        original_oracles=json.loads((package/'windows-provenance/pms-oracle.json').read_text());assert len(original_oracles)==40
        pms_count=0;tight_versions=set();offset_versions=set()
        for row in original_oracles:
            stem=row['stem'];wcnf=fixtures/(stem+'.wcnf');exact,witness,loose=science.wcnf(wcnf.read_bytes())
            science.need(exact==row['oracle'] and sha(wcnf)==row['input_sha256'],'Original PMS input/oracle mismatch')
            results={}
            for kind in ['ordinary','provided']:
                results[kind]=[]
                for version,binary in standalone.items():
                    argv=[binary,'-verb=1',wcnf]+([str(witness[1])] if kind=='provided' else [])
                    label=stem+'-'+version+'-'+kind;rc,text,error=run(argv,sources[version],label)
                    result=science.pms(rc,text,exact);pms_count+=1;results[kind].append(result)
                    if kind=='provided':
                        accepted=witness[1] if witness[1]>0 else 2147483647
                        science.need(re.findall(r'^c initial UB:\s*(\d+)\s*$',text,re.M)==[str(accepted)],'Original Main cap CLI semantics changed')
                        provided=re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)
                        if witness[1]>0 and provided and int(provided[0])>=2 and re.search(r'^c UB=1 fails,',text,re.M):
                            tight_versions.add(version);coverage.append(dict(stem=stem,version=version,cap=witness[1],strict_providedUB=int(provided[0]),failed_bound=1))
                        if stem=='pms-root-cap-offset':
                            science.need(provided==['1'],'Root offset P1 normalization missing');offset_versions.add(version+'-P1')
                    pms_records.append(dict(label=label,original_exact=exact,verified_witness=witness,result=result));save(out/'pms-results.json',pms_records)
                science.need(results[kind][0]==results[kind][1],'PMS status/return semantics mismatch')
            if stem=='pms-root-cap-offset':
                science.need(witness[1]==1 and loose[1]==2,'Original offset witness changed')
                for version,binary in standalone.items():
                    label=stem+'-'+version+'-loose';rc,text,error=run([binary,'-verb=1',wcnf,str(loose[1])],sources[version],label)
                    result=science.pms(rc,text,exact);pms_count+=1
                    science.need(re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)==['2'],'Root offset P2 normalization missing');offset_versions.add(version+'-P2')
                    pms_records.append(dict(label=label,original_exact=exact,verified_witness=loose,result=result));save(out/'pms-results.json',pms_records)
        if tight_versions!={'baseline','candidate'} or len(offset_versions)!=4:raise science.CoverageGap('Tight residual/offset normalization paths not covered')
        save(out/'offset-and-tight-coverage.json',dict(offset=sorted(offset_versions),tight=coverage))
        flags=['-Isrc/solver','-Wall','-Wno-parentheses','-O3','-g','-D__STDC_LIMIT_MACROS','-D__STDC_FORMAT_MACROS','-DNDEBUG']
        for version,source in sources.items():
            original=(source/'src/solver/Solver.cc').read_bytes().replace(b'\r\n',b'\n')
            for phase in ['pre-search','post-model']:
                if phase=='pre-search':
                    assert original.count(b'emitTryUpdate(UB);')==1
                    expected=original.replace(b'emitTryUpdate(UB);',b'emitTryUpdate(UB); ::sleep(3);')
                else:
                    start=original.index(b'void Solver::noteBestSolution(');end=original.index(b'void Solver::printBestSolution()',start)
                    section=original[start:end];assert section.count(b'emitBoundsUpdate();')==1
                    expected=original[:start]+section.replace(b'emitBoundsUpdate();',b'emitBoundsUpdate(); ::sleep(3);')+original[end:]
                tag=version+'-'+phase;hook=fixtures/(tag+'-test-only-Solver.cc')
                assert hook.read_bytes().replace(b'\r\n',b'\n')==b'#include <unistd.h>\n'+expected,'Hook provenance differs from exact original test-only sleep'
                obj=out/(tag+'.o');binary=out/(tag+'-test-only')
                checked([compiler,*flags,'-c',hook,'-o',obj],source,tag+'-hook-build',120)
                rest=[source/'build'/(name+'.o') for name in ['SimpSolver','Options','System']]
                checked([compiler,*flags,source/'src/core/distqldpc.cc',obj,*rest,'-lz','-o',binary],source,tag+'-app-build',120)
                binary_pins[str(binary)]=sha(binary);verify_link(binary,tag+'-link')
                for mode in ['no-card','card-mto']:
                    label=tag+'-timeout-'+mode
                    rc,text,error=app_run([binary,'-v','-'+mode,'-cpu-lim=1',fixtures/'css4'],source,label,2,True)
                    found=re.findall(r'^c\s+d_ub:\s*(\d+)\s*$',text,re.M)
                    if phase=='post-model' and not found:
                        raise science.CoverageGap('Independently sound forced TIMEOUT did not reach required post-model phase: '+label)
                    science.need(not found if phase=='pre-search' else bool(found),'Forced pre-search unexpected model or malformed model phase')
                save(out/(tag+'-hook-provenance.json'),dict(source_sha=sha(hook),object_sha=sha(obj),binary_sha=sha(binary),production_engine_untouched=True))
        science.need(len(records)==52 and pms_count==162,'Incomplete original scientific corpus')
        identities();save(out/'postexecution-identities.json',dict(package=True,critical_runtime=True,full_runtime='CHECKED_IN_FINALLY',source=True,input=True,binary=True))
        summary.update(status='TIER0_COMPLETE',Tier0='LOCAL_PASS',science=52,PMS=162,helper=21840,diagnostic='NOT_REQUESTED',
            classification='CORRECTNESS_CAPACITY_ONLY',decision='INCONCLUSIVE',reason='Correctness capacity-only science gate complete; performance NOT_MEASURED; no idle/exclusivity claim')
    except science.ScienceError as error:
        summary.update(status='SCIENTIFIC_REJECT',Tier0='REJECT',reason=str(error));print('SCIENCE STOP: '+str(error),flush=True)
    except BaseException as error:summary['reason']=repr(error)
    finally:
        if window is not None:
            try:window.close();summary['cleanup_restoration_confirmed']=True
            except BaseException as error:summary.update(cleanup_restoration_confirmed=False,cleanup_error=repr(error))
        if out.exists():
            try:
                identities();full_runtime_identity();summary['identity_confirmed']=True
                save(out/'full-runtime-postexecution.json',dict(confirmed=True,files=len(runtime['files']),policy=runtime['identity_policy']))
            except BaseException as error:summary.update(identity_confirmed=False,identity_error=repr(error))
            summary['valid_run']=bool(summary['status']=='TIER0_COMPLETE' and summary.get('cleanup_restoration_confirmed') and summary.get('identity_confirmed'))
            if not summary['valid_run'] and summary['status']!='SCIENTIFIC_REJECT':summary.update(status='INCONCLUSIVE',Tier0='INCONCLUSIVE')
            save(out/'summary.json',summary)
            save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json'})
        print(json.dumps(summary,indent=2),flush=True)
    return 0 if summary.get('valid_run') else 1
if __name__=='__main__':sys.exit(main())
