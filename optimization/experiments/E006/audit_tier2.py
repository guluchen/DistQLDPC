"""Independent audit of E006 user-directed exploratory Tier2 LP340."""
import argparse
import hashlib
import json
import math
import re
import statistics
from pathlib import Path


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('run',type=Path)
    ap.add_argument('--prior',required=True,type=Path)
    ap.add_argument('--candidate',required=True,type=Path)
    a=ap.parse_args();e=a.run/'evidence';pkg=a.prior/'E004-server-package'
    read=lambda p:json.loads(p.read_text(encoding='utf8'))
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    env=read(e/'environment.json');setup=env['affinity']
    for rel,want in env['manifest']['files'].items():assert sha(pkg/rel)==want,rel
    assert env['manifest']['baseline']=='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
    assert env['candidate_sha']=='c91b19bbf29a28a6e808c8ef2c328cb9cef784e8'
    assert env['hosted_ci']['candidate_sha']==env['candidate_sha']
    assert len(env['hosted_ci']['workflow_runs'])==2 and all(r['conclusion']=='success' for r in env['hosted_ci']['workflow_runs'])
    for rel,want in env['tier0_validation']['source_hashes'].items():assert sha(a.candidate/rel)==want,rel
    for version,tree in [('baseline',pkg/'baseline'),('candidate',a.candidate)]:
        assert sha(tree/'bin/distqldpc.exe')==env['binary_sha256'][version]
    assert sha(e/'executed-driver.py')==env['driver_sha256']
    assert read(a.prior/'evidence/tier0/summary.json')['status']=='PASS'
    assert setup['allow_contention'] and not setup['exclusive_reservation']
    assert setup['mask']==1<<setup['selected_cpu']
    assert [setup['selected_cpu'],setup['sibling']] in setup['topology']
    assert setup['priority_class']==32768 and not setup['power_policy_changed']
    assert read(e/'cleanup.json')==dict(job_limit_released=True,affinity_restored=True,
        sleep_requirement_restored=True,final_mask=65535,priority_restored=True,final_priority_class=32)
    resources=read(e/'resources.json')
    assert resources and all(r['idle_percent']>50 and r['half_spare_logical_cpus']>=1 and r['eligible'] and r['affinity']==setup['mask'] for r in resources)
    samples=read(e/'samples.json');assert len(samples)==12,'Incomplete: retain INCONCLUSIVE'
    patterns=dict(d=r'^c\s+d\s*:\s*(\d+)\s*$',objective=r'^o\s+(-?\d+)\s*$',lb=r'^c\s+d_lb:\s*(\d+)\s*$',ub=r'^c\s+d_ub:\s*(\d+)\s*$')
    per_run=[]
    for row in samples:
        expected=int(row['case'].rsplit('_',1)[1]);label=f"{row['case']}-{row['mode']}-{row['repeat']}-{row['version']}"
        tree=pkg/'baseline' if row['version']=='baseline' else a.candidate
        assert Path(row['command'][0]).resolve()==(tree/'bin/distqldpc.exe').resolve()
        assert Path(row['cwd']).resolve()==tree.resolve()
        assert row['command'][1:4]==['-v','-cpu-lim=600','-'+row['mode']]
        assert row['command'][4].endswith('/baseline/data/matrices/'+row['case'])
        assert row['returncode']==0 and not row['resource_abort'] and not row['external_timeout']
        text=(e/(label+'.stdout')).read_text(encoding='utf8')
        for k,p in patterns.items():
            values=list(map(int,re.findall(p,text,re.M)))
            assert values and values[-1]==expected and row['semantic'][k]==expected
            assert all(v<=expected if k=='lb' else v>=expected for v in values)
        assert not row['semantic']['timeout'] and not row['semantic']['unknown']
        assert 's UNKNOWN' not in text and 'c status: TIMEOUT' not in text
        observed=read(e/(label+'.affinity.json'))
        assert observed and len({r['pid'] for r in observed})>=2
        assert all(r['mask']==setup['mask'] and r['priority_class']==32768 for r in observed)
        checks=[r for r in resources if r['label']==label or r['label']==label+'-preflight']
        assert any(r['label']==label+'-preflight' for r in checks)
        active=[r for r in checks if r['label']==label]
        per_run.append(dict(label=label,elapsed_sec=row['elapsed_sec'],
            active_checks=len(active),active_interference_checks=sum(r['core_contention_detected'] for r in active),
            min_active_sibling_idle=min((r['sibling_idle'] for r in active),default=None),
            note='No active telemetry sample for solves shorter than the2s cadence' if not active else 'Observed at2s cadence; not continuous exclusivity evidence'))
    details=[];aggregates={}
    for mode in ['no-card','card-mto']:
        ratios=[];envelopes=[];nonworse=True
        for case in ['LP_340_56_8']:
            rows=[r for r in samples if r['case']==case and r['mode']==mode]
            assert [(r['repeat'],r['version']) for r in rows]==[(1,'baseline'),(1,'candidate'),(2,'candidate'),(2,'baseline'),(3,'baseline'),(3,'candidate')]
            raw={v:[r['elapsed_sec'] for r in rows if r['version']==v] for v in ['baseline','candidate']}
            b,c=(statistics.median(raw[v]) for v in ['baseline','candidate'])
            ratio=c/b;envelope=max(raw['candidate'])/min(raw['baseline'])
            ratios.append(ratio);envelopes.append(envelope);nonworse &= c<=b
            details.append(dict(case=case,mode=mode,raw=raw,baseline_median=b,candidate_median=c,
                median_ratio=ratio,range_envelope=envelope,nonoverlapping_regression=min(raw['candidate'])>max(raw['baseline'])))
        gm=lambda xs:math.exp(sum(math.log(x) for x in xs)/len(xs))
        aggregates[mode]=dict(median_geomean=gm(ratios),range_envelope_geomean=gm(envelopes),no_worse_medians=nonworse)
    numeric='reject' if any(d['nonoverlapping_regression'] for d in details) else ('pass' if all(d['range_envelope_geomean']<1 and d['no_worse_medians'] for d in aggregates.values()) else 'inconclusive')
    recorded=read(e/'result.json');assert recorded['numeric_filter']==numeric
    for d in details:
        actual=next(r for r in recorded['medians'] if r['case']==d['case'] and r['mode']==d['mode'])
        assert all(actual[k]==d[k] for k in ['baseline_median','candidate_median','median_ratio','range_envelope'])
    active=[r for r in resources if not r['label'].endswith('-preflight')]
    result=dict(audit='PASS',decision='INCONCLUSIVE',correct_solves=12,medians=details,aggregates=aggregates,
        numeric_filter=numeric,per_run_resources=per_run,
        min_observed_global_idle=min(r['idle_percent'] for r in resources),
        resource_checks=len(resources),active_checks=len(active),
        active_interference_checks=sum(r['core_contention_detected'] for r in active),
        preflight_interference_checks=sum(r['core_contention_detected'] for r in resources if r['label'].endswith('-preflight')),
        min_active_sibling_idle=min((r['sibling_idle'] for r in active),default=None),
        identities='PASS',scientific_results='PASS',affinity_priority='PASS',cleanup='PASS',
        reason='Exploratory Tier2 only; Tier1 remains rejected; no Tier3 or general acceptance regardless of this case')
    (e/'independent-tier2-audit.json').write_text(json.dumps(result,indent=2),encoding='utf8',newline='\n')
    print(json.dumps({k:v for k,v in result.items() if k not in ['medians','per_run_resources']},indent=2))


if __name__=='__main__':
    main()
