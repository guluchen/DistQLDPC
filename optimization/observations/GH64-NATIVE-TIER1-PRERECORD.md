# GH64 native Tier 1 confirmation prerecord

2026-10-09. Same single hypothesis: guarded next-watch clause prefetch in
propagateForLK, baseline72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7 versus
candidateb632a1c016c2289ab1625ccb768626a187c5aa62. Five production Solver.cc
lines only; original Solver.h, objective/search/bound/timeout/result/Pauli/logical
semantics and compiler settings remain unchanged. This is the downstream
instrumented MaxCDCL-derived DistQLDPC engine with the QDistSAT benchmark platform.
No LTO, LBD specialization, new prefetch distance or other optimization is added.

Prior evidence is retained: all48 Windows results correct, all eight candidate
medians slower, OFF/MTO geometric mean slowdowns1.6629%/1.6868%. Original numeric
filter rejects, formal performance INCONCLUSIVE because of observation/noise
limits. Native confirmation does not replace or improve these historical data.

Actual native targeted-plus-full Tier0 is now independently certified:
audit2d2be5098fb5fdede9187de50c043a9b9c1cc59acab4f31ff14c8d4e9fa06ebf,
raw6bedb46cb34738b1f2805699781f6b29854443e59aea88de15ba64de0c51e4bb,
54apps/204fields/162PMS/40oracles/40dumps/12timeouts/2smokes plus mandatory
directed gates. Actual native runtime/Git/binaries/original terminal streams and
separate helper release/root recovery are bound. Reuse only the two certified
production apps, preserving all12 production pins; no compilation or relinking.
Authenticate actual native installed hint separately; hint emission alone is
not evidence of a cache bottleneck or speedup.

Before timing, prepare a separate disabled adapter and independently review it.
The correctness guard lacks waited-child rusage and an exit lower bracket.
One owned-PID wait4 observer will record actual status/rusage, a lower timestamp
before the last zero-result wait, and upper immediately after terminal wait.
It must exclusively reap that PID throughout normal/error/cleanup paths,
synchronize Popen.returncode, and preserve science-first priority at cap/resource
races. Missing/reused/ECHILD identities are engineering failures, never invented
CPU0 or natural solver outcomes. Meaningful short owned-process observer tests
must pass before opening scientific timing. Existing frozen Tier0 support remains
immutable; this is measurement infrastructure, not another solver optimization.

Fresh input package: exactly16 original Git matrices, baseline/candidate bytes
equal, independently authenticated. Case order and expected truth: BB_90_8_10=10,
GB_144_12_8=8, BB_108_8_10=10, LP_238_44_6=6. Each case OFF then MTO; each cell
three paired repetitions AB/BA/AB, A=baseline/B=candidate. Exactly48 serial solves:

```sh
"$ROLE_APP" -v -cpu-lim=180 -no-card "$CASE"
"$ROLE_APP" -v -cpu-lim=180 -card-mto "$CASE"
```

No warmups, discarded samples, timing-selected retries or simultaneous siblings.
Nominal external cap195s, inner6600s, outer6660s plus owned TERM3/KILL5 cleanup,
within installed lease7200s. Nominal48caps sum9360s plus preflight/provenance;
the aggregate is intentionally tighter and cannot guarantee full completion.
Immediately before Popen use min(195,actual remaining); exhausted/incomplete
attempts retain all raw and are INCONCLUSIVE, never extrapolated medians.

One named runner on the host, fixed authenticated physical pair lease, ordinary
unprivileged solver processes, global spare strictly>50%, reserve no more than
half spare throughout. Both logical CPUs count. Initial/pre-solve pair should
be>=95%idle; selected CPU intentionally busy during solve. Log sibling/global
activity, original resources and actual owned identities; hard capacity/lease/
identity failure stops. Pair reservation is not full-host exclusivity. No power,
IRQ/governor/other-user configuration changes or forced-supervisor-death claim.

Original numeric wall judge is unchanged, source0dbf7b77bcf54e1f061a90ceac4f75db6abc4c6a76c00a4cdfe6e30a3b7ba7dc:
any cell min(C)>max(B) rejects; positive requires both mode geometric means of
max(C)/min(B)<1 and no worse candidate median. Wall metric remains full
launch-before to terminal-upper, without subtraction or midpoint replacement.
Report every raw wall/CPU value, eight medians/ranges, both mode geometric means,
all24 paired wall-ratio intervals and actual observation widths. Three observed
repetitions are empirical ranges, not confidence intervals.

Stronger corroboration requires complete science-correct eligible48, all source/
runtime/compiled/input/capacity/cleanup/release proofs, original numeric positive,
all eight candidate upper ranges strictly below baseline lower ranges, all24
paired upper-vs-lower wins and corroborating CPU direction. Relevant noise,
overlap or contradictory CPU/wall evidence leaves INCONCLUSIVE. Repeated
regressions separated beyond observation/variability, across both AB orders
with CPU/control evidence, support shelving; original Windows negatives remain.
Minor interference is not automatically acceptable: retained evidence must show
it cannot change the decision. No replication/repeat-until-positive authorized
by this record; any finite robustness follow-up needs its own prior record.

Any wrong scientific result/bound/crash/output regression STOP/REJECT; known
scientific mismatches survive engineering cleanup/record errors. Complete raw,
compiled pins, current actual native runtime and separate root release proof
must be independently audited after terminal. No Tier2/Tier3, adoption or speed
claim follows merely from worker markers. Numeric/support/provenance failures
remain separate from scientific failures and are preserved.

Engineering risk: observer reaping races; scientific risk: using wrong app/input
or interpreting incomplete bounds as exact results; measurement risk: shared
memory/power/interrupt activity despite pair isolation. Cost: source/independent
review plus a short bounded observer validation and one<=6668s timing attempt;
48 fixed scientific solves maximum. Expected affected cases are all four cases
in either mode if this guard reaches costly next-clause reads; no percentage or
hotspot is established. Ordinary engineering/BibTeX not applicable. Full private
planning source4cce6af66922c700d135abd5bf2604df8d3b122b5ea15261a00cf50a3577c1d7
is historical preparation; actual audit now closes its pending-Tier0 condition.
