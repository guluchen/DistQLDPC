"""Read-only evidence audit, not a reproduction or runner import."""
import ctypes
ctypes.windll.kernel32.GetCurrentProcess.restype=ctypes.c_void_p
ctypes.windll.kernel32.SetProcessAffinityMask.argtypes=[ctypes.c_void_p,ctypes.c_size_t]
assert ctypes.windll.kernel32.SetProcessAffinityMask(ctypes.windll.kernel32.GetCurrentProcess(),1)
import ast,hashlib,json,re,tarfile
from pathlib import Path
R=Path(__file__).resolve().parent
sha=lambda b:hashlib.sha256(b).hexdigest()
def contents(path):
 with tarfile.open(path,'r:') as t:
  ms=[m for m in t.getmembers() if m.isfile()]
  assert len({m.name for m in ms})==len(ms)
  assert all(not m.name.startswith('/') and '..' not in Path(m.name).parts for m in ms)
  return {m.name:t.extractfile(m).read() for m in ms}
arc=R/'GH46-native-anomaly-01-raw.tar';raw=contents(arc)
prefix='GH46-native-anomaly-01/'
get=lambda name:raw[prefix+name]
j=lambda name:json.loads(get(name))
index=j('SHA256.json')
assert set(index)=={k[len(prefix):] for k in raw if k.startswith(prefix) and k!=prefix+'SHA256.json'}
for k,h in index.items():assert sha(get(k))==h
source=R/'DistQLDPC/optimization/investigations/GH46-native-01'
freeze=json.loads((source/'FROZEN.json').read_bytes())
for name in ['run.py','launcher.py','PRERECORD.md','FROZEN.json','SOURCE_REVIEW.json']:
 assert raw['GH46-native-source-01/'+name]==(source/name).read_bytes()
driver=raw['GH46-native-source-01/run.py'];launcher=raw['GH46-native-source-01/launcher.py']
assert sha(driver)==freeze['driver_sha'] and sha(launcher)==freeze['launcher_sha']
assert sha(raw['GH46-native-source-01/SOURCE_REVIEW.json'])==freeze['review_sha']
constants={}
for node in ast.parse(driver).body:
 if isinstance(node,ast.Assign) and len(node.targets)==1 and isinstance(node.targets[0],ast.Name) and isinstance(node.value,ast.Constant):constants[node.targets[0].id]=node.value.value
assert constants['ASSIGNMENT']==freeze['assignment']
fixture=raw['GH46-family1-variant1.wcnf']
assert len(fixture)==300 and sha(fixture)==constants['FIXTURE_SHA']
lines=[line.split() for line in fixture.decode('ascii').splitlines() if line.strip() and not line.lstrip().startswith('c')]
assert lines.pop(0)==['p','wcnf','10','28','14']
clauses=[]
for row in lines:
 vals=list(map(int,row));assert vals[-1]==0 and all(1<=abs(v)<=10 for v in vals[1:-1]);clauses.append((vals[0],vals[1:-1]))
hard=[c for w,c in clauses if w==14];soft=[c for w,c in clauses if w==1]
assert len(clauses)==28 and len(hard)==15 and len(soft)==13 and all(len(c)==1 for c in soft)
models=[]
for integer in range(1024):
 assignment=[bool(integer&(1<<i)) for i in range(10)]
 def holds(c):return any(assignment[abs(p)-1]==(p>0) for p in c)
 if all(holds(c) for c in hard):models.append((sum(not holds(c) for c in soft),integer))
