"""Disabled GH41 native Tier2. Frozen Tier0 binaries; no builds or auto advance."""
import argparse,hashlib,importlib.util,json,math,os,re,shutil,signal,statistics,sys
from pathlib import Path
ASSIGNED_URL='https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069823418'
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='66cf8be5a4881643f2063471325e33cecaa0caf1'
TIER0_MANIFEST_SHA='ecf1f127d1d6f130fa99d954220e10f70a8accec5b6d7d01de2b14ab1118deeb'
TIER0_AUDIT_SHA='c9fe629d492e50c9c94f6644390ce2fa47a309da8f92fc218f7b49e27b6a7d0d'
RUNTIME_SHA='940fce2a7063e8f6c3fce44fe1e013d194712a7ed9b05873dc2a89ad61accd8a'
HOSTED_AUDIT_SHA='87c45397e734dab37910c633a42db2e28cdb1474eef1570987a17b7a3c870481'
BINHASHES={'baseline':'13e15ba78f1d7f96af7d54ba767d3e99fb23c8cf44109b9610f037d343051cf4','candidate':'ba374320bc3c20679585bf8a552c374636404d26a45383bd7d40a0f79f436a03'}
HOSTED_ZIP_SHA='bc9bf45541d332dff2def2042c160c91cb9bce0bc9626d85ce79af2fa95bd33f'
HOSTED_MERGE='e87894a70b37e675c4c7f3d8a533f86d0f0c8208'
CASES=['LP_340_56_8']
MODES=['no-card','card-mto']
POLICY='PAIR_ISOLATION_DIAGNOSTIC_FORMAL_INCONCLUSIVE'
ROBUSTNESS_PRERECORD_COMMIT='ab61a882cea88fdc689b1eaaa591e624b9eb3701'
ROBUSTNESS_PRERECORD_SHA='e5a81bcdaf65af5b2da91a5e89c59016780a93d04b5c8d14b8fba1cd56519ff0'
ISOLATION_PRERECORD_COMMIT='98ee77c0f8a03eb3ebd1bff60c4f8b3da566ac6e'
ISOLATION_PRERECORD_SHA='7eb90050cd70aae2b76a75fa21609f91c71acc6b0a8163c874488f17424cedf4'
LEASE_AUDIT_SHA='dbab398ca46c7b73318fccb6b74bf377e9f9c4ef2e365a7d4ece88017a1d4928'
HELPER_SHA='0bf26454f93bdb2d1d3973d212f141c1e3af174c4954d35df2ab98abddee0229'
EXPLORATORY_PRERECORD_COMMIT='8a1245bc0d40f24b76972da50967792e2e25ddc4'
EXPLORATORY_PRERECORD_SHA='a68989d044694f1fdde53d892e6ff07e53e9b4fea4b5db37886e7cea24c55be5'
TIER1_MANIFEST_SHA='18d5231e72684b5ca06b34f7a2784f760fc34cbbbc29a9908eb1461314cb7481'
TIER1_AUDIT_SHA='256bdce7887d0f85b78ea075d7ede9e27a1f082edc53567bb1309203e0a347b4'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):Path(p).write_text(json.dumps(v,indent=2)+'\n',encoding='utf8')
def read(p):return json.loads(Path(p).read_text(encoding='utf8'))
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def incomplete_science(science,rc,text,exact):
    # Original application has two lawful incomplete trailers. Preserve both
    # verbatim; the frozen Tier0 parser deliberately tests true TIMEOUT only.
    statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M)
    comments=re.findall(r'^c status:\s*(.*?)\s*$',text,re.M)
    distance=re.findall(r'^c\s+d\s*:\s*(.*?)\s*$',text,re.M)
    science.need(rc==1 and statuses==['UNKNOWN'] and len(comments)==1 and
        comments[0] in ['UNKNOWN','TIMEOUT (child killed after -cpu-lim)'],'Incomplete status/return')
    science.need(distance==['UNKNOWN'] and not re.search(r'^o(?:\s|$)',text,re.M),'Incomplete fabricated/missing distance or objective')
    values={'d':None,'objective':None}
    for key in ['lb','ub']:
        raw=re.findall(r'^c\s+d_'+key+r':\s*(.*?)\s*$',text,re.M)
        science.need(bool(raw),'Missing incomplete '+key)
        for item in raw:
            if item=='-':continue
            science.need(re.fullmatch(r'\d+',item) is not None,'Malformed incomplete '+key)
            value=int(item);science.need(value<=exact if key=='lb' else value>=exact,'Wrong incomplete '+key)
        values[key]=int(raw[-1]) if re.fullmatch(r'\d+',raw[-1]) else None
    return dict(values,returncode=rc,timeout=comments[0].startswith('TIMEOUT'),reported_status=comments[0])
