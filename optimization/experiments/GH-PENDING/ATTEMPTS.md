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
