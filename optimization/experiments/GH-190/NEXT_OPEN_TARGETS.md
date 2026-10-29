# Next priority: published unresolved-distance reference inputs

PI steering2026-10-30: after this coverage batch, prioritize codes with
unconfirmed exact distance. Preserve intervals, heuristic estimates, our
verified physical upper words and search-certified lower bounds separately.
An interval in a paper is not proof that no later exact result exists.
Retain frozen easy/poor cases; do not replace them after observing results.

## First source to resolve before selecting the next batch

Panteleev–Kalachev, *Degenerate Quantum LDPC Codes With Good Finite Length
Performance*, [1904.02703v3](https://arxiv.org/html/1904.02703v3),
Quantum5,585(2021), DOI10.22331/q-2021-11-22-585, CC BY4.0.
AppendixA/Table1 report GB A1 [[254,28,14<=d<=20]] and A5
[[180,10,15<=d<=18]]. A1 has circulant length127 and supports
a=[0,15,20,28,66], b=[0,58,59,100,121] in the main-body example.
A5 length90 coefficients still need extraction from the primary PDF/TeX;
HTML loses its displayed equation. No guessed polynomial or author code.
Published intervals are source claims, not our independent verification.

The same source AppendixB supplies GHP [[882,24,18<=d<=24]] and
[[1270,28,16<=d<=46]]; explicit matrix data still require primary-equation
extraction. A later separate GHP/LP-specialization batch is possible.

Rabeti–Mahdavifar, *Univariate Bicycle Quantum LDPC Codes: Explicit Logical
Structure and Distance Bounds*, [2605.14173v1](https://arxiv.org/html/2605.14173v1),
SecV still compares against A1 with interval14..20. This corroborates its
continued use as an interval-valued reference, not global novelty/open status.
Its own TableI labels d values; do not silently reinterpret those as
heuristic-only just to create targets. GB specialization, not disjoint family.

## Selection and execution boundary

Check current issues/branches and newer primary sources, extract all source
parameters and check same-(n,k) peers across pinned library branches before
claiming/fixing a case list. Main currently has neither GB254k28 nor GB180k10;
GH171 divisor-GB inputs already exist and must not be duplicated. Record
three proposals and one chosen issue before construction. Keep GB prefix.
No implementation, input addition, new issue or distance result is claimed
by these notes. Apply ordinary GF2/full logicals/rowspace and physical
equivalence checks, byte reproduction and bounded Linux validation. No
external distance program; heavy unresolved proof becomes a frozen server
package with explicit PI allocation. All inputs stay untiered.

Certified-expander HGP/cosheaf practical-hypothesis gaps and the previous
APM source interpretation hold remain visible; they do not block these
independent unambiguous source investigations.
