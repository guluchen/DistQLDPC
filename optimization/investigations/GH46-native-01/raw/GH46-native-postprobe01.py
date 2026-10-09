from pathlib import Path
import json,subprocess,time,hashlib,os
home=Path.home();outer=json.loads((home/'GH46-native-anomaly-01.launcher.json').read_text())
leader=outer['leader'];pid=leader['pid'];rows=[]
for p in Path('/proc').iterdir():
 if not p.name.isdigit():continue
 try:s=(p/'stat').read_text()
 except (FileNotFoundError,ProcessLookupError):continue
 f=s[s.rfind(')')+2:].split()
 if int(f[3])==pid:rows.append(dict(pid=int(p.name),group=int(f[2]),session=int(f[3]),birth=int(f[19])))
status=subprocess.run(['sudo','-n','/usr/local/sbin/distqldpc-cpu-run','status'],capture_output=True)
assert status.returncode==0
parsed=json.loads(status.stdout);assert parsed['active'] is False and parsed['lease'] is None
root=Path('/sys/fs/cgroup');assert not (root/'distqldpc-bench').exists()
effective=(root/'cpuset.cpus.effective').read_text().strip();assert effective=='0-255'
assert not Path('/proc',str(pid)).exists() and not rows
out=dict(utc=time.time(),read_only=True,source_sha=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),owned_leader=leader,owned_leader_absent=True,remaining_owned_session=rows,helper_status=parsed,helper_status_raw=status.stdout.decode(),helper_stderr=status.stderr.decode(),helper_returncode=status.returncode,group_absent=True,actual_root_cpuset_effective=effective,actual_cpu_affinity=sorted(os.sched_getaffinity(0)),core_files=[dict(name=p.name,size=p.stat().st_size) for p in (home/'GH41-linux-tier0-04/baseline').glob('core*') if p.is_file()])
print(json.dumps(out,indent=2))
