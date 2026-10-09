# E001 / H-001 — approved Brain Round 1 exact #1

Source: Codex chat 01a111cd-9e52-7112-ad06-4a4b4a078c0c, final Brain Round 1;
user approval in ChatGPT 6ac503bf-5384-83ee-8551-c06d26ceb216 and this restart request.
Baseline: 24572d6d09cce9a4a5faa58300a89e0feba9da6a.
QDistSAT harness: 7c4774fffc49856f48a22ae5f9063d00b2661aaa.
No committed STATE/HYPOTHESES/experiment index existed. Private history unknown.

## Hypothesis and exact scope

Independently shorten Gx and Gz memory copies before MaxCDCL encoding. One
sequential pass, rows in original order. For each row choose the current other
row giving the greatest strict weight reduction; ties choose lowest row index.
Apply only that XOR immediately. Preserve row count/order. No H preprocessing,
XOR sharing, initial bound, solver heuristic, scientific or reporting changes.
Each elementary Gi <- Gi XOR Gj (i != j, Gj retained) is its own inverse.
Their composition is invertible, so nonzero logical syndrome is equivalent;
the feasible original (x,z) set and Pauli objective are unchanged. Separate
Gx/Gz transformations need not preserve a canonical pairing matrix, only its
rank and the nontriviality predicate actually consumed by this encoder.

LP families have many weight-reducing opportunities. Fewer gates may still
worsen propagation/search; runtime benefit is unproven. Cost O((kx²+kz²)n).
Existing s1/s2 H preprocessing copies G unchanged; no prior public trial found.

## Preregistered gates (before any candidate timings)

Tier 0: build both; production-helper algebra tests (determinism, exact sequential
rule, row-space, quotient-rank, pairing-rank, tiny exhaustive syndrome/distance);
existing smoke; tiny exact CSS solves with baseline/candidate in default BOTH,
no-card and card-mto; timeout/result soundness; unchanged QDistSAT cross-repo
pilot LP_136_32_4 and BB_108_8_10 in both explicit modes, timeout 45 s.
Any semantic discrepancy rejects and escalates; no performance promotion.
Required hosted PR check remains required before merge.

Tier 1 on an exclusive dedicated Linux host only: BB_90_8_10, GB_144_12_8,
BB_108_8_10, LP_238_44_6; no-card and card-mto separately; baseline/candidate
three measured runs each = 48. Same compiler/flags, original inputs, pinned CPU,
180 s internal wall limit and 195 s external watchdog; serial interleaved AB/BA/AB.
Total wall includes loading, preprocessing, encoding, simplification and search.
Keep full stdout/stderr, exit status, bounds and exact result; timeouts never count
as completed solves. Default BOTH is correctness-only, outside performance claim.

Per case/mode report all samples, medians, min/max and baseline range/median.
A conservative noise envelope uses observed run ranges: confirmed regression
means candidate minimum > baseline maximum. Reject any such per-case regression.
For each mode use equally weighted geometric mean of candidate/base median
ratios across cases. Promote only if every candidate median <= baseline median,
and geometric mean(candidate maxima / baseline minima) < 1 in BOTH modes.
Thus aggregate improvement must exceed the full observed ranges. Otherwise
inconclusive, not pass; no universal percentage threshold. This is a conservative
three-sample filter, not a research-grade statistical confidence claim.
Timeout/failure/missing samples block promotion; unequal semantic results reject.

Tier 2 only after Tier 1 pass: LP_340_56_8, both explicit modes, 3 repeats each
version, 600 s internal / 615 s watchdog, same range/median rule and environment.
Reversed/disappearing gains reject (overlap alone inconclusive). Never run Tier 3.
Historical Tier 1 estimate ~4.2 min solver time, worst 144 min; Tier 2 ~29 min,
worst 120 min. Estimates are not guarantees. No full suite or paid cloud substitute.

Both performance binaries use `-v` with stdout/stderr redirected to raw files;
this preserves solver diagnostics and applies identical logging cost. The isolated
production-helper probe records preprocessing duration and row weights as
structural diagnostics, outside measured runs. It is not an estimate of the
per-run preprocessing cost. Full wall time remains the decision metric. Raw
verbose logs retain available simplification/search counters; absent engine
counters are unknown, not zero. No new solver instrumentation is introduced.