def host_configuration(cpu,sibling):
    paths=['/sys/devices/system/cpu/cpufreq/boost','/sys/devices/system/cpu/intel_pstate/no_turbo','/sys/devices/system/clocksource/clocksource0/current_clocksource']
    for number in [cpu,sibling]:
        paths += [f'/sys/devices/system/cpu/cpu{number}/cpufreq/'+name for name in ['scaling_governor','scaling_min_freq','scaling_max_freq']]
    result={}
    for name in paths:
        try:result[name]={'value':Path(name).read_text().strip(),'available':True}
        except FileNotFoundError:result[name]={'value':None,'available':False}
    return result
def robustness_details(samples,cases):
    details=[]
    for case in cases:
        for mode in MODES:
            rows={v:[r for r in samples if r['case']==case and r['mode']==mode and r['version']==v] for v in BINHASHES}
            intervals={v:[r['exit_interval_sec'] for r in rows[v]] for v in rows}
            cpu={v:[r['waited_child_cpu_sec'] for r in rows[v]] for v in rows}
            pairs=[]
            for repeat in range(1,4):
                b=next(r for r in rows['baseline'] if r['repeat']==repeat);c=next(r for r in rows['candidate'] if r['repeat']==repeat)
                pairs.append(dict(repeat=repeat,order=['baseline','candidate'] if repeat%2 else ['candidate','baseline'],
                    exit_interval_win=c['exit_interval_sec'][1]<b['exit_interval_sec'][0],cpu_win=c['waited_child_cpu_sec']<b['waited_child_cpu_sec'],
                    conservative_exit_difference_sec=c['exit_interval_sec'][1]-b['exit_interval_sec'][0],cpu_difference_sec=c['waited_child_cpu_sec']-b['waited_child_cpu_sec']))
            exit_win=max(x[1] for x in intervals['candidate'])<min(x[0] for x in intervals['baseline'])
            cpu_win=max(cpu['candidate'])<min(cpu['baseline'])
            details.append(dict(case=case,mode=mode,exit_intervals=intervals,cpu_raw=cpu,
                median_exit_intervals={v:[statistics.median(x[i] for x in intervals[v]) for i in [0,1]] for v in intervals},
                candidate_max_exit_upper=max(x[1] for x in intervals['candidate']),baseline_min_exit_lower=min(x[0] for x in intervals['baseline']),
                candidate_max_cpu=max(cpu['candidate']),baseline_min_cpu=min(cpu['baseline']),pairs=pairs,
                exit_ranges_disjoint_positive=exit_win,cpu_ranges_disjoint_positive=cpu_win,
                corroborated=exit_win and cpu_win and all(p['exit_interval_win'] and p['cpu_win'] for p in pairs)))
    return details
