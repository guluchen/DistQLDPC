#!/usr/bin/env bash
# GH-124 S0 (fix round 1): command-line checks of the engine flags of bin/distqldpc.
#   - conflicting engine flag combinations are rejected (exit 1, "error:" on stderr, no answer line);
#   - invalid values of the CC flags are rejected;
#   - valid combinations still answer, and -engine=auto warns on stderr about flags its choice ignores.
# Runs one solver process at a time on two tier0 codes (TN_36_8_3: auto -> maxsat; LP_34_20_2: auto -> cc),
# each with -cpu-lim=20 (a few MB of memory). Usage: tests/test_cc_flags.sh [BINARY]
set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
bin="${1:-./bin/distqldpc}"
[[ -x "$bin" ]] || { echo "error: expected executable at $bin" >&2; exit 2; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fails=0
runs=0

run() {   # run ARGS...: sets rc, out (stdout), err (stderr)
    "$bin" "$@" >"$tmp/out" 2>"$tmp/err" </dev/null
    rc=$?
    out="$(cat "$tmp/out")"
    err="$(cat "$tmp/err")"
}

reject() {   # reject PATTERN ARGS...: exit 1, stderr has "error:" matching PATTERN, no answer, no file written
    local pat="$1"; shift
    runs=$((runs + 1))
    rm -f "$tmp/dump.wcnf" "$tmp/dump.opb" "$tmp/trace.txt"
    run "$@"
    if [[ $rc -ne 1 ]] || ! grep -q "^error: .*$pat" <<<"$err" || grep -Eq '^o [0-9]+' <<<"$out" \
        || [[ -e "$tmp/dump.wcnf" || -e "$tmp/dump.opb" || -e "$tmp/trace.txt" ]]; then
        echo "FAIL (expected rejection /$pat/): $* -> rc=$rc stderr: $err" >&2
        fails=$((fails + 1))
    fi
}

accept() {   # accept D WARN_PATTERN ARGS...: exit 0 with 'o D'; WARN_PATTERN '' = no warning on stderr
    local d="$1" warn="$2"; shift 2
    runs=$((runs + 1))
    run "$@"
    local ok=1
    [[ $rc -eq 0 ]] && grep -qx "o $d" <<<"$out" || ok=0
    if [[ -n "$warn" ]]; then
        grep -q "^warning: .*$warn" <<<"$err" || ok=0
    else
        grep -q "^warning: -engine=auto" <<<"$err" && ok=0
    fi
    grep -q "^error:" <<<"$err" && ok=0
    if [[ $ok -ne 1 ]]; then
        echo "FAIL (expected o $d${warn:+ and warning /$warn/}): $* -> rc=$rc stdout tail: $(tail -1 <<<"$out") stderr: $err" >&2
        fails=$((fails + 1))
    fi
}

M=TN_36_8_3    # auto -> maxsat (qubit degree 2)
C=LP_34_20_2   # auto -> cc
L=-cpu-lim=20

# 1. MaxSAT formulation / backend / dump flags with -engine=cc or -engine=auto
for e in -engine=cc -engine=auto; do
    for f in -joint -roundingsat -roundingsat=/nonexistent "-dump-wcnf=$tmp/dump.wcnf" "-dump-opb=$tmp/dump.opb" \
             -dump-only -native-parity-opb; do
        reject "cannot be combined with $e" "$e" "$f" $L $M
        reject "cannot be combined with $e" "$f" "$e" $L $C          # order does not matter
    done
done
reject "cannot be combined with -engine=cc" -engine=cc -dump-only "-dump-wcnf=$tmp/dump.wcnf" $M

# 2. MaxSAT tuning flags with -engine=cc
for f in -no-card -card-sinz -card-mto -card-both -card-both-force -dualshare-stats; do
    reject "no effect with -engine=cc" -engine=cc "$f" $L $C
done

# 3. CC flags without -engine=cc|auto (default engine and explicit -engine=maxsat)
for f in -ub-basis -ub-basis=on -ub-basis=off -cc-rules=mrv -cc-rules=none -cc-dual=on -cc-dual=off -cc-seed=1 \
         "-cc-trace=$tmp/trace.txt" -cc-stats -cc-mutant=2 -cc-mutant=0 -cc-schedule=sequential -cc-schedule=lockstep; do
    reject "need -engine=cc or -engine=auto" "$f" $L $M
    reject "need -engine=cc or -engine=auto" -engine=maxsat "$f" $L $M
done
reject "need -engine=cc or -engine=auto" -cc-rules=mrv -cc-mutant=2 -engine=maxsat $L $M
reject "need -engine=cc or -engine=auto" -engine=cc -engine=maxsat -ub-basis $L $M   # the last -engine= wins

# 4. invalid values
for f in -cc-seed=abc -cc-seed=-1 -cc-seed= -cc-seed=1x -cc-mutant=5 -cc-mutant=-1 -cc-mutant=x -cc-mutant= \
         -cc-trace= -cc-schedule=fast -ub-basis=maybe -cc-rules=bogus -cc-dual=maybe -cc-unknown -engine=fast; do
    reject "invalid\|unknown" -engine=cc "$f" $L $C
done

# 5. valid combinations still answer
accept 3 "" $L $M                                         # default engine (main's path)
accept 3 "" -engine=maxsat -card-mto -dualshare-stats $L $M
accept 3 "" -engine=maxsat -joint $L $M
accept 2 "" -engine=cc $L $C
accept 3 "" -engine=cc -ub-basis -cc-rules=excl,pack,orbf,mrv -cc-seed=2 -cc-stats -cc-schedule=sequential $L $M
accept 3 "" -engine=cc -no-symbreak -dualmode=off -cc-dual=off -cc-rules=none $L $M
accept 2 "" -engine=cc -cc-mutant=0 -cc-schedule=lockstep -ub-basis=off "-cc-trace=$tmp/trace.txt" $L $C
accept 2 "" -engine=auto $L $C
accept 3 "" -engine=auto $L $M
accept 2 "" -engine=auto -cc-rules=mrv -ub-basis $L $C           # auto -> cc: CC flags apply
accept 3 "" -engine=auto -card-mto $L $M                         # auto -> maxsat: tuning flag applies
accept 2 "selected cc .*ignoring -card-mto -dualshare-stats" -engine=auto -card-mto -dualshare-stats $L $C
accept 3 "selected maxsat .*ignoring -cc-rules=mrv -ub-basis" -engine=auto -cc-rules=mrv -ub-basis $L $M

echo "test_cc_flags: $runs checks, $fails failed"
[[ $fails -eq 0 ]] && echo "CC_FLAG_TESTS PASS" || echo "CC_FLAG_TESTS FAIL"
exit $((fails > 0))
