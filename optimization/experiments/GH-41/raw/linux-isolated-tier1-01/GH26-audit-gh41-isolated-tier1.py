"""Read-only offline independent GH41 fixed-pair Tier1 audit, outside checkout.
Never import evidence/support or launch compute. Authenticated original archives,
lease streams and external post-exit proof are mandatory. Write only a new report.
"""
import argparse,ast,hashlib,json,math,re,statistics,subprocess,tarfile
from pathlib import Path,PurePosixPath
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='66cf8be5a4881643f2063471325e33cecaa0caf1'
CASES=['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']
MODES=['no-card','card-mto'];VERSIONS=['baseline','candidate']
POLICY='PAIR_ISOLATION_DIAGNOSTIC_FORMAL_INCONCLUSIVE'
HELPER='0bf26454f93bdb2d1d3973d212f141c1e3af174c4954d35df2ab98abddee0229'
T0SHA='ecf1f127d1d6f130fa99d954220e10f70a8accec5b6d7d01de2b14ab1118deeb'
T0AUDIT='c9fe629d492e50c9c94f6644390ce2fa47a309da8f92fc218f7b49e27b6a7d0d'
RUNTIME='940fce2a7063e8f6c3fce44fe1e013d194712a7ed9b05873dc2a89ad61accd8a'
BINS={'baseline':'13e15ba78f1d7f96af7d54ba767d3e99fb23c8cf44109b9610f037d343051cf4','candidate':'ba374320bc3c20679585bf8a552c374636404d26a45383bd7d40a0f79f436a03'}
LEASE='dbab398ca46c7b73318fccb6b74bf377e9f9c4ef2e365a7d4ece88017a1d4928'
ISOLATION='7eb90050cd70aae2b76a75fa21609f91c71acc6b0a8163c874488f17424cedf4'
ROBUST='e5a81bcdaf65af5b2da91a5e89c59016780a93d04b5c8d14b8fba1cd56519ff0'
HOSTED='87c45397e734dab37910c633a42db2e28cdb1474eef1570987a17b7a3c870481'
HOSTED_ZIP='bc9bf45541d332dff2def2042c160c91cb9bce0bc9626d85ce79af2fa95bd33f'
ADDITIVE=['ru_utime','ru_stime','ru_nvcsw','ru_nivcsw','ru_minflt','ru_majflt','ru_inblock','ru_oublock']
class ScienceMismatch(RuntimeError):pass
def need(p,why):
    if not p:raise RuntimeError(why)
def science_need(p,why):
    if not p:raise ScienceMismatch(why)
def sha(b):return hashlib.sha256(b).hexdigest()
def file_sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1048576),b''):h.update(b)
    return h.hexdigest()
class OriginalTar:
    def __init__(self,path,expected):
        need(file_sha(path)==expected,'Original archive SHA mismatch '+str(path))
        self.tar=tarfile.open(path);self.members={}
        for m in self.tar.getmembers():
            name=m.name.removeprefix('./');p=PurePosixPath(name)
            need(not p.is_absolute() and '..' not in p.parts and name not in self.members,'Unsafe/duplicate archive member')
            need(m.isdir() or m.isfile(),'Unexpected link/device in original archive');self.members[name]=m
    def data(self,name):
        need(name in self.members and self.members[name].isfile(),'Missing original '+name)
        return self.tar.extractfile(self.members[name]).read()
    def json(self,name):return json.loads(self.data(name))
def number(v):return type(v) in (int,float) and math.isfinite(v)
def equal(a,b):
    # Cross-platform libm rounding affects descriptive geometric means only.
    # Numeric decision is recomputed independently without changed thresholds.
    if isinstance(a,float) or isinstance(b,float):return number(a) and number(b) and math.isclose(a,b,rel_tol=1e-12,abs_tol=1e-12)
    if isinstance(a,dict) and isinstance(b,dict):return a.keys()==b.keys() and all(equal(a[k],b[k]) for k in a)
    if isinstance(a,(list,tuple)) and isinstance(b,(list,tuple)):return len(a)==len(b) and all(equal(x,y) for x,y in zip(a,b))
    return type(a)==type(b) and a==b
