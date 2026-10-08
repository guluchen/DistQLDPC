import pathlib,json,subprocess
root=pathlib.Path('/sys/fs/cgroup');remaining=[]
for p in pathlib.Path('/proc').iterdir():
 if p.name.isdigit():
  try:
   raw=(p/'stat').read_text();f=raw[raw.rfind(')')+2:].split()
  except (FileNotFoundError,ProcessLookupError):continue
  if int(f[3])==3454484:remaining.append(dict(pid=int(p.name),group=int(f[2]),session=int(f[3]),birth=int(f[19])))
status=subprocess.run(['/usr/bin/sudo','-n','/usr/local/sbin/distqldpc-cpu-run','status'],capture_output=True)
assert status.returncode==0
lease=json.loads(status.stdout);assert lease['active'] is False and lease['lease'] is None and lease['partition'] is None
result=dict(leader_proc_absent=not pathlib.Path('/proc/3454484').exists(),remaining_session_members=remaining,lease_group_absent=not (root/'distqldpc-bench').exists(),root_effective_cpus=(root/'cpuset.cpus.effective').read_text().strip(),root_isolated=(root/'cpuset.cpus.isolated').read_text().strip(),helper_status=lease,helper_status_stdout_hex=status.stdout.hex(),helper_status_stderr_hex=status.stderr.hex())
assert result['leader_proc_absent'] and not remaining and result['lease_group_absent'] and result['root_effective_cpus']=='0-255' and not result['root_isolated']
print(json.dumps(result))
