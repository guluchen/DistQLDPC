from pathlib import Path
import json,hashlib,subprocess
r=Path(__file__).resolve().parent/'DistQLDPC';base='optimization/investigations/GH46-native-01'
catalog=json.loads((r/base/'PUBLIC_CATALOG.json').read_text(encoding='utf8'))
for name,record in catalog.items():
 p=base+'/raw/'+name.replace('\\','/')
 b=subprocess.check_output(['git','-C',str(r),'cat-file','blob','HEAD:'+p])
 assert len(b)==record['size'] and hashlib.sha256(b).hexdigest()==record['sha256'],p
print(json.dumps(dict(actual_git_blob_check='PASS',payloads=len(catalog),commit=subprocess.check_output(['git','-C',str(r),'rev-parse','HEAD'],text=True).strip())))
