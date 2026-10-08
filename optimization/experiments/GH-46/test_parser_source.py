"""Pure parser cases extracted by AST; no support imports or solver execution."""
import ast
import json
from pathlib import Path
import re

source=Path(__file__).with_name("run_tier0.py")
module=ast.parse(source.read_text())
names={"ScienceMismatch","CoverageGap","require_science","semantic","assert_all_bounds","assert_status","require_completed_application"}
subset=ast.Module(body=[n for n in module.body if isinstance(n,(ast.FunctionDef,ast.ClassDef)) and n.name in names],type_ignores=[])
namespace={"re":re}
exec(compile(subset,str(source),"exec"),namespace)
completed="c d_lb: 2\nc d_ub: 2\nc d  : 2\no 2\n"
unknown="c d_lb: 0\nc d_ub: 2\nc status: UNKNOWN\nc d  : UNKNOWN\ns UNKNOWN\n"
cases=[("completed",0,completed,"PASS"),
       ("lawful_unknown",1,unknown,"CoverageGap"),
       ("lawful_timeout",1,unknown.replace("status: UNKNOWN","status: TIMEOUT (child killed after -cpu-lim)"),"CoverageGap"),
       ("missing_distance",1,unknown.replace("c d  : UNKNOWN\n",""),"ScienceMismatch"),
       ("wrong_bounds",1,unknown.replace("d_lb: 0","d_lb: 3"),"ScienceMismatch"),
       ("bare_objective",1,unknown+"o\n","ScienceMismatch"),
       ("arbitrary_timeout_prefix",1,unknown.replace("status: UNKNOWN","status: TIMEOUT arbitrary"),"ScienceMismatch"),
       ("bare_timeout",1,unknown.replace("status: UNKNOWN","status: TIMEOUT"),"ScienceMismatch"),
       ("wrong_optimum",0,completed.replace("o 2","o 3"),"ScienceMismatch"),
       ("crash",139,unknown,"ScienceMismatch")]
results=[]
for name,rc,text,expected in cases:
    actual="PASS"
    try: namespace["require_completed_application"]((rc,text,""),2)
    except Exception as error:actual=type(error).__name__
    if actual!=expected:raise AssertionError((name,expected,actual))
    results.append(dict(case=name,expected=expected,actual=actual))
print(json.dumps(dict(status="PASS",solver_executed=False,support_imports=False,cases=results),indent=2))
