"""GH58 independent finite oracles; no process/filesystem activity on import."""
import itertools
import re

class ScienceError(RuntimeError): pass
class CoverageGap(RuntimeError): pass
def need(ok,why):
    if not ok: raise ScienceError(why)

def wcnf(data):
    lines=[s.split() for s in data.decode('ascii').splitlines() if s.strip() and not s.startswith('c')]
    h=lines.pop(0);need(len(h)==5 and h[:2]==['p','wcnf'],'WCNF header')
    n,count,top=map(int,h[2:]);need(0<n<=10 and top>0,'Finite WCNF dimensions')
    rows=[]
    for s in lines:
        v=list(map(int,s));need(len(v)>=2 and v[0]>0 and v[-1]==0 and all(0<abs(l)<=n for l in v[1:-1]),'WCNF weight/literal/terminator')
        rows.append((v[0],v[1:-1]))
    need(len(rows)==count,'WCNF clause count')
    def sat(c,a):return any(bool(a&(1<<(abs(l)-1)))==(l>0) for l in c)
    feasible=[(a,sum(w for w,c in rows if w<top and not sat(c,a))) for a in range(1<<n) if all(sat(c,a) for w,c in rows if w>=top)]
    need(feasible,'Hard-infeasible oracle fixture')
    best=min(feasible,key=lambda z:(z[1],z[0]));loose=max(feasible,key=lambda z:(z[1],z[0]))
    return dict(exact=best[1],witness=best[0],loose_cost=loose[1],loose_witness=loose[0],assignments=1<<n,hard_satisfying=len(feasible))

def pms(rc,text,exact):
    tails=re.findall(r'optimal:([^\r\n]*)',text)
    vals=[s.split(',')[0].strip() for s in tails]
    need(text.count('optimal:')==len(vals) and vals,'Missing/hidden optimal label')
    need(all(re.fullmatch(r'\d+',v) and int(v)==exact for v in vals),'Wrong/malformed optimal cost')
    statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M)
    need(rc in (10,20) and statuses==(['SATISFIABLE'] if rc==10 else ['UNSATISFIABLE']),'Original PMS rc/status relationship')
    return dict(optimal=exact,returncode=rc,statuses=statuses)

def app(rc,text,exact,require_timeout=False):
    values={key:[] for key in ['lb','ub','d','objective']}
    fields={'d_lb':'lb','d_ub':'ub','d':'d'}
    for line in text.splitlines():
        m=re.match(r'^c\s+(d_lb|d_ub|d)\s*:',line)
        if m:
            key=fields[m.group(1)];s=line[m.end():].strip();values[key].append(s)
        elif re.match(r'^o(?:\s|$)',line):values['objective'].append(line[1:].strip())
    for key,raw in values.items():
        for s in raw:
            if s=='-' and key in ('lb','ub'):continue
            if s=='UNKNOWN' and key=='d':continue
            need(re.fullmatch(r'\d+',s),'Malformed scientific '+key)
            v=int(s);need(v<=exact if key=='lb' else v==exact if key=='d' else v>=exact,'Wrong interim '+key)
    statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M);comments=re.findall(r'^c status:\s*(.*?)\s*$',text,re.M)
    final={k:(int(v[-1]) if v and re.fullmatch(r'\d+',v[-1]) else None) for k,v in values.items()}
    if rc==1:
        need(statuses==['UNKNOWN'] and comments in (['UNKNOWN'],['TIMEOUT (child killed after -cpu-lim)']),'Incomplete original status semantics')
        need(values['d'] and values['d'][-1]=='UNKNOWN' and not values['objective'],'Incomplete original UNKNOWN/noobjective trailer')
        need(values['lb'] and values['ub'],'Incomplete missing bound trailers')
        if not require_timeout:raise CoverageGap('Sound original incomplete result under bounded test deadline')
        if comments!=['TIMEOUT (child killed after -cpu-lim)']:raise CoverageGap('Sound UNKNOWN did not cover required genuine timeout')
    else:
        need(rc==0 and not statuses and not comments,'Original complete rc/status')
        need(all(v==exact for v in final.values()),'Wrong/missing complete final science')
        if require_timeout:raise CoverageGap('Correct early completion did not cover required timeout')
    return dict(values=final,returncode=rc,timeout=rc==1)

def css(stem,fixtures):
    mats={}
    for s in ['Hx','Hz','Gx','Gz']:
        rows=[[int(x) for x in l.split()] for l in (fixtures/(stem+'_'+s+'.txt')).read_text().splitlines() if l.strip() and not l.startswith('#')]
        need(rows and all(set(r)<={0,1} for r in rows),'CSS matrix bits');mats[s]=rows
    n=len(mats['Hx'][0]);need(0<n<=6 and all(len(r)==n for rs in mats.values() for r in rs),'Finite CSS dimensions')
    bits=lambda r:sum(v<<i for i,v in enumerate(r))
    hx=[bits(r) for r in mats['Hx']];hz=[bits(r) for r in mats['Hz']]
    def span(rows):
        out={0}
        for r in rows:out|={v^r for v in out}
        return out
    sx,sz=span(hx),span(hz)
    costs=[(x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if all((h&z).bit_count()%2==0 for h in hx) and all((h&x).bit_count()%2==0 for h in hz) and (x not in sx or z not in sz)]
    need(costs,'CSS missing logical witness');return min(costs)
