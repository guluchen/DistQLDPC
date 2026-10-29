#!/usr/bin/env bash
# GH-148 Tier 0 after merging origin/main; cores 100-107 only; every process pinned + 4 GB cap.
# usage: t0.sh WORKTREE TAG [CAND_DEFAULT_EXTRA]   (run with nohup, stdin /dev/null)
set -u
W=$1; TAG=$2; A=~/mac-agent-20261009; O=$A/gh148m-t0/$TAG; mkdir -p $O
cd $A/$W || exit 1
CAP="prlimit --as=4294967296 --"
echo "build start $(date)" > $O/status
taskset -c 100-107 $CAP make -j8 > $O/build.log 2>&1; echo "build rc $?" >> $O/status
taskset -c 100-107 $CAP make -j8 build/test_cc_engine >> $O/build.log 2>&1 || taskset -c 100-107 $CAP make -j8 test_cc_engine_build_only >> $O/build.log 2>&1
mkdir -p $A/frozen/server-$TAG && cp bin/distqldpc $A/frozen/server-$TAG/distqldpc && sha256sum $A/frozen/server-$TAG/distqldpc >> $O/status
B=$A/frozen/server-$TAG/distqldpc; MAIN=$A/frozen/server-main-e52d15b/distqldpc
( taskset -c 100 $CAP make test-cc > $O/test_cc.txt 2>&1; echo "test-cc rc $?" >> $O/status ) &
( taskset -c 101 $CAP bash tests/test_cc_flags.sh ./bin/distqldpc > $O/test_cc_flags.txt 2>&1; echo "test-cc-flags rc $?" >> $O/status
  taskset -c 101 $CAP bash scripts/smoke_test.sh ./bin/distqldpc > $O/smoke.txt 2>&1; echo "smoke rc $?" >> $O/status ) &
( python3 $A/gh148m-t0/ident.py $MAIN $B $O/ident_default 102 > $O/ident_default.txt 2>&1; echo "ident default rc $?" >> $O/status ) &
( python3 $A/gh148m-t0/ident.py $MAIN $B $O/ident_off 103 -stab-overlap=off > $O/ident_off.txt 2>&1; echo "ident off rc $?" >> $O/status ) &
( python3 - $B $O/jobs_t0.jsonl <<'PY'
import glob, json, os, sys
B, OUT = sys.argv[1:3]; js = []
for f in sorted(glob.glob('data/matrices/tier0/*_Hx.txt')):
    stem = os.path.basename(f)[:-7]
    for mode in ('-no-card', '-card-mto'):
        for arm, ex in (('auto', ['-stab-overlap=auto']), ('on', ['-stab-overlap=on']), ('off', ['-stab-overlap=off'])):
            js.append(dict(id=f't0.{stem}.{mode[1:]}.{arm}', bin=B, args=[mode, '-frontier-stats'] + ex, code=f'data/matrices/tier0/{stem}',
                           stem=stem, tier=0, arm=arm, seed=0, mode=mode[1:], limit=600))
open(OUT, 'w').write(''.join(json.dumps(j) + '\n' for j in js)); print(len(js))
PY
  python3 $A/gh148m-t0/run_queue.py --cpus 104-107 --jobs $O/jobs_t0.jsonl --out $O/answers > $O/answers.out 2>&1; echo "answers rc $?" >> $O/status ) &
wait
echo "ALL DONE $(date)" >> $O/status
