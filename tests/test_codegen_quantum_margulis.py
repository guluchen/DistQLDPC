#!/usr/bin/env python3
"""Independent SL2/vector/typed-Pauli construction checks and corruption mutants."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
import quantum_margulis as gen
import validate_quantum_margulis as check
from validate_css import read_code,validate
from verify_css_witness import verify_witness


class MargulisTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases=json.loads(gen.CASES.read_text());cls.certs=[];cls.matrices=[]
        for c in cls.cases:
            stem=f'QMC_{c["n"]}_{c["k"]}_unknown'
            cls.certs.append(json.loads((ROOT/'optimization/experiments/GH-187/raw/certificates'/f'{stem}.json').read_text()))
            cls.matrices.append(read_code(ROOT/'data/matrices/untiered',stem))

    def test_all_frozen_cases_and_full_independent_physical_audit(self):
        self.assertEqual([c['n'] for c in self.cases],[240,672,2640])
        for c,cert,(n,m) in zip(self.cases,self.certs,self.matrices):
            r=check.certify(c,cert,n,m);self.assertEqual(r['k'],c['k']);self.assertTrue(r['group']['central_minus_identity_distinguished'])

    def test_source_integral_conjugation_mutant(self):
        cert=copy.deepcopy(self.certs[0]);cert['integral_generators']['A'][0][1]+=1
        with self.assertRaisesRegex(ValueError,'integral conjugation'):check.group_and_actions(self.cases[0],cert)

    def test_projective_quotient_collapse_mutant(self):
        cert=copy.deepcopy(self.certs[0]);cert['elements']=cert['elements'][::2]
        with self.assertRaisesRegex(ValueError,'complete SL2'):check.group_and_actions(self.cases[0],cert)

    def test_wrong_identity_mutant(self):
        cert=copy.deepcopy(self.certs[0]);cert['identity']=cert['elements'].index([4,0,0,4])
        with self.assertRaisesRegex(ValueError,'projective quotient|identity'):check.group_and_actions(self.cases[0],cert)

    def test_right_left_action_swap_mutant(self):
        cert=copy.deepcopy(self.certs[0]);cert['right_A'][0][0]=cert['right_A'][0][1]
        with self.assertRaisesRegex(ValueError,'vector composition'):check.group_and_actions(self.cases[0],cert)

    def test_missing_inverse_transpose_mutant(self):
        cert=copy.deepcopy(self.certs[0]);cert['inverse_left_B']=copy.deepcopy(cert['left_B'])
        with self.assertRaisesRegex(ValueError,'inverse transpose'):check.group_and_actions(self.cases[0],cert)

    def test_actual_binary_column_mutant(self):
        n,m=copy.deepcopy(self.matrices[0]);m[0][0]^=1
        with self.assertRaisesRegex(ValueError,'binary column'):check.certify(self.cases[0],self.certs[0],n,m)

    def test_commuting_row_basis_change_does_not_match_source_columns(self):
        n,m=copy.deepcopy(self.matrices[0]);m[1][0]^=m[1][1];validate(n,m)
        with self.assertRaisesRegex(ValueError,'binary column'):check.certify(self.cases[0],self.certs[0],n,m)

    def test_typed_pauli_rows_prevent_false_direct_sum_rejection(self):
        # Scalar merging falsely splits this space into two blocks. The X
        # generator couples all four physical qubits in the true stabilizer.
        self.assertEqual(check.rowspace_components(4,[0b1111,0b1100]),2)
        self.assertEqual(check.rowspace_components(4,[0b1111,0b1100<<4]),1)

    def test_mixed_typed_rows_still_expose_actual_direct_sum(self):
        self.assertEqual(check.rowspace_components(4,[0b1111,0b1100,0b1111<<4,0b1100<<4]),2)

    def test_actual_full_code_has_one_typed_physical_component(self):
        n,m=self.matrices[0]
        self.assertEqual(check.rowspace_components(n,m[0]+[w<<n for w in m[1]]),1)

    def test_stabilizer_cannot_be_upper_witness(self):
        n,m=self.matrices[0]
        with self.assertRaises(ValueError):verify_witness(n,m,'X',check.support(m[0][0]))

    def test_parameter_identity_mutant(self):
        cert=copy.deepcopy(self.certs[0]);cert['parameter_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'identity'):check.certify(self.cases[0],cert,*self.matrices[0])

    def test_explicit_three_case_cli_selection(self):
        stems=[f'QMC_{c["n"]}_{c["k"]}_unknown' for c in self.cases]
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--family','QMC','--stems',*stems,'--dry-run','--out','/tmp/gh187-unused'],cwd=ROOT,text=True,capture_output=True,check=True)
        jobs=json.loads(r.stdout);self.assertEqual(len(jobs),3);self.assertEqual({j[-1].split('/')[-1] for j in jobs},set(stems))

    def test_fresh_matrix_and_full_certificate_byte_reproduction(self):
        with tempfile.TemporaryDirectory() as tmp:
            out=Path(tmp)/'matrices';certs=Path(tmp)/'certificates'
            for c in self.cases:
                stem=gen.generate(c,out,certs)
                for kind in ('Hx','Hz','Gx','Gz'):
                    self.assertEqual((out/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
                self.assertEqual((certs/f'{stem}.json').read_bytes(),(ROOT/'optimization/experiments/GH-187/raw/certificates'/f'{stem}.json').read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(self.cases[0],out,certs)


if __name__=='__main__':unittest.main()
