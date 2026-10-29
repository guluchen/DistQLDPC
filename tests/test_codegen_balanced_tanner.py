#!/usr/bin/env python3
"""Full-CSS/orbit/claim safeguards and independent tiny distance checks."""
from itertools import combinations
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import balanced_tanner as gen
import validate_balanced_tanner as independent
import validate_css as css
import smoke_untiered as smoke
from audit_balanced_smoke import verify_witness


class BalancedTests(unittest.TestCase):
    def test_orbit_differential_independent(self):
        for length in (3,5,7,11):
            n,x,z=gen.checks(length)
            edges,a,xx,zz=independent.reconstruct(length,gen.LABELS)
            self.assertEqual((x,z),(xx,zz))
            self.assertEqual(len(css.basis(a)),len(a))
            self.assertEqual(n-len(css.basis(x))-len(css.basis(z)),2)
            self.assertFalse(any(css.dot(r,s) for r in x for s in z))

    def test_deck_equivariance_and_cover(self):
        for length in (3,5,7):
            edges,a,te,tc=gen.factor(length)
            for q,row in enumerate(a):
                moved=sum(((row >> j)&1) << te[j] for j in range(len(edges)))
                self.assertEqual(moved,a[tc[q]])
            self.assertTrue(all(x%4 != y%4 for x,y in edges))
            degree=[sum(v in edge for edge in edges) for v in range(4*length)]
            self.assertEqual(set(degree),{7})
            for p in (te,tc):
                self.assertEqual(len(set(p)),len(p))
                for q in range(len(p)):
                    cur=q;orbit=[]
                    for _ in range(length):orbit.append(cur);cur=p[cur]
                    self.assertEqual(cur,q);self.assertEqual(len(set(orbit)),length)

    def test_tiny_exact_global_distance(self):
        # Exhaust all supports of weight 1 and 2 in BOTH halves. A separate
        # explicit nontrivial X cycle of weight 3 supplies the matching upper.
        n,x,z=gen.checks(3)
        for parity,stab in ((x,z),(z,x)):
            span=css.basis(stab)
            for w in (1,2):
                for s in combinations(range(n),w):
                    word=sum(1 << q for q in s)
                    if not any(css.dot(word,r) for r in parity):
                        self.assertTrue(css.contains(span,word))
        edges,_,te,_=gen.factor(3);words=[]
        for q in range(len(edges)):
            orbit=[q,te[q],te[te[q]]];word=sum(1 << p for p in orbit)
            if not css.contains(css.basis(x),word):words.append(word)
        self.assertTrue(words)
        self.assertTrue(all(bin(w).count('1')==3 and not any(css.dot(w,r) for r in z) for w in words))

    def test_reversed_action_mutant(self):
        n,x,z=gen.checks(3);edges,a,te,tc=gen.factor(3);m=len(edges)
        # Replace only the horizontal action by its inverse, leaving A and
        # the check-cell action fixed: this breaks the chain relation.
        inverse=[te.index(q) for q in range(m)]
        wrong=[(row ^ (1 << te[e]) ^ (1 << inverse[e])) for e,row in enumerate(z)]
        self.assertTrue(any(css.dot(r,s) for r in x for s in wrong))
        self.assertNotEqual((x,wrong),independent.reconstruct(3,gen.LABELS)[2:])

    def test_invalid_lengths(self):
        for length in (-1,0,1,2,4):
            with self.assertRaises(ValueError):gen.factor(length)

    def test_reproduce_and_certificate(self):
        with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
            stem=gen.generate(3,Path(a));gen.generate(3,Path(b))
            for p in Path(a).glob('*.txt'):self.assertEqual(p.read_bytes(),(Path(b)/p.name).read_bytes())
            n,matrices=css.read_code(Path(a),stem)
            cert=independent.certify(3,gen.LABELS,n,matrices)
            self.assertEqual(cert['verified_cycle_ub'],3)
            self.assertEqual(cert['k'],2)
            with self.assertRaises(FileExistsError):gen.generate(3,Path(a))

    def test_upper_bound_is_not_an_exact_claim(self):
        s='c d_lb: 3\nc d_ub: 3\no 3\n'
        self.assertEqual(smoke.parse(s,7,exact=False)['status'],'SOLVED')
        with self.assertRaises(ValueError):smoke.parse(s,7)
        self.assertEqual(smoke.parse('c d_lb: 3\nc d_ub: 10\ns UNKNOWN\n',7,exact=False)['ub'],10)
        for text in ('c d_lb: 8\nc d_ub: 9\n','c d_lb: 2\nc d_ub: 8\no 8\n',
                     'c d_lb: 4\nc d_ub: 3\n','c d_lb: 0\nc d_ub: 3\n',
                     'c d_lb: 4\nc d_ub: 7\no 3\n'):
            with self.assertRaises(ValueError):smoke.parse(text,7,exact=False)

    def test_engine_and_family_selection(self):
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),
              '--family','BP','--cpu','0','--dry-run','--out','/tmp/unused-bp']
        a=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True))
        b=json.loads(subprocess.check_output(argv+['--engine','cc'],cwd=ROOT,text=True))
        self.assertEqual(len(a),6);self.assertEqual(len(b),6)
        self.assertFalse(any('-engine=cc' in cmd for cmd in a))
        self.assertTrue(all('-engine=cc' in cmd for cmd in b))
        self.assertTrue(all('BP_' in cmd[-1] for cmd in a+b))

    def test_actual_witness_rejection(self):
        directory=ROOT/'data/matrices/untiered'
        n,m=css.read_code(directory,'BP_78_2_unknown')
        edges,_,te,_=gen.factor(3)
        valid=next([e,te[e],te[te[e]]] for e in range(len(edges))
                   if not css.contains(css.basis(m[0]),sum(1 << q for q in (e,te[e],te[te[e]]))))
        verify_witness(n,m,'X',valid)
        for bad in ([],[n],[0,0],valid[:-1]):
            with self.assertRaises(ValueError):verify_witness(n,m,'X',bad)
        stabilizer=[q for q in range(n) if (m[0][0] >> q)&1]
        with self.assertRaises(ValueError):verify_witness(n,m,'X',stabilizer)


if __name__=='__main__':unittest.main()
