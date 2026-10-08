# Attempt log (all attempts retained)

## Candidate 9735547 — Tier0 FAIL (engineering bug caught by the test-only check)

- `LITVALS_CHECK` build aborted at the first `value(Lit)` read on every case
  (LP_34/LP_136/four Tier1, OFF and MTO; NDEBUG and asserts-enabled builds).
  Detail: lit 69 (negative literal of an unassigned variable) mirror=2,
  expected `assigns^sign`=3. Variable creation pushed `l_Undef` (2) for both
  literal slots, whereas the original expression yields 3 for the negative
  literal until the first assignment. Both encodings mean "undefined" under
  MiniSat lbool `==`/`!=`/`&&`/`||`, but the preregistered invariant is
  bit-exact, so the candidate was rejected before any timing.
- The concurrently started trace-identity sweep was aborted and kept only as
  superseded evidence (`raw/tier0-01-ABORTED-superseded-candidate`, partial).
- Raw: `raw/tier0-check-01-FAIL-init-encoding/`.
- Fix: push `l_Undef ^ true` for the negative literal slot (same concept, no
  scope change). Candidate re-enters Tier0 from the start.

## Tier0 sweep tier0-02 — harness STOP, then post-hoc corrected re-judge

The trace-identity harness exited STOP (5 `TIMEOUT-PREFIX-MISMATCH`). Investigation
showed a comparator defect (the parent's multi-line trailer after a kill vs a
one-line strip). The comparator was corrected after seeing the STOP and applied to
the same saved logs; this is a post-hoc rule change, disclosed in TIER0_RESULT.md,
and the original verdict files are kept unchanged. The sweep also used a 20 s
limit instead of the preregistered 60 s; the 60 s check is run separately.

## Independent review (subagent, after Tier1)

No BLOCKER. All source writes covered, lbool encoding bit-exact, Tier1 numbers
reproduced exactly. MAJOR (procedure): undisclosed 60 s -> 20 s change; post-hoc
rejudge not labelled. MINOR: "23 write sites" text; decision wording; "18 sample
sets"; causal mechanism claim; MODIFICATIONS overstated; out-of-range `value()`
safety only test-supported; Makefile lacks header dependencies (binaries used here
verified fresh). All addressed in records; 60 s check scheduled after Tier2.