def output(text,rc,exact):
    values={}
    patterns={'lb':(r'^c\s+d_lb:\s*(.*?)\s*$',{'-'}),'ub':(r'^c\s+d_ub:\s*(.*?)\s*$',{'-'}),
        'd':(r'^c\s+d\s*:\s*(.*?)\s*$',{'UNKNOWN'}),'objective':(r'^o(?:\s+(.*?))?\s*$',set())}
    for key,(pattern,sentinels) in patterns.items():
        fields=re.findall(pattern,text,re.M)
        for item in fields:
            if item in sentinels:continue
            science_need(re.fullmatch(r'\d+',item),'Malformed scientific '+key)
            v=int(item);science_need(v<=exact if key=='lb' else v==exact if key=='d' else v>=exact,'Wrong scientific '+key)
        values[key]=int(fields[-1]) if fields and re.fullmatch(r'\d+',fields[-1]) else None
    for line in text.splitlines():
        if re.match(r'^c\s+(?:d_lb|d_ub|d)\b',line):science_need(any(re.fullmatch(p,line) for p,_ in patterns.values()),'Malformed scientific prefix')
        if re.match(r'^o(?:\s|$)',line):science_need(re.fullmatch(patterns['objective'][0],line),'Malformed objective prefix')
    statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M);comments=re.findall(r'^c status:\s*(.*?)\s*$',text,re.M)
    if rc==0:
        science_need(not statuses and not comments and all(v==exact for v in values.values()),'Wrong completed scientific/status result')
        return dict(values,returncode=0,timeout=False)
    if rc==1:
        science_need(statuses==['UNKNOWN'] and len(comments)==1 and comments[0] in ['UNKNOWN','TIMEOUT (child killed after -cpu-lim)'],'Wrong incomplete return/status')
        science_need(re.findall(patterns['d'][0],text,re.M)==['UNKNOWN'] and not re.search(r'^o(?:\s|$)',text,re.M),'Fabricated/missing incomplete distance')
        science_need(re.findall(patterns['lb'][0],text,re.M) and re.findall(patterns['ub'][0],text,re.M),'Missing incomplete bounds')
        return dict(values,returncode=1,timeout=comments[0].startswith('TIMEOUT'),reported_status=comments[0])
    science_need(rc is None,'Solver crash/invalid return '+str(rc));return values
def judge(rows):
    modes={};details=[]
    for mode in MODES:
        ratios=[];envelopes=[];nonworse=True
        for case in CASES:
            b=[r['elapsed_sec'] for r in rows if (r['case'],r['mode'],r['version'])==(case,mode,'baseline')]
            c=[r['elapsed_sec'] for r in rows if (r['case'],r['mode'],r['version'])==(case,mode,'candidate')]
            need(len(b)==len(c)==3,'Incomplete fixed samples')
            bm,cm=statistics.median(b),statistics.median(c)
            details.append(dict(case=case,mode=mode,baseline_raw=b,candidate_raw=c,baseline_median=bm,candidate_median=cm,median_ratio=cm/bm,
                baseline_range_over_median=(max(b)-min(b))/bm,baseline_min=min(b),baseline_max=max(b),candidate_min=min(c),candidate_max=max(c)))
            if min(c)>max(b):return 'reject','confirmed per-case regression',details
            ratios.append(cm/bm);envelopes.append(max(c)/min(b));nonworse &= cm<=bm
        gm=lambda x:math.exp(sum(math.log(v) for v in x)/len(x))
        modes[mode]=dict(median_geomean=gm(ratios),range_envelope_geomean=gm(envelopes),no_worse_medians=nonworse)
    return ('pass' if all(v['range_envelope_geomean']<1 and v['no_worse_medians'] for v in modes.values()) else 'inconclusive'),modes,details
