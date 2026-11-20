#!/usr/bin/env python3
import ctypes as C,json
from test_ccv import Problem,Frame,Workspace,Stats,arr,Harness
v=Harness('./libccv.so');n=6
keep=[(C.c_ubyte*max(n,count))() for count in [n,n,4,1,n,n]];undo=(C.c_uint*n)();frames=(Frame*n)();w=Workspace(n,n,*keep[:5],undo,frames)
h=arr([7,25,42,52],n);l=arr([63],n);k=arr([45,51],n);p=Problem(n,4,1,2,h,l,k);out=keep[5];s=Stats();distance=C.c_uint(0)
for cap,budget,expected in [(6,0,-1),(3,100000,1),(1,100000,0),(2,100000,0),(4,1,-1),(6,100000,1),(0,0,0)]:
 r=v.lib.ccv_decide(C.byref(p),cap,budget,63,C.byref(w),out,C.byref(s));assert r==expected,(cap,budget,r)
 if r!=1:assert not any(out)
# Every INVALID here has valid argument objects/pointers; no invalid-pointer test.
count=0
for field,new in [('n',0),('n',2147483647),('logical_rows',0),('checks',4294967295)]:
 old=getattr(p,field);setattr(p,field,new)
 r=v.lib.ccv_decide(C.byref(p),3,1000,63,C.byref(w),out,C.byref(s));assert r==-2,(field,new,r)
 setattr(p,field,old);count+=1
for a in [h,l,k]:
 old=a[0];a[0]=2;r=v.lib.ccv_decide(C.byref(p),3,1000,63,C.byref(w),out,C.byref(s));assert r==-2;a[0]=old;count+=1
for field in ['capacity','frame_capacity']:
 setattr(w,field,n-1);r=v.lib.ccv_decide(C.byref(p),3,1000,63,C.byref(w),out,C.byref(s));assert r==-2;setattr(w,field,n);count+=1
assert v.lib.ccv_decide(C.byref(p),3,1000,64,C.byref(w),out,C.byref(s))==-2;count+=1
# Explicitly aliased read-only H=L arrays; separate writable arrays stay disjoint.
a=arr([63],n);p=Problem(n,1,1,0,a,a,arr([],n))
assert v.lib.ccv_distance(C.byref(p),100000,63,C.byref(w),out,C.byref(distance),C.byref(s))==0
assert distance.value==0 and not any(out)
print(json.dumps(dict(status='PASS',invalid_cases=count,workspace_reuse=7,readonly_alias_case=1)))
