"""GH58 support: immutable fixed lease authentication and owned command guard."""

from pathlib import Path

import hashlib,json,os,signal,subprocess,time

HELPER_SHA='0bf26454f93bdb2d1d3973d212f141c1e3af174c4954d35df2ab98abddee0229'

sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

def save(p,d):p.write_text(json.dumps(d,indent=2)+'\n',encoding='utf8')

def cpus(s):
 out=set()
 for x in s.strip().split(','):
  if not x:continue
  a,b=(list(map(int,x.split('-'))) if '-' in x else [int(x)]*2);out.update(range(a,b+1))
 return out

def proc(pid):
 try:
  s=Path('/proc',str(pid),'stat').read_text();f=s[s.rfind(')')+2:].split()
  return dict(pid=pid,group=int(f[2]),session=int(f[3]),birth=int(f[19]))
 except (FileNotFoundError,ProcessLookupError):return None

def members(sid):
 return [r for p in Path('/proc').iterdir() if p.name.isdigit() and (r:=proc(int(p.name))) is not None and r['session']==sid]

def lease():
 root=Path('/sys/fs/cgroup');g=root/'distqldpc-bench';helper=Path('/usr/local/sbin/distqldpc-cpu-run')
 st=helper.stat();assert st.st_uid==0 and not st.st_mode&0o022 and sha(helper)==HELPER_SHA
 assert os.getuid()==1004 and os.sched_getaffinity(0)=={102}
 assert Path('/proc/self/cgroup').read_text().strip()=='0::/distqldpc-bench'
 assert next(x for x in Path('/proc/self/status').read_text().splitlines() if x.startswith('NoNewPrivs:')).split()[-1]=='1'
 fields={n:(g/n).read_text().strip() for n in ['cpuset.cpus.partition','cpuset.cpus.effective','cpuset.cpus.exclusive.effective']}
 assert fields['cpuset.cpus.partition']=='isolated' and cpus(fields['cpuset.cpus.effective'])==cpus(fields['cpuset.cpus.exclusive.effective'])=={102,230}
 assert {102,230}<=cpus((root/'cpuset.cpus.isolated').read_text()) and not {102,230}&cpus((root/'cpuset.cpus.effective').read_text())
 for p in root.iterdir():
  if p!=g and (p/'cpuset.cpus.effective').exists():assert not {102,230}&cpus((p/'cpuset.cpus.effective').read_text())
 return dict(uid=os.getuid(),affinity=sorted(os.sched_getaffinity(0)),fields=fields,host_exclusive=False)

class Guard:
    def __init__(self,out,identities,critical,seconds):
        assert os.getsid(0)==os.getpid(), 'Fresh outer-owned runner session required'
        self.out=out;self.identities=identities;self.critical=critical
        self.deadline=time.monotonic()+seconds;self.original=os.sched_getaffinity(0)
        self.commands=[];self.sid=os.getsid(0);self.current=None;self.birth=None
        self.proof=lease()
    def owned(self):return [r for r in members(self.sid) if r['pid']!=os.getpid()]
    def cleanup(self):
        errors=[]
        for sig,seconds in [(signal.SIGTERM,2),(signal.SIGKILL,5)]:
            if self.current is not None:
                now=proc(self.current.pid)
                if now and self.birth and now['birth']!=self.birth['birth']:
                    raise RuntimeError('Reused owned command PID; no signaling')
            for pg in sorted({r['group'] for r in self.owned()}):
                fresh=[r for r in self.owned() if r['group']==pg]
                if not fresh:continue
                assert pg!=os.getpgrp(),'Refuse signaling runner group'
                try:os.killpg(pg,sig)
                except ProcessLookupError:pass
            end=time.monotonic()+seconds
            while time.monotonic()<end:
                if self.current is not None:self.current.poll()
                if not self.owned():break
                time.sleep(.05)
            if not self.owned():break
        if self.current is not None:self.current.poll()
        remaining=self.owned();assert not remaining,'Owned descendants remained: '+repr(remaining)
        return dict(owned_empty=True,remaining=remaining)
    def run(self,argv,cwd,label,limit):
        assert time.monotonic()<self.deadline,'Aggregate deadline reached'
        assert not self.owned(),'Unexpected owned process before command'
        self.identities();self.critical();lease()
        argv=list(map(str,argv));record=dict(argv=argv,cwd=str(cwd),limit_seconds=limit,label=label)
        save(self.out/(label+'.command.json'),record)
        try:
            with (self.out/(label+'.stdout')).open('wb') as stdout,(self.out/(label+'.stderr')).open('wb') as stderr:
                self.current=subprocess.Popen(argv,cwd=cwd,stdout=stdout,stderr=stderr,process_group=0)
                self.birth=proc(self.current.pid)
                assert self.birth and self.birth['group']==self.current.pid and self.birth['session']==self.sid
                record['leader']=self.birth
                self.current.wait(timeout=min(limit,max(.01,self.deadline-time.monotonic())))
                record['returncode']=self.current.returncode
        except BaseException as error:
            record['engineering_error']=repr(error);raise
        finally:
            try:record.update(self.cleanup())
            except BaseException as error:record['cleanup_error']=repr(error)
            self.commands.append(record);save(self.out/(label+'.command.json'),record)
        assert record.get('owned_empty') and not record.get('cleanup_error'),'Command cleanup failed'
        self.identities();self.critical();lease()
        return record['returncode'],(self.out/(label+'.stdout')).read_bytes(),(self.out/(label+'.stderr')).read_bytes()
    def close(self):
        result=dict(owned_empty=False,actual_restore=False)
        try:result.update(self.cleanup())
        except BaseException as error:result['cleanup_error']=repr(error)
        finally:
            try:
                os.sched_setaffinity(0,self.original)
                result['actual_restore']=os.sched_getaffinity(0)==self.original
                result['actual_affinity']=sorted(os.sched_getaffinity(0))
            except BaseException as error:result['restore_error']=repr(error)
            try:result['lease']=lease()
            except BaseException as error:result['lease_error']=repr(error)
        return result
