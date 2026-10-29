#!/usr/bin/env python3
"""Independent source/chain checks and corruption mutants for finite DHLV."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
import dhlv as gen
import validate_dhlv as check
from validate_css import read_code,validate
from verify_css_witness import verify_witness


class DHLVTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases=json.loads(gen.CASES.read_text());cls.certs=[];cls.matrices=[]
        for c in cls.cases:
            stem=f'DHLV_{c["n"]}_{c["k"]}_unknown'
            cls.certs.append(json.loads((ROOT/'optimization/experiments/GH-186/raw/certificates'/f'{stem}.json').read_text()))
            cls.matrices.append(read_code(ROOT/'data/matrices/untiered',stem))

    def test_all_six_full_certificates_and_actual_binary_columns(self):
        self.assertEqual([c['n'] for c in self.cases],[108,784,1176,1568,1960,2744])
        for c,cert,(n,m) in zip(self.cases,self.certs,self.matrices):
            r=check.certify(c,cert,n,m);self.assertEqual(r['k'],c['k'])
            self.assertEqual(r['chain']['actual_corner_tensor_paths_verified'],8*len(cert['squares']))

    def test_faithful_group_composition_mutant(self):
        cert=copy.deepcopy(self.certs[1]);cert['multiplication'][1][2]^=1
        with self.assertRaisesRegex(ValueError,'composition'):check.geometry(self.cases[1],cert)

    def test_nonsymmetric_source_generator_mutant(self):
        c=copy.deepcopy(self.cases[2]);c['A'][1]=[2,0]
        with self.assertRaisesRegex(ValueError,'symmetric'):check.geometry(c,self.certs[2])

    def test_actual_edge_endpoint_mutant(self):
        cert=copy.deepcopy(self.certs[1]);cert['edges'][0]['ends'][1]^=4
        with self.assertRaisesRegex(ValueError,'endpoints'):check.geometry(self.cases[1],cert)

    def test_actual_square_incidence_mutant(self):
        cert=copy.deepcopy(self.certs[1]);cert['squares'][0]['vertices'][-1]^=4
        with self.assertRaisesRegex(ValueError,'square incidence'):check.geometry(self.cases[1],cert)

    def test_missing_square_full_star_mutant(self):
        cert=copy.deepcopy(self.certs[1]);cert['squares'].pop()
        with self.assertRaisesRegex(ValueError,'incomplete square'):check.geometry(self.cases[1],cert)

    def test_local_stalk_width_mutant(self):
        cert=copy.deepcopy(self.certs[1]);cert['edges'][0]['width']+=1
        with self.assertRaisesRegex(ValueError,'stalk width'):check.geometry(self.cases[1],cert)

    def test_wrong_endpoint_inverse_local_label_mutant(self):
        # Ordered edge label is the SAME at both endpoints (source Sec2.7).
        c,cert=self.cases[1],self.certs[1];n,m=copy.deepcopy(self.matrices[1]);e=cert['edges'][0]
        v=e['ends'][1];q=0;mb=cert['mb'];ma=cert['ma']
        for ia in range(ma):
            if c['HA'][ia][0]!=c['HA'][ia][1]:m[0][(v*ma+ia)*mb+q]^=1<<(e['offset']+q)
        with self.assertRaisesRegex(ValueError,'d1 endpoint/local-label'):check.certify(c,cert,n,m)

    def test_actual_square_map_column_mutant(self):
        c,cert=self.cases[1],self.certs[1];n,m=copy.deepcopy(self.matrices[1]);m[1][0]^=1
        with self.assertRaisesRegex(ValueError,'d2 edge-star'):check.certify(c,cert,n,m)

    def test_commuting_changed_square_basis_is_not_source_incidence(self):
        c,cert=self.cases[0],self.certs[0];n,m=copy.deepcopy(self.matrices[0]);m[1][0]^=m[1][1]
        validate(n,m)  # Same valid stabilizer space, wrong claimed face map.
        with self.assertRaisesRegex(ValueError,'d2 edge-star'):check.certify(c,cert,n,m)

    def test_parameter_identity_mutant(self):
        cert=copy.deepcopy(self.certs[0]);cert['parameter_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'identity'):check.certify(self.cases[0],cert,*self.matrices[0])

    def test_stabilizer_is_not_upper_word(self):
        n,m=self.matrices[0]
        with self.assertRaises(ValueError):verify_witness(n,m,'X',check.support(m[0][0]))

    def test_mixed_stabilizer_rows_cannot_hide_direct_sum(self):
        self.assertEqual(check.rowspace_components(4,[0b1111,0b1100]),2)

    def test_explicit_six_case_cli_selection(self):
        stems=[f'DHLV_{c["n"]}_{c["k"]}_unknown' for c in self.cases]
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--family','DHLV','--stems',*stems,'--dry-run','--out','/tmp/gh186-unused'],cwd=ROOT,text=True,capture_output=True,check=True)
        jobs=json.loads(r.stdout);self.assertEqual(len(jobs),6)
        self.assertEqual({j[-1].split('/')[-1] for j in jobs},set(stems))

    def test_fresh_matrix_and_complete_certificate_byte_reproduction(self):
        with tempfile.TemporaryDirectory() as tmp:
            out=Path(tmp)/'matrices';certs=Path(tmp)/'certificates'
            for c in self.cases:
                stem=gen.generate(c,out,certs)
                for kind in ('Hx','Hz','Gx','Gz'):
                    self.assertEqual((out/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
                self.assertEqual((certs/f'{stem}.json').read_bytes(),(ROOT/'optimization/experiments/GH-186/raw/certificates'/f'{stem}.json').read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(self.cases[0],out,certs)


if __name__=='__main__':unittest.main()
