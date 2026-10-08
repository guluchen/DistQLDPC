"""Read-only independent GH32 raw Tier1 audit; no workload or timing execution."""
import hashlib, json, math, re, statistics, sys
from pathlib import Path

sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
CASES={'BB_90_8_10':10,'GB_144_12_8':8,'BB_108_8_10':10,'LP_238_44_6':6}
MODES=['no-card','card-mto']

def audit(d):
    d=Path(d);env=read(d/'environment.json');result=read(d/'result.json');samples=read(d/'samples.json')
    assert len(samples)==48 and result['valid_run'] and result['decision'] in ['INCONCLUSIVE','REJECT']
    assert result['tier2']==result['tier3']=='NOT_RUN'
    assert env['baseline_sha']=='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
    assert env['candidate_sha']=='6b99e1322dd49332b6a96bcc41571bc4aea0e9ec'
    assert env['record_head']=='2b1c33eaf329f47828421945e021f495baabb5b6'
    assert env['assignment']=='https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6065877412'
    assert env['tier']==1 and not env['exclusive_reservation'] and not env['exploratory_exception']
    assert sha(d/'executed-driver.py')==env['driver_sha256']
    hashes=read(d/'SHA256.json')
    for p,digest in hashes.items():assert sha(d/p)==digest,p
    ordering=[(c,m,i,v) for c in CASES for m in MODES for i in [1,2,3]
              for v in (['candidate','baseline'] if i==2 else ['baseline','candidate'])]
    assert [(r['case'],r['mode'],r['repeat'],r['version']) for r in samples]==ordering
    mask=env['affinity']['mask'];groups={};bounds=0;input_paths={}
    for row in samples:
        case,mode,version,repeat=(row[k] for k in ['case','mode','version','repeat'])
        expected=CASES[case];label=f'{case}-{mode}-{repeat}-{version}'
        command=read(d/(label+'.command.json'))
        assert command['argv']==row['command'] and command['cwd']==row['cwd']
        assert command['argv'][1:]==['-v','-cpu-lim=180','-'+mode,command['argv'][-1]]
        assert command['argv'][-1].endswith('/baseline/data/matrices/'+case)
        assert row['returncode']==0 and not row['resource_abort'] and not row['external_timeout']
        assert row['elapsed_sec']>0 and row['elapsed_sec']<195
        science=row['semantic'];assert all(science[k]==expected for k in ['d','objective','lb','ub'])
        assert not science['timeout'] and not science['unknown']
        text=(d/(label+'.stdout')).read_text(encoding='utf-8')
        assert (d/(label+'.stderr')).read_bytes()==b''
        specs={'lb':r'^c\s+d_lb:\s*(.*?)\s*$', 'ub':r'^c\s+d_ub:\s*(.*?)\s*$',
               'd':r'^c\s+d\s*:\s*(.*?)\s*$', 'objective':r'^o(?:\s+(.*?))?\s*$'}
        for field,pattern in specs.items():
            values=re.findall(pattern,text,re.M);assert values
            assert values[-1]==str(expected)
            for value in values:
                if value=='-' and field in ['lb','ub']:continue
                if value=='UNKNOWN' and field=='d':continue
                assert re.fullmatch(r'\d+',value),(label,field,value)
                n=int(value)
                assert n<=expected if field=='lb' else n>=expected if field in ['ub','objective'] else n==expected
                if field in ['lb','ub']:bounds+=1
        assert not re.search(r'^s(?:\s|$)|^c\s+status:',text,re.M),label
        assert command['returncode']==0 and command['owned_descendants_remaining']==[] and command['timeout_sec']==195
        assert command['assignment']==env['assignment'] and command['elapsed_sec']==row['elapsed_sec']
        affinities=read(d/(label+'.affinity.json'));assert affinities
        assert all(a['mask']==mask and a['priority_class']==32768 for a in affinities)
        groups.setdefault((case,mode),{'baseline':[],'candidate':[]})[version].append(row['elapsed_sec'])
        binary=Path(command['argv'][0])
        if binary.exists():assert sha(binary)==env['binary_sha256'][version]
    recomputed=[];summary={}
    for (case,mode),times in groups.items():
        b,c=(statistics.median(times[v]) for v in ['baseline','candidate'])
        ratio=c/b;envelope=max(times['candidate'])/min(times['baseline'])
        regression=min(times['candidate'])>max(times['baseline'])
        saved=next(x for x in result['medians'] if x['case']==case and x['mode']==mode)
        assert saved['raw']==times and saved['nonoverlapping_regression']==regression
        for key,value in [('baseline_median',b),('candidate_median',c),('ratio',ratio),('range_envelope',envelope)]:
            assert math.isclose(saved[key],value,rel_tol=1e-12)
        recomputed.append(dict(case=case,mode=mode,baseline_median=b,candidate_median=c,
                               ratio=ratio,envelope=envelope,nonoverlapping_regression=regression))
    for mode in MODES:
        rows=[r for r in recomputed if r['mode']==mode]
        summary[mode]={'median_geomean':math.exp(statistics.mean(math.log(r['ratio']) for r in rows)),
                       'range_envelope_geomean':math.exp(statistics.mean(math.log(r['envelope']) for r in rows)),
                       'no_worse_medians':all(r['ratio']<=1 for r in rows)}
        for key,value in summary[mode].items():
            if isinstance(result['numeric_reason'],dict):
                assert math.isclose(result['numeric_reason'][mode][key],value,rel_tol=1e-12)
    if result['numeric_filter']=='reject':
        assert result['numeric_reason']=='confirmed per-case regression'
        assert any(r['nonoverlapping_regression'] for r in recomputed)
    resources=read(d/'resources.json')
    assert all(r['eligible'] and r['idle_percent']>50 and r['half_spare_logical_cpus']>=1 and r['affinity']==mask for r in resources)
    cleanup=read(d/'cleanup.json')
    assert all(cleanup[k] is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
    assert cleanup['final_mask']==env['affinity']['original_affinity'] and cleanup['final_priority_class']==32
    assert read(d/'remaining-owned.json')==[]
    assert len(env['input_sha256'])==16
    # Accessible original artifacts are additionally checked; public-clone audit still checks exact archived bytes.
    workspace=next((p for p in Path(__file__).resolve().parents if (p/'E004-windows-tier2-02').is_dir()),None)
    if workspace is not None:
        pkg=workspace/'E004-windows-tier2-02/E004-server-package'
        for rel,digest in env['manifest']['files'].items():assert sha(pkg/rel)==digest,rel
        for rel,digest in env['input_sha256'].items():assert sha(pkg/rel)==digest,rel
        record=workspace/'GH32-MTUNE/optimization/experiments/GH-32'
        assert sha(record/'windows_cpu_window.py')==env['window_helper_sha256']
        assert sha(pkg/'candidate/optimization/server/run.py')==env['parser_sha256']
        runtime=workspace/'E004-windows-runtime/cygwin/etc/setup/installed.db'
        assert sha(runtime)==env['tier0_identity']['runtime_manifest_sha256']
        for mapping in [env['source_sha256'],env['support_sha256'],env['runtime_file_sha256']]:
            for path,h in mapping.items():
                p=Path(path)
                # The publication index grows after the completed run. Preserve
                # its exact assigned version separately; no scientific raw or
                # original execution manifest is rewritten.
                if p.name=='PUBLIC-SHA256.json' and (d/'frozen-PUBLIC-SHA256.json').exists():
                    p=d/'frozen-PUBLIC-SHA256.json'
                assert sha(p)==h,path
    return dict(audit='PASS',solves=48,emitted_bounds=bounds,raw_manifest_files=len(hashes),
                modes=summary,medians=recomputed,resource_checks=len(resources),
                contention_alerts=sum(r['core_contention_detected'] for r in resources),
                active_contention_alerts=sum(r['core_contention_detected'] and not r['label'].endswith('-preflight') for r in resources),
                min_global_idle=min(r['idle_percent'] for r in resources),min_sibling_idle=min(r['sibling_idle'] for r in resources),
                identity='PASS original files checked' if workspace is not None else 'PASS archived only',cleanup='PASS',decision=result['decision'],tier2='NOT_RUN',tier3='NOT_RUN')

if __name__=='__main__':
    print(json.dumps(audit(Path(sys.argv[1])),indent=2))
