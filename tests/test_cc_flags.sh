#!/usr/bin/env bash
# GH-124 S0 (fix round 1, pre-S1): command-line checks of the engine flags of bin/distqldpc.
#   - conflicting engine flag combinations are rejected (exit 1, "error:" on stderr, no answer line);
#   - invalid values of the CC flags, of -seed and of -oddcap-skip are rejected (GH-133: -oddcap-skip is a MaxSAT flag);
#   - valid combinations still answer, and -engine=auto warns on stderr about flags its choice ignores;
#   - -engine=auto picks cc on sparse codes and maxsat on dense ones (decision printed with -v).
# Runs one solver process at a time on two tier0 codes (TN_36_8_3, LP_34_20_2; auto -> cc) and three generated
# d = 2 codes (Hx = Hz = one all-ones row per block): D1 one block of 34 (row weight 34 > 32: auto -> maxsat),
# D2 two blocks of 32 (n = 64, mean row weight 32 > n/4: auto -> maxsat), S4 four blocks of 32 (n = 128, mean
# row weight 32 = n/4: auto -> cc), each with -cpu-lim=20 (a few MB of memory). Usage: tests/test_cc_flags.sh [BINARY]
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

vgrep() {   # vgrep D PATTERN ARGS...: exit 0 with 'o D' and a stdout line matching PATTERN
    local d="$1" pat="$2"; shift 2
    runs=$((runs + 1))
    run "$@"
    if [[ $rc -ne 0 ]] || ! grep -qx "o $d" <<<"$out" || ! grep -q "$pat" <<<"$out"; then
        echo "FAIL (expected o $d and /$pat/): $* -> rc=$rc stdout tail: $(tail -1 <<<"$out") stderr: $err" >&2
        fails=$((fails + 1))
    fi
}

gen_blocks() {   # gen_blocks PREFIX SIZE...: Hx = Hz = one all-ones row per block, Gx = Gz = e_s + e_{s+i}, d = 2
    local prefix="$1"; shift
    awk -v sizes="$*" -v prefix="$prefix" 'BEGIN {
        nb = split(sizes, b, " "); n = 0
        for (i = 1; i <= nb; i++) { st[i] = n; n += b[i] }
        hx = prefix "_Hx.txt"; hz = prefix "_Hz.txt"; gx = prefix "_Gx.txt"; gz = prefix "_Gz.txt"
        for (i = 1; i <= nb; i++) {
            line = ""
            for (q = 0; q < n; q++) line = line (q ? " " : "") ((q >= st[i] && q < st[i] + b[i]) ? 1 : 0)
            print line > hx; print line > hz
            for (j = 1; j <= b[i] - 2; j++) {
                line = ""
                for (q = 0; q < n; q++) line = line (q ? " " : "") ((q == st[i] || q == st[i] + j) ? 1 : 0)
                print line > gx; print line > gz
            }
        }
    }'
}

M=TN_36_8_3    # auto -> cc (pre-S1 rule; the S0 rule sent it to maxsat for its degree-2 qubits)
C=LP_34_20_2   # auto -> cc
D1="$tmp/D1_34_32_2"; gen_blocks "$D1" 34              # auto -> maxsat (row weight 34 > 32)
D2="$tmp/D2_64_60_2"; gen_blocks "$D2" 32 32           # auto -> maxsat (n 64, mean row weight 32 > 16)
S4="$tmp/S4_128_120_2"; gen_blocks "$S4" 32 32 32 32   # auto -> cc (n 128, mean row weight 32 = n/4)
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
for f in -no-card -card-sinz -card-mto -card-both -card-both-force -dualshare-stats -oddcap-skip=on -oddcap-skip=off -ub-pre=off -ub-pre=2 \
         -stab-overlap=on -stab-overlap=auto -stab-overlap=off; do
    reject "no effect with -engine=cc" -engine=cc "$f" $L $C
done

# 3. CC flags without -engine=cc|auto (default engine and explicit -engine=maxsat)
for f in -ub-basis -ub-basis=on -ub-basis=off -cc-rules=mrv -cc-rules=none -cc-rules=parity,leaf -cc-dual=on -cc-dual=off -cc-seed=1 \
         "-cc-trace=$tmp/trace.txt" -cc-stats -cc-mutant=2 -cc-mutant=0 -cc-mutant=7 -cc-mutant=10 -cc-schedule=sequential \
         -cc-schedule=lockstep -cc-rules=overlap -ub-search=on -ub-search=off -ub-search=budget:5 -cc-ub-only -cc-ub-pre=1 \
         -cc-ub-share=0.2 -cc-ub-triples=10 -cc-ub-slack=2 -cc-mutant=11 -cc-mutant=12 -cc-aut=on -cc-aut=off -cc-mutant=13 -cc-mutant=14 \
         -cc-rules=charge -cc-lb-minr=2 -cc-lb-gap=1 -cc-lb-raise=off -cc-lb-auto=0 -cc-mutant=15; do
    reject "need -engine=cc or -engine=auto" "$f" $L $M
    reject "need -engine=cc or -engine=auto" -engine=maxsat "$f" $L $M
done
reject "need -engine=cc or -engine=auto" -cc-rules=mrv -cc-mutant=2 -engine=maxsat $L $M
reject "need -engine=cc or -engine=auto" -engine=cc -engine=maxsat -ub-basis $L $M   # the last -engine= wins

# 4. invalid values
for f in -cc-seed=abc -cc-seed=-1 -cc-seed= -cc-seed=1x -cc-mutant=16 -cc-mutant=-1 -cc-mutant=x -cc-mutant= \
         -cc-trace= -cc-schedule=fast -ub-basis=maybe -cc-rules=bogus -cc-rules= -cc-rules=excl,,pack -cc-rules=excl, \
         -cc-rules=parity, -cc-rules=Leaf -cc-rules=overlap, -cc-rules=Overlap -cc-rules=ovl -cc-rules=Charge -cc-rules=charge, -cc-dual=maybe \
         -cc-aut -cc-aut= -cc-aut=maybe -cc-aut=ON -cc-autx -cc-rules=ecover -cc-lb-minr=0 -cc-lb-minr= -cc-lb-minr=x -cc-lb-minr=1001 -cc-lb-gap= -cc-lb-gap=-1 \
         -cc-lb-gap=x -cc-lb-gap=1001 -cc-lb-raise= -cc-lb-raise=no -cc-lb-auto= -cc-lb-auto=101 -cc-lb-auto=x -cc-unknown -engine=fast -seed=abc -seed=-1 -seed= -seed=1x; do
    reject "invalid\|unknown" -engine=cc "$f" $L $C
