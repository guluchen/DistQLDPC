"""Create a separate counter-only ORIGINAL-baseline snapshot. Does not build/run."""
import argparse
import hashlib
import pathlib
import shutil


def unique_replace(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f"Expected exactly one baseline fragment: {old!r}")
    return text.replace(old, new, 1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=pathlib.Path, required=True,
                        help="An unmodified pinned baseline source snapshot")
    parser.add_argument("--out", type=pathlib.Path, required=True,
                        help="New empty destination, outside source")
    args = parser.parse_args()
    source=args.source.resolve()
    destination=args.out.resolve()
    if destination==source or source in destination.parents or destination.exists():
        raise SystemExit("Destination must be new and outside original source")
    text=(source/"src/solver/Solver.cc").read_text(encoding="utf-8")
    # Refuse the candidate signature and unknown/expanded source changes.
    if "void Solver::setConflict(int& nbIsets) {" not in text:
        raise SystemExit("Not original baseline setConflict; refusing instrumentation")
    # Git's LF source hash; CRLF source exports normalize to the same bytes.
    expected="aecaea724d63a93eaaba670798d4188d53987f0faa96ef5e619dc0e724932e43"
    normalized=text.replace("\r\n","\n").encode("utf-8")
    if hashlib.sha256(normalized).hexdigest()!=expected:
        raise SystemExit("Baseline Solver.cc hash mismatch; refusing unknown code")
    text=unique_replace(text,'#include "Solver.h"',
                        '#include "Solver.h"\n#include "GH17AllocationDiagnostic.h"')
    text=unique_replace(text,"  vec<Lit> out_learnt, ps;",
                        '  vec<Lit> out_learnt, ps;\n  GH17AllocationDiagnostic gh17_diag("restart");')
    # There is exactly one matching plain local declaration in this baseline.
    text=unique_replace(text,"  vec<Lit> out_learnt;",
                        '  vec<Lit> out_learnt;\n  GH17AllocationDiagnostic gh17_diag("main");')
    text=unique_replace(text,"\t  oldset.push(subIset);",
                        "\t  int gh17_old_capacity=oldset.capacity();\n"
                        "\t  oldset.push(subIset);\n"
                        "\t  if (gh17_active_diagnostic) gh17_active_diagnostic->push(\n"
                        "\t      oldset.size(),oldset.capacity(),oldset.capacity()!=gh17_old_capacity);")
    text=unique_replace(text,"  nbIsets++;\n}\n\nvoid Solver::resetConflicts",
                        "  nbIsets++;\n"
                        "  if (gh17_active_diagnostic) gh17_active_diagnostic->finish(oldset.size());\n"
                        "}\n\nvoid Solver::resetConflicts")
    shutil.copytree(source,destination,ignore=shutil.ignore_patterns(".git","build","bin","__pycache__"))
    (destination/"src/solver/Solver.cc").write_text(text,encoding="utf-8",newline="\n")
    shutil.copyfile(pathlib.Path(__file__).with_name("allocation_diagnostic.h"),
                    destination/"src/solver/GH17AllocationDiagnostic.h")
    print(destination)


if __name__=="__main__":
    main()
