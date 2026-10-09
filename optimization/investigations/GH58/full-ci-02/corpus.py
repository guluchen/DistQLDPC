"""Finite correctness corpus shared by guarded native and ordinary CI adapters.

No execution on import. Adapters own process/resource/identity/deadline policies.
run returns (returncode, strict UTF8 stdout, stderr); pin authenticates newly
created files before consumption. ScienceMismatch stops immediately.
"""
import hashlib,json,re

def execute(run, checked, pin, sources, binaries, standalone, objects,
            fixtures, inputs, out, science, compiler):
    records=[];pms_records=[];coverage=[];tight=set();offset=set()
    def save(name,data):
        (out/name).write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
    def app(argv,cwd,label,exact,timeout=False):
        rc,text,error=run(argv,cwd,label,20)
        result=science.app(rc,text,exact,timeout)
        records.append(dict(label=label,result=result));save('science.json',records)
        return rc,text,error
    modes=['no-card','card-sinz','card-mto','card-both','card-both-force']
    for stem in ['css1','css4','css5','css-fallback']:
        exact=science.css(stem,fixtures)
        for mode in modes:
            dumps=[]
            for version,binary in binaries.items():
                label=stem+'-'+mode+'-'+version
                app([binary,'-v','-cpu-lim=5','-'+mode,fixtures/stem],sources[version],label,exact)
                dump=out/(label+'.wcnf')
                checked([binary,'-'+mode,'-dump-only','-dump-wcnf='+str(dump),fixtures/stem],sources[version],label+'-dump',20)
                science.need(dump.is_file(),'Required CSS dump missing')
                pin(dump);dumps.append(dump.read_bytes())
            science.need(dumps[0]==dumps[1],'CSS WCNF changed after bookkeeping repair')
    for version,binary in binaries.items():
        checked(['/usr/bin/bash',sources[version]/'scripts/smoke_test.sh',binary],sources[version],'smoke-'+version,20)
        # Smoke script intentionally suppresses scientific streams; additionally
        # validate original LP34 explicitly, with a deadline generous for coverage.
        app([binary,'-v','-cpu-lim=20',inputs/'LP_34_20_2'],sources[version],'lp34-'+version,2)
        for mode in ['no-card','card-mto']:
            label='production-one-second-'+version+'-'+mode
            rc,text,error=app([binary,'-v','-'+mode,'-cpu-lim=1',inputs/'LP_340_56_8'],sources[version],label,8,True)
            coverage.append(dict(label=label,genuine_timeout=rc==1))
            save('timeout-coverage.json',coverage)
    rows=json.loads((fixtures/'pms-oracles.json').read_text());science.need(len(rows)==40,'Original forty PMS rows required')
    for row in rows:
        p=fixtures/row['name'];truth=science.wcnf(p.read_bytes())
        science.need(truth==row['oracle'] and hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],'PMS oracle/input mismatch')
        stem=p.stem;exact=truth['exact'];cap=exact
        for kind in ['ordinary','provided']:
            for version,binary in standalone.items():
                label=stem+'-'+version+'-'+kind
                argv=[binary,'-verb=1',p]+([str(cap)] if kind=='provided' else [])
                rc,text,error=run(argv,sources[version],label,20)
                result=science.pms(rc,text,exact)
                pms_records.append(dict(label=label,oracle=truth,result=result));save('pms-results.json',pms_records)
                if kind=='provided':
                    science.need(re.findall(r'^c initial UB:\s*(\d+)\s*$',text,re.M)==[str(cap if cap else 2147483647)],'Original inclusive cap CLI changed')
                    provided=re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)
                    if cap>0 and provided and int(provided[0])>=2 and re.search(r'^c UB=1 fails,',text,re.M):tight.add(version)
                    if stem=='pms-root-cap-offset':
                        science.need(provided==['1'],'Root-offset tight normalization missing');offset.add(version+'-P1')
        if stem=='pms-root-cap-offset':
            science.need(exact==1 and truth['loose_cost']==2,'Root-offset independent witness costs changed')
            for version,binary in standalone.items():
                label=stem+'-'+version+'-loose'
                rc,text,error=run([binary,'-verb=1',p,'2'],sources[version],label,20)
                result=science.pms(rc,text,exact)
                science.need(re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)==['2'],'Root-offset loose normalization missing')
                offset.add(version+'-P2');pms_records.append(dict(label=label,oracle=truth,result=result));save('pms-results.json',pms_records)
    if tight!={'baseline','candidate'} or len(offset)!=4:
        raise science.CoverageGap('Required tight-residual/root-offset paths not covered')
    save('cap-coverage.json',dict(tight=sorted(tight),offset=sorted(offset)))
    flags=['-Isrc/solver','-Wall','-Wno-parentheses','-O3','-g','-D__STDC_LIMIT_MACROS','-D__STDC_FORMAT_MACROS','-DNDEBUG']
    for version,source in sources.items():
        original=(source/'src/solver/Solver.cc').read_bytes().replace(b'\r\n',b'\n')
        for phase in ['pre-search','post-model']:
            if phase=='pre-search':
                science.need(original.count(b'emitTryUpdate(UB);')==1,'Pre-search hook site ambiguous')
                expected=original.replace(b'emitTryUpdate(UB);',b'emitTryUpdate(UB); ::sleep(3);')
            else:
                start=original.index(b'void Solver::noteBestSolution(');end=original.index(b'void Solver::printBestSolution()',start)
                section=original[start:end];science.need(section.count(b'emitBoundsUpdate();')==1,'Model hook site ambiguous')
                expected=original[:start]+section.replace(b'emitBoundsUpdate();',b'emitBoundsUpdate(); ::sleep(3);')+original[end:]
            tag=version+'-'+phase;hook=out/(tag+'-test-only-Solver.cc')
            hook.write_bytes(b'#include <unistd.h>\n'+expected);pin(hook)
            obj=out/(tag+'.o');binary=out/(tag+'-test-only')
            checked([compiler,*flags,'-c',hook,'-o',obj],source,tag+'-hook-build',120);pin(obj)
            rest=[objects[version][n] for n in ['SimpSolver','Options','System']]
            # App translation unit first, then original engine order with only
            # the test-only Solver object replaced. Production objects untouched.
            checked([compiler,*flags,source/'src/core/distqldpc.cc',rest[0],obj,*rest[1:],'-lz','-o',binary],source,tag+'-app-build',120);pin(binary)
            # Adapter verifies frozen GNU ELF closure for every executable pin.
            for mode in ['no-card','card-mto']:
                label=tag+'-timeout-'+mode
                rc,text,error=app([binary,'-v','-'+mode,'-cpu-lim=1',fixtures/'css4'],source,label,2,True)
                ub=re.findall(r'^c\s+d_ub:\s*(.*?)\s*$',text,re.M)
                science.need(ub,'Forced timeout bound trailer missing')
                if phase=='post-model' and ub[-1]=='-':
                    raise science.CoverageGap('Sound genuine timeout did not retain the required model incumbent')
                science.need(bool(re.fullmatch(r'\d+',ub[-1])) if phase=='post-model' else ub[-1]=='-','Forced timeout incumbent phase wrong')
                coverage.append(dict(label=label,phase=phase,genuine_timeout=True,ub=ub[-1]));save('timeout-coverage.json',coverage)
            save(tag+'-hook-provenance.json',dict(original_source_sha=hashlib.sha256((source/'src/solver/Solver.cc').read_bytes()).hexdigest(),hook_sha=hashlib.sha256(hook.read_bytes()).hexdigest(),object_sha=hashlib.sha256(obj.read_bytes()).hexdigest(),binary_sha=hashlib.sha256(binary.read_bytes()).hexdigest(),production_unchanged=True))
    science.need(len(records)==54 and len(pms_records)==162 and len(coverage)==12,'Full corpus count incomplete')
    return dict(application=54,PMS=162,WCNF_dumps=40,smokes=2,timeouts=12,production_rebuilt=False,performance='NOT_MEASURED')