done
# GH-140: -ub-search values and the finder's tuning flags
for f in -ub-search -ub-search= -ub-search=maybe -ub-search=ON -ub-search=budget: -ub-search=budget:0 -ub-search=budget:-1 \
         -ub-search=budget:x -ub-search=budget:1s -ub-searchX "-ub-search=budget:5 -cc-ub-pre=x" "-ub-search=on -cc-ub-pre=" \
         "-ub-search=on -cc-ub-share=1" "-ub-search=on -cc-ub-share=1.5" "-ub-search=on -cc-ub-share=-0.1" "-ub-search=on -cc-ub-share=x" \
         "-ub-search=on -cc-ub-triples=x" "-ub-search=on -cc-ub-triples=-1" "-ub-search=on -cc-ub-slack=x" "-ub-search=on -cc-ub-slack=1001" \
         "-ub-search=on -cc-ub-hits=x" "-ub-search=on -cc-ub-hits=-1" "-ub-search=on -cc-ub-bogus"; do
    reject "invalid\|unknown" -engine=cc $f $L $C
done
reject "need -ub-search=on or -ub-search=budget:S" -engine=cc -ub-search=off -cc-ub-pre=1 $L $C   # -ub-search is on by default since 2026-10-23
reject "need -ub-search=on or -ub-search=budget:S" -engine=cc -ub-search=off -cc-ub-share=0.5 -cc-ub-slack=1 $L $C
reject "need -ub-search=on or -ub-search=budget:S" -engine=cc -ub-search=on -ub-search=off -cc-ub-only $L $C   # the last -ub-search wins
reject "needs -ub-search=budget:S" -engine=cc -ub-search=on -cc-ub-only $L $C
for f in -seed=abc -seed=-1 -seed= -seed=1x -oddcap-skip=maybe -oddcap-skip= -oddcap-skip -oddcap-skip=ON; do
    reject "invalid" "$f" $L $M
done

# 4b. -seed conflicts: different -seed / -cc-seed values; -seed with -roundingsat
reject "different seeds" -engine=cc -seed=1 -cc-seed=2 $L $C
reject "different seeds" -engine=auto -cc-seed=3 -seed=0 $L $C
reject "no effect with -roundingsat" -seed=1 -roundingsat $L $M

# 5. valid combinations still answer
accept 3 "" $L $M                                         # default engine (main's path)
accept 3 "" -engine=maxsat -card-mto -dualshare-stats $L $M
accept 3 "" -engine=maxsat -joint $L $M
accept 2 "" -engine=cc $L $C
accept 3 "" -engine=cc -ub-basis -cc-rules=excl,pack,orbf,mrv -cc-seed=2 -cc-stats -cc-schedule=sequential $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,mrv $L $M                                   # GH-133 rules
accept 2 "" -engine=cc -cc-rules=parity $L $C
accept 2 "" -engine=cc -cc-rules=leaf -cc-seed=3 $L $C
accept 2 "" -engine=cc -cc-rules=excl,pack,orbf $L $C                                                   # GH-124 rule set
accept 2 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf $L $C                                       # GH-133 rule set
accept 3 "" -engine=cc -cc-rules=overlap $L $M                                                          # GH-138 rule alone
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,mrv -cc-seed=1 $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge $L $M                         # GH-157 rules
accept 2 "" -engine=cc -cc-rules=charge -cc-lb-minr=1 $L $C
accept 2 "" -engine=cc -cc-rules=charge,mrv -cc-lb-minr=2 -cc-seed=2 $L $C
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge -cc-lb-gap=2 -cc-lb-minr=1 $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge -cc-lb-raise=off -cc-lb-minr=1 $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge -cc-lb-auto=0 -cc-lb-minr=1 $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge -cc-lb-auto=100 $L $M
accept 2 "" -oddcap-skip=on $L $C                                                                       # GH-133 MaxSAT flag
accept 2 "" -oddcap-skip=off -card-mto $L $C
accept 3 "" -oddcap-skip=on -no-card $L $M
accept 2 "" -engine=auto -oddcap-skip=on $L $D1                                                         # auto -> maxsat: applies
accept 2 "selected cc .*ignoring -oddcap-skip=on" -engine=auto -oddcap-skip=on $L $C
accept 3 "" -engine=cc -no-symbreak -dualmode=off -cc-dual=off -cc-rules=none $L $M
accept 2 "" -engine=cc -cc-mutant=0 -cc-schedule=lockstep -ub-basis=off "-cc-trace=$tmp/trace.txt" $L $C
accept 2 "" -engine=auto $L $C
accept 3 "" -engine=auto $L $M
accept 2 "" -engine=auto -cc-rules=mrv -ub-basis $L $C           # auto -> cc: CC flags apply
accept 2 "" -engine=auto -card-mto $L $D1                        # auto -> maxsat: tuning flag applies
accept 2 "selected cc .*ignoring -card-mto -dualshare-stats" -engine=auto -card-mto -dualshare-stats $L $C
accept 2 "selected maxsat .*ignoring -cc-rules=mrv -ub-basis" -engine=auto -cc-rules=mrv -ub-basis $L $D2
accept 2 "" -engine=cc $L $D1                                    # dense codes still answer when forced
accept 2 "" -engine=maxsat $L $S4

# 5a. GH-152 -cc-aut (Tanner-graph automorphism candidates; LP_34_20_2 gains a verified swap map, TN_36_8_3 none)
accept 3 "" -engine=cc -cc-aut=on $L $M
accept 3 "" -engine=cc -cc-aut=off $L $M
accept 2 "" -engine=cc -cc-aut=on $L $C
accept 2 "" -engine=cc -cc-aut=on -cc-dual=off -no-symbreak -seed=2 $L $C
accept 2 "" -engine=auto -cc-aut=on $L $C                                                            # auto -> cc: applies
accept 2 "selected maxsat .*ignoring -cc-aut=on" -engine=auto -cc-aut=on $L $D1
vgrep 2 "^c cc aut: Tanner graph (qubits, Hx rows, Hz rows): [0-9]* generator(s), [0-9]* qubit orbit(s), group" -v -engine=cc -cc-aut=on $L $C
vgrep 2 "^c cc aut: Tanner swap map: verified as XZ-dual map: X half only" -v -engine=cc -cc-aut=on $L $C
vgrep 3 "^c cc aut: Tanner swap map: none" -v -engine=cc -cc-aut=on $L $M
vgrep 2 "^c cc aut: Tanner swap map: verified as XZ-dual map: X half only" -v -engine=cc $L $C   # default on since 2026-10-28
vgrep 2 "^c cc aut: Tanner graph (qubits, Hx rows, Hz rows): [0-9]* generator(s)" -v -engine=auto $L $C   # auto -> cc: default on
runs=$((runs + 1)); run -v -engine=cc -cc-aut=off $L $C   # off: no -cc-aut output at all (the search before GH-152)
if [[ $rc -ne 0 ]] || grep -q "cc aut" <<<"$out"; then echo "FAIL (-cc-aut=off printed aut lines): rc=$rc" >&2; fails=$((fails + 1)); fi

