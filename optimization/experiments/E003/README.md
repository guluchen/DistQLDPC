# E003 / H-004: reuse XOR gate clause buffer

**Decision: INCONCLUSIVE. Local Windows numeric filter: INCONCLUSIVE.**

One general engineering change: xor2 replaces four temporary std::vectors and
four copies into fresh solver vecs with a single local vec, cleared/refilled
between the original four clauses. Clause signs/order/weights/variable IDs
unchanged; no prefix sharing or logical-basis shortening. Baseline 24572d6d09cce9a4a5faa58300a89e0feba9da6a;
candidate 02fc219e8c2816b510d785104e64ac05caeda5f3; exact diff: implementation.patch. Isolated branch
experiment/h004-xor-clause-buffer; no merge or promotion.
Embedded MaxCDCL, matrices, attribution, scientific and result semantics unchanged.
DistQLDPC remains a downstream application/engine combination, not upstream MaxCDCL.

## Tier 0

Build PASS with identical GCC 14.4 original application Makefile flags and
verified unchanged engine objects/baseline executable. 584 production XOR
chains with signed/repeated operands, all 16 base assignments and auxiliary
extensions PASS. Six byte-identical exported WCNFs (including LP_340; export
only, no Tier 2 timing). Exhaustive CSS fixtures d=2/d=1, default/OFF/MTO,
smoke, unchanged pinned QDistSAT pilot OFF/MTO, six forced one-second timeouts
PASS. All 48 timing solves have identical certified expected distances,
objective, lower/upper bounds. Hosted cross-repo PR check remains pending;
local pilot does not replace it. No correctness anomaly.

## Tier 1 Windows diagnostics

Serial AB/BA/AB, 3/version/case/mode, verbose raw logs, 180s internal limit,
195s watchdog. No discarded sample, timeout or failure. Full wall includes
input/encoding/preprocessing/search/startup. Interactive Windows/Cygwin,
unreserved and unpinned, balanced power; no portable/research-grade timing claim.
Preregistered unchanged numeric judge in PROPOSAL.md; original controlled-host
gate unfulfilled, so no Tier 2/3.

| Case | Mode | Baseline median (s) | Candidate median (s) | Candidate/base |
|---|---|---:|---:|---:|
| BB_90_8_10 | no-card | 2.4017 | 2.4147 | 1.0054 |
| BB_90_8_10 | card-mto | 2.9157 | 2.8652 | 0.9827 |
| GB_144_12_8 | no-card | 0.9990 | 0.9995 | 1.0005 |
| GB_144_12_8 | card-mto | 1.2657 | 1.2633 | 0.9981 |
| BB_108_8_10 | no-card | 2.8658 | 2.8838 | 1.0062 |
| BB_108_8_10 | card-mto | 3.7160 | 3.6817 | 0.9908 |
| LP_238_44_6 | no-card | 1.8807 | 1.8838 | 1.0016 |
| LP_238_44_6 | card-mto | 2.1987 | 2.1984 | 0.9999 |

Equal-weight median-ratio geomeans: OFF 1.00346; MTO 0.99283.
All individual samples and ranges: raw/windows-run-01/all-medians.json.

## Learning / next action

Reducing short-lived allocations preserves the exact CNF in this experiment.
Whole-solve timings cannot isolate encoding cost; do not claim that allocation
was a hot spot or infer hardware-independent gain. If the numeric gate overlaps,
the next useful measurement is a construction-versus-search profile on the
baseline, or a controlled reproduction, before extending this idea. Do not stack
another change here. H-003 initial verified witness remains a separate untested
candidate, requiring a witness and bound-semantics review. E001/E002 retained.

## Exact dedicated-server reproduction

Offline source-only package: pinned baseline/candidate/QDistSAT, data, licenses,
runner and hash manifest; no Windows binaries. Linux exclusive reserved physical
CPU/sibling, stable governor/power, g++, make, zlib headers, Python >=3.10.
Replace CPU/reservation with real values; new empty output directory. Runner
builds both, repeats Tier 0/1 and allows LP_340 Tier 2 only on controlled Tier 1
PASS (3/version/mode, 600s/615s). No Tier 3. Worst internal budgets Tier 1
144 min, conditional Tier 2 120 min; expected Tier 1 minutes, overhead extra.

```sh
tar -xzf E003-run-package.tar.gz
cd E003-run-package
python3 server_run.py --package . --output ../E003-controlled-results --cpu 2 --exclusive-host --reservation-note 'actual exclusive reservation ID'
```

Archive SHA-256 `7d7a229c0c93c74f638e2a8c17f91a0a24728204a9a48d5aa37547dd02828a8d`; 1585 payload hashes verified. Retain all controlled outputs; never overwrite this run.
