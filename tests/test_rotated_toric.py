#!/usr/bin/env python3
"""Exact, solver-independent checks of the bundled rotated-toric fixture."""
from pathlib import Path
import sys
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts/codegen'))
import validate_css as css


class RotatedToricTests(unittest.TestCase):
    def setUp(self):
        self.n, self.matrices = css.read_code(
            ROOT / 'data/matrices/untiered', 'TORIC_10_2_3')

    def test_css_and_logical_bases(self):
        result = css.validate(self.n, self.matrices)
        self.assertEqual((result['n'], result['k'], result['rank_Hx'],
                          result['rank_Hz']), (10, 2, 4, 4))
        self.assertTrue(all(row.bit_count() == 4
                            for rows in self.matrices[:2] for row in rows))

    def test_exact_distance_both_halves(self):
        hx, hz, gx, gz = self.matrices
        # Enumerate the stabilizer spans directly, independently of elimination.
        def span(rows):
            words = {0}
            for row in rows:
                words |= {word ^ row for word in words}
            return words
        for parity, stabilizers in ((hx, hz), (hz, hx)):
            stabilizer_span = span(stabilizers)
            logicals = [word for word in range(1 << self.n)
                        if all((word & row).bit_count() % 2 == 0 for row in parity)
                        and word not in stabilizer_span]
            self.assertEqual(min(word.bit_count() for word in logicals), 3)
            self.assertEqual(len(logicals), 48)


    @unittest.skipUnless((ROOT / 'bin/distqldpc').is_file(), 'build bin/distqldpc first')
    def test_solver_engines(self):
        for engine in ('cc', 'maxsat'):
            with self.subTest(engine=engine):
                run = subprocess.run(
                    [str(ROOT / 'bin/distqldpc'), '-engine=' + engine,
                     str(ROOT / 'data/matrices/untiered/TORIC_10_2_3')],
                    capture_output=True, text=True, timeout=20)
                self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
                self.assertIn('o 3', run.stdout.splitlines())


if __name__ == '__main__':
    unittest.main()
