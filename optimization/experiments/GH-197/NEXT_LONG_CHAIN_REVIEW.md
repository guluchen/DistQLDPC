# Longer-chain prescriptions: source review, not selected

Primary sources/version checks:
- Jacob, McLauchlan and Browne, Single-Shot Decoding and Fault-tolerant
  Gates with Trivariate Tricycle Codes,2508.08191v3, latest2Oct2026,
  CC BY4.0; https://arxiv.org/html/2508.08191v3 .
- Lin, Lim, Kovalev and Pryadko, Abelian multi-cycle codes for single-shot
  error correction,2506.16910v3, latest16Mar2026, perpetual license;
  https://arxiv.org/html/2506.16910v3 .
- Mian, Gwilliam and Krastanov, Multivariate Multicycle Codes for Complete
  Single-Shot Decoding,2601.18879v2, latest24May2026, perpetual license;
  https://arxiv.org/html/2601.18879v2 .

These longer-chain finite prescriptions are not established merely by
existing2blockITB/BB/GB or ordinary2factorHGP labels. They overlap general
homological/Koszul constructions; do not assert new disjoint families.
Source checks/metachecks describe static CSS stabilizers, not subsystem
or circuit-distance inputs. Single-shot/threshold/gate claims require
additional hypotheses, not imported from matrix reconstruction.

TTv3 Table5 supplies particularly useful overall upper-only targets with
explicit polynomials:588k9<=14,648k6<=16,648k12<=14,735k18<=14,
840k9<=16,1029k18<=16. It separately gives X-upper estimates73/72/72/80,
and no numeric X value for840/1029. Those empty values remain absent.
A small exact source72k6d6 (torus4,3,2) can anchor construction. Do not
relabel other exact overall cases as heuristic just because their larger
X-distance is only an upper. Source uses mixed external methods; none
of their programs are read/copied/run here. Upper targets require our own
actual GF2 words, not an unverified borrowed distance scalar.

Own reconstruction plan: let3commuting torus matrices be A,B,C.
Hx=[A B C];Hz has3block rows [0 C^T B^T], [C^T 0 A^T], [B^T A^T 0].
Each cross term cancels in GF2. Independent inverse physical columns AND
actual block products/transpose would check all entries, ranks and quotient
bases. Source conventions need full primary PDF/table visual verification
before freezing inputs. Actual same(n,k)rowspace/physical equivalence review
and complete provenance required;35refs is only the current snapshot.

Tentative source-only parameter transcription (not generated/selected):
588:(7,7,4), A=1+yz+x^3y^2z, B=1+xy^4z+x^4y^4z^2,
 C=1+x^2y^2z+x^2y^4.
648k12:(6,6,6), A=1+x+x^4z, B=1+y+xyz^4, C=1+z+x^3y^2z.
735:(7,7,5), A=1+y^2+x^6y^5, B=1+x^2yz+x^2y^4z^3,
 C=1+x^4y^5z^2+x^5y.
840:(8,7,5), A=1+y^3z+xyz^2, B=1+y^5z+x^3y^4z,
 C=1+xy^3z^4+x^7yz.
1029:(7,7,7), A=1+y^2z^3+x^5y^5z, B=1+x^2y^5z+x^4z^5,
 C=1+x^4y^6+x^5y^4z^6.

Selecting one648 variant rather than both can cover distinct sizes without
quantity inflation. No next issue, input or solver experiment selected in
GH197. Current ITB Linux job40942338412/job123688677544 must finish first.
No external author communication, server core allocation or adoption claim.


Additional proof-status caution from MMv2 AppendixF: some table captions
refer to MIP, while other sizes use randomized information-set outputs yet
call the distances actual. Finite randomized sampling with no independent
lower proof must not be silently promoted into certified ground truth.
Before any MM case selection, pin the exact table row/method, distinguish
source wording from independently supported upper/lower evidence, and
review source certificate availability. Do not run the named external
solvers to settle this. TTv3 explicit <= labels avoid that ambiguity for
the proposed unknown targets; no MM result is adopted here.
