#!/usr/bin/env python3
"""Wedge geometry, tiny distance, Steane equivalence and caught mutants."""
from copy import deepcopy
from itertools import combinations
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import color488 as gen
import validate_color488 as independent
import validate_css as css
from verify_css_witness import verify_witness

CASES=json.loads(gen.CASES.read_text())


class Color488Tests(unittest.TestCase):
    def test_all_fixed_independent_wedges(self):
        for c in CASES:
            n,hx,hz=gen.checks(c['m']);_,_,rows=independent.wedge(c['m'])
            self.assertEqual(hx,rows);self.assertEqual(hz,rows)
            self.assertEqual(n,8*c['m']**2-1)
            self.assertEqual(len(css.basis(hx)),(n-1)//2)

    def test_other_sizes_and_geometry(self):
        for m in (1,4,6,7):
            sites,faces=gen.geometry(m);points,ff,rows=independent.wedge(m)
            self.assertEqual(sites,[(-4*m-1-u,6+2*v) for u,v in points])
            self.assertEqual({frozenset(f) for f in faces},{frozenset((-4*m-1-u,6+2*v) for u,v in f) for f in ff})
            graph=independent.face_graph(rows);colors=independent.three_colors(graph)
            self.assertTrue(all(colors[i]!=colors[j] for i,g in enumerate(graph) for j in g))

    def test_tiny_exhaustive_distance_and_random_relabeling(self):
        n,x,z=gen.checks(1)
        def exact(rows):
            span=css.basis(rows)
            for w in range(1,4):
                for s in combinations(range(n),w):
                    word=sum(1<<q for q in s)
                    if not any(css.dot(word,r) for r in rows) and not css.contains(span,word):return w
        self.assertEqual(exact(x),3)
        order=list(range(n));random.Random(172).shuffle(order)
        move=lambda row:sum(((row>>q)&1)<<order[q] for q in range(n))
        self.assertEqual(exact(list(map(move,x))),3)

    def test_m1_is_existing_steane_after_permutation(self):
        n,x,z=gen.checks(1);nn,m=css.read_code(ROOT/'data/matrices/untiered','COLOR_7_1_unknown')
        def columns(rows):return [sum(((r>>q)&1)<<i for i,r in enumerate(rows)) for q in range(7)]
        a,b=columns(x),columns(m[0]);self.assertEqual(set(a),set(range(1,8)));self.assertEqual(set(b),set(a))
        order=[b.index(t) for t in a]
        move=lambda r:sum(((r>>q)&1)<<order[q] for q in range(7))
        self.assertTrue(css.equal_space(list(map(move,x)),m[0]));self.assertTrue(css.equal_space(list(map(move,z)),m[1]))

    def test_boundary_witness_both_halves_and_full_quotient(self):
        for c in CASES:
            n,m=css.read_code(ROOT/'data/matrices/untiered',f'COLOR_{c["n"]}_1_unknown')
            result=independent.certify(c,n,m)
            self.assertEqual(result['verified_boundary_ub'],c['d'])
            self.assertEqual([w['weight'] for w in result['witnesses'] if w['label']=='right boundary'],[c['d'],c['d']])

    def test_missing_boundary_face_mutant(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered','COLOR_31_1_unknown')
        bad=deepcopy(m);bad[0].pop();bad[1].pop()
        with self.assertRaisesRegex(ValueError,'wedge columns'):independent.certify(c,n,bad)
        with self.assertRaises(ValueError):css.validate(n,bad)

    def test_wrong_coordinate_or_incidence_mutant(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered','COLOR_31_1_unknown')
        bad=deepcopy(m);bad[0][0]^=1
        with self.assertRaises(ValueError):independent.certify(c,n,bad)
        with self.assertRaises(ValueError):css.validate(n,bad)

    def test_stabilizer_word_and_logical_mutants(self):
        n,m=css.read_code(ROOT/'data/matrices/untiered','COLOR_31_1_unknown')
        support=[q for q in range(n) if (m[0][0]>>q)&1]
        with self.assertRaises(ValueError):verify_witness(n,m,'X',support)
        bad=deepcopy(m);bad[2]=m[0][:1]
        with self.assertRaises(ValueError):css.validate(n,bad)

    def test_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            stem=gen.generate(CASES[0],Path(d))
            for p in Path(d).glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],Path(d))
        for m in (0,-1,1.5,True):
            with self.assertRaises(ValueError):gen.geometry(m)

    def test_smoke_explicit_subclass_subset(self):
        stems=[f'COLOR_{c["n"]}_1_unknown' for c in CASES]
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--out','/tmp/unused488','--family','COLOR','--stems']+stems
        jobs=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True));self.assertEqual(len(jobs),6)
        self.assertEqual({x[-1].split('/')[-1] for x in jobs},set(stems))
        self.assertFalse(any('COLOR_7_1_' in x[-1] for x in jobs))


if __name__=='__main__':unittest.main()
