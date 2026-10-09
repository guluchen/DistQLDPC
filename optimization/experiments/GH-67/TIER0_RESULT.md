# GH-67 Tier0 result — PASS

Candidate c39c37c (Makefile alignment flags only), frozen 43c0af4c…; baseline ac43af52….
- Build/smoke PASS; same warning count. Text segment 229,376 -> 262,144 bytes (alignment padding).
- Trace identity, 50 codes x 4 modes, 60 s, corrected comparator declared in PROPOSAL.md:
  200/200 OK (58 completed byte-identical with named distances; 142 timeouts child-prefix
  consistent). Original harness comparator flagged 2 timeout pairs, its documented defect.
- Relink controls R1–R3: distinct hashes, identical text size, BB90 OFF `-v` trace byte-identical
  to baseline.
- Hosted CI + QDistSAT cross-repo: SUCCESS, scientific match YES (`raw/hosted/`).
