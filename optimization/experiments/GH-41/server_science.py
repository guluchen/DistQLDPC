"""Original-objective checks for GH41 Linux Tier0; no execution on import."""
import itertools,re
class ScienceError(RuntimeError):pass
class CoverageGap(RuntimeError):pass
def need(p,why):
    if not p:raise ScienceError(why)
def app(rc,text,exact,timeout=False):
    values={}
    patterns={'lb':(r'^c\s+d_lb:\s*(.*?)\s*$',{'-'}),'ub':(r'^c\s+d_ub:\s*(.*?)\s*$',{'-'}),
        'd':(r'^c\s+d\s*:\s*(.*?)\s*$',{'UNKNOWN'}),'objective':(r'^o(?:\s+(.*?))?\s*$',set())}
    for key,(pattern,sentinels) in patterns.items():
        raw=re.findall(pattern,text,re.M)
        for item in raw:
            if item in sentinels:continue
            need(item is not None and re.fullmatch(r'\d+',item),'Malformed '+key)
            v=int(item);need(v<=exact if key=='lb' else v==exact if key=='d' else v>=exact,'Wrong interim '+key)
        values[key]=int(raw[-1]) if raw and re.fullmatch(r'\d+',raw[-1]) else None
    statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M);comments=re.findall(r'^c status:\s*(.*?)\s*$',text,re.M)
    if timeout:
        need(rc==1 and statuses==['UNKNOWN'] and len(comments)==1 and comments[0].startswith('TIMEOUT'),'Timeout status/return')
        need(values['d'] is None and values['objective'] is None and not re.search(r'^o(?:\s|$)',text,re.M),'Timeout fabricated optimum')
    else:
        need(rc==0 and not statuses and not comments,'Complete status/return')
        need(all(v==exact for v in values.values()),'Incomplete/wrong final science')
    return dict(values,returncode=rc,timeout=timeout)
def wcnf(data):
    rows=[];n=top=None
    for line in data.decode().splitlines():
        if not line or line.startswith('c'):continue
        fields=line.split()
        if fields[0]=='p':need(fields[1]=='wcnf','Fixture format');n,count,top=map(int,fields[2:]);continue
        values=list(map(int,fields));need(values[-1]==0,'WCNF terminator');rows.append((values[0],values[1:-1]))
    need(n is not None and len(rows)==count and n<=6,'Original bounded fixture size')
    def sat(c,a):return any(bool(a&(1<<(abs(p)-1)))==(p>0) for p in c)
    feasible=[(a,sum(w for w,c in rows if w<top and not sat(c,a))) for a in range(1<<n) if all(sat(c,a) for w,c in rows if w>=top)]
    need(bool(feasible),'Original fixture infeasible');exact=min(cost for _,cost in feasible)
    return exact,min(feasible,key=lambda row:(row[1],row[0])),max(feasible,key=lambda row:(row[1],row[0]))
def pms(rc,text,exact):
    vals=re.findall(r'optimal:\s*([^\s,]+)',text)
    need(rc in (10,20) and vals,'PMS return/optimum missing')
    need(all(re.fullmatch(r'\d+',v) and int(v)==exact for v in vals),'PMS wrong/malformed optimum')
    statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M)
    need(statuses==(['SATISFIABLE'] if rc==10 else ['UNSATISFIABLE']),'PMS status semantics')
    return dict(returncode=rc,statuses=statuses,optimal=exact)
def css(stem,fixtures):
    mats={}
    for suffix in ['Hx','Hz','Gx','Gz']:
        lines=(fixtures/(stem+'_'+suffix+'.txt')).read_text().splitlines()
        rows=[[int(x) for x in line.split()] for line in lines if line.strip()]
        need(bool(rows) and all(set(r)<={0,1} for r in rows),'CSS original matrix')
        mats[suffix]=rows
    n=len(mats['Hx'][0]);need(all(len(r)==n for rows in mats.values() for r in rows),'CSS shape')
    def bits(row):return sum(v<<i for i,v in enumerate(row))
    hx=[bits(r) for r in mats['Hx']];hz=[bits(r) for r in mats['Hz']]
    def span(rows):
        vals={0}
        for row in rows:vals|={v^row for v in vals}
        return vals
    sx,sz=span(hx),span(hz)
    costs=[(x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if
        all((h&z).bit_count()%2==0 for h in hx) and all((h&x).bit_count()%2==0 for h in hz) and (x not in sx or z not in sz)]
    need(bool(costs),'CSS no logical candidate');return min(costs)
