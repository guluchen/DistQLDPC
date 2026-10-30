"""Dry plans/allocation/source guards; never starts a native distance search."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
RUNNER=ROOT/'optimization/experiments/GH-208/runner/run_serial.py'
spec=importlib.util.spec_from_file_location('qr_server',RUNNER)
server=importlib.util.module_from_spec(spec);spec.loader.exec_module(server)


class ServerGuardTests(unittest.TestCase):
    def test_canonical_dry_queues_never_create_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'not-started'
            for name,engine in [('jobs.jsonl','maxsat'),('optional-maxsat-jobs.jsonl','maxsat'),('optional-cc-jobs.jsonl','cc')]:
                path=RUNNER.with_name(name)
                jobs=[json.loads(x) for x in path.read_text().splitlines() if x.strip()]
                result=subprocess.run([sys.executable,str(RUNNER),'--cpu','54','--out',str(out),
                                       '--jobs',str(path)],cwd=ROOT,text=True,capture_output=True,check=True)
                commands=json.loads(result.stdout)
                self.assertEqual([c[-1] for c in commands],[j['code'] for j in jobs])
                self.assertTrue(all(('-engine=cc' in c)==(engine=='cc') for c in commands))
                self.assertFalse(out.exists())

    def test_unallocated_execution_stops_before_output_or_solver(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'not-started'
            result=subprocess.run([sys.executable,str(RUNNER),'--cpu','54','--out',str(out),'--execute'],
                                  cwd=ROOT,text=True,capture_output=True)
            self.assertNotEqual(result.returncode,0)
            self.assertTrue('yfclab2 execution only' in result.stderr or 'explicit PI allocation' in result.stderr)
            self.assertFalse(out.exists())

    def test_unregistered_queue_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'not-started';jobs=Path(directory)/'jobs.jsonl';jobs.write_text('')
            result=subprocess.run([sys.executable,str(RUNNER),'--cpu','54','--out',str(out),'--jobs',str(jobs)],
                                  cwd=ROOT,text=True,capture_output=True)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('canonical frozen queues',result.stderr)
            self.assertFalse(out.exists())

    def test_source_guard_needs_no_historical_commit_objects(self):
        values=['19cbea916c41b3918de87f86791da9f1c80abbbd\n','1951a24d5de920a651ad3919c672331862976365\n']
        with patch.object(server.subprocess,'check_output',side_effect=values) as check:
            with patch.object(server.subprocess,'run',return_value=SimpleNamespace(returncode=0)) as run:
                server.verify_solver_sources()
                self.assertEqual([c.args[0] for c in check.call_args_list],
                                 [['git','rev-parse','HEAD:src'],['git','rev-parse','HEAD:Makefile']])
                self.assertEqual(run.call_args.args[0],['git','diff','--quiet','HEAD','--','src','Makefile'])

    def test_changed_source_or_dirty_solver_refused(self):
        with patch.object(server.subprocess,'check_output',return_value='bad\n'):
            with self.assertRaises(ValueError):server.verify_solver_sources()
        values=['19cbea916c41b3918de87f86791da9f1c80abbbd\n','1951a24d5de920a651ad3919c672331862976365\n']
        with patch.object(server.subprocess,'check_output',side_effect=values):
            with patch.object(server.subprocess,'run',return_value=SimpleNamespace(returncode=1)):
                with self.assertRaises(ValueError):server.verify_solver_sources()


if __name__=='__main__':unittest.main()
