"""Independent exact oracle/raw audit and retention. No solver execution."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,zipfile
ROOT=Path(__file__).resolve().parent
repo=ROOT/'GH36-WITNESS';record=repo/'optimization/experiments/GH-36';out=ROOT/'GH36-windows-tier0-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_bytes())
s=read(out/'summary.json')
assert s['Tier0']=='LOCAL_PASS' and s['performance']=='NOT_MEASURED'
assert all(s['cleanup'][k] is True for k in ['job_limit_released','affinity_restored','priority_restored','sleep_requirement_restored'])
assert len(read(out/'job-pids-before-release.json'))==1
final=list(out.glob('owned-cleanup-*.json'));assert len(final)==1
assert read(final[0])['remaining']==[] and read(final[0])['confirmed']
manifest=read(out/'SHA256.json')
for n,h in manifest.items():assert sha(out/n)==h,n
pre=read(out/'preexecution.json')
assert pre['record_head']=='247bc11d4191e36466f2203f0236da102d27ff0d'
assert pre['baseline']=='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
assert read(out/'postexecution-identities.json')==dict(support=True,runtime=True,inputs=True)
for n,h in pre['support'].items():
    p=record/n if n!='windows_cpu_window.py' else ROOT/'DistQLDPC/optimization/experiments/E004/windows_cpu_window.py'
    assert sha(p)==h,n
for v,hashes in pre['source_hashes'].items():
    for n,h in hashes.items():assert sha(out/(v+'-source')/n)==h,n
for n,h in pre['runtime_hashes'].items():assert sha(ROOT/'E004-windows-runtime/cygwin/bin'/n)==h,n
for v,h in read(out/'binary-hashes.json').items():assert sha(out/(v+'-source')/'bin/distqldpc.exe')==h,v
assert b'WITNESS_ORACLE_PASS cases=4368 plus_multirow' in (out/'candidate-witness-trace.stdout').read_bytes()
for stem in ['css1','css4','css5','css-fallback']:
    for mode in ['no-card','card-mto']:
        assert (out/(stem+'-'+mode+'-baseline.wcnf')).read_bytes()==(out/(stem+'-'+mode+'-candidate.wcnf')).read_bytes()
def boundcheck(text,exact,timeout):
    for key,pat in [('lb',r'^c\s+d_lb:\s*(.*?)\s*$'),('ub',r'^c\s+d_ub:\s*(.*?)\s*$'),('d',r'^c\s+d\s*:\s*(.*?)\s*$'),('o',r'^o\s+(.*?)\s*$')]:
        values=re.findall(pat,text,re.M)
        for raw in values:
            if raw in ['-','UNKNOWN']:continue
            assert raw.isdecimal(),(key,raw)
            value=int(raw)
            assert value<=exact if key=='lb' else value==exact if key=='d' else value>=exact
        if not timeout:assert values and values[-1]==str(exact)
    if timeout:
        assert re.search(r'^s UNKNOWN\s*$',text,re.M) and re.search(r'^c status: TIMEOUT\b',text,re.M)
        assert not re.search(r'^o\b',text,re.M) and not re.search(r'^c\s+d\s*:\s*\d+',text,re.M)
    else:assert not re.search(r'^s UNKNOWN\s*$',text,re.M)
science=read(out/'science.json');assert len(science)==28
for row in science:
    label=row['label'];file_label=label.replace('production-1s-','timeout-');cmd=read(out/(file_label+'.command.json'));text=(out/(file_label+'.stdout')).read_text()
    timeout=row['result']['timeout'];exact=8 if label.startswith('production-1s') else 2 if label.startswith('css4') or '-timeout-' in label else 1
    assert cmd['returncode']==row['result']['returncode']==(1 if timeout else 0)
    boundcheck(text,exact,timeout)
    if '-pre-search-timeout-' in label:assert not re.search(r'^c\s+d_ub:\s*\d+',text,re.M)
    if '-post-model-timeout-' in label:assert re.search(r'^c\s+d_ub:\s*\d+',text,re.M)
oracle=read(out/'pms-oracle.json');assert len(oracle)==40
count=0
for row in oracle:
    stem=row['stem'];p=out/(stem+'.wcnf');assert sha(p)==row['input_sha256']
    lines=p.read_text().splitlines();header=lines[0].split();n,top=int(header[2]),int(header[4])
    clauses=[list(map(int,line.split())) for line in lines[1:]]
    assert all(c[-1]==0 for c in clauses)
    def sat(c,a):return any(bool(a&(1<<(abs(v)-1)))==(v>0) for v in c[1:-1])
    feasible=[a for a in range(1<<n) if all(sat(c,a) for c in clauses if c[0]>=top)]
    cost=lambda a:sum(c[0] for c in clauses if c[0]<top and not sat(c,a))
    exact=min(map(cost,feasible));assert exact==row['oracle']
    witness=read(out/(stem+'-witness.json'));assert witness['assignment'] in feasible and cost(witness['assignment'])==witness['verified_weight']==exact
    for tail in ['', '-provided']+(['-loose'] if stem=='pms-root-cap-offset' else []):
        pair=[]
        for v in ['baseline','candidate']:
            label=stem+'-'+v+tail;cmd=read(out/(label+'.command.json'));text=(out/(label+'.stdout')).read_text()
            rc=cmd['returncode'];assert rc in [10,20]
            values=list(map(int,re.findall(r'optimal:\s*(\d+)',text)));assert values and all(x==exact for x in values)
            status=re.findall(r'^s\s+(.*?)\s*$',text,re.M);assert status==(['SATISFIABLE'] if rc==10 else ['UNSATISFIABLE'])
            pair.append([rc,status,exact]);count+=1
            if tail=='-provided':assert re.findall(r'^c initial UB:\s*(\d+)\s*$',text,re.M)==[str(exact if exact else 2147483647)]
            if stem=='pms-root-cap-offset' and tail:
                assert re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)==(['1'] if tail=='-provided' else ['2'])
        assert pair[0]==pair[1]
        if not tail:assert pair==row['scientific_results']
assert count==162
coverage=read(out/'tight-positive-residual-coverage.json');assert {r['version'] for r in coverage}=={'baseline','candidate'}
for row in coverage:
    text=(out/(row['stem']+'-'+row['version']+'-provided.stdout')).read_text()
    assert row['verified_cost']==row['exact']>0 and row['strict_providedUB']>=2 and re.search(r'^c UB=1 fails,',text,re.M)
resources=read(out/'resources.json');assert resources and all(r['eligible'] for r in resources)
host=record/'raw/hosted-247bc11';identity=read(host/'identity.json')
assert not subprocess.check_output(['git','-C',str(repo),'diff',identity['actual_merge'],pre['record_head'],'--','src','Makefile','scripts','.github'])
ha=dict(status='PASS',production=subprocess.check_output(['git','-C',str(repo),'rev-parse','f8f379d'],text=True).strip(),actual_merge=identity['actual_merge'],source_tree_byte_equal=True,correct_final_solves=8,performance='CI diagnostic only',artifact_sha256=sha(host/'artifact.zip'))
(host/'AUDIT.json').write_text(json.dumps(ha,indent=2),encoding='utf8',newline='\n')
audit=dict(status='PASS',helper_exhaustive_cases=4368,additional_multirow_and_five_builder_modes=True,CSS_correct_solves=16,WCNF_equal_pairs=8,PMS_exact_oracles=40,PMS_correct_solves=count,original_zero_cap_cli_ignored=True,root_offset_inclusive_to_strict_verified=[1,2],tight_positive_residual_and_failed_initial_bound=True,genuine_timeouts=sum(r['result']['timeout'] for r in science),pre_search_no_model_timeouts=4,post_model_with_UB_timeouts=4,production_one_second_runs=4,smoke_scripts=2,original_manifest_files=len(manifest),resource_samples=len(resources),contention_alerts=sum(r['core_contention_detected'] for r in resources),minimum_global_spare=min(r['idle_percent'] for r in resources),selected_CPU=read(out/'window.json')['selected_cpu'],cleanup='owned descendants empty; all four restorations confirmed',performance='NOT_MEASURED',decision='INCONCLUSIVE pending Tier1')
dest=record/'raw/windows-tier0-01';dest.mkdir(parents=True,exist_ok=False)
# Entire executed manifest including four test-only hook objects/binaries is kept
# byte-for-byte in an archive. Original exported source trees are represented by
# exact source TARs and frozen per-file hashes; production exe hashes are retained.
archive=dest/'raw.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for name in sorted(manifest):z.write(out/name,name)
    z.write(out/'SHA256.json','SHA256.json')
with zipfile.ZipFile(archive) as z:
    assert set(z.namelist())==set(manifest)|{'SHA256.json'}
    for n,h in manifest.items():assert hashlib.sha256(z.read(n)).hexdigest()==h,n
for p in out.iterdir():
    if p.is_file() and p.suffix not in ['.exe','.o']:shutil.copyfile(p,dest/p.name)
(dest/'AUDIT.json').write_text(json.dumps(audit,indent=2),encoding='utf8',newline='\n')
(dest/'ARCHIVE.json').write_text(json.dumps(dict(sha256=sha(archive),members=len(manifest)+1,original_manifest_verified=True,source_trees='original TARs + per-file hashes; not compiled build directories'),indent=2),encoding='utf8',newline='\n')
(record/'PUBLIC-SHA256.json').write_text(json.dumps({p.relative_to(record).as_posix():sha(p) for p in sorted((record/'raw').rglob('*')) if p.is_file()},indent=2),encoding='utf8',newline='\n')
print(json.dumps(audit,indent=2));print('archive',sha(archive),'public raw',len(read(record/'PUBLIC-SHA256.json')))
