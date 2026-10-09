# GH-67 Tier1 result — REJECT (alignment slightly slower); layout noise floor measured

All runs: frozen binaries, one solve at a time, same session; candidate 208/208 and each relink
48/48 correct with identical emitted bounds; hashes/inputs re-verified. Diagnostic Mac host.

| Cell | Candidate ratio gate (repl.) | Relink R1 / R2 / R3 | Floor max\|r-1\| | Beyond floor |
|---|---|---|---:|---|
| BB90 OFF | 1.0027 (1.0023) | 1.0020 / 0.9977 / 0.9983 | 0.0023 | yes, slower |
| GB144 OFF | 1.0081 (1.0038) | 1.0181 / 1.0210 / 1.0107 | 0.0210 | no |
| BB108 OFF | 1.0040 (1.0033) | 1.0027 / 1.0025 / 1.0035 | 0.0035 | yes, slower |
| LP238 OFF | 1.0084 (1.0061), regression flag | 0.9983 / 1.0007 / 0.9968 | 0.0032 | yes, slower |
| BB90 MTO | 1.0045 (1.0043) | 1.0001 / 1.0009 / 0.9968 | 0.0032 | yes, slower |
| GB144 MTO | 1.0031 (1.0059) | 1.0075 / 1.0061 / 0.9954 | 0.0075 | no |
| BB108 MTO | 1.0024 (1.0036) | 0.9992 / 1.0041 / 0.9993 | 0.0041 | no |
| LP238 MTO | 1.0011 (1.0038) | 0.9992 / 0.9973 / 1.0033 | 0.0033 | no |

Candidate geomeans: gate OFF 1.0058 / MTO 1.0027; replication OFF 1.0039 / MTO 1.0044.
Fixed GH16 judge: not positive; LP238 OFF non-overlapping regression => **REJECT**.

## Layout noise floor (main learning)
Relinking the identical baseline objects in a different order moves per-cell medians by
typically 0.2–0.4%, but GB144 OFF by +1.1..+2.1% in all three relinks (GB144 OFF is the
shortest run, 0.66 s). So on this host, effects below ~0.5% are not separable from layout,
and GB144 OFF needs >2%.
Implication for earlier results (same host): GH-34's BB90/BB108 gains of -1.3..-1.5% are
3–5x the floor in those cells, supporting a real ~1% effect; its GB144 OFF cell (+0.05%)
is inside the floor. Results from other hosts/compilers (#21, #40) need their own floor.
