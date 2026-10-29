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
from lower_reference_gb import build,generate,CASES
from validate_lower_reference_gb import certify,reconstruct,gcd
from validate_css import read_code,dot,basis
from smoke_untiered import parse_claim
from audit_lower_reference_gb_smoke import assess

CASES_LIST=json.loads(CASES.read_text())


class ReferenceGB(unittest.TestCase):
    def setUp(self):
        self.c=CASES_LIST[0];self.n,self.m=read_code(ROOT/'data/matrices/untiered','GB_180_26_unknown')
    def test_frozen_source(self):
        self.assertEqual([(c['id'],c['l'],c['a'],c['b']) for c in CASES_LIST],[('MRL-TableII-GB180-anchor',90,[0,19,81,82],[0,59,68,72]),('MRL-TableII-GB688-lower-only',344,[0,17,77,97,125,145,146,265],[0,4,116,120,196,207,214,282])])
    def test_first_column(self):
        for c in CASES_LIST:
            n,hx,hz=build(c)
            self.assertEqual([r for r,w in enumerate(hx) if w&1],c['a'])
            self.assertEqual([r for r,w in enumerate(hz) if w&1],sorted((-e)%c['l'] for e in c['b']))
    def test_random_columns(self):
        rng=random.Random(196)
        for _ in range(50):
            l=rng.randrange(2,10);c={'l':l,'n':2*l,'a':rng.sample(range(l),rng.randrange(1,l+1)),'b':rng.sample(range(l),rng.randrange(1,l+1))}
            _,hx,hz=build(c);self.assertEqual([hx,hz],reconstruct(c));self.assertFalse(any(dot(x,z) for x in hx for z in hz))
    def test_random_polynomial_rank(self):
        rng=random.Random(1960)
        for _ in range(50):
            l=rng.randrange(2,13);c=dict(l=l,n=2*l,a=rng.sample(range(l),rng.randrange(1,l+1)),b=rng.sample(range(l),rng.randrange(1,l+1)))
            n,hx,hz=build(c);g=gcd(gcd(c['a'],c['b']),{0,l})
            self.assertEqual(len(basis(hx)),l-max(g));self.assertEqual(len(basis(hz)),l-max(g))

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
        for raw in ['c d_lb: 1\nc d_ub: 6\n','c d_lb: 8\nc d_ub: 9\n','c d_lb: 1\nc d_ub: 7\nc witness X: 0\n','c d_lb: 7\nc d_ub: 7\no 7\n']:
            with self.assertRaises(ValueError):assess(self.c,self.n,self.m,construction,dict(maxsat=raw,cc=raw))
    def test_lower_only_reference_not_exact_or_synthetic(self):
        c=CASES_LIST[1];n,m=read_code(ROOT/'data/matrices/untiered','GB_688_30_unknown');con=certify(c,n,m)
        raw='c d_lb: 7\nc d_ub: 104\n';r=assess(c,n,m,con,dict(maxsat=raw,cc=raw))
        self.assertEqual(r['engines']['maxsat']['lb'],7);self.assertEqual(r['reference_range'],[19,None]);self.assertEqual(r['source_upper_word_gate'],'NOT_APPLICABLE')
        raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n';r=assess(c,n,m,con,dict(maxsat=raw,cc=raw))
        self.assertIsNone(r['engines']['maxsat']['lb']);self.assertIsNone(r['engines']['maxsat']['ub']);self.assertEqual(r['numeric_smoke_gate'],'INCOMPLETE')
    def test_lower_only_contradiction_mutants(self):
        for raw in ['c d_lb: 7\nc d_ub: 18\n','c d_lb: 18\nc d_ub: 18\no 18\n']:
            with self.assertRaises(ValueError):parse_claim(raw,'>= 19 (published lower only)',688)
        r=parse_claim('c d_lb: 19\nc d_ub: 104\n','>= 19',688);self.assertEqual(r['status'],'BOUNDED')
        # Even an exact result above19 is allowed by a LOWER-only reference;
        # its scientific acceptance still requires a materialized GF2 word.
        r=parse_claim('c d_lb: 20\nc d_ub: 20\no 20\n','>= 19',688);self.assertEqual(r['status'],'SOLVED')
    def test_invalid_lower_reference_endpoint(self):
        for claim in ['>= 0','>= 689','> 19','unknown 19']:
            with self.assertRaises(ValueError):parse_claim('c d_lb: 1\nc d_ub: 100\n',claim,688)
    def test_original_claim_modes_unchanged(self):
        raw='c d_lb: 2\nc d_ub: 4\n'
        for claim in ['<= 5','estimate 3']:self.assertEqual(parse_claim(raw,claim,10),dict(lb=2,ub=4,status='BOUNDED'))
        self.assertEqual(parse_claim('c d_lb: 7\nc d_ub: 7\no 7\n','exact 7',180)['status'],'SOLVED')

    def test_smoke_selections(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/GH196-NOT-ALLOCATED','--dry-run']
        for flags,count in [([],12),(['--family','GB'],2)]:
            r=subprocess.run(base+flags,capture_output=True,text=True,check=True);self.assertEqual(len(json.loads(r.stdout)),count)
        r=subprocess.run(base+['--family','no-such-family'],capture_output=True);self.assertNotEqual(r.returncode,0)


if __name__=='__main__':unittest.main()
