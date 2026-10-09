from pathlib import Path
import json,subprocess,shlex
r=Path(__file__).resolve().parent
d=json.loads((r/'DistQLDPC/optimization/investigations/GH46-native-01/FROZEN.json').read_text(encoding='utf8'))
command=['taskset','-c','0','sudo','-n','/usr/local/sbin/distqldpc-cpu-run','run','--cwd','/home/yfc','--','/usr/bin/env','PYTHONDONTWRITEBYTECODE=1','/usr/bin/python3.12','-B',d['remote_source']+'/launcher.py','--assignment',d['assignment'],'--source-sha',d['driver_sha'],'--launcher-sha',d['launcher_sha']]
ssh=['ssh','-o','BatchMode=yes','yfclab2',shlex.join(command)]
prefix=r/'GH46-native-lease01'
for suffix in ['.stdout','.stderr','.exit','.command.json']:assert not Path(str(prefix)+suffix).exists()
Path(str(prefix)+'.command.json').write_text(json.dumps(ssh,indent=2)+'\n',encoding='utf8')
with Path(str(prefix)+'.stdout').open('wb') as stdout,Path(str(prefix)+'.stderr').open('wb') as stderr:
 p=subprocess.run(ssh,stdout=stdout,stderr=stderr)
Path(str(prefix)+'.exit').write_text(str(p.returncode)+'\n',encoding='ascii')
print(json.dumps(dict(actual_ssh_returncode=p.returncode,assignment=d['assignment'])))
raise SystemExit(p.returncode)
