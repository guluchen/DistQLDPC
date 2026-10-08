"""Eight one-second functionality runs, no baseline performance comparison."""
import json,os,re,subprocess,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'E004'))
from windows_cpu_window import Window,descendant_affinities
root=Path.cwd(); pkg=root/'E004-windows-tier2-02/E004-server-package'
runtime=root/'E004-windows-runtime/cygwin'; binary=root/'E005-SLS/bin/distqldpc.exe'
out=root/'E005-mechanism-screen-01';out.mkdir(exist_ok=False)
os.environ['PATH']=str(runtime/'bin')+os.pathsep+os.environ['PATH']
save=lambda name,obj:(out/name).write_text(json.dumps(obj,indent=2),encoding='utf8',newline='\n')
def cyg(p):p=str(p).replace('\\','/');return '/cygdrive/'+p[0].lower()+p[2:]
def matrix(p):return [sum(int(b)<<i for i,b in enumerate(line.split())) for line in p.read_text().splitlines() if line.strip() and not line.startswith('#')]
def member(v,rows):
 pivots={}
 for r in rows:
  while r:
   k=r.bit_length()
   if k in pivots:r^=pivots[k]
   else:pivots[k]=r;break
 while v:
  k=v.bit_length()
  if k not in pivots:return False
  v^=pivots[k]
 return True
window=Window(True,0x8000); resources=[]; rows=[]; process=None
result=dict(decision='INCONCLUSIVE',scope='functionality only',performance='not measured')
try:
 save('environment.json',dict(invocation=sys.argv,affinity=window.selection,candidate_sha='749391c9aab5389965822cac94d90aa360446f9a'))
 time.sleep(2);resources.append(window.observe('screen-preflight'));assert resources[-1]['eligible'],'Spare capacity unavailable'
 for case in ['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']:
  prefix=pkg/'baseline/data/matrices'/case; expected=int(case.rsplit('_',1)[1])
  hx,hz,gx,gz=[matrix(Path(str(prefix)+'_'+suffix+'.txt')) for suffix in ['Hx','Hz','Gx','Gz']]
  for mode in ['no-card','card-mto']:
   label=case+'-'+mode;cmd=[str(binary),'-v','-cpu-lim=1','-'+mode,cyg(prefix)];observed=[]
   with (out/(label+'.stdout')).open('w',encoding='utf8') as so,(out/(label+'.stderr')).open('w',encoding='utf8') as se:
    process=subprocess.Popen(cmd,stdout=so,stderr=se);deadline=time.monotonic()+15
    while process.poll() is None:
     time.sleep(.1);observed+=descendant_affinities(process.pid)
     assert all(r['mask']==window.mask and r['priority_class']==32768 for r in observed)
     if time.monotonic()>deadline:raise RuntimeError('External watchdog')
   text=(out/(label+'.stdout')).read_text(encoding='utf8')
   assert process.returncode in [0,1],text
   if process.returncode==1:assert 's UNKNOWN' in text and 'c status: TIMEOUT' in text
   else:assert re.search(r'^c\s+d\s*:\s*'+str(expected)+r'\s*$',text,re.M)
   assert all(int(v)<=expected for v in re.findall(r'^c\s+d_lb:\s*(\d+)',text,re.M))
   assert all(int(v)>=expected for v in re.findall(r'^c\s+d_ub:\s*(\d+)',text,re.M))
   match=re.search(r'c sls: seed 1 budget 10000 flips (\d+) final-hard-unsat (\d+) verified-cap (-?\d+) seconds ([0-9.]+)',text)
   row=dict(case=case,mode=mode,command=cmd,returncode=process.returncode,cap=None,flips=None,acquisition_seconds=None)
   if match:
    flips,unsat,cap,seconds=match.groups();row.update(cap=int(cap),flips=int(flips),final_hard_unsat=int(unsat),acquisition_seconds=float(seconds));assert int(flips)<=10000
    if int(cap)>=0:
     witness=re.search(r'c sls witness: ([01]+) ([01]+)',text);assert witness
     x,z=[sum(int(b)<<i for i,b in enumerate(bits)) for bits in witness.groups()]
     assert not any((r&z).bit_count()%2 for r in hx) and not any((r&x).bit_count()%2 for r in hz)
     assert any((r&x).bit_count()%2 for r in gx) or any((r&z).bit_count()%2 for r in gz)
     assert not member(x,hx) or not member(z,hz)
     assert (x|z).bit_count()==int(cap)>=expected
   rows.append(row);save(label+'.affinity.json',observed);save('samples.json',rows)
   resources.append(window.observe(label));save('resources.json',resources)
   if not resources[-1]['eligible']:raise RuntimeError('Spare-capacity guard')
   print(json.dumps(row),flush=True)
 result.update(functionality='PASS',completed_runs=len(rows),observed_calls=sum(r['cap'] is not None for r in rows),verified_caps=sum(r['cap'] is not None and r['cap']>=0 for r in rows),reason='No controlled performance comparison')
except AssertionError as e:
 result.update(decision='REJECTED',reason=str(e));raise
except Exception as e:
 result.update(reason=repr(e));raise
finally:
 if process is not None and process.poll() is None:
  killed=subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],capture_output=True,text=True);save('kill.json',dict(returncode=killed.returncode,stdout=killed.stdout));process.wait(timeout=15)
 save('cleanup.json',window.close());save('result.json',result);print(json.dumps(result,indent=2),flush=True)
