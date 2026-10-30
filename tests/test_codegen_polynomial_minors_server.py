"""Remaining-gate planning/source/allocation guards, without native solver runs."""
import copy
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
RUNNER=ROOT/'optimization/experiments/GH-209/runner/run_serial.py'
spec=importlib.util.spec_from_file_location('minor_server',RUNNER)
server=importlib.util.module_from_spec(spec);spec.loader.exec_module(server)
CASES=json.loads((ROOT/'scripts/codegen/polynomial_minors_cases.json').read_text())
OBS=json.loads((ROOT/'optimization/experiments/GH-209/raw/actions/default/audit.json').read_text())


class ServerTests(unittest.TestCase):
    def test_known_source_proofs_required_unknown_exact_not_required(self):
        queues=server.make_queues([OBS[1],OBS[2]],[CASES[1],CASES[2]])
        self.assertEqual([(j['engine'],j['purpose']) for j in queues['jobs.jsonl']],
                         [('maxsat','source-proof'),('cc','source-proof')])
        self.assertEqual(len(queues['optional-maxsat-jobs.jsonl']),1)
        self.assertEqual(len(queues['optional-cc-jobs.jsonl']),1)

    def test_missing_numeric_remains_required(self):
        q=server.make_queues([OBS[4]],[CASES[4]])
        self.assertEqual([(j['engine'],j['purpose']) for j in q['jobs.jsonl']],[('maxsat','numeric-proof')])
        self.assertIsNone(OBS[4]['engines']['maxsat']['lb'])
        self.assertIsNone(OBS[4]['engines']['maxsat']['ub'])

    def test_missing_actual_upper_word_gets_explicit_finder_job(self):
        p=copy.deepcopy(OBS[2]);p['engines']['maxsat']['ub']=40;snapshot=copy.deepcopy(p)
        q=server.make_queues([p],[CASES[2]])
        self.assertEqual(len(q['jobs.jsonl']),1)
        j=q['jobs.jsonl'][0]
        self.assertEqual((j['purpose'],j['engine'],j['word_target']),('word','cc',40))
        self.assertIn('-cc-ub-only',j['args']);self.assertIn('-ub-search=budget:600',j['args'])
        self.assertEqual(p,snapshot)

    def test_truncated_case_inventory_cannot_silently_drop_jobs(self):
        with self.assertRaises(ValueError):server.make_queues(OBS[:-1],CASES)

    def test_canonical_dry_plans_never_create_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'unstarted'
            for name in server.QUEUES:
                path=RUNNER.with_name(name);jobs=[json.loads(x) for x in path.read_text().splitlines() if x.strip()]
                result=subprocess.run([sys.executable,str(RUNNER),'--cpu','54','--out',str(out),'--jobs',str(path)],
                                      cwd=ROOT,text=True,capture_output=True,check=True)
                commands=json.loads(result.stdout)
                self.assertEqual([c[-1] for c in commands],[j['code'] for j in jobs])
                self.assertFalse(out.exists())

    def test_unallocated_execution_stops_before_output_or_solver(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'unstarted'
            result=subprocess.run([sys.executable,str(RUNNER),'--cpu','54','--out',str(out),'--execute'],
                                  cwd=ROOT,text=True,capture_output=True)
            self.assertNotEqual(result.returncode,0)
            self.assertTrue('yfclab2 execution only' in result.stderr or 'explicit PI allocation' in result.stderr)
            self.assertFalse(out.exists())

    def test_source_guard_needs_no_historical_commit(self):
        values=['19cbea916c41b3918de87f86791da9f1c80abbbd\n','1951a24d5de920a651ad3919c672331862976365\n']
        with patch.object(server.subprocess,'check_output',side_effect=values) as check:
            with patch.object(server.subprocess,'run',return_value=SimpleNamespace(returncode=0)) as run:
                server.verify_solver_sources()
                self.assertEqual([c.args[0] for c in check.call_args_list],
                                 [['git','rev-parse','HEAD:src'],['git','rev-parse','HEAD:Makefile']])
                self.assertEqual(run.call_args.args[0],['git','diff','--quiet','HEAD','--','src','Makefile'])

    def test_changed_source_or_dirty_build_refused(self):
        with patch.object(server.subprocess,'check_output',return_value='bad\n'):
            with self.assertRaises(ValueError):server.verify_solver_sources()
        values=['19cbea916c41b3918de87f86791da9f1c80abbbd\n','1951a24d5de920a651ad3919c672331862976365\n']
        with patch.object(server.subprocess,'check_output',side_effect=values):
            with patch.object(server.subprocess,'run',return_value=SimpleNamespace(returncode=1)):
                with self.assertRaises(ValueError):server.verify_solver_sources()

    def test_noncanonical_queue_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'unstarted';path=Path(directory)/'other.jsonl';path.write_text('')
            result=subprocess.run([sys.executable,str(RUNNER),'--cpu','54','--out',str(out),'--jobs',str(path)],
                                  cwd=ROOT,text=True,capture_output=True)
            self.assertNotEqual(result.returncode,0);self.assertIn('canonical frozen queues',result.stderr)
            self.assertFalse(out.exists())


if __name__=='__main__':unittest.main()
