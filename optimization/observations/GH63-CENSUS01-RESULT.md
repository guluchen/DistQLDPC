# GH63 baseline LBD census: completed diagnostic

Baseline72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7 only. All eight
preregistered calls completed naturally with expected scientific results;
independent audit authenticates all32 scientific fields before count parsing.
This is a separately instrumented diagnostic, never a timing executable.

| Case | Mode | Size-two calls | Total LBD calls |
|---|---|---:|---:|
| BB_90_8_10 | OFF | 207100 | 740867 |
| BB_90_8_10 | MTO | 233218 | 823304 |
| GB_144_12_8 | OFF | 71943 | 231761 |
| GB_144_12_8 | MTO | 106010 | 343102 |
| BB_108_8_10 | OFF | 242355 | 836553 |
| BB_108_8_10 | MTO | 310305 | 1065147 |
| LP_238_44_6 | OFF | 117243 | 379725 |
| LP_238_44_6 | MTO | 142380 | 459116 |

All eight have authenticated FINAL counts, required powers-of-two prefixes,
monotonic buckets summing to total and zero observer overflow. Size-two calls
represent27.95–31.04% of diagnostic baseline LBD calls. This is not CPU-time
share or attribution to the two outlined production callers; compiler outlining
and code growth may still offset any loop savings. Net benefit remains untested.

Independent status PASS_BASELINE_DIAGNOSTIC_CENSUS_ONLY, audit:
1db088ea6162187e40d2fb6b993c3fbc52f2ed51c3c035ebaaf289f21b2def93.
Raw109-payload catalog:
5f6064056282ac996bf3ddbbc80612ee854914c35856c45eacbd2d6508633612.
Frozen supportc180604f0c38e16812df9386188f3413f9627f1a7c063b59cc932df06b688352;
packagec9bd77a37a705eca4df0ad33ce33cdb8261de2ca0d23aaa3abbbff50ffca6408.
Actual source inverse, six consumed compilation pins, original flags, Python/
Cygwin pre/post/current identities, owned cleanup and restoration were audited.
Detailed raw/environment metadata remain private and immutable locally.
Assignment6073808156 terminated with zero exit; no runner remains active.

Learning: actual size-two opportunity exists in every selected Tier1 cell;
combined with full Windows Tier0 and actual codegen/state checks, this permits
preparing the separate preregistered Tier1 comparison. It does not establish
speedup, formal Tier1 PASS, native-Linux certification or Tier2/3 eligibility.
Reuse only authenticated uninstrumented full01 production apps for timing.
Decision: diagnostic COMPLETE; optimization INCONCLUSIVE pending measurement.
General program optimization; no paper-derived claim or BibTeX.
