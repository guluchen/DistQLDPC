"""Independent exact-payload public-safety evidence; no push or remote operation."""
import ctypes
ctypes.windll.kernel32.GetCurrentProcess.restype=ctypes.c_void_p
ctypes.windll.kernel32.SetProcessAffinityMask.argtypes=[ctypes.c_void_p,ctypes.c_size_t]
assert ctypes.windll.kernel32.SetProcessAffinityMask(ctypes.windll.kernel32.GetCurrentProcess(),1)
import hashlib,json,re,subprocess,tarfile
from pathlib import Path
R=Path(__file__).resolve().parent;repo=R/'DistQLDPC';base=repo/'optimization/investigations/GH46-native-01'
sha=lambda b:hashlib.sha256(b).hexdigest()
def git(*args):return subprocess.check_output(['git','-C',str(repo),*args])
commit=git('rev-parse','fd85ce5').decode().strip()
assert git('remote','get-url','--push','origin').decode().strip()=='https://github.com/guluchen/DistQLDPC.git'
names=git('diff-tree','--no-commit-id','--name-only','-r',commit).decode().splitlines()
assert len(names)==28 and names[0]=='.gitattributes'
assert all(name=='.gitattributes' or name.startswith('optimization/investigations/GH46-native-01/') for name in names)
rawnames=[name for name in names if '/raw/' in name];assert len(rawnames)==25
bad=re.compile(rb'-----BEGIN (?:OPENSSH|RSA|EC|DSA|PRIVATE).*?KEY-----|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[A-Z0-9]{16}|(?i:password|passwd|access_token|api_key)\s*[:=]\s*["\x27][^"\x27]{8,}')
records=[]
for name in names:
 local=(repo/name).read_bytes();b=git('show',commit+':'+name)
 if '/raw/' in name:assert b==local
 else:assert b.replace(b'\r\n',b'\n')==local.replace(b'\r\n',b'\n')
 assert not bad.search(b)
 if name.endswith('.tar'):
  with tarfile.open(repo/name,'r:') as t:
   members=[m for m in t.getmembers() if m.isfile()]
   assert len(members)==16
   for m in members:
    assert not m.name.startswith('/') and '..' not in Path(m.name).parts
    assert Path(m.name).suffix in ['.json','.py','.md','.wcnf','.stdout','.stderr']
    data=t.extractfile(m).read();data.decode('utf8');assert not bad.search(data)
    assert data==(base/'raw'/m.name).read_bytes()
  category='Original tar; exactly16 UTF8 source/JSON/fixture/stream members, no executable/library/object/core/key payload'
 else:
  b.decode('utf8')
  if '/preexecution.json' in name:
   category='JSON metadata only:25934 path-to-SHA256 pins plus public assignment/lease/oracle, no file content or environment values'
  elif name.endswith('.wcnf'):category='Exact300-byte synthetic10-variable valid WCNF; no user data'
  elif name.endswith('.py'):category='Public investigation/control/postproof source; no authentication secret or environment value dump'
  elif name.endswith('.stderr'):category='Empty or retained SSH oom_score_adj permission diagnostics, no credentials'
  elif name.endswith('.stdout'):category='Retained experiment/helper/postproof JSON facts or empty solver stream'
  elif name.endswith('.exit'):category='ASCII transport exit code'
  else:category='Public source prerecord/review/hash catalog/result/config metadata'
 records.append({'path':name,'bytes':len(b),'sha256':sha(b),'public_content_classification':category,'actual_committed_git_bytes_equal':b==local,'tracked_doc_normalized_equivalence_only':b!=local})
pre=json.loads((base/'raw/GH46-native-anomaly-01/preexecution.json').read_bytes())
assert set(pre)=={'assignment','baseline','pins','lease','oracle','build','candidate','performance'}
pins=pre['pins'];assert len(pins)==25934
assert all(isinstance(p,str) and isinstance(h,str) and re.fullmatch('[0-9a-f]{64}',h) for p,h in pins.items())
runtime=json.loads((R/'GH41-server-runtime-03.json').read_bytes())
assert all(p.startswith(('/usr/','/lib/','/lib64/','/etc/python3.12/')) for p in runtime['files'])
assert all(p in runtime['files'] or p.startswith('/home/yfc/GH41-linux-tier0-04/') or p in ['/home/yfc/GH46-family1-variant1.wcnf','/home/yfc/distqldpc-gh41-runtime-03.json','/home/yfc/GH46-native-source-01/run.py'] for p in pins)
assert all(pins[p]==h for p,h in runtime['files'].items())
assert not any('/.ssh/' in p or '/.aws/' in p or '/.config/' in p or '/.gnupg/' in p for p in pins)
# Every apparent token/secret word in pin paths is a standard-library/header/module filename, never its content.
catalog=json.loads((base/'PUBLIC_CATALOG.json').read_bytes())
report={'schema':'GH52_GH46_NATIVE_PUBLIC_PAYLOAD_INDEPENDENT_AUDIT','status':'EXACT_PUBLIC_EXPERIMENT_PAYLOAD_VERIFIED',
 'source_sha256':sha(Path(__file__).read_bytes()),'commit':commit,'exact_remote':'https://github.com/guluchen/DistQLDPC.git',
 'changed_paths':28,'raw_payload_files':25,'archive_members':16,'archive_sha256':sha((base/'raw/GH46-native-anomaly-01-raw.tar').read_bytes()),
 'all25_raw_git_bytes_equal':True,'three_other_paths_authenticated_as_actual_Git_blobs_with_text_normalization_where_applicable':True,'all_payloads_utf8_or_fully_inspected_tar':True,
 'no_executable_object_library_core_or_private_key_content':True,'no_secret_pattern_hits':True,
 'pins_are_hashes_not_file_contents':True,'pin_count':25934,'standard_runtime_pin_count':len(runtime['files']),
 'no_environment_value_dump':True,'records':records,
 'limits':'This audit establishes concrete payload safety for the already authorized public experiment repository; it does not override automatic approval review or initiate a push. Scientific result remains baseline SIGSEGV REJECT; no solver/build/reproduction.'}
out=R/'GH52-GH46-native-publication-audit-v2.json';assert not out.exists();out.write_bytes((json.dumps(report,indent=2)+'\n').encode())
print(json.dumps({'report':str(out),'sha256':sha(out.read_bytes()),'source_sha256':report['source_sha256'],'status':report['status']}))
