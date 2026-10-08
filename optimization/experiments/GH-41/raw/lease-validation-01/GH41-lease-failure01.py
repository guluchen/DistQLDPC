import os,pathlib,subprocess,json,time,sys
assert os.getuid()==1004 and sorted(os.sched_getaffinity(0))==[102]
p=subprocess.Popen(['/usr/bin/python3.12','-B','-c','import time;time.sleep(20)'],start_new_session=True)
raw=pathlib.Path('/proc',str(p.pid),'stat').read_text();fields=raw[raw.rfind(')')+2:].split()
print(json.dumps(dict(expected_exit=7,own_descendant_pid=p.pid,own_descendant_birth=int(fields[19]),uid=os.getuid(),affinity=sorted(os.sched_getaffinity(0)),cgroup=pathlib.Path('/proc/self/cgroup').read_text())),flush=True)
time.sleep(2)
sys.exit(7)
