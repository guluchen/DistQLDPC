"""Read-only Git source identity check; no compiler, fixture or solver imports."""
import hashlib
import json
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = '24572d6d09cce9a4a5faa58300a89e0feba9da6a'


def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args])


def main():
    head = git('rev-parse', 'HEAD').decode().strip()
    changed = git('diff', '--name-only', BASE, head, '--', 'src').decode().splitlines()
    if changed != ['src/solver/Solver.cc']:
        raise SystemExit('Unexpected production source scope')
    source = git('show', BASE + ':src/solver/Solver.cc')
    candidate = git('show', head + ':src/solver/Solver.cc')
    old = b'static IntOption     opt_ccmin_mode        (_cat, "ccmin-mode",  "Controls conflict clause minimization (0=none, 1=basic, 2=deep)", 2, IntRange(0, 2));'
    new = old.replace(b'", 2, IntRange', b'", 1, IntRange')
    if source.count(old) != 1 or candidate != source.replace(old, new):
        raise SystemExit('Candidate must be exactly original bytes plus one default literal')
    result = {
        'status': 'SOURCE_SCOPE_PASS_ONLY_NOT_SCIENCE', 'baseline': BASE, 'head': head,
        'baseline_solver_sha256': hashlib.sha256(source).hexdigest(),
        'candidate_solver_sha256': hashlib.sha256(candidate).hexdigest(),
        'changed_production_files': changed,
        'change': 'ccmin-mode default2->1 only; original helper/constructor/all other bytes retained',
        'builds_or_scientific_tests_executed': False,
        'known_GH46_baseline_anomaly': 'UNRESOLVED_BLOCKS_COMPLETE_CERTIFICATION_PROMOTION',
    }
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