# 5b. GH-140 -ub-search
accept 3 "" -engine=cc -ub-search=on $L $M
accept 3 "" -engine=cc -ub-search=off $L $M
accept 2 "" -engine=cc -ub-search=budget:1 $L $C
accept 3 "" -engine=cc -ub-search=budget:0.5 -cc-ub-pre=0.1 -cc-ub-share=0.2 -cc-ub-triples=100 -cc-ub-slack=2 -cc-ub-hits=0 -seed=3 $L $M
accept 3 "" -engine=cc -ub-search=on -cc-ub-share=0 -cc-ub-pre=0 -cc-dual=off -cc-schedule=sequential $L $M
accept 2 "" -engine=auto -ub-search=on $L $C                                                         # auto -> cc: applies
accept 2 "selected maxsat .*ignoring -ub-search=on" -engine=auto -ub-search=on $L $D1
vgrep 3 "^c cc: ub-search: pre-pass 0.100s, share 0.200 of wall time (/16 after 16 re-hits of U or a plateau), cap 0.500000s" -v -engine=cc -ub-search=budget:0.5 -cc-ub-pre=0.1 -cc-ub-share=0.2 $L $M
vgrep 3 "^c cc: X half ub-search: rank H [0-9]*, information set [0-9]*, triples on, slack 4" -v -engine=cc -ub-search=on -cc-ub-triples=1000 $L $M
vgrep 3 "^c cc-stats: ub-search X: iterations [0-9]*, finder time" -engine=cc -ub-search=on -cc-stats $L $M
# finder-only diagnostic: an upper bound, no answer (s UNKNOWN, rc 1), d_ub kept
runs=$((runs + 1)); run -engine=cc -ub-search=budget:0.2 -cc-ub-only $L TN_72_8_8
if [[ $rc -ne 1 ]] || [[ "$(grep '^c d_ub:' <<<"$out" | tail -1)" != "c d_ub: 8" ]] || ! grep -qx "s UNKNOWN" <<<"$out" \
    || grep -q "^c d_lb: [0-9]" <<<"$out"; then
    echo "FAIL (-cc-ub-only: expected d_ub 8 and s UNKNOWN): rc=$rc stdout: $out" >&2; fails=$((fails + 1))
fi
# mutants 11/12 on BB_90_8_10 (weight-6 stabilizer rows, d = 10): 11 must trap (bounds withdrawn), 12 must answer wrongly
runs=$((runs + 1)); run -engine=cc -ub-search=budget:0.2 -cc-ub-pre=1 -cc-mutant=11 $L BB_90_8_10
if [[ $rc -ne 1 ]] || [[ "$(grep '^c d_ub:' <<<"$out" | tail -1)" != "c d_ub: -" ]] || ! grep -qx "s UNKNOWN" <<<"$out" \
    || ! grep -q "ub-search word failed verification" <<<"$err"; then
    echo "FAIL (mutant 11: expected a verification trap): rc=$rc stdout: $out stderr: $err" >&2; fails=$((fails + 1))
fi
runs=$((runs + 1)); run -engine=cc -ub-search=budget:0.2 -cc-ub-pre=1 -cc-mutant=12 $L BB_90_8_10
if ! grep -Eq '^o [0-9]+$' <<<"$out" || grep -qx "o 10" <<<"$out"; then
    echo "FAIL (mutant 12: expected a wrong answer): rc=$rc stdout: $out" >&2; fails=$((fails + 1))
fi
accept 10 "" -engine=cc -ub-search=budget:0.2 -cc-ub-pre=1 $L BB_90_8_10                            # canonical

# 6. -seed: one flag for both engines (-cc-seed = alias for CC)
accept 3 "" -seed=0 $L $M
accept 3 "" -seed=3 $L $M
accept 3 "" -engine=maxsat -seed=2 -card-mto $L $M
accept 3 "" -joint -seed=1 $L $M
accept 2 "" -engine=cc -seed=2 $L $C
accept 2 "" -engine=cc -seed=2 -cc-seed=2 $L $C
accept 2 "" -engine=auto -seed=4 $L $C
accept 2 "" -engine=auto -seed=4 $L $D1
vgrep 3 "^c solver: MaxCDCL, cardinality encoding: .*, seed 3 (rnd-seed [0-9]*)$" -v -seed=3 $L $M
vgrep 3 "^c solver: MaxCDCL, cardinality encoding: Sinz+MTO (default, Sinz if n<=100)$" -v -seed=0 $L $M   # main's line
vgrep 2 "^c solver: CC .*cc-seed 5" -v -engine=cc -seed=5 $L $C

