"""Specialize the shared advice for two 756-bit children in a Coq word."""
from pathlib import Path
import re
import sys

source, target = map(Path, sys.argv[1:])
text = source.read_text().replace("Large_generated", "Xl_generated")
text = text.replace("let words w =", "let half_words w =")
text = text.replace("let bit a q", "let words w = Array.append (half_words w.xl_low) (half_words w.xl_high)\nlet bit a q")
text = text.replace("Array.make 12 0", "Array.make 24 0").replace("to 11 do", "to 23 do")
text = text.replace("Array.make 756 []", "Array.make 1512 []")
# Extraction allocates successive names to the same identifiers in child modules.
text = re.sub(r"\b(bits|singleton|none)1\b", r"\g<1>2", text)
target.write_text(text)
