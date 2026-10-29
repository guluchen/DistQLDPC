#!/usr/bin/env python3
"""Own bounded relation enumerator reused from GH165; GPL-3.0-or-later.
No third-party group or distance implementation.
"""
import time

class Quotient:
    def __init__(self,relators,max_states=100000,seconds=5):
        if max_states<1 or seconds<=0:raise ValueError('positive enumeration limits required')
        self.table=[[-1]*4];self.parent=[0];self.relators=relators
        self.max_states=max_states;self.deadline=time.monotonic()+seconds

    def root(self,x):
        while self.parent[x]!=x:
            self.parent[x]=self.parent[self.parent[x]];x=self.parent[x]
        return x

    def merge(self,a,b):
        pending=[(a,b)]
        while pending:
            a,b=map(self.root,pending.pop())
            if a==b:continue
            if a>b:a,b=b,a
            self.parent[b]=a
            for g in range(4):
                x,y=self.table[a][g],self.table[b][g]
                if x<0:self.table[a][g]=y
                elif y>=0:pending.append((x,y))

    def define(self,a,g,b):
        for u,h,v in ((a,g,b),(b,g^1,a)):
            u,v=self.root(u),self.root(v)
            if self.table[u][h]<0:self.table[u][h]=v
            else:self.merge(self.table[u][h],v)

    def new(self):
        if len(self.table)>=self.max_states or time.monotonic()>self.deadline:
            raise RuntimeError('finite-quotient enumeration limit; prepare server package')
        k=len(self.table);self.table.append([-1]*4);self.parent.append(k);return k

    def scan(self,start,word):
        start=self.root(start);left=start;i=0
        while i<len(word):
            target=self.table[self.root(left)][word[i]]
            if target<0:break
            left=self.root(target);i+=1
        if i==len(word):self.merge(left,start);return
        right=start;j=len(word)-1
        while j>=i:
            target=self.table[self.root(right)][word[j]^1]
            if target<0:break
            right=self.root(target);j-=1
        if j<i:self.merge(left,right);return
        while i<j:
            target=self.new();self.define(left,word[i],target)
            left=self.root(target);i+=1
        self.define(left,word[i],right)

    def run(self):
        cursor=0
        while cursor<len(self.table):
            if time.monotonic()>self.deadline:raise RuntimeError('enumeration time limit')
            if self.root(cursor)==cursor:
                for word in self.relators:self.scan(cursor,word)
            cursor+=1
        # Canonical BFS labels make output independent of intermediate row IDs.
        identity=self.root(0);order=[identity];index={identity:0}
        for u in order:
            for x in self.table[u]:
                if x<0:raise ValueError('incomplete Cayley table')
                v=self.root(x)
                if v not in index:index[v]=len(order);order.append(v)
        table=[[index[self.root(x)] for x in self.table[u]] for u in order]
        verify_table(table,self.relators)
        return table,dict(allocated_states=len(self.table),quotient_order=len(table))


def walk(table,start,word):
    for g in word:start=table[start][g]
    return start


def verify_table(table,relators):
    for a,row in enumerate(table):
        if len(row)!=4 or any(not 0<=x<len(table) for x in row):raise ValueError('invalid Cayley row')
        if any(table[row[g]][g^1]!=a for g in range(4)):raise ValueError('inverse relation failed')
        if any(walk(table,a,word)!=a for word in relators):raise ValueError('defining relator failed')

