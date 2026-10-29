import time
class Enum:
 def __init__(self,relators,cap=20000,seconds=10):
  self.t=[[-1]*4];self.p=[0];self.rel=relators;self.cap=cap;self.end=time.monotonic()+seconds;self.changes=0
 def find(self,x):
  while self.p[x]!=x:self.p[x]=self.p[self.p[x]];x=self.p[x]
  return x
 def merge(self,a,b):
  todo=[(a,b)]
  while todo:
   a,b=map(self.find,todo.pop())
   if a==b:continue
   if a>b:a,b=b,a
   self.p[b]=a;self.changes+=1
   for g in range(4):
    x,y=self.t[a][g],self.t[b][g]
    if x<0:self.t[a][g]=y
    elif y>=0:todo.append((x,y))
 def define(self,a,g,b):
  for u,h,v in ((a,g,b),(b,g^1,a)):
   u,v=self.find(u),self.find(v)
   if self.t[u][h]<0:self.t[u][h]=v;self.changes+=1
   else:self.merge(self.t[u][h],v)
 def new(self):
  if len(self.t)>=self.cap or time.monotonic()>self.end:raise RuntimeError(('pilot cap',len(self.t)))
  k=len(self.t);self.t.append([-1]*4);self.p.append(k);return k
 def scan(self,a,w,fill=False):
  a=self.find(a);left=a;i=0
  while i<len(w):
   nxt=self.t[self.find(left)][w[i]]
   if nxt<0:break
   left=self.find(nxt);i+=1
  if i==len(w):self.merge(left,a);return
  right=a;j=len(w)-1
  while j>=i:
   nxt=self.t[self.find(right)][w[j]^1]
   if nxt<0:break
   right=self.find(nxt);j-=1
  if j<i:self.merge(left,right)
  elif j==i:self.define(left,w[i],right)
  elif fill:
   while i<j:
    nxt=self.new();self.define(left,w[i],nxt);left=self.find(nxt);i+=1
   self.define(left,w[i],right)
 def run(self):
  cursor=0
  while cursor<len(self.t):
   if time.monotonic()>self.end:raise RuntimeError(('pilot time',len(self.t)))
   if self.find(cursor)==cursor:
    for w in self.rel:self.scan(cursor,w,True)
   cursor+=1
  # complete table at live nodes, relators are scanned at every node
  live=[i for i in range(len(self.t)) if self.find(i)==i];idx={v:i for i,v in enumerate(live)}
  table=[[idx[self.find(x)] if x>=0 else -1 for x in self.t[i]] for i in live]
  if any(-1 in r for r in table):raise RuntimeError('incomplete table')
  for a in range(len(table)):
   for w in self.rel:
    v=a
    for g in w:v=table[v][g]
    assert v==a
   for g in range(4):assert table[table[a][g]][g^1]==a
  return table,len(self.t)
