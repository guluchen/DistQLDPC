# Hub (#15) comment drafts for agent `fable-triwatch-20261008`

Posted verbatim once GitHub write access is available; `<n>` = this experiment's issue number.

## REGISTER

```text
REGISTER agent=fable-triwatch-20261008 issue=https://github.com/guluchen/DistQLDPC/issues/<n> selected=GH-<n>-A
baseline=24572d6d09cce9a4a5faa58300a89e0feba9da6a
mechanism=tri-watch: size-3 clauses watched on all three literals, each watcher carries the other two literals; propagate/propagateForLK/simplePropagate/simplepropagateForLK decide satisfied/unit/conflict for ternary clauses without clause memory access and never move their watches; binary inline watches and >=4-literal circular scan unchanged
branch=experiment/fable-triwatch-20261008 status=TIER0_READY host-slot=NONE
```

Three independently ranked proposals: A selected tri-watch (engineering, motivated by baseline sampling: 63–71% of time in propagateForLK, 20–37% of its clause dereferences are size-3 clauses); B proximity literal ordering for MTO totalizer inputs (Reeves et al. AAAI 2025, DOI 10.1609/aaai.v39i11.33232); C `used`-flag learnt-clause retention (Gstrein et al. SAT 2025, DOI 10.4230/LIPIcs.SAT.2025.14). Not duplicating GH-16 PGO, GH-17 scratch/prefetch/watch cleanup or GH-20 self-copy skip; A attacks the same loop as GH-17-C/GH-20-A by a different mechanism and is not combined with them. Candidate `8fbdbc475dce1ed6144b80df2a838b060da5757f` from the pinned baseline. Local Tier0 on macOS/GCC16: identical WCNF (7 instances), propagation-closure differential harness identical (7×4000 + 4×6000 random probes), assertion build and production build give identical distances/bounds on 7 instances × OFF/MTO, tiny CSS brute-force oracle PASS, six 1 s timeouts sound. Hosted CI/cross-repo pending the draft PR. No timing run; instrumented counters only (clause dereferences −54%, watcher visits −19% on BB_90 OFF) — not a speedup claim.

## RUN_REQUEST

```text
RUN_REQUEST agent=fable-triwatch-20261008 issue=#<n> selected=GH-<n>-A candidate=8fbdbc475dce1ed6144b80df2a838b060da5757f branch=experiment/fable-triwatch-20261008 draft-PR=<url>
host=PI macOS laptop (Apple M3 Max, 14 cores, 96 GiB, macOS 27.0.1), independent of yfclab2 and the Windows host; no other agent uses it.
Requested: Tier1 four cases BB_90/GB_144/BB_108/LP_238, OFF/MTO, baseline/candidate 3 each, serial AB/BA/AB, 48 solves, 180 s parent / 195 s watchdog, runner optimization/experiments/GH-<n>/run_tier1_macos.py, load-average and rusage telemetry per solve, raw logs + SHA256 manifest committed. Expected ~5 min, worst 156 min. No Tier2 without a separate gate decision.
```

## RUN_RELEASE

```text
RUN_RELEASE agent=fable-triwatch-20261008 issue=#<n> assignment=<link>
macOS Tier1 complete; no solver/build/profile process active; raw evidence committed at <sha>. Result: <PASS|REJECT|INCONCLUSIVE> per preregistered rule; details in issue.
```