# 7. -engine=auto decision (printed with -v) and the CC banner
vgrep 2 "^c engine: auto -> maxsat (.*row weight > 32.*: dense)$" -v -engine=auto $L $D1
vgrep 2 "^c engine: auto -> maxsat (.*mean row weight > n/4.*: dense)$" -v -engine=auto $L $D2
vgrep 2 "^c engine: auto -> cc (.*: sparse " -v -engine=auto $L $S4
vgrep 3 "^c engine: auto -> cc (.*: sparse " -v -engine=auto $L $M
vgrep 2 "^c DistQLDPC .*(connected-cluster level search)$" -v -engine=cc $L $C
vgrep 2 "^c cc: rules .*dual on (verified map in use)" -v -engine=cc $L $D1
vgrep 2 "^c cc: rules .*dual on (no verified map: both halves)" -v -engine=cc -dualmode=off $L $D1
vgrep 2 "^c cc: rules .*dual off" -v -engine=cc -cc-dual=off $L $D1
# 7b. GH-133: default rule set, parity decision per half, level skip, odd-cap skip on the MaxSAT path
vgrep 2 "^c cc: rules excl,pack,orbf,parity,leaf,overlap,charge, " -v -engine=cc $L $C
vgrep 2 "^c cc: rules excl,pack,orbf,parity,leaf,overlap, " -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap $L $C
vgrep 2 "^c cc: rules excl,pack,orbf,parity,leaf, " -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf $L $C
vgrep 2 "^c cc: rules excl,pack,orbf, " -v -engine=cc -cc-rules=excl,pack,orbf $L $C
vgrep 2 "^c cc: X half parity: on (column weights 3..5, all odd)" -v -engine=cc $L $C
vgrep 3 "^c cc: X half parity: off (column weights 2..4, an even weight present)" -v -engine=cc $L $M
vgrep 3 "^c cc: Z half parity: off (column weights 2..3, an even weight present)" -v -engine=cc $L $M
vgrep 2 "^c cc: X half parity: rule off" -v -engine=cc -cc-rules=excl,pack,orbf $L $C
vgrep 2 "^c cc: X half level 1 skipped\|^c d_lb: 2" -v -engine=cc $L $C
vgrep 2 "^c cc-stats: X level 2 FOUND nodes [0-9]* seeds [0-9]* closed [0-9]* nocand [0-9]* packprune [0-9]* parprune 0 leaf1 [0-9]* leaf2 [0-9]* ovtight [0-9]* ovforbid [0-9]* time" -engine=cc -cc-stats -ub-basis=off -ub-search=off $L $C
vgrep 3 "^c cc-stats: X level 1 EMPTY nodes [0-9]* seeds [0-9]* closed [0-9]* nocand [0-9]* packprune [0-9]* parprune 0 leaf1 [0-9]* leaf2 0 ovtight [0-9]* ovforbid [0-9]* time" -engine=cc -cc-stats $L $M
vgrep 3 "^c cc-stats: X level 2 EMPTY .* ovtight 0 ovforbid 0 time" -engine=cc -cc-stats -cc-rules=excl,pack,orbf,parity,leaf $L $M
# 7b'. GH-157: the node-lower-bound line and stats lines appear only with the new rules
vgrep 3 "^c cc: node lower bound charge at remaining budget >= 3 and budget - packing <= 0, auto off below 40 % (GH-157)" -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge $L $M
vgrep 3 "^c cc-stats: X level 2 lb lbeval [0-9]* chgprune [0-9]* lbdead [0-9]*" -engine=cc -cc-stats -cc-rules=charge -cc-lb-minr=1 -cc-lb-gap=5 $L $M
vgrep 3 "^c cc-stats: X level 2 lbprune-by-budget" -engine=cc -cc-stats -cc-rules=charge -cc-lb-minr=1 $L $M
runs=$((runs + 1)); run -v -engine=cc -cc-stats -cc-rules=excl,pack,orbf,parity,leaf,overlap $L $M
if grep -q "node lower bound\|lbeval\|lbprune" <<<"$out"; then echo "FAIL (GH-157 lines printed without charge)" >&2; fails=$((fails + 1)); fi
vgrep 3 "^c cc: node lower bound charge at remaining budget >= 3" -v -engine=cc $L $M   # GH-157: charge is a default rule
# 7c. GH-138: overlap decision per half (K = same-type stabilizer rows; TN_36_8_3 rows have weight 4..6)
vgrep 3 "^c cc: X half overlap: on ([0-9]* stabilizer rows of Hx, weights [0-9]*\.\.[0-9]*, 0 forbidden from the start)" -v -engine=cc $L $M
vgrep 3 "^c cc: Z half overlap: on ([0-9]* stabilizer rows of Hz, weights " -v -engine=cc $L $M
vgrep 3 "^c cc: X half overlap: rule off" -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf $L $M
vgrep 3 "^c cc: X half overlap: on (TEST MUTANT 9: parity checks used, [0-9]* stabilizer rows of Hz" -v -engine=cc -cc-mutant=9 $L $M
vgrep 2 "^c oddcap X: column weights 3..5 all odd (every logical has even weight) -> odd caps skipped" -v -oddcap-skip=on $L $C
vgrep 2 "^c oddcap: X half cap 1 skipped (odd cap, no probe): lb 2" -v -oddcap-skip=on $L $C
vgrep 3 "^c oddcap X: column weights 2..4 (an even weight present) -> odd caps kept" -v -oddcap-skip=on $L $M
runs=$((runs + 1)); run -v -oddcap-skip=off $L $C
if grep -q "^c oddcap" <<<"$out"; then echo "FAIL (-oddcap-skip=off must not print oddcap lines)" >&2; fails=$((fails + 1)); fi
runs=$((runs + 1)); run -v $L $C
if ! grep -q "^c oddcap" <<<"$out"; then echo "FAIL (default is -oddcap-skip=on since 2026-10-21: oddcap lines expected)" >&2; fails=$((fails + 1)); fi

# 7d. GH-144 -ub-pre (split MaxSAT path): values, conflicts, output, default identity
for f in -ub-pre -ub-pre= -ub-pre=0 -ub-pre=-1 -ub-pre=x -ub-pre=1s -ub-pre=ON -ub-preX -ub-pre=yes \
         "-ub-pre=1 -ub-pre-hits=x" "-ub-pre=1 -ub-pre-hits=-1" "-ub-pre=1 -ub-pre-plateau=0" "-ub-pre=1 -ub-pre-plateau=x" \
         "-ub-pre=1 -ub-pre-bogus=1"; do
    reject "invalid" $f $L $M
done
reject "need -ub-pre=S" -ub-pre=off -ub-pre-hits=4 $L $M   # -ub-pre is on by default since 2026-10-23
reject "need -ub-pre=S" -ub-pre=1 -ub-pre=off -ub-pre-plateau=10 $L $M   # the last -ub-pre wins
reject "no effect with -engine=cc" -engine=cc -ub-pre=on $L $C
accept 3 "" -ub-pre=on $L $M
accept 10 "" -ub-pre=1 -ub-pre-hits=0 -ub-pre-plateau=5 $L BB_90_8_10
vgrep 10 "^c ub-pre X: converged (plateau) after " -v -ub-pre=1 -ub-pre-hits=0 -ub-pre-plateau=5 $L BB_90_8_10
vgrep 10 "^c ub-pre: U0 after .*(time budget; " -v -ub-pre=0.2 -ub-pre-hits=0 -ub-pre-plateau=1000000000 $L BB_90_8_10
reject "needs the split MaxSAT path" -ub-pre=1 -joint $L $M
reject "needs the split MaxSAT path" -joint -ub-pre=0.5 -card-mto $L $M
reject "needs the split MaxSAT path" -ub-pre=1 -roundingsat=/nonexistent $L $M
accept 3 "" -ub-pre=1 $L $M
accept 3 "" -ub-pre=0.5 -card-mto -seed=3 $L $M
accept 3 "" -ub-pre=off $L $M
accept 2 "" -ub-pre=2 -oddcap-skip=off -no-symbreak -dualmode=off $L $C
accept 2 "" -ub-pre=2 -dualmode=skip $L $C
accept 10 "" -ub-pre=1 $L BB_90_8_10
accept 8 "" -ub-pre=1 -card-mto $L TN_72_8_8
accept 2 "" -engine=auto -ub-pre=1 $L $D1                                                               # auto -> maxsat: applies
accept 2 "selected cc .*ignoring -ub-pre=1" -engine=auto -ub-pre=1 $L $C
vgrep 10 "^c ub-pre: U0 after [0-9.]*s (both halves converged; iterations X [0-9]* Z [0-9]*, words X [0-9]* Z [0-9]*): 10 (X " -v -ub-pre=1 $L BB_90_8_10
vgrep 10 "^c witness X (ub-pre): " -v -ub-pre=1 $L BB_90_8_10
vgrep 3 "^c ub-pre Z: rank H [0-9]*, information set [0-9]*, seed 4, collision stern p 2 l [0-9]* walk 32 batch 1 refresh 0$" -v -ub-pre=1 -seed=4 $L $M   # -ub-isd=stern by default since 2026-10-23
# default output: the pre-pass bound is the first c d_ub line (before any c d_lb), and the answer follows
runs=$((runs + 1)); run -ub-pre=1 $L TN_72_8_8
if [[ $rc -ne 0 ]] || [[ "$(grep -m1 '^c d_' <<<"$out")" != "c d_ub: 8" ]] || ! grep -qx "o 8" <<<"$out"; then
    echo "FAIL (-ub-pre: expected the first bound line c d_ub: 8 and o 8): rc=$rc stdout: $out" >&2; fails=$((fails + 1))
