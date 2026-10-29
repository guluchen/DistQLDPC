#!/usr/bin/env python3
"""Three-axis finite construction and retained-bound mutants; no solver."""
import copy
import itertools
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
from itb import build,generate,CASES
from validate_itb import certify,reconstruct,tensor_source,support
from validate_css import read_code,dot,basis
from audit_itb_smoke import assess
CASES_LIST=json.loads(CASES.read_text())

class ITB(unittest.TestCase):
    def setUp(self):
        self.c=CASES_LIST[0];self.n,self.m=read_code(ROOT/'data/matrices/untiered','ITB_54_14_unknown')
    def test_frozen_selection(self):
        self.assertEqual([c['L'] for c in CASES_LIST],[3,4,5,7,9,11]);self.assertEqual([c['n'] for c in CASES_LIST],[54,128,250,686,1458,2662])
        self.assertEqual([c['expected_k'] for c in CASES_LIST],[14,20,None,None,None,None]);self.assertEqual([c['published_exact'] for c in CASES_LIST],[5,8,None,None,None,None])
        for c in CASES_LIST:self.assertEqual(c['A'],[[0,0,0],[1,0,0],[0,1,0],[0,0,1]]);self.assertEqual(c['B'],[[0,0,0],[c['L']-1,0,0],[0,c['L']-1,0],[0,0,c['L']-1]])
    def test_random_tiny_general_columns(self):
        rng=random.Random(197)
        for _ in range(30):
            L=rng.randrange(2,4);grid=list(itertools.product(range(L),repeat=3));c=dict(L=L,n=2*L**3,expected_k=None)
            for key in ['A','B']:c[key]=[list(e) for e in rng.sample(grid,rng.randrange(1,min(6,len(grid))))]
            hx,hz=reconstruct(c);self.assertFalse(any(dot(a,b) for a in hx for b in hz));k=c['n']-len(basis(hx))-len(basis(hz))
            if k:self.assertEqual(build(c),(c['n'],hx,hz,k))
            else:
                with self.assertRaises(ValueError):build(c)
    def test_tiny_separate_kronecker(self):
        for L in [2,3,4,5]:
            c=copy.deepcopy(self.c);c.update(L=L,n=2*L**3,expected_k=None,B=[[0,0,0],[L-1,0,0],[0,L-1,0],[0,0,L-1]])
            n,hx,hz,k=build(c);self.assertEqual([hx,hz],reconstruct(c));self.assertEqual([hx,hz],tensor_source(c));self.assertEqual(hx,hz)
    def test_source_right_shift_literal(self):
        self.assertEqual(support(self.m[0][0]),[0,1,3,9,27,29,33,45])
        self.assertEqual([r for r,w in enumerate(self.m[0]) if w&1],[0,2,6,18])
    def test_actual_all(self):
        results=json.loads((ROOT/'optimization/experiments/GH-197/raw/construction.json').read_text())
        for c,r in zip(CASES_LIST,results):
            n,m=read_code(ROOT/'data/matrices/untiered',r['stem']);self.assertEqual(certify(c,n,m),r)
    def test_entry_mutant(self):
        m=copy.deepcopy(self.m);m[0][0]^=1
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_logical_mutant(self):
        m=copy.deepcopy(self.m);m[2][0]=0
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_commuting_wrong_source_mutant(self):
        c=copy.deepcopy(self.c);c['B']=copy.deepcopy(c['A']);c['expected_k']=None;n,hx,hz,k=build(c)
        self.assertFalse(any(dot(x,z) for x in hx for z in hz))
        with self.assertRaises(ValueError):certify(self.c,n,[hx,hz]+self.m[2:])
    def test_source_k_mismatch(self):
        c=copy.deepcopy(self.c);c['expected_k']=13
        with self.assertRaises(ValueError):build(c)
        with self.assertRaises(ValueError):certify(c,self.n,self.m)
    def test_invalid_support(self):
        for p in [[0,0,0],[3,0,0]]:
            c=copy.deepcopy(self.c);c['A'].append(p)
            with self.assertRaises(ValueError):build(c)
            with self.assertRaises(ValueError):reconstruct(c)
    def test_wrong_inverse_partner(self):
        c=copy.deepcopy(self.c);c['B'][1]=[1,0,0]
        with self.assertRaises(ValueError):certify(c,self.n,self.m)
    def test_regenerate_all_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            for c in CASES_LIST:
                stem=generate(c,Path(d))
                for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((Path(d)/(stem+'_'+kind+'.txt')).read_bytes(),(ROOT/'data/matrices/untiered'/(stem+'_'+kind+'.txt')).read_bytes())
                with self.assertRaises(FileExistsError):generate(c,Path(d))
    def test_missing_source_exact_fields(self):
        con=certify(self.c,self.n,self.m);raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n';r=assess(self.c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
        self.assertIsNone(r['engines']['maxsat']['lb']);self.assertIsNone(r['engines']['maxsat']['ub']);self.assertEqual(r['numeric_smoke_gate'],'INCOMPLETE')
    def test_original_no_source_distance_transfer(self):
        c=CASES_LIST[2];n,m=read_code(ROOT/'data/matrices/untiered','ITB_250_26_unknown');con=certify(c,n,m);raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n';r=assess(c,n,m,con,dict(maxsat=raw,cc=raw))
        self.assertEqual(r['reference_range'],[None,None]);self.assertIsNone(r['engines']['maxsat']['lb']);self.assertEqual(r['source_upper_word_gate'],'NOT_APPLICABLE')
    def test_source_exact_contradiction_mutants(self):
        con=certify(self.c,self.n,self.m)
        for raw in ['c d_lb: 6\nc d_ub: 8\n','c d_lb: 1\nc d_ub: 4\n']:
            with self.assertRaises(ValueError):assess(self.c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
    def test_actual_invalid_word_mutant(self):
        con=certify(self.c,self.n,self.m);raw='c d_lb: 1\nc d_ub: 5\nc witness X: 0\n'
        with self.assertRaises(ValueError):assess(self.c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
    def test_exact_requires_materialized_minimum(self):
        con=certify(self.c,self.n,self.m);w=max(self.m[3],key=lambda w:len(support(w)));self.assertGreater(len(support(w)),5)
        con['independently_checked_uppers']=[dict(half='X',weight=len(support(w)),support=support(w))]
        raw='c d_lb: 5\nc d_ub: 5\no 5\n'
        with self.assertRaises(ValueError):assess(self.c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
    def test_cli_selection(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/GH197-NOT-ALLOCATED','--dry-run']
        for flags,count in [([],12),(['--family','ITB'],6)]:self.assertEqual(len(json.loads(subprocess.run(base+flags,capture_output=True,text=True,check=True).stdout)),count)
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/itb.py'),'--L','999'],capture_output=True);self.assertNotEqual(r.returncode,0)

if __name__=='__main__':unittest.main()
