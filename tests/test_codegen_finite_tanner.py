#!/usr/bin/env python3
"""Finite-group QT reconstruction, independent incidence and source mutants."""
import copy
import json
from pathlib import Path
import random
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import finite_tanner as gen
import validate_finite_tanner as independent
import validate_css as gf
import smoke_untiered as smoke
from verify_css_witness import verify_witness

CASES=json.loads(gen.CASES.read_text())


def dual(rows,n):
    words=[w for w in range(1,1<<n) if not any(gf.dot(w,r) for r in rows)]
    return list(gf.basis(words).values())


def dense(rows,n):return [[(r>>q)&1 for q in range(n)] for r in rows]


class FiniteTannerTests(unittest.TestCase):
    def test_fixed_sources_incidence_and_full_logicals(self):
        for c in CASES:
            stem=f'TN_{c["n"]}_{c["k"]}_unknown';n,m=gf.read_code(ROOT/'data/matrices/untiered',stem)
            r=independent.certify(c,n,m);self.assertEqual(r['k'],c['k'])
            self.assertEqual(gen.checks(c),(n,*m[:2]))

    def test_group_inverse_and_action_commutation(self):
        for c in CASES:
            group,a,b=gen.group_data(c);identity=tuple(range(len(group[0])))
            inverse_group,_,_=independent.independent_group(c)
            self.assertEqual(group,[gen.inverse(g) for g in inverse_group])
            for g in group:
                self.assertEqual(gen.multiply(g,gen.inverse(g)),identity)
                for x,y in zip(a,b):
                    self.assertEqual(gen.multiply(x,gen.multiply(g,gen.inverse(y))),gen.multiply(gen.multiply(x,g),gen.inverse(y)))

    def test_invalid_cycle_dimension_and_local_duality_mutants(self):
        for text in ('(1,2)(2,3)','(0,1)','(1,1)','garbage'):
            with self.assertRaises(ValueError):gen.permutation(text,3)
            with self.assertRaises(ValueError):independent.inverse_cycles(text,3)
        c=copy.deepcopy(CASES[0]);c['pi_A']=[1]*8
        with self.assertRaises(ValueError):gen.checks(c)
        c=copy.deepcopy(CASES[0]);c['H_A'][0][0]^=1
        with self.assertRaises(ValueError):gen.checks(c)

    def test_source_parameter_mutants(self):
        for key in ('A','pi_B','H_A'):
            c=copy.deepcopy(CASES[0])
            if key=='A':c['A'][0]='(1,2)'
            elif key=='pi_B':c['pi_B'][0],c['pi_B'][1]=c['pi_B'][1],c['pi_B'][0]
            else:c['H_A'][0][0]^=1
            with self.assertRaises(ValueError):independent.source_binding(c)
        c=copy.deepcopy(CASES[0]);c['source_reconstruction']['H1_B'][0][0]^=1
        with self.assertRaises(ValueError):independent.source_binding(c)

    def test_wrong_right_action_still_css_but_not_source_code(self):
        # Inverting the B inputs gives another mathematically valid lift; CSS
        # alone cannot identify the published instance. Independent fixed-case
        # pullback must reject its altered physical rows.
        c=CASES[0];wrong=copy.deepcopy(c)
        wrong['B']=[s.replace('(1,2,3)','TEMP').replace('(1,3,2)','(1,2,3)').replace('TEMP','(1,3,2)') for s in wrong['B']]
        n,x,z=gen.checks(wrong)
        self.assertFalse(any(gf.dot(a,b) for a in x for b in z))
        expected=independent.reconstruct(c)
        self.assertNotEqual((x,z),expected)

    def test_single_half_action_mutant_breaks_independent_incidence(self):
        c=CASES[1];n,m=gf.read_code(ROOT/'data/matrices/untiered',f'TN_{c["n"]}_{c["k"]}_unknown')
        m[0][0]^=1
        with self.assertRaises(ValueError):independent.certify(c,n,m)

    def test_random_local_codes_and_column_permutations(self):
        rng=random.Random(169)
        for _ in range(24):
            c=dict(A=['()','(1,2)','(1,2,3)'],B=['()','(2,3)','(1,3,2)'],group_order=6,n=54)
            for side in ('A','B'):
                h=list(gf.basis([rng.randrange(1,8)]).values());g=dual(h,3)
                c['H_'+side]=dense(h,3);c['G_'+side]=dense(g,3);pi=[1,2,3];rng.shuffle(pi);c['pi_'+side]=pi
            n,x,z=gen.checks(c);self.assertEqual((x,z),independent.reconstruct(c))
            self.assertFalse(any(gf.dot(a,b) for a in x for b in z))

    def test_tiny_exhaustive_logical_supports(self):
        c=dict(A=['()','(1,2)'],B=['()','(1,2)'],group_order=2,n=8,H_A=[[1,1]],G_A=[[1,1]],H_B=[[1,1]],G_B=[[1,1]],pi_A=[1,2],pi_B=[1,2])
        n,x,z=gen.checks(c);self.assertEqual((x,z),independent.reconstruct(c))
        self.assertEqual(n-len(gf.basis(x))-len(gf.basis(z)),2)
        for parity,stab in ((x,z),(z,x)):
            distance=min(bin(w).count('1') for w in range(1,1<<n) if not any(gf.dot(w,r) for r in parity) and not gf.contains(gf.basis(stab),w))
            self.assertEqual(distance,2)

    def test_heuristic_upper_not_promoted_to_exact(self):
        raw='c d_lb: 9\nc d_ub: 12\ns UNKNOWN\n'
        self.assertEqual(smoke.parse(raw,15,exact=False),dict(lb=9,ub=12,status='BOUNDED'))
        with self.assertRaises(ValueError):smoke.parse(raw,15)
        self.assertEqual(smoke.parse('c d_lb: 12\nc d_ub: 12\no 12\n',15,exact=False)['status'],'SOLVED')
        for raw in ('c d_lb: 16\nc d_ub: 18\n','c d_lb: 0\nc d_ub: 0\n','c d_lb: 10\nc d_ub: 9\n'):
            with self.assertRaises(ValueError):smoke.parse(raw,15,exact=False)

    def test_real_basis_words_and_stabilizer_mutant(self):
        c=CASES[0];n,m=gf.read_code(ROOT/'data/matrices/untiered',f'TN_{c["n"]}_{c["k"]}_unknown')
        for half,words in (('X',m[3]),('Z',m[2])):
            for w in words:verify_witness(n,m,half,[q for q in range(n) if (w>>q)&1])
        w=m[0][0]
        with self.assertRaises(ValueError):verify_witness(n,m,'X',[q for q in range(n) if (w>>q)&1])

    def test_singular_logical_and_disconnected_mutants(self):
        c=CASES[0];n,m=gf.read_code(ROOT/'data/matrices/untiered',f'TN_{c["n"]}_{c["k"]}_unknown');m[2][1]=m[2][0]
        with self.assertRaises(ValueError):independent.certify(c,n,m)
        with self.assertRaises(ValueError):independent.connected(4,[3,12])

    def test_byte_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d);gen.generate(CASES[0],p)
            for f in p.glob('*.txt'):self.assertEqual(f.read_bytes(),(ROOT/'data/matrices/untiered'/f.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],p)


if __name__=='__main__':unittest.main()
