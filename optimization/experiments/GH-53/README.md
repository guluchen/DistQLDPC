# GH53 preparation status

SELECTED / SOURCE ONLY / UNTESTED. No CPU host assignment; no builds, science,
allocation diagnostics or timings. Draft PR54 is an isolated candidate, not acceptance.

- Immutable baseline: 24572d6d09cce9a4a5faa58300a89e0feba9da6a.
- Prerecord before source: c27660aaf52e3cfac2e709a257397e6a702f5be1.
- Production concept: 08971d16c041e7f32f38ea822db85e76050c0b05.
- Final production diff: ONLY existing ccmin default literal2→1. Original
  constructor, both helpers and all other engine/application code are unchanged.
- Attribution documentation originally suffered Windows line-ending churn;
  a following support commit restores all original LF bytes. Final diff has
  only13 MODIFICATIONS additions,5 NOTICE additions, and1 source literal change.
- test_minimization.cc is UNCOMPILED test-only preparation:192 direct/helper+hard-caller
  helper cases per binary (two modes, four reason graphs, two helper paths plus actual hard analyze,
  eight polarity patterns), exhaustive32-model nonvacuous implication oracle,
  constructor defaults, literal retention, levels/LBD, seen cleanup, immutable
  assignment/trail/reasons. Direct legal reason graph construction is not
  full analysis caller or weighted-bound context certification; watches are
  empty so existing binResMinimize is reached but its removal behavior is not
  substantively covered. Explicit test mode selection is confined to fixture.

Known valid GH46 baseline anomaly remains unresolved and forbids complete
science certification or normal performance promotion. No fixture deletion,
unsupported-input waiver, changed ground truth or hidden semantics repair.
Tier0 runner is NOT READY; caller/weighted/bound lifecycle support and peer
source review remain necessary. Do not run this fixture without named slot.

Exactly three proposal/ranking, original source literature attribution and Bib
are in PRERECORD.md. IJCAI2017 is an older source-header attribution, not a
recent MaxSAT adaptation or a scientific proof for basic minimization.

## Bounded source feasibility disposition

SOURCE_ONLY / BLOCKED_FULL_CERTIFICATION, not scientific REJECT of ccmin1.
Independent academic review of fixture4933517 found no obvious API or legal
reason-graph defect;192 cases per binary and expected constructor/default,
retention/backtrack/LBD/seen/state and exhaustive32-model oracle are coherent.
This is a LIMITED source review, UNCOMPILED. Direct quasi examples are hard
entailment examples; they do not establish actual weighted/auxiliary-bound
quasi caller lifecycle. Watches are empty. No further synthetic variants or
full execution wrapper are prepared while this certification blocker remains.

The exact-source byte audit at06d6838 confirms only the default literal differs;
no optimization experiment has run. All local science/performance gates remain
NOT_RUN. Hosted CI success metadata at294bbcde is not a complete raw correctness
certificate, and does not resolve the known original245 baseline anomaly.

Concrete obligations before a full Tier0 request: authenticate a resolution of
GH46 valid input crash without changing ground truth, then establish actual
soft/quasi/current-bound reason validity, auxiliary/rollback lifecycle and
substantive watcher minimization coverage using the real callers, followed by
full existing CSS/PMS/allbounds/status/timeouts and exact-source CI artifacts.
No new default/mode sweep, fixture waiver, or stacked repair is authorized.
Root is asking the user how to proceed on the scientifically meaningful baseline
anomaly. Original245 baseline, GH46 failed record and this candidate stay intact.
