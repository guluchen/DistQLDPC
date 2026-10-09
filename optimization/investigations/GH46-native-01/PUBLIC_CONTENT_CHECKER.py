from pathlib import Path
import hashlib,json,re,tarfile
r=Path(__file__).resolve().parent;p=r/'DistQLDPC/optimization/investigations/GH46-native-01';raw=p/'raw'
pins=json.loads((raw/'GH46-native-anomaly-01/preexecution.json').read_text(encoding='utf8'))['pins']
allowed=['/home/yfc/GH41-linux-tier0-04/','/usr/','/lib/','/lib64/']
single={'/etc/python3.12/sitecustomize.py','/home/yfc/GH46-family1-variant1.wcnf','/home/yfc/distqldpc-gh41-runtime-03.json','/home/yfc/GH46-native-source-01/run.py'}
assert all((n in single or any(n.startswith(prefix) for prefix in allowed)) and re.fullmatch('[0-9a-f]{64}',h) for n,h in pins.items())
catalog=json.loads((p/'PUBLIC_CATALOG.json').read_text(encoding='utf8'));checked=[]
patterns=[rb'-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY',rb'gh[pousr]_[A-Za-z0-9]{30,}',rb'github_pat_[A-Za-z0-9_]{30,}',rb'AKIA[0-9A-Z]{16}',rb'(?i)(?:authorization\s*:\s*bearer|x-amz-signature=|[?&]sig=)',rb'(?i)"(?:password|access_token|api_key|secret_access_key|session_token)"\s*:\s*"[^"]+"']
for n,record in catalog.items():
 f=raw/n;b=f.read_bytes();assert len(b)==record['size'] and hashlib.sha256(b).hexdigest()==record['sha256']
 assert f.suffix in {'.py','.json','.md','.wcnf','.stdout','.stderr','.exit','.tar'},n
 assert not any(re.search(pattern,b) for pattern in patterns),n
 if f.suffix=='.tar':
  with tarfile.open(f) as t:
   for m in t.getmembers():
    assert m.isfile() or m.isdir()
    if not m.isfile():continue
    payload=t.extractfile(m).read();candidate=raw/m.name
    assert candidate.is_file() and payload==candidate.read_bytes(),m.name
    assert not any(re.search(pattern,payload) for pattern in patterns),m.name
 else:b.decode('utf8')
 checked.append(dict(path=n,size=len(b),sha256=record['sha256']))
report=dict(status='PUBLIC_CONTENT_SCOPE_CHECK_PASS',authorization='User explicitly requested GitHub coordination and cumulative shared experiment experience, including raw evidence.',payload_count=len(checked),checked_payloads=checked,runtime_pins_count=len(pins),runtime_data='Only known test/system paths and SHA256 identities, no runtime file contents or environment values',host_identifiers='Previously disclosed authorized yfc/yfclab2 and experiment paths; uid1004/cpu102230/ownPID metadata',compiled_objects_or_memory_dumps_exported=False,credentials_or_signed_urls_found=False,all_archive_members_equal_checked_extracted_payloads=True,limitation='Scoped content review and known-secret-pattern scan; no general claim that regex proves all confidentiality.',catalog_sha=hashlib.sha256((p/'PUBLIC_CATALOG.json').read_bytes()).hexdigest())
(p/'PUBLIC_CONTENT_CHECK.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k!='checked_payloads'}))
