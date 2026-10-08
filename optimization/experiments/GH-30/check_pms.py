"""Independent brute-force PMS oracle for original Main output."""
import sys,re
from pathlib import Path
lines=Path(sys.argv[1]).read_text().splitlines();h=lines[0].split()
n,top=int(h[2]),int(h[4]);clauses=[list(map(int,l.split())) for l in lines[1:]]
assert len(clauses)==int(h[3]) and all(c[-1]==0 for c in clauses)
def sat(c,a):return any(bool(a&(1<<(abs(v)-1)))==(v>0) for v in c[1:-1])
exact=min(sum(c[0] for c in clauses if c[0]<top and not sat(c,a)) for a in range(1<<n) if all(sat(c,a) for c in clauses if c[0]>=top))
text=Path(sys.argv[2]).read_text();rc=int(sys.argv[3])
values=re.findall(r'optimal:\s*([^\r\n,]*)',text)
assert rc in (10,20) and values and all(re.fullmatch(r'\d+',v) and int(v)==exact for v in values),'SCIENCE wrong PMS optimum/exit'
assert re.findall(r'^s\s+(.*?)\s*$',text,re.M)==(['SATISFIABLE'] if rc==10 else ['UNSATISFIABLE']),'SCIENCE wrong status'
print('PASS exact',exact)
