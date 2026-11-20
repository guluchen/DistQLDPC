#!/usr/bin/env python3
"""Independent exhaustive GF(2) oracle, no external solver or solver hints."""
import argparse,ctypes as C,itertools,json,random,sys,time
from pathlib import Path
class Problem(C.Structure):
 _fields_=[('n',C.c_uint),('checks',C.c_uint),('logical_rows',C.c_uint),('stabilizers',C.c_uint),('h',C.POINTER(C.c_ubyte)),('logical',C.POINTER(C.c_ubyte)),('stabilizer',C.POINTER(C.c_ubyte))]
class Frame(C.Structure):
 _fields_=[(s,C.c_uint) for s in ['row','next','chosen','mark','phase']]
class Workspace(C.Structure):
 _fields_=[('capacity',C.c_uint),('frame_capacity',C.c_uint)]+[(s,C.POINTER(C.c_ubyte)) for s in ['selected','forbidden','syndrome','logical_value','packed']]+[('undo',C.POINTER(C.c_uint)),('frames',C.POINTER(Frame))]
class Stats(C.Structure):
 _fields_=[(s,C.c_uint) for s in ['steps','nodes','pack_prunes','charge_prunes','overlap_prunes']]
def arr(rows,n):return (C.c_ubyte*(len(rows)*n))(*[(r>>q)&1 for r in rows for q in range(n)])
def good(e,h,l):return e!=0 and not any((r&e).bit_count()%2 for r in h) and any((r&e).bit_count()%2 for r in l)
def oracle(n,h,l):return min((e.bit_count() for e in range(1,1<<n) if good(e,h,l)),default=None)
class Harness:
 def __init__(self,lib):
  self.lib=C.CDLL(str(Path(lib).resolve()));self.queries=0;self.models=0;self.assertions=0;self.prunes=[0,0,0]
  args=[C.POINTER(Problem),C.c_uint,C.c_uint,C.c_uint,C.POINTER(Workspace),C.POINTER(C.c_ubyte),C.POINTER(Stats)]
  self.lib.ccv_decide.argtypes=args;self.lib.ccv_decide.restype=C.c_int
  self.lib.ccv_distance.argtypes=[C.POINTER(Problem),C.c_uint,C.c_uint,C.POINTER(Workspace),C.POINTER(C.c_ubyte),C.POINTER(C.c_uint),C.POINTER(Stats)];self.lib.ccv_distance.restype=C.c_int
 def check(self,b,message):
  self.assertions+=1
  if not b:raise AssertionError(message)
 def run(self,n,h,l,k,rules,cap=None,budget=1000000):
  inputs=[arr(rows,n) for rows in [h,l,k]];copies=[bytes(a) for a in inputs]
  p=Problem(n,len(h),len(l),len(k),*inputs)
  # Each writable byte/word/frame allocation has untouched guard elements.
  keep=[];guards=[]
  def mem(ctype,count):
   a=(ctype*(count+2))();keep.append(a)
   if ctype is Frame:
    a[0].phase=991;a[count+1].phase=992;guards.append(lambda: (a[0].phase,a[count+1].phase)==(991,992))
   else:
    x,y=(91,92);a[0]=x;a[count+1]=y;guards.append(lambda:(a[0],a[count+1])==(x,y))
   return C.cast(C.byref(a,C.sizeof(ctype)),C.POINTER(ctype))
  selected=mem(C.c_ubyte,n);forbidden=mem(C.c_ubyte,n);syn=mem(C.c_ubyte,len(h));lv=mem(C.c_ubyte,len(l));packed=mem(C.c_ubyte,n);out=mem(C.c_ubyte,n)
  w=Workspace(n,n,selected,forbidden,syn,lv,packed,mem(C.c_uint,n),mem(Frame,n));s=Stats();d=C.c_uint(999)
  if cap is None:status=self.lib.ccv_distance(C.byref(p),budget,rules,C.byref(w),out,C.byref(d),C.byref(s))
  else:status=self.lib.ccv_decide(C.byref(p),cap,budget,rules,C.byref(w),out,C.byref(s))
  self.queries+=1;witness=sum(int(out[q])<<q for q in range(n));ctx=(n,h,l,k,rules,cap,budget,status,d.value,witness)
  self.check(all(g() for g in guards),('guard corruption',ctx))
  self.check(copies==[bytes(a) for a in inputs],('input modified',ctx))
  self.check(s.steps<=budget,('budget exceeded',ctx))
  self.check(all(out[q]<=1 for q in range(n)),('non-bit output',ctx))
  if status==1:
   self.check(good(witness,h,l),('invalid witness',ctx))
   self.check(witness.bit_count()<=(cap if cap is not None else n),('overweight',ctx))
   if cap is None:self.check(d.value==witness.bit_count(),('distance/witness mismatch',ctx))
  elif status in [0,-1]:
   self.check(witness==0,('non-found output not zero',ctx))
   if cap is None:self.check(d.value==0,('non-found distance nonzero',ctx))
  self.prunes=[x+getattr(s,name) for x,name in zip(self.prunes,['pack_prunes','charge_prunes','overlap_prunes'])]
  return status,d.value,witness
 def model(self,n,h,l,k,flags=range(64),caps=True):
  self.models+=1;d=oracle(n,h,l)
  for rules in flags:
   r,actual,e=self.run(n,h,l,k,rules)
   self.check(r==(1 if d is not None else 0) and (d is None or actual==d),('distance oracle',n,h,l,k,rules,d,r,actual,e))
   if caps:
    for cap in range(n+2):
     r,_,e=self.run(n,h,l,k,rules,cap=cap)
     self.check(r==(1 if d is not None and d<=cap else 0),('bounded oracle',n,h,l,k,rules,cap,d,r,e))
  for budget in [0,1,2,3,5]:
   r,actual,e=self.run(n,h,l,k,63,budget=budget)
   self.check(r in [0,1,-1],('unexpected status',r))
   if r==0:self.check(d is None,('budget became EMPTY',n,h,l,k,budget,d))
   if r==1:self.check(actual==d,('budget hit nonminimum',n,h,l,k,budget,d,actual))
