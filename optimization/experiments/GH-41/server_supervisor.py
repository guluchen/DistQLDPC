"""Disabled support module for nonexclusive observed-quiet Linux diagnostics.
No CLI, build/science orchestration, or claim of a reserved/exclusive host.
"""
import json,os,signal,subprocess,time
from pathlib import Path
RUN_ASSIGNMENT='HOST_SLOT_NOT_ASSIGNED'
def save(p,v):Path(p).write_text(json.dumps(v,indent=2)+'\n',encoding='utf8')
def cpus(text):
    out=set()
    for item in text.strip().split(','):
        if '-' in item:
            lo,hi=map(int,item.split('-'));out.update(range(lo,hi+1))
        else:out.add(int(item))
    return out
def ticks():
    out={}
    for line in Path('/proc/stat').read_text().splitlines():
        fields=line.split()
        if fields and (fields[0]=='cpu' or fields[0][3:].isdigit()):
            values=list(map(int,fields[1:9]));out[fields[0]]=(sum(values),values[3]+values[4])
    return out
def idle(before,after,key):
    total=after[key][0]-before[key][0];free=after[key][1]-before[key][1]
    if total<=0:raise RuntimeError('Insufficient /proc/stat observation')
    return free/total
def process(pid):
    try:
        raw=Path('/proc',str(pid),'stat').read_text();fields=raw[raw.rfind(')')+2:].split()
        return dict(pid=pid,ppid=int(fields[1]),pgrp=int(fields[2]),session=int(fields[3]),start=int(fields[19]))
    except FileNotFoundError:return None
def session_members(session):
    members=[]
    for path in Path('/proc').iterdir():
        if not path.name.isdigit():continue
        item=process(int(path.name))
        if item and item['session']==session:members.append(item)
    return members
