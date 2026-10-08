#!/usr/bin/env bash
# Fixed small training / final build. Instrumented timings are not benchmarks.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
profile="$PWD/pgo-data"
evidence="${1:?provide an evidence directory}"
mkdir -p "$evidence"
evidence="$(cd "$evidence" && pwd)"
if [[ -e "$profile" ]]; then
  echo 'Refusing stale PGO data; use a fresh experiment checkout.' >&2
  exit 1
fi
export GCOV_EXIT_AT_ERROR=1
g++ --version > "$evidence/compiler.txt"
gcov --version > "$evidence/gcov.txt"
make clean
make -j1 PGO=generate PGO_DIR="$profile" bin/distqldpc > "$evidence/build-generate.log" 2>&1
for stem in LP_34_20_2 LP_136_32_4; do
  for mode in no-card card-mto; do
    ./bin/distqldpc -v -cpu-lim=120 "-$mode" "$stem" > "$evidence/train-$stem-$mode.log" 2>&1
  done
done
python3 - "$evidence" <<'PY'
import pathlib,re,sys
p=pathlib.Path(sys.argv[1])
for stem,expected in [('LP_34_20_2',2),('LP_136_32_4',4)]:
    for mode in ['no-card','card-mto']:
        text=(p/f'train-{stem}-{mode}.log').read_text()
        pats=[r'^c\s+d\s*:\s*(\d+)\s*$',r'^o\s+(\d+)\s*$',r'^c\s+d_lb:\s*(\d+)\s*$',r'^c\s+d_ub:\s*(\d+)\s*$']
        values=[int(re.findall(x,text,re.M)[-1]) if re.findall(x,text,re.M) else None for x in pats]
        if values != [expected]*4: raise SystemExit(f'Training semantic/incomplete result: {stem} {mode} {values}')
PY
python3 - "$profile" <<'PY'
import pathlib,shutil,sys
files=list(pathlib.Path(sys.argv[1]).glob('*.gcda'))
expected={'Solver.gcda','SimpSolver.gcda','Options.gcda','System.gcda'}
if {p.name.split('#')[-1] for p in files}!=expected or len(files)!=4:
    raise SystemExit('Missing or unexpected engine profiles')
for p in files: shutil.copy2(p,pathlib.Path('build')/p.name.split('#')[-1])
PY
gcov --json-format -o build src/solver/Solver.cc > "$evidence/coverage.log" 2>&1
python3 - "$evidence" <<'PY'
import gzip,hashlib,json,pathlib,shutil,sys
e=pathlib.Path(sys.argv[1]); functions=[]
for p in pathlib.Path('.').glob('*.gcov.json.gz'):
    shutil.copy2(p,e/p.name)
    for f in json.loads(gzip.decompress(p.read_bytes())).get('files',[]):
        functions.extend(f.get('functions',[]))
counts={n:sum(f.get('execution_count',0) for f in functions if n in f.get('demangled_name',f.get('name',''))) for n in ['Minisat::Solver::search','Minisat::Solver::propagate']}
if not all(counts.values()): raise SystemExit(f'Incomplete solver profiles: {counts}')
hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in pathlib.Path('pgo-data').glob('*.gcda')}
(e/'profiles.json').write_text(json.dumps({'counts':counts,'hashes':hashes},indent=2))
shutil.copytree('pgo-data',e/'profiles')
shutil.copytree('build',e/'training-build')
PY
make clean
make -j1 PGO=use PGO_DIR="$profile" bin/distqldpc > "$evidence/build-use.log" 2>&1
nm bin/distqldpc > "$evidence/production-symbols.txt"
if grep -q '__gcov_' "$evidence/production-symbols.txt"; then
  echo 'Training runtime or hook entered production binary.' >&2
  exit 1
fi
python3 - "$evidence" <<'PY'
import hashlib,json,pathlib,sys
e=pathlib.Path(sys.argv[1]); old=json.loads((e/'profiles.json').read_text())['hashes']
now={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in pathlib.Path('pgo-data').glob('*.gcda')}
if now!=old: raise SystemExit('Frozen profiles changed during final build')
(e/'final-binary.json').write_text(json.dumps({'sha256':hashlib.sha256(pathlib.Path('bin/distqldpc').read_bytes()).hexdigest()},indent=2))
PY
