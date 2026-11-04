#!/usr/bin/env python3
"""Deterministic tiny algebra, source-convention and mutation checks; no solver."""
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import amc
import validate_amc as va
import audit_amc_smoke as aa
from validate_css import validate,read_code,dot


class AMC(unittest.TestCase):
    def setUp(self):self.cases=json.loads(amc.CASES.read_text())

    def test_frozen_cases(self):
        self.assertEqual([(c['l'],c['n'],c['k'],c['exponents']) for c in self.cases],
            [(18,108,6,[1,3,5,7]),(36,216,6,[3,21,26,35]),
             (55,330,6,[15,39,46,51]),(73,438,6,[18,29,32,63]),
             (87,522,6,[39,54,77,80])])

    def test_source_claim_status(self):
        self.assertEqual([c['published_exact'] for c in self.cases],[9,None,None,None,None])
        self.assertEqual([c['published_estimate'] for c in self.cases],[None,12,14,17,20])

    def test_source_literal_first_rows(self):
        n,hx,hz=amc.checks(18,[1,3,5,7]);self.assertEqual(n,108)
        self.assertEqual(hx[0],sum(1<<i for i in [0,13,18,33,36,53]))
        self.assertEqual(hz[0],sum(1<<i for i in [0,3,18,23,54,61]))

    def test_thirty_tiny_random_constructions(self):
        rng=random.Random(199)
        for _ in range(30):
            l=rng.randrange(5,14);e=rng.sample(range(1,l),4)
            n,hx,hz=amc.checks(l,e);self.assertEqual((hx,hz),va.literal(l,e))
            self.assertFalse(any(dot(a,b) for a in hx for b in hz))
            mx,mz=va.metachecks(l,e);va.relation(mx,hx);va.relation(mz,hz)

    def test_full_actual_inputs(self):
        for c in self.cases:
            r=va.audit(c,ROOT/'data/matrices/untiered');self.assertEqual(r['k'],6)
            self.assertFalse(r['metachecks_complete'])
            self.assertEqual(r['rank_Mx'],c['l']-1)

    def test_bad_support(self):
        for l,e in [(4,[1,2,3,4]),(7,[1,2,3,3]),(7,[0,2,3,4]),(7,[1,2,3])]:
            with self.assertRaises(ValueError):amc.checks(l,e)

    def test_bad_degree(self):
        for d in [0,5]:
            with self.assertRaises(ValueError):amc.boundary(7,[1,2,3,4],d)

    def test_entry_mutant(self):
        c=self.cases[0];n,m=read_code(ROOT/'data/matrices/untiered','AMC_108_6_unknown');m[0][0]^=1
        with self.assertRaises(ValueError):validate(n,m)

    def test_logical_mutant(self):
        n,m=read_code(ROOT/'data/matrices/untiered','AMC_108_6_unknown');m[2][0]=0
        with self.assertRaises(ValueError):validate(n,m)

    def test_source_k_mutant(self):
        c=dict(self.cases[0]);c['k']=5
        with tempfile.TemporaryDirectory() as temp:
            for kind in ['Hx','Hz','Gx','Gz']:
                source=ROOT/'data/matrices/untiered'/('AMC_108_6_unknown_'+kind+'.txt')
                (Path(temp)/('AMC_108_5_unknown_'+kind+'.txt')).write_bytes(source.read_bytes())
            with self.assertRaisesRegex(ValueError,'source n/k mismatch'):va.audit(c,Path(temp))

    def test_metacheck_mutant(self):
        _,hx,hz=amc.checks(7,[1,2,3,4]);mx,_=va.metachecks(7,[1,2,3,4]);mx[0]^=1
        with self.assertRaises(ValueError):va.relation(mx,hx)

    def test_wrong_but_commuting_source_mutant(self):
        _,hx,hz=amc.checks(11,[1,2,3,5]);self.assertFalse(any(dot(a,b) for a in hx for b in hz))
        self.assertNotEqual((hx,hz),va.literal(11,[1,2,3,4]))

    def test_inverse_shift_mutant(self):
        _,hx,hz=amc.checks(11,[1,2,3,4]);_,xx,zz=amc.checks(11,[10,9,8,7])
        self.assertNotEqual((hx,hz),(xx,zz))
        self.assertFalse(any(dot(a,b) for a in xx for b in zz))

    def test_invalid_word_mutant(self):
        n,m=read_code(ROOT/'data/matrices/untiered','AMC_108_6_unknown')
        with self.assertRaises(ValueError):va.word(n,m[1],m[0],[m[0][0]],'X')

    def test_twenty_matrix_bytes_and_no_overwrite(self):
        with tempfile.TemporaryDirectory() as temp:
            d=Path(temp)
            for c in self.cases:
                stem=amc.generate(c,d)
                for kind in ['Hx','Hz','Gx','Gz']:
                    name=stem+'_'+kind+'.txt';self.assertEqual((d/name).read_bytes(),(ROOT/'data/matrices/untiered'/name).read_bytes())
                with self.assertRaises(FileExistsError):amc.generate(c,d)

    def test_only_source_cli_cases(self):
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/amc.py'),'--l','99'],capture_output=True,text=True)
        self.assertNotEqual(r.returncode,0);self.assertIn('frozen source cases',r.stderr)

    def evidence(self,index=1):
        c=self.cases[index];stem='AMC_%d_%d_unknown'%(c['n'],c['k'])
        n,m=read_code(ROOT/'data/matrices/untiered',stem)
        return c,n,m,va.audit(c,ROOT/'data/matrices/untiered')

    def test_weaker_raw_upper_not_filled(self):
        c,n,m,r=self.evidence()
        out=aa.assess(c,n,m,r,{'maxsat':'c d_lb: 4\nc d_ub: 20\n','cc':'c d_lb: 5\nc d_ub: 12\n'})
        self.assertEqual(out['engines']['maxsat']['ub'],20)
        self.assertEqual(out['actual_verified_upper'],12)
        self.assertEqual(out['reference_range'],[None,None])
        self.assertEqual(out['source_upper_word_gate'],'PASS')

    def test_missing_raw_bound_not_filled(self):
        c,n,m,r=self.evidence()
        out=aa.assess(c,n,m,r,{'maxsat':'c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n','cc':'c d_lb: 5\nc d_ub: 12\n'})
        self.assertIsNone(out['engines']['maxsat']['lb']);self.assertIsNone(out['engines']['maxsat']['ub'])
        self.assertEqual(out['numeric_smoke_gate'],'INCOMPLETE')

    def test_estimate_does_not_create_source_word(self):
        c,n,m,r=self.evidence(2)
        out=aa.assess(c,n,m,r,{'maxsat':'c d_lb: 5\nc d_ub: 20\n','cc':'c d_lb: 6\nc d_ub: 15\n'})
        self.assertEqual(out['actual_verified_upper'],15)
        self.assertEqual(out['source_upper_word_gate'],'INCOMPLETE')

    def test_source_exact_mismatch_mutant(self):
        c,n,m,r=self.evidence(0)
        with self.assertRaises(ValueError):aa.assess(c,n,m,r,{'maxsat':'c d_lb: 8\nc d_ub: 8\no 8\n'})

    def test_exact_without_minimum_word_mutant(self):
        c,n,m,r=self.evidence()
        with self.assertRaisesRegex(ValueError,'lacks actual minimum word'):
            aa.assess(c,n,m,r,{'maxsat':'c d_lb: 6\nc d_ub: 6\no 6\n'})

    def test_invalid_log_witness_mutant(self):
        c,n,m,r=self.evidence()
        with self.assertRaises(ValueError):aa.assess(c,n,m,r,{'maxsat':'c d_lb: 4\nc d_ub: 12\nc witness X: 0\n'})

    def test_certified_lower_exceeding_estimate_escalates(self):
        c,n,m,r=self.evidence();c=dict(c,published_estimate=10)
        with self.assertRaisesRegex(ValueError,'scientific discrepancy'):
            aa.assess(c,n,m,r,{'maxsat':'c d_lb: 11\nc d_ub: 12\n'})

    def test_smoke_defaults_and_amc_selection_dry_only(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/gh199-never-executed','--dry-run']
        default=json.loads(subprocess.check_output(base,text=True))
        selected=json.loads(subprocess.check_output(base+['--family','AMC'],text=True))
        self.assertEqual(len(default),12);self.assertTrue(all('/HGP_' in cmd[-1] for cmd in default))
        self.assertEqual(len(selected),5);self.assertTrue(all('/AMC_' in cmd[-1] for cmd in selected))
        self.assertTrue(all('-cpu-lim=60' in cmd for cmd in selected))
        self.assertFalse(Path('/tmp/gh199-never-executed').exists())


if __name__=='__main__':unittest.main()
