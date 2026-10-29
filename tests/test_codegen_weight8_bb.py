#!/usr/bin/env python3
"""Independent incidence, short-word oracle, mutation and reproduction tests."""
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
import weight8_bb as gen
import validate_weight8_bb as independent
import validate_css as css
import audit_exact_smoke as audit


class Weight8Tests(unittest.TestCase):
    def test_two_engine_audit_accepts_one_shared_verified_witness(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);mat=root/'matrices';mat.mkdir();stem='BB_3_1_unknown'
            for kind,text in (('Hx','1 1 0\n'),('Hz','1 1 0\n'),('Gx','0 0 1\n'),('Gz','0 0 1\n')):
                (mat/f'{stem}_{kind}.txt').write_text(text)
            hashes={kind:hashlib.sha256((mat/f'{stem}_{kind}.txt').read_bytes()).hexdigest()
                    for kind in ('Hx','Hz','Gx','Gz')}
            for engine in ('maxsat','cc'):
                d=root/engine;d.mkdir()
                raw=('c witness X (ub-pre): 2\n' if engine=='maxsat' else '')+'c d_lb: 1\nc d_ub: 1\no 1\n'
                (d/f'{stem}.log').write_text(raw)
                (d/f'{stem}.json').write_text(json.dumps(dict(lb=1,ub=1,status='SOLVED',
                    cmd=['-engine=cc'] if engine=='cc' else [],input_sha256=hashes,
                    source_head='fixture-source',binary_sha256='fixture-binary')))
            (root/'cases.json').write_text(json.dumps([dict(n=3,k=1,d=1)]))
            argv=[sys.executable,str(ROOT/'scripts/codegen/audit_exact_smoke.py'),
                  '--maxsat',str(root/'maxsat'),'--cc',str(root/'cc'),'--matrices',str(mat),
                  '--cases',str(root/'cases.json'),'--out',str(root/'audit.json')]
            subprocess.run(argv,check=True,capture_output=True)
            self.assertEqual(json.loads((root/'audit.json').read_text())[0]['verification'],
                             'CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS')
            p=root/'maxsat'/f'{stem}.log';p.write_text('c d_lb: 1\nc d_ub: 1\no 1\n')
            self.assertNotEqual(subprocess.run(argv,capture_output=True).returncode,0)

    def test_witness_audit_rejects_stabilizer_and_bad_syndrome(self):
        matrices=[[3],[],[3],[1]]
        audit.verify_witness(2,matrices,'X',[0])
        for half,support in (('X',[0,1]),('Z',[0]),('X',[0,0]),('X',[2])):
            with self.assertRaises(ValueError):audit.verify_witness(2,matrices,half,support)

    def test_incidence_dimension_and_weights(self):
        for c in gen.CASES:
            n,x,z=gen.checks(c)
            self.assertEqual((x,z),independent.reconstruct(c))
            self.assertEqual(n-len(css.basis(x))-len(css.basis(z)),c['k'])
            self.assertEqual({bin(r).count('1') for r in x+z},{8})
            self.assertFalse(any(css.dot(a,b) for a in x for b in z))

    def test_omitted_transpose_mutant(self):
        c=gen.CASES[2];n,x,_=gen.checks(c);v=n//2;mask=(1 << v)-1
        wrong=[(r >> v)|((r & mask) << v) for r in x]
        self.assertNotEqual(wrong,independent.reconstruct(c)[1])
        self.assertTrue(any(css.dot(a,b) for a in x for b in wrong))

    def test_grid_axis_mutant(self):
        c=gen.CASES[3]
        bad=dict(c,l=c['m'],m=c['l'])
        self.assertNotEqual(gen.checks(bad)[1:],independent.reconstruct(c))

    def test_gf2_collisions_and_negative_powers(self):
        c=dict(l=3,m=5,A=[[0,0],[3,0],[-1,-2]],B=[[0,1],[0,6]])
        n,x,z=gen.checks(c)
        self.assertEqual((x,z),independent.reconstruct(c))
        self.assertEqual({bin(r).count('1') for r in x+z},{1})
        with self.assertRaises(ValueError):gen.checks(dict(c,l=0))

    def test_short_word_oracle_against_direct_enumeration(self):
        rng=random.Random(164)
        # Small arbitrary parity matrices, with stabilizers chosen in the
        # kernel. Compare existence with literal enumeration, including odd words.
        for _ in range(30):
            n=9;parity=[rng.randrange(1 << n) for _ in range(3)]
            closed=[w for w in range(1 << n) if not any(css.dot(w,r) for r in parity)]
            stabilizers=rng.sample(closed,min(3,len(closed)))
            span=css.basis(stabilizers)
            found=[]
            for weight in range(1,5):
                for support in combinations(range(n),weight):
                    w=sum(1 << q for q in support)
                    if not any(css.dot(w,r) for r in parity) and not css.contains(span,w):found.append(w)
            answer=independent.logical_up_to_four(n,parity,stabilizers)
            self.assertEqual(answer is not None,bool(found))
            if answer is not None:self.assertIn(answer,found)

    def test_stabilizer_filter_mutant_is_caught(self):
        # A syndrome-only oracle would wrongly call the weight-2 stabilizer a logical.
        self.assertIsNone(independent.logical_up_to_four(2,[3],[3]))
        self.assertEqual(independent.logical_up_to_four(2,[3],[]),3)

    def test_same_dimension_tanner_is_inequivalent(self):
        n,x,z=gen.checks(gen.CASES[0])
        for a,b in ((x,z),(z,x)):
            self.assertIsNone(independent.logical_up_to_four(n,a,b))
        _,peer=css.read_code(ROOT/'data/matrices/tier0','TN_72_14_4')
        for a,b in ((peer[0],peer[1]),(peer[1],peer[0])):
            word=independent.logical_up_to_four(n,a,b)
            self.assertIsNotNone(word)
            self.assertLessEqual(bin(word).count('1'),4)
            self.assertFalse(any(css.dot(word,r) for r in a))
            self.assertFalse(css.contains(css.basis(b),word))

    def test_reproduction_overwrite_and_smoke_selection(self):
        with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
            c=gen.CASES[0];stem=gen.generate(c,Path(a));gen.generate(c,Path(b))
            before={p.name:p.read_bytes() for p in Path(a).glob('*.txt')}
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(b).glob('*.txt')})
            independent.certify(c,Path(a))
            with self.assertRaises(FileExistsError):gen.generate(c,Path(a))
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(a).glob('*.txt')})
        stems=[f'BB_{c["n"]}_{c["k"]}_unknown' for c in gen.CASES]
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),
              '--cpu','0','--dry-run','--family','BB','--out','/tmp/unused-weight8','--stems']+stems
        jobs=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True))
        self.assertEqual({cmd[-1].split('/')[-1] for cmd in jobs},set(stems))


if __name__=='__main__':unittest.main()