fi
# Phase 1 stops below U0 - 1 and Phase 2a probes U0 - 1 (BB_90_8_10: all-odd columns, U0 = 10 -> even cap 8)
runs=$((runs + 1)); run -v -ub-pre=1 $L BB_90_8_10
if grep -Eq "^c CSS interleave: . half cap (9|1[0-9]|[2-9][0-9]) " <<<"$out" || ! grep -q "^c CSS interleave: X half cap 8 lb [0-9]* feasibility -> NONE" <<<"$out"; then
    echo "FAIL (-ub-pre: expected no probe cap >= U0 - 1 = 9 and the Phase 2a probe at cap 8): $(grep 'CSS interleave' <<<"$out")" >&2; fails=$((fails + 1))
fi
# -ub-pre=off prints no ub-pre line (the previous search); the default (on since 2026-10-23) does
runs=$((runs + 1)); run -v -ub-pre=off $L BB_90_8_10
if grep -q "ub-pre" <<<"$out" || ! grep -qx "o 10" <<<"$out"; then echo "FAIL (no ub-pre output expected with -ub-pre=off)" >&2; fails=$((fails + 1)); fi
runs=$((runs + 1)); run -v $L BB_90_8_10
if ! grep -q "ub-pre" <<<"$out" || ! grep -qx "o 10" <<<"$out"; then echo "FAIL (default: ub-pre output and o 10 expected)" >&2; fails=$((fails + 1)); fi

# 7e. GH-146 -ub-isd (collision mode of the shared finder): values, conflicts, output, mutants, off = unchanged
for f in -ub-isd= -ub-isd=bogus -ub-isd=sternx -ub-isd=STERN -ub-isd=stern: -ub-isd=stern:0 -ub-isd=stern:3 -ub-isd=stern:x \
         -ub-isd=stern:2,21 -ub-isd=stern:2,-1 -ub-isd=dumer:2,1,100001 -ub-isd=stern:2,1,1,4097 -ub-isd=stern:2,1,1,0 -ub-isd=stern:2,1,1,1,1000000001 \
         -ub-isd=stern:2,,,,,1 -ub-isd=stern:2,1x; do
    reject "invalid -ub-isd" -ub-pre=1 "$f" $L $M
done
reject "needs the finder" -ub-pre=off -ub-isd=stern $L $M   # -ub-pre / -ub-search are on by default since 2026-10-23
reject "needs the finder" -ub-pre=off -ub-isd=off $L $M
reject "needs the finder" -engine=cc -ub-search=off -ub-isd=stern $L $C
reject "needs the finder" -engine=cc -ub-search=on -ub-search=off -ub-isd=dumer $L $C
accept 10 "" -ub-pre=1 -ub-isd=stern $L BB_90_8_10
accept 10 "" -ub-pre=1 -ub-isd=dumer:1 $L BB_90_8_10
accept 8 "" -ub-pre=1 -ub-isd=stern:2,,0 -card-mto $L TN_72_8_8
accept 3 "" -ub-pre=0.5 -ub-isd=off $L $M
accept 10 "" -engine=cc -ub-search=on -ub-isd=stern $L BB_90_8_10
accept 10 "" -engine=cc -ub-search=budget:0.2 -cc-ub-pre=1 -ub-isd=dumer:2,4,0,2,3 $L BB_90_8_10
accept 2 "" -engine=auto -ub-search=on -ub-isd=stern $L $C
accept 2 "" -engine=auto -ub-pre=1 -ub-isd=stern $L $D1
vgrep 10 "^c cc: X half ub-search: rank H [0-9]*, information set [0-9]*, triples off, slack 4, li-cap 64, collision stern p 2 l 6 walk 4 batch 2 refresh 0$" \
      -v -engine=cc -ub-search=on -ub-isd=stern:2,6,4,2 $L BB_90_8_10
vgrep 10 "^c cc: X half ub-search: rank H [0-9]*, information set [0-9]*, triples off, slack 4, li-cap 64$" -v -engine=cc -ub-search=on -ub-isd=off $L BB_90_8_10
vgrep 10 "^c cc-stats: ub-search X collision: rounds [0-9]*, colliding pairs [0-9]* (nontrivial [0-9]*)" -engine=cc -ub-search=on -ub-isd=dumer -cc-stats $L BB_90_8_10
vgrep 10 "^c ub-pre X: rank H [0-9]*, information set [0-9]*, seed 0, collision dumer p 2 l [0-9]* walk 32 batch 1 refresh 0$" -v -ub-pre=1 -ub-isd=dumer $L BB_90_8_10
vgrep 10 "^c ub-pre X: rank H [0-9]*, information set [0-9]*, seed 0$" -v -ub-pre=1 -ub-isd=off $L BB_90_8_10
# default (since 2026-10-23): stern with the S0 parameters on both finders
vgrep 10 "^c ub-pre X: rank H [0-9]*, information set [0-9]*, seed 0, collision stern p 2 l [0-9]* walk 32 batch 1 refresh 0$" -v $L BB_90_8_10
vgrep 10 "^c cc: X half ub-search: rank H [0-9]*, information set [0-9]*, triples off, slack 4, li-cap 64, collision stern p 2 l [0-9]* walk 32 batch 1 refresh 0$" -v -engine=cc $L BB_90_8_10
runs=$((runs + 1)); run -engine=cc -ub-search=budget:0.2 -cc-ub-only -ub-isd=stern $L TN_72_8_8
if [[ $rc -ne 1 ]] || [[ "$(grep '^c d_ub:' <<<"$out" | tail -1)" != "c d_ub: 8" ]] || ! grep -qx "s UNKNOWN" <<<"$out"; then
    echo "FAIL (-cc-ub-only -ub-isd=stern: expected d_ub 8 and s UNKNOWN): rc=$rc stdout: $out" >&2; fails=$((fails + 1))
fi
for m in stern dumer; do   # collision mode: mutant 11 must trap, mutant 12 (unverified reporting) must answer wrongly
    runs=$((runs + 1)); run -engine=cc -ub-search=budget:0.2 -cc-ub-pre=1 -cc-mutant=11 -ub-isd=$m $L BB_90_8_10
    if [[ $rc -ne 1 ]] || [[ "$(grep '^c d_ub:' <<<"$out" | tail -1)" != "c d_ub: -" ]] || ! grep -q "ub-search word failed verification" <<<"$err"; then
        echo "FAIL (mutant 11, -ub-isd=$m: expected a verification trap): rc=$rc stdout: $out stderr: $err" >&2; fails=$((fails + 1))
    fi
    runs=$((runs + 1)); run -engine=cc -ub-search=budget:0.2 -cc-ub-pre=1 -cc-mutant=12 -ub-isd=$m $L BB_90_8_10
    if ! grep -Eq '^o [0-9]+$' <<<"$out" || grep -qx "o 10" <<<"$out"; then
        echo "FAIL (mutant 12, -ub-isd=$m: expected a wrong answer): rc=$rc stdout: $out" >&2; fails=$((fails + 1))
    fi
done

