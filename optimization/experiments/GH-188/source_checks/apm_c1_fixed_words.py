# Original finite arithmetic check of two FIXED published words. No search.
import json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
from validate_css import basis,contains,dot
P=216
F=[(73,87),(199,75),(181,24),(127,213),(199,75),(181,186)]
G=[(97,188),(73,204),(25,140),(13,154),(73,168),(25,68)]
X=[(0,0),(1,110),(2,76),(3,72),(4,192),(5,40),(7,195),(8,90),(10,123),(11,180)]
Z=[(0,204),(1,26),(2,136),(3,60),(4,180),(5,100),(7,183),(8,78),(10,111),(11,168)]
words=[sum(1<<(c*P+t) for c,t in coords) for coords in (X,Z)]
results=[]
for convention in ['row_f(x)=y','column_Me_t=e_f(t)']:
 def perm(pair,t,transpose=False):
  a,b=pair
  if (convention=='column_Me_t=e_f(t)')^transpose:return (pow(a,-1,P)*(t-b))%P
  return (a*t+b)%P
 hx=[];hz=[]
 for i in range(3):
  for t in range(P):
   xx=zz=0
   for j in range(6):
    xx^=1<<(j*P+perm(F[(j-i)%6],t));xx^=1<<((6+j)*P+perm(G[(j-i)%6],t))
    zz^=1<<(j*P+perm(G[(i-j)%6],t,True));zz^=1<<((6+j)*P+perm(F[(i-j)%6],t,True))
   hx.append(xx);hz.append(zz)
 rx,rz=basis(hx),basis(hz)
 results.append(dict(convention=convention,n=12*P,k=12*P-len(rx)-len(rz),ranks=[len(rx),len(rz)],commutation=not any(dot(x,z) for x in hx for z in hz),published_X_weight10_syndrome_weight=sum(dot(words[0],z) for z in hz),published_Z_weight10_syndrome_weight=sum(dot(words[1],x) for x in hx),X_outside_stabilizer=not contains(rx,words[0]),Z_outside_stabilizer=not contains(rz,words[1])))
print(json.dumps(results,indent=2))
