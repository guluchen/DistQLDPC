from pathlib import Path
import json,hashlib,statistics,math,shutil,re
root=Path(__file__).resolve().parent;out=root/'GH36-windows-tier1-01'
record=root/'GH36-WITNESS/optimization/experiments/GH-36'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((out/'result.json').read_text());samples=json.loads((out/'samples.json').read_text())
assert r['valid_run'] and len(samples)==48 and r['status']=='FILTER_COMPLETE'
assert all(r['cleanup'][k] for k in ['job_limit_released','affinity_restored','priority_restored','sleep_requirement_restored'])
assert len(json.loads((out/'job-pids-before-release.json').read_text()))==1
for rel,digest in json.loads((out/'SHA256.json').read_text()).items():assert sha(out/rel)==digest
pre=json.loads((out/'preexecution.json').read_text())
assert pre['candidate']=='f8f379ddb7d7cc4a0f8dc1d62f670b2e97bd22a1'
for v,d in pre['binary_hashes'].items():assert sha(root/'GH36-windows-tier0-01'/(v+'-source')/'bin/distqldpc.exe')==d
for p,d in pre['input_hashes'].items():assert sha(Path(p))==d
for n,d in pre['identities'].items():assert sha(Path(n))==d,n
assert sha(out/'executed-driver.py')==pre['driver_sha256']
cases=['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6'];modes=['no-card','card-mto']
order=[(case,mode,i,v) for case in cases for mode in modes for i in range(1,4)
       for v in (['baseline','candidate'] if i%2 else ['candidate','baseline'])]
assert [(x['case'],x['mode'],x['repeat'],x['version']) for x in samples]==order
updates=0
for x in samples:
    case,mode,i,v=x['case'],x['mode'],x['repeat'],x['version'];expected=int(case.rsplit('_',1)[1])
    label=f'{case}-{mode}-{i}-{v}';text=(out/(label+'.stdout')).read_text()
    command=json.loads((out/(label+'.command.json')).read_text())
    assert x['returncode']==command['returncode']==0 and command['timeout_sec']==195
    assert '-cpu-lim=180' in command['argv'] and '-'+mode in command['argv']
    assert x['elapsed_sec']==command['elapsed_sec'] and x['elapsed_sec']>0
    assert not x['external_timeout'] and not x['resource_abort']
    assert not command['owned_descendants_remaining']
    for key,pattern in [('lb',r'^c\s+d_lb:\s*(.*?)\s*$'),('ub',r'^c\s+d_ub:\s*(.*?)\s*$'),
                        ('d',r'^c\s+d\s*:\s*(.*?)\s*$'),('objective',r'^o\s+(.*?)\s*$')]:
        values=re.findall(pattern,text,re.M);assert values and values[-1]==str(expected)
        for raw in values:
            if raw in ['-','UNKNOWN']:continue
            assert raw.isdecimal();value=int(raw)
            assert value<=expected if key=='lb' else value==expected if key=='d' else value>=expected
            if key in ['lb','ub']:updates+=1
    assert not re.search(r'^s UNKNOWN\s*$',text,re.M) and not re.search(r'^c status: TIMEOUT\b',text,re.M)
for row in r['medians']:
    vals={v:[x['elapsed_sec'] for x in samples if (x['case'],x['mode'],x['version'])==(row['case'],row['mode'],v)] for v in ['baseline','candidate']}
    assert vals==row['raw']
    b,c=(statistics.median(vals[v]) for v in ['baseline','candidate'])
    assert b==row['baseline_median'] and c==row['candidate_median'] and c/b==row['ratio']
    assert row['nonoverlapping_regression']==(min(vals['candidate'])>max(vals['baseline']))
    assert max(vals['candidate'])/min(vals['baseline'])==row['range_envelope']
resources=json.loads((out/'resources.json').read_text());assert all(x['eligible'] for x in resources)
stats={m:{'median_geomean':math.exp(sum(math.log(x['ratio']) for x in r['medians'] if x['mode']==m)/4),
          'range_envelope_geomean':math.exp(sum(math.log(x['range_envelope']) for x in r['medians'] if x['mode']==m)/4)} for m in modes}
audit={'status':'PASS','solves':48,'bound_updates':updates,'ordering':'AB/BA/AB bothmodes4cases',
       'resource_samples':len(resources),'alerts':sum(x['core_contention_detected'] for x in resources),
       'min_global_spare':min(x['idle_percent'] for x in resources),'stats':stats,
       'local_decision':'Pending full independent assessment; legacy numeric filter '+str(r['numeric_filter']),
       'formal_controlled_decision':'INCONCLUSIVE','selected_cpu':json.loads((out/'window.json').read_bytes())['selected_cpu'],'source_mechanism':'Verified original-row cap changes pre-feasible bound exploration; see MECHANISM.json','cleanup':'allconfirmed;runneronlybeforeJobrelease'}
mechanism=[]
for case in cases:
    for mode in modes:
        group={}
        for version in ['baseline','candidate']:
            traces=[]
            for repeat in range(1,4):
                label=f'{case}-{mode}-{repeat}-{version}';text=(out/(label+'.stdout')).read_text()
                traces.append(dict(repeat=repeat,provided=re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M),bound_sequence=re.findall(r'^c UB=(\d+) (fails|succ)',text,re.M),lookahead_stats=re.findall(r'^c prunedLB.*$',text,re.M)))
            group[version]=traces
        mechanism.append(dict(case=case,mode=mode,traces=group))
dest=record/'raw/windows-tier1-01' ;dest.mkdir(parents=True,exist_ok=False)
for p in out.iterdir():
    if p.is_file():shutil.copyfile(p,dest/p.name)
(dest/'MECHANISM.json').write_text(json.dumps(mechanism,indent=2),encoding='utf8',newline='\n')
(dest/'AUDIT.json').write_text(json.dumps(audit,indent=2),encoding='utf8',newline='\n')
manifest={p.relative_to(record).as_posix():sha(p) for p in sorted((record/'raw').rglob('*')) if p.is_file()}
(record/'PUBLIC-SHA256.json').write_text(json.dumps(manifest,indent=2),encoding='utf8',newline='\n')
print(json.dumps(audit,indent=2));print('retained',len(manifest),'exactpayloads')
