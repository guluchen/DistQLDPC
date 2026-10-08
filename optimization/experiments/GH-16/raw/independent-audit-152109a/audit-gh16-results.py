"""Independent metadata/raw audit; no solver/build/profiler execution."""
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import subprocess

ROOT=Path(__file__).resolve().parent.parent
EXPECTED={'BB_90_8_10':10,'GB_144_12_8':8,'BB_108_8_10':10,'LP_238_44_6':6,'LP_340_56_8':8}
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
reports=[]
for dirname,count,cases,limit in [('GH16-windows-tier1-01',48,list(EXPECTED)[:4],180),
                                ('GH16-windows-tier2-exploratory-01',12,['LP_340_56_8'],600)]:
    d=ROOT/dirname;samples=read(d/'samples.json');result=read(d/'result.json');env=read(d/'environment.json')
    assert len(samples)==count and result['decision']=='INCONCLUSIVE' and result['tier3']=='NOT_RUN'
    assert env['baseline_sha']=='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
    assert env['candidate_sha']=='467433133851f25a1ab76b662ca93250acf46d03'
    assert env['qdistsat_sha']=='7c4774fffc49856f48a22ae5f9063d00b2661aaa'
    groups={};bound_count=0
    assert {(r['case'],r['mode'],r['version'],r['repeat']) for r in samples}=={
        (c,m,v,i) for c in cases for m in ['no-card','card-mto']
        for v in ['baseline','candidate'] for i in [1,2,3]}
    for row in samples:
        stem=row['case'];mode=row['mode'];version=row['version'];expected=EXPECTED[stem]
        label=f"{stem}-{mode}-{row['repeat']}-{version}"
        command=read(d/(label+'.command.json'))
        assert command['argv']==row['command'] and command['cwd']==row['cwd']
        assert f'-cpu-lim={limit}' in command['argv'] and '-'+mode in command['argv']
        assert row['returncode']==0 and not row['resource_abort'] and not row['external_timeout']
        science=row['semantic'];assert all(science[k]==expected for k in ['d','objective','lb','ub'])
        assert not science['timeout'] and not science['unknown']
        text=(d/(label+'.stdout')).read_text(encoding='utf-8')
        assert (d/(label+'.stderr')).read_bytes()==b''
        for field,pattern in [('d',r'^c\s+d\s*:\s*(\d+)\s*$'),('objective',r'^o\s+(\d+)\s*$')]:
            values=re.findall(pattern,text,re.M);assert values and all(int(v)==expected for v in values),(label,field)
        for field,pattern in [('lb',r'^c\s+d_lb:\s*(\d+)\s*$'),('ub',r'^c\s+d_ub:\s*(\d+)\s*$')]:
            values=list(map(int,re.findall(pattern,text,re.M)));assert values and values[-1]==expected
            assert all(v<=expected if field=='lb' else v>=expected for v in values),(label,field,values)
            bound_count+=len(values)
        assert 's UNKNOWN' not in text and 'c status: TIMEOUT' not in text
        affinities=read(d/(label+'.affinity.json'));assert affinities
        assert all(v['mask']==16384 and v['priority_class']==32768 for v in affinities)
        binary=Path(command['argv'][0]);assert sha(binary)==env['binary_sha256'][version]
        groups.setdefault((stem,mode),{'baseline':[],'candidate':[]})[version].append(row['elapsed_sec'])
    # Check actual serial order; repeat2 is reversed, all others baseline first.
    for start in range(0,len(samples),2):
        pair=samples[start:start+2];repeat=pair[0]['repeat']
        assert [r['version'] for r in pair]==(['candidate','baseline'] if repeat==2 else ['baseline','candidate'])
        assert len({(r['case'],r['mode'],r['repeat']) for r in pair})==1
    recomputed=[]
    for (case,mode),times in groups.items():
        b=times['baseline'];c=times['candidate'];ratio=statistics.median(c)/statistics.median(b)
        envelope=max(c)/min(b);regression=min(c)>max(b)
        saved=next(x for x in result['medians'] if x['case']==case and x['mode']==mode)
        assert saved['raw']==times
        for field,value in [('baseline_median',statistics.median(b)),('candidate_median',statistics.median(c)),
                            ('ratio',ratio),('range_envelope',envelope)]:
            assert math.isclose(saved[field],value,rel_tol=1e-12)
        assert saved['nonoverlapping_regression']==regression
        recomputed.append(dict(case=case,mode=mode,ratio=ratio,envelope=envelope,regression=regression))
    for mode in ['no-card','card-mto']:
        rows=[r for r in recomputed if r['mode']==mode]
        geomean=math.exp(statistics.mean(math.log(r['ratio']) for r in rows))
        envelope=math.exp(statistics.mean(math.log(r['envelope']) for r in rows))
        saved=result['numeric_reason'][mode]
        assert math.isclose(saved['median_geomean'],geomean,rel_tol=1e-12)
        assert math.isclose(saved['range_envelope_geomean'],envelope,rel_tol=1e-12)
        assert saved['no_worse_medians']==all(r['ratio']<=1 for r in rows)
    resources=read(d/'resources.json');assert resources
    assert all(r['eligible'] and r['idle_percent']>50 and r['half_spare_logical_cpus']>=1 and r['affinity']==16384 for r in resources)
    cleanup=read(d/'cleanup.json')
    assert all(cleanup[k] for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
    assert cleanup['final_mask']==65535 and cleanup['final_priority_class']==32
    assert read(d/'remaining-owned.json')==[]
    manifest=env['manifest'];package=ROOT/'E004-windows-tier2-02/E004-server-package'
    assert all(sha(package/p)==h for p,h in manifest['files'].items())
    reports.append(dict(directory=dirname,samples=len(samples),emitted_bounds=bound_count,
                        resource_checks=len(resources),contention=sum(r['core_contention_detected'] for r in resources),
                        active_contention=sum(r['core_contention_detected'] and not r['label'].endswith('preflight') for r in resources),
                        min_idle=min(r['idle_percent'] for r in resources),min_sibling=min(r['sibling_idle'] for r in resources),
                        recomputed=recomputed,identity_and_cleanup='PASS',decision='INCONCLUSIVE appropriate'))
tree=ROOT/'GH16-PGO';record=tree/'optimization/experiments/GH-16'
env=read(ROOT/'GH16-windows-tier2-exploratory-01/environment.json')
for name,digest in env['profiles']['profiles'].items():assert sha(tree/'pgo-data'/name)==digest
assert sha(record/'raw/windows-tier2-exploratory-01/executed-driver.py')==env['driver_sha256']
assert sha(record/'windows_cpu_window.py')==env['window_helper_sha256']
assert sha(ROOT/'E004-windows-tier2-02/E004-server-package/candidate/optimization/server/run.py')==env['parser_sha256']
manifest=read(record/'raw-sha256.json')
head=subprocess.check_output(['git','-C',str(tree),'rev-parse','HEAD'],text=True).strip()
ls=subprocess.check_output(['git','-C',str(tree),'ls-tree','-r',head,'optimization/experiments/GH-16/raw'],text=True)
blobs={line.split('\t',1)[1]:line.split()[2] for line in ls.splitlines()}
for path,digest in manifest.items():
    data=(record/path).read_bytes();assert hashlib.sha256(data).hexdigest()==digest,path
    blob=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
    assert blobs['optimization/experiments/GH-16/'+path]==blob,path
report=dict(tiers=reports,provenance=dict(profiles='4frozen hashes PASS',driver_helper_parser='PASS',
             raw_manifest_count=len(manifest),exact_git_blob_bytes='PASS',record_commit=head))
output=ROOT/'independent-brain-records/GH16-INDEPENDENT-AUDIT.json'
output.write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
