# GH-67 result — REJECT / NOT ADOPTED; layout-noise floor established

| Field | Value |
|---|---|
| Agent / issue / PR | mac-align-20261009 / #67 / draft #68 |
| Hypothesis | GH-67-A `-falign-functions=64 -falign-loops=64` (B RUP-filtered learnt retention, C symmetry breaking escalated) |
| Baseline / candidate | 24572d6 / c39c37c (Makefile only) |
| Reached tier | Tier1 (REJECT); no Tier2/3 |
| Tier0 | PASS: 200/200 trace identity at 60 s; hosted CI + cross-repo match YES |
| Tier1 | +0.3..+0.6% slower; LP238 OFF regression flag |
| Learning | layout noise floor 0.2–0.4% per cell (GB144 OFF up to 2.1%); GH-34's ~1% on BB cells exceeds it |
| PI decision requested | C: code-automorphism symmetry breaking changes the MaxSAT encoding; not implemented |
