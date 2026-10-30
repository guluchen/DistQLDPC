"""Independent finite physical-root proof and deliberately broken certificates."""
import copy
import json
from pathlib import Path
import random
import sys
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import bch as generator
import bch_certificate as proof

TINY=dict(id='tiny7',n=7,m=3,primitive_polynomial=11,delta=3,k=1,
          published_exact=3)
CERTS=ROOT/'optimization/experiments/GH-207/raw/certificates'


class CertificateTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.directory=Path(self.tmp.name)
        generator.generate(TINY,self.directory)
        # This proof uses an odd kernel word as its own detector; logical
        # matrix files are irrelevant to the nontriviality argument.
        text='# tiny logical representative\n1 1 0 1 0 0 0\n'
        for kind in ('Gx','Gz'):
            (self.directory/('BCH_7_1_unknown_'+kind+'.txt')).write_text(text)
        self.cert=proof.build(TINY,self.directory,
                              dict(half='X',support=[0,1,3],weight=3))

    def check_bad(self,change,case=None):
        cert=copy.deepcopy(self.cert)
        change(cert)
        with self.assertRaises(ValueError):
            proof.verify(case or TINY,self.directory,cert)

    def test_tiny_lower_and_nontrivial_word(self):
        self.assertEqual(proof.verify(TINY,self.directory,self.cert)['certificate_exact'],3)

    def test_all_frozen_finite_physical_proofs(self):
        results=[]
        for case in proof.CASES:
            cert=json.loads((CERTS/(proof.stem(case)+'.json')).read_text())
            results.append(proof.verify(case,ROOT/'data/matrices/untiered',cert))
        self.assertEqual([r['certificate_exact'] for r in results],[5,9,11,None,None])
        self.assertEqual([(r['certificate_lower'],r['actual_verified_upper']) for r in results],
                         [(5,5),(9,9),(11,11),(17,22),(19,24)])

    def test_independent_coefficient_field_products(self):
        rng=random.Random(20711)
        for m,p in ((3,11),(4,19),(5,37),(8,285),(10,1033),(12,4179)):
            self.assertTrue(proof.irreducible(p))
            for _ in range(20):
                a,b=rng.randrange(1 << m),rng.randrange(1 << m)
                self.assertEqual(proof.field_mul(a,b,p),generator.gf_mul(a,b,p))

    def test_missing_equation_mutant(self):
        self.check_bad(lambda c:c['root_row_combinations'].pop())

    def test_wrong_physical_combination_mutant(self):
        self.check_bad(lambda c:c['root_row_combinations'].__setitem__(0,c['root_row_combinations'][0]^1))

    def test_out_of_range_combination_mutant(self):
        self.check_bad(lambda c:c['root_row_combinations'].__setitem__(0,1 << 100))

    def test_root_order_mutant(self):
        self.check_bad(lambda c:c.__setitem__('beta',1))

    def test_reducible_field_and_nonclosing_root(self):
        self.assertFalse(proof.irreducible(0x15))
        with self.assertRaises(ValueError):proof.root_equations(dict(TINY,n=9),2)

    def test_duplicate_upper_coordinates_mutant(self):
        self.check_bad(lambda c:c['word'].__setitem__('support',[0,0,3]))

    def test_non_kernel_word_mutant(self):
        self.check_bad(lambda c:c['word'].__setitem__('support',[0,1,2]))

    def test_invalid_detector_mutant(self):
        self.check_bad(lambda c:c.__setitem__('detector_support',[0]))

    def test_even_pairing_detector_mutant(self):
        self.check_bad(lambda c:c.__setitem__('detector_support',[0,1,2,4]))

    def test_identity_and_frozen_parameter_mutants(self):
        self.check_bad(lambda c:c.__setitem__('delta',4))
        self.check_bad(lambda c:c['input_sha256'].__setitem__('Hx','0'*64))
        self.check_bad(lambda c:c.__setitem__('case_id','other'))

    def test_physical_file_mutation_rejected(self):
        path=self.directory/'BCH_7_1_unknown_Hx.txt'
        path.write_text(path.read_text().replace('1','0',1))
        with self.assertRaises(ValueError):proof.verify(TINY,self.directory,self.cert)

    def test_server_canonical_queues_contain_only_remaining_gaps(self):
        runner=ROOT/'optimization/experiments/GH-207/runner/run_serial.py'
        for name,engine in [('jobs.jsonl','maxsat'),('optional-cc-jobs.jsonl','cc')]:
            cmd=[sys.executable,str(runner),'--cpu','54','--out',str(self.directory/'unstarted'),
                 '--jobs',str(runner.with_name(name))]
            result=subprocess.run(cmd,cwd=ROOT,text=True,capture_output=True,check=True)
            commands=json.loads(result.stdout)
            self.assertEqual(len(commands),2)
            self.assertEqual([c[-1].split('/')[-1] for c in commands],
                             ['BCH_1365_1173_unknown','BCH_1365_1149_unknown'])
            self.assertTrue(all(('-engine=cc' in c)==(engine=='cc') for c in commands))
            self.assertFalse((self.directory/'unstarted').exists())

    def test_server_execution_without_allocation_never_starts(self):
        runner=ROOT/'optimization/experiments/GH-207/runner/run_serial.py'
        out=self.directory/'unstarted'
        result=subprocess.run([sys.executable,str(runner),'--cpu','54','--out',str(out),'--execute'],
                              cwd=ROOT,text=True,capture_output=True)
        self.assertNotEqual(result.returncode,0)
        self.assertTrue('yfclab2 execution only' in result.stderr or
                        'explicit PI allocation' in result.stderr)
        self.assertFalse(out.exists())


if __name__=='__main__':unittest.main()
