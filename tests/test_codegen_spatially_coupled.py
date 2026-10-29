#!/usr/bin/env python3
"""Finite source/column/logical mutants; no solver or distance search."""
import copy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
from spatially_coupled import build,generate,CASES
from validate_spatially_coupled import expected_columns,source_kronecker_columns,certify,physical_components
from validate_css import dot,read_code,validate
from verify_css_witness import verify_witness


def actual_columns(n,hx,hz):
    return [(sum(((w>>q)&1)<<i for i,w in enumerate(hx)),sum(((w>>q)&1)<<i for i,w in enumerate(hz))) for q in range(n)]


class SC(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.c=json.loads(CASES.read_text())[0];cls.stem=f'SC_{cls.c["n"]}_{cls.c["k"]}_unknown';cls.n,cls.m=read_code(ROOT/'data/matrices/untiered',cls.stem)
        cls.cert=json.loads((ROOT/'optimization/experiments/GH-188/raw/certificates'/f'{cls.stem}.json').read_text())

    def test_source_and_first_complete_certificate(self):
        result=certify(self.c,self.cert,self.n,self.m);self.assertEqual(result['k'],88)

    def test_twenty_tiny_random_polynomial_columns_and_commutation(self):
        rng=random.Random(188)
        for _ in range(20):
            L,M=rng.randrange(1,4),rng.randrange(1,4);mem=[rng.randrange(1,4),rng.randrange(1,4)];limit=(mem[0]+1)*(mem[1]+1)
            c=dict(periods=[L,M],memory=mem,partition_A=[[rng.randrange(limit) for _ in range(3)] for _ in range(2)],partition_B=[[rng.randrange(limit) for _ in range(2)]],n=8*L*M)
            cert,hx,hz=build(c)
            self.assertEqual(actual_columns(c['n'],hx,hz),expected_columns(c))
            self.assertFalse(any(dot(a,b) for a in hx for b in hz))

    def test_complement_column_mutant(self):
        m=copy.deepcopy(self.m);m[0][0]^=(1<<(49*4))|(1<<(49*4+1))
        with self.assertRaisesRegex(ValueError,'column'):certify(self.c,self.cert,self.n,m)

    def test_commuting_but_wrong_source_row_basis_mutant(self):
        m=copy.deepcopy(self.m);m[0][0]^=m[0][1]
        validate(self.n,m)
        with self.assertRaises(ValueError):certify(self.c,self.cert,self.n,m)

    def test_source_tensor_order_bijection(self):
        self.assertEqual(source_kronecker_columns(self.c),actual_columns(self.n,*self.m[:2]))

    def test_source_fact_mutant(self):
        c=copy.deepcopy(self.c);c['partition_A'][0][0]^=1
        with self.assertRaisesRegex(ValueError,'Eq89'):certify(c,self.cert,self.n,self.m)

    def test_parameter_hash_mutant(self):
        cert=copy.deepcopy(self.cert);cert['parameter_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'identity'):certify(self.c,cert,self.n,self.m)

    def test_logical_basis_mutant(self):
        m=copy.deepcopy(self.m);m[2][0]=m[2][1]
        with self.assertRaises(ValueError):validate(self.n,m)

    def test_false_stabilizer_upper(self):
        w=self.m[1][0];support=[q for q in range(self.n) if (w>>q)&1]
        with self.assertRaises(ValueError):verify_witness(self.n,self.m,'Z',support)

    def test_two_dimensional_deck_group_is_not_cyclic(self):
        def shift(g,d):return ((g//2+d//2)%2)*2+(g%2+d%2)%2
        for d in [1,2,3]:self.assertEqual(shift(shift(0,d),d),0)
        self.assertNotEqual((1+1)%4,shift(1,1))

    def test_typed_pauli_connectivity(self):
        self.assertEqual(physical_components(4,[15],[3]),1)
        self.assertEqual(physical_components(4,[3,12],[3,12]),2)

    def test_first_case_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            out=Path(d)/'out';certs=Path(d)/'certs';stem=generate(self.c,out,certs)
            for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((out/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
            self.assertEqual((certs/f'{stem}.json').read_bytes(),(ROOT/'optimization/experiments/GH-188/raw/certificates'/f'{stem}.json').read_bytes())
            with self.assertRaises(FileExistsError):generate(self.c,out,certs)

    def test_cli_exact_frozen_selection_and_unchanged_default(self):
        runner=ROOT/'scripts/codegen/smoke_untiered.py'
        r=subprocess.run([sys.executable,str(runner),'--family','SC','--cpu','54','--dry-run','--out','/tmp/not-allocated'],capture_output=True,text=True,check=True)
        commands=json.loads(r.stdout);self.assertEqual(len(commands),5);self.assertTrue(all('-engine=cc' not in c for c in commands))
        r=subprocess.run([sys.executable,str(runner),'--cpu','54','--dry-run','--out','/tmp/not-allocated'],capture_output=True,text=True,check=True);self.assertEqual(len(json.loads(r.stdout)),12)
        r=subprocess.run([sys.executable,str(runner),'--family','SC','--stems','HGP_13_1_unknown','--cpu','54','--dry-run','--out','/tmp/not-allocated'],capture_output=True,text=True);self.assertNotEqual(r.returncode,0)


if __name__=='__main__':unittest.main()
