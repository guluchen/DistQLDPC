"""Exercise the optional 24-lane kernel through its binary and raw PCM CLI."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from unittest.mock import patch
from types import SimpleNamespace

from test_wide import ROOT, query

for n in (758, 1512):
    row = "1" * n + "\n"
    query(n, "X", {755, n - 1}, row, row, 2, "pcm-xl", "pair-pack")
    query(n, "Z", {0, 756}, row, row, 2, "pcm-xl", "reverse-bfs", "class-parity")
    query(n, "Z", {n - 1}, row, row, None, "pcm-xl", "erasure-pack")
query(1513, "X", {1512}, "", "", None, "pcm-xl")
with tempfile.TemporaryDirectory() as tmp:
    pcm = Path(tmp) / "h"
    pcm.write_text("1" * 758 + "\n")
    args = [sys.executable, ROOT / "certified.py", "758", pcm, pcm,
            "--extended-width", "--upper-rounds", "1", "--class-parity"]
    result = json.loads(subprocess.run(args, check=True, capture_output=True, text=True).stdout)
    assert result["status"] == "FOUND" and result["distance"] == 2
    x, z = (int(result[side], 2) for side in ("x", "z"))
    assert (x | z).bit_count() == 2 and x.bit_count() % 2 == z.bit_count() % 2 == 0
# An inconclusive short proof must not suppress the full proof if the
# second upper search reproduces the same word or finds no witness.
sys.path.insert(0, str(ROOT))
import certified

for second in (None, ("X", "1" + "0" * 757)):
    word = ("X", "1" + "0" * 757)
    cli = ["certified.py", "758", "hx", "hz", "--extended-width"]
    with patch.object(sys, "argv", cli), patch.object(certified, "upper_proposal", side_effect=[word, second]), \
         patch.object(certified, "packed_check", side_effect=[SimpleNamespace(returncode=3),
                     SimpleNamespace(returncode=0, stdout="")]) as check:
        assert certified.main() == 0
        first, full = check.call_args_list
        assert first.args == ([ROOT/"pcm-xl", "758", "hx", "hz", "quick-probe"], word)
        assert full.args == ([ROOT/"pcm-xl", "758", "hx", "hz"], word)
print("2 adaptive search fallback controls passed")
print("7 extended-width certificate controls and 1 full CLI witness passed")

with tempfile.TemporaryDirectory() as tmp:
    hx, hz = (Path(tmp) / side for side in ("hx", "hz"))
    hx.write_text("# comment\n\n" + "0" * 758 + " # row\n")
    hz.write_text("")
    raw = ["758", str(hx), str(hz)]
    assert certified.multiple_logicals_from_row_count(raw)
    word = ("X", "1" * 8 + "0" * 750)
    with patch.object(sys, "argv", ["certified.py", *raw, "--extended-width"]), \
         patch.object(certified, "upper_proposal", side_effect=[word, None]), \
         patch.object(certified, "packed_check", return_value=SimpleNamespace(returncode=0, stdout="")) as check:
        assert certified.main() == 0
        check.assert_called_once_with([ROOT / "pcm-xl", *raw], word)
    hz.write_text(("0" * 758 + "\n") * 756)
    assert not certified.multiple_logicals_from_row_count(raw)
print("3 structural upper-schedule controls passed")
