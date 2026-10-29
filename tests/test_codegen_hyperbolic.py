#!/usr/bin/env python3
"""Quotient, manifold, tiny homology and mutation checks (no external solver)."""
from copy import deepcopy
from itertools import combinations
import hashlib
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import hyperbolic_surface as gen
import validate_hyperbolic as independent
import validate_css as css


class HyperbolicTests(unittest.TestCase):
    def test_surface_witness_audit_and_smoke_family(self):
        stem='HYP_60_8_unknown';n,m=css.read_code(ROOT/'data/matrices/untiered',stem)
        witnesses=dict(stem=stem,primal_Z=independent.shortest_cycle(n,m[0],m[1],m[3]),
                       dual_X=independent.shortest_cycle(n,m[1],m[0],m[2]))
        hashes={kind:hashlib.sha256((ROOT/f'data/matrices/untiered/{stem}_{kind}.txt').read_bytes()).hexdigest()
                for kind in ('Hx','Hz','Gx','Gz')}
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            (root/'independent.json').write_text(json.dumps([witnesses]))
            (root/'cases.json').write_text(json.dumps([gen.CASES[0]]))
            for engine in ('maxsat','cc'):
                d=root/engine;d.mkdir()
                (d/f'{stem}.log').write_text('c d_lb: 4\nc d_ub: 4\no 4\n')
                (d/f'{stem}.json').write_text(json.dumps(dict(lb=4,ub=4,status='SOLVED',
                    cmd=['-engine=cc'] if engine=='cc' else [],input_sha256=hashes,
                    source_head='synthetic-fixture',binary_sha256='synthetic-fixture')))
            argv=[sys.executable,str(ROOT/'scripts/codegen/audit_exact_smoke.py'),'--family','HYP',
                  '--cases',str(root/'cases.json'),'--independent',str(root/'independent.json'),
                  '--maxsat',str(root/'maxsat'),'--cc',str(root/'cc'),'--out',str(root/'audit.json')]
            subprocess.run(argv,check=True,capture_output=True)
            witnesses['dual_X']['support']=[0]
            (root/'independent.json').write_text(json.dumps([witnesses]))
            self.assertNotEqual(subprocess.run(argv,capture_output=True).returncode,0)
        jobs=json.loads(subprocess.check_output([sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),
             '--cpu','0','--dry-run','--family','HYP','--out','/tmp/unused-hyp'],cwd=ROOT,text=True))
        self.assertEqual(len(jobs),sum(c['status']=='READY_FOR_VALIDATION' for c in gen.CASES))
        self.assertTrue(all(cmd[-1].split('/')[-1].startswith('HYP_') for cmd in jobs))

    def test_independent_surface_incidence_and_dimension(self):
        for c in gen.CASES:
            if c['status']!='READY_FOR_VALIDATION':continue
            x,z,data=gen.construction(c);xx,zz,topology=independent.reconstruct(c,data['table'])
            self.assertEqual((x,z),(xx,zz))
            self.assertEqual(c['n']-len(css.basis(x))-len(css.basis(z)),2*topology['genus'])
            self.assertEqual(2*topology['genus'],c['k'])
            self.assertEqual({bin(r).count('1') for r in x},{4})
            self.assertEqual({bin(r).count('1') for r in z},{5})
            self.assertFalse(any(css.dot(a,b) for a in x for b in z))

    def test_relation_scan_order_is_canonical(self):
        for c in gen.CASES[:3]:
            rel=gen.relators(c)
            a,_=gen.Quotient(rel).run();b,_=gen.Quotient(list(reversed(rel))).run()
            self.assertEqual(a,b)

    def test_small_group_and_enumeration_limits(self):
        table,_=gen.Quotient([(0,)*3,(2,)*2,(0,2)*2]).run()
        self.assertEqual(len(table),6)
        with self.assertRaises(RuntimeError):gen.Quotient([(0,)*5,(2,)*4,(0,2)*2],max_states=8).run()
        with self.assertRaises(ValueError):gen.Quotient([],seconds=0)

    def test_extra_relation_mutant_cannot_claim_published_code(self):
        c=dict(gen.CASES[0],words=gen.CASES[0]['words']+['r'])
        with self.assertRaisesRegex(ValueError,'quotient order'):gen.construction(c)

    def test_inverse_and_disconnected_action_mutants(self):
        c=gen.CASES[0];_,_,data=gen.construction(c);table=data['table']
        bad=deepcopy(table);bad[0][0]=0
        with self.assertRaises(ValueError):independent.reconstruct(c,bad)
        doubled=table+[[v+len(table) for v in row] for row in table]
        with self.assertRaisesRegex(ValueError,'disconnected'):independent.reconstruct(dict(c,n=120),doubled)

    def test_incidence_flip_and_singular_logical_mutants(self):
        n,m=css.read_code(ROOT/'data/matrices/untiered','HYP_60_8_unknown')
        bad=deepcopy(m);bad[1][0] ^= 1
        with self.assertRaises(ValueError):css.validate(n,bad)
        bad=deepcopy(m);bad[2][0]=0
        with self.assertRaisesRegex(ValueError,'quotient'):css.validate(n,bad)

    def test_tiny_surface_half_distances_and_relabel(self):
        n,m=css.read_code(ROOT/'data/matrices/untiered','HYP_60_8_unknown')
        self.assertEqual(independent.shortest_cycle(n,m[0],m[1],m[3])['distance'],6)
        self.assertEqual(independent.shortest_cycle(n,m[1],m[0],m[2])['distance'],4)
        order=list(range(n));random.Random(165).shuffle(order)
        move=lambda word:sum(((word >> i)&1) << order[i] for i in range(n))
        relabelled=[list(map(move,rows)) for rows in m]
        self.assertEqual(independent.shortest_cycle(n,relabelled[1],relabelled[0],relabelled[2])['distance'],4)

    def test_graph_oracle_matches_literal_enumeration(self):
        edges=list(combinations(range(4),2));n=len(edges)
        parity=[sum(1 << e for e,pair in enumerate(edges) if v in pair) for v in range(4)]
        stabilizers=[sum(1 << e for e,pair in enumerate(edges) if set(pair)<={0,1,2})]
        # All vectors orthogonal to the stabilizers include a complete detector
        # basis; avoid borrowing the generator's logical construction.
        detectors=[w for w in range(1 << n) if not any(css.dot(w,r) for r in stabilizers)]
        span=css.basis(stabilizers);exact=None
        for weight in range(1,n+1):
            for support in combinations(range(n),weight):
                word=sum(1 << q for q in support)
                if not any(css.dot(word,r) for r in parity) and not css.contains(span,word):exact=weight;break
            if exact is not None:break
        self.assertEqual(independent.shortest_cycle(n,parity,stabilizers,detectors)['distance'],exact)

    def test_graph_oracle_rejects_stabilizer_as_logical(self):
        parity=[5,3,6]
        with self.assertRaisesRegex(ValueError,'invalid BFS logical'):
            independent.shortest_cycle(3,parity,[7],[1])

    def test_pending_case_not_silently_generated(self):
        pending=[c for c in gen.CASES if c['status']!='READY_FOR_VALIDATION']
        for c in pending:
            with self.assertRaisesRegex(ValueError,'PI decision'):gen.construction(c)

    def test_generation_reproduction_and_overwrite(self):
        c=gen.CASES[0]
        with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
            stem=gen.generate(c,Path(a));gen.generate(c,Path(b))
            before={p.name:p.read_bytes() for p in Path(a).glob('*.txt')}
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(b).glob('*.txt')})
            with self.assertRaises(FileExistsError):gen.generate(c,Path(a))
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(a).glob('*.txt')})


if __name__=='__main__':unittest.main()