class ObservedQuiet:
    def __init__(self,out,cpu,sibling,assignment,aggregate_seconds):
        assert RUN_ASSIGNMENT!='HOST_SLOT_NOT_ASSIGNED','Support only: no assigned CPU slot'
        assert assignment==RUN_ASSIGNMENT and os.name=='posix' and Path('/proc/stat').exists()
        assert os.getsid(0)==os.getpid(),'Tier0 must be started by the reviewed fresh-session outer launcher'
        self.out=Path(out).resolve();assert not self.out.exists(),'Fresh user-owned directory required'
        self.out.mkdir(mode=0o700);self.cpu=cpu;self.sibling=sibling;self.assignment=assignment
        topo=Path('/sys/devices/system/cpu',f'cpu{cpu}','topology/thread_siblings_list').read_text()
        assert cpus(topo)=={cpu,sibling},'Actual fixed SMT pair mismatch'
        self.original=set(os.sched_getaffinity(0));assert cpu in self.original
        self.events=[];self.deadline=time.monotonic()+aggregate_seconds;self.current=None
        self.previous=ticks();self.index=0;self.owned={};self.saved_leader=None
        try:
            os.sched_setaffinity(0,{cpu})
            save(self.out/'context.json',dict(assignment=assignment,cpu=cpu,sibling=sibling,
                original_affinity=sorted(self.original),topology=topo.strip(),exclusive=False,
                classification='OBSERVED_QUIET_DIAGNOSTIC',quiet_seconds=3,sibling_idle_min=.95,global_idle_min=.5))
        except BaseException:
            os.sched_setaffinity(0,self.original);raise
    def observe(self,label,require_target=False):
        now=ticks();global_idle=idle(self.previous,now,'cpu')
        count=len([k for k in now if k!='cpu']);spare=count*global_idle
        row=dict(label=label,time=time.time(),global_idle=global_idle,spare_cpu_equivalents=spare,
            half_spare_workers=int(spare/2),target_idle=idle(self.previous,now,f'cpu{self.cpu}'),
            sibling_idle=idle(self.previous,now,f'cpu{self.sibling}'),require_target=require_target)
        self.previous=now;self.events.append(row);save(self.out/'resources.json',self.events)
        if not (global_idle>.5 and int(spare/2)>=1 and row['sibling_idle']>=.95 and
                (not require_target or row['target_idle']>=.95)):
            raise RuntimeError('INCONCLUSIVE observed-quiet capacity guard: '+label)
        return row
    def owned_members(self):
        if self.current is None:return []
        leader=process(self.current.pid)
        if self.saved_leader is not None and leader is not None and leader['start']!=self.saved_leader['start']:
            raise RuntimeError('INCONCLUSIVE session leader identity reused; no signaling')
        session=session_members(os.getsid(0))
        assert all(p['pid']==os.getpid() or p['pgrp']==self.current.pid for p in session),'Unexpected other owned process group'
        members=[p for p in session if p['pid']!=os.getpid()]
        if members and self.saved_leader is None:
            raise RuntimeError('INCONCLUSIVE session birth identity unconfirmed; no signaling')
            # The outer launcher's fresh child session is inherited by trusted non-detaching
        # make/compiler/solver workers; every observed identity is retained.
        for member in members:
            prior=self.owned.get(member['pid'])
            if prior is not None and prior!=member['start']:
                raise RuntimeError('INCONCLUSIVE owned process identity reused')
            self.owned[member['pid']]=member['start']
            assert member['pgrp']==self.current.pid,'Unexpected detached owned process group'
            try:assert os.sched_getaffinity(member['pid'])=={self.cpu},'Child CPU affinity changed'
            except ProcessLookupError:pass
        return members
    def clean_owned(self):
        if self.current is None:return
        actions=[]
        for sig,wait in [(signal.SIGTERM,2),(signal.SIGKILL,5)]:
            members=self.owned_members()
            # Re-read owned identities immediately before signaling the new
            # process group. No arbitrary PID list, names, or other sessions.
            if members:
                fresh=self.owned_members()
                if fresh:
                    try:os.killpg(self.current.pid,sig);actions.append(dict(signal=int(sig),members=fresh))
                    except ProcessLookupError:pass
            end=time.monotonic()+wait
            while time.monotonic()<end:
                self.current.poll()
                if not self.owned_members():break
                time.sleep(.05)
            if not self.owned_members():break
        self.current.poll();remaining=self.owned_members()
        save(self.out/f'cleanup-{self.index}.json',dict(actions=actions,remaining=remaining,confirmed=not remaining))
        if remaining:raise RuntimeError('INCONCLUSIVE owned cleanup unconfirmed')
    def run(self,argv,cwd,timeout,label):
        assert time.monotonic()<self.deadline,'Aggregate deadline expired'
        assert self.current is None or not self.owned_members(),'Competing owned worker'
        self.previous=ticks();time.sleep(3);self.observe(label+'-quiet-preflight',True)
        assert time.monotonic()<self.deadline,'Aggregate deadline expired after preflight'
        self.index+=1;command=dict(argv=list(map(str,argv)),cwd=str(cwd),limit=timeout,assignment=self.assignment)
        command['state']='STARTING';save(self.out/(label+'.command.json'),command)
        self.owned={};self.saved_leader=None;started=time.monotonic();last=started
        with (self.out/(label+'.stdout')).open('wb') as stdout,(self.out/(label+'.stderr')).open('wb') as stderr:
            try:
                env=dict(os.environ);env.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
                self.current=subprocess.Popen(command['argv'],cwd=cwd,stdout=stdout,stderr=stderr,
                    env=env,process_group=0)
                self.saved_leader=process(self.current.pid);command['leader']=self.saved_leader
                command['state']='RUNNING';save(self.out/(label+'.command.json'),command)
                while self.current.poll() is None:
                    time.sleep(.05);now=time.monotonic()
                    if now-last>=2:
                        command['last_owned_members']=self.owned_members();self.observe(label);last=now
                    if now-started>timeout or now>self.deadline:raise subprocess.TimeoutExpired(argv,timeout)
                command.update(returncode=self.current.returncode,elapsed_sec=time.monotonic()-started)
                if self.owned_members():raise RuntimeError('Unexpected lingering owned descendant after command')
                self.clean_owned()
            except BaseException as error:
                command['error']=repr(error)
                try:self.clean_owned()
                except BaseException as cleanup:command['cleanup_error']=repr(cleanup)
                raise
            finally:save(self.out/(label+'.command.json'),command)
        return command
    def close(self):
        try:self.clean_owned()
        finally:
            os.sched_setaffinity(0,self.original)
            save(self.out/'restoration.json',dict(actual_affinity=sorted(os.sched_getaffinity(0)),
                confirmed=set(os.sched_getaffinity(0))==self.original))
