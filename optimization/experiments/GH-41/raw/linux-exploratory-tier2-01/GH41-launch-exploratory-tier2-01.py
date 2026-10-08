from pathlib import Path
import json,subprocess,shlex
r=Path(__file__).resolve().parent
old=json.loads((r/'GH41-MTO-WITNESS/optimization/experiments/GH-41/raw/linux-isolated-tier1-01/GH41-linux-isolated-tier1-01.launcher.json').read_text(encoding='utf8'))['argv'][3:]
audit=json.loads((r/'GH41-server-exploratory-tier2-package-01-audit.json').read_text(encoding='utf8'))
args=dict(zip(old[::2],old[1::2]))
args.update({'--package':'/home/yfc/GH41-server-exploratory-tier2-package-01','--out':'/home/yfc/GH41-linux-exploratory-tier2-01','--prerecord':'/home/yfc/GH41-server-exploratory-tier2-prerecord-01.json','--run-assignment':audit['assignment'],'--manifest-sha':audit['manifest_sha'],'--support-sha':audit['support_head'],'--prerecord-sha':audit['prerecord_sha'],'--tier1':'/home/yfc/GH41-linux-isolated-tier1-01','--tier1-audit':'/home/yfc/GH26-independent-GH41-isolated-tier1-01-audit.json'})
command=['taskset','-c','0','sudo','-n','/usr/local/sbin/distqldpc-cpu-run','run','--cwd','/home/yfc','--','/usr/bin/env','PYTHONDONTWRITEBYTECODE=1','/usr/bin/python3.12','-B','/home/yfc/GH41-server-exploratory-tier2-package-01/support/server_tier2_exploratory_launcher.py']
for k,v in args.items():command += [k,v]
ssh=['ssh','-o','BatchMode=yes','yfclab2',shlex.join(command)]
prefix=r/'GH41-exploratory-tier2-lease01'
for suffix in ['.stdout','.stderr','.exit','.command.json']:assert not Path(str(prefix)+suffix).exists()
Path(str(prefix)+'.command.json').write_text(json.dumps(ssh,indent=2)+'\n',encoding='utf8')
with Path(str(prefix)+'.stdout').open('wb') as out,Path(str(prefix)+'.stderr').open('wb') as err:
 p=subprocess.run(ssh,stdout=out,stderr=err)
Path(str(prefix)+'.exit').write_text(str(p.returncode)+'\n',encoding='ascii')
print(json.dumps(dict(returncode=p.returncode,assignment=audit['assignment'],stdout=str(prefix)+'.stdout',stderr=str(prefix)+'.stderr')))
raise SystemExit(p.returncode)
