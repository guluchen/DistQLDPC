#!/bin/bash
# GH-85 Mac Tier0 checks; serial (1 solver process), waits while TIMING_LOCK exists before each step.
L=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
cd "$W/cand85"; O=optimization/experiments/GH-85/raw/mac; mkdir -p $O/traces
wl() { while [ -e "$L" ]; do sleep 30; done; }
B=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/splitsb/bin/base; C=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/splitsb/bin/cand; G=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/splitsb/bin/gh73
wl; bash scripts/smoke_test.sh "$C" > $O/smoke.txt 2>&1; echo "smoke=$?"
:
:
:
for code in LP_34_20_2 BB_72_12_6 TN_36_8_4; do for m in default no-card; do f=""; [ $m = no-card ] && f="-no-card"
  wl; $B -v -cpu-lim=120 $f $code > $O/traces/$code.$m.base.txt 2>&1
  wl; $C -v -cpu-lim=120 -joint $f $code > $O/traces/$code.$m.cand-joint.txt 2>&1
  wl; $G -v -cpu-lim=120 $f $code > $O/traces/$code.$m.gh73.txt 2>&1
  wl; $C -v -cpu-lim=120 -no-symbreak $f $code > $O/traces/$code.$m.cand-nosb.txt 2>&1
  wl; $C -v -cpu-lim=120 $f $code > $O/traces/$code.$m.cand.txt 2>&1
  cmp -s $O/traces/$code.$m.base.txt $O/traces/$code.$m.cand-joint.txt && j=IDENTICAL || j=DIFFER
  cmp -s $O/traces/$code.$m.gh73.txt $O/traces/$code.$m.cand-nosb.txt && s=IDENTICAL || s=DIFFER
  echo "$code $m joint-vs-base=$j nosymbreak-vs-gh73=$s base:$(grep '^o ' $O/traces/$code.$m.base.txt) cand:$(grep '^o ' $O/traces/$code.$m.cand.txt)"
done; done
:
echo MAC_DONE
