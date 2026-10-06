import importlib.util
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('runner',Path(__file__).resolve().parents[1]/'server/run.py')
r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
class Gates(unittest.TestCase):
    def samples(self,b,c):
        return [{'case':'x','mode':m,'version':v,'elapsed_sec':t} for m in r.MODES
                for v,ts in [('baseline',b),('candidate',c)] for t in ts]
    def test_beyond_range(self):self.assertEqual(r.judge(self.samples([9,10,11],[6,7,8]),['x'])[0],'pass')
    def test_regression(self):self.assertEqual(r.judge(self.samples([9,10,11],[12,13,14]),['x'])[0],'reject')
    def test_overlap(self):self.assertEqual(r.judge(self.samples([9,10,11],[8,9,10]),['x'])[0],'inconclusive')
    def test_incomplete(self):
        with self.assertRaises(ValueError):r.judge(self.samples([9,10],[6,7,8]),['x'])
    def test_timeout_not_exact(self):
        p=r.parse('c d_lb: 2\nc d_ub: 10\nc status: TIMEOUT (child killed after -cpu-lim)\nc d  : UNKNOWN\ns UNKNOWN\n')
        self.assertIsNone(p['d']);self.assertTrue(p['timeout']);self.assertTrue(p['unknown'])
    def test_exact(self):
        p=r.parse('c d_lb: 10\nc d_ub: 10\nc d  : 10\no 10\n')
        self.assertEqual([p[x] for x in ['d','objective','lb','ub']],[10]*4)
if __name__=='__main__':unittest.main()
