# Review amendments before any execution

Independent review of support 31c36ea / 0846bad identified test-harness blockers.
They do not change production 51509de or the one selected capacity mechanism.
This record precedes their support implementation; no GH46 build/solver has run.

1. A correct LP340 optimum 8 completed before the one-second deadline is valid
   scientific behavior. Validate every field/status first, then record timeout
   path coverage INCONCLUSIVE rather than falsely rejecting it. Established wrong
   fields/results, crashes, or output semantics remain scientific REJECT. Replace
   blanket AssertionError classification with explicitly typed scientific failures;
   unexpected assertions and watchdog/coverage failures are engineering evidence.
2. Refuse local support bytecode caches before imports and after the run; disable
   bytecode writes in the supervisor and every Python child. Pin actual consumed
   engine objects before each application/Main link and check them after links and
   finalization, with public hash records even though executable/object bytes remain
   local. Source hashes alone are insufficient evidence of consumed object identity.
3. Enforce successful and failing substantive lookahead exits and selected hard and
   soft reset labels, as well as repeated populated calls across a UB transition.
   Add four explicitly structured small exhaustive cases (non-auxiliary hard binary
   conflict, nonbinary hard conflict, soft conflict/implication chain, and mixed
   paths), for sixteen tiny oracle instances total. Do not manipulate thresholds,
   seeds, modes, original algorithm, or benchmark data to manufacture this coverage.
   Missing labels remain a coverage gap and block diagnostics/performance.
4. The reserved Lit slot is value-initialized to zero by original Vec::push's T().
   It is not uninitialized storage, but it is not a populated explanation/UIP until
   original production assigns that role. Correct that documentation; preserve the
   meaningful-slot comparison rule and all original slot handling.

Actual GCC/C++ execution, coverage, scientific results and allocation opportunity
remain UNTESTED. Independent review and a named host slot are still required.

### Additional review: lawful short-case deadlines

Before execution, authenticate every bound/status and absence of completed distance/objective for an actual rc1 UNKNOWN/TIMEOUT in tiny CSS, LP34 smoke, and observer CSS. Such lawful incompletion is CoverageGap INCONCLUSIVE, not a scientific rejection. Wrong fields, wrong completed optimum, or crash remain REJECT. This changes support classification only; no deadline or production change.

### Exact incomplete-output trailer review

Before execution, require precisely one distance trailer with UNKNOWN for an incomplete application. Accept only original exact c status values UNKNOWN or TIMEOUT (child killed after -cpu-lim), paired with s UNKNOWN. Missing distance/status or arbitrary TIMEOUT prefixes are scientific output regressions, never lawful coverage gaps. Source-only AST-extracted parser cases will check this support repair.
