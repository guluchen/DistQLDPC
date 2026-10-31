# Next family: closed hyperbolic surface codes

Primary source inspected: Breuckmann-Terhal arXiv:1506.04029v2,
Sections III-A/B, IV-A and Table I. This note records a research lead, not
implemented matrices or a passed family gate.

Candidate published {5,4} ladder: [[60,8,4]], [[160,18,6]], [[360,38,8]],
[[1800,182,10]], [[1920,194,10]]. The paper specifies compactifying
translation words. Reconstruct the orientation-preserving triangle group
rho^5=sigma^4=(rho sigma)^2=1 modulo their normal closure. Need reflection
conjugation too if using the full reflection group's normal closure; with
rho=bc and sigma=ca, conjugation by c inverts both generators. Verify the
actual quotient order equals 2n before claiming to reproduce any table case.
The base r/s/rs cosets represent faces, vertices and edges, with incidence
by intersection. Require connected closed orientable surface links and
appropriate face/vertex lengths, commutation and ranks k=2g; a matching
parameter triple alone does not establish a faithful construction.

Use an original standard-library enumerator or a clearly attributed math
library, never copy third-party implementation. SymPy is unavailable on the
current system Python; dependency assumptions must be explicit. Large or
unbounded presentation enumeration is not allowed on the PI Mac. Bound
pilot algebra by size/time, then move heavier generation to a server package.
Independent reconstruction can use the completed Cayley permutations and
separate cell-orbit enumeration. Own double-cover shortest-cycle search
(from the paper's Section III-D mathematics) can independently validate
surface distances; it is not an external distance solver. Do not call a
published exact anchor a new result or rename any unknown stem.

Before starting: recheck current issues/branches, open a separate Codex issue,
write three proposals and claim it from #15. Keep GH-164 and GH-160 intact.
