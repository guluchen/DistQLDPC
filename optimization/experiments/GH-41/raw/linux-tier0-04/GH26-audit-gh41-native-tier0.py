"""Offline independent GH41 native Tier0 audit. No imports from evidence/no execution.
Original tar is read in place; only a NEW audit JSON is written outside raw/checkouts.
Prepared source only; requires authenticated archive/package/runtime/support/absence.
"""
import argparse,hashlib,io,itertools,json,re,subprocess,tarfile
from pathlib import Path,PurePosixPath
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='66cf8be5a4881643f2063471325e33cecaa0caf1'
MODES=['no-card','card-sinz','card-mto','card-both','card-both-force']
VERSIONS=['baseline','candidate']
def digest(data):return hashlib.sha256(data).hexdigest()
def file_sha(path):
    h=hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda:stream.read(1048576),b''):h.update(chunk)
    return h.hexdigest()
def need(value,why):
    if not value:raise RuntimeError(why)
def app(rc,text,exact,timeout):
    values={}
    specs={'lb':(r'^c\s+d_lb:\s*(.*?)\s*$',{'-'}),'ub':(r'^c\s+d_ub:\s*(.*?)\s*$',{'-'}),
        'd':(r'^c\s+d\s*:\s*(.*?)\s*$',{'UNKNOWN'}),'objective':(r'^o(?:\s+(.*?))?\s*$',set())}
    for key,(pattern,sentinels) in specs.items():
        raw=re.findall(pattern,text,re.M)
        for item in raw:
            if item in sentinels:continue
            need(isinstance(item,str) and re.fullmatch(r'\d+',item),'Malformed science '+key)
            value=int(item);need(value<=exact if key=='lb' else value==exact if key=='d' else value>=exact,'Wrong interim '+key)
        values[key]=int(raw[-1]) if raw and isinstance(raw[-1],str) and re.fullmatch(r'\d+',raw[-1]) else None
    statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M);comments=re.findall(r'^c status:\s*(.*?)\s*$',text,re.M)
    if timeout:
        need(rc==1 and statuses==['UNKNOWN'] and len(comments)==1 and comments[0].startswith('TIMEOUT'),'Timeout trailer/return')
        need(re.findall(r'^c\s+d\s*:\s*(.*?)\s*$',text,re.M)==['UNKNOWN'],'Timeout distance trailer')
        need(values['d'] is None and values['objective'] is None and not re.search(r'^o(?:\s|$)',text,re.M),'Fabricated timeout optimum')
    else:
        need(rc==0 and not statuses and not comments and all(v==exact for v in values.values()),'Complete science mismatch')
    return dict(values,returncode=rc,timeout=timeout)
def pms(rc,text,exact):
    vals=re.findall(r'optimal:\s*([^\s,]+)',text);statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M)
    need(rc in (10,20) and vals and all(re.fullmatch(r'\d+',v) and int(v)==exact for v in vals),'PMS optimum/return')
    need(statuses==(['SATISFIABLE'] if rc==10 else ['UNSATISFIABLE']),'PMS10/20 status relation')
    return dict(returncode=rc,statuses=statuses,optimal=exact)
def wcnf(data):
    rows=[];n=count=top=None
    for line in data.decode().splitlines():
        if not line.strip() or line.startswith('c'):continue
        parts=line.split()
        if parts[0]=='p':need(parts[1]=='wcnf','WCNF format');n,count,top=map(int,parts[2:]);continue
        row=list(map(int,parts));need(row[-1]==0 and row[0]>0,'Weighted clause encoding');rows.append((row[0],row[1:-1]))
    need(n is not None and n<=6 and len(rows)==count,'Exact bounded original WCNF')
    need(all(0<abs(p)<=n for _,c in rows for p in c),'WCNF literal range')
    sat=lambda c,a:any(bool(a&(1<<(abs(p)-1)))==(p>0) for p in c)
    feasible=[(a,sum(w for w,c in rows if w<top and not sat(c,a))) for a in range(1<<n) if all(sat(c,a) for w,c in rows if w>=top)]
    need(feasible,'Original fixture has no hard model')
    return min(v for _,v in feasible),min(feasible,key=lambda p:(p[1],p[0])),max(feasible,key=lambda p:(p[1],p[0]))
