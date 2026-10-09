"""Independent read-only backtrace/public-payload audit, no runner imports or reproduction."""
import ctypes
ctypes.windll.kernel32.GetCurrentProcess.restype=ctypes.c_void_p
ctypes.windll.kernel32.SetProcessAffinityMask.argtypes=[ctypes.c_void_p,ctypes.c_size_t]
assert ctypes.windll.kernel32.SetProcessAffinityMask(ctypes.windll.kernel32.GetCurrentProcess(),1)
import ast,hashlib,json,re,subprocess,tarfile
from pathlib import Path
R=Path(__file__).resolve().parent;repo=R/'GH58-BASELINE-FIX';record=repo/'optimization/investigations/GH58';D=record/'raw/backtrace-01'
sha=lambda b:hashlib.sha256(b).hexdigest()
def git(*args):return subprocess.check_output(['git','-C',str(repo),*args])
commit=git('rev-parse','81bb3aa').decode().strip()
catalog=json.loads((record/'BACKTRACE01_PUBLIC_CATALOG.json').read_bytes());assert len(catalog)==26
members_proof=[]
secret=re.compile(rb'-----BEGIN (?:OPENSSH|RSA|EC|DSA|PRIVATE).*?KEY-----|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[A-Z0-9]{16}|(?i:password|passwd|access_token|api_key)\s*[:=]\s*["\x27][^"\x27]{8,}')
for name,proof in catalog.items():
 b=(D/name).read_bytes();assert len(b)==proof['size'] and sha(b)==proof['sha256']
 assert git('show',commit+':optimization/investigations/GH58/raw/backtrace-01/'+name)==b
 assert not secret.search(b)
 if not name.endswith('.tar'):
  b.decode('utf8');assert Path(name).suffix in ['.py','.md','.json','.stdout','.stderr','.exit']
 members_proof.append(dict(path=name,bytes=len(b),sha256=sha(b),Git_bytes_equal=True,public_classification='Experiment source/hash/JSON/control/debugger text; no runtime file contents, environment value dump or credentials'))
arc=D/'GH58-backtrace-01-raw.tar';assert sha(arc.read_bytes())=='00018209379eef35226b25e0e799f08056fe156b133a170548c81bc37e7d7fb8'
with tarfile.open(arc,'r:') as t:
 ms=[m for m in t.getmembers() if m.isfile()];assert len({m.name for m in ms})==len(ms)
 for m in ms:
  assert not m.name.startswith('/') and '..' not in Path(m.name).parts
  b=t.extractfile(m).read();b.decode('utf8');assert Path(m.name).suffix in ['.py','.md','.json','.stdout','.stderr'] and not secret.search(b)
  assert b==(D/m.name).read_bytes()
prefix=D/'GH58-backtrace-01';load=lambda n:json.loads((prefix/n).read_bytes())
index=load('SHA256.json');assert set(index)=={p.name for p in prefix.iterdir() if p.is_file() and p.name!='SHA256.json'}
for n,h in index.items():assert sha((prefix/n).read_bytes())==h
frozen=json.loads((D/'GH58-backtrace-source-01/FROZEN.json').read_bytes())
for n in ['run.py','launcher.py','PRERECORD.md','FROZEN.json','SOURCE_REVIEW.json']:
 assert (D/'GH58-backtrace-source-01'/n).read_bytes().replace(b'\r\n',b'\n')==git('show','174cd6b:optimization/investigations/GH58/'+n).replace(b'\r\n',b'\n')
driver=(D/'GH58-backtrace-source-01/run.py').read_bytes()
assert sha(driver)==frozen['driver_sha'] and sha((D/'GH58-backtrace-source-01/launcher.py').read_bytes())==frozen['launcher_sha']
assert sha((D/'GH58-backtrace-source-01/SOURCE_REVIEW.json').read_bytes())==frozen['review_sha']=='a2da2558e1523bc220eaf38a62dddfe47c66536e471e34b07f3185d5dc9ff00a'
constants={}
for n in ast.parse(driver).body:
 if isinstance(n,ast.Assign) and len(n.targets)==1 and isinstance(n.targets[0],ast.Name) and isinstance(n.value,ast.Constant):constants[n.targets[0].id]=n.value.value
