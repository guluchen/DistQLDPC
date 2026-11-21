"""Specialize the shared OCaml hints to the flat three-word extraction type."""
from pathlib import Path
import re
import sys

source, dest = map(Path, sys.argv[1:])
text = source.read_text()
start = text.index("let words w =")
end = text.index("let bit a q", start)
text = text[:start] + "let words w = [|word w.low;word w.middle;word w.high|]\n" + text[end:]
for old, new in [("Wide_generated", "Small_generated"), ("Array.make 6 0", "Array.make 3 0"),
                 ("to 5 do", "to 2 do"), ("Array.make 378", "Array.make 189")]:
    if old not in text:
        raise ValueError("Unrecognized advice template: " + old)
    text = text.replace(old, new)
# Extraction no longer emits a second, enclosing 'bits' record at this width.
dest.write_text(re.sub(r"\b(bits|singleton|none)0\b", r"\1", text))
