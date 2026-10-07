# E002 / H-002 — preregistered engineering iteration

User clarified that another loop means another engineering hypothesis, not
another repeat of E001. Repository HYPOTHESES.md retains the original unselected
Brain candidate name **H-002: exact XOR-prefix sharing**. The source Brain chat
01a111cd-9e52-7112-ad06-4a4b4a078c0c cannot currently be read (durable host failed).
Only this name is recovered; the following design is this execution's explicit
implementation scope, not a claimed verbatim recovery of unavailable Brain prose.

## Prior learning and baseline

E001 changed logical bases and passed correctness, but two Windows rounds
(96 samples) reproduced GB regressions of about 48–49% OFF and 41% MTO. It is
not promoted; its controlled-host result remains inconclusive. Smaller encodings
alone do not predict search speed. Keep E001 and its failed local filters.
Start E002 from baseline 24572d6d09cce9a4a5faa58300a89e0feba9da6a, removing H-001
from the isolated candidate. Do not shorten/reorder G or H or mix another idea.
Local branch experiment/h002-xor-prefix retains history and the E001 branch.

## One conceptual change

In the MaxCDCL application encoding only, reuse the already-defined auxiliary
literal for an identical ordered pair of literal IDs in the existing XOR chain.
Use a std::map<pair<int,int>,Lit>, scoped to one build and one SimpSolver.
Literal IDs include sign. Do not sort operands, change row order, share across
solver instances, rewrite constraints or change the objective. Matching previous
accumulator IDs recursively shares exact ordered prefixes, including prefixes
common to stabilizer/logical rows on the same physical variable block.
Other builders/backends/dump-only entry points keep default uncached behavior.
No embedded-engine edits; MaxCDCL downstream notices and attribution preserved.

Mechanism: fewer repeated XOR gate variables/clauses. A cached literal already
has the same four-clause definition t = a XOR b; reusing that function preserves
existential projection onto original Pauli/weight/logical variables. The original
feasible set and weighted objective are unchanged. Signed/ordered keys and
per-build lifetime are correctness-critical. Risks: extra lookup/memory cost,
altered propagation/search despite semantic equivalence, ID/lifetime mistakes.
Expected affected cases: those with repeated ordered parity prefixes; quantify
sharing on the six pilot/Tier 1/Tier 2 matrices before measuring, without treating
gate reduction as runtime evidence.

## Gates and costs recorded before timings

Tier 0: build candidate with identical GCC 14.4 root Makefile application flags;
reuse unchanged baseline executable/engine objects only after verifying hashes.
Production-helper probe checks truth-table projection and unique extensions for
signed/repeated literals, exact-prefix reuse, and fresh-cache isolation. Exhaustive
small CSS oracle distances, BOTH/OFF/MTO solves, smoke, pinned QDistSAT pilot
LP_136_32_4 and BB_108_8_10 in OFF/MTO, and forced timeout soundness. Any wrong
distance/bounds, crash or semantic mismatch rejects and stops before timings.
Hosted PR check is still required before merge; local pilot is not hosted CI.

Windows Tier 1 diagnostic: BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6;
OFF and MTO separately, 3 baseline + 3 candidate, AB/BA/AB, serial, same inputs,
verbose logs, 180 s internal limit and 195 s watchdog. Preserve all 48 raw runs,
scientific tuples, failures and medians/ranges. Same E001 numerical rule: reject
disjoint per-case regression (candidate min > baseline max); require all medians
nonworse and geometric mean(candidate maxima / baseline minima) < 1 separately
in both modes for a numeric pass. Overlap/incomplete outcomes are inconclusive.
Do not discard runs, hide modes or adjust thresholds after observing timings.
Estimated lightweight elapsed few minutes; worst internal timing budget 144 min.

Interactive Windows/Cygwin host remains unreserved, unpinned, balanced power.
Local numerical results are diagnostic and cannot pass the original controlled
host promotion gate. Overall INCONCLUSIVE pending controlled run unless a
correctness failure rejects. Do not schedule Tier 2 or Tier 3 on this host.
If local filtering warrants later controlled work, provide exact source diff,
identity manifest, commands and offline package. Do not merge this experiment.