pre=load('preexecution.json');result=load('result.json');command=load('command.json');child=load('child.json')
old=json.loads((R/'DistQLDPC/optimization/investigations/GH46-native-01/raw/GH46-native-anomaly-01/preexecution.json').read_bytes())
expected=dict(old['pins']);del expected['/home/yfc/GH46-native-source-01/run.py']
expected['/home/yfc/GH58-backtrace-source-01/run.py']=frozen['driver_sha'];expected['/usr/bin/gdb']=constants['GDB_SHA']
assert pre['pins']==expected and all(re.fullmatch('[0-9a-f]{64}',h) for h in expected.values())
assert pre['baseline']==old['baseline']=='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
assert pre['oracle']==result['oracle']==old['oracle']
fixture=(R/'DistQLDPC/optimization/investigations/GH46-native-01/raw/GH46-family1-variant1.wcnf').read_bytes()
assert len(fixture)==300 and sha(fixture)==constants['FIXTURE_SHA']
lines=[l.split() for l in fixture.decode().splitlines() if l.strip() and not l.startswith('c')]
assert lines.pop(0)==['p','wcnf','10','28','14']
cs=[]
for row in lines:
 v=list(map(int,row));assert v[-1]==0 and all(1<=abs(p)<=10 for p in v[1:-1]);cs.append((v[0],v[1:-1]))
assert len(cs)==28 and sum(w==14 for w,c in cs)==15 and sum(w==1 and len(c)==1 for w,c in cs)==13
feasible=[]
for mask in range(1024):
 def sat(c):return any(bool(mask&(1<<(abs(p)-1)))==(p>0) for p in c)
 if all(sat(c) for w,c in cs if w==14):feasible.append((sum(w for w,c in cs if w<14 and not sat(c)),mask))
