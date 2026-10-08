import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('installer', Path(__file__).with_name('install.py'))
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class InstallationDirectory(unittest.TestCase):
    def test_missing_directory_created_without_changing_existing_parent(self):
        with tempfile.TemporaryDirectory() as temp:
            parent = Path(temp)
            before = parent.stat().st_mode
            helper = parent / 'sbin/helper'
            with patch.object(m, 'HELPER', helper), patch.object(m, 'secure_parent') as verify:
                m.ensure_helper_directory()
                self.assertEqual([call.args[0] for call in verify.call_args_list], [helper.parent, helper])
            self.assertEqual(helper.parent.stat().st_mode & 0o777, 0o755)
            self.assertEqual(parent.stat().st_mode, before)

    def test_untrusted_parent_refused_before_creation(self):
        with tempfile.TemporaryDirectory() as temp:
            helper = Path(temp) / 'sbin/helper'
            with patch.object(m, 'HELPER', helper), patch.object(m, 'secure_parent', side_effect=RuntimeError('unsafe')):
                with self.assertRaises(RuntimeError):
                    m.ensure_helper_directory()
            self.assertFalse(helper.parent.exists())

    def test_dangling_symlink_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp) / 'sbin'
            directory.symlink_to(Path(temp) / 'missing', target_is_directory=True)
            with patch.object(m, 'HELPER', directory / 'helper'):
                with self.assertRaises(RuntimeError):
                    m.ensure_helper_directory()
            self.assertFalse((Path(temp) / 'missing').exists())


if __name__ == '__main__':
    unittest.main()
