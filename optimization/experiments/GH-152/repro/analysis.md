| Code | claimed lb | reproduced lb (mrv) | reproduced? | lb events (lb@s, from 18) |
|---|---:|---:|---|---|
| TN_288_2_9to24 | 22 | 22 | YES | 18@225 19@821 20@3012 21@11155 22@41377 |
| TN_324_4_9to25 | 22 | 22 | YES | 18@156 19@526 20@1794 21@6184 22@21428 |
| TN_432_8_9to29 | 23 | 23 | YES | 18@70 19@242 20@792 21@2652 22@9043 23@31033 |
| TN_496_2_17to30 | 23 | 23 | YES | 18@41 19@130 20@448 21@1470 22@4945 23@17151 |
| TN_540_4_9to34 | 23 | 23 | YES | 18@49 19@156 20@511 21@1667 22@5517 23@18618 |
| TN_576_2_9to37 | 24 | 24 | YES | 18@29 19@90 20@280 21@891 22@2898 23@9430 24@31140 |

### TN_288_2_9to24 (halves searched: X+Z; last log line at 43200 s)
- level 18: X EMPTY 1112.3M 349s @821s; Z EMPTY 815.7M 247s @472s
- level 19: X EMPTY 4082.0M 1301s @3012s; Z EMPTY 2886.6M 890s @1711s
- level 20: X EMPTY 15117.2M 4899s @11155s; Z EMPTY 10277.6M 3243s @6255s
- level 21: X EMPTY 56327.9M 18448s @41377s; Z EMPTY 36773.0M 11775s @22930s
  - `c cc: dual map detection: none (ranks Hz 143 Hx 143 [Hz;Gx] 145 [Hx;Gz] 145, 123 candidates, cpu 0.000s): both halves`
  - `c cc aut: Tanner graph (qubits, Hx rows, Hz rows): 1 generator(s), 36 qubit orbit(s), group complete, point stabiliser trivial, swap map none, 1 test(s) (0 refuted, 0 undecided), work 24906, cpu 0.000`
  - `c cc aut: Tanner swap map: none`
  - `c cc symbreak X: n=288 candidates=123 verified_generators=1 orbits=36 detect_cpu=0.001s clause=orbit-chain`
  - `c cc symbreak Z: n=288 candidates=123 verified_generators=1 orbits=36 detect_cpu=0.001s clause=orbit-chain`
  - status: `c d_lb: 22`
  - status: `c status: TIMEOUT (child killed after -cpu-lim)`
  - status: `c d  : UNKNOWN`
  - status: `s UNKNOWN`

### TN_324_4_9to25 (halves searched: X+Z; last log line at 43200 s)
- level 18: X EMPTY 616.1M 194s @526s; Z EMPTY 573.8M 176s @332s
- level 19: X EMPTY 2028.1M 652s @1794s; Z EMPTY 1958.9M 616s @1142s
- level 20: X EMPTY 6761.4M 2229s @6184s; Z EMPTY 6728.9M 2161s @3955s
- level 21: X EMPTY 22790.9M 7626s @21428s; Z EMPTY 23231.3M 7618s @13802s
  - `c cc: dual map detection: none (ranks Hz 160 Hx 160 [Hz;Gx] 164 [Hx;Gz] 164, 85 candidates, cpu 0.002s): both halves`
  - `c cc aut: Tanner graph (qubits, Hx rows, Hz rows): 1 generator(s), 36 qubit orbit(s), group complete, point stabiliser trivial, swap map none, 1 test(s) (0 refuted, 0 undecided), work 29937, cpu 0.000`
  - `c cc aut: Tanner swap map: none`
  - `c cc symbreak X: n=324 candidates=85 verified_generators=1 orbits=36 detect_cpu=0.001s clause=orbit-chain`
  - `c cc symbreak Z: n=324 candidates=85 verified_generators=1 orbits=36 detect_cpu=0.001s clause=orbit-chain`
  - status: `c d_lb: 22`
  - status: `c status: TIMEOUT (child killed after -cpu-lim)`
  - status: `c d  : UNKNOWN`
  - status: `s UNKNOWN`

### TN_432_8_9to29 (halves searched: X+Z; last log line at 43200 s)
- level 18: X EMPTY 269.9M 102s @242s; Z EMPTY 210.4M 70s @141s
- level 19: X EMPTY 893.1M 315s @792s; Z EMPTY 683.8M 235s @477s
- level 20: X EMPTY 2986.3M 1072s @2652s; Z EMPTY 2249.3M 788s @1580s
- level 21: X EMPTY 10080.1M 3705s @9043s; Z EMPTY 7476.7M 2686s @5338s
- level 22: X EMPTY 34327.6M 12794s @31033s; Z EMPTY 25092.9M 9197s @18240s
  - `c cc: dual map detection: none (ranks Hz 212 Hx 212 [Hz;Gx] 220 [Hx;Gz] 220, 146 candidates, cpu 0.002s): both halves`
  - `c cc aut: Tanner graph (qubits, Hx rows, Hz rows): 2 generator(s), 36 qubit orbit(s), group complete, point stabiliser trivial, swap map none, 2 test(s) (0 refuted, 0 undecided), work 46773, cpu 0.002`
  - `c cc aut: Tanner swap map: none`
  - `c cc symbreak X: n=432 candidates=147 verified_generators=2 orbits=36 detect_cpu=0.003s clause=orbit-chain`
  - `c cc symbreak Z: n=432 candidates=147 verified_generators=2 orbits=36 detect_cpu=0.003s clause=orbit-chain`
  - status: `c d_lb: 23`
  - status: `c status: TIMEOUT (child killed after -cpu-lim)`
  - status: `c d  : UNKNOWN`
  - status: `s UNKNOWN`