def pauli_exact(mats):
    n=len(mats['Hx'][0]);need(0<n<=5,'Small original CSS oracle scope')
    need(all(len(r)==n and set(r)<={0,1} for rs in mats.values() for r in rs),'CSS matrix shape')
    bits=lambda r:sum(v<<i for i,v in enumerate(r))
    hx=list(map(bits,mats['Hx']));hz=list(map(bits,mats['Hz']))
    # The authentic fallback has an incomplete logical-row basis. Test the
    # original builder predicate directly; compare quotient minima separately.
    gx=list(map(bits,mats['Gx']));gz=list(map(bits,mats['Gz']))
    def span(rows):
        out={0}
        for h in rows:out|={v^h for v in out}
        return out
    sx,sz=span(hx),span(hz);costs=[];quotient_costs=[]
    for x,z in itertools.product(range(1<<n),repeat=2):
        commuting=all((h&z).bit_count()%2==0 for h in hx) and all((h&x).bit_count()%2==0 for h in hz)
        if not commuting:continue
        logical=any((h&x).bit_count()%2 for h in gx) or any((h&z).bit_count()%2 for h in gz)
        quotient=(x not in sx or z not in sz)
        if logical:costs.append((x|z).bit_count())
        if quotient:quotient_costs.append((x|z).bit_count())
    need(costs and quotient_costs,'No original logical operator')
    need(min(costs)==min(quotient_costs),'Original logical/quotient minimum disagreement')
    return min(costs)
