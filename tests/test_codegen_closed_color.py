#!/usr/bin/env python3
"""Finite algebra/topology/cover certificate units, no distance/support search."""
import copy
import json
import subprocess
from pathlib import Path
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import closed_color as gen
import validate_closed_color as independent
from validate_css import read_code
from verify_css_witness import verify_witness
CERTS=ROOT/'optimization/experiments/GH-184/raw/certificates'


class ClosedColorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases=gen.CASES;cls.cert={c['n']:json.loads((CERTS/f'COLOR_{c["n"]}_{c["k"]}_unknown.json').read_text()) for c in cls.cases}

    def test_fixed_six_cases_full_independent_certificates(self):
        self.assertEqual([(c['n'],c['k'],c['genus'],c['degree']) for c in self.cases],[(240,16,4,1),(480,28,7,2),(640,36,9,1),(1200,64,16,5),(1440,76,19,1),(2400,124,31,10)])
        for c in self.cases:
            n,m=read_code(ROOT/'data/matrices/untiered',f'COLOR_{c["n"]}_{c["k"]}_unknown');r=independent.certify(c,self.cert[c['n']],n,m)
            self.assertTrue(r['cover']['integer_chain_projection_and_transfer_verified']);self.assertTrue(r['physical_XZ_identity_map'])

    def test_wrong_group_action_mutant(self):
        cert=copy.deepcopy(self.cert[240]);cert['base']['oriented_table'][0][0]=0
        with self.assertRaises(ValueError):independent.source_group(self.cases[0],cert['base'])

    def test_wrong_reflection_automorphism_mutant(self):
        cert=copy.deepcopy(self.cert[240]);cert['base']['reflection_automorphism']=list(range(len(cert['base']['oriented_table'])))
        with self.assertRaisesRegex(ValueError,'reflection automorphism'):independent.source_group(self.cases[0],cert['base'])

    def test_oriented_boundary_sign_mutant(self):
        final=copy.deepcopy(self.cert[240]['final']);final['faces'][0]['edge_signs'][0]*=-1
        with self.assertRaisesRegex(ValueError,'oriented face sign'):independent.topology(final)

    def test_face_coloring_mutant(self):
        final=copy.deepcopy(self.cert[240]['final']);final['faces'][0]['color']=(final['faces'][0]['color']+1)%3
        with self.assertRaisesRegex(ValueError,'face coloring'):independent.topology(final)

    def test_nonclosing_integer_voltage_mutant(self):
        cert=copy.deepcopy(self.cert[480]);co=cert['cocycle'];co['voltage'][co['dual_tree_edges'][0]]+=1
        _,inc,_=independent.topology(cert['base'])
        with self.assertRaisesRegex(ValueError,'integral face voltage'):independent.integer_cover(self.cases[1],cert,inc)

    def test_disconnected_zero_voltage_cover_mutant(self):
        base=self.cert[480]['base'];co=dict(voltage=[0]*len(base['edges']));bad=gen.cover(base,2,co)
        with self.assertRaisesRegex(ValueError,'disconnected cellulation'):independent.topology(bad)

    def test_composite_nonzero_but_nonprimitive_cover_mutant(self):
        cert=self.cert[2400];bad=gen.cover(cert['base'],10,dict(voltage=[2*a for a in cert['cocycle']['voltage']]))
        self.assertTrue(any(cert['cocycle']['voltage']))
        with self.assertRaisesRegex(ValueError,'disconnected cellulation'):independent.topology(bad)

    def test_actual_face_matrix_mutant(self):
        c=self.cases[0];n,m=read_code(ROOT/'data/matrices/untiered','COLOR_240_16_unknown');m=[r[:] for r in m];m[0][0]^=1
        with self.assertRaisesRegex(ValueError,'actual static CSS face matrix'):independent.certify(c,self.cert[240],n,m)

    def test_hidden_direct_sum_under_mixed_checks(self):
        self.assertEqual(independent.rowspace_components(4,[0b0011,0b1111]),2)
        self.assertEqual(independent.rowspace_components(4,[0b0011,0b1100]),2)
        self.assertEqual(independent.rowspace_components(4,[0b1111]),1)

    def test_stabilizer_cannot_be_an_upper_word(self):
        n,m=read_code(ROOT/'data/matrices/untiered','COLOR_240_16_unknown')
        with self.assertRaisesRegex(ValueError,'nontrivial logical'):verify_witness(n,m,'X',independent.support(m[0][0]))

    def test_closed_subset_smoke_dry_run(self):
        stems=[f'COLOR_{c["n"]}_{c["k"]}_unknown' for c in self.cases]
        cmd=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--out','/tmp/not-created-closed-color-smoke','--family','COLOR','--stems']+stems
        jobs=json.loads(subprocess.check_output(cmd,cwd=ROOT,text=True))
        self.assertEqual([j[-1] for j in jobs],['data/matrices/untiered/'+stem for stem in stems])
        self.assertEqual(len(jobs),6)

    def test_byte_regeneration_and_overwrite_refusal(self):
        with tempfile.TemporaryDirectory() as d:
            stem,cert=gen.generate(self.cases[0],Path(d))
            for kind in ('Hx','Hz','Gx','Gz'):self.assertEqual((Path(d)/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
            self.assertEqual(json.dumps(cert,indent=2)+'\n',(CERTS/(stem+'.json')).read_text())
            with self.assertRaises(FileExistsError):gen.generate(self.cases[0],Path(d))


if __name__=='__main__':unittest.main()
