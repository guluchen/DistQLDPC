#!/usr/bin/env python3
"""GH-95 Tier0 trace comparison (rule fixed in PROPOSAL.md before running).

usage: cmp_traces.py BASE_DIR CAND_DIR LISTFILE [CAND_RERUN_DIR]
Each run <code>.<mode>.out holds stdout+stderr of `distqldpc <flags> -cpu-lim=L <code>`, and
<code>.<mode>.rc holds `exit=<status>`.

Normalisation: the only timing-dependent token in -v output, `detect_cpu=<x>s`, is replaced.
- Baseline completed (no 'c status: TIMEOUT'): candidate must be byte-identical after
  normalisation, with equal exit status.                                   -> IDENTICAL
- Baseline timed out: split each output at the last occurrence of the parent banner
  'c DistQLDPC — QLDPC/CSS minimum distance' (parent summary block). The baseline child part
  minus its last line (block-buffered stdout of a SIGKILLed child may end mid-line) must be a
  prefix of the candidate child part, and the first 7 lines of the parent block (banner, solver,
  matrix paths and sizes) must match. Bound lines after the kill are not compared.
  If the candidate child part is shorter than the baseline's (candidate got less far under the
  same limit), the candidate rerun from CAND_RERUN_DIR (longer limit) is used.  -> PREFIX_OK
"""
import sys, re, os
BANNER = 'c DistQLDPC — QLDPC/CSS minimum distance'
def load(d, stem):
    t = open(os.path.join(d, stem + '.out'), encoding='utf-8', errors='surrogateescape').read()
    rc = open(os.path.join(d, stem + '.rc')).read().strip()
    return re.sub(r'detect_cpu=[0-9.]+s', 'detect_cpu=<t>s', t), rc
def split(t):
    i = t.rfind(BANNER)
    assert i >= 0
    return t[:i], t[i:]
base, cand, listfile = sys.argv[1:4]
rerun = sys.argv[4] if len(sys.argv) > 4 else None
res = {'IDENTICAL': 0, 'PREFIX_OK': 0, 'FAIL': 0}
rows = []
cover = []
for line in open(listfile):
    code, mode = line.split()
    stem = code + '.' + mode
    bt, brc = load(base, stem)
    ct, crc = load(cand, stem)
    if 'c status: TIMEOUT' not in bt:
        ok = (bt == ct and brc == crc)
        note = ''
        if not ok and 'c status: TIMEOUT' in ct and rerun and os.path.exists(os.path.join(rerun, stem + '.out')):
            rt, rrc = load(rerun, stem)
            ok = (bt == rt and brc == rrc)
            note = 'identical in candidate rerun' if ok else ''
        verdict = 'IDENTICAL' if ok else 'FAIL'
        if not ok:
            note = 'completed-run mismatch (cand %s)' % ('timed out; needs rerun' if 'c status: TIMEOUT' in ct else 'differs')
    else:
        bc, bp = split(bt)
        def check(ct):
            cc, cp = split(ct)
            blines = bc.split('\n')[:-1]          # drop possibly truncated last line
            bpre = '\n'.join(blines) + ('\n' if blines else '')
            hdr = bp.split('\n')[:7] == cp.split('\n')[:7]
            return cc.startswith(bpre) and hdr, len(cc) >= len(bpre), len(bpre), cc
        ok, longer, blen, cc = check(ct)
        used = 'same limit'
        if ok and not longer:
            ok = False
        if not ok and rerun and os.path.exists(os.path.join(rerun, stem + '.out')):
            rt, _ = load(rerun, stem)
            ok2, longer2, blen, cc = check(rt)
            if ok2 and longer2:
                ok, used = True, 'candidate rerun'
        if not ok:
            # diagnose: is it a consistent prefix the other way round (candidate got less far)?
            cc0 = split(ct)[0]
            short = bc.startswith('\n'.join(cc0.split('\n')[:-1]))
            note = 'timeout prefix mismatch' + (' (candidate shorter, consistent prefix; needs rerun)' if short else '')
        else:
            note = 'baseline child lines %d covered (%s)' % (bc.count('\n'), used)
            cover.append(bc.count('\n'))
        verdict = 'PREFIX_OK' if ok else 'FAIL'
    res[verdict] += 1
    rows.append('%-22s %-8s %-10s %s' % (code, mode, verdict, note))
print('\n'.join(rows))
print('GH95_TRACE_SUMMARY runs=%d identical=%d prefix_ok=%d fail=%d' % (sum(res.values()), res['IDENTICAL'], res['PREFIX_OK'], res['FAIL']))
sys.exit(1 if res['FAIL'] else 0)