def main():
    ap=argparse.ArgumentParser()
    for name in ['archive','repo','absence-proof','out']:ap.add_argument('--'+name,type=Path,required=True)
    for name in ['archive-sha','prefix','package-sha','runtime-sha','support-sha','absence-sha','assignment']:ap.add_argument('--'+name,required=True)
    a=ap.parse_args();need(not a.out.exists(),'Fresh outside-raw audit output required')
    need(a.repo.resolve() not in a.out.resolve().parents and a.out.resolve() not in [a.archive.resolve(),a.absence_proof.resolve()],'Audit output outside checkout/evidence required')
    need(file_sha(a.archive)==a.archive_sha,'Original archive SHA proof')
    need(file_sha(a.absence_proof)==a.absence_sha,'Independent absence proof SHA')
    archive=tarfile.open(a.archive,'r:*');members={}
    for member in archive.getmembers():
        name=member.name.removeprefix('./');path=PurePosixPath(name)
        need(not path.is_absolute() and '..' not in path.parts and name not in members,'Unsafe/duplicate original tar member')
        need(member.isdir() or member.isfile(),'No symlinks/devices/other tar members accepted');members[name]=member
    prefix=a.prefix.strip('/');need(prefix and '..' not in PurePosixPath(prefix).parts,'Authenticated output prefix')
    def data(name):
        need(name in members and members[name].isfile(),'Missing original file '+name);return archive.extractfile(members[name]).read()
    def raw(name):return data(prefix+'/'+name)
    def js(name):return json.loads(raw(name))
    def outer(name):return json.loads(data(prefix+'.launcher'+name))
    sha_tree=js('SHA256.json');need(len(sha_tree)>=200,'Full original Tier0 tree')
    for name,value in sha_tree.items():
        need(not PurePosixPath(name).is_absolute() and '..' not in PurePosixPath(name).parts,'Raw manifest escape');need(digest(raw(name))==value,'Raw SHA mismatch '+name)
    actual_files={name[len(prefix)+1:] for name,m in members.items() if m.isfile() and name.startswith(prefix+'/')}
    # Original producer excludes every basename SHA256.json, including this
    # nested original Windows index. Its bytes are independently package-pinned.
    excluded={'frozen-package/windows-provenance/SHA256.json'}
    need(actual_files==set(sha_tree)|{'SHA256.json'}|excluded,'Raw manifest incomplete/extraneous files')
    raw_manifest_sha=digest(raw('SHA256.json'));summary=js('summary.json');pre=js('preexecution.json');manifest=js('frozen-package/manifest.json')
    need(summary['baseline']==BASE and summary['candidate']==CAND and summary['support_head']==a.support_sha and summary['assignment']==a.assignment,'Actual baseline/source/assignment')
    need(summary['status']=='TIER0_COMPLETE' and summary['valid_run'] is True and summary['Tier0']=='LOCAL_PASS','Actual complete summary')
    need(summary['classification']=='CORRECTNESS_CAPACITY_ONLY' and summary['performance']=='NOT_MEASURED','No timing/controlled claim')
    need(digest(raw('frozen-package/manifest.json'))==a.package_sha==pre['package_manifest_sha'],'Exact package pin')
    need(manifest['baseline']==BASE and manifest['candidate']==CAND and manifest['support_head']==a.support_sha,'Original package sources')
    for name,value in manifest['files'].items():need(digest(raw('frozen-package/'+name))==value,'Exact package member '+name)
    for name in excluded:need(name.removeprefix('frozen-package/') in manifest['files'],'Excluded nested index lacks package pin')
    runtime=js('runtime-inventory.json');need(digest(raw('runtime-inventory.json'))==a.runtime_sha==pre['runtime_inventory_sha'],'Runtime03 exact pin')
    need(runtime['schema_version']==2 and runtime['gcc_version']=='13.3.0' and runtime['cache_policy']=='DONTWRITE_BYTECODE_FULL_PRE_POST_EXISTING_PYC','Original native runtime/cache')
    need(runtime['critical_files'] and all(runtime['files'].get(p)==v for p,v in runtime['critical_files'].items()),'Critical runtime subset')
    need(js('full-runtime-postexecution.json')['confirmed'] is True and js('full-runtime-postexecution.json')['files']==len(runtime['files']),'Actual full runtime post loop')
    for version,commit in [('baseline',BASE),('candidate',CAND)]:
        tarbytes=raw('frozen-package/archives/'+version+'.tar');need(digest(tarbytes)==manifest['archives'][version],'Original Git source archive SHA')
        t=tarfile.open(fileobj=io.BytesIO(tarbytes));count=0
        original_paths=set(subprocess.check_output(['git','-C',str(a.repo),'ls-tree','-r','--name-only',commit,'--','Makefile','scripts/smoke_test.sh','src'],timeout=15).decode().splitlines())
        need({m.name for m in t.getmembers() if m.isfile()}==original_paths,'Complete original Git source set')
        for member in t.getmembers():
            if not member.isfile():continue
            need(not PurePosixPath(member.name).is_absolute() and '..' not in PurePosixPath(member.name).parts,'Source archive escape')
            blob=subprocess.check_output(['git','-C',str(a.repo),'show',commit+':'+member.name],timeout=15)
            exported=t.extractfile(member).read();need(exported.replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'),'Git source mismatch '+member.name)
            need(raw('frozen-package/'+version+'/'+member.name)==exported and raw(version+'/'+member.name)==exported,'Executed original source changed')
            count+=1
        need(count==len(original_paths) and count>=30,'Full original source archive')
        build=js('build-'+version+'.command.json');need(build['returncode']==0 and build['argv']==[runtime['make'],'-j1','CXX='+runtime['compiler'],'bin/distqldpc','bin/maxcdcl'],'Original native O3 build argv')
        need(build['cwd'].endswith('/'+version),'Build working tree')
        for name in ['SimpSolver','Solver','Options','System']:need(version+'/build/'+name+'.o' in sha_tree,'All original objects retained')
    # Authenticate actual support Git bytes, not success markers alone.
    for name in ['server_tier0_correctness.py','server_tier0_correctness_launcher.py','server_tier0_correctness_supervisor.py','server_science.py','test_witness.cc']:
        b=raw('frozen-package/support/'+name);blob=subprocess.check_output(['git','-C',str(a.repo),'show',a.support_sha+':optimization/experiments/GH-41/'+name],timeout=15)
        need(b.replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'),'Executed support differs from committed source '+name)
    need(raw('executed-driver.py')==raw('frozen-package/support/server_tier0_correctness.py') and raw('executed-correctness-supervisor.py')==raw('frozen-package/support/server_tier0_correctness_supervisor.py'),'Actual executed support identity')
    for filename in ['binary-hashes.json','standalone-hashes.json']:
        for version,value in js(filename).items():need(digest(raw(version+'/bin/'+('distqldpc' if filename.startswith('binary') else 'maxcdcl')))==value,'Frozen native binary')
    helper=raw('helper-trace.stdout');need(js('helper-trace.command.json')['returncode']==0 and not raw('helper-trace.stderr'),'Actual helper completed')
    need(helper.count(b'WITNESS_ORACLE_PASS cases=21840 plus_multirow')==1,'Actual21840 marker')
    helper_source=raw('frozen-package/support/test_witness.cc');need(b'for(int mode=0;mode<5;++mode)' in helper_source and b'!solver.hasCostUB()' in helper_source and b'mode==Solver::CARD_ENC_MTO ? expected : INT32_MAX' in helper_source,'Actual helper mode/no-model source assertions')
    helper_cmd=js('helper-build.command.json');need(helper_cmd['returncode']==0 and '-O2' in helper_cmd['argv'] and '-std=gnu++11' in helper_cmd['argv'] and helper_cmd['argv'][-1].endswith('/candidate-witness-fixture'),'Test-only helper original compile')
    need('candidate-witness-fixture' in sha_tree,'Helper binary retained')
    app_results={};expected_labels=set();css_answers={}
    def command(label):
        c=js(label+'.command.json');need(c.get('returncode') is not None and not c.get('error') and not c.get('cleanup_error'),'Actual command failure '+label)
        return c,raw(label+'.stdout').decode('utf8'),raw(label+'.stderr')
    link_labels=[v+'-'+b+'-link' for v in VERSIONS for b in ['distqldpc','maxcdcl']]+['helper-link']+[v+'-'+p+'-link' for v in VERSIONS for p in ['pre-search','post-model']]
    for label in link_labels:
        c,_,_=command(label);need(c['returncode']==0 and c['argv'][0]=='/usr/bin/ldd','Actual native dependency probe '+label)
        dependencies=js(label+'.dependencies.json');need(dependencies,'Missing native dependency identities '+label)
        for row in dependencies:need(runtime['files'].get(row['resolved'])==row['sha256'],'Native dependency runtime pin '+label)
    for stem in ['css1','css4','css5','css-fallback']:
        mats={k:[[int(v) for v in line.split()] for line in raw('frozen-package/fixtures/'+stem+'_'+k+'.txt').decode().splitlines() if line.strip()] for k in ['Hx','Hz','Gx','Gz']}
        exact=pauli_exact(mats);css_answers[stem]=exact
        for mode in MODES:
            outputs=[];dumps=[]
            for version in VERSIONS:
                label=stem+'-'+mode+'-'+version;c,text,err=command(label);need(not err,'Science stderr '+label);need('-'+mode in c['argv'] and '-cpu-lim=5' in c['argv'],'Original five-mode CLI')
                app_results[label]=app(c['returncode'],text,exact,False);expected_labels.add(label);outputs.append(text)
                d,_,err=command(label+'-dump');need(d['returncode']==0 and '-dump-only' in d['argv'] and not err,'Original dump command');dumps.append(raw(label+'.wcnf'))
            need(dumps[0]==dumps[1],'Initial WCNF byte equality '+stem+' '+mode)
            if mode!='card-mto':need(re.findall(r'^c (?:initial UB|provided UB|UB=\d+ fails)[^\r\n]*',outputs[0],re.M)==re.findall(r'^c (?:initial UB|provided UB|UB=\d+ fails)[^\r\n]*',outputs[1],re.M),'Non-MTO cap behavior')
    for version in VERSIONS:
        c,_,err=command('smoke-'+version);need(c['returncode']==0 and not err,'Original smoke result')
        for mode in ['no-card','card-mto']:
            label='production-1s-'+version+'-'+mode;c,text,err=command(label);need(not err and '-cpu-lim=1' in c['argv'],'Production timeout CLI');app_results[label]=app(c['returncode'],text,8,c['returncode']==1);expected_labels.add(label)
    pms_rows=js('frozen-package/windows-provenance/pms-oracle.json');need(len(pms_rows)==40,'Original forty PMS corpus');pms_results={};tight=set();offset=set()
    for row in pms_rows:
        stem=row['stem'];b=raw('frozen-package/fixtures/'+stem+'.wcnf');exact,witness,loose=wcnf(b);need(exact==row['oracle'] and digest(b)==row['input_sha256'],'Independent original weighted objective')
        for kind in ['ordinary','provided']:
            results=[]
            for version in VERSIONS:
                label=stem+'-'+version+'-'+kind;c,text,err=command(label);need(not err and '-verb=1' in c['argv'],'Native Main command');value=pms(c['returncode'],text,exact);pms_results[label]=value;results.append(value)
                if kind=='provided':
                    need(c['argv'][-1]==str(witness[1]),'Original feasible cap argument');need(re.findall(r'^c initial UB:\s*(\d+)\s*$',text,re.M)==[str(witness[1] or 2147483647)],'Main initial cap0 semantics')
                    provided=re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)
                    if witness[1]>0 and provided and int(provided[0])>=2 and re.search(r'^c UB=1 fails,',text,re.M):tight.add(version)
                    if stem=='pms-root-cap-offset':need(provided==['1'],'P1 root offset');offset.add(version+'-P1')
            need(results[0]==results[1],'Native standalone return/status/objective equality')
        if stem=='pms-root-cap-offset':
            need(witness[1]==1 and loose[1]==2,'Original offset witnesses')
            for version in VERSIONS:
                label=stem+'-'+version+'-loose';c,text,err=command(label);need(not err and c['argv'][-1]=='2','Original loose cap argument');pms_results[label]=pms(c['returncode'],text,exact);need(re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)==['2'],'P2 residual offset');offset.add(version+'-P2')
    need(len(pms_results)==162 and tight==set(VERSIONS) and len(offset)==4,'Exact PMS/offset/tight coverage')
    for version in VERSIONS:
        original=raw(version+'/src/solver/Solver.cc').replace(b'\r\n',b'\n')
        for phase in ['pre-search','post-model']:
            if phase=='pre-search':need(original.count(b'emitTryUpdate(UB);')==1,'Original try hook');body=original.replace(b'emitTryUpdate(UB);',b'emitTryUpdate(UB); ::sleep(3);')
            else:
                begin=original.index(b'void Solver::noteBestSolution(');end=original.index(b'void Solver::printBestSolution()',begin);section=original[begin:end];need(section.count(b'emitBoundsUpdate();')==1,'Original model hook');body=original[:begin]+section.replace(b'emitBoundsUpdate();',b'emitBoundsUpdate(); ::sleep(3);')+original[end:]
            tag=version+'-'+phase;hook=raw('frozen-package/fixtures/'+tag+'-test-only-Solver.cc');need(hook.replace(b'\r\n',b'\n')==b'#include <unistd.h>\n'+body,'Exact original sleep-only source')
            h=js(tag+'-hook-provenance.json');need(digest(hook)==h['source_sha'] and digest(raw(tag+'.o'))==h['object_sha'] and digest(raw(tag+'-test-only'))==h['binary_sha'] and h['production_engine_untouched'] is True,'Actual hook object/binary/source hashes')
            for build_label in [tag+'-hook-build',tag+'-app-build']:c,_,_=command(build_label);need(c['returncode']==0 and '-O3' in c['argv'] and c['argv'][0]==runtime['compiler'],'Original symmetric hook compile')
            for mode in ['no-card','card-mto']:
                label=tag+'-timeout-'+mode;c,text,err=command(label);need(not err and '-cpu-lim=1' in c['argv'],'Forced original timeout CLI');app_results[label]=app(c['returncode'],text,css_answers['css4'],True);expected_labels.add(label)
                found=re.findall(r'^c\s+d_ub:\s*(\d+)\s*$',text,re.M);need(bool(found)==(phase=='post-model'),'Required authentic pre/post model timeout phase')
    need(len(app_results)==52 and len(expected_labels)==52,'Complete original scientific corpus')
    need({r['label'] for r in js('science.json')}==expected_labels,'Science record labels')
    for r in js('science.json'):need(r['result']==app_results[r['label']],'Original recorded science agrees with independent parser')
    need(len(js('pms-results.json'))==162 and {r['label'] for r in js('pms-results.json')}==set(pms_results),'PMS record labels')
    for r in js('pms-results.json'):need(r['result']==pms_results[r['label']],'Recorded PMS agrees with independent objective')
    need(summary['science']==52 and summary['PMS']==162 and summary['helper']==21840,'Summary count consistency')
    cleanups=[name for name in sha_tree if re.fullmatch(r'cleanup-\d+\.json',name)];need(cleanups,'Owned cleanup evidence')
    for name in cleanups:need(js(name)['confirmed'] is True and js(name)['remaining']==[],'Owned inner cleanup')
    context=js('context.json');restore=js('restoration.json');need(context['cpu']==6 and context['sibling']==134 and context['classification']=='CORRECTNESS_CAPACITY_ONLY','Original fixed correctness pair')
    need(context['topology']=='6,134' and context['performance']=='NOT_MEASURED','Actual SMT topology/no performance claim')
    resources=js('resources.json');need(resources,'Retained resource samples')
    for row in resources:need(row['global_idle']>.5 and row['half_spare_workers']>=1 and row['idle_prerequisite_enforced'] is False and row['resource_policy']=='CORRECTNESS_CAPACITY_ONLY','Correctness capacity guard samples')
    need(restore['confirmed'] is True and restore['actual_affinity']==context['original_affinity'],'Actual inner affinity restore')
    outer_report=outer('.json');data(prefix+'.launcher.stdout');data(prefix+'.launcher.stderr')
    need(outer_report['state']=='CHILD_EXITED' and outer_report['returncode']==0 and outer_report['owned_empty'] is True and outer_report['remaining']==[] and outer_report['affinity_restored'] is True and outer_report['full_runtime_post_confirmed'] is True and outer_report['valid_transport'] is True,'Actual outer transport/owned/restore')
    need(outer_report['assignment']==a.assignment and outer_report['classification']=='CORRECTNESS_CAPACITY_ONLY','Outer scope/assignment')
    absence=json.loads(a.absence_proof.read_bytes());need(absence['assignment']==a.assignment and absence['session_id']==outer_report['pid'] and absence['leader_birth']==outer_report['leader']['birth'],'Independent post-exit identity')
    need(absence['probe_returncode']==0 and absence['remaining_session_members']==[] and absence['leader_proc_absent'] is True and absence['observed_after_outer_exit'] is True,'Actual independent /proc absence')
    need(absence['command'] and absence['stdout_hex'] is not None and absence['stderr_hex'] is not None and absence['observed_utc'],'Original absence-probe byte evidence')
    probe_stdout=json.loads(bytes.fromhex(absence['stdout_hex']));need(probe_stdout=={'leader_proc_absent':True,'remaining_session_members':[]},'Actual absence stdout independently parsed')
    need(summary['cleanup_restoration_confirmed'] is True and summary['identity_confirmed'] is True,'Final source/runtime identity flags')
    post=js('postexecution-identities.json');need(all(post[k] is True for k in ['package','critical_runtime','source','input','binary']) and post['full_runtime']=='CHECKED_IN_FINALLY','Actual complete post identity loops')
    report=dict(classification='GH41_NATIVE_TIER0_INDEPENDENT_AUDIT',baseline=BASE,candidate=CAND,assignment=a.assignment,support_head=a.support_sha,
        raw_manifest_sha=raw_manifest_sha,archive_sha=a.archive_sha,package_sha=a.package_sha,runtime_sha=a.runtime_sha,absence_proof_sha=a.absence_sha,
        counts={'science':52,'PMS':162,'helper':21840},science_complete=True,full_raw_hashes_match=True,source_archives_match=True,runtime_input_binary_hashes_match=True,
        owned_empty=True,actual_restore=True,outer_transport_valid=True,full_boundary_identities=True,source_assertion_helper_checked=True,
        audited_files=len(sha_tree),raw_manifest_excluded_package_pinned=sorted(excluded),app_results=app_results,pms_results=pms_results,css_oracles=css_answers,tight=sorted(tight),offset=sorted(offset),
        exclusive=False,performance='NOT_MEASURED',audit_method='Original bytes + independent original objectives + authenticated committed support loops + independent post-exit process proof')
    a.out.write_text(json.dumps(report,indent=2)+'\n',encoding='utf8');print(json.dumps({'audit':str(a.out),'sha256':file_sha(a.out),'status':'PASS','counts':report['counts']}))
if __name__=='__main__':main()
