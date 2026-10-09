# TN_648_10_71: independently verified named-distance anomaly

2026-10-09. Other agents reported this through hub15/6078813000. A separate
read-only canonical-Git check against corrected baseline72d1fe18 independently
confirms that individual Gz rows0 and2 are valid X-sector logical operators
of Pauli weight52. They commute with every Hz stabilizer, are outside row(Hx)
(rank319 increases to320), and have nonzero Gx logical syndrome. Individual
Gx rows0,1,2 similarly give Z-sector weight54 witnesses.

Thus the bundled matrices imply distance<=52; this does NOT prove exact
distance52. The name's71 cannot be used as certified ground truth for these
bytes. Either intended-code provenance or naming/ground-truth metadata needs
scientific clarification. No matrices, names, reference answers, harness
expectations or scientific semantics were changed. Do not silently replace71
with52 or call an upper-bound witness an optimum.

Canonical matrix identities, full witnesses, GF(2) reduction certificates,
commutation and application orientation are retained in
TN648-INDEPENDENT-CANONICAL-WITNESS.json (original report SHA256
116bc68ee54a9d2cedd0864d12a62e87e16d2827599ed870a1c62e674eed7893).
The producer is archived beside it. This is a pre-existing data anomaly,
not a GH83 candidate failure; GH83 tier cases do not include this stem.
Runs or conclusions depending on the named distance of this code require
clarification before proceeding.