# 7f. GH-148 -stab-overlap (split MaxSAT path): values, conflicts, output; default auto, off = the previous search
for f in -stab-overlap -stab-overlap= -stab-overlap=yes -stab-overlap=ON -stab-overlapX "-stab-overlap=on -stab-overlap-enc=x" "-stab-overlap=on -stab-overlap-enc=auto" \
         "-stab-overlap=on -stab-overlap-enc=" "-stab-overlap=on -stab-overlap-ratio=x" "-stab-overlap=on -stab-overlap-ratio=-1" \
         "-stab-overlap=on -stab-overlap-bogus=1"; do
    reject "invalid" $f $L $M
done
reject "needs -stab-overlap=on or -stab-overlap=auto" -stab-overlap=off -stab-overlap-enc=seq $L $M   # default auto: the tuning flags apply to it
accept 3 "" -stab-overlap-enc=seq $L $M
accept 3 "" -stab-overlap-ratio=1 -card-mto $L $M
accept 3 "" -stab-overlap=off -joint $L $M
reject "needs -stab-overlap=on or -stab-overlap=auto" -stab-overlap=on -stab-overlap=off -stab-overlap-ratio=1 $L $M   # last wins
reject "must come after" -stab-overlap-ratio=1 -stab-overlap=on $L $M
reject "no effect with -engine=cc" -engine=cc -stab-overlap=on $L $C
reject "no effect with -engine=cc" -engine=cc -stab-overlap=auto $L $C
reject "needs the split MaxSAT path" -stab-overlap=on -joint $L $M
reject "needs the split MaxSAT path" -joint -stab-overlap=auto -card-mto $L $M
reject "needs the split MaxSAT path" -stab-overlap=on -roundingsat=/nonexistent $L $M
accept 3 "" -stab-overlap=on $L $M
accept 3 "" -stab-overlap=auto -card-mto -seed=3 $L $M
accept 3 "" -stab-overlap=off $L $M
accept 2 "" -stab-overlap=on -stab-overlap-enc=seq -oddcap-skip=off -no-symbreak -dualmode=off $L $C
accept 2 "" -stab-overlap=on -stab-overlap-enc=bin -dualmode=skip -ub-pre=off $L $C
accept 10 "" -stab-overlap=on $L BB_90_8_10
accept 10 "" -stab-overlap=auto -stab-overlap-ratio=1.5 $L BB_90_8_10
accept 8 "" -stab-overlap=on -card-mto $L TN_72_8_8
accept 8 "" -stab-overlap=on -stab-overlap-enc=seq $L TN_72_8_8
accept 8 "" -stab-overlap=auto -stab-overlap-enc=native -card-mto -seed=2 $L TN_72_8_8
accept 10 "" -stab-overlap=on -stab-overlap-enc=clauses -ub-pre=off $L BB_90_8_10
runs=$((runs + 1)); run -frontier-stats -stab-overlap=on $L BB_90_8_10
if [[ $rc -ne 0 ]] || ! grep -q "^c OVERLAP X cap 8: rows 45 props [0-9]* conflicts [0-9]* cached_clauses [0-9]*$" <<<"$err"; then echo "FAIL (-frontier-stats with the native propagator: c OVERLAP line expected)" >&2; fails=$((fails + 1)); fi
runs=$((runs + 1)); run -frontier-stats -stab-overlap=on -stab-overlap-enc=bin $L BB_90_8_10
if grep -q "^c OVERLAP" <<<"$err"; then echo "FAIL (no c OVERLAP line with clause encodings)" >&2; fails=$((fails + 1)); fi
accept 2 "" -engine=auto -stab-overlap=on $L $D1                                                        # auto -> maxsat: applies
accept 2 "selected cc .*ignoring -stab-overlap=on" -engine=auto -stab-overlap=on $L $C
vgrep 10 "^c stab-overlap X: 45 of 45 rows used (0 rejected: H g != 0 or G g != 0; 0 duplicates); |g| -> rows: 6:45 (<= 3); binomial rows 45, counter rows 0; per probe 675 clauses, 0 aux vars$" -v -stab-overlap=on -stab-overlap-enc=clauses $L BB_90_8_10
vgrep 10 "^c stab-overlap X: 45 of 45 rows used (0 rejected: H g != 0 or G g != 0; 0 duplicates); |g| -> rows: 6:45 (<= 3); native propagator rows 45 (no clauses)$" -v -stab-overlap=on $L BB_90_8_10
vgrep 10 "^c stab-overlap X: 45 of 45 rows used .* binomial rows 45, counter rows 0" -v -stab-overlap=auto -stab-overlap-enc=bin $L BB_90_8_10
vgrep 10 "^c stab-overlap Z: 45 of 45 rows used .* binomial rows 0, counter rows 45; per probe 1440 clauses, 675 aux vars$" -v -stab-overlap=on -stab-overlap-enc=seq $L BB_90_8_10
vgrep 10 "^c stab-overlap X cap 8: 45 of 45 rows active (ratio 2.00)$" -v -stab-overlap=auto $L BB_90_8_10
vgrep 10 "^c stab-overlap X cap 4: 0 of 45 rows active (ratio 2.00)$" -v -stab-overlap=auto $L BB_90_8_10
vgrep 10 "^c stab-overlap X cap 4: 45 of 45 rows active (ratio 0.00)$" -v -stab-overlap=on $L BB_90_8_10
runs=$((runs + 1)); run -v -stab-overlap=off $L BB_90_8_10
if grep -q "stab-overlap" <<<"$out$err"; then echo "FAIL (-stab-overlap=off must not print stab-overlap lines)" >&2; fails=$((fails + 1)); fi
# default (auto since the PI's adoption decision): the same lines as -stab-overlap=auto
vgrep 10 "^c stab-overlap X: 45 of 45 rows used (0 rejected: H g != 0 or G g != 0; 0 duplicates); |g| -> rows: 6:45 (<= 3); native propagator rows 45 (no clauses)$" -v $L BB_90_8_10
vgrep 10 "^c stab-overlap X cap 8: 45 of 45 rows active (ratio 2.00)$" -v $L BB_90_8_10
vgrep 10 "^c stab-overlap X cap 4: 0 of 45 rows active (ratio 2.00)$" -v $L BB_90_8_10
runs=$((runs + 1)); run -frontier-stats $L BB_90_8_10
if [[ $rc -ne 0 ]] || ! grep -q "^c OVERLAP X cap 8: rows 45 props [0-9]* conflicts [0-9]* cached_clauses [0-9]*$" <<<"$err"; then echo "FAIL (default: c OVERLAP line expected with -frontier-stats)" >&2; fails=$((fails + 1)); fi
runs=$((runs + 1)); run -v -joint $L $M
if grep -q "stab-overlap" <<<"$out$err"; then echo "FAIL (default auto is silently off with -joint: no stab-overlap lines expected)" >&2; fails=$((fails + 1)); fi

