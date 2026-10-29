#!/usr/bin/env python3
"""Group/action/CSS/claim invariants and mutants for the ZSZ-LP package."""
from copy import deepcopy
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
import zsz_lp as gen
import validate_zsz_lp as independent
import validate_css as css
from smoke_untiered import parse
from verify_css_witness import verify_witness


class ZszTests(unittest.TestCase):
    def test_independent_permutations_all_published_cases(self):
        for c in gen.CASES:
            n,x,z,seeds=gen.checks(c)
            self.assertEqual((x,z),independent.reconstruct(c))
            self.assertEqual(n-len(css.basis(x))-len(css.basis(z)),c['k'])
            self.assertEqual({len(css.basis(s)) for s in seeds.values()},{n//5})
            self.assertFalse(any(css.dot(a,b) for a in x for b in z))

    def test_group_associativity_small_exhaustive_and_all_random(self):
        c=gen.CASES[0];points=[(a,b) for a in range(c['l1']) for b in range(c['l2'])]
        for a in points:
            for b in points:
                for d in points:self.assertEqual(gen.multiply(c,gen.multiply(c,a,b),d),gen.multiply(c,a,gen.multiply(c,b,d)))
        rng=random.Random(166)
        for c in gen.CASES:
            for _ in range(50):
                a,b,d=[(rng.randrange(c['l1']),rng.randrange(c['l2'])) for _ in range(3)]
                self.assertEqual(gen.multiply(c,gen.multiply(c,a,b),d),gen.multiply(c,a,gen.multiply(c,b,d)))

    def test_presentation_inverses_and_noncommutativity(self):
        for c in gen.CASES:
            x,y=(1,0),(0,1)
            self.assertNotEqual(gen.multiply(c,x,y),gen.multiply(c,y,x))
            self.assertEqual(gen.multiply(c,y,gen.multiply(c,x,gen.inverse(c,y))),(c['q'],0))
            for g in ((0,0),(1,1),(c['l1']-1,c['l2']-1)):
                self.assertEqual(gen.multiply(c,g,gen.inverse(c,g)),(0,0))
                l=gen.regular(c,[g],True);r=gen.regular(c,[g],False)
                self.assertEqual(gen.transpose(l),gen.regular(c,[gen.inverse(c,g)],True))
                self.assertEqual(gen.transpose(r),gen.regular(c,[gen.inverse(c,g)],False))

    def test_abelian_and_wrong_group_parameter_mutants(self):
        c=dict(gen.CASES[0],q=1)
        with self.assertRaisesRegex(ValueError,'nonabelian'):independent.reconstruct(c)
        with self.assertRaises(ValueError):gen.parameters(dict(c,q=2))
        self.assertNotEqual(gen.checks(c)[1:3],gen.checks(gen.CASES[0])[1:3])

    def test_replacing_right_action_with_left_breaks_css(self):
        c=gen.CASES[1];size=c['l1']*c['l2']
        a,b=gen.regular(c,c['a'],True),gen.regular(c,c['b'],True)
        cc,d=gen.regular(c,c['c'],True),gen.regular(c,c['dpoly'],True)
        at,bt,ct,dt=map(gen.transpose,(a,b,cc,d))
        x=[a[i]|(b[i] << 2*size)|(ct[i] << 4*size) for i in range(size)]
        x += [(a[i] << size)|(b[i] << 3*size)|(dt[i] << 4*size) for i in range(size)]
        z=[cc[i]|(d[i] << size)|(at[i] << 4*size) for i in range(size)]
        z += [(cc[i] << 2*size)|(d[i] << 3*size)|(bt[i] << 4*size) for i in range(size)]
        self.assertTrue(any(css.dot(u,v) for u in x for v in z))

    def test_gf2_polynomial_collisions(self):
        c=gen.CASES[0]
        for left in (True,False):
            self.assertEqual(gen.regular(c,[[0,0],[c['l1'],0]],left),[0]*c['k'])
            dense=independent.polynomial(c,[[0,0],[0,c['l2']]],left)
            self.assertTrue(all(not any(row) for row in dense))

    def test_claim_semantics_and_observed_bounds(self):
        def timeout(lb,ub):return f'c d_lb: {lb}\nc d_ub: {ub}\nc status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n'
        self.assertEqual(parse(timeout(0,30),22,exact=False),dict(lb=0,ub=30,status='BOUNDED'))
        self.assertEqual(parse('c d_lb: 18\nc d_ub: 18\no 18\n',22,exact=False)['status'],'SOLVED')
        self.assertEqual(parse(timeout('-','-'),22,exact=False)['status'],'TIMEOUT_NO_BOUNDS')
        for raw,exact in ((timeout(23,30),False),(timeout(5,13),True),('c d_lb: 5\nc d_ub: 5\no 5\n',True),
                          ('c d_lb: 20\nc d_ub: 30\no 19\n',False),(timeout(5,0),False)):
            with self.assertRaises(ValueError):parse(raw,14 if exact else 22,exact=exact)

    def test_witness_stabilizer_syndrome_and_support_mutants(self):
        matrices=[[3],[],[3],[1]];verify_witness(2,matrices,'X',[0])
        for half,support in (('X',[0,1]),('Z',[0]),('X',[0,0]),('X',[2])):
            with self.assertRaises(ValueError):verify_witness(2,matrices,half,support)

    def test_upper_claim_audit_uses_actual_exact_answer(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);mat=root/'mat';mat.mkdir();stem='LP_3_1_unknown'
            for kind,text in (('Hx','1 1 0\n'),('Hz','1 1 0\n'),('Gx','0 0 1\n'),('Gz','0 0 1\n')):
                (mat/f'{stem}_{kind}.txt').write_text(text)
            hashes={kind:hashlib.sha256((mat/f'{stem}_{kind}.txt').read_bytes()).hexdigest() for kind in ('Hx','Hz','Gx','Gz')}
            for engine in ('maxsat','cc'):
                d=root/engine;d.mkdir()
                (d/(stem+'.log')).write_text('c witness X: 2\nc d_lb: 1\nc d_ub: 1\no 1\n')
                (d/(stem+'.json')).write_text(json.dumps(dict(lb=1,ub=1,status='SOLVED',cmd=['-engine=cc'] if engine=='cc' else [],input_sha256=hashes,source_head='synthetic-fixture',binary_sha256='synthetic-fixture')))
            (root/'cases.json').write_text(json.dumps([dict(n=3,k=1,d=2,claim='upper')]))
            argv=[sys.executable,str(ROOT/'scripts/codegen/audit_zsz_smoke.py'),'--cases',str(root/'cases.json'),
                  '--matrices',str(mat),'--maxsat',str(root/'maxsat'),'--cc',str(root/'cc'),'--out',str(root/'audit.json')]
            subprocess.run(argv,check=True,capture_output=True)
            result=json.loads((root/'audit.json').read_text())[0]
            self.assertEqual(result['engines']['maxsat']['lb'],1)
            self.assertEqual(result['published_d'],2)
            self.assertTrue(result['reference_upper_witness_reproduced'])
            self.assertIsNone(result['reference_exact_reproduced'])
            self.assertEqual(result['scientific_status'],'CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS')
            (root/'cc'/(stem+'.log')).write_text('c witness X: 2\nc d_lb: 2\nc d_ub: 2\no 2\n')
            self.assertNotEqual(subprocess.run(argv,capture_output=True).returncode,0)

    def test_reproduction_and_overwrite(self):
        c=gen.CASES[0]
        with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
            stem=gen.generate(c,Path(a));gen.generate(c,Path(b))
            before={p.name:p.read_bytes() for p in Path(a).glob('*.txt')}
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(b).glob('*.txt')})
            independent.certify(c,Path(a))
            with self.assertRaises(FileExistsError):gen.generate(c,Path(a))
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(a).glob('*.txt')})

    def test_smoke_family_selection_and_default_argv(self):
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--family','LP','--out','/tmp/unused-zsz']
        commands=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True))
        self.assertEqual({cmd[-1].split('/')[-1] for cmd in commands},{f'LP_{c["n"]}_{c["k"]}_unknown' for c in gen.CASES})
        self.assertTrue(all(not any(a.startswith('-engine') for a in cmd) for cmd in commands))
        cc=json.loads(subprocess.check_output(argv+['--engine','cc'],cwd=ROOT,text=True))
        self.assertTrue(all('-engine=cc' in cmd for cmd in cc))


if __name__=='__main__':unittest.main()
