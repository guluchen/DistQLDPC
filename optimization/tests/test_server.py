import importlib.util
from pathlib import Path
import unittest
capacity_spec=importlib.util.spec_from_file_location('capacity',Path(__file__).resolve().parents[1]/'server/idle_tier1.py')
capacity=importlib.util.module_from_spec(capacity_spec);capacity_spec.loader.exec_module(capacity)
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
    def test_resource_threshold_is_strict(self):
        self.assertFalse(capacity.capacity_ok(50,256))
        self.assertTrue(capacity.capacity_ok(50.1,256))
    def test_resource_budget_is_half_idle(self):
        self.assertFalse(capacity.capacity_ok(60,2))
        self.assertTrue(capacity.capacity_ok(89,256))
        self.assertFalse(capacity.capacity_ok(89,256,115))
    def test_unknown_capacity_is_not_allowed(self):
        self.assertFalse(capacity.capacity_ok(None,256))
    def test_iowait_is_not_available_capacity(self):
        before={'cpu':[0]*8}
        after={'cpu':[0,0,0,40,60,0,0,0]}
        self.assertEqual(capacity.idle_percent(before,after),40)
if __name__=='__main__':unittest.main()
