# E006 / H-009 preregistration: singleton BDD objective bound

2026-10-08 before implementation. User authorizes the next method; fresh
[Round4](../../brain/2026-10-08-round4.md) selects existing research revision H-009.
Independent baseline24572d6, candidateE006-BDD, no LTO/SLS/row/XOR changes.

Hypothesis: reduced ordered BDD CNF for the same active sum<=k improves exact
propagation/search relative to downstream MTO. Replace only the MTO construction
at its existing call site. Fixed original active-literal order, singleton unit
coefficients, original k=UB-1-nbFalse, invocation/mode conditions, n*k<=10000
guard and dynamic clause/auxiliary cleanup. Existing Sinz component remains
where previously enabled; OFF and Sinz-only unchanged. No tree reuse/AMO groups,
reordering/new bound heuristic/threshold sweep/proof logging. Report actual
BDD replacement in candidate diagnostic labels and retained metadata.

Mechanism: build suffix-budget ROBDD before adding clauses; one variable/node,
paper forward clauses(~node,low) and(~node,~input,high), constants simplified,
root true. Use existing newAuxiVarForCardinality/cardinalityC/CORE watchers and
root-unit policy. No scientific definition, Pauli weight, logical predicate,
certified bound, timeout/result or engine correctness assumption change.

Expected affected cases: MTO-sensitive workloads; OFF negative control. No
predicted speedup. Risks: wrong terminal/polarity/projection, stale root units
on relaxation, assigned-variable reuse/reasons/garbage collection and auxiliary
overhead/search regression. Graph/CNF correctness and existing lifecycle must
be established. Any mismatch or crash immediately rejects, stops performance,
and is reported; do not silently repair scientific mismatch into the same trial.

Tier0: fresh candidate build with unchanged compiler/-O3; production CNF
projection exhaustive n<=8/all k and mixed signs; graph terminal boundaries;
partial-assignment projection checks; real removal/reset/recycle, tighten/relax
and garbage tests. Original tiny CSS distance oracle/dump consistency, smoke,
QDistSAT LP136/BB108 both modes, one-second UNKNOWN/sound bounds; hosted required
cross-repo check. Embedded patch documentation/NOTICE updated; upstream headers
preserved. New generic implementation under existing engine MIT terms.

Tier1 only after Tier0 PASS: BB90_8_10,GB144_12_8,BB108_8_10,LP238_44_6;
OFF/MTO selectors (candidate MTO=BDD),3 repeats/version/mode,ABBAAB,48 serial
solves.180s parent wall/195s watchdog, same fixed-core/AboveNormal both versions;
initial/preflight pair>=95% idle, sibling>=95% active, global>50% and allocation
<=half spare,30s preflight wait. Resource loss/refusal records INCONCLUSIVE with
partial evidence; no relaxed gates/timing-selected retries. Preserve raw search,
node/clause/aux counts/construction timings. No clause-count-only speed claim.

Expected cost: serial build/projection/lifecycle/Tier0 minutes, Tier1~5--10min,
max144 solver-min. If controlled resources unavailable, prepare exact repeatable
commands and report uncertainty. Apply same median/range gate, per-mode/case
regressions visible. Positive repeatable Tier1 direction required for Tier2
LP340; no expensive Tier3 auto-launch. User exploratory-tier override never
turns INCONCLUSIVE into scientific PASS.

Prior relations: distinct from E001 basis/E002 sharing/E003 allocation/E004 LTO/
E005 SLS and H006 tree reuse. E005 configuration rejected on absent cap, formal
performance unmeasured. Do not bundle or adopt earlier candidates.
