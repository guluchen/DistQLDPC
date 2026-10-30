"""Independent QR cyclic ideals, physical lower proofs and scientific log gates."""
import copy
import json
from pathlib import Path
import random
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import qr
import validate_qr as audit
import validate_css as css
import audit_qr_smoke as logs
import smoke_untiered as smoke


class QRTests(unittest.TestCase):
    def test_all_frozen_physical_ideals_and_lower_certificates(self):
        for case in qr.CASES:
            n,h,receipt=qr.checks(case)
            expected,proof=audit.reconstruct(n)
            self.assertEqual(h,expected)
            self.assertEqual(receipt['selected_shifts'],proof['selected_shifts'])
            self.assertEqual(proof['certificate_lower'],case['published_lower'])
            self.assertEqual(n-2*proof['rank'],1)

    def test_complete_logical_and_actual_input_contracts(self):
        for case in qr.CASES:
            result=audit.audit_case(case,ROOT/'data/matrices/untiered')
            self.assertEqual(result['checks'],'PASS')
            self.assertEqual(result['tiny_anchor_independent_exact'],case['published_exact'])

    def test_tiny_random_odd_cosets_obey_literal_correlation(self):
        rng=random.Random(208)
        for n in (7,23,31,47):
            _,h,_=qr.checks(dict(n=n,k=1,id='tiny'))
            for _ in range(8):
                w=(1 << n)-1
                for row in h:
                    if rng.randrange(2):w^=row
                support=[i for i in range(n) if (w >> i)&1]
                self.assertTrue(all(c%2==1 for c in audit.correlation(support,n)))
                self.assertEqual(len(support)%4,3)
                self.assertGreaterEqual(len(support),audit.floor_bound(n))
                self.assertFalse(css.contains(css.basis(h),w))

    def test_tiny_full_steane_coset_minimum(self):
        _,h,_=qr.checks(dict(n=7,k=1,id='tiny'))
        coset=[127]
        for row in h:coset += [w^row for w in coset]
        self.assertEqual(len(coset),8)
        self.assertEqual(min(bin(w).count('1') for w in coset),3)

    def test_wrong_css_prime_or_composite_length(self):
        for n in (5,17,15,39,87,3007):
            with self.assertRaises(ValueError):qr.checks(dict(n=n,k=1,id='bad'))
            with self.assertRaises(ValueError):audit.reconstruct(n)

    def test_wrong_quantum_dimension_stops_before_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):qr.generate(dict(n=23,k=2,id='bad'),Path(directory))
            self.assertFalse(list(Path(directory).iterdir()))

    def test_physical_entry_mutant(self):
        _,h,_=qr.checks(dict(n=23,k=1,id='tiny'));bad=h.copy();bad[0]^=1
        with self.assertRaises(ValueError):audit.physical_certificate(23,bad,h)

    def test_physical_reordering_mutant(self):
        _,h,_=qr.checks(dict(n=23,k=1,id='tiny'));bad=h[::-1]
        with self.assertRaises(ValueError):audit.physical_certificate(23,bad,bad)

    def test_missing_cyclic_generator_mutant(self):
        _,h,_=qr.checks(dict(n=23,k=1,id='tiny'))
        with self.assertRaises(ValueError):audit.physical_certificate(23,h[:-1],h[:-1])

    def test_nontrivial_even_basis_cannot_be_a_logical(self):
        n,h,_=qr.checks(dict(n=23,k=1,id='tiny'))
        with self.assertRaises(ValueError):css.validate(n,[h,h,[h[0]],[h[0]]])

    def test_generator_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory);case=dict(n=7,k=1,id='tiny')
            qr.generate(case,path)
            with self.assertRaises(FileExistsError):qr.generate(case,path)

    def test_literal_polynomial_remainder(self):
        self.assertEqual(audit.remainder(0b10101,0b111),0)
        self.assertEqual(audit.gcd(0b10000001,0b10111),0b10111)

    def test_search_lower_never_filled_from_theorem(self):
        case=qr.CASES[1]
        n,matrices=css.read_code(ROOT/'data/matrices/untiered','QR_431_1_unknown')
        construction=audit.audit_case(case,ROOT/'data/matrices/untiered')
        observed=logs.assess(case,n,matrices,construction,{'maxsat':'c d_lb: 3\nc d_ub: 107\ns UNKNOWN\n'})
        # Use native observed syntax through the shared parser without making
        # any assumption that an independently proven source floor was searched.
        self.assertEqual(observed['engines']['maxsat']['lb'],3)
        self.assertNotEqual(observed['engines']['maxsat']['lb'],case['published_lower'])

    def test_missing_numeric_and_source_upper_target_separate(self):
        case=qr.CASES[1]
        n,matrices=css.read_code(ROOT/'data/matrices/untiered','QR_431_1_unknown')
        construction=audit.audit_case(case,ROOT/'data/matrices/untiered')
        observed=logs.assess(case,n,matrices,construction,
                             {'maxsat':'c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n'})
        self.assertIsNone(observed['engines']['maxsat']['lb'])
        self.assertIsNone(observed['engines']['maxsat']['ub'])
        self.assertEqual(observed['source_upper_word_gate'],'NOT_APPLICABLE')
        self.assertEqual(observed['numeric_smoke_gate'],'INCOMPLETE')

    def test_exact_answer_without_minimum_word_rejected(self):
        case=qr.CASES[1]
        n,matrices=css.read_code(ROOT/'data/matrices/untiered','QR_431_1_unknown')
        construction=audit.audit_case(case,ROOT/'data/matrices/untiered')
        with self.assertRaises(ValueError):logs.assess(case,n,matrices,construction,{'maxsat':'o 23\n'})


if __name__=='__main__':unittest.main()
