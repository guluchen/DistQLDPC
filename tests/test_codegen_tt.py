#!/usr/bin/env python3
"""Static tricycle source/chain/logical/actual-word guards, no solver."""
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
from tt import build,generate,CASES
from validate_tt import certify,reconstruct,tensor_source,check_meta,support
from validate_css import read_code,dot
from audit_tt_smoke import assess
CASES_LIST=json.loads(CASES.read_text())

class TT(unittest.TestCase):
    def setUp(self):
        self.c=CASES_LIST[0];self.n,self.m=read_code(ROOT/'data/matrices/untiered','TT_72_6_unknown')
    def test_frozen_source(self):
        self.assertEqual([(c['n'],c['k'],c['published_exact'],c['published_ub']) for c in CASES_LIST],[(72,6,6,6),(588,9,None,14),(648,12,None,14),(735,18,None,14),(840,9,None,16),(1029,18,None,16)])
        self.assertEqual([c['dims'] for c in CASES_LIST],[[4,3,2],[7,7,4],[6,6,6],[7,7,5],[8,7,5],[7,7,7]])
        self.assertEqual([c['published_X_upper'] for c in CASES_LIST],[12,73,72,80,None,None]);self.assertEqual(self.c['published_X_exact'],12)
        self.assertEqual(self.c['A'],[[0,0,0],[0,1,0],[1,2,0]])
        self.assertEqual(CASES_LIST[-1]['C'],[[0,0,0],[4,6,0],[5,4,6]])
    def test_random_tiny_columns_tensor_chain(self):
        rng=random.Random(198)
        for _ in range(30):
            dims=[rng.randrange(2,5) for _ in range(3)];grid=list(itertools.product(*(range(d) for d in dims)));c=dict(dims=dims,n=3*len(grid))
            for key in ['A','B','C']:c[key]=[list(e) for e in rng.sample(grid,rng.randrange(1,5))]
            n,hx,hz=build(c);r=reconstruct(c);self.assertEqual([hx,hz],list(r[:2]));self.assertEqual(r,tensor_source(c));self.assertFalse(any(dot(a,b) for a in hx for b in hz));check_meta(hz,r[2])
    def test_literal_first_column_and_transpose(self):
        self.assertEqual(support(self.m[0][0]),[0,4,20,24,29,38,48,64,69])
        self.assertEqual([r for r,w in enumerate(self.m[0]) if w&1],[0,2,10])
        self.assertEqual(support(self.m[1][0]),[24,35,38,48,51,64])
    def test_actual_all(self):
        rows=json.loads((ROOT/'optimization/experiments/GH-198/raw/construction.json').read_text())
        for c,r in zip(CASES_LIST,rows):
            n,m=read_code(ROOT/'data/matrices/untiered',r['stem']);self.assertEqual(certify(c,n,m),r)
    def test_entry_mutant(self):
        m=copy.deepcopy(self.m);m[0][0]^=1
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_logical_mutant(self):
        m=copy.deepcopy(self.m);m[2][0]=0
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_commuting_wrong_source(self):
        c=copy.deepcopy(self.c);c['B'][1]=[0,2,1];n,hx,hz=build(c);self.assertFalse(any(dot(x,z) for x in hx for z in hz))
        with self.assertRaises(ValueError):certify(self.c,n,[hx,hz]+self.m[2:])
    def test_source_k_mutant(self):
        c=copy.deepcopy(self.c);c['k']=7
        with self.assertRaises(ValueError):certify(c,self.n,self.m)
    def test_invalid_support(self):
        for point in [[0,0,0],[4,0,0]]:
            c=copy.deepcopy(self.c);c['A'].append(point)
            with self.assertRaises(ValueError):build(c)
            with self.assertRaises(ValueError):reconstruct(c)
    def test_metacheck_mutant(self):
        hx,hz,mz=reconstruct(self.c);mz[0]^=1
        with self.assertRaises(ValueError):check_meta(hz,mz)
    def test_asymmetric_not_assumed_dual(self):
        r=certify(self.c,self.n,self.m);self.assertEqual((r['rank_Hx'],r['rank_Hz']),(22,44));self.assertFalse(r['assumed_XZ_metric_map'])
    def test_regenerate_all_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            for c in CASES_LIST:
                stem=generate(c,Path(d))
                for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((Path(d)/(stem+'_'+kind+'.txt')).read_bytes(),(ROOT/'data/matrices/untiered'/(stem+'_'+kind+'.txt')).read_bytes())
                with self.assertRaises(FileExistsError):generate(c,Path(d))
    def test_missing_numbers_not_source_filled(self):
        con=certify(self.c,self.n,self.m);raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n';r=assess(self.c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
        self.assertIsNone(r['engines']['maxsat']['lb']);self.assertIsNone(r['engines']['maxsat']['ub']);self.assertEqual(r['numeric_smoke_gate'],'INCOMPLETE');self.assertEqual(r['source_upper_word_gate'],'INCOMPLETE');self.assertEqual(r['actual_verified_half_uppers'],dict(X=14,Z=8))
    def test_source_exact_half_not_global_only(self):
        c=copy.deepcopy(self.c);c['published_X_exact']=15;con=certify(self.c,self.n,self.m);raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n'
        with self.assertRaises(ValueError):assess(c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
        with self.assertRaises(ValueError):certify(c,self.n,self.m)
    def test_source_overall_contradiction_mutants(self):
        con=certify(self.c,self.n,self.m)
        for raw in ['c d_lb: 7\nc d_ub: 8\n','c d_lb: 1\nc d_ub: 5\n']:
            with self.assertRaises(ValueError):assess(self.c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
    def test_invalid_word(self):
        con=certify(self.c,self.n,self.m);raw='c d_lb: 1\nc d_ub: 6\nc witness Z: 0\n'
        with self.assertRaises(ValueError):assess(self.c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
    def test_exact_requires_materialized_minimum(self):
        con=certify(self.c,self.n,self.m);raw='c d_lb: 6\nc d_ub: 6\no 6\n'
        with self.assertRaises(ValueError):assess(self.c,self.n,self.m,con,dict(maxsat=raw,cc=raw))
    def test_cli_selection(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/GH198-NOT-ALLOCATED','--dry-run']
        for flags,count in [([],12),(['--family','TT'],6)]:self.assertEqual(len(json.loads(subprocess.run(base+flags,capture_output=True,text=True,check=True).stdout)),count)
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/tt.py'),'--n','1'],capture_output=True);self.assertNotEqual(r.returncode,0)

if __name__=='__main__':unittest.main()
