#!/usr/bin/env python3
"""Pairing, shift, girth, provenance and GF(2) tests; no external verifier."""
from collections import deque
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
import pair_partition as gen
import validate_pair_partition as independent
import validate_css as css


def all_root_girth(n,rows):
    m=len(rows);graph=[[] for _ in range(m+n)]
    for r,row in enumerate(rows):
        for q in range(n):
            if (row >> q)&1:graph[r].append(m+q);graph[m+q].append(r)
    best=m+n+1
    for root in range(m+n):
        distance=[-1]*(m+n);parent=[-1]*(m+n);distance[root]=0;pending=deque([root])
        while pending:
            u=pending.popleft()
            for v in graph[u]:
                if distance[v]<0:distance[v]=distance[u]+1;parent[v]=u;pending.append(v)
                elif parent[u]!=v and parent[v]!=u:best=min(best,distance[u]+distance[v]+1)
    return best


class PairTests(unittest.TestCase):
    def test_independent_incidence_pairing_and_published_ranks(self):
        for c in gen.CASES:
            n,x,z,matching=gen.checks(c)
            independent.matching_check(c,matching);independent.source_identity(c)
            self.assertEqual((x,z),independent.reconstruct(c))
            self.assertEqual(n-len(css.basis(x))-len(css.basis(z)),c['k'])
            self.assertFalse(any(css.dot(a,b) for a in x for b in z))

    def test_wrong_perfect_matching_mutant(self):
        c=gen.CASES[0];matching=gen.pairing_certificate(c);bad=deepcopy(matching)
        (a,b),(u,v)=bad[0][0][:2];bad[0][0][:2]=[[a,u],[b,v]]
        self.assertEqual(sorted(q for pair in bad[0][0] for q in pair),list(range(c['L'])))
        with self.assertRaisesRegex(ValueError,'mixed-difference'):independent.matching_check(c,bad)

    def test_half_shift_sign_mutant_breaks_css(self):
        c=gen.CASES[2];bad=dict(c,D=[[(-v)%c['P'] for v in row] for row in c['D']])
        x,z=independent.reconstruct(bad)
        self.assertTrue(any(css.dot(a,b) for a in x for b in z))

    def test_global_shift_sign_is_a_coordinate_relabeling(self):
        c=gen.CASES[0];p=c['P'];n,x,z,_=gen.checks(c)
        bad=dict(c,E=[[(-v)%p for v in row] for row in c['E']],D=[[(-v)%p for v in row] for row in c['D']])
        _,xx,zz,_=gen.checks(bad)
        move=lambda row:sum(((row >> q)&1) << ((q//p)*p+(-q%p)) for q in range(n))
        for original,flipped in ((x,xx),(z,zz)):
            self.assertEqual([move(original[(i//p)*p+(-i%p)]) for i in range(len(original))],flipped)

    def test_exponent_and_source_digest_mutants(self):
        c=deepcopy(gen.CASES[0]);c['E'][0][0]=(c['E'][0][0]+1)%c['P']
        with self.assertRaises(ValueError):gen.checks(c)
        with self.assertRaisesRegex(ValueError,'digest'):independent.source_identity(c)
        c=deepcopy(gen.CASES[0]);c['parameter_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'SHA256'):independent.source_identity(c)

    def test_tiny_pairings_girth_matches_all_roots(self):
        rng=random.Random(167)
        for p in (3,5,7):
            c=dict(P=p,J=2,L=6)
            for key in ('E','D'):
                base=[rng.randrange(p) for _ in range(3)];delta=[0,1,rng.randrange(p)]
                c[key]=[[value for value in base for _ in range(2)],
                        [value for value in [(a+d)%p for a,d in zip(base,delta)] for _ in range(2)]]
            n,x,z,matching=gen.checks(c);independent.matching_check(c,matching)
            self.assertEqual((x,z),independent.reconstruct(c))
            self.assertFalse(any(css.dot(a,b) for a in x for b in z))
            for rows in (x,z):
                self.assertEqual(independent.tanner_girth(c,rows)['girth'],all_root_girth(n,rows))

    def test_published_girth_and_cycles(self):
        for c in gen.CASES:
            _,x,z,_=gen.checks(c)
            for rows in (x,z):
                record=independent.tanner_girth(c,rows)
                self.assertEqual(record['girth'],c['girth'])
                self.assertEqual(len(record['cycle_vertices']),c['girth'])

    def test_bad_dimensions_and_nonprime_lift(self):
        for changes in (dict(P=1),dict(P=15),dict(L=7),dict(J=0)):
            with self.assertRaises(ValueError):gen.checks(dict(gen.CASES[0],**changes))
        c=deepcopy(gen.CASES[0]);c['E'][0].pop()
        with self.assertRaises(ValueError):gen.checks(c)

    def test_logical_mutant_rejected(self):
        n,m=css.read_code(ROOT/'data/matrices/untiered','PP_104_30_unknown')
        m[2][0]=0
        with self.assertRaisesRegex(ValueError,'quotient'):css.validate(n,m)

    def test_tiny_exhaustive_support_oracle_and_stabilizer_mutant(self):
        n,x,z,_=gen.checks(gen.CASES[0])
        for a,b in ((x,z),(z,x)):self.assertIsNone(independent.logical_up_to_four(n,a,b))
        self.assertIsNone(independent.logical_up_to_four(2,[3],[3]))
        self.assertEqual(independent.logical_up_to_four(2,[3],[]),3)

    def test_reproduction_and_overwrite(self):
        c=gen.CASES[0]
        with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
            stem=gen.generate(c,Path(a));gen.generate(c,Path(b));independent.certify(c,Path(a),gen.pairing_certificate(c))
            before={p.name:p.read_bytes() for p in Path(a).glob('*.txt')}
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(b).glob('*.txt')})
            with self.assertRaises(FileExistsError):gen.generate(c,Path(a))
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(a).glob('*.txt')})

    def test_smoke_family_isolated(self):
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run',
              '--family','PP','--out','/tmp/unused-pp']
        jobs=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True))
        self.assertEqual({cmd[-1].split('/')[-1] for cmd in jobs},{f'PP_{c["n"]}_{c["k"]}_unknown' for c in gen.CASES})
        self.assertTrue(all(not any(a.startswith('-engine') for a in cmd) for cmd in jobs))


if __name__=='__main__':unittest.main()
