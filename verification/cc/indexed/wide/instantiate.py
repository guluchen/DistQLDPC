"""Instantiate the existing bounded-search proof over the two-block value type."""
from pathlib import Path
import re
import sys
base, dest = map(Path, sys.argv[1:3])
prefix, width = sys.argv[3], sys.argv[4]
modules = "Branch Refute Roots Layout Index Short Orbit Dual Half Answer".split()
for tag in modules:
    if tag in {"Half", "Answer"}:
        continue
    src = (base / f"CCPacked{tag}.v").read_text()
    for dependency in [*modules, "Words"]:
        src = src.replace(f"CCV.CCPacked{dependency}", f"{prefix}{dependency}")
        src = src.replace(f"CCPacked{dependency}.", f"{prefix}{dependency}.")
    src = re.sub(r"\b189\b", width, src)
    if tag == "Layout":
        start = src.index("Proof.", src.index("Lemma decode_out"))
        end = src.index("Qed.", start) + 4
        src = src[:start] + "Proof. apply outside. Qed." + src[end:]
    (dest / f"{prefix}{tag}.v").write_text(src)
