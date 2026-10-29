#!/usr/bin/env python3
"""Finite construction certificates, independent topology and corruption mutants."""
import copy
import itertools
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
import color3d as gen
import validate_color3d as check
from validate_css import read_code,validate
from verify_css_witness import verify_witness


class ColexTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases=json.loads(gen.CASES.read_text());cls.certs=[];cls.matrices=[]
        for c in cls.cases:
            stem=f'COLOR_{c["n"]}_{c["k"]}_unknown'
            cls.certs.append(json.loads((ROOT/'optimization/experiments/GH-185/raw/certificates'/f'{stem}.json').read_text()))
            cls.matrices.append(read_code(ROOT/'data/matrices/untiered',stem))

    def test_all_frozen_cases_full_independent_audit(self):
        self.assertEqual([c['n'] for c in self.cases],[8,384,576,864,1296,1728,2304])
        for c,cert,(n,m) in zip(self.cases,self.certs,self.matrices):
            r=check.certify(c,cert,n,m);self.assertEqual(r['k'],c['k'])
            self.assertFalse(r['physical_XZ_identity_map'])

    def test_period_two_parallel_cells_are_distinct(self):
        c=self.certs[1]
        # The positive x edges at x=0 and x=1 have identical endpoint sets,
        # but distinct position/mask IDs, each present in the full flag set.
        ids=set(cell for flag in c['flags'] for cell in flag)
        self.assertIn(1,ids);self.assertIn(33,ids)
        self.assertEqual(len(ids),64)

    def test_neighbor_involution_mutant(self):
        c=copy.deepcopy(self.certs[1]);c['adjacency'][0][0]=0
        with self.assertRaisesRegex(ValueError,'involution|four-valent'):check.topology(self.cases[1],c)

    def test_colored_facet_mismatch_mutant(self):
        c=copy.deepcopy(self.certs[1]);c['flags'][0][0],c['flags'][1][0]=c['flags'][1][0],c['flags'][0][0]
        # These may share a vertex; change an actual rank explicitly.
        c['flags'][0][0]=c['flags'][0][1]
        with self.assertRaisesRegex(ValueError,'flags'):check.topology(self.cases[1],c)

    def test_volume_residue_mutant(self):
        c=copy.deepcopy(self.certs[1]);c['cells'][0]=c['cells'][0][1:]
        with self.assertRaisesRegex(ValueError,'volume residue'):check.topology(self.cases[1],c)

    def test_face_residue_mutant(self):
        c=copy.deepcopy(self.certs[1]);c['faces'][0]=c['faces'][0][1:]
        with self.assertRaisesRegex(ValueError,'face residue'):check.topology(self.cases[1],c)

    def test_four_colored_graph_with_toroidal_volume_is_rejected(self):
        # Two copies of a three-colored honeycomb torus joined by color3.
        # Proper coloring, bipartition and connectedness alone are insufficient.
        def label(x,y,p,t):return (((x%3)*3+y%3)*2+p)*2+t
        adj=[None]*36
        for x,y,p,t in itertools.product(range(3),range(3),range(2),range(2)):
            sign=1 if p==0 else -1
            adj[label(x,y,p,t)]=[label(x,y,1-p,t),label(x+sign,y,1-p,t),label(x,y+sign,1-p,t),label(x,y,p,1-t)]
        # Bipartition includes the copy index.
        cert={'adjacency':adj,'cells':[],'faces':[]}
        for missing in range(4):cert['cells'] += [sorted(vs) for vs in gen.residues(adj,[i for i in range(4) if i!=missing])]
        for cs in itertools.combinations(range(4),2):cert['faces'] += gen.residues(adj,cs)
        with self.assertRaisesRegex(ValueError,'not a sphere'):check.topology({'n':36},cert)

    def test_actual_matrix_column_mutant(self):
        n,m=copy.deepcopy(self.matrices[0]);m[0][0]^=1
        with self.assertRaisesRegex(ValueError,'matrix mismatch'):check.certify(self.cases[0],self.certs[0],n,m)

    def test_no_assumed_XZ_identity(self):
        n,m=copy.deepcopy(self.matrices[1]);m[0],m[1]=m[1],m[0]
        with self.assertRaisesRegex(ValueError,'matrix mismatch'):check.certify(self.cases[1],self.certs[1],n,m)

    def test_stabilizer_is_not_an_upper_witness(self):
        n,m=self.matrices[0]
        with self.assertRaises(ValueError):verify_witness(n,m,'X',list(range(8)))

    def test_mixed_rows_cannot_hide_physical_direct_sum(self):
        self.assertEqual(check.rowspace_components(4,[0b1111,0b1100]),2)

    def test_parameter_identity_mutant(self):
        c=copy.deepcopy(self.certs[0]);c['parameter_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'identity'):check.certify(self.cases[0],c,*self.matrices[0])

    def test_explicit_seven_case_cli_selection(self):
        stems=[f'COLOR_{c["n"]}_{c["k"]}_unknown' for c in self.cases]
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--family','COLOR','--stems',*stems,'--dry-run','--out','/tmp/gh185-unused'],cwd=ROOT,text=True,capture_output=True,check=True)
        jobs=json.loads(r.stdout);self.assertEqual(len(jobs),7)
        self.assertEqual({j[-1].split('/')[-1] for j in jobs},set(stems))

    def test_fresh_matrix_and_full_certificate_byte_reproduction(self):
        with tempfile.TemporaryDirectory() as tmp:
            out=Path(tmp)/'matrices';certs=Path(tmp)/'certificates'
            for c in self.cases:
                stem=gen.generate(c,out,certs)
                for kind in ('Hx','Hz','Gx','Gz'):
                    self.assertEqual((out/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
                self.assertEqual((certs/f'{stem}.json').read_bytes(),(ROOT/'optimization/experiments/GH-185/raw/certificates'/f'{stem}.json').read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(self.cases[0],out,certs)


if __name__=='__main__':unittest.main()
