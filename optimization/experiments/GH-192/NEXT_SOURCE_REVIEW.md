# Remaining practical prescriptions after GH192

The goal remains active. Prioritize actual unconfirmed distances and useful
structure/size gaps; keep explicit outstanding construction coverage rather
than declaring all mainstream CSS prescriptions collected. No new issue,
case selection, implementation or distance conclusion in these notes.

## Priority lead: quantum radial codes

Thomas R. Scruby, Timo Hillmann, Joschka Roffe, *High-threshold, low-overhead
and single-shot decodable fault-tolerant quantum memory*,
[2406.14445v2](https://arxiv.org/html/2406.14445v2), latest20Apr2026,
PRX Quantum7,020310, DOI10.1103/67xf-zdjb. Paper perpetual license;
original mathematics-only reconstruction, no author files/prose/code.
This is a specific lifted-product prescription, not a disjoint LP family.
AppendixC explicitly discusses numerically estimated distances; do not
inherit exact certification or run its external QDistRnd program.
AppendixD supplies two concrete exponent-matrix pairs:
- (r,s)=(3,5), n90,k8, source reported10:
  A1=[[3,2,1],[4,1,4],[1,2,3]],
  A2=[[3,3,0],[1,0,1],[4,2,0]].
- (r,s)=(4,11), n352,k18, source reported20:
  A1=[[10,10,1,6],[4,7,5,2],[8,10,6,9],[1,6,0,6]],
  A2=[[9,5,8,3],[5,4,1,0],[0,4,6,10],[2,8,4,2]].
Before selection visually check primary PDF, interpret claimed distances
as estimates unless independent exact proof located, verify SecII girth/
prime/r<=s/row-independence hypotheses and all actual binary dimensions.
Source circulants shift identity rows RIGHT, unlike PK first-column
convention; do not blindly reuse sign. Full lifted transpose/tensor-order,
actual-column/word/logical/duplicate gates remain. Formula bound<=2s is
not a substitute for materialized upper words or raw search fields.

## Genuine finite planar-boundary prescription: tile codes

Vincent Steffan, Shin Ho Choe, Nikolas P. Breuckmann, Francisco Revson
Fernandes Pereira, Jens Niklas Eberhardt, *Tile Codes: High-Efficiency
Quantum Codes on a Lattice with Boundary*,
[2504.09171v1](https://arxiv.org/html/2504.09171v1), latest/only listed.
Static CSS planar tiles/boundary checks require explicit reconstruction;
periodic BB/surface/color inputs do not alone establish this coverage.
Source includes [[288,8,12]], [[288,8,14]], [[512,18,19]] labels. Do not
relabel these as heuristic/open before proof-status review. The first
also appears in earlier Liang work, so same(n,k)/column equivalence review
matters. No tile inputs selected; boundary/commutation/source terms pending.

## Multivariate/trivariate bicycle prescriptions: avoid family inflation

Voss–Sim–Haug–Bharti [2406.19151v4](https://arxiv.org/html/2406.19151v4),
latest20Feb2025, uses z=S_l tensor S_m=xy (AppendixF): only two independent
cyclic factors. Its new label is not proof of an absent algebraic family.
Specific published prescriptions still need parameter/claim/peer review.
Galimova [2603.17703v1](https://arxiv.org/abs/2603.17703), latest/only,
claims independent three-factor codes; complete primary construction and
proof-status review still needed. Potential CRT reductions and already
collected Haah/GB/BB rowspace equivalences must be checked. No copy of
external implementations, no extra family count or input selected.

## Other unresolved-distance lead

GH191/NEXT_SOURCE_REVIEW.md records Mostad–Rosnes–Lin2025 GB688k30,
published d>=19 and full polynomial supports. A useful later target,
but radial/tile coverage can add distinct prescriptions first. The related
2505.06157v1 GB examples examined so far label exact d and do not by
themselves justify an unknown-only collection. Earlier APM source hold and
certified-expander/cosheaf finite-hypothesis/practicality gaps remain open.
