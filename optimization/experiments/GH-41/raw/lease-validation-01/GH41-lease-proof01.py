import os,json,pathlib,time
r=pathlib.Path('/sys/fs/cgroup');d=r/'distqldpc-bench'
status=pathlib.Path('/proc/self/status').read_text()
proof=dict(uid=os.getuid(),gid=os.getgid(),pid=os.getpid(),affinity=sorted(os.sched_getaffinity(0)),cgroup=pathlib.Path('/proc/self/cgroup').read_text(),no_new_privs=next(x for x in status.splitlines() if x.startswith('NoNewPrivs:')),partition=(d/'cpuset.cpus.partition').read_text().strip(),effective=(d/'cpuset.cpus.effective').read_text().strip(),exclusive=(d/'cpuset.cpus.exclusive.effective').read_text().strip(),global_isolated=(r/'cpuset.cpus.isolated').read_text().strip(),global_effective=(r/'cpuset.cpus.effective').read_text().strip())
assert proof['uid']==1004 and proof['affinity']==[102] and proof['partition']=='isolated' and proof['effective']=='102,230' and proof['exclusive']=='102,230'
assert proof['no_new_privs'].split()[-1]=='1' and '/distqldpc-bench' in proof['cgroup']
print(json.dumps(proof),flush=True)
time.sleep(5)
assert sorted(os.sched_getaffinity(0))==[102] and (d/'cpuset.cpus.partition').read_text().strip()=='isolated'
print(json.dumps(dict(after_five_seconds=True,actual_partition_valid=True)),flush=True)
