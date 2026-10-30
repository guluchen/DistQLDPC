#!/usr/bin/env python3
"""No solver execution: frozen input and diagnostic interpretation mutations."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('cc500',ROOT/'optimization/experiments/GH-202/diagnostic/cc500.py')
diag=importlib.util.module_from_spec(spec);spec.loader.exec_module(diag)


class DiagnosticTests(unittest.TestCase):
    def test_frozen_input_full_gf2_logicals_and_previous8_word(self):
        n,m,meta,result,words=diag.preflight()
        self.assertEqual((n,len(m[2]),len(m[3])),(500,42,42))
        self.assertEqual(result,dict(lb=8,ub=8,status='SOLVED'))
        self.assertTrue(any(w['weight']==8 for w in words))

    def test_two_engine8_does_not_change_source6_or_adopt(self):
        r=diag.assess('c d_lb: 8\nc d_ub: 8\no 8\n',0)
        self.assertEqual(r['reconstructed_input_exact_crosschecked'],8)
        self.assertEqual(r['source_reference_exact'],6)
        self.assertTrue(r['source_exact_guard_raised'])
        self.assertFalse(r['library_adoption']);self.assertFalse(r['paper_erratum_claim'])

    def test_incomplete_cc_lower_is_not_filled_from_maxsat(self):
        r=diag.assess('c d_lb: 5\nc d_ub: 8\n',1)
        self.assertEqual(r['authorized_cc']['lb'],5)
        self.assertIsNone(r['reconstructed_input_exact_crosschecked'])
        self.assertFalse(r['solver_conflict'])

    def test_claimed_smaller_upper_flags_engine_conflict(self):
        r=diag.assess('c d_lb: 5\nc d_ub: 6\n',1)
        self.assertTrue(r['solver_conflict'])
        self.assertEqual(r['actual_verified_upper'],8)
        self.assertFalse(r['library_adoption'])

    def test_invalid_printed_word_rejected(self):
        with self.assertRaises(ValueError):diag.assess('c d_lb: 5\nc d_ub: 8\nc witness X: 0 0\n',1)

    def test_mismatched_exit_is_not_diagnostic_success(self):
        with self.assertRaises(ValueError):diag.assess('c d_lb: 8\nc d_ub: 8\no 8\n',1)

    def test_non_actions_execution_refused_before_output(self):
        with tempfile.TemporaryDirectory() as directory:
            out=Path(directory)/'not-created'
            result=subprocess.run([sys.executable,str(Path(diag.__file__)),'--ci','--out',str(out)],
                                  text=True,capture_output=True,env=dict(os.environ,GITHUB_ACTIONS='false'))
            self.assertNotEqual(result.returncode,0)
            self.assertIn('ephemeral Linux Actions only',result.stderr)
            self.assertFalse(out.exists())

    def test_guard_without_original_ancestor_and_rejects_dirty_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);(root/'src').mkdir();(root/'src/f').write_text('unit source\n')
            (root/'Makefile').write_text('unit build\n')
            subprocess.run(['git','init','--quiet'],cwd=root,check=True)
            subprocess.run(['git','add','src','Makefile'],cwd=root,check=True)
            subprocess.run(['git','-c','user.name=unit','-c','user.email=unit@example.invalid',
                            'commit','--quiet','-m','single snapshot'],cwd=root,check=True)
            trees=subprocess.check_output(['git','rev-parse','HEAD:src','HEAD:Makefile'],cwd=root,text=True).splitlines()
            missing=subprocess.run(['git','cat-file','-e',diag.ORIGINAL_SOURCE],cwd=root,capture_output=True)
            self.assertNotEqual(missing.returncode,0)
            diag.verify_solver_sources(root,*trees)
            with self.assertRaises(ValueError):diag.verify_solver_sources(root,'0'*40,trees[1])
            (root/'src/f').write_text('changed source\n')
            with self.assertRaises(ValueError):diag.verify_solver_sources(root,*trees)


if __name__=='__main__':unittest.main()
