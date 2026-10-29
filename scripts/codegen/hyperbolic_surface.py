#!/usr/bin/env python3
"""Original bounded triangle-quotient generator, GPL-3.0-or-later (GH-165).

Breuckmann-Terhal 1506.04029v2 III-A/B, IV-A Table I. No code/data copied.
Generators r,R,s,S denote rho, rho^-1, sigma, sigma^-1. The table is the
regular right action on cosets of the trivial subgroup. A row merge only
enforces an inverse relation or a defining relator at a reachable group word.
"""
import argparse
from collections import deque
import json
from pathlib import Path
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('hyperbolic_cases.json').read_text())
ALPHABET='rRsS'


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


def relators(case,reflection=True):
    words=[tuple(ALPHABET.index(c) for c in word) for word in case['words']]
    base=[(0,)*case['r'],(2,)*case['s'],(0,2)*2]
    return base+words+([tuple(g^1 for g in w) for w in words] if reflection else [])


def orbits(table,word):
    labels=[-1]*len(table);cells=[]
    for a in range(len(table)):
        if labels[a]>=0:continue
        cycle=[];b=a
        while labels[b]<0:
            labels[b]=len(cells);cycle.append(b);b=walk(table,b,word)
        if b!=a:raise ValueError('orbit is not a cycle')
        cells.append(cycle)
    return labels,cells


def construction(case):
    if case['status']!='READY_FOR_VALIDATION':raise ValueError('case awaits PI decision')
    table,stats=Quotient(relators(case)).run()
    if len(table)!=2*case['n']:raise ValueError('published quotient order mismatch')
    vertex,vertices=orbits(table,(2,));face,faces=orbits(table,(0,));edge,edges=orbits(table,(0,2))
    if {len(c) for c in vertices}!={case['s']} or {len(c) for c in faces}!={case['r']} or {len(c) for c in edges}!={2}:
        raise ValueError('wrong local rotation orders')
    hx=[sum(1 << e for e in sorted({edge[g] for g in c})) for c in vertices]
    hz=[sum(1 << e for e in sorted({edge[g] for g in c})) for c in faces]
    endpoints=[sorted({vertex[g] for g in c}) for c in edges]
    adjacent_faces=[sorted({face[g] for g in c}) for c in edges]
    if any(len(c)!=2 for c in endpoints+adjacent_faces):raise ValueError('degenerate edge incidence')
    return hx,hz,dict(table=table,vertices=vertices,faces=faces,edges=edges,
                      endpoints=endpoints,adjacent_faces=adjacent_faces,**stats)


def generate(case,out):
    from validate_css import basis
    hx,hz,data=construction(case);n=len(data['edges'])
    k=n-len(basis(hx))-len(basis(hz))
    if (n,k)!=(case['n'],case['k']):raise ValueError('published dimensions mismatch')
    stem=f'HYP_{n}_{k}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError('refusing matrix overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(
            f'# closed hyperbolic {{{case["r"]},{case["s"]}}}; {kind}; arXiv:1506.04029v2 Table {case["table"]} row {case["row"]}\n'+
            ''.join(' '.join(str((row >> j)&1) for j in range(n))+'\n' for row in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    group=ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--n',type=int,choices=[c['n'] for c in CASES if c['status']=='READY_FOR_VALIDATION'])
    group.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--certificates',type=Path,help='new directory for full quotient action certificates')
    args=ap.parse_args()
    if args.certificates:args.certificates.mkdir(parents=True,exist_ok=False)
    for c in CASES:
        if c['status']=='READY_FOR_VALIDATION' and (args.all or c['n']==args.n):
            print(generate(c,args.out),flush=True)
            if args.certificates:
                _,_,data=construction(c)
                (args.certificates/f'HYP_{c["n"]}_{c["k"]}_unknown.json').write_text(json.dumps(data,indent=2)+'\n')


if __name__=='__main__':main()
