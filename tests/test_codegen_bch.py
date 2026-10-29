#!/usr/bin/env python3
"""Independent field/root/dual/logical/source-bound contracts; no solver runs."""
from pathlib import Path
import random
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import bch as gen
import validate_bch as audit
import validate_css as css
import smoke_untiered as smoke
import audit_bch_smoke as logaudit

TINY=dict(id='tiny7',n=7,m=3,primitive_polynomial=11,delta=3,k=1,
          published_lower=3,published_exact=3,anchor_support=[0,1,3])


class BCHTests(unittest.TestCase):
    def test_all_frozen_entries_against_independent_root_kernel(self):
        for c in gen.CASES:
            n,hx,hz,receipt=gen.checks(c)
            expected,roots,g=audit.reconstruct(c)
            self.assertEqual(hx,expected);self.assertEqual(hz,expected)
            self.assertEqual(g,receipt['generator_polynomial'])
            self.assertEqual(n-2*len(css.basis(roots)),c['k'])
            self.assertEqual(audit.source_hypotheses(c)['defining_set'],receipt['defining'])

    def test_complete_field_group_and_smallest_polynomial(self):
        for m,p in ((8,285),(10,1033),(12,4179)):
            self.assertEqual(gen.first_primitive(m),p)
            self.assertTrue(audit.irreducible(p))
            self.assertEqual(gen.primitive_cycle(m,p),audit.field_table(m,p))

    def test_random_tiny_css_entries_and_commutation(self):
        rng=random.Random(207)
        for _ in range(30):
            m=rng.choice([3,4,5,6]);n=(1 << m)-1
            delta=rng.choice(list(range(2,(1 << ((m+1)//2)))))
            p=gen.first_primitive(m);k=n-2*m*(delta//2)
            c=dict(n=n,m=m,primitive_polynomial=p,delta=delta,k=k)
            nn,hx,hz,receipt=gen.checks(c)
            expected,root_rows,g=audit.reconstruct(c)
            self.assertEqual(nn,n);self.assertEqual(hx,expected);self.assertEqual(hz,expected)
            self.assertEqual(g,receipt['generator_polynomial'])
            self.assertFalse(any(css.dot(x,z) for x in hx for z in hz))

    def test_independent_multiplication_random_elements(self):
        rng=random.Random(2071)
        for m in range(3,9):
            p=gen.first_primitive(m)
            for _ in range(20):
                a,b=rng.randrange(1 << m),rng.randrange(1 << m)
                self.assertEqual(gen.gf_mul(a,b,p),audit.remainder(audit.product(a,b),p))

    def test_irreducible_but_nonprimitive_modulus_rejected(self):
        self.assertTrue(audit.irreducible(0x11b))
        with self.assertRaises(ValueError):gen.primitive_cycle(8,0x11b)
        with self.assertRaises(ValueError):audit.field_table(8,0x11b)

    def test_reducible_modulus_rejected(self):
        self.assertFalse(audit.irreducible(0x15))
        with self.assertRaises(ValueError):gen.primitive_cycle(4,0x15)
        with self.assertRaises(ValueError):audit.field_table(4,0x15)

    def test_wrong_root_order_or_source_range_rejected(self):
        for c in (dict(TINY,n=9),dict(TINY,delta=5),dict(TINY,m=4,primitive_polynomial=19),dict(TINY,n=6)):
            with self.assertRaises(ValueError):gen.checks(c)

    def test_dimension_guard_before_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'new'
            with self.assertRaisesRegex(ValueError,'actual dimension'):
                gen.generate(dict(TINY,k=3),out)
            self.assertFalse(out.exists())

    def test_reciprocity_omission_mutant_caught_by_physical_source(self):
        c=gen.CASES[0];n,hx,_,info=gen.checks(c)
        dual=hx[0];degree=dual.bit_length()-1
        wrong=sum(((dual >> i)&1) << (degree-i) for i in range(degree+1))
        self.assertNotEqual([wrong << i for i in range(info['rank'])],audit.reconstruct(c)[0])

    def test_consecutive_root_and_even_design_equivalence(self):
        c=dict(TINY,delta=2)
        self.assertEqual(gen.checks(c)[1:3],gen.checks(TINY)[1:3])
        self.assertTrue({1,2,4}.issubset(set(gen.checks(c)[3]['defining'])))

    def test_invalid_polynomial_inputs(self):
        for m,p in ((1,3),(13,8195),(3,-11),(3,10),(3,19)):
            with self.assertRaises(ValueError):gen.primitive_cycle(m,p)
        with self.assertRaises(ValueError):gen.divide(1,0)

    def test_polynomial_division_reconstructs_binary_product(self):
        rng=random.Random(2072)
        for _ in range(30):
            q,d=rng.randrange(1,256),rng.randrange(1,256)
            numerator=audit.product(q,d)
            self.assertEqual(gen.divide(numerator,d),(q,0))

    def test_tiny_complete_logicals_word_and_byte_reproduction(self):
        with tempfile.TemporaryDirectory() as aa,tempfile.TemporaryDirectory() as bb:
            a,b=Path(aa),Path(bb)
            receipt=gen.generate(TINY,a);gen.generate(TINY,b)
            result=audit.audit_case(TINY,a)
            self.assertEqual(result['rank_pairing'],1)
            self.assertEqual(result['actual_verified_upper'],3)
            for p in a.glob('*.txt'):self.assertEqual(p.read_bytes(),(b/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(TINY,a)

    def test_actual_physical_entry_mutant(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory);stem=gen.generate(TINY,out)['stem']
            p=out/f'{stem}_Hx.txt';lines=p.read_text().splitlines()
            row=lines[1].split();row[0]=str(1-int(row[0]));lines[1]=' '.join(row)
            p.write_text('\n'.join(lines)+'\n')
            with self.assertRaisesRegex(ValueError,'physical dual-polynomial entries'):
                audit.audit_case(TINY,out)

    def test_invalid_logical_basis_mutant(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory);stem=gen.generate(TINY,out)['stem']
            p=out/f'{stem}_Gx.txt';p.write_text('# invalid\n0 0 0 0 0 0 0\n')
            with self.assertRaises(ValueError):audit.audit_case(TINY,out)

    def test_source_lower_not_inserted_into_observed_lower(self):
        result=smoke.parse_claim('c d_lb: 3\nc d_ub: 14\n','>= 9 (construction)',341)
        self.assertEqual(result,dict(lb=3,ub=14,status='BOUNDED'))

    def test_source_lower_violation_stops(self):
        for text in ('c d_lb: 3\nc d_ub: 8\n','c d_lb: 3\nc d_ub: 10\no 8\n'):
            with self.assertRaises(ValueError):smoke.parse_claim(text,'>= 9',341)

    def test_source_lower_does_not_fill_missing_bounds(self):
        text='s UNKNOWN\nc status: TIMEOUT (child killed after -cpu-lim)\n'
        self.assertEqual(smoke.parse_claim(text,'>= 9',341),dict(lb=None,ub=None,status='TIMEOUT_NO_BOUNDS'))

    def test_source_exact_control_protected(self):
        for text in ('c d_lb: 6\nc d_ub: 9\n','c d_lb: 3\nc d_ub: 4\n','c d_lb: 3\nc d_ub: 6\no 6\n'):
            with self.assertRaises(ValueError):smoke.parse_claim(text,'exact 5',85)

    def test_explicit_exact_answer_cannot_exceed_actual_word(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory);gen.generate(TINY,out)
            c=audit.audit_case(TINY,out)
            n,matrices=css.read_code(out,c['stem'])
            weaker=dict(TINY,published_exact=None,published_lower=1)
            with self.assertRaisesRegex(ValueError,'actual-word bounds contradict'):
                logaudit.assess(weaker,n,matrices,c,{'maxsat':'c d_lb: 1\nc d_ub: 6\no 4\n'})

    def test_lower_only_has_no_source_upper_target(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory);gen.generate(TINY,out);c=audit.audit_case(TINY,out)
            n,matrices=css.read_code(out,c['stem'])
            lower=dict(TINY,published_exact=None)
            r=logaudit.assess(lower,n,matrices,c,{'maxsat':'c d_lb: 1\nc d_ub: 6\n'})
            self.assertEqual(r['source_upper_word_gate'],'NOT_APPLICABLE')
            self.assertEqual(r['engines']['maxsat']['lb'],1)
            self.assertEqual(r['actual_verified_upper'],3)

    def test_unmaterialized_reported_upper_is_not_promoted(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory);gen.generate(TINY,out);c=audit.audit_case(TINY,out)
            n,matrices=css.read_code(out,c['stem'])
            weaker=dict(TINY,published_exact=None,published_lower=1)
            r=logaudit.assess(weaker,n,matrices,c,{'maxsat':'c d_lb: 1\nc d_ub: 2\n'})
            self.assertEqual(r['engines']['maxsat']['ub'],2)
            self.assertEqual(r['actual_verified_upper'],3)
            self.assertEqual(r['reported_upper_word_gate'],'INCOMPLETE')

    def test_invalid_emitted_word_stops(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory);gen.generate(TINY,out);c=audit.audit_case(TINY,out)
            n,matrices=css.read_code(out,c['stem'])
            with self.assertRaises(ValueError):
                logaudit.assess(TINY,n,matrices,c,{'maxsat':'c d_lb: 1\nc d_ub: 6\nc witness X: 0 0 1\n'})


if __name__=='__main__':unittest.main()
