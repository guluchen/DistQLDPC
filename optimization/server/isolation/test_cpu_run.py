import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('cpu_run', Path(__file__).with_name('cpu_run.py'))
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class LeaseSafety(unittest.TestCase):
    def test_capacity_strict_threshold_and_reserved_pair(self):
        self.assertFalse(m.capacity(50,256))
        self.assertFalse(m.capacity(None,256))
        self.assertFalse(m.capacity(80,4))  # both SMT CPUs count against allowance
        self.assertTrue(m.capacity(80,256))

    def test_iowait_is_not_spare_capacity(self):
        a={'cpu':[0]*8}
        b={'cpu':[10,0,0,40,50,0,0,0]}
        self.assertEqual(m.idle(a,b),40)
        self.assertFalse(m.capacity(m.idle(a,b),256))

    def test_no_relative_command_or_cwd(self):
        for cwd,argv in [('/tmp',['python3']),('relative',['/usr/bin/python3']),('/tmp',[])]:
            with self.assertRaises(ValueError):
                m.run(cwd,argv)

    def test_verify_rejects_degraded_or_overlapping_partition(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp); group=root/'distqldpc-bench'; group.mkdir()
            sibling=root/'user.slice'; sibling.mkdir()
            for name,text in [('cpuset.cpus.partition','isolated'),
                              ('cpuset.cpus.effective','102,230'),
                              ('cpuset.cpus.exclusive.effective','102,230')]:
                (group/name).write_text(text)
            (root/'cpuset.cpus.isolated').write_text('102,230')
            (sibling/'cpuset.cpus.effective').write_text('0-101,103-229,231-255')
            with patch.object(m,'ROOT',root),patch.object(m,'GROUP',group):
                m.verify()
                (group/'cpuset.cpus.partition').write_text('isolated invalid (test)')
                with self.assertRaises(RuntimeError):m.verify()
                (group/'cpuset.cpus.partition').write_text('isolated')
                (sibling/'cpuset.cpus.effective').write_text('0-255')
                with self.assertRaises(RuntimeError):m.verify()
                (sibling/'cpuset.cpus.effective').write_text('0-101')
                (group/'cpuset.cpus.exclusive.effective').write_text('102')
                with self.assertRaises(RuntimeError):m.verify()

if __name__=='__main__':
    unittest.main()