assert len(models)==216 and min(c for c,a in models)==5 and (5,472) in models
pre=j('preexecution.json');result=j('result.json');cmd=j('command.json');child=j('child.json')
assert pre['oracle']==result['oracle']==dict(exact=5,witness=472,assignments_enumerated=1024,hard_satisfying_assignments=216,source_soft_all_unit=True)
assert pre['baseline']=='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
t0_path=R/'GH41-linux-tier0-04-raw.tar';t0=contents(t0_path);t0prefix='GH41-linux-tier0-04/'
t0index=json.loads(t0[t0prefix+'SHA256.json'])
assert sha(t0[t0prefix+'SHA256.json'])==constants['RAW_SHA']
for k,h in t0index.items():assert sha(t0[t0prefix+k])==h
extra={k[len(t0prefix):] for k in t0 if k.startswith(t0prefix) and k!=t0prefix+'SHA256.json'}-set(t0index)
assert extra=={'frozen-package/windows-provenance/SHA256.json'}
assert t0[t0prefix+'frozen-package/windows-provenance/SHA256.json']==(R/'GH41-server-package-04/windows-provenance/SHA256.json').read_bytes()
runtime_bytes=(R/'GH41-server-runtime-03.json').read_bytes();assert sha(runtime_bytes)==constants['RUNTIME_SHA']
runtime=json.loads(runtime_bytes)
expected={str(Path('/home/yfc/GH41-linux-tier0-04')/k).replace('\\','/'):h for k,h in t0index.items()}
expected.update(runtime['files']);expected.update({'/home/yfc/GH46-family1-variant1.wcnf':constants['FIXTURE_SHA'],
 '/home/yfc/distqldpc-gh41-runtime-03.json':constants['RUNTIME_SHA'],
 '/home/yfc/GH41-linux-tier0-04/SHA256.json':constants['RAW_SHA'],
 '/home/yfc/GH46-native-source-01/run.py':freeze['driver_sha']})
assert pre['pins']==expected
assert sha(t0[t0prefix+'baseline/bin/maxcdcl'])==constants['BIN_SHA']
assert cmd['argv']==['/home/yfc/GH41-linux-tier0-04/baseline/bin/maxcdcl','-verb=1','/home/yfc/GH46-family1-variant1.wcnf'] and cmd['engineering_limit']==5
assert result['returncode']==result['actual_returncode']==-11
assert result['status']=='NATIVE_SCIENTIFIC_ANOMALY_REPRODUCED' and result['science_pass'] is False
assert result['reported_optima']==result['statuses']==[] and get('solve.stdout')==get('solve.stderr')==b''
assert result['candidate']=='NOT_RUN' and result['performance']=='NOT_MEASURED' and result['baseline_modified'] is False
assert result['owned_empty'] and result['actual_restore'] and result['full_recorded_identity_post'] and result['valid_evidence']
assert result['remaining_owned_group']==[] and result['actual_affinity']==[102]
outer=json.loads(raw['GH46-native-anomaly-01.launcher.json'])
assert outer['returncode']==0 and outer['valid_transport'] and outer['owned_empty'] and outer['actual_restore'] and outer['source_identity_post']
assert outer['remaining']==[] and outer['actual_affinity']==[102] and outer['state']=='CHILD_EXITED' and outer['actions']==[]
assert child==dict(pid=3487389,group=3487389,session=3487384,birth=136241878)
assert outer['leader']==dict(pid=3487384,group=3487384,session=3487384,birth=136241480)
assert json.loads(raw['GH46-native-anomaly-01.launcher.stdout'])==result
assert raw['GH46-native-anomaly-01.launcher.stderr']==b''
streams={name:(R/name).read_bytes() for name in ['GH46-native-lease01.stdout','GH46-native-lease01.stderr','GH46-native-lease01.exit','GH46-native-lease01.command.json','GH46-native-postprobe01.py','GH46-native-postprobe01.stdout','GH46-native-postprobe01.stderr']}
assert streams['GH46-native-lease01.exit']==b'0\r\n'
events=[json.loads(line) for line in streams['GH46-native-lease01.stdout'].decode().splitlines()]
assert [e.get('event') for e in events]==['preflight','acquired','capacity','capacity','capacity',None,'released']
assert events[-2]==outer
assert all(e['idle_percent']>50 and 2<=(256*e['idle_percent']/100)/2 for e in events if 'idle_percent' in e)
assert events[1]['uid']==1004 and events[1]['cpus']==events[-1]['cpus']==[102,230]
external_cmd=json.loads(streams['GH46-native-lease01.command.json']);assert freeze['assignment'] in external_cmd[-1] and freeze['driver_sha'] in external_cmd[-1] and freeze['launcher_sha'] in external_cmd[-1]
post=json.loads(streams['GH46-native-postprobe01.stdout'])
assert post['source_sha']==sha(streams['GH46-native-postprobe01.py']) and post['owned_leader']==outer['leader']
assert post['owned_leader_absent'] and post['remaining_owned_session']==[] and post['group_absent'] and post['actual_root_cpuset_effective']=='0-255'
assert post['helper_returncode']==0 and post['helper_status']['active'] is False and post['helper_status']['lease'] is None and post['helper_status']['partition'] is None
assert json.loads(post['helper_status_raw'])==post['helper_status'] and post['helper_stderr']=='' and post['core_files']==[]
for lease in [pre['lease'],result['post_lease']]:
 assert lease['uid']==1004 and lease['affinity']==[102] and lease['host_exclusive'] is False
 assert lease['fields']=={'cpuset.cpus.partition':'isolated','cpuset.cpus.effective':'102,230','cpuset.cpus.exclusive.effective':'102,230'}
