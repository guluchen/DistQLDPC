#!/usr/bin/env python3
"""Finite construction/audit mutants; no solver experiments."""
import copy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
from reference_gb import build,generate,CASES
from validate_reference_gb import certify,reconstruct
from validate_css import read_code
from audit_reference_gb_smoke import assess

CASES_LIST=json.loads(CASES.read_text())


class ReferenceGB(unittest.TestCase):
    def setUp(self):
        self.c=CASES_LIST[0];self.n,self.m=read_code(ROOT/'data/matrices/untiered','GB_254_28_unknown')
    def test_frozen_source(self):
        self.assertEqual([(c['id'],c['l'],c['a'],c['b']) for c in CASES_LIST],[('A1',127,[0,15,20,28,66],[0,58,59,100,121]),('A5',90,[0,28,80,89],[0,2,21,25])])
    def test_first_column(self):
        for c in CASES_LIST:
            n,hx,hz=build(c)
            self.assertEqual([r for r,w in enumerate(hx) if w&1],c['a'])
            self.assertEqual([r for r,w in enumerate(hz) if w&1],sorted((-e)%c['l'] for e in c['b']))
    def test_random_columns(self):
        rng=random.Random(191)
        for _ in range(50):
            l=rng.randrange(2,10);c={'l':l,'n':2*l,'a':rng.sample(range(l),rng.randrange(1,l+1)),'b':rng.sample(range(l),rng.randrange(1,l+1))}
            _,hx,hz=build(c);self.assertEqual([hx,hz],reconstruct(c))
    def test_actual_both(self):
        for c in CASES_LIST:
            n,m=read_code(ROOT/'data/matrices/untiered',f'GB_{c["n"]}_{c["k"]}_unknown');self.assertEqual(certify(c,n,m)['k'],c['k'])
    def test_source_mutant(self):
        c=copy.deepcopy(self.c);c['a'][1]+=1
        with self.assertRaises(ValueError):certify(c,self.n,self.m)
    def test_column_mutant(self):
        m=copy.deepcopy(self.m);m[0][0]^=1
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_commuting_wrong_source(self):
        m=copy.deepcopy(self.m);m[0],m[1]=m[1],m[0];m[2],m[3]=m[3],m[2]
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_logical_mutant(self):
        m=copy.deepcopy(self.m);m[2][0]=0
        with self.assertRaises(ValueError):certify(self.c,self.n,m)
    def test_duplicate_support(self):
        c=copy.deepcopy(self.c);c['a'].append(0)
        with self.assertRaises(ValueError):build(c)
        with self.assertRaises(ValueError):reconstruct(c)
    def test_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            for c in CASES_LIST:
                stem=generate(c,Path(tmp))
                for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((Path(tmp)/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
                with self.assertRaises(FileExistsError):generate(c,Path(tmp))
    def test_audit_preserves_missing_numbers(self):
        construction=certify(self.c,self.n,self.m)
        raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n'
        r=assess(self.c,self.n,self.m,construction,dict(maxsat=raw,cc=raw))
        self.assertIsNone(r['engines']['maxsat']['lb']);self.assertEqual(r['numeric_smoke_gate'],'INCOMPLETE')
    def test_audit_lower_and_invalid_witness_mutants(self):
        construction=certify(self.c,self.n,self.m)
        for raw in ['c d_lb: 1\nc d_ub: 13\n','c d_lb: 21\nc d_ub: 22\n','c d_lb: 1\nc d_ub: 20\nc witness X: 0\n']:
            with self.assertRaises(ValueError):assess(self.c,self.n,self.m,construction,dict(maxsat=raw,cc=raw))
    def test_smoke_selections(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/GH191-NOT-ALLOCATED','--dry-run']
        for flags,count in [([],12),(['--family','GB'],2)]:
            r=subprocess.run(base+flags,capture_output=True,text=True,check=True);self.assertEqual(len(json.loads(r.stdout)),count)
        r=subprocess.run(base+['--family','no-such-family'],capture_output=True);self.assertNotEqual(r.returncode,0)


if __name__=='__main__':unittest.main()
