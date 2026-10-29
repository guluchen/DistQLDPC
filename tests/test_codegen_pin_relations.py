#!/usr/bin/env python3
"""Independent pin-kernel proof hypotheses, chain/source/logical mutants."""
import copy
import itertools
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
from pin_relations import tensor_chain,complete_endpoints,chain_flags,generate,CASES
from validate_pin_relations import independent_flags,check_relation,pinned_checks,isolation_check,certify,physical_components
from validate_css import read_code,validate,dot
from verify_css_witness import verify_witness


class Pin(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases=json.loads(CASES.read_text());cls.c=cls.cases[0];cls.stem=f'PIN_{cls.c["n"]}_{cls.c["k"]}_unknown';cls.n,cls.m=read_code(ROOT/'data/matrices/untiered',cls.stem);cls.cert=json.loads((ROOT/'optimization/experiments/GH-189/raw/certificates'/f'{cls.stem}.json').read_text())

    def test_complete_first_case(self):self.assertEqual(certify(self.c,self.cert,self.n,self.m)['k'],64)

    def test_twenty_random_tiny_recursive_paths_and_endpoint_fibers(self):
        rng=random.Random(189)
        for _ in range(20):
            # Rectangular independent random factors, including inactive pins.
            factors=[]
            for __ in range(rng.choice([2,3])):
                rows,cols=rng.randrange(1,4),rng.randrange(1,4);factors.append([[rng.randrange(2) for j in range(cols)] for i in range(rows)])
            bases,boundary=tensor_chain(factors);sizes,complete,added=complete_endpoints(list(map(len,bases)),boundary);flags=chain_flags(sizes,complete)
            independent,_,_,_=independent_flags(dict(construction='tensor_chain',factors=factors))
            self.assertEqual(flags,independent)
            if flags:check_relation(flags)

    def test_odd_fiber_mutant(self):
        flags=[tuple(f) for f in self.cert['flags']][1:]
        with self.assertRaisesRegex(ValueError,'odd'):check_relation(flags)

    def test_repeated_flag_mutant(self):
        flags=[tuple(f) for f in self.cert['flags']];flags.append(flags[0])
        with self.assertRaisesRegex(ValueError,'distinct'):check_relation(flags)

    def test_missing_endpoint_completion_mutant(self):
        flags=[tuple(f) for f in self.cert['flags'] if f[-1]!=self.cert['endpoint_added_pins'][1]]
        with self.assertRaisesRegex(ValueError,'odd'):check_relation(flags)

    def test_boundary_certificate_mutant(self):
        cert=copy.deepcopy(self.cert);cert['original_boundary_columns'][0][0]^=1
        with self.assertRaisesRegex(ValueError,'boundaries'):certify(self.c,cert,self.n,self.m)

    def test_missing_pin_check_invalidates_kernel_bound(self):
        m=copy.deepcopy(self.m);m[0].pop()
        with self.assertRaisesRegex(ValueError,'pinned-check'):certify(self.c,self.cert,self.n,m)

    def test_commuting_changed_check_basis_is_not_complete_pin_presentation(self):
        m=copy.deepcopy(self.m);m[0][0]^=m[0][1];validate(self.n,m)
        with self.assertRaisesRegex(ValueError,'pinned-check'):certify(self.c,self.cert,self.n,m)

    def test_parameter_hash_mutant(self):
        cert=copy.deepcopy(self.cert);cert['parameter_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'identity'):certify(self.c,cert,self.n,self.m)

    def test_logical_quotient_mutant(self):
        m=copy.deepcopy(self.m);m[2][0]=m[2][1]
        with self.assertRaises(ValueError):validate(self.n,m)

    def test_stabilizer_is_not_upper_word(self):
        qs=[q for q in range(self.n) if (self.m[1][0]>>q)&1]
        with self.assertRaises(ValueError):verify_witness(self.n,self.m,'Z',qs)

    def test_random_tiny_isolation_certificates_not_distance_search(self):
        # Only verify predetermined sub-threshold supports, never seek a codeword.
        flags=list(itertools.product(range(2),repeat=4));rng=random.Random(189)
        for pins in [1,2]:
            rows,labels=pinned_checks(flags,pins);lookup={(tuple(l['type']),tuple(l['pins'])):w for l,w in zip(labels,rows)}
            for _ in range(80):
                qs=rng.sample(range(16),rng.randrange(1,1<<(pins+1)));cert=isolation_check(flags,qs,pins);w=lookup[tuple(cert['type']),tuple(cert['pins'])]
                self.assertEqual(sum((w>>q)&1 for q in qs),1)

    def test_asymmetric_source_anchor_and_explicit_weight8_word(self):
        c=self.cases[2];stem=f'PIN_{c["n"]}_{c["k"]}_unknown';n,m=read_code(ROOT/'data/matrices/untiered',stem);cert=json.loads((ROOT/'optimization/experiments/GH-189/raw/certificates'/f'{stem}.json').read_text());result=certify(c,cert,n,m)
        self.assertEqual(result['pin_kernel_lower'],dict(X=32,Z=8));self.assertEqual(result['independent_overall_upper'],8)

    def test_typed_physical_product_mutants(self):
        self.assertEqual(physical_components(4,[15],[3]),1);self.assertEqual(physical_components(4,[3,12],[3,12]),2)

    def test_byte_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            out,certs=Path(d)/'out',Path(d)/'certs';stem=generate(self.c,out,certs)
            for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((out/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
            self.assertEqual((certs/f'{stem}.json').read_bytes(),(ROOT/'optimization/experiments/GH-189/raw/certificates'/f'{stem}.json').read_bytes())
            with self.assertRaises(FileExistsError):generate(self.c,out,certs)

    def test_explicit_six_cli_and_default_workload(self):
        runner=ROOT/'scripts/codegen/smoke_untiered.py';base=[sys.executable,str(runner),'--cpu','54','--dry-run','--out','/tmp/not-allocated']
        p=subprocess.run(base+['--family','PIN'],text=True,capture_output=True,check=True);self.assertEqual(len(json.loads(p.stdout)),6)
        p=subprocess.run(base,text=True,capture_output=True,check=True);self.assertEqual(len(json.loads(p.stdout)),12)
        p=subprocess.run(base+['--family','PIN','--stems','HGP_13_1_unknown'],text=True,capture_output=True);self.assertNotEqual(p.returncode,0)


if __name__=='__main__':unittest.main()