def main():
 a=argparse.ArgumentParser();a.add_argument('library');a.add_argument('--quick',action='store_true');args=a.parse_args();t=time.monotonic();v=Harness(args.library);rng=random.Random(0xCC191126)
 # Six-qubit tutorial is dX=3, not full CSS distance (d=2).
 v.model(6,[7,25,42,52],[63],[45,51])
 # Degenerate/no-check, disconnected zero-syndrome prefixes, equality ties,
 # multi-logical, repeated/zero rows, and overlapping candidate repair sets.
 cases=[(2,[3],[1],[0]),(3,[7,7],[1],[6]),(4,[3,12],[1,4],[0]),(4,[],[15],[3,12]),(3,[3,5,6],[1],[]),(2,[3],[3],[3]),(4,[7,11,13],[15],[])]
 for n,h,l,k in cases:v.model(n,h,l,k)
 for n in range(1,4):
  for rows in itertools.product(range(1<<n),repeat=2):
   for logical in range(1<<n):
    k=[x for x in range(1,1<<n) if not any((x&r).bit_count()%2 for r in (*rows,logical))]
    v.model(n,list(rows),[logical],k,flags=range(64) if not args.quick else [0,1,2,4,8,16,32,63],caps=True)
 for index in range(60 if args.quick else 600):
  n=rng.randrange(1,11);h=[rng.randrange(1<<n) for _ in range(rng.randrange(0,9))];l=[rng.randrange(1<<n) for _ in range(rng.randrange(1,5))]
  k=[x for x in range(1,1<<n) if not any((x&r).bit_count()%2 for r in h+l)];rng.shuffle(k);k=k[:rng.randrange(min(len(k),6)+1)]
  v.model(n,h,l,k,flags=range(64) if index<100 else [0,1,2,4,8,16,32,63],caps=index<120)
 # Reject invalid stabilizers and oversized shape before array access.
 r,_,_=v.run(2,[3],[1],[1],63);v.check(r==-2,'unchecked bad stabilizer')
 # Scalar primitive overflow regression at UINT_MAX, ceil without a+b-1.
 v.lib.ccv_ceil_div.argtypes=[C.c_uint,C.c_uint];v.lib.ccv_ceil_div.restype=C.c_uint
 for x in [0,1,2,2147483647,4294967295]:
  for y in [1,2,3,2147483647,4294967295]:v.check(v.lib.ccv_ceil_div(x,y)==-(-x//y),'ceil overflow')
 print(json.dumps(dict(status='PASS',models=v.models,queries=v.queries,assertions=v.assertions,prunes=v.prunes,seconds=time.monotonic()-t,proof_claim=False)))
if __name__=='__main__':main()