# 8. a CC trap withdraws the bounds already sent (test mutant 2 with the GH-124 rule set traps on LP_136_32_4 after
#    emitting d_lb lines; with the GH-133 rules the same mutant answers wrongly instead, which this check does not need)
runs=$((runs + 1))
run -engine=cc -cc-mutant=2 -cc-rules=excl,pack,orbf -ub-search=off $L LP_136_32_4
if [[ $rc -ne 1 ]] || ! grep -q "^c d_lb: [0-9]" <<<"$out" || [[ "$(grep '^c d_lb:' <<<"$out" | tail -1)" != "c d_lb: -" ]] \
    || [[ "$(grep '^c d_ub:' <<<"$out" | tail -1)" != "c d_ub: -" ]] || ! grep -q "^c status: UNKNOWN (CC engine stopped without an answer" <<<"$out" \
    || ! grep -qx "s UNKNOWN" <<<"$out"; then
    echo "FAIL (expected withdrawn bounds after a CC trap): rc=$rc stdout: $out" >&2
    fails=$((fails + 1))
fi

# 7g. GH-162 tiebreak (opt-in -cc-rules token; needs overlap): values, -v lines, mutants 17/18 accepted, no line without it
reject "need -engine=cc or -engine=auto" -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak $L $M
for f in -cc-rules=Tiebreak -cc-rules=tiebreak, -cc-rules=tie -cc-mutant=16 -cc-mutant=25; do
    reject "invalid\|unknown" -engine=cc "$f" $L $C
done
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak $L $M
accept 3 "" -engine=cc -cc-rules=overlap,tiebreak -cc-seed=2 -cc-dual=off $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv -cc-aut=off -no-symbreak $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak $L $M                  # default rules (GH-157) + tiebreak
vgrep 3 "^c cc: rules excl,pack,orbf,parity,leaf,overlap,tiebreak,charge, " -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak $L $M
vgrep 3 "^c cc: rules excl,pack,orbf,parity,leaf,overlap,tiebreak, " -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak $L $M
vgrep 3 "^c cc: X half tiebreak: on$" -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak $L $M
vgrep 3 "^c cc: X half tiebreak: [0-9]* of [0-9]* rows even: limit |g|/2 - 1 on g minus first(g) (order: the seed, then earlier orbits, then descending label)" \
    -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak $L $M
vgrep 3 "^c cc: X half tiebreak: idle (needs overlap rows)" -v -engine=cc -cc-rules=excl,pack,orbf,tiebreak $L $M
vgrep 3 "^c cc: X half tiebreak: on \[TEST MUTANT 17: naive tie cut\]" -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak -cc-mutant=17 $L $M
vgrep 3 "^c cc: X half tiebreak: on \[TEST MUTANT 18: seed not first\]" -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak -cc-mutant=18 $L $M
runs=$((runs + 1)); run -v -cc-stats -engine=cc $L $M
if [[ $rc -ne 0 ]] || grep -q "tiebreak" <<<"$out"; then
    echo "FAIL (GH-162: a tiebreak line without the token): rc=$rc" >&2; fails=$((fails + 1))
fi

# 7h. GH-183 -cc-roworder=index|bfs and -cc-tbbase=desc|asc: values, -v lines, mutants 19/20 accepted, no line with the defaults
reject "need -engine=cc or -engine=auto" -cc-roworder=bfs $L $M
reject "need -engine=cc or -engine=auto" -cc-tbbase=asc $L $M
for f in -cc-roworder -cc-roworder= -cc-roworder=BFS -cc-roworder=dfs -cc-tbbase -cc-tbbase=up -cc-tbbase=ASC -cc-mutant=25; do
    reject "invalid\|unknown" -engine=cc "$f" $L $C
done
accept 3 "" -engine=cc -cc-roworder=bfs $L $M
accept 3 "" -engine=cc -cc-roworder=index -cc-tbbase=desc $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv -cc-roworder=bfs $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,mrv -cc-roworder=bfs $L $M   # default rules (GH-157) + tiebreak,mrv
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv -cc-roworder=bfs -cc-tbbase=asc -cc-seed=2 -cc-dual=off $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,mrv -cc-roworder=bfs -cc-aut=off -no-symbreak $L $M
accept 2 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv -cc-roworder=bfs $L $C
vgrep 3 "^c cc: X half row order: reversed BFS from the rows of the first seed ([0-9]* rows; packing scan and mrv ties)$" \
    -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv -cc-roworder=bfs $L $M
vgrep 3 "^c cc: X half tiebreak: [0-9]* of [0-9]* rows even: limit |g|/2 - 1 on g minus first(g) (order: the seed, then earlier orbits, then ascending label)" \
    -v -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak -cc-tbbase=asc $L $M
for mt in 19 20; do
    runs=$((runs + 1)); run -v -engine=cc -cc-roworder=bfs -cc-mutant=$mt $L $M
    if ! grep -q "^c cc: X half row order: .*\[TEST MUTANT $mt" <<<"$out" || ! grep -q "^warning: cc: test mutant $mt active" <<<"$err"; then
        echo "FAIL (GH-183: mutant $mt not reported): rc=$rc" >&2; fails=$((fails + 1))
    fi
done
for a in "" "-cc-roworder=index" "-cc-tbbase=desc" "-cc-roworder=index -cc-tbbase=desc"; do
    runs=$((runs + 1)); run -v -cc-stats -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak $a $L $M
    if [[ $rc -ne 0 ]] || grep -q "row order\|ascending" <<<"$out"; then
        echo "FAIL (GH-183: a row-order line with the defaults: $a): rc=$rc" >&2; fails=$((fails + 1))
    fi
done

# 7i. GH-206 -cc-roworder=auto, -cc-probe=S|switch|stay, -cc-probe-growth=F: values, -v lines, probe lines, mutant 21 accepted
reject "need -engine=cc or -engine=auto" -cc-roworder=auto $L $M
reject "need -engine=cc or -engine=auto" -cc-probe=2 $L $M
reject "need -engine=cc or -engine=auto" -cc-probe-growth=10 $L $M
for f in -cc-roworder=Auto -cc-probe -cc-probe= -cc-probe=-1 -cc-probe=x -cc-probe=1s -cc-probe=SWITCH -cc-probe-growth= \
         -cc-probe-growth=0.5 -cc-probe-growth=-2 -cc-probe-growth=x -cc-mutant=25; do
    reject "invalid\|unknown" -engine=cc "$f" $L $C
done
NB="-ub-basis=off -ub-search=off"   # no upper bound before the hit, so a probe is not skipped for lb >= U
accept 3 "" -engine=cc -cc-roworder=auto $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak -cc-roworder=auto -cc-probe=0 $L $M   # default rules (GH-157) + tiebreak
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak -cc-roworder=auto -cc-probe=0 $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak -cc-roworder=auto -cc-probe=switch -cc-seed=2 -cc-dual=off $L $M
accept 3 "" -engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv -cc-roworder=auto -cc-probe=stay -cc-tbbase=asc $L $M
accept 3 "" -engine=cc -cc-roworder=auto -cc-probe=0 -cc-probe-growth=0 $NB $L $M
accept 3 "" -engine=cc -cc-roworder=auto -cc-probe=0 -cc-probe-growth=1 $NB $L $M
accept 2 "" -engine=cc -cc-roworder=auto -cc-probe=0.5 -cc-probe-growth=100 $L $C
vgrep 3 "^c cc: X half row order: auto (A = index order, rules without mrv, from level 1; B = reversed BFS, rules with mrv, [0-9]* rows; probe at the first refuted level taking >= 0.1s (one probe))$" \
    -v -engine=cc -cc-roworder=auto $L $M
