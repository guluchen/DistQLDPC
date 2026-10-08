"""Read-only GH32 assigned Tier0 raw audit; no execution of solver/driver."""
import hashlib,json,pathlib,re
ROOT=next(p for p in pathlib.Path(__file__).resolve().parents if (p/'E004-windows-tier2-02').is_dir())
out=ROOT/'GH32-windows-tier0-01'
load=lambda p:json.loads(p.read_text(encoding='utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
summary=load(out/'summary.json');identity=load(out/'identity.json')
assert summary['valid_run'] and summary['Tier0']=='LOCAL_PASS' and summary['status']=='PREPARATORY_COMPLETE'
assert identity['candidate']=='3953a4cbfb5826a1402196d18a8ac292cd0f4870'
assert identity['assignment'].endswith('6065434429')
assert all(summary['cleanup'][key] is True for key in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
for rel,h in load(out/'SHA256.json').items():assert sha(out/rel)==h,rel
for path,h in load(out/'pretest-binary-hashes.json').items():assert sha(pathlib.Path(path))==h,path
for name,h in load(out/'preimport-support.json')['hashes'].items():assert sha(ROOT/'GH32-MTUNE/optimization/experiments/GH-32'/name)==h
for name,h in identity['runtime_file_hashes'].items():assert sha(ROOT/'E004-windows-runtime/cygwin/bin'/name)==h
manifest=load(ROOT/'E004-windows-tier2-02/E004-server-package/manifest.json')['files']
for name,h in identity['input_hashes'].items():assert manifest['baseline/data/matrices/'+name]==h
resources=load(out/'resources.json');mask=identity['selection']['mask']
assert all(r['eligible'] and r['idle_percent']>50 and r['half_spare_logical_cpus']>=1 and r['affinity']==mask for r in resources)
assert all(r['mask']==mask and r['priority_class']==32768 for sample in load(out/'descendants.json') for r in sample['records'])
commands=list(out.rglob('*.command.json'))
for p in commands:
    c=load(p);assert c['owned_descendants_remaining']==[] and c['assignment']==identity['assignment'],p
cleanup=list(out.glob('owned-cleanup-*.json'));assert cleanup
assert all(load(p)['confirmed'] and load(p)['remaining']==[] for p in cleanup)
counts={'CSS':0,'WCNF_pairs':0,'PMS':0,'smoke':0,'timeout':0}
for stem,exact in [('css1',1),('css4',2),('css5',1)]:
    for mode in ['no-card','card-mto']:
        a=out/'tier0'/(stem+'-'+mode+'-baseline.wcnf');b=out/'tier0'/(stem+'-'+mode+'-candidate.wcnf')
        assert a.read_bytes()==b.read_bytes();counts['WCNF_pairs']+=1
for p in (out/'tier0').glob('*.stdout'):
    label=p.stem;text=p.read_text(encoding='utf-8');rc=load(p.with_suffix('.command.json'))['returncode']
    if '-dump' in label or label.startswith('help-'):assert rc==0;continue
    if label.startswith('pms-'):
        exact=0 if 'pms-zero' in label else 1 if 'pms-conflict' in label else 2
        raw=re.findall(r'optimal:\s*([^,\r\n]*)',text)
        assert rc==10 and raw and all(re.fullmatch(r'\d+',v.strip()) and int(v)==exact for v in raw)
        assert [v.strip() for v in re.findall(r'^s\s+(.+)$',text,re.M)]==['SATISFIABLE']
        counts['PMS']+=1;continue
    kind='timeout' if label.startswith('timeout-') else 'smoke' if label.startswith('smoke-') else 'CSS'
    exact=8 if kind=='timeout' else 2 if kind=='smoke' or label.startswith('css4-') else 1
    assert rc==(1 if kind=='timeout' else 0)
    if kind=='timeout':assert 's UNKNOWN' in text and 'c status: TIMEOUT' in text and not re.search(r'^o\b',text,re.M)
    for key,pattern in [('lb',r'^c\s+d_lb:\s*(.*?)\s*$'),('ub',r'^c\s+d_ub:\s*(.*?)\s*$'),('d',r'^c\s+d\s*:\s*(.*?)\s*$'),('o',r'^o(?:\s+(.*?))?\s*$')]:
        values=re.findall(pattern,text,re.M)
        for item in values:
            if item in ({'-'} if key in ['lb','ub'] else {'UNKNOWN'} if key=='d' else set()):continue
            assert re.fullmatch(r'\d+',item),(label,key,item)
            v=int(item);assert (v<=exact if key=='lb' else v==exact if key=='d' else v>=exact)
        if kind!='timeout':assert values and int(values[-1])==exact
    counts[kind]+=1
assert counts==dict(CSS=12,WCNF_pairs=6,PMS=8,smoke=4,timeout=4),counts
target=load(out/'target-provenance.json');assert target['march']==dict(original='x86-64',native='x86-64') and target['all_non_tuning_macros_identical']
report=dict(status='PASS',actual_support=identity['candidate'],assignment=identity['assignment'],counts=counts,commands=len(commands),
    selection=identity['selection'],target=target,binary_hashes=load(out/'pretest-binary-hashes.json'),resource_samples=len(resources),
    min_global_idle=min(r['idle_percent'] for r in resources),min_half_spare=min(r['half_spare_logical_cpus'] for r in resources),
    active_alerts=sum(r['core_contention_detected'] and not r['label'].endswith('-preflight') for r in resources),
    cleanup=summary['cleanup'],performance='NOT_MEASURED',Tier1='NOT_RUN')
(ROOT/'independent-brain-records/GH32-TIER0-AUDIT.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
