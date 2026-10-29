#!/usr/bin/env python3
"""Frozen construction, independent products, tiny units and caught mutants."""
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
import gallager_hgp as gen
import validate_gallager_hgp as independent
from certify_gallager_hgp import classical_distance
import validate_css as css
from verify_css_witness import verify_witness
from smoke_untiered import parse

CASES=json.loads(gen.CASES.read_text())


class GallagerHGPTests(unittest.TestCase):
    def test_frozen_factors_and_independent_columns(self):
        for c in CASES:
            raw,h,selected,perms=gen.factor(c);rr,hh=independent.factors(c)
            self.assertEqual([set(q for q in range(c['classical_n']) if (row>>q)&1) for row in raw],rr)
            self.assertEqual([set(q for q in range(c['classical_n']) if (row>>q)&1) for row in h],hh)
            N,k,x,z=gen.checks(c);self.assertEqual((x,z),independent.reconstruct(c))
            self.assertEqual((N,k),(c['n'],c['k']))

    def test_actual_full_quotients_and_upper_words(self):
        for c in CASES:
            N,m=css.read_code(ROOT/'data/matrices/untiered',f'HGP_{c["n"]}_{c["k"]}_unknown')
            result=independent.certify(c,N,m)
            self.assertEqual(result['verified_algebraic_ub'],c['classical_n'])
            self.assertLessEqual(max(result['quantum_row_weights']),7)

    def test_hash_shuffle_and_sparse_basis_mutants(self):
        c=deepcopy(CASES[1]);c['permutations'][1][0],c['permutations'][1][1]=c['permutations'][1][1],c['permutations'][1][0]
        with self.assertRaises(ValueError):gen.factor(c)
        with self.assertRaises(ValueError):independent.factors(c)
        c=deepcopy(CASES[1]);c['selected_rows'][0]=c['selected_rows'][1]
        with self.assertRaises(ValueError):gen.factor(c)
        with self.assertRaises(ValueError):independent.factors(c)

    def test_wrong_incidence_and_stabilizer_logical_mutants(self):
        c=CASES[0];N,m=css.read_code(ROOT/'data/matrices/untiered',f'HGP_{c["n"]}_{c["k"]}_unknown')
        wrong=deepcopy(m);wrong[0][0]^=1
        with self.assertRaises(ValueError):independent.certify(c,N,wrong)
        wrong=deepcopy(m);wrong[2][0]=m[1][0]
        with self.assertRaises(ValueError):css.validate(N,wrong)
        support=[q for q in range(N) if (m[1][0]>>q)&1]
        with self.assertRaises(ValueError):verify_witness(N,m,'Z',support)

    def test_tiny_classical_oracle_against_all_supports(self):
        rng=random.Random(173)
        for n in range(4,9):
            for _ in range(5):
                rows=[{q for q in range(n) if rng.randrange(2)} for i in range(2)]
                proof=classical_distance(n,rows)
                codes=[w for w in range(1<<n) if not any(sum((w>>q)&1 for q in row)%2 for row in rows)]
                self.assertEqual(proof['enumerated_codewords'],len(codes))
                self.assertEqual(proof['distance'],min(bin(w).count('1') for w in codes if w))
                self.assertEqual({int(w):count for w,count in proof['weight_enumerator'].items()},
                                 {w:sum(bin(x).count('1')==w for x in codes) for w in {bin(x).count('1') for x in codes}})

    def test_tiny_product_distance_and_duality(self):
        c=dict(classical_n=4,seed=0,j=3,check_weight=4);N,k,x,z=gen.checks(c)
        def search(parity,stab):
            span=css.basis(stab)
            for weight in (1,2):
                for support in combinations(range(N),weight):
                    word=sum(1<<q for q in support)
                    if not any(css.dot(word,r) for r in parity) and not css.contains(span,word):return weight
        self.assertEqual(search(x,z),2);self.assertEqual(search(z,x),2)
        raw,h,idx,ps=gen.factor(c);self.assertEqual(classical_distance(4,[{q for q in range(4) if (r>>q)&1} for r in raw])['distance'],2)

    def test_deterministic_stream_and_invalid_lengths(self):
        self.assertEqual(gen.permutation(20,0,1),gen.permutation(20,0,1))
        self.assertNotEqual(gen.permutation(20,0,1),gen.permutation(20,0,2))
        for n in (0,3,10):
            with self.assertRaises(ValueError):gen.factor(dict(classical_n=n,seed=0,j=3,check_weight=4))

    def test_reproduction_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            stem=gen.generate(CASES[0],Path(d))
            for p in Path(d).glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],Path(d))

    def test_explicit_hgp_subclass_smoke_subset(self):
        stems=[f'HGP_{c["n"]}_{c["k"]}_unknown' for c in CASES]
        cmd=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--out','/tmp/unused-gallager','--stems']+stems
        jobs=json.loads(subprocess.check_output(cmd,cwd=ROOT,text=True))
        self.assertEqual({x[-1].split('/')[-1] for x in jobs},set(stems));self.assertEqual(len(jobs),6)
        self.assertTrue(all('-engine=cc' not in x for x in jobs))

    def test_upper_only_claim_and_absent_bounds_are_not_exact(self):
        self.assertEqual(parse('c d_lb: 2\nc d_ub: 2\no 2\n',44,exact=False)['status'],'SOLVED')
        text='c d_lb: -\nc d_ub: -\nc status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n'
        self.assertEqual(parse(text,44,exact=False)['lb'],None)
        with self.assertRaises(ValueError):parse('c d_lb: 5\nc d_ub: 4\n',44,exact=False)


if __name__=='__main__':unittest.main()