def corroboration(rows):
    medians=[];details=[]
    for case in CASES:
        for mode in MODES:
            cells={v:[r for r in rows if (r['case'],r['mode'],r['version'])==(case,mode,v)] for v in VERSIONS}
            raw={v:[r['elapsed_sec'] for r in cells[v]] for v in VERSIONS}
            bm,cm=[statistics.median(raw[v]) for v in VERSIONS]
            medians.append(dict(case=case,mode=mode,raw=raw,baseline_median=bm,candidate_median=cm,ratio=cm/bm,range_envelope=max(raw['candidate'])/min(raw['baseline']),nonoverlapping_regression=min(raw['candidate'])>max(raw['baseline'])))
            intervals={v:[r['exit_interval_sec'] for r in cells[v]] for v in VERSIONS};cpu={v:[r['waited_child_cpu_sec'] for r in cells[v]] for v in VERSIONS};pairs=[]
            for repeat in range(1,4):
                b=next(r for r in cells['baseline'] if r['repeat']==repeat);c=next(r for r in cells['candidate'] if r['repeat']==repeat)
                pairs.append(dict(repeat=repeat,order=['baseline','candidate'] if repeat%2 else ['candidate','baseline'],exit_interval_win=c['exit_interval_sec'][1]<b['exit_interval_sec'][0],cpu_win=c['waited_child_cpu_sec']<b['waited_child_cpu_sec'],conservative_exit_difference_sec=c['exit_interval_sec'][1]-b['exit_interval_sec'][0],cpu_difference_sec=c['waited_child_cpu_sec']-b['waited_child_cpu_sec']))
            ew=max(x[1] for x in intervals['candidate'])<min(x[0] for x in intervals['baseline']);cw=max(cpu['candidate'])<min(cpu['baseline'])
            details.append(dict(case=case,mode=mode,exit_intervals=intervals,cpu_raw=cpu,median_exit_intervals={v:[statistics.median(x[i] for x in intervals[v]) for i in [0,1]] for v in VERSIONS},candidate_max_exit_upper=max(x[1] for x in intervals['candidate']),baseline_min_exit_lower=min(x[0] for x in intervals['baseline']),candidate_max_cpu=max(cpu['candidate']),baseline_min_cpu=min(cpu['baseline']),pairs=pairs,exit_ranges_disjoint_positive=ew,cpu_ranges_disjoint_positive=cw,corroborated=ew and cw and all(p['exit_interval_win'] and p['cpu_win'] for p in pairs)))
    return medians,details
def cpus(text):
    result=set()
    for item in text.strip().split(','):
        if not item:continue
        if '-' in item:
            lo,hi=map(int,item.split('-'));result.update(range(lo,hi+1))
        else:result.add(int(item))
    return result
