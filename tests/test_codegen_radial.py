#!/usr/bin/env python3
"""Finite radial reconstruction, upper-word proof and rank-qualifier mutants."""
import copy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
from radial import build,generate,CASES
from validate_radial import certify,reconstruct,tensor_pullback,classical_facts,prime_rank
from validate_css import read_code,dot
from audit_radial_smoke import assess
from review_radial_peer import compare
CASES_LIST=json.loads(CASES.read_text())


class Radial(unittest.TestCase):
    def setUp(self):
        self.c=CASES_LIST[0];self.n,self.m=read_code(ROOT/'data/matrices/untiered','LP_352_18_unknown')
    def test_frozen_source(self):
        self.assertEqual([c['s'] for c in CASES_LIST],[11,29,47,79])
        for c in CASES_LIST:
            self.assertEqual((c['r'],c['n'],c['k']),(4,32*c['s'],18))
            self.assertEqual(c['A1'],[[10,10,1,6],[4,7,5,2],[8,10,6,9],[1,6,0,6]])
            self.assertEqual(c['A2'],[[9,5,8,3],[5,4,1,0],[0,4,6,10],[2,8,4,2]])
            self.assertEqual(c['published_estimate'],20 if c['s']==11 else None)
    def test_random_columns_tensor_and_ring_words(self):
        rng=random.Random(193)
        for _ in range(25):
            r,s=rng.randrange(2,4),rng.choice([3,5,7]);c=dict(r=r,s=s,n=2*r*r*s,A1=[[rng.randrange(s) for _ in range(r)] for _ in range(r)],A2=[[rng.randrange(s) for _ in range(r)] for _ in range(r)])
            n,hx,hz=build(c);self.assertEqual([hx,hz],reconstruct(c));self.assertEqual([hx,hz],tensor_pullback(c));self.assertFalse(any(dot(x,z) for x in hx for z in hz))
            X=sum(1<<(j*s+v) for j in [0,r-1] for v in range(s));Z=sum(1<<((i*r)*s+v) for i in [0,r-1] for v in range(s))
            self.assertFalse(any(dot(X,z) for z in hz));self.assertFalse(any(dot(Z,x) for x in hx));self.assertEqual(dot(X,Z),1)
    def test_actual_all(self):
        for c in CASES_LIST:
            n,m=read_code(ROOT/'data/matrices/untiered',f'LP_{c["n"]}_{c["k"]}_unknown');self.assertEqual(certify(c,n,m)['k'],18)
    def test_row_right_convention(self):
        _,hx,_=build(self.c);s=self.c['s'];r=self.c['r']
        self.assertEqual([q for q in range(r*r*s) if (hx[0]>>q)&1],[(k*r)*s+self.c['A1'][0][k] for k in range(r)])
    def test_source_transpose_mutant(self):
        c=copy.deepcopy(self.c);c['A1']=[list(row) for row in zip(*c['A1'])]
        with self.assertRaises(ValueError):certify(c,self.n,self.m)
    def test_commuting_wrong_source_mutant(self):
        c=copy.deepcopy(self.c);c['A1'][0][0]=(c['A1'][0][0]+1)%c['s'];_,hx,hz=build(c)
        self.assertFalse(any(dot(x,z) for x in hx for z in hz))
        with self.assertRaises(ValueError):certify(self.c,self.n,[hx,hz]+self.m[2:])
    def test_entry_mutant(self):
        m=copy.deepcopy(self.m);m[1][0]^=1
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_logical_mutant(self):
        m=copy.deepcopy(self.m);m[2][0]=0
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_four_cycle_mutant(self):
        M=copy.deepcopy(self.c['A1']);M[0]=list(M[1])
        with self.assertRaises(ValueError):classical_facts(M,self.c['s'])
    def test_extra_binary_dependencies_qualifier(self):
        # Full exponent rank and no four-cycles do not force binary rank.
        M=[[2,1,1],[1,1,3],[1,3,2]];self.assertEqual(prime_rank(M,7),3)
        with self.assertRaisesRegex(ValueError,'extra dependencies'):classical_facts(M,7)
    def test_bad_parameters(self):
        for key,value in [('A1',[[0]]),('s',True),('n',1)]:
            c=copy.deepcopy(self.c);c[key]=value
            with self.assertRaises(ValueError):build(c)
            with self.assertRaises(ValueError):reconstruct(c)
        with self.assertRaises(ValueError):classical_facts(self.c['A1'],12)
    def test_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            for c in CASES_LIST:
                stem=generate(c,Path(d))
                for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((Path(d)/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
                with self.assertRaises(FileExistsError):generate(c,Path(d))
    def test_peer90_not_benchmark_cli(self):
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/radial.py'),'--n','90'],capture_output=True);self.assertNotEqual(r.returncode,0)
        self.assertFalse((ROOT/'data/matrices/untiered/LP_90_8_unknown_Hx.txt').exists())
    def test_peer_map_verifies_gf2(self):
        c=dict(r=2,s=3,n=24,A1=[[0,0],[1,0]],A2=[[1,0],[0,0]]);n,hx,hz=build(c)
        result=compare(n,[hx,hz],n,[hx,hz],2,3);self.assertTrue(result['direct_rowspace']);self.assertIsNotNone(result['verified_physical_map'])
    def test_missing_raw_and_source_word(self):
        c=certify(self.c,self.n,self.m);raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n';r=assess(self.c,self.n,self.m,c,dict(maxsat=raw,cc=raw))
        self.assertIsNone(r['engines']['maxsat']['lb']);self.assertEqual(r['numeric_smoke_gate'],'INCOMPLETE');self.assertEqual(r['source_upper_word_gate'],'INCOMPLETE')
    def test_audit_contradiction_mutants(self):
        c=certify(self.c,self.n,self.m)
        for raw in ['c d_lb: 21\nc d_ub: 22\n','c d_lb: 1\nc d_ub: 20\nc witness X: 0\n']:
            with self.assertRaises(ValueError):assess(self.c,self.n,self.m,c,dict(maxsat=raw,cc=raw))
    def test_smoke_selections(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/GH193-NOT-ALLOCATED','--dry-run']
        for flags,count in [([],12),(['--family','LP'],4)]:
            r=subprocess.run(base+flags,capture_output=True,text=True,check=True);self.assertEqual(len(json.loads(r.stdout)),count)
        r=subprocess.run(base+['--family','LP','--stems','LP_90_8_unknown'],capture_output=True);self.assertNotEqual(r.returncode,0)


if __name__=='__main__':unittest.main()
