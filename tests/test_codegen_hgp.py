#!/usr/bin/env python3
"""Meaningful construction/verifier tests, including corruption and duplicate mutants."""
import importlib.util
from pathlib import Path
import random
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT/path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


gen = module('hgp', 'scripts/codegen/hgp_repetition.py')
check = module('validator', 'scripts/codegen/validate_css.py')
logicals = module('logicals', 'scripts/compute_logicals.py')
smoke = module('smoke', 'scripts/codegen/smoke_untiered.py')


def bits(rows):
    return [sum(x << j for j,x in enumerate(row)) for row in rows]


def sample(length):
    hx, hz = gen.checks(length)
    gx, gz = logicals.css_logical_nbit_rows(hx,hz)
    return len(hx[0]), list(map(bits, (hx,hz,gx,gz)))


class HGPTests(unittest.TestCase):
    def test_bundled_geometric_witnesses(self):
        for length in gen.LADDER:
            n = length**2+(length-1)**2
            stem = f'HGP_{n}_1_unknown'
            _, matrices = check.read_code(ROOT/'data/matrices/untiered',stem)
            hx,hz,_,_ = matrices
            # First-block straight strings, derived without quotient elimination.
            z = sum(1 << (i*length) for i in range(length))
            x = (1 << length)-1
            self.assertFalse(any(check.dot(z,h) for h in hx))
            self.assertFalse(any(check.dot(x,h) for h in hz))
            self.assertFalse(check.contains(check.basis(hz),z))
            self.assertFalse(check.contains(check.basis(hx),x))
            self.assertEqual(check.dot(z,x),1)
            self.assertEqual(bin(z).count('1'),length)
            self.assertEqual(bin(x).count('1'),length)

    def test_smoke_parser_scientific_failures(self):
        self.assertEqual(smoke.parse('c d_lb: 2\nc d_ub: 3\ns UNKNOWN\n',3),
                         dict(lb=2,ub=3,status='BOUNDED'))
        self.assertEqual(smoke.parse('c d_lb: 3\nc d_ub: 3\no 3\n',3)['status'],'SOLVED')
        for text in ('c d_lb: 4\nc d_ub: 5\n', 'c d_lb: 2\nc d_ub: 2\n',
                     'c d_lb: 2\nc d_ub: 4\no 4\n', 'c d_lb: -\nc d_ub: -\n',
                     'error: missing file\n'):
            with self.assertRaises(ValueError):
                smoke.parse(text,3)

    def test_legitimate_timeout_without_bounds_stays_unknown(self):
        text = 'c d_lb: -\nc d_ub: -\nc status: TIMEOUT (child killed after -cpu-lim)\nc d  : UNKNOWN\ns UNKNOWN\n'
        self.assertEqual(smoke.parse(text,24),dict(lb=None,ub=None,status='TIMEOUT_NO_BOUNDS'))
        self.assertEqual(smoke.parse('c d_ub: 24\n'+text.replace('c d_ub: -\n',''),24),
                         dict(lb=None,ub=24,status='TIMEOUT_PARTIAL_BOUNDS'))
        with self.assertRaises(ValueError):
            smoke.parse('c d_lb: 2\n'+text,24)
        with self.assertRaises(ValueError):
            smoke.parse(text.replace('TIMEOUT (child killed after -cpu-lim)','UNKNOWN'),24)

    def test_tiny_exhaustive_distance(self):
        # Exhaust all 2^13 supports in both quotients, no external solver.
        for length in (2,3):
            n, (hx,hz,gx,gz) = sample(length)
            check.validate(n, [hx,hz,gx,gz])
            for parity, stabilizer in ((hx,hz),(hz,hx)):
                span = check.basis(stabilizer)
                distance = min(bin(v).count('1') for v in range(1,1 << n)
                               if not any(check.dot(v,h) for h in parity)
                               and not check.contains(span,v))
                self.assertEqual(distance,length)

    def test_randomized_label_and_basis_changes(self):
        rng = random.Random(153)
        for length in range(2,7):
            n, matrices = sample(length)
            for _ in range(4):
                perm = list(range(n))
                rng.shuffle(perm)
                transformed = [[sum(((r >> i)&1) << perm[i] for i in range(n))
                                for r in rows] for rows in matrices]
                for rows in transformed[:2]:
                    rng.shuffle(rows)
                    for _ in range(10):
                        a,b = rng.sample(range(len(rows)),2)
                        rows[a] ^= rows[b]
                self.assertEqual(check.validate(n,transformed)['k'],1)

    def test_corruption_mutants(self):
        n, matrices = sample(3)
        mutants = []
        bad = [r[:] for r in matrices]
        bad[0][0] ^= 1
        mutants.append(bad)  # destroys CSS commutation
        bad = [r[:] for r in matrices]
        bad[2] = [bad[1][0]]
        mutants.append(bad)  # replaces logical by a stabilizer
        bad = [r[:] for r in matrices]
        bad[3] = [1]
        mutants.append(bad)  # outside the parity kernel
        for bad in mutants:
            with self.assertRaises(ValueError):
                check.validate(n,bad)
        # k=2 example: each row nontrivial but quotient rows dependent.
        with self.assertRaises(ValueError):
            check.validate(4, [[1],[2],[4,4],[4,8]])

    def test_duplicate_and_swap_mutants(self):
        n, (hx,hz,_,_) = sample(3)
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp)
            def write(kind, rows):
                path = out/f'OTHER_13_1_unknown_{kind}.txt'
                path.write_text(''.join(' '.join(str((r>>j)&1) for j in range(n))+'\n' for r in rows))
                return path
            path = write('Hx',[hz[0]^hz[1]]+hz[1:])
            write('Hz',hx[::-1])
            peers, matches = check.duplicates(n,1,hx,hz,[path],out/'own_Hx.txt')
            self.assertEqual(len(peers),1)
            self.assertEqual(matches,[{'path':str(path),'swap':True}])
            write('Hx',hx[::-1])
            write('Hz',hz)
            _, matches = check.duplicates(n,1,hx,hz,[path],out/'own_Hx.txt')
            self.assertEqual(matches,[{'path':str(path),'swap':False}])

    def test_strict_parser(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)/'matrix.txt'
            for text in ('0 2\n', '0 1\n1\n', '# comment only\n'):
                path.write_text(text)
                with self.assertRaises(ValueError):
                    check.load(path)


if __name__ == '__main__':
    unittest.main()