def main():
    ap=argparse.ArgumentParser()
    for n in ['archive','package-archive','tier0-archive','post-proof','lease-stdout','lease-stderr','lease-exit','hosted-zip','helper-source','repo','out']:ap.add_argument('--'+n,type=Path,required=True)
    for n in ['archive-sha','package-archive-sha','tier0-archive-sha','post-proof-sha','lease-stdout-sha','lease-stderr-sha','lease-exit-sha','prefix','package-prefix','tier0-prefix','manifest-sha','prerecord-sha','support-sha','assignment']:ap.add_argument('--'+n,required=True)
    a=ap.parse_args();need(not a.out.exists() and a.repo.resolve() not in a.out.resolve().parents,'New audit outside checkout required')
    files=[(a.post_proof,a.post_proof_sha),(a.lease_stdout,a.lease_stdout_sha),(a.lease_stderr,a.lease_stderr_sha),(a.lease_exit,a.lease_exit_sha)]
    for p,h in files:need(file_sha(p)==h,'Original external proof/stream SHA '+str(p));need(p.resolve()!=a.out.resolve(),'Evidence overwrite refused')
    need(file_sha(a.hosted_zip)==HOSTED_ZIP and file_sha(a.helper_source)==HELPER,'Actual original hosted ZIP/installed public helper source')
    original=OriginalTar(a.archive,a.archive_sha);package=OriginalTar(a.package_archive,a.package_archive_sha);t0=OriginalTar(a.tier0_archive,a.tier0_archive_sha)
    prefix=a.prefix.strip('/');pp=a.package_prefix.strip('/');tp=a.tier0_prefix.strip('/')
    raw=lambda n:original.data(prefix+'/'+n);js=lambda n:json.loads(raw(n));pkg=lambda n:package.data((pp+'/' if pp else '')+n);prior=lambda n:t0.data(tp+'/'+n)
    tree=js('SHA256.json')
    for n,h in tree.items():need(sha(raw(n))==h,'Original raw hash mismatch '+n)
    present={n[len(prefix)+1:] for n,m in original.members.items() if m.isfile() and n.startswith(prefix+'/')}
    need(present==set(tree)|{'SHA256.json'},'Full raw manifest exact coverage')
    result=js('result.json');pre=js('preexecution.json');context=js('context.json');samples=js('samples.json')
    need(pre['baseline']==BASE and pre['candidate']==CAND and pre['assignment']==a.assignment and pre['support_head']==a.support_sha,'Actual source/assignment')
    need(pre['build']=='NOT_RUN' and pre['exclusive'] is False and pre['interpretation']==POLICY,'No rebuild/exclusive/control claim')
    need(pre['tier0_manifest_sha']==T0SHA and pre['tier0_audit_sha']==T0AUDIT and pre['runtime_sha']==RUNTIME and pre['prerecord_sha']==a.prerecord_sha,'Actual frozen prerequisites')
    need(pre['hosted_audit_sha']==HOSTED,'Actual frozen hosted evidence')
    need(sha(prior('SHA256.json'))==T0SHA and sha(prior('runtime-inventory.json'))==RUNTIME,'Original Tier0/runtime identity')
    for n,h in json.loads(prior('SHA256.json')).items():need(sha(prior(n))==h,'Original Tier0 raw byte changed')
    need(json.loads(prior('context.json'))['cpu']==6 and json.loads(prior('context.json'))['sibling']==134,'Historical Tier0 preserved')
    for v,h in BINS.items():need(sha(prior(v+'/bin/distqldpc'))==h,'Actual frozen native binary')
    manifest=json.loads(pkg('manifest.json'));need(sha(pkg('manifest.json'))==a.manifest_sha,'Actual package manifest')
    need(manifest['baseline']==BASE and manifest['candidate']==CAND and manifest['support_head']==a.support_sha,'Exact source package')
    for n,h in manifest['files'].items():need(sha(pkg(n))==h,'Exact original package byte '+n)
    by_hash=lambda h:next(raw(n) for n,v in tree.items() if v==h)
    prereg=json.loads(by_hash(a.prerecord_sha));lease=json.loads(by_hash(LEASE));prior_audit=json.loads(by_hash(T0AUDIT));hosted=json.loads(by_hash(HOSTED))
    need(prior_audit['classification']=='GH41_NATIVE_TIER0_INDEPENDENT_AUDIT' and prior_audit['raw_manifest_sha']==T0SHA and prior_audit['counts']=={'science':52,'PMS':162,'helper':21840},'Authentic independent full scientific prerequisite')
    need(all(prior_audit[k] is True for k in ['science_complete','full_raw_hashes_match','source_archives_match','runtime_input_binary_hashes_match','owned_empty','actual_restore','outer_transport_valid','full_boundary_identities']),'Original complete prerequisite booleans')
    need(hosted['candidate']==CAND and hosted['zip_sha256']==HOSTED_ZIP and hosted['executed_merge']=='e87894a70b37e675c4c7f3d8a533f86d0f0c8208' and hosted['final_science_count']==8 and hosted['source_byte_equal'] is True and hosted['final_science_pass'] is True,'Authentic original hosted proof')
    need(lease['classification']=='ACTUAL_REGULAR_FIXED_PAIR_LEASE_VALIDATION' and lease['actual_reserved_pair']==[102,230] and lease['installed_helper_sha']==HELPER and lease['forced_supervisor_death_recovery_tested'] is False,'Original regular-lifecycle lease evidence only')
    need(all(lease[k] is True for k in ['normal_exit_pass','nonzero_exit_own_descendant_cleanup_pass','actual_partition_isolated','actual_root_effective_pair_exclusion','actual_group_removed_root_cpus_restored','owned_failure_descendant_absent']),'Actual prior bounded lease validation')
    need(prereg['assignment']==a.assignment and prereg['support_head']==a.support_sha and prereg['baseline']==BASE and prereg['candidate']==CAND and prereg['cases']==CASES and prereg['modes']==MODES and prereg['repeats']==3,'Authentic fixed original prerecord')
    need(prereg['order']==['baseline','candidate','candidate','baseline','baseline','candidate'] and prereg['internal_limit']==180 and prereg['outer_limit']==195 and prereg['aggregate_limit']==6900 and prereg['cpu']==102 and prereg['sibling']==230,'Authentic unchanged fixed order/limits')
    need(prereg['interpretation']==POLICY and prereg['pair_reserved'] is True and prereg['host_exclusive'] is False and prereg['controlled_claim'] is False and prereg['lease_audit_sha']==LEASE,'Actual diagnostic prerecord scope')
    runtime=json.loads(prior('runtime-inventory.json'));need(runtime['schema_version']==2 and runtime['cache_policy']=='DONTWRITE_BYTECODE_FULL_PRE_POST_EXISTING_PYC','Actual original full runtime/cache policy')
    t0_roots=[p.removesuffix('/SHA256.json') for p,v in pre['pins'].items() if p.endswith('/SHA256.json') and v==T0SHA];need(len(t0_roots)==1,'Unique actual Tier0 provenance root');t0_root=t0_roots[0]
    pkg_roots=[p.removesuffix('/manifest.json') for p,v in pre['pins'].items() if p.endswith('/manifest.json') and v==a.manifest_sha];need(len(pkg_roots)==1,'Unique actual new package root');pkg_root=pkg_roots[0]
    for p,v in pre['whole_boundary_pins'].items():
        if p in runtime['files']:need(runtime['files'][p]==v,'Whole original runtime boundary pin')
        else:need(p.startswith(t0_root+'/') and sha(prior(p[len(t0_root)+1:]))==v,'Whole original source/raw boundary pin')
    need(all(pre['whole_boundary_pins'].get(p)==v for p,v in runtime['files'].items()),'Complete original runtime boundary set')
    known_external={a.manifest_sha,a.prerecord_sha,T0AUDIT,HOSTED,LEASE,RUNTIME,HOSTED_ZIP,HELPER}
    for p,v in pre['pins'].items():
        if p.startswith(t0_root+'/'):need(sha(prior(p[len(t0_root)+1:]))==v,'Actual source/input/binary prerequisite pin')
        elif p.startswith(pkg_root+'/'):need(sha(pkg(p[len(pkg_root)+1:]))==v,'Actual current support/package pin')
        elif p in runtime['critical_files']:need(runtime['critical_files'][p]==v,'Actual critical runtime per-command pin')
        else:need(v in known_external,'Unverified external evidence pin '+p)
    for case in CASES:
        for suffix in ['Hx','Hz','Gx','Gz']:
            n=case+'_'+suffix+'.txt';need(sha(prior('frozen-package/inputs/'+n))==prereg['inputs'][n],'Original immutable scientific input')
    need(sha(pkg('support/TIER1_ISOLATED_PAIR_PRERECORD.md'))==ISOLATION and sha(pkg('support/TIER1_NATIVE_ROBUSTNESS_PROPOSAL.md'))==ROBUST,'Preregistered immutable protocols')
    for n in ['server_tier1_isolated.py','server_tier1_isolated_launcher.py','server_tier1_isolated_supervisor.py']:
        blob=subprocess.check_output(['git','-C',str(a.repo),'show',a.support_sha+':optimization/experiments/GH-41/'+n],timeout=15)
        need(pkg('support/'+n).replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'),'Committed executed support '+n)
        if n!='server_tier1_isolated_launcher.py':need(raw(n)==pkg('support/'+n),'Actual retained support '+n)
    source_ast=ast.parse(pkg('support/server_tier1_isolated.py').decode());old_ast=ast.parse(subprocess.check_output(['git','-C',str(a.repo),'show','61a925f:optimization/experiments/GH-41/server_tier1.py'],timeout=15).decode())
    for fn in ['judge','robustness_details']:
        extract=lambda t:next(x for x in t.body if isinstance(x,ast.FunctionDef) and x.name==fn)
        need(ast.dump(extract(source_ast))==ast.dump(extract(old_ast)),'Original immutable filter/corroboration AST')
    need(context['cpu']==102 and context['sibling']==230 and cpus(context['topology'])=={102,230} and context['original_affinity']==[102],'Actual reserved fixed pair')
    need(context['pair_reserved'] is True and context['host_exclusive'] is False,'Pair only claim')
    lease_checks=js('lease-checks.json');need(lease_checks and lease_checks[0]['phase']=='START' and lease_checks[-1]['phase']=='POST_CHILD_CLEANUP','Actual lease lifecycle checks')
    for row in lease_checks:
        proof=row['proof'];need(proof['pair']==[102,230] and proof['actual_uid']==1004 and proof['actual_affinity']==[102] and proof['host_exclusive'] is False and proof['forced_supervisor_death_recovery_tested'] is False,'Actual lease scope')
        p=proof['partition'];need(p['cpuset.cpus.partition']=='isolated' and cpus(p['cpuset.cpus.effective'])==cpus(p['cpuset.cpus.exclusive.effective'])=={102,230},'Actual exclusive isolated effective pair')
        for effective in proof['other_top_level_effective'].values():need(not(cpus(effective)&{102,230}),'Other actual cpuset pair overlap')
    resources=js('resources.json');need(resources,'Actual capacity samples')
    resource_guards_held=all(row['global_idle']>.5 and row['half_spare_workers']>=2 and row['sibling_idle']>=.95 and (not row['require_target'] or row['target_idle']>=.95) for row in resources)
    events=[]
    for line in a.lease_stdout.read_bytes().decode('utf8').splitlines():
        if line.startswith('{'):
            value=json.loads(line)
            if 'event' in value:events.append(value)
    need([r['event'] for r in events].count('preflight')==1 and [r['event'] for r in events].count('acquired')==1 and [r['event'] for r in events].count('released')==1,'Actual helper acquired/released stream lifecycle')
    acquired=next(r for r in events if r['event']=='acquired');released=next(r for r in events if r['event']=='released');flight=next(r for r in events if r['event']=='preflight')
    need(acquired['cpus']==released['cpus']==flight['reserved_cpus']==[102,230] and acquired['uid']==1004 and acquired['maximum_seconds']==7200 and flight['allocated_cpu']==102 and flight['idle_percent']>50,'Actual fixed helper lease scope/capacity')
    need(events[0]['event']=='preflight' and events[1]['event']=='acquired' and events[-1]['event']=='released','Original helper lifecycle order')
    helper_capacity_held=all(r['idle_percent']>50 for r in events if r['event']=='capacity')
    expected=[(case,mode,repeat,version) for case in CASES for mode in MODES for repeat in range(1,4) for version in (VERSIONS if repeat%2 else VERSIONS[::-1])]
    observed=[(r['case'],r['mode'],r['repeat'],r['version']) for r in samples];need(observed==expected[:len(observed)] and len(observed)<=48,'Exact original order/prefix')
    semantic_rows=[];measurements_complete=True
    for row in samples:
        case,mode,repeat,version=row['case'],row['mode'],row['repeat'],row['version'];label=f'{case}-{mode}-{repeat}-{version}';cmd=js(label+'.command.json')
        need(cmd['assignment']==a.assignment and cmd['limit']==195,'Actual per-solve bound/assignment')
        need(cmd['argv'][1:4]==['-v','-cpu-lim=180','-'+mode] and cmd['argv'][0].endswith('/'+version+'/bin/distqldpc') and cmd['argv'][-1].endswith('/inputs/'+case),'Actual immutable native command')
        exact=int(case.rsplit('_',1)[1]);parsed=output(raw(label+'.stdout').decode('utf8'),cmd.get('returncode'),exact)
        need(row['returncode']==cmd.get('returncode') and row['command']==cmd['argv'],'Original scientific sample command')
        if 'semantic' in row:need(equal(row['semantic'],parsed),'Original scientific sample arithmetic')
        science_need(not raw(label+'.stderr'),'Unexpected scientific stderr')
        semantic_rows.append(dict(label=label,result=parsed))
        if cmd.get('returncode')!=0:measurements_complete=False;continue
        if not all(k in row for k in ['exit_interval_sec','waited_child_cpu_sec']):measurements_complete=False;continue
        need(row['elapsed_sec']==cmd['elapsed_sec'] and number(cmd['elapsed_sec']) and cmd['elapsed_sec']>0,'Actual original elapsed')
        for k,v in row['measurement'].items():need(equal(v,cmd.get(k)),'Original measurement field '+k)
        delta={k:cmd['rusage_children_after'][k]-cmd['rusage_children_before'][k] for k in ADDITIVE}
        need(set(delta)==set(cmd['rusage_children_delta']) and equal(delta,cmd['rusage_children_delta']) and all(number(v) and v>=0 for v in delta.values()),'Actual additive child rusage deltas')
        cpu=delta['ru_utime']+delta['ru_stime'];need(cpu==cmd['waited_child_cpu_sec']==row['waited_child_cpu_sec'] and cpu>0 and cmd['waited_child_measurement_complete'] is True,'Actual waited child CPU provenance')
        start=cmd['original_start_monotonic'];alive=cmd['last_alive_lower_monotonic'];exit=cmd['exited_upper_monotonic'];interval=[max(0,alive-start),exit-start]
        need(interval==cmd['exit_interval_sec']==row['exit_interval_sec'] and 0<=interval[0]<=interval[1]<=cmd['elapsed_sec'],'Conservative actual exit interval arithmetic')
        need(cmd['observed_exit_interval_width_sec']==exit-alive and start<=cmd['popen_begin_monotonic']<=cmd['popen_return_monotonic']<=exit,'Actual poll/start timestamps')
        need(equal(cmd['descriptive_elapsed_minus_cpu_sec'],max(0,cmd['elapsed_sec']-cpu)) and equal(cmd['descriptive_cpu_over_elapsed'],cpu/cmd['elapsed_sec']),'Actual descriptive CPU arithmetic')
        need(not cmd.get('error') and not cmd.get('cleanup_error'),'Actual completed command error')
    # Partial runs never receive a numeric verdict. Their prefix remains retained.
    complete=len(samples)==48 and measurements_complete and resource_guards_held and helper_capacity_held and result.get('valid_run') is True and all(r['returncode']==0 and r['science']=='PASS' for r in samples)
    report=dict(classification='GH41_ISOLATED_TIER1_INDEPENDENT_AUDIT',baseline=BASE,candidate=CAND,assignment=a.assignment,support_head=a.support_sha,
        raw_manifest_sha=sha(raw('SHA256.json')),archive_sha=a.archive_sha,science_count=len(semantic_rows),science_results=semantic_rows,
        complete48=complete,resource_guards_held=resource_guards_held,helper_capacity_held=helper_capacity_held,measurements_complete=measurements_complete,decision='INCONCLUSIVE',interpretation=POLICY,pair_reserved=True,host_exclusive=False,forced_supervisor_death_recovery_tested=False,adoption='NOT_AUTHORIZED')
    if complete:
        numeric,reason,legacy=judge(samples);medians,details=corroboration(samples)
        need(result['numeric_filter']==numeric and equal(result['numeric_reason'],reason) and equal(result['legacy_filter_details'],legacy),'Independent ORIGINAL numeric filter')
        need(equal(result['medians'],medians) and equal(result['robustness_details'],details),'Independent all8 raw medians/pair inequalities')
        preliminary=numeric=='pass' and all(r['corroborated'] for r in details if r['mode']=='card-mto')
        need(result['preliminary_corroboration']==preliminary,'Original prerecorded MTO corroboration predicate')
        report.update(numeric_filter=numeric,numeric_reason=reason,medians=medians,robustness_details=details)
    need(result['interpretation']==POLICY and result['host_exclusive'] is False and result['forced_supervisor_death_recovery_tested'] is False and result['decision'] in ['INCONCLUSIVE','REJECT'],'No false adoption/control/recovery claim')
    for n in tree:
        if re.fullmatch(r'cleanup-\d+\.json',n):need(js(n)['confirmed'] is True and js(n)['remaining']==[],'Actual inner owned cleanup')
    restoration=js('restoration.json');need(restoration['confirmed'] is True and restoration['actual_affinity']==[102],'Actual inner restoration to lease CPU')
    outer=original.json(prefix+'.launcher.json');original.data(prefix+'.launcher.stdout');original.data(prefix+'.launcher.stderr')
    need(outer['assignment']==a.assignment and outer['owned_empty'] is True and outer['remaining']==[] and outer['affinity_restored'] is True and outer['actual_affinity']==[102] and outer['full_runtime_post_confirmed'] is True,'Actual outer owned/fullruntime/lease-affinity restore')
    need(outer['outer_seconds']==6960,'Original aggregate outer cap')
    post=json.loads(a.post_proof.read_bytes());need(post['assignment']==a.assignment and post['inner_session_id']==outer['pid'] and post['inner_leader_birth']==outer['leader']['birth'],'Authenticated external session identity')
    need(all(post[k] is True for k in ['observed_after_helper_exit','leader_proc_absent','lease_group_absent','root_effective_restored','helper_owned_empty']) and post['remaining_session_members']==[] and cpus(post['root_effective_cpus'])==set(range(256)),'Actual independent post-lease/root/proc release')
    need(post['probe_returncode']==0 and post['command'] and post['observed_utc'] and post['stdout_hex'] is not None and post['stderr_hex'] is not None,'Actual original post-exit byte proof')
    lease_rc=int(a.lease_exit.read_text().strip());report['helper_returncode']=lease_rc;report['outer_returncode']=outer['returncode']
    if complete:
        need(lease_rc==outer['returncode']==0 and outer['valid_transport'] is True and result['valid_run'] is True and result['full_identity_confirmed'] is True and result['cleanup_restoration_confirmed'] is True,'Complete identity/transport scope')
        configuration_equal=js('host-configuration-before.json')==js('host-configuration-after.json');need(result['available_configuration_unchanged']==configuration_equal,'Actual available host configuration')
        engineering=result['valid_run'] and result['preliminary_corroboration'] and configuration_equal;need(result['engineering_corroboration_valid']==engineering,'Actual descriptive engineering corroboration')
        report.update(audit='PASS',owned_empty=True,actual_restore=True,post_lease_released=True,source_runtime_input_binary_identities=True,full_raw_hashes_match=True,outer_transport_valid=True,engineering_corroboration_valid=engineering)
    else:report.update(audit='INCONCLUSIVE_PARTIAL',retained_sample_count=len(samples),numeric_filter='NOT_RUN')
    a.out.write_text(json.dumps(report,indent=2)+'\n',encoding='utf8');print(json.dumps({'report':str(a.out),'sha256':file_sha(a.out),'audit':report['audit'],'science_count':len(semantic_rows)}))
if __name__=='__main__':main()