secret=re.compile(rb'-----BEGIN (?:OPENSSH|RSA|EC|DSA|PRIVATE) .*?KEY-----|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[A-Z0-9]{16}|(?i:password|passwd|access_token|api_key)\s*[:=]\s*["\x27][^"\x27]{8,}')
assert not any(secret.search(b) for b in list(raw.values())+list(streams.values()))
report={'schema':'GH52_INDEPENDENT_GH46_NATIVE_ANOMALY_AUDIT','audit_status':'PASS_EVIDENCE_AUTHENTICATED_SCIENTIFIC_FAILURE',
 'science_status':'REJECT_BASELINE_ANOMALY_UNRESOLVED','science_pass':False,'source_sha256':sha(Path(__file__).read_bytes()),
 'archive_sha256':sha(arc.read_bytes()),'archive_files':len(raw),'original_raw_manifest_sha256':sha(get('SHA256.json')),
 'complete_original_raw_manifest_verified':True,'source_freeze_verified':True,'full_retained_T0_tree_verified_files':len(t0index),
 'recorded_full_runtime_and_T0_pin_map_matches':True,'pin_count':len(expected),
 'baseline_binary_sha256':constants['BIN_SHA'],'fixture_sha256':constants['FIXTURE_SHA'],
 'independent_oracle':{'assignments':1024,'hard_feasible':216,'optimum':5,'witness':472,'variables':10,'hard_clauses':15,'unit_soft_clauses':13},
 'actual_solver_returncode':-11,'POSIX_signal':'SIGSEGV','solver_stdout_bytes':0,'solver_stderr_bytes':0,
 'outer_transport_returncode':0,'outer_transport_is_not_scientific_pass':True,'owned_group_session_absence_and_restore_authenticated':True,
 'full_identity_post_record':True,'public_secret_pattern_scan_no_hits':True,
 'external_stream_sha256':{k:sha(v) for k,v in streams.items()},
 'limits':['Read-only archive/source/oracle audit; no solver, compiler, runner import or reproduction.',
 'Remote runtime contents were not independently read at audit time: exact retained inventory/pins, authenticated driver full pre/post assertion and valid cleanup records establish recorded identity evidence.',
 'No causation attributed to upstream MaxCDCL; immutable original baseline and known scientific anomaly remain unwaived; no new baseline, optimization/performance/adoption claim.']}
out=R/'GH52-independent-GH46-native-anomaly-01-audit.json';assert not out.exists()
out.write_bytes((json.dumps(report,indent=2)+'\n').encode())
print(json.dumps({'report':str(out),'sha256':sha(out.read_bytes()),'source_sha256':report['source_sha256'],'audit_status':report['audit_status']}))
