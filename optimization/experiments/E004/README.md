# E004 / H-007 result: INCONCLUSIVE

> Latest Windows window setup: [fixed-core validation/result](WINDOWS-AFFINITY-RESULT-2026-10-08.md).
> Job Object confines owned process tree; probes/48 exact Tier1 solves/audit and
> restoration PASS. Background interference remains, 55/90 contention observations.
> Numeric filter REJECT on BB108 MTO, controlled status INCONCLUSIVE; no advancement
> from this negative local round. [Strict launcher/user guide](WINDOWS-WINDOW-GUIDE.md).

> Latest user-directed continuation: [BB144 Tier 3 pilot completed](TIER3-PILOT-RESULT-2026-10-08.md).
> Four exact distance-12 solves, independent audit PASS; OFF/MTO singleton ratios
> 0.979988/0.804853. Unequal contention prevents speedup attribution; INCONCLUSIVE.
> Explicit user instruction permits bounded exploratory advancement on uncertainty,
> while scientific promotion remains pending. Older no-Tier-3 statements below
> describe earlier scheduling. Next: alternating repeated BB144 comparison.

> Latest H-007 advancement: [Windows Tier 1 coverage completed](WINDOWS-TIER1-RESULT-2026-10-08.md).
> 48 new correct diagnostic solves, OFF/MTO median geometric ratios
> 0.992546/0.994110; both noise envelopes exceed 1. INCONCLUSIVE, no Tier 3.
> Controlled follow-up prepared; actual reservation and live helper validation pending.

> Latest: [2026-10-08 Windows fallback ready](TIER2-WINDOWS-COMPLETE-2026-10-08.md).
> Cygwin/GCC installed, Tier 0 PASS, all 12 LP340 diagnostic solves correct.
> OFF/MTO median ratios 0.987788/0.993750; small gains, desktop/control limitations.
> Still INCONCLUSIVE, no Tier 3 or merge. Earlier environment failures retained.

> Later user-requested [Windows continuation](TIER2-WINDOWS-RESULT.md): installer
> launch blocked by automatic review and compiler unavailable. No Windows builds
> or new timings. Reproducible driver prepared; integration remains unexecuted.

> Subsequent user-requested [Tier 2 diagnostic](TIER2-DIAGNOSTIC-RESULT.md): two
> resource interruptions, one completed OFF baseline d=8, no complete LTO/MTO
> comparison. Still INCONCLUSIVE; no Tier 3 or adoption. The report below retains
> the original completed Tier 0/1 round and its original scope.

