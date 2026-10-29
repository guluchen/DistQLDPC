#!/usr/bin/env python3
"""Finite incidence/theorem hypotheses and failure mutations; no distance solver."""
import itertools
import json
from pathlib import Path
import random
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import hyperbicycle as gen
import validate_hyperbicycle as audit
import validate_css as css
import smoke_untiered as smoke
import audit_hyperbicycle_smoke as logaudit


class HyperbicycleTests(unittest.TestCase):
    def test_random_tiny_actual_columns_and_commutation(self):
        rng=random.Random(205)
        for _ in range(30):
            a,b,c=rng.randint(1,5),rng.randint(1,5),rng.choice([2,4,6])
            case=dict(n1=a,n2=b,c=c,chi=1,
                      h1=sorted(rng.sample(range(c*a),rng.randint(1,min(5,c*a)))),
                      h2=sorted(rng.sample(range(c*b),rng.randint(1,min(5,c*b)))))
            n,hx,hz=gen.checks(case)
            self.assertEqual((n,hx,hz),audit.independent_checks(case))
            self.assertFalse(any(css.dot(x,z) for x in hx for z in hz))

    def test_frozen_case_entries_dimensions_and_source_hypotheses(self):
        for case in gen.CASES:
            n,hx,hz=gen.checks(case)
            self.assertEqual((n,hx,hz),audit.independent_checks(case))
            self.assertEqual(n,case['n'])
            self.assertEqual(n-len(css.basis(hx))-len(css.basis(hz)),case['k'])
            factors=[audit.classical(case['n1'],case['c'],case['h1']),
                     audit.classical(case['n2'],case['c'],case['h2'])]
            d=min(x['distance'] for f in factors for x in f['original_and_transpose'])
            self.assertEqual([2*d//case['c'],d],case['conditional_construction_interval'])

    def test_scalar_kernel_matches_complete_bruteforce(self):
        rng=random.Random(2051)
        for n in range(1,9):
            rows=[rng.randrange(1 << n) for _ in range(n//2)]
            expected={w for w in range(1 << n) if not any(css.dot(w,r) for r in rows)}
            ker=audit.set_kernel(rows,n)
            actual={0}
            for g in ker:
                actual |= {w^g for w in list(actual)}
            self.assertEqual(actual,expected)

    def test_transpose_omission_mutant_is_caught(self):
        case=dict(n1=3,n2=4,c=2,chi=1,h1=[0,1,4],h2=[0,2,5])
        n,hx,hz=gen.checks(case)
        # Wrong same-signed shifts, frequently hidden by symmetric toy inputs.
        wrong=[((r << 1)&((1 << n)-1))|(r >> (n-1)) for r in hz]
        self.assertNotEqual(wrong,audit.independent_checks(case)[2])
        self.assertTrue(any(css.dot(x,z) for x in hx for z in wrong))

    def test_wrong_physical_carry_mutant_is_caught(self):
        case=dict(n1=3,n2=4,c=4,chi=1,h1=[0,1,4],h2=[0,2,5])
        _,hx,hz=gen.checks(case)
        bad=dict(case,h1=[0,1,3])
        self.assertNotEqual((hx,hz),audit.independent_checks(bad)[1:])

    def test_actual_dimension_guard_before_any_write(self):
        case=dict(gen.CASES[0],k=52)
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'new'
            with self.assertRaisesRegex(ValueError,'actual dimension'):
                gen.generate(case,out)
            self.assertFalse(out.exists())

    def test_invalid_inputs_and_unimplemented_chi(self):
        for args in [(0,2,[0]),(3,0,[0]),(3,2,[]),(3,2,[0,0]),(3,2,[6]),(3,2,[-1])]:
            with self.assertRaises(ValueError):gen.blocks(*args)
        with self.assertRaises(ValueError):gen.checks(dict(gen.CASES[0],chi=3))

    def test_classical_full_symmetry_guard_mutant(self):
        # The polynomial does not divide x^3+1: its length6 kernel may not
        # inherit the repeated-code hypothesis, even though CSS still commutes.
        with self.assertRaises(ValueError):audit.classical(3,2,[0,1,3])

    def test_too_large_classical_enumeration_refused(self):
        with self.assertRaises(ValueError):audit.words([1 << j for j in range(13)])

    def test_dependent_classical_basis_refused(self):
        with self.assertRaises(ValueError):audit.words([1,1])

    def test_canonical_components_do_not_fake_coupling(self):
        # Redundant sum joins the displayed supports but not the rowspace.
        self.assertEqual(audit.components([3,12,15],[],4),[2,2])

    def test_reference_interval_preserves_weaker_observed_bounds(self):
        # Reference lower14 is not inserted into an observed search lower3.
        result=smoke.parse_claim('c d_lb: 3\nc d_ub: 19\n','range 14 28 (construction)',1800)
        self.assertEqual(result,dict(lb=3,ub=19,status='BOUNDED'))

    def test_reference_interval_violations_stop(self):
        for text in ['c d_lb: 29\nc d_ub: 40\n','c d_lb: 3\nc d_ub: 13\n',
                     'c d_lb: 3\nc d_ub: 28\no 13\n']:
            with self.assertRaises(ValueError):smoke.parse_claim(text,'range 14 28',1800)

    def test_interval_does_not_fill_missing_numeric(self):
        text='s UNKNOWN\nc status: TIMEOUT (child killed after -cpu-lim)\n'
        self.assertEqual(smoke.parse_claim(text,'range 14 28',1800),
                         dict(lb=None,ub=None,status='TIMEOUT_NO_BOUNDS'))

    def test_invalid_interval_and_physical_ceiling(self):
        for claim in ('range 0 2','range 4 3','range 2 50','range 2'):
            with self.assertRaises(ValueError):smoke.parse_claim('c d_lb: 1\nc d_ub: 4\n',claim,36)

    def test_reference_interval_exact_answer(self):
        self.assertEqual(smoke.parse_claim('c d_lb: 14\nc d_ub: 14\no 14\n',
                                          'range 14 28',1800)['status'],'SOLVED')

    def test_log_audit_rejects_search_lower_above_actual_word(self):
        case=dict(n1=3,n2=3,c=2,chi=1,h1=[0,1],h2=[0,1])
        n,hx,hz=gen.checks(case)
        # A physical kernel word is obtained from the tiny nullspace directly;
        # use the bundled logical builder only as an input, never as verifier.
        sys.path.insert(0,str(ROOT/'scripts'))
        import compute_logicals
        dense=lambda rr:[[(r >> j)&1 for j in range(n)] for r in rr]
        gx,gz=compute_logicals.css_logical_bitset_rows(dense(hx),dense(hz))
        pack=lambda rr:[sum(int(v) << j for j,v in enumerate(r)) for r in rr]
        matrices=[hx,hz,pack(gx),pack(gz)]
        actual=[]
        for rows in matrices[2:]:
            w=min(rows,key=lambda r:bin(r).count('1'))
            actual.append(dict(weight=bin(w).count('1'),support=[j for j in range(n) if (w >> j)&1]))
        construction=dict(stem='LP_36_2_unknown',actual_basis_words_GxGz=actual)
        case.update(id='tiny',conditional_construction_interval=[1,n],reference_exact=None)
        upper=min(x['weight'] for x in actual)
        with self.assertRaisesRegex(ValueError,'actual word disagree'):
            logaudit.assess(case,n,matrices,construction,{'maxsat':f'c d_lb: {upper+1}\nc d_ub: {n}\n'})
        result=logaudit.assess(case,n,matrices,construction,{'maxsat':'c d_lb: 1\nc d_ub: 36\n'})
        self.assertEqual(result['engines']['maxsat']['ub'],36)
        self.assertEqual(result['actual_verified_upper'],upper)

    def test_log_audit_invalid_actual_word_mutant(self):
        case=dict(conditional_construction_interval=[1,4],reference_exact=None,id='tiny')
        construction=dict(stem='tiny',actual_basis_words_GxGz=[dict(weight=1,support=[0]),dict(weight=1,support=[0])])
        with self.assertRaises(ValueError):logaudit.assess(case,4,[[3],[3],[12],[12]],construction,{})

    def test_small_complete_logical_and_entry_mutations(self):
        case=dict(id='tiny',n1=3,n2=3,c=2,chi=1,h1=[0,1],h2=[0,1],
                  n=36,k=2,reference_exact=None,conditional_construction_interval=[6,6])
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)
            stem=gen.generate(case,out)
            self.assertEqual(audit.audit_case(case,out)['rank_pairing'],2)
            with self.assertRaises(FileExistsError):gen.generate(case,out)
            p=out/f'{stem}_Gx.txt'
            saved=p.read_text()
            lines=saved.splitlines()
            p.write_text(lines[0]+'\n'+'0 '*35+'1\n'+'\n'.join(lines[2:])+'\n')
            with self.assertRaises(ValueError):audit.audit_case(case,out)
            p.write_text(saved)
            p=out/f'{stem}_Hx.txt'
            lines=p.read_text().splitlines()
            bits=lines[1].split();bits[0]=str(1-int(bits[0]));lines[1]=' '.join(bits)
            p.write_text('\n'.join(lines)+'\n')
            with self.assertRaisesRegex(ValueError,'physical stabilizer entry'):
                audit.audit_case(case,out)


if __name__=='__main__':
    unittest.main()
