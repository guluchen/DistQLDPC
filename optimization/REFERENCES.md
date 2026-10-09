# Optimization literature provenance

User instruction2026-10-08: whenever an optimization is learned from a paper,
record which paper and preferably retain a BibTeX entry. This mapping and
[references.bib](references.bib) implement that requirement; link the relevant
key from each proposal/experiment. Verified primary metadata on2026-10-08.
This records sources and adaptations, not new research or experimental results.

## H-009 / E006: BDD objective bounds

Keys: vandesande2026certified (published paper),
vandesande2025certifiedextended (exact extended version actually read).
Dieter Vandesande, Jordi Coll, Bart Bogaerts,
[Certified Branch-and-Bound MaxSAT Solving](https://ojs.aaai.org/index.php/AAAI/article/view/38449),
AAAI2026, published2026-03-14,40(17):14342--14351,
DOI10.1609/aaai.v40i17.38449. The
[extended arXiv version](https://arxiv.org/abs/2511.10273v1) was submitted2025-11-13;
the live unversioned page now points to v2, so preserve v1 explicitly.

Reading location: [v1 HTML section0.4](https://arxiv.org/html/2511.10273v1)
and technical appendix.9. Section0.4 describes the BDD representation of the
solution-improving bound and its CNF translation; appendix supplies formal
details. Use the HTML section heading if anchor rendering changes.
This is the immediate source from which this trial learned the construction;
the paper itself credits earlier BDD/MDD work, including Abio2012/Bofill2020.
Do not attribute invention of BDD encoding or a DistQLDPC speedup to this paper.

Our adaptation: fixed-order singleton unit-weight BDD for the existing active
sum<=k; forward clauses/root assertion and original dynamic-bound lifecycle.
An iterative suffix-budget construction is newly authored for this restricted
case. No weighted interval machinery, AMO groups, MDD, proof logging/certification
implementation or wholesale upstream MaxCDCL replacement. This trial's local
results evaluate our adaptation in the downstream instrumented engine; they
do not reproduce the paper's experiments or undermine its certification claims.
[Proposal](experiments/E006/PROPOSAL.md), [record](experiments/E006/README.md).

## H-008 / E005: bounded SLS warm start

Key: lubke2025sls. Ole Luebke, Jeremias Berg,
[SLS-Enhanced Core-Boosted Linear Search for Anytime Maximum Satisfiability](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.CP.2025.28),
CP2025, published2025-08-08, LIPIcs340:28:1--28:20,
DOI10.4230/LIPIcs.CP.2025.28. The BibTeX entry preserves the author's umlaut;
metadata checked against the publisher's citation export.
Earlier research notes read full HTML, particularly sections3/4; this update
verifies the primary bibliographic metadata rather than claiming a new full read.

Adapted idea: supply a verified feasible objective cap through one bounded
original-instance SLS call before exact search. Our WalkSAT-style fixed seed/
budget backend is a separate implementation; no Loandra import, core-boosted
three-phase architecture, relaxed-instance reconstruction, feedback or precision
schedule. E005's zero-cap failure rejects that configuration, not the paper's
method or all SLS. [Proposal](experiments/E005/PROPOSAL.md),
[record](experiments/E005/README.md),
[original literature screen](brain/2026-10-07-round2-research-revision.md).

## Other techniques and future entries

H-012, proposed in [Round5](brain/2026-10-08-round5.md), uses key
`zhang2026enhanced`: [CP2026 publisher record and exact published PDF](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.CP.2026.60),
metadata checked2026-10-08. Reading depth: sections2/3, Algorithms1–3,
Proposition6; section3.3 read to exclude RL. Proposed adaptation restricts
eligible cores to size two. No experiment, full-system reproduction or code
import. Code licensing must be checked separately from the paper's CC-BY license.
H010 PGO and H011 scratch reuse are general engineering techniques;
their inspected code and compiler sources are linked in Round5, not invented
paper citations.

H007 LTO came from ordinary compiler/program optimization, not a selected
MaxSAT paper; do not invent a paper source for it. Earlier local hypotheses
likewise need an honest origin, not an unsupported scholarly attribution.
For future paper-derived ideas, record the citation key, DOI/arXiv and exact
version, publication/submission date, section/algorithm used, reading depth,
our adaptation and omitted components, and any original-method references
actually verified. Keep methodology provenance distinct from performance
evidence and code copyright/license attribution.
