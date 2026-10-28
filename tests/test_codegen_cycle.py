#!/usr/bin/env python3
"""Independent graph-cycle, HGP and logical-backend correctness checks (GH-154)."""
from collections import deque
from contextlib import redirect_stdout
from io import StringIO
from itertools import combinations
import importlib.util
from pathlib import Path
import random
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def module(name,path):
    spec = importlib.util.spec_from_file_location(name,ROOT/path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


cycle = module('cycle','scripts/codegen/hgp_cycle.py')
check = module('check','scripts/codegen/validate_css.py')
logical = module('logical','scripts/compute_logicals.py')


def girth(v,edges):
    """Remove each edge, BFS between its endpoints; independent of construction."""
    adjacency = [[] for _ in range(v)]
    for a,b in edges:
        adjacency[a].append(b); adjacency[b].append(a)
    best = None
    for a,b in edges:
        dist = {a:0}; q = deque([a])
        while q:
            x = q.popleft()
            for y in adjacency[x]:
                if (x,y) in ((a,b),(b,a)) or y in dist:
                    continue
                dist[y] = dist[x]+1
                q.append(y)
        if b in dist:
            length = dist[b]+1
            best = length if best is None else min(best,length)
    return best


def dense(n,rows):
    return [[(r>>j)&1 for j in range(n)] for r in rows]


def packed(rows):
    return [sum(x<<j for j,x in enumerate(r)) for r in rows]


class CycleTests(unittest.TestCase):
    def test_classical_cycle_distance_exhaustive(self):
        # At most 2^16 classical words; independent of the BFS girth oracle.
        for name in cycle.LADDER:
            m,h = cycle.factor(name)
            ker = packed(logical._kernel_gf2_with_n(dense(m,h),m))
            word = 0
            distance = m+1
            for i in range(1,1<<len(ker)):
                word ^= ker[(i & -i).bit_length()-1]
                distance = min(distance,bin(word).count('1'))
            self.assertEqual(distance,cycle.EXPECTED[name][2])

    def test_existing_small_css_backend_identity(self):
        for stem in ('LP_34_20_2','TN_36_8_3','BB_72_12_6'):
            directory = ROOT/'data/matrices/tier0'
            hx = logical.load_matrix(directory/f'{stem}_Hx.txt')
            hz = logical.load_matrix(directory/f'{stem}_Hz.txt')
            self.assertEqual(logical.css_logical_bitset_rows(hx,hz),
                             logical.css_logical_nbit_rows(hx,hz))

    def test_graph_parameters_and_full_rank(self):
        for name in cycle.LADDER:
            v,edges = cycle.graph(name)
            self.assertEqual(len(edges),len(set(edges)))
            self.assertTrue(all(a!=b and 0<=a<v and 0<=b<v for a,b in edges))
            self.assertEqual([sum(i in e for e in edges) for i in range(v)],[3]*v)
            seen = {0}
            for _ in range(v):
                seen |= {x for e in edges if any(y in seen for y in e) for x in e}
            self.assertEqual(len(seen),v)
            self.assertEqual(girth(v,edges),cycle.EXPECTED[name][2])
            m,h = cycle.factor(name)
            self.assertEqual(m,len(edges))
            self.assertEqual(len(check.basis(h)),v-1)
            # Omitted incidence row is XOR of the retained rows.
            omitted = sum(1<<j for j,e in enumerate(edges) if v-1 in e)
            total = 0
            for row in h:
                total ^= row
            self.assertEqual(total,omitted)

    def test_bitset_exact_basis_against_dense_random_css(self):
        rng = random.Random(154)
        for _ in range(100):
            n = rng.randrange(2,23)
            hx = dense(n,[rng.getrandbits(n) for _ in range(rng.randrange(1,n+2))])
            ker = logical._kernel_gf2_with_n(hx,n)
            hz = [r[:] for r in ker if rng.randrange(2)]
            if hz:
                hz.append(hz[0][:])
            self.assertEqual(logical.css_logical_bitset_rows(hx,hz),
                             logical.css_logical_nbit_rows(hx,hz))
        for hx,hz in (([],[[0,0,0]]), ([[0,0,0]],[]), ([],[])):
            self.assertEqual(logical.css_logical_bitset_rows(hx,hz),
                             logical.css_logical_nbit_rows(hx,hz))

    def test_cli_basis_bytes_identical(self):
        n,hx,hz = cycle.product(*cycle.factor('k4'))
        with tempfile.TemporaryDirectory() as temp:
            dirs = [Path(temp)/x for x in ('dense','bitset')]
            for out,method in zip(dirs,('dense','bitset')):
                out.mkdir()
                for kind,rows in (('Hx',hx),('Hz',hz)):
                    (out/f'TEST_{kind}.txt').write_text(''.join(' '.join(map(str,r))+'\n' for r in dense(n,rows)))
                with redirect_stdout(StringIO()):
                    self.assertTrue(logical.compute_one(out,'TEST',overwrite=False,dry_run=False,method=method))
            for kind in ('Gx','Gz'):
                self.assertEqual((dirs[0]/f'TEST_{kind}.txt').read_bytes(),
                                 (dirs[1]/f'TEST_{kind}.txt').read_bytes())

    def test_tiny_finite_dimension_hgp_exhaustive(self):
        # Classical [3,2,2] single-parity check -> [[10,4,2]].
        n,hx,hz = cycle.product(3,[7])
        gx,gz = logical.css_logical_bitset_rows(dense(n,hx),dense(n,hz))
        self.assertEqual(check.validate(n,[hx,hz,packed(gx),packed(gz)])['k'],4)
        for parity,stab in ((hx,hz),(hz,hx)):
            span = check.basis(stab)
            distance = min(bin(w).count('1') for w in range(1,1<<n)
                           if not any(check.dot(w,h) for h in parity)
                           and not check.contains(span,w))
            self.assertEqual(distance,2)

    def test_k4_quantum_distance_oracle(self):
        n,hx,hz = cycle.product(*cycle.factor('k4'))
        for parity,stab in ((hx,hz),(hz,hx)):
            span = check.basis(stab)
            for weight in (1,2):
                for support in combinations(range(n),weight):
                    w = sum(1<<j for j in support)
                    self.assertTrue(any(check.dot(w,h) for h in parity) or check.contains(span,w))
        # The classical triangle on vertices 0,1,2 lifted along edge coordinate 0.
        m,h = cycle.factor('k4')
        _,edges = cycle.graph('k4')
        supp = [j for j,e in enumerate(edges) if set(e)<=set((0,1,2))]
        z = sum(1 << (j*m) for j in supp)
        x = sum(1 << j for j in supp)
        self.assertEqual(len(supp),3)
        self.assertFalse(any(check.dot(z,r) for r in hx))
        self.assertFalse(check.contains(check.basis(hz),z))
        self.assertFalse(any(check.dot(x,r) for r in hz))
        self.assertFalse(check.contains(check.basis(hx),x))


if __name__ == '__main__':
    unittest.main()
