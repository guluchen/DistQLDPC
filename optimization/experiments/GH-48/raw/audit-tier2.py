from pathlib import Path
import json,hashlib,shutil,re,statistics,math
root=Path(__file__).parent;repo=root/'GH48-ISA-V2';record=repo/'optimization/experiments/GH-48'
out=root/'GH48-windows-tier2-01';dest=record/'raw/windows-tier2-01'
digest=lambda b:hashlib.sha256(b).hexdigest()
load=lambda name:json.loads((out/name).read_text(encoding='utf8'))
result=load('result.json');samples=load('samples.json');pre=load('preexecution.json')
assert result['status']=='FILTER_COMPLETE' and result['valid_run'] is True and len(samples)==12
assert result['exploratory'] is True and result['normal_promotion'] is False and result['user_one_tier_exception'] is True
assert result['Tier1']=='FORMAL_INCONCLUSIVE_NUMERIC_REJECT' and result['Tier3']=='NOT_RUN'
assert pre['record_head']=='fb73879d5cd2976d29789c827be42ee7f656d73a'
assert pre['candidate']=='d27cf4d54bc08c6db4b2ffcebfe0372417bb13ef' and pre['baseline']=='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
assert pre['assignment']=='https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6070015624'
assert pre['binary_hashes']=={'baseline':'70582f38a02b8e2b2948867f9ea3680f44ca9e04184bdb7891f1f51a7222693e','candidate':'ef61efc3d6a4605c19b9c4b279dc95d08914910efb946221030601bfe24c2317'}
assert pre['driver_sha256']==digest((out/'executed-driver.py').read_bytes())=='d6d2518225d751ab56dd67ca99e16cb290d03fa432376b8ec5df1c4334876cb5'
runner=load('job-pids-before-release.json');assert len(runner)==1
assert load('POST-EXIT.json')['runner_pid']==runner[0] and load('POST-EXIT.json')['exact_matching_runner_absent']
assert all(result['cleanup'][k] is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
manifest=load('SHA256.json')
for rel,want in manifest.items(): assert digest((out/rel).read_bytes())==want,rel
cases=['LP_340_56_8'];modes=['no-card','card-mto']
expected_order=[(c,m,r,v) for c in cases for m in modes for r in range(1,4) for v in (['baseline','candidate'] if r%2 else ['candidate','baseline'])]
assert [(s['case'],s['mode'],s['repeat'],s['version']) for s in samples]==expected_order
for s in samples:
    label=f"{s['case']}-{s['mode']}-{s['repeat']}-{s['version']}";truth=int(s['case'].rsplit('_',1)[1])
    command=load(label+'.command.json'); assert command['returncode']==s['returncode']==0 and not command['owned_descendants_remaining']
    assert command['elapsed_sec']==s['elapsed_sec'] and command['argv']==s['command']
    text=(out/(label+'.stdout')).read_text(encoding='utf8');assert not (out/(label+'.stderr')).read_bytes()
    fields={'lb':r'^c\s+d_lb:\s*(.*?)\s*$', 'ub':r'^c\s+d_ub:\s*(.*?)\s*$', 'd':r'^c\s+d\s*:\s*(.*?)\s*$', 'objective':r'^o(?:\s+(.*?))?\s*$'}
    for key,pattern in fields.items():
        raw=re.findall(pattern,text,re.M);assert raw and raw[-1]==str(truth),(label,key,raw)
        for token in raw:
            if token=='-' and key in ('lb','ub'):continue
            assert token is not None and re.fullmatch(r'\d+',token),(label,key,token)
            number=int(token);assert number<=truth if key=='lb' else number==truth if key=='d' else number>=truth
    assert not re.findall(r'^s\s+.*$|^c status:.*$',text,re.M)
groups=[]
for c in cases:
    for m in modes:
        raw={v:[s['elapsed_sec'] for s in samples if (s['case'],s['mode'],s['version'])==(c,m,v)] for v in ['baseline','candidate']}
        b,k=(statistics.median(raw[v]) for v in ['baseline','candidate'])
        actual=next(x for x in result['medians'] if (x['case'],x['mode'])==(c,m))
        assert actual['raw']==raw and actual['baseline_median']==b and actual['candidate_median']==k and actual['ratio']==k/b
        groups.append(dict(case=c,mode=m,raw=raw,baseline_median=b,candidate_median=k,ratio=k/b,percent_change=100*(k/b-1),nonoverlapping_regression=min(raw['candidate'])>max(raw['baseline']),overlap=not(min(raw['candidate'])>max(raw['baseline']) or min(raw['baseline'])>max(raw['candidate']))))
gm={m:math.exp(statistics.mean(math.log(g['ratio']) for g in groups if g['mode']==m)) for m in modes}
resources=load('resources.json');assert all(r['eligible'] for r in resources)
flags=[r for r in resources if r['core_contention_detected']]
audit={'status':'12_SCIENCE_AND_MEDIAN_AUDIT_PASS','formal_decision':'INCONCLUSIVE','local_numeric_filter':result['numeric_filter'],
       'local_numeric_reason':result['numeric_reason'],'support':pre['record_head'],'candidate':pre['candidate'],'baseline':pre['baseline'],
       'binary_hashes':pre['binary_hashes'],'driver_sha256':pre['driver_sha256'],'assignment':pre['assignment'],'cleanup_all_true':True,
       'only_runner_before_release':runner[0],'all_raw_manifest_files_verified':len(manifest),'raw_science_checks':12,
       'median_geomeans':gm,'groups':groups,'resource_samples':len(resources),'capacity_all_eligible':True,'contention_flags':len(flags),
       'minimum_global_idle':min(r['idle_percent'] for r in resources),'minimum_sibling_idle':min(r['sibling_idle'] for r in resources),
       'flags':flags,'exploratory':True,'normal_promotion':False,'performance_limit':'Nonexclusive Windows exploratory diagnostic; group medians and ranges retained without posthoc selection. No automatic higher tier or controlled acceptance.'}
assert load('runtime-post-file-set.json')==dict(pre_count=10216,post_count=10216,identical=True,added=[],removed=[])
assert load('isa-gate.json')['cpuid']['compatible'] and load('isa-gate.json')['cpuid']['level']=='x86-64-v2'
for p in out.glob('owned-cleanup-*.json'):
 x=json.loads(p.read_text());assert x['confirmed'] and x['remaining']==[]
for path,want in pre['identities'].items():assert digest(Path(path).read_bytes())==want,path
for path,want in pre['input_hashes'].items():assert digest(Path(path).read_bytes())==want,path
for a in load('descendants.json'):
 for x in a['records']:assert x['mask']==load('window.json')['mask'] and x['priority_class']==32768
dest.mkdir(parents=True,exist_ok=False)
for p in out.iterdir():
    if p.is_file():shutil.copyfile(p,dest/p.name)

(out/'AUDIT.json').write_text(json.dumps(audit,indent=2),encoding='utf8',newline='\n')
(dest/'AUDIT.json').write_text(json.dumps(audit,indent=2),encoding='utf8',newline='\n')
(record/'raw-sha256.json').write_text(json.dumps({p.relative_to(record/'raw').as_posix():digest(p.read_bytes()) for p in sorted((record/'raw').rglob('*')) if p.is_file()},indent=2),encoding='utf8',newline='\n')
print(json.dumps(audit))