def judge(samples,cases):
    # Exact numeric-filter logic from authenticated E004 run.py judge().
    details=[]; modes={}
    for mode in MODES:
        median_ratios=[]; worst_ratios=[]; nonworse=True
        for case in cases:
            b=[r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']=='baseline']
            c=[r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']=='candidate']
            if len(b)!=3 or len(c)!=3:raise ValueError('incomplete samples')
            bm,cm=statistics.median(b),statistics.median(c)
            details.append({'case':case,'mode':mode,'baseline_raw':b,'candidate_raw':c,
                'baseline_median':bm,'candidate_median':cm,'median_ratio':cm/bm,
                'baseline_range_over_median':(max(b)-min(b))/bm,
                'baseline_min':min(b),'baseline_max':max(b),'candidate_min':min(c),'candidate_max':max(c)})
            if min(c)>max(b):return 'reject','confirmed per-case regression',details
            median_ratios.append(cm/bm);worst_ratios.append(max(c)/min(b));nonworse &= cm<=bm
        gm=lambda xs:math.exp(sum(math.log(x) for x in xs)/len(xs))
        modes[mode]={'median_geomean':gm(median_ratios),'range_envelope_geomean':gm(worst_ratios),'no_worse_medians':nonworse}
    passed=all(x['range_envelope_geomean']<1 and x['no_worse_medians'] for x in modes.values())
    return ('pass' if passed else 'inconclusive'),modes,details
def main():
    ap=argparse.ArgumentParser()
    for name in ['package','out','runtime-inventory','tier0','tier0-audit','hosted-audit','prerecord','lease-audit','tier1','tier1-audit']:ap.add_argument('--'+name,type=Path,required=True)
    for name in ['run-assignment','manifest-sha','runtime-sha','support-sha','tier0-sha','tier0-audit-sha','hosted-audit-sha','prerecord-sha']:ap.add_argument('--'+name,required=True)
    ap.add_argument('--cpu',type=int,required=True);ap.add_argument('--sibling',type=int,required=True)
    a=ap.parse_args();assert ASSIGNED_URL!='HOST_SLOT_NOT_ASSIGNED' and a.run_assignment==ASSIGNED_URL
    assert 'NOT_FROZEN' not in ''.join([TIER0_MANIFEST_SHA,TIER0_AUDIT_SHA,RUNTIME_SHA,HOSTED_AUDIT_SHA,*BINHASHES.values()])
    assert sys.platform=='linux' and os.geteuid()!=0
    assert os.environ.get('PYTHONDONTWRITEBYTECODE')=='1' and sys.dont_write_bytecode
    assert not any(os.environ.get(k) for k in ['CXX','CXXFLAGS','LDFLAGS','MAKEFLAGS','LD_PRELOAD','LD_LIBRARY_PATH'])
    package=a.package.resolve();t0=a.tier0.resolve();out=a.out.resolve()
    assert t0.parent==Path.home() and out.parent==Path.home() and not out.exists() and t0!=out
    assert not any(p.name=='__pycache__' or p.suffix=='.pyc' for p in package.rglob('*'))
    pins={};whole={}
    def pin(p,value):
        p=p.resolve();assert sha(p)==value,'Identity mismatch: '+str(p);pins[str(p)]=value
    pin(package/'manifest.json',a.manifest_sha);manifest=read(package/'manifest.json')
    assert manifest['support_head']==a.support_sha and manifest['baseline']==BASE and manifest['candidate']==CAND
    for name,value in manifest['files'].items():
        p=(package/name).resolve();assert p.is_relative_to(package);pin(p,value)
    assert sha(__file__)==manifest['files']['support/server_tier2_exploratory.py']
    pin(package/'support/TIER1_NATIVE_ROBUSTNESS_PROPOSAL.md',ROBUSTNESS_PRERECORD_SHA)
    pin(package/'support/TIER1_ISOLATED_PAIR_PRERECORD.md',ISOLATION_PRERECORD_SHA)
    pin(package/'support/TIER2_EXPLORATORY_PRERECORD.md',EXPLORATORY_PRERECORD_SHA)
    pin(a.tier1_audit,TIER1_AUDIT_SHA);audit1=read(a.tier1_audit)
    assert audit1['classification']=='GH41_ISOLATED_TIER1_INDEPENDENT_AUDIT'
    assert audit1['baseline']==BASE and audit1['candidate']==CAND
    assert audit1['raw_manifest_sha']==TIER1_MANIFEST_SHA and audit1['science_count']==48
    assert audit1['audit']=='PASS' and audit1['numeric_filter']=='inconclusive'
    assert audit1['decision']=='INCONCLUSIVE' and audit1['engineering_corroboration_valid'] is False
    assert all(audit1[k] is True for k in ['complete48','resource_guards_held','helper_capacity_held','measurements_complete','owned_empty','actual_restore','post_lease_released','source_runtime_input_binary_identities','full_raw_hashes_match','outer_transport_valid'])
    t1=a.tier1.resolve();assert t1.parent==Path.home() and t1!=out and t1!=t0
    pin(t1/'SHA256.json',TIER1_MANIFEST_SHA)
    for name,value in read(t1/'SHA256.json').items():
        p=(t1/name).resolve();assert p.is_relative_to(t1);assert sha(p)==value;whole[str(p)]=value
    pin(a.tier1_audit,TIER1_AUDIT_SHA)
    pin(Path('/usr/local/sbin/distqldpc-cpu-run'),HELPER_SHA)
    pin(a.lease_audit,LEASE_AUDIT_SHA);lease=read(a.lease_audit)
    assert lease['classification']=='ACTUAL_REGULAR_FIXED_PAIR_LEASE_VALIDATION'
    assert all(lease[k] is True for k in ['normal_exit_pass','nonzero_exit_own_descendant_cleanup_pass','actual_partition_isolated','actual_root_effective_pair_exclusion','actual_group_removed_root_cpus_restored','owned_failure_descendant_absent'])
    assert lease['actual_reserved_pair']==[102,230] and lease['forced_supervisor_death_recovery_tested'] is False
    assert lease['installed_helper_sha']==HELPER_SHA
    assert a.tier0_sha==TIER0_MANIFEST_SHA and a.tier0_audit_sha==TIER0_AUDIT_SHA
    pin(t0/'SHA256.json',a.tier0_sha);raw=read(t0/'SHA256.json')
    assert len(raw)>=200,'Incomplete native Tier0 evidence'
    for name,value in raw.items():
        p=(t0/name).resolve();assert p.is_relative_to(t0);assert sha(p)==value;whole[str(p)]=value
    pin(a.tier0_audit,a.tier0_audit_sha);audit=read(a.tier0_audit)
    assert audit['classification']=='GH41_NATIVE_TIER0_INDEPENDENT_AUDIT'
    assert audit['baseline']==BASE and audit['candidate']==CAND and audit['raw_manifest_sha']==TIER0_MANIFEST_SHA
    assert all(audit[k] is True for k in ['science_complete','full_raw_hashes_match','source_archives_match','runtime_input_binary_hashes_match','owned_empty','actual_restore','outer_transport_valid','full_boundary_identities'])
    assert audit['counts']=={'science':52,'PMS':162,'helper':21840}
    summary0=read(t0/'summary.json')
    assert summary0['status']=='TIER0_COMPLETE' and summary0['Tier0']=='LOCAL_PASS' and summary0['valid_run'] is True
    assert summary0['baseline']==BASE and summary0['candidate']==CAND
    assert summary0['science']==52 and summary0['PMS']==162 and summary0['helper']==21840
    assert summary0['identity_confirmed'] is True and summary0['cleanup_restoration_confirmed'] is True
    assert summary0['classification']=='CORRECTNESS_CAPACITY_ONLY' and summary0['performance']=='NOT_MEASURED'
    prior_context=read(t0/'context.json');assert (prior_context['cpu'],prior_context['sibling'])==(6,134) and (a.cpu,a.sibling)==(102,230)
    science0=read(t0/'science.json');pms0=read(t0/'pms-results.json')
    assert len(science0)==52 and len(pms0)==162 and read(t0/'full-runtime-postexecution.json')['confirmed'] is True
    assert a.runtime_sha==RUNTIME_SHA and sha(t0/'runtime-inventory.json')==RUNTIME_SHA
    pin(a.runtime_inventory,a.runtime_sha);runtime=read(a.runtime_inventory)
    assert runtime['schema_version']==2 and runtime['metadata_only'] is True and runtime['gcc_version'].split('.')[0]=='13'
    assert runtime['identity_policy']=='FULL_PRE_IMPORT_AND_POST_RUN_CRITICAL_PER_COMMAND'
    assert runtime['cache_policy']=='DONTWRITE_BYTECODE_FULL_PRE_POST_EXISTING_PYC'
    assert runtime['critical_files'] and all(runtime['files'].get(p)==v for p,v in runtime['critical_files'].items())
    assert str(Path(sys.executable).resolve())==runtime['python']
    for p,v in runtime['files'].items():assert sha(p)==v;whole[p]=v
    for p,v in runtime['critical_files'].items():pin(Path(p),v)
    assert a.hosted_audit_sha==HOSTED_AUDIT_SHA;pin(a.hosted_audit,a.hosted_audit_sha);hosted=read(a.hosted_audit)
    assert hosted['candidate']==CAND and hosted['executed_merge']==HOSTED_MERGE and hosted['zip_sha256']==HOSTED_ZIP_SHA
    assert hosted['final_science_count']==8 and all(hosted[k] is True for k in ['source_byte_equal','final_science_pass','original_zip_retained'])
    assert hosted['interim_bounds_retained'] is False and hosted['timing_classification']=='DIAGNOSTIC_ONLY'
    assert sha(Path(hosted['zip_path']))==HOSTED_ZIP_SHA;pin(Path(hosted['zip_path']),HOSTED_ZIP_SHA)
    pin(a.prerecord,a.prerecord_sha);prereg=read(a.prerecord)
    assert prereg['assignment']==a.run_assignment and prereg['support_head']==a.support_sha
    assert prereg['baseline']==BASE and prereg['candidate']==CAND and prereg['cases']==CASES and prereg['modes']==MODES
    assert prereg['repeats']==3 and prereg['order']==['baseline','candidate','candidate','baseline','baseline','candidate']
    assert prereg['internal_limit']==600 and prereg['outer_limit']==615 and prereg['aggregate_limit']==6900
    assert prereg['exclusive'] is False and prereg['interpretation']==POLICY and prereg['controlled_claim'] is False
    assert prereg['cpu']==a.cpu and prereg['sibling']==a.sibling and prereg['tier0_manifest_sha']==TIER0_MANIFEST_SHA
    assert prereg['robustness_prerecord_commit']==ROBUSTNESS_PRERECORD_COMMIT and prereg['robustness_prerecord_sha']==ROBUSTNESS_PRERECORD_SHA
    assert prereg['isolation_prerecord_commit']==ISOLATION_PRERECORD_COMMIT and prereg['isolation_prerecord_sha']==ISOLATION_PRERECORD_SHA
    assert prereg['pair_reserved'] is True and prereg['host_exclusive'] is False and prereg['lease_audit_sha']==LEASE_AUDIT_SHA
    assert prereg['exploratory_prerecord_commit']==EXPLORATORY_PRERECORD_COMMIT and prereg['exploratory_prerecord_sha']==EXPLORATORY_PRERECORD_SHA
    assert prereg['tier1_audit_sha']==TIER1_AUDIT_SHA and prereg['tier1_manifest_sha']==TIER1_MANIFEST_SHA and prereg['tier1_numeric_filter']=='inconclusive'
    binaries={v:t0/v/'bin/distqldpc' for v in BINHASHES}
    assert read(t0/'binary-hashes.json')==BINHASHES
    for v,p in binaries.items():pin(p,BINHASHES[v])
    frozen=read(t0/'frozen-package/manifest.json')
    assert frozen['baseline']==BASE and frozen['candidate']==CAND
    for case in CASES:
        for suffix in ['Hx','Hz','Gx','Gz']:
            name=case+'_'+suffix+'.txt';value=frozen['files']['inputs/'+name]
            assert prereg['inputs'][name]==value
            pin(t0/'frozen-package/inputs'/name,value)
    # Entire original source + runtime + raw authenticated above. Per solve only
    # immutable code/support/input/binary/critical runtime, not old build logs.
    for name,value in raw.items():
        if name.startswith(('baseline/src/','candidate/src/','frozen-package/')) or name in ['baseline/Makefile','candidate/Makefile']:pins[str(t0/name)]=value
    supervisor=module('gh41_tier1_supervisor',package/'support/server_tier2_exploratory_supervisor.py')
    science=module('gh41_tier1_science',t0/'frozen-package/support/server_science.py')
    assert supervisor.RUN_ASSIGNMENT==a.run_assignment
    def terminate(signum,frame):raise RuntimeError('External Tier2 termination '+str(signum))
    signal.signal(signal.SIGTERM,terminate);os.environ['PATH']='/usr/bin:/bin'
    samples=[];window=None;configuration_before=None;result=dict(status='INCONCLUSIVE',Tier2='NOT_RUN',decision='INCONCLUSIVE',performance='NOT_MEASURED',exclusive=False,interpretation=POLICY,assignment=a.run_assignment,robustness_prerecord_commit=ROBUSTNESS_PRERECORD_COMMIT,robustness_prerecord_sha=ROBUSTNESS_PRERECORD_SHA)
    def identities(full=False):
        for p,v in (dict(whole,**pins) if full else pins).items():assert sha(p)==v,'Identity changed: '+p
    try:
        window=supervisor.ObservedQuiet(out,a.cpu,a.sibling,a.run_assignment,6900)
        configuration_before=host_configuration(a.cpu,a.sibling);save(out/'host-configuration-before.json',configuration_before)
        save(out/'preexecution.json',dict(baseline=BASE,candidate=CAND,support_head=a.support_sha,assignment=a.run_assignment,tier0_manifest_sha=a.tier0_sha,tier0_audit_sha=a.tier0_audit_sha,runtime_sha=a.runtime_sha,hosted_audit_sha=a.hosted_audit_sha,prerecord_sha=a.prerecord_sha,pins=pins,whole_boundary_pins=whole,build='NOT_RUN',exclusive=False,interpretation=POLICY))
        for p in [Path(__file__),package/'support/server_tier2_exploratory_supervisor.py',a.prerecord,a.tier0_audit,a.hosted_audit,a.lease_audit,a.tier1_audit]:shutil.copyfile(p,out/p.name)
        for case in CASES:
            exact=int(case.rsplit('_',1)[1])
            for mode in MODES:
                reference=None
                for repeat in range(1,4):
                    for version in (['baseline','candidate'] if repeat%2 else ['candidate','baseline']):
                        label=f'{case}-{mode}-{repeat}-{version}';identities()
                        print('START '+label,flush=True)
                        command=window.run([binaries[version],'-v','-cpu-lim=600','-'+mode,t0/'frozen-package/inputs'/case],t0/version,615,label)
                        identities();rc=command['returncode'];text=(out/(label+'.stdout')).read_bytes().decode('utf8',errors='replace')
                        row=dict(case=case,mode=mode,repeat=repeat,version=version,elapsed_sec=command['elapsed_sec'],returncode=rc,command=command['argv'],science='PENDING',
                            measurement={key:command.get(key) for key in ['original_start_monotonic','popen_begin_monotonic','popen_return_monotonic','last_alive_lower_monotonic','exited_upper_monotonic','exit_interval_sec','observed_exit_interval_width_sec','rusage_children_before','rusage_children_after','rusage_children_delta','waited_child_cpu_sec','waited_child_measurement_complete','descriptive_elapsed_minus_cpu_sec','descriptive_cpu_over_elapsed']})
                        samples.append(row);save(out/'samples.json',samples)
                        if rc not in (0,1):raise science.ScienceError('Solver crash/invalid return: '+label)
                        semantic=incomplete_science(science,rc,text,exact) if rc==1 else science.app(rc,text,exact);row['semantic']=semantic;row['science']='PASS';save(out/'samples.json',samples)
                        if rc==1:raise RuntimeError('Genuine incomplete solve blocks timing filter: '+label)
                        science.need(reference is None or reference==semantic,'Per-case result semantics changed: '+label);reference=semantic
                        assert command['waited_child_measurement_complete'] is True,'Incomplete waited-child usage provenance'
                        assert all(v>=0 for v in command['rusage_children_delta'].values()),'Negative waited-child usage delta'
                        lo,hi=command['exit_interval_sec'];assert 0<=lo<=hi<=command['elapsed_sec'],'Invalid observed exit interval'
                        assert command['waited_child_cpu_sec']>0,'Unresolved CPU measurement'
                        row.update(exit_interval_sec=command['exit_interval_sec'],waited_child_cpu_sec=command['waited_child_cpu_sec']);save(out/'samples.json',samples)
        assert len(samples)==12
        numeric,reason,legacy_details=judge(samples,CASES);medians=[]
        for case in CASES:
            for mode in MODES:
                values={v:[r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']==v] for v in BINHASHES}
                b,c=[statistics.median(values[v]) for v in BINHASHES]
                medians.append(dict(case=case,mode=mode,raw=values,baseline_median=b,candidate_median=c,ratio=c/b,range_envelope=max(values['candidate'])/min(values['baseline']),nonoverlapping_regression=min(values['candidate'])>max(values['baseline'])))
        corroboration=robustness_details(samples,CASES)
        diagnostic='REJECT' if numeric=='reject' else 'SPECIALIZED_DIAGNOSTIC' if all(r['corroborated'] for r in corroboration if r['mode']=='card-mto') else 'INCONCLUSIVE'
        result.update(status='FILTER_COMPLETE',Tier2='12_SCIENCE_PASS',performance='OBSERVED_QUIET_DIAGNOSTIC',numeric_filter=numeric,numeric_reason=reason,legacy_filter_details=legacy_details,medians=medians,robustness_details=corroboration,
            preliminary_corroboration=(numeric=='pass' and all(r['corroborated'] for r in corroboration if r['mode']=='card-mto')),decision=diagnostic,reason='Exploratory medium-case result; prior Tier1 INCONCLUSIVE retained, no adoption or Tier3 authorized',prior_tier1_numeric_filter='inconclusive',exploratory=True,adoption='NOT_AUTHORIZED')
    except science.ScienceError as error:
        result.update(status='SCIENTIFIC_REJECT',Tier2='REJECT',decision='REJECT',reason=str(error));print('SCIENCE STOP '+str(error),flush=True)
    except BaseException as error:result['reason']=repr(error)
    finally:
        if configuration_before is not None:
            try:
                configuration_after=host_configuration(a.cpu,a.sibling);save(out/'host-configuration-after.json',configuration_after)
                result['available_configuration_unchanged']=configuration_before==configuration_after
                result['unavailable_configuration_fields']=[k for k,v in configuration_after.items() if not v['available']]
            except BaseException as error:result.update(available_configuration_unchanged=False,configuration_error=repr(error))
        if window is not None:
            try:
                window.close();restoration=read(out/'restoration.json')
                assert restoration['confirmed'] is True and restoration['actual_affinity']==sorted(window.original),'Actual affinity restoration unconfirmed'
                result['cleanup_restoration_confirmed']=True
            except BaseException as error:result.update(cleanup_restoration_confirmed=False,cleanup_error=repr(error))
        try:identities(full=True);result['full_identity_confirmed']=True
        except BaseException as error:result.update(full_identity_confirmed=False,identity_error=repr(error))
        result['valid_run']=bool(result['status']=='FILTER_COMPLETE' and len(samples)==12 and result.get('cleanup_restoration_confirmed') and result.get('full_identity_confirmed'))
        result['engineering_corroboration_valid']=bool(result['valid_run'] and result.get('preliminary_corroboration') and result.get('available_configuration_unchanged'))
        result['pair_reserved']=True;result['host_exclusive']=False;result['forced_supervisor_death_recovery_tested']=False
        result['engineering_status']='DIAGNOSTIC_CORROBORATED_TIER2_PENDING_RECOVERY_UNVERIFIED' if result['engineering_corroboration_valid'] else 'NUMERIC_PASS_WITH_ROBUSTNESS_UNRESOLVED' if result.get('numeric_filter')=='pass' else result.get('numeric_filter','INCONCLUSIVE')
        if not result['valid_run'] and result['decision']!='REJECT':result.update(status='INCONCLUSIVE',decision='INCONCLUSIVE')
        if out.exists():
            save(out/'result.json',result);save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json'})
        print(json.dumps(result,indent=2),flush=True)
    return 0 if result.get('valid_run') else 1
if __name__=='__main__':sys.exit(main())
