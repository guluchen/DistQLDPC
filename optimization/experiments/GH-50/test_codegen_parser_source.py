"""Synthetic source-extracted parser checks; no tool, support import or solver."""
import ast
import hashlib
import json
from pathlib import Path
import re
p=Path(__file__).with_name("codegen_parser.py")
tree=ast.parse(p.read_text(encoding="utf-8"))
namespace={"hashlib":hashlib,"re":re}
subset=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) or isinstance(n,ast.Assign)],type_ignores=[])
exec(compile(subset,str(p),"exec"),namespace)
symbol=namespace["SYMBOL"]
text="0000000000000100 <"+symbol+">:\n"+"".join(f" {256+i:x}:  90  nop\n" for i in range(12))+" 104: IMAGE_REL_AMD64_REL32 helper-0x4\n"
base=namespace["parse"](text)
assert namespace["compare"](base,namespace["parse"](text.replace("0100","0200").replace(" 10"," 20")))["exact_bytes_equal"]
results=[]
for name,modified in [("missing_function",text.replace(symbol,"wrong")),("duplicate_function",text+text),
                      ("byte_gap",text.replace(" 101:"," 111:")),("omitted_bytes",text.replace(" 101:  90  nop","...")),
                      ("bad_relocation",text.replace("IMAGE_REL_AMD64_REL32","UNKNOWN_RELOCATION"))]:
    try:namespace["parse"](modified)
    except ValueError:results.append(dict(case=name,status="PASS"));continue
    raise AssertionError(name)
changed=namespace["parse"](text.replace(" 101:  90  nop"," 101:  91  xchg"))
assert namespace["compare"](base,changed)["status"]=="DIFFERENT_INDEPENDENT_REVIEW_REQUIRED"
changed=namespace["parse"](text.replace("helper-0x4","other-0x4"))
assert not namespace["compare"](base,changed)["relative_relocations_equal"]
print(json.dumps(dict(status="PASS",cases=results,relocated_same_code_equal=True,changed_bytes_detected=True,changed_relocation_detected=True,solver_or_tool_executed=False),indent=2))
