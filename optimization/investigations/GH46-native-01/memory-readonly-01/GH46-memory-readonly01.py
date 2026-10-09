import datetime,json,pathlib,subprocess,time
start=datetime.datetime.fromtimestamp(1791505220,datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
end=datetime.datetime.fromtimestamp(1791505250,datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
args=['journalctl','--no-pager','-k','--since',start,'--until',end,'-o','short-iso','--grep','maxcdcl|Out of memory|oom-kill|Killed process|segfault']
p=subprocess.run(args,capture_output=True,timeout=10)
fields={}
for line in pathlib.Path('/proc/meminfo').read_text().splitlines():
 name,value=line.split(':',1)
 if name in ['MemTotal','MemFree','MemAvailable','SwapTotal','SwapFree']:fields[name]=value.strip()
events=pathlib.Path('/sys/fs/cgroup/memory.events')
print(json.dumps(dict(read_only=True,utc=time.time(),historical_window=[start,end],kernel_query=args,kernel_returncode=p.returncode,kernel_stdout=p.stdout.decode('utf8',errors='replace')[:12000],kernel_stderr=p.stderr.decode('utf8',errors='replace')[:2000],current_meminfo_kB=fields,current_root_memory_events=events.read_text() if events.exists() else None,limitations='Current free memory and cumulative root counters do not establish memory state at crash. No solver run or privileged-log access.'),indent=2))