### TN_496_2_17to30 (halves searched: X; last log line at 43200 s)
- level 18: X EMPTY 274.4M 90s @131s
- level 19: X EMPTY 887.9M 317s @448s
- level 20: X EMPTY 2973.4M 1022s @1470s
- level 21: X EMPTY 9924.2M 3475s @4945s
- level 22: X EMPTY 34147.5M 12206s @17151s
  - `c cc: dual map detection: none (ranks Hz 247 Hx 247 [Hz;Gx] 249 [Hx;Gz] 249, 43 candidates, cpu 0.002s): both halves`
  - `c cc aut: Tanner graph (qubits, Hx rows, Hz rows): 1 generator(s), 16 qubit orbit(s), group complete, point stabiliser trivial, swap map found, 4 test(s) (2 refuted, 0 undecided), work 61722, cpu 0.00`
  - `c cc aut: Tanner swap map: verified as XZ-dual map: X half only`
  - `c cc symbreak X: n=496 candidates=43 verified_generators=2 orbits=16 detect_cpu=0.001s clause=orbit-chain`
  - `c cc: dual map 'tanner-swap (cc-aut)' verified: dX = dZ, searching the X half only (Z bounds mirrored)`
  - status: `c d_lb: 23`
  - status: `c status: TIMEOUT (child killed after -cpu-lim)`
  - status: `c d  : UNKNOWN`
  - status: `s UNKNOWN`

### TN_540_4_9to34 (halves searched: X+Z; last log line at 43200 s)
- level 18: X EMPTY 175.8M 61s @156s; Z EMPTY 137.7M 46s @95s
- level 19: X EMPTY 563.2M 201s @511s; Z EMPTY 433.1M 154s @310s
- level 20: X EMPTY 1829.1M 666s @1667s; Z EMPTY 1377.4M 489s @1000s
- level 21: X EMPTY 6009.4M 2240s @5517s; Z EMPTY 4426.5M 1610s @3277s
- level 22: X EMPTY 19944.9M 7554s @18617s; Z EMPTY 14368.6M 5546s @11063s
- level 23: Z EMPTY 47082.2M 17782s @36399s
  - `c cc: dual map detection: none (ranks Hz 268 Hx 268 [Hz;Gx] 272 [Hx;Gz] 272, 172 candidates, cpu 0.005s): both halves`
  - `c cc aut: Tanner graph (qubits, Hx rows, Hz rows): 2 generator(s), 36 qubit orbit(s), group complete, point stabiliser trivial, swap map none, 2 test(s) (0 refuted, 0 undecided), work 58740, cpu 0.002`
  - `c cc aut: Tanner swap map: none`
  - `c cc symbreak X: n=540 candidates=173 verified_generators=2 orbits=36 detect_cpu=0.004s clause=orbit-chain`
  - `c cc symbreak Z: n=540 candidates=173 verified_generators=2 orbits=36 detect_cpu=0.005s clause=orbit-chain`
  - status: `c d_lb: 23`
  - status: `c status: TIMEOUT (child killed after -cpu-lim)`
  - status: `c d  : UNKNOWN`
  - status: `s UNKNOWN`

### TN_576_2_9to37 (halves searched: X+Z; last log line at 43200 s)
- level 18: X EMPTY 97.4M 35s @90s; Z EMPTY 73.9M 26s @55s
- level 19: X EMPTY 303.6M 109s @280s; Z EMPTY 224.0M 81s @171s
- level 20: X EMPTY 963.8M 354s @891s; Z EMPTY 686.8M 257s @537s
- level 21: X EMPTY 3113.0M 1192s @2898s; Z EMPTY 2128.6M 815s @1706s
- level 22: X EMPTY 10218.3M 3918s @9430s; Z EMPTY 6664.0M 2614s @5512s
- level 23: X EMPTY 34051.1M 13265s @31140s; Z EMPTY 21066.2M 8444s @17874s
  - `c cc: dual map detection: none (ranks Hz 287 Hx 287 [Hz;Gx] 289 [Hx;Gz] 289, 165 candidates, cpu 0.004s): both halves`
  - `c cc aut: Tanner graph (qubits, Hx rows, Hz rows): 1 generator(s), 36 qubit orbit(s), group complete, point stabiliser trivial, swap map none, 1 test(s) (0 refuted, 0 undecided), work 51818, cpu 0.001`
  - `c cc aut: Tanner swap map: none`
  - `c cc symbreak X: n=576 candidates=165 verified_generators=1 orbits=36 detect_cpu=0.004s clause=orbit-chain`
  - `c cc symbreak Z: n=576 candidates=165 verified_generators=1 orbits=36 detect_cpu=0.004s clause=orbit-chain`
  - status: `c d_lb: 24`
  - status: `c status: TIMEOUT (child killed after -cpu-lim)`
  - status: `c d  : UNKNOWN`
  - status: `s UNKNOWN`

