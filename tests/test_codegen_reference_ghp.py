#!/usr/bin/env python3
"""QC GHP finite construction and audit mutants; no solver experiments."""
import copy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
from reference_ghp import build,generate,CASES
from validate_reference_ghp import certify,reconstruct,layer_major
from validate_css import read_code,dot
from audit_reference_ghp_smoke import assess
CASES_LIST=json.loads(CASES.read_text())


class ReferenceGHP(unittest.TestCase):
    def setUp(self):
        self.c=CASES_LIST[0];self.n,self.m=read_code(ROOT/'data/matrices/untiered','LP_882_24_unknown')
    def test_frozen_source(self):
        c,d=CASES_LIST
        self.assertEqual((c['id'],c['l'],c['m'],c['n'],c['k'],c['b'],c['published_lb'],c['published_ub']),('B1',63,7,882,24,[0,1,6],18,24))
        for i in range(7):
            for j in range(7):self.assertEqual(c['A'][i][j],{0:27,1:54,2:0}.get((i-j)%7))
        self.assertEqual((d['id'],d['l'],d['m'],d['n'],d['k'],d['b'],d['published_lb'],d['published_ub']),('B3',127,5,1270,28,[0,1,7],16,46))
        self.assertEqual(d['A'],[[0,None,51,52,None],[None,0,None,111,20],[0,None,98,None,122],[0,80,None,119,None],[None,0,5,None,106]])
    def test_random_coordinate_and_commutation(self):
        rng=random.Random(192)
        for _ in range(30):
            l,m=rng.randrange(2,8),rng.randrange(1,5)
            c=dict(l=l,m=m,n=2*l*m,A=[[rng.choice([None]+list(range(l))) for j in range(m)] for i in range(m)],b=rng.sample(range(l),rng.randrange(1,l+1)))
            _,hx,hz=build(c);self.assertEqual([hx,hz],reconstruct(c));self.assertEqual([hx,hz],layer_major(c));self.assertFalse(any(dot(x,z) for x in hx for z in hz))
    def test_actual_both(self):
        for c in CASES_LIST:
            n,m=read_code(ROOT/'data/matrices/untiered',f'LP_{c["n"]}_{c["k"]}_unknown');self.assertEqual(certify(c,n,m)['k'],c['k'])
    def test_zero_versus_constant_mutant(self):
        c=copy.deepcopy(self.c);c['A'][0][5]=None
        with self.assertRaises(ValueError):certify(c,self.n,self.m)
    def test_transpose_source_mutant(self):
        c=copy.deepcopy(self.c);c['A']=[list(row) for row in zip(*c['A'])]
        with self.assertRaises(ValueError):certify(c,self.n,self.m)
    def test_entry_mutant(self):
        m=copy.deepcopy(self.m);m[1][0]^=1
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_commuting_wrong_source(self):
        c=copy.deepcopy(self.c);c['A'][0][0]+=1;_,hx,hz=build(c)
        self.assertFalse(any(dot(x,z) for x in hx for z in hz))
        with self.assertRaises(ValueError):certify(self.c,self.n,[hx,hz]+self.m[2:])
    def test_logical_mutant(self):
        m=copy.deepcopy(self.m);m[3][0]=0
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_bad_parameters(self):
        for key,value in [('b',[0,0,1]),('A',[[0]]),('n',1),('l',True)]:
            c=copy.deepcopy(self.c);c[key]=value
            with self.assertRaises(ValueError):build(c)
            with self.assertRaises(ValueError):reconstruct(c)
    def test_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            for c in CASES_LIST:
                stem=generate(c,Path(tmp))
                for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((Path(tmp)/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
                with self.assertRaises(FileExistsError):generate(c,Path(tmp))
    def test_unknown_cli(self):
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/reference_ghp.py'),'--n','1'],capture_output=True);self.assertNotEqual(r.returncode,0)
    def test_audit_preserves_missing(self):
        c=certify(self.c,self.n,self.m);raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n';r=assess(self.c,self.n,self.m,c,dict(maxsat=raw,cc=raw))
        self.assertIsNone(r['engines']['maxsat']['lb']);self.assertIsNone(r['engines']['maxsat']['ub']);self.assertEqual(r['numeric_smoke_gate'],'INCOMPLETE');self.assertEqual(r['source_upper_word_gate'],'PASS')
    def test_audit_contradiction_mutants(self):
        c=certify(self.c,self.n,self.m)
        for raw in ['c d_lb: 1\nc d_ub: 17\n','c d_lb: 25\nc d_ub: 26\n','c d_lb: 1\nc d_ub: 24\nc witness X: 0\n']:
            with self.assertRaises(ValueError):assess(self.c,self.n,self.m,c,dict(maxsat=raw,cc=raw))
    def test_smoke_selection(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/GH192-NOT-ALLOCATED','--dry-run']
        for flags,count in [([],12),(['--family','LP'],2)]:
            r=subprocess.run(base+flags,capture_output=True,text=True,check=True);self.assertEqual(len(json.loads(r.stdout)),count)
        r=subprocess.run(base+['--family','LP','--stems','LP_1_1_unknown'],capture_output=True);self.assertNotEqual(r.returncode,0)


if __name__=='__main__':unittest.main()