One concept tested: opt-in GCC LTO (`-flto=1` at compile and link time).
Scientific correctness PASS; diagnostic Tier 1 INCONCLUSIVE. No Tier 2/3,
acceptance, adoption or merge. Candidate is isolated in
[draft PR 12](https://github.com/guluchen/DistQLDPC/pull/12), branch
`experiment/h007-lto`; default build remains non-LTO.

## Exact identities and scope

- Baseline/main: `24572d6d09cce9a4a5faa58300a89e0feba9da6a`.
- Tested candidate: `5b13a2c01b6e0a4dec6a88ad5bbccdbf15df2030`.
- Final candidate/PR: `2efbdc13a81770e896301599da30d8c2e8d7eb89`.
  Final change only serializes the CI candidate build; Makefile, solver and data
  are identical to the tested candidate. No performance rerun is represented.
- Pinned local QDistSAT: `7c4774fffc49856f48a22ae5f9063d00b2661aaa`.
- Original and final exact diffs: [implementation.patch](implementation.patch),
  [final-implementation.patch](final-implementation.patch).
- Package manifest: [package-manifest.json](package-manifest.json), 156 hashes.
  Archive SHA256 `963c398f3ea87c2fd063bb06a752f1739139c75a5b81e518e44ac28d40844d06`.
- Raw returned archive SHA256
  `a41049170dd2c708e51b3f2aac663cc01e8256a2c6006525b22321fcd60072b0`.

Files implementing the idea: Makefile's six opt-in lines and the candidate build
line in `.github/workflows/qdist-cross-repo-benchmark.yml`. Support records,
packaging and validation are separate. No changes to src, matrix blobs, NOTICE,
MODIFICATIONS.md, scientific semantics, defaults or result/timeout interpretation.
DistQLDPC contains a patched downstream MaxCDCL engine; QDistSAT is its benchmark
platform, not an interchangeable solver name. No historical performance patch
was stacked.

## Tier 0

PASS on yfclab2, GCC 13.3.0 / Ubuntu 24.04, one logical CPU 4, sibling 132.
Clean serial builds: baseline `make -j1 CXX=g++ LTO=0`, candidate same with LTO=1.
Baseline/candidate build elapsed 15.005/17.200s (diagnostic; not solver timings).

- All six exported WCNFs byte-identical, including LP_340 export only; no LP_340
  solve/Tier 2 occurred.
- Independent exhaustive CSS fixtures have distances 2 and 1; both binaries pass
  default/OFF/MTO modes.
- Smoke/help, unchanged pinned QDistSAT LP_136 and BB_108 OFF/MTO checks, and
  six one-second parent timeout tests PASS. Timeout remains UNKNOWN with sound
  bounds; it is never interpreted as an exact distance.
- Ten tests of the actual adapted package's resource/gate/parser functions PASS.
- Required final PR cross-repo check PASS:
  [serial PR run 37632853674](https://github.com/guluchen/DistQLDPC/actions/runs/37632853674).
  Normal PR CI also PASS. Hosted timing is excluded from conclusions.

See [Tier 0 summary](raw/server/results/tier0/summary.json),
[WCNF hashes](raw/server/results/tier0/exports.json),
[local cross-repo results](raw/server/results/tier0/cross-repo.json),
[hosted PR report](raw/hosted-pr-serial/qdistsat-cross-repo-benchmark/result.json),
[PR check receipt](raw/pr-checks.json), [gate tests](raw/harness-gates.txt).
Full command/stdout/stderr files are retained beside these records.

Initial parallel PR CI remained in the build step for several minutes and was
cancelled (terminal receipt retained), not silently discarded. No root cause or solver crash is inferred.
Serial candidate CI subsequently passed in 58s; compiler flags/source unchanged.
Initial push comparison also passed in 53s. Preserve the initial run receipt and
failed log-fetch evidence under raw/; the cancelled job log was unavailable.
CI serialization is a supporting
build fix, not another solver optimization.

## Tier 1: all 48 diagnostic samples complete

Three baseline and three candidate executions per case/mode, AB/BA/AB, 180s
internal / 195s watchdog. All exact distance/objective/LB/UB results agree with
baseline and retained expected values; no timeout, crash or resource abort.

| Case | OFF baseline median (s) | OFF LTO median (s) | Cand/base | MTO baseline median (s) | MTO LTO median (s) | Cand/base |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| BB_90_8_10 | 3.6795 | 3.6311 | 0.9868 | 4.4786 | 4.3809 | 0.9782 |
| GB_144_12_8 | 1.5772 | 1.5274 | 0.9684 | 2.0290 | 1.9822 | 0.9770 |
| BB_108_8_10 | 4.6789 | 4.5808 | 0.9790 | 5.9349 | 5.8344 | 0.9831 |
| LP_238_44_6 | 3.1809 | 3.1296 | 0.9839 | 3.7310 | 3.6831 | 0.9872 |

Median-ratio geometric means: OFF **0.979514**, MTO **0.981341**, descriptive
reductions about 2.05%/1.87%. All medians favor LTO and no sample-range separation
establishes a serious regression. However the preregistered aggregate range
envelope is **0.997200 OFF / 1.006753 MTO**. MTO does not pass the beyond-noise
criterion; the combined numerical filter is INCONCLUSIVE even before evaluating
host control. Do not relabel small favorable medians as reproducible improvement.

[Raw samples](raw/server/results/samples.json),
[decision/medians](raw/server/results/decision.json),
[independent audit](raw/independent-audit.json),
[resource telemetry](raw/server/results/capacity.json),
[environment](raw/server/results/environment.json),
[build/binary identities](raw/server/results/build-identities.json).
Measured Tier 1 solve time totals 175.022s, plus 28.857s Tier 0, builds and
guard waits. No shared/noisy timing is used for a scientific conclusion.

## Resources, learning and limitations

The server was occupied, without exclusive reservation or installed CPU
isolation. Preflight global idle 73.74%; measured during guarded work
51.71--73.75%, 137 resource checks, 29 contention observations. Minimum half-spare
capacity 66.19 logical CPUs; only one allocated/pinned CPU. The user's >50%
spare/half-spare allowance was respected. Guard checks run before commands and
every two seconds while they remain active; subinterval contention is not ruled
out. Affinity and spare capacity do not establish isolation.

Recorded named LRB-phase and final search-counter lines are identical across all
six executions per case/mode. This is consistent with optimizing execution
overhead rather than deliberately altering search, but not proof of identical
execution or a hardware bottleneck. Independent audit retains the exact lines.
Binary file sizes (including debug data) are 2,250,344 vs 1,876,664 bytes; smaller
file size is not runtime evidence. Existing compiler warnings and serial LTRANS
notes remain in raw logs. No lto-type-mismatch, link failure or semantic anomaly
was observed. Driver process-wait polling can also obscure small timing changes.

Prediction: execution overhead could fall while retaining encoding/search.
Observation: encoding/results and available counters unchanged, small favorable
medians in both modes, but MTO spread and host contention prevent a pass.
Confidence: high in these retained correctness checks; low in the size and
portability of a speedup. No evidence warrants calling LTO ineffective, accepting
it, or promoting it to expensive cases. E004 stays unpromoted INCONCLUSIVE.

Next action: if resolving LTO is valuable, rerun the same Tier 1 package in a
controlled environment. Otherwise explicitly shelve it and hold a fresh Brain
to reassess SLS/BDD against profiling evidence; do not automatically execute
H-008/H-009 as a queue. No Tier 2/3 from this result.

## Reproduce

`prepare_local.py` exports committed baseline/candidate blobs, verifies pinned
QDistSAT files from the existing verified offline package, generates adapters,
syntax-checks them and hashes every payload. Keep the original tar's checksum;
regenerating a tar changes container timestamps and may change its archive hash.

Exact completed diagnostic command:

```sh
python3 /home/yfc/codex-e004-lto-20261007/E004-server-package/idle_tier1_lto.py \
  --package /home/yfc/codex-e004-lto-20261007/E004-server-package \
  --output /home/yfc/codex-e004-lto-20261007/results \
  --cpu 4 --sibling 132 --allow-core-contention
```

Future commands require a new output directory and freshly observed eligible
CPU pair. Controlled follow-up only with real reservation evidence, stable
configuration and the user's spare-capacity rule satisfied:

```sh
python3 E004-server-package/candidate/optimization/server/run.py \
  --package E004-server-package --output controlled-results-01 \
  --cpu "$BENCH_CPU" --exclusive-host --reservation-note "$RESERVATION_EVIDENCE"
```

Never supply a false attestation. This runner gates Tier 2 on Tier 1 and has no
Tier 3. Scientific mismatch stops; incomplete/noisy evidence cannot promote.
The occupied-host guard must remain enforced for any use without reservation.
Recompute the retained audit with `python optimization/experiments/E004/analyze_results.py`.
