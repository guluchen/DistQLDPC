#!/usr/bin/env python3
"""Source-dimension hold regression checks; algebra only, no distance solver."""
import importlib.util
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import mm
from validate_css import read_code,validate,dot
spec=importlib.util.spec_from_file_location('source648',ROOT/'optimization/experiments/GH-200/raw/check_source648.py')
independent=importlib.util.module_from_spec(spec);spec.loader.exec_module(independent)
Q=ROOT/'data/matrices/untiered/quarantine/GH-200'


class MMHold(unittest.TestCase):
    def setUp(self):self.cases=json.loads(mm.CASES.read_text())

    def test_source_case_stays_frozen(self):
        c=self.cases[3]
        self.assertEqual((c['n'],c['k'],c['dims']),(648,18,[3,9,2,2]))
        self.assertEqual(c['polynomials'],['w^2*x^4*y*z+w^2*x^2*y+w*x^5*y*z',
            'w^2*x*z+w*x^7*y*z+w*x^5*y*z','w*x^5*y*z+x^8*y+y','w^2*x^8*z+w*x^8*y*z+x^5'])
        self.assertEqual([c['n'] for c in self.cases],[144,324,432,648,972])

    def test_independent_numeric_literal_matches_every_entry(self):
        hx,hz=independent.literal()
        for kind,rows in [('Hx',hx),('Hz',hz)]:
            self.assertEqual(independent.read_actual(Q/('MM_648_18_unknown_'+kind+'.txt')),rows)
        c=self.cases[3];n,xx,zz=mm.checks(c['dims'],c['polynomials'])
        self.assertEqual((n,len(hx),len(hz)),(648,432,432))
        self.assertEqual(xx,[sum(v<<i for i,v in enumerate(r)) for r in hx])
        self.assertEqual(zz,[sum(v<<i for i,v in enumerate(r)) for r in hz])

    def test_generic_rank_and_logicals_expose_source_dimension(self):
        observed=[]
        for c in self.cases:
            n,m=read_code(Q,'MM_%d_%d_unknown'%(c['n'],c['k']));r=validate(n,m)
            observed.append(r['k'])
        self.assertEqual(observed,[6,12,12,12,24])
        receipt=json.loads((ROOT/'optimization/experiments/GH-200/raw/source648-independent.json').read_text())
        self.assertEqual(receipt['independent_dense_ranks'],[318,318])
        self.assertEqual(receipt['source_dimension_gate'],'FAIL')

    def test_generation_refuses_wrong_source_k_before_writing(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp)/'new'
            with self.assertRaisesRegex(ValueError,'SOURCE_DIMENSION_HOLD'):
                mm.generate(self.cases[3],out)
            self.assertFalse(out.exists())

    def test_no_parameter_repair_by_cli(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp)/'new'
            r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/mm.py'),'--n','648','--out',str(out)],capture_output=True,text=True)
            self.assertNotEqual(r.returncode,0);self.assertIn('source k=18, reconstructed k=12',r.stderr)
            self.assertFalse(out.exists())

    def test_wrong_k_mutant_for_anchor_also_refused(self):
        c=dict(self.cases[0],k=12)
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(ValueError,'SOURCE_DIMENSION_HOLD'):mm.generate(c,Path(temp))
            self.assertEqual(list(Path(temp).iterdir()),[])

    def test_polynomial_ring_reduction(self):
        self.assertEqual(mm.support('w+w',[3,2,2,2]),[])
        self.assertEqual(mm.support('x^10+1',[3,9,2,2]),[(0,0,0,0),(0,1,0,0)])
        for p in ['w^','u','w**x','w+','-x']:
            with self.assertRaises(ValueError):mm.support(p,[3,9,2,2])

    def test_thirty_tiny_commuting_random_cases(self):
        rng=random.Random(200)
        for _ in range(30):
            dims=[rng.randrange(1,4) for _ in range(4)]
            polys=[]
            for j in range(4):
                terms=[]
                for t in range(3):
                    terms.append('*'.join(v+'^'+str(rng.randrange(4)) for v in 'wxyz'))
                polys.append('+'.join(terms))
            n,hx,hz=mm.checks(dims,polys)
            self.assertFalse(any(dot(a,b) for a in hx for b in hz))

    def test_data_error_mutant_is_detected(self):
        n,m=read_code(Q,'MM_648_18_unknown');m[0][0]^=1
        with self.assertRaises(ValueError):validate(n,m)

    def test_bad_complex_inputs(self):
        with self.assertRaises(ValueError):mm.boundary([3,2,2,2],['w'],2)
        with self.assertRaises(ValueError):mm.boundary([3,2,2,2],['w']*4,5)
        with self.assertRaises(ValueError):mm.support('w',[0,2,2,2])


if __name__=='__main__':unittest.main()
