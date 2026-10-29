#!/usr/bin/env python3
"""Tiny algebraic and mutation checks; no source-distance/support search."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import haah_cubic as gen
import validate_haah_cubic as independent
from validate_css import read_code,dot,equal_space
from verify_css_witness import verify_witness


class HaahTests(unittest.TestCase):
    def test_frozen_dimensions_and_actual_full_certificates(self):
        self.assertEqual([(c['L'],c['n'],c['k']) for c in gen.CASES],[(2,16,6),(4,128,14),(6,432,6),(8,1024,30),(10,2000,6),(11,2662,2)])
        for c in gen.CASES:
            n,m=read_code(ROOT/'data/matrices/untiered',f'HCC_{c["n"]}_{c["k"]}_unknown')
            r=independent.certify(c,n,m)
            self.assertEqual(r['published_interval_is_new_independent_proof'],False)
            self.assertTrue(r['complete_logical_quotients_under_dual_map'])

    def test_small_periodic_columns_and_commutation(self):
        for L in (1,2,3,4):
            hx,hz=gen.matrices(L)
            self.assertEqual((hx,hz),independent.reconstruct(L))
            self.assertFalse(any(dot(x,z) for x in hx for z in hz))

    def test_periodic_collision_xor_mutant(self):
        self.assertEqual(gen.matrices(1),([0],[0]))
        # OR instead of parity would leave both physical species set.
        or_mutant=3
        self.assertNotEqual(or_mutant,gen.matrices(1)[0][0])

    def test_source_corner_coordinates_and_Z_pattern(self):
        self.assertEqual(gen.CORNERS,{'A':(1,0,1),'B':(1,1,1),'C':(1,0,0),'D':(1,1,0),'Ap':(0,1,0),'Bp':(0,0,0),'Cp':(0,1,1),'Dp':(0,0,1)})
        self.assertEqual(tuple(gen.Z_LABELS.values()),('ZI','ZZ','IZ','ZI','IZ','II','ZI','IZ'))
        for name,p in gen.CORNERS.items():
            opposite=name[:-1] if name.endswith('p') else name+'p'
            self.assertEqual(tuple(1-v for v in p),gen.CORNERS[opposite])

    def test_actual_physical_dual_involution(self):
        for L in (2,3,4):
            p=independent.dual_permutation(L);hx,hz=gen.matrices(L)
            self.assertEqual(sorted(p),list(range(2*L**3)))
            self.assertEqual([p[p[q]] for q in range(len(p))],list(range(len(p))))
            self.assertEqual({independent.permute(w,p) for w in hx},set(hz))

    def test_one_corner_mutant_is_caught(self):
        c=gen.CASES[0];n,m=read_code(ROOT/'data/matrices/untiered','HCC_16_6_unknown');m=[r[:] for r in m];m[1][0]^=1
        with self.assertRaisesRegex(ValueError,'physical columns'):independent.certify(c,n,m)

    def test_omitted_body_inversion_mutant_is_caught(self):
        c=gen.CASES[1];n,m=read_code(ROOT/'data/matrices/untiered','HCC_128_14_unknown');m=[r[:] for r in m]
        # Keep the species exchange but omit Eq8's spatial body inversion.
        swap=[q^1 for q in range(n)]
        m[0]=[independent.permute(w,swap) for w in m[1]]
        with self.assertRaisesRegex(ValueError,'physical columns'):independent.certify(c,n,m)

    def test_frozen_peer_raw_proofs_and_rowspace_checks(self):
        from audit_haah_cubic_smoke import verify_peer
        n,m,receipt=verify_peer();nn,own=read_code(ROOT/'data/matrices/untiered','HCC_128_14_unknown')
        self.assertEqual((n,nn),(128,128))
        self.assertFalse(equal_space(m[0],own[0]) and equal_space(m[1],own[1]))
        self.assertFalse(equal_space(m[0],own[1]) and equal_space(m[1],own[0]))

    def test_stabilizer_is_not_an_upper_word(self):
        n,m=read_code(ROOT/'data/matrices/untiered','HCC_16_6_unknown')
        with self.assertRaisesRegex(ValueError,'nontrivial logical'):verify_witness(n,m,'X',independent.support(m[0][0]))

    def test_regeneration_and_overwrite_refusal(self):
        c=gen.CASES[0]
        with tempfile.TemporaryDirectory() as d:
            out=Path(d);stem=gen.generate(c,out)
            for kind in ('Hx','Hz','Gx','Gz'):self.assertEqual((out/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(c,out)

    def test_invalid_side_and_outside_width_witness(self):
        for L in (0,-1,1.5):
            with self.assertRaises(ValueError):gen.matrices(L)
        n,m=read_code(ROOT/'data/matrices/untiered','HCC_16_6_unknown')
        with self.assertRaises(ValueError):verify_witness(n,m,'X',[n])


if __name__=='__main__':unittest.main()