vgrep 3 "^c cc: X half auto probe at level [0-9]*: current A [0-9.]*s, B [A-Z]* nodes [0-9]* [0-9.]*s -> B (A = index, no mrv; B = bfs, mrv)$" \
    -v -engine=cc -cc-roworder=auto -cc-probe=switch $NB $L $M
vgrep 3 "^c cc-probe: X level [0-9]* B [A-Z]* nodes [0-9]* time [0-9.]*s A [0-9.]*s -> A$" -cc-stats -engine=cc -cc-roworder=auto -cc-probe=stay $NB $L $M
vgrep 3 "^c cc: X half row order: auto (.* probe at the first refuted level taking >= 0.5s, then >= 30 x the last probe level)$" \
    -v -engine=cc -cc-roworder=auto -cc-probe=0.5 -cc-probe-growth=30 $L $M
runs=$((runs + 1)); run -v -engine=cc -cc-roworder=auto -cc-mutant=21 $L $M
if ! grep -q "TEST MUTANT 21" <<<"$out" || ! grep -q "^warning: cc: test mutant 21 active" <<<"$err"; then
    echo "FAIL (GH-206: mutant 21 not reported): rc=$rc" >&2; fails=$((fails + 1))
fi
runs=$((runs + 1)); run -v -cc-stats -engine=cc -cc-roworder=bfs $L $M
if [[ $rc -ne 0 ]] || grep -q "probe" <<<"$out"; then
    echo "FAIL (GH-206: a probe line without auto): rc=$rc" >&2; fails=$((fails + 1))
# 7j. GH-181 sparse / sparseov / sparsemrv / xorunit (opt-in -cc-rules tokens): values, -v lines, mutants 22-24 (19-21 before the
#     merge with GH-162/183/206), no line without them
G=excl,pack,orbf,parity,leaf,overlap
reject "need -engine=cc or -engine=auto" -cc-rules=$G,sparse $L $M
for f in -cc-rules=Sparse -cc-rules=sparse, -cc-rules=sparseOV -cc-rules=xor -cc-rules=sparse-mrv -cc-mutant=16 -cc-mutant=25; do
    reject "invalid\|unknown" -engine=cc "$f" $L $C
done
accept 3 "" -engine=cc -cc-rules=$G,sparse $L $M
accept 3 "" -engine=cc -cc-rules=$G,sparse,sparseov,sparsemrv -cc-seed=2 -cc-dual=off $L $M
accept 3 "" -engine=cc -cc-rules=$G,sparse,sparseov,sparsemrv,xorunit -cc-aut=off -no-symbreak $L $M
accept 3 "" -engine=cc -cc-rules=xorunit,sparse $L $M
accept 2 "" -engine=cc -cc-rules=$G,sparse,sparseov,sparsemrv,xorunit,mrv $L $C
vgrep 3 "^c cc: rules $G,sparse,sparseov,sparsemrv,xorunit, " -v -engine=cc -cc-rules=$G,sparse,sparseov,sparsemrv,xorunit $L $M
vgrep 3 "^c cc: X half sparse: [1-9][0-9]* redundant rows (pair sums of Hz rows, weights [0-9]*\.\.[0-9]*)$" -v -engine=cc -cc-rules=$G,sparse $L $M
vgrep 3 "^c cc: X half sparseov: [0-9]* redundant stabilizer rows (pair sums of Hx rows" -v -engine=cc -cc-rules=$G,sparseov $L $M
vgrep 3 "^c cc: X half sparseov: idle (needs overlap)" -v -engine=cc -cc-rules=excl,pack,sparseov $L $M
vgrep 3 "^c cc: X half sparsemrv: on (fewest-candidate branching" -v -engine=cc -cc-rules=$G,sparse,sparsemrv $L $M
vgrep 3 "^c cc: X half sparsemrv: idle (no redundant rows)" -v -engine=cc -cc-rules=$G,sparsemrv $L $M
vgrep 3 "^c cc: X half xorunit: on (rows of H and the redundant rows)" -v -engine=cc -cc-rules=$G,sparse,xorunit $L $M
vgrep 3 "^c cc-stats: X level 2 gh181 spack " -cc-stats -engine=cc -cc-rules=$G,sparse $L $M
# merge with GH-157/162/183/206: the new default rules + the GH-181 tokens, with tiebreak, mrv + bfs, and auto
accept 3 "" -engine=cc -cc-rules=$G,charge,sparse,sparseov,sparsemrv $L $M
accept 3 "" -engine=cc -cc-rules=$G,charge,tiebreak,sparse,sparseov,sparsemrv $L $M
accept 3 "" -engine=cc -cc-rules=$G,charge,tiebreak,mrv,sparse,sparseov,sparsemrv -cc-roworder=bfs $L $M
accept 3 "" -engine=cc -cc-rules=$G,charge,tiebreak,sparse,sparseov,sparsemrv,xorunit -cc-roworder=auto -cc-probe=0 $L $M
vgrep 3 "^c cc: rules $G,tiebreak,sparse,sparseov,sparsemrv,charge, " -v -engine=cc -cc-rules=$G,charge,tiebreak,sparse,sparseov,sparsemrv $L $M
vgrep 3 "^c cc: X half sparsemrv: on (mrv is on everywhere)" -v -engine=cc -cc-rules=$G,sparse,sparsemrv,mrv $L $M   # sparsemrv + mrv = mrv
for mt in 22 23 24; do   # mutants are accepted values (answers may be wrong by design): the -v line names them
    runs=$((runs + 1)); run -v -engine=cc -cc-rules=$G,sparse,sparseov,xorunit -cc-mutant=$mt -ub-search=off $L $M
    if ! grep -q "TEST MUTANT $mt" <<<"$out" || ! grep -q "^warning: cc: test mutant $mt" <<<"$err"; then
        echo "FAIL (GH-181: mutant $mt not reported)" >&2; fails=$((fails + 1))
    fi
done
runs=$((runs + 1)); run -v -cc-stats -engine=cc $L $M
if [[ $rc -ne 0 ]] || grep -q "sparse\|xorunit\|gh181" <<<"$out"; then
    echo "FAIL (GH-181: a sparse/xorunit line without the tokens): rc=$rc" >&2; fails=$((fails + 1))
fi

echo "test_cc_flags: $runs checks, $fails failed"
[[ $fails -eq 0 ]] && echo "CC_FLAG_TESTS PASS" || echo "CC_FLAG_TESTS FAIL"
exit $((fails > 0))
