#!/bin/bash
# GH-224 behaviour checks, old vs new binary, one pinned core (arg 1), 4 GB cap unless stated:
#  (1) -cpu-lim wall deadline -> SIGKILL -> TIMEOUT with bounds (MaxSAT and CC);
#  (2) a tighter memory cap (prlimit --as) that the child exceeds;
#  (3) the child killed from outside (SIGKILL) -> UNKNOWN at once; (4) the child stopped and continued (SIGSTOP/SIGCONT).
# usage (from a worktree root): behaviour.sh CORE OLD NEW [WORKDIR]
C=$1; OLD=$2; NEW=$3; W=${4:-.}
run() {  # run LABEL AS_BYTES ARGS...
    local lab=$1 as=$2; shift 2
    for arm in old new; do
        b=$OLD; [[ $arm == new ]] && b=$NEW
        t0=$(date +%s.%N)
        out=$(taskset -c $C prlimit --as=$as -- $b "$@" 2>&1 < /dev/null); rc=$?
        t1=$(date +%s.%N)
        printf '%-28s %-4s rc=%d wall=%.3f  %s\n' "$lab" $arm $rc $(echo "$t1 - $t0" | bc) "$(echo "$out" | grep -E '^(c d_lb|c d_ub|c status|o |s |c d  )' | tr '\n' '|' )"
    done
}
run timeout-maxsat 4294967296 -cpu-lim=3 TN_250_10_15
run timeout-cc 4294967296 -engine=cc -cpu-lim=3 $(ls data/matrices/tier5 | grep _Hx | grep BB_756 | sed s/_Hx.txt//)
run memcap-200M 209715200 -cpu-lim=60 $(ls data/matrices/tier5 | grep _Hx | grep LP_2610 | sed s/_Hx.txt//)
run memcap-60M-cc 62914560 -engine=cc -cpu-lim=60 $(ls data/matrices/tier5 | grep _Hx | grep LP_2610 | sed s/_Hx.txt//)
for arm in old new; do   # (3) external SIGKILL of the child after 1 s
    b=$OLD; [[ $arm == new ]] && b=$NEW
    t0=$(date +%s.%N)
    taskset -c $C prlimit --as=4294967296 -- $b -cpu-lim=60 TN_250_10_15 > $W/gh224_kill_$arm.txt 2>&1 < /dev/null &
    p=$!; sleep 1; ch=$(pgrep -P $p -n)
    tk=$(date +%s.%N); kill -9 $ch; wait $p; rc=$?; t1=$(date +%s.%N)
    printf '%-28s %-4s rc=%d after-kill=%.3f  %s\n' child-sigkill $arm $rc $(echo "$t1 - $tk" | bc) "$(grep -E '^(c status|s |o )' $W/gh224_kill_$arm.txt | tr '\n' '|')"
done
for arm in old new; do   # (4) SIGSTOP the child for 2 s, then SIGCONT; the run must finish normally
    b=$OLD; [[ $arm == new ]] && b=$NEW
    t0=$(date +%s.%N)
    taskset -c $C prlimit --as=4294967296 -- $b -cpu-lim=60 LP_442_68_10 > $W/gh224_stop_$arm.txt 2>&1 < /dev/null &
    p=$!; sleep 0.5; ch=$(pgrep -P $p -n); kill -STOP $ch; sleep 2; kill -CONT $ch; wait $p; rc=$?; t1=$(date +%s.%N)
    printf '%-28s %-4s rc=%d wall=%.3f  %s\n' child-stop-cont $arm $rc $(echo "$t1 - $t0" | bc) "$(grep -E '^(c status|s |o )' $W/gh224_stop_$arm.txt | tr '\n' '|')"
done