assert len(feasible)==216 and min(cost for cost,mask in feasible)==5 and (5,472) in feasible
argv=command['argv'];assert argv[0]=='/usr/bin/gdb' and argv[-3:]==['/home/yfc/GH41-linux-tier0-04/baseline/bin/maxcdcl','-verb=1','/home/yfc/GH46-family1-variant1.wcnf']
assert argv.count('run')==1 and '--nx' in argv and '--nh' in argv and 'set auto-load off' in argv and command['engineering_limit']==15
stdout=(prefix/'solve.stdout').read_text();assert 'Program received signal SIGSEGV, Segmentation fault.' in stdout
frames=re.findall(r'^#.*$',stdout,re.M);assert frames==result['frames']
assert ['simplepropagateForLK','detectInitConflicts','solve_','solveLimited','main']==[re.search(r'(simplepropagateForLK|detectInitConflicts|solve_|solveLimited|main)',x).group(0) for x in frames]
assert 'Solver.cc:5804' in frames[1] and 'Solver.cc:6566' in frames[2] and 'Main.cc:217' in frames[4]
assert '<Minisat::Solver::simplepropagateForLK()+197>' in stdout and re.search(r'^\$1 = 11$',stdout,re.M)
assert result['science_pass'] is False and result['debugger_returncode']==result['actual_debugger_returncode']==0 and result['status']=='BACKTRACE_CAPTURED_SIGSEGV'
assert result['candidate']=='NOT_RUN' and result['performance']=='NOT_MEASURED' and result['baseline_modified'] is False
assert result['owned_empty'] and result['actual_restore'] and result['full_recorded_identity_post'] and result['valid_evidence'] and result['remaining_owned_session_except_self']==[]
outer=json.loads((D/'GH58-backtrace-01.launcher.json').read_bytes())
assert outer['leader']==dict(pid=3492226,group=3492226,session=3492226,birth=136349098)
assert child==dict(pid=3492239,group=3492239,session=3492226,birth=136349470)
assert outer['returncode']==0 and outer['owned_empty'] and outer['actual_restore'] and outer['source_identity_post'] and outer['valid_transport'] and outer['remaining']==[] and outer['actual_affinity']==[102]
assert json.loads((D/'GH58-backtrace-01.launcher.stdout').read_bytes())==result
events=[json.loads(l) for l in (D/'GH58-backtrace-lease01.stdout').read_text().splitlines()]
assert events[1]['event']=='acquired' and events[-1]['event']=='released' and events[1]['cpus']==events[-1]['cpus']==[102,230] and events[-2]==outer
assert all(e['idle_percent']>50 and 2<=(256*e['idle_percent']/100)/2 for e in events if 'idle_percent' in e)
assert (D/'GH58-backtrace-lease01.exit').read_bytes()==b'0\r\n'
post=json.loads((D/'GH58-backtrace-postprobe01.stdout').read_bytes())
assert post['source_sha']==sha((D/'GH58-backtrace-postprobe01.py').read_bytes()) and post['owned_leader']==outer['leader']
assert post['owned_leader_absent'] and post['remaining_owned_session']==[] and post['group_absent'] and post['actual_root_cpuset_effective']=='0-255' and post['core_files']==[]
assert post['helper_returncode']==0 and post['helper_status']['active'] is False and post['helper_status']['lease'] is None and json.loads(post['helper_status_raw'])==post['helper_status']
dis=(D/'GH58-original-simplepropagate-disassembly.stdout').read_text()
assert '0000000000018ea0 <_ZN7Minisat6Solver20simplepropagateForLKEv>:' in dis
assert re.search(r'18f65:\s+8b 48 04\s+mov\s+0x4\(%rax\),%ecx',dis) and int('18f65',16)-int('18ea0',16)==197
assert 'Solver.cc:5623' in dis.split('18f65:')[0][-200:]
solver=git('show','24572d6:src/solver/Solver.cc').decode().splitlines();assert 'wbin[k].blocker' in solver[5622]
report={'schema':'GH58_INDEPENDENT_BACKTRACE01_RAW_AND_PUBLIC_AUDIT','audit_status':'PASS_EVIDENCE_AUTHENTICATED_SCIENTIFIC_FAILURE_UNRESOLVED',
 'source_sha256':sha(Path(__file__).read_bytes()),'frozen_commit':'174cd6b','raw_commit':commit,'raw_catalog_files':26,'tar_files':len(ms),
 'archive_sha256':sha(arc.read_bytes()),'original_raw_manifest_all_files_verified':True,'all26_actual_Git_blobs_and_public_catalog_verified':True,
 'all_tar_members_UTF8_and_match_retained_bytes':True,'no_binary_object_core_library_key_contents':True,'no_secret_pattern_hits':True,
 'pins_hashes_only_authenticated_previous_map_plus_GDB_and_driver':True,'pin_count':len(expected),'GDB_sha256':constants['GDB_SHA'],
 'independent_oracle':{'variables':10,'hard':15,'unit_soft':13,'assignments':1024,'hard_feasible':216,'optimum':5,'witness':472},
 'debugger_returncode':0,'debugger_exit_is_not_science_PASS':True,'inferior_signal':'SIGSEGV','signal_number':11,
 'fault_function':'simplepropagateForLK','fault_offset_decimal':197,'fault_instruction':'mov 0x4(%rax),%ecx','linked_instruction_address':'0x18f65',
 'source_mapping':'Original Solver.cc5623 wbin[k].blocker read','cause_established':False,'actual_owned_cleanup_and_restore_authenticated':True,
 'full_recorded_runtime_identity_post':True,'postprobe_root_cpuset':'0-255','payloads':members_proof,
 'limits':['Read-only original evidence/source/math audit; no solver/debugger/compile/import runner/second reproduction.',
 'Fault location is authenticated; invalid pointer/index/list mutation cause not established by this backtrace.',
 'Remote runtime bytes not freshly read by auditor; retained authenticated pinmap and original driver fullpre/post records checked.',
 'Scientific baseline anomaly remains unresolved; no new baseline/waiver/performance/optimization/adoption claim.']}
out=R/'GH58-independent-backtrace01-audit.json';assert not out.exists();out.write_bytes((json.dumps(report,indent=2)+'\n').encode())
print(json.dumps({'report':str(out),'sha256':sha(out.read_bytes()),'source_sha256':report['source_sha256'],'status':report['audit_status']}))
