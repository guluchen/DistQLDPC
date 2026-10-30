# CSS/qLDPC construction coverage

Continuous library goal, started 2026-10-29. This is a working acceptance
ledger, not a claim that all CSS codes or all papers have been covered.
The goal remains open until each applicable missing construction below has
representative reproducible inputs and completed validation. A documented
scientific/availability limitation requiring a PI decision remains an open item. Discovering another
major omission adds a row; it does not silently shrink the goal.

## Acceptance criteria

For each construction, record published parameters and distinguish exact
distances, lower bounds and heuristic upper estimates. Generate all four
matrices from published mathematics with original scripts; record provenance
and redistribution terms. Check GF(2) commutation, dimensions, both logical
quotient bases and full pairing, all same-(n,k) row spaces including X/Z swap,
and suspected column-permutation equivalence. Reproduce files byte for byte.
Run serial 60-second Linux smoke with retained source/binary/input identities
and raw logs; partial or missing numeric bounds remain incomplete gates.
A published small exact-distance anchor should be reproduced. New scientific
results remain PLAUSIBLE until independently checked with GF(2) witnesses.

Target a small anchor and several sizes spanning roughly 100-3000 qubits
where the construction supplies practical examples. Preserve known published
size ranges rather than inventing scaled distance claims. A connected-case
ladder is useful; repeated equivalent inputs or disconnected copies are not
additional coverage. Prefixes identify provenance, not disjoint mathematics.

All additions remain in `data/matrices/untiered`. No automatic tier assignment,
stem rename, QDistSAT mirror, solver change or main integration. Completed work
branches can accumulate while PI integration is pending. Heavy validation
becomes an exact reproducible server job package; no Mac solver experiments.

## Next-stage priority (PI steering, 2026-10-30)

After the current collection batch, prioritize individual codes whose exact
minimum distance has not been established: published nontrivial intervals,
heuristic-only estimates, and reproducible original finite instances with
unconfirmed exact distance. A missing value in one paper is not evidence of
a globally open problem. Check available primary source/version and recorded
proofs before labeling any case open. Preserve claimed distance/estimate,
verified actual-word upper and search-certified lower as separate fields.

Select structural/size gaps with useful remaining distance uncertainty;
avoid equivalent copies or quantity-only parameter expansion. Known-distance
anchors and outstanding mainstream family coverage remain useful controls
but no longer take priority over suitable unresolved-distance targets.
Do not discard easy or poor results after frozen selection. Retain independent
verification, licensing, untiered placement and bounded-compute requirements.

## Current evidence snapshot

Base main `6083e662c621f3b66defd434cfae31a028d483c4`: 51 tiered codes and
24 untiered codes. The separate GH-160 branch contains six more BP inputs;
those are not part of this branch or main. GH-164 contains six BB inputs on its separate reviewed work branch.
GH-165 adds four hyperbolic inputs on its separate work branch.
GH-166 adds six nonabelian ZSZ-LP inputs on its reviewed work branch.
GH-167 has six pair-partition CPM inputs on its separate work branch. GH-168 has six periodic toric inputs on its separate work branch. GH-169 has six finite-group Tanner inputs on its separate work branch. GH-170 adds four quaternary group-valued PP inputs on its separate work branch. GH-171 adds four divisor-driven cyclic GB inputs on its separate work branch. GH-172 adds six triangular4.8.8 inputs on its separate work branch. GH-173 retains six Gallager-LDPC-factor HGP controls on its separate work branch. GH-174 adds four first-distinct-column HGP inputs on its separate work branch. GH-175 adds six periodic4D toric inputs on its separate work branch. GH-176 adds six explicit covering-graph BB inputs on its separate work branch. GH-177 adds six source-open weight5 LLM CSS BB inputs on its separate work branch; all six exact distances now cross-checked. GH-178 adds six finite circle-bundle inputs on its separate work branch. GH-179 adds six finite single-sector homological-product CSS inputs on its separate work branch. GH-182 adds six Haah Code1 inputs on its separate work branch; two numeric gates and seven proof jobs remain. GH-184 adds six closed higher-genus static4.8.10 color candidates on its separate work branch. Local+Linux47units/full topology/integer-cover/logicals/actual-word/rowspace and byte-reproduction gates pass; one numeric gate and five proof jobs remain. Counts measure files, not families.

| Construction class / specialization | Coverage and remaining work | Evidence |
|---|---|---|
| Repeated-cyclic multi-block CSS hyperbicycle | GH205 six fixed inputs N420..2700,K30/50; local full GF2/logicals/independent physical incidence/complete small classical kernels/source hypotheses/connected stabilizer support and24-file reproduction pass. Source900 exact14 control; five original finite specializations retain theorem intervals and actual words separately. Linux40961747658 passes53units/24-file byte reproduction and all12numeric gates; both engines+GF2 confirm global8/11/11 at N420/840/1260. Source900 CC14 reproduces known exact14; N1800/2700 CC14 remains PLAUSIBLE with MaxSAT[9,14]. Three unexecuted MaxSAT proof completions packaged, zero optionalCC/numeric/source-word jobs. Preserve easy symmetric outcomes; no distance-growth or global novelty assertion. This is a lifted-product specialization, not a disjoint-family increment | Kovalev–Pryadko [1212.6703v2](https://arxiv.org/abs/1212.6703v2), Eq19/Theorem9/Examples5–6; scripts/codegen/HYPERBICYCLE.md, GH205 report |
| Dual-containing quantum BCH, generally non-LDPC CSS | GH207 five fixed nonprimitive binary CSS inputs n85/341/819/1365/1365,k53/261/699/1173/1149. Terminal short gates retained; independent finite physical-root certificates prove exact5/9/11 and bounds17..22/19..24 with actual words. Raw MaxSAT5..5/5..9/3..11/null/null and CC5..5/7..9/6..11/5..22/5..24 remain separate. Last2 numeric/proof gates need guarded unexecuted server jobs.73local contracts,20byte regeneration and41pinned peer scans PASS; certificate Linux contracts PASS run40984476152/job123832151018. Dense CSS, not qLDPC; no global openness/novelty claim | Aly–Klappenecker–Sarvepalli [quant-ph/0604102v1](https://arxiv.org/abs/quant-ph/0604102v1), Theorem19; GH207 REPORT and raw/certificates |
| Binary prime quantum quadratic-residue (QR), dense CSS | GH208 five fixed p23/431/719/1031/2039,k1. Both engines and independent tiny coset confirm Golay7. Four intended unresolved-distance targets retain physical certificate/actual-word intervals23..71/31..135/35..191/47..427. Original native bounds remain separate. Linux49contracts/construction/20bytes/all actual-word gates PASS; MaxSAT2039numeric INCOMPLETE, one required unexecuted job. Seven optional searches are research, not failed acceptance gates.54local static contracts and42pinned peer scans PASS; final retained-only Linux54PASS40995422015. Dense single-qubit CSS, not qLDPC or global openness/novelty claim | Ketkar et al. [quant-ph/0508070v2](https://arxiv.org/abs/quant-ph/0508070v2) Thm40; Grassl2023 DOI[10.1007/s11128-023-03835-3](https://doi.org/10.1007/s11128-023-03835-3) Prop7; Zurel et al. [2603.18560v2](https://arxiv.org/abs/2603.18560v2) Thm3/Cor4/Table1; GH208 REPORT |
| Polynomial-minor2x3 three-block cyclic CSS | GH209 six frozen liftsN9/85/255/425/595/935,n27/255/765/1275/1785/2805,k4/80/88/80/80/80.53Linux construction/source/Smith/logical/word/24byte checks and12selected short attempts PASS; known4reproduced. Published255exact12 remains source claim, both native proofs5..12/8..12 incomplete. Four original new targets have actual upper54 and CC8lower PLAUSIBLE; source/native/certificate fields separate. Default1785/2805numeric gates incomplete.4required jobs,6optional searches unexecuted.62local static contracts/43peer refs PASS; final Linux replay pending. Related Koszul specialization, not disjoint family/global novelty claim | Nourozi–Smarandache–Mitchell [2610.19459v1](https://arxiv.org/abs/2610.19459v1),Eqs10/11,Thm5,TablesI/II; POLYNOMIAL_MINORS.md/GH209 REPORT |
| Bivariate bicycle (BB), ordinary weight-6 | Existing tiered family | `NOTICE` section 5, tier0..tier5 |
| Generalized bicycle (GB), cyclic two-block | Existing tiered family; GH-171 adds four fixed divisor-driven cyclic examples n46/66/90/170, independent source/algebra/logical/duplicate checks and all numeric Linux smoke gates pass; both engines reproduce exact8/7/10/8 with GF(2) words; separate work branch only | `NOTICE` section 5; Lu et al. [2608.09115](https://arxiv.org/abs/2608.09115) supplies these fixed cases (v3) |
| Lifted products (LP), existing cyclic lifts | Existing tiered family; not a substitute for nonabelian group examples | `NOTICE` section 5 |
| Quantum Tanner codes | Existing TN family; must not describe it as absent | `NOTICE` section 5 |
| Generalized Tanner prescriptions from non-Cayley Schreier graphs | Explicit finite specialization still to reconstruct; existing face-qubit group/Tanner and DHLV edge-qubit cases do not establish the non-Cayley prescription. Published small journal examples are exact labels, so future correctness/coverage controls rather than priority open-distance targets. Need labelled local views/quadripartite cover/tensor constraints and peer checks; no automatic asymptotic-good claim for an arbitrary finite sample | Mostad–Rosnes–Lin, IEEE JSAIT6,367–382(2025), DOI[10.1109/JSAIT.2025.3594310](https://doi.org/10.1109/JSAIT.2025.3594310), TableI/AppendixB; journal accepted manuscript differs from earlier arXiv2405.07980v2 |
| HGP, repetition factors / planar surface specialization | Six inputs n=13..1105 on main; largest default smoke lacks numeric bounds, supplemental [9,26] | GH-153, `untiered/README.md` |
| HGP, cubic-graph cycle factors | Six inputs n=45..2866 on main; n=2866 default smoke lacks bounds, supplemental [5,8] | GH-154, `CYCLE_HGP.md` |
| HGP, genuine degree-three Gallager LDPC factors | GH-173: six fixed first-seed(3,4) ensemble factors, N80..2897; all algebra/44 units/regeneration and Linux classical-product+both-engine exact proofs pass, d2/2/2/4/2/2. Five factors have duplicate columns. VALID_UNEXPURGATED_CONTROLS, neutral for distance growth; those controls alone did not supply a finite distance step. GH-174 adds four explicit conditional-ensemble cases N356..2384; first-admissible replay/algebra/44 units/regeneration and all numeric Linux smokes pass; complete classical-product proof plus CC confirm d4/4/6/6 with GF(2) words, MaxSAT exact first two and[5,6] last two. Two optional MaxSAT-only reproduction jobs packaged; finite distance step only, no deterministic/asymptotic guarantee. Typical ensemble growth is not a finite-seed guarantee | Gallager1963 Sec2.2/Theorem2.4; Tillich–Zemor [0903.0566v2](https://arxiv.org/abs/0903.0566v2) Theorems1/15 |
| HGP / quantum expander codes with an explicit certified growing-distance factor family | Remaining research gap. Finite Gallager samples represent genuine LDPC factors but do not establish a deterministic expander-factor family | [1504.00822](https://arxiv.org/abs/1504.00822) |
| Color codes, triangular 6.6.6 | Six inputs n=7..2791 on main; n=2791 numeric upper-bound smoke gate incomplete | GH-156, `COLOR666.md` |
| Color codes, 4.8.8 / closed higher-genus variants | GH-172 static triangular4.8.8 cases n31..2887 from explicit published coordinates, independent wedge/GF(2)/full-logical/upper-word checks,44 units and24-file regeneration pass; both engines exact7/11 on n31/71, CC-only exact19 on n199 PLAUSIBLE; MaxSAT numeric gates n1567/2887 INCOMPLETE, seven unresolved proof jobs packaged. GH-184 now supplies six fixed closed static4.8.10 candidates n240..2400,k16/28/36/64/76/124,genus4/7/9/16/19/31. Independent finite regular-group/reflection/all manifold links/color-orbits/integer primitive covers/full chain projection-transfer/logicals/physical rowspace and actual basis words pass locally+Linux,47units;24matrix+6full-certificate byte reproduction and actual-word audit replay. Both engines exact8 at n240/480; CC-only exact12/8/16 at n640/1200/1440 PLAUSIBLE; n2400 CC[2,8] with actual basis upper8 and default MaxSAT numeric fields missing(INCOMPLETE). Five guarded jobs packaged unexecuted. Fixed single-class cover controls are not advertised as growing-distance. Static k/distances are distinct from Floquet values; not a new independent family | Shutty [2609.21376v3](https://arxiv.org/abs/2609.21376v3) AppendixD; closed static: Bombin–Martin-Delgado quant-ph/0605138v3 Eqs1–3; Higgott–Breuckmann2308.03750v2 SecII.1–II.3 Wythoff; Breuckmann–Terhal1506.04029v2 TableI rows1–3; original integral cyclic covers |
| Three-dimensional stabilizer color codes | GH-185 adds seven fixed static volume-X/face-Z colex inputs on its separate work branch: published cube anchor n8,k3,d2 and original periodic flag-dual T3 instances n384/576/864/1296/1728/2304,k9. Complete independent primal flags/colored residues/local spherical volume boundaries/integer primal and actual colex GF2 chains/Betti/logicals/physical row-space/actual upper-word checks pass;14 new units,28 matrices+7 complete certificate byte reproductions pass. Supplied-basis uppers4/4/4/6/6/6 are not asserted minima or globally unsolved cases. Local+Linux48units/construction/28matrix+7certificate regeneration and actual-word audit replay pass; all seven numeric gates PASS. Both engines exact2/4/4/4/6/6; n2304 MaxSAT[5,6]/CCexact6 PLAUSIBLE with one guarded unexecuted proof job. That work branch has31untiered+51tiered; other library branches remain separate. Gauge-only/subsystem or circuit data are not interchangeable with these static CSS matrices | Bombin–Martin-Delgado [cond-mat/0607736v3](https://arxiv.org/abs/cond-mat/0607736v3), Phys.Rev.B75,075103(2007); finite original parameters and source-license boundaries documented in COLOR3D.md; Linux numeric gates passed, one independent proof remains |
| General quantum pin-relation CSS codes | GH-189 adds6 fixed candidates here: source complete-relation [[256,30,8]] anchor plus five original tensor-chain flag cases n160/240/1152/1728/2304,k64/142/60/84/207. Independent recursive boundaries, full factor-edge/permutation flags, endpoint parity, all even D-pin fibers and physical pinned classes/columns/full logicals/GF2/actual words/typed physical rowspace pass;16new+34prior units, no same(n,k) peers across28 pinned refs. Independent support-isolation lower4/8 meets actual upper words, so retain these as small-distance controls rather than growth/open-problem claims; Linux40920177770 passes50units/full construction/24matrix+6certificate byte regeneration and actual-word audit replay; CC+finite certificate+GF2 cross-check all6 exact4/4/8/4/4/4, first4 MaxSAT exact and last2[3,4]/no numeric fields. n2304 numeric INCOMPLETE, one unexecuted MaxSAT completion job. Static checks, no gauge/circuit semantics; no source individual exact value transferred to originals | Vuillot–Breuckmann [1906.11394v3](https://arxiv.org/abs/1906.11394v3), Defs1–4/Prop3/11, SecII-F3/V-B; DOI10.1109/TIT.2022.3170846. PIN_RELATIONS.md/GH-189/REPORT.md and MODIFICATIONS.md finite proof; source perpetual license, original mathematics only |
| Active-only orthogonal affine permutation (APM) CSS | Published upper-only practical-size candidates identified, but SOURCE_WITNESS_REVIEW_HOLD. Original fixed-word checks reproduce C1 n2592,k1300 ranks646/646/commutation and X word10, while source Z word10 has22 odd X checks under explicit companion row convention; independent set calculation agrees. PDF and latest v1 checked. Column convention does not resolve the published pair. No APM input added, no distance search/external tool/author contact, no claim disproving the overall upper10. PI source-interpretation review before adoption; other work can continue | Kasai [2604.15307v1](https://arxiv.org/abs/2604.15307v1), Sec3/Table2 C1/Examples7.7–7.8; companion2601.08824v4 explicit row convention. Complete one-check counterexample and two original reproduction scripts in GH-188/NEXT_SOURCE_REVIEW.md |
| X-cube / foliated type-I fracton CSS | GH-190 adds4 fixed oddL3/5/7/9 inputs here, n81/375/1029/2187,k15/27/39/51. Independent actual link/cube/plane-star columns, full source ranks/logicals/pairing/typed physical space and complete L-disjoint stabilizer-coset detector families pass;16new+34prior units. Actual line/ribbon upperL matches disjoint-detector lowerL in both halves. No same(n,k) peer across29 pinned refs; finite structure/scaling control, no unknown-distance/gauge/decoder/energy-barrier claim. Linux40922592722 passes50units/full construction/16matrix+4certificate byte reproduction/actual-word audit replay. Both engines exact3/5/7; CC exact9 plus independent finite proof and GF2 word cross-check. n2187 MaxSAT has no raw numbers, numeric INCOMPLETE; one unexecuted completion job | Vijay–Haah–Fu [1603.04442v1](https://arxiv.org/abs/1603.04442v1), TableI/main Hamiltonian/AppB odd-L formula; PRB94,235157(2016), DOI10.1103/PhysRevB.94.235157; original source/proof in XCUBE.md/MODIFICATIONS.md/GH-190/REPORT.md |
| Haah cubic / fracton CSS codes | GH-182 has six fixed Code1 candidates L2/4/6/8/10/11,n16..2662 with actual k6/14/6/30/6/2; local+Linux45units/physical columns/GF2/full logicals/weight-preserving XZ involution/24-file reproduction and actual-word audit pass. Both engines exact2/8; CC-only exact18 PLAUSIBLE. Published [[1024,30,13<=d<=32]] from1904.02703v3 AppendixB itemD/Table1 now has actual GF2 upper32, provisional CC lower19; other open CC[19,50]/[19,121] have actual basis uppers and provisional lower19. Haah128 word8 vs independently confirmed covering BB peer exact12 proves inequivalence. Default MaxSAT n2000/n2662 numeric fields missing (INCOMPLETE); seven unexecuted proof/numeric jobs packaged; do not infer finite distance or a self-correcting memory theorem from the absence of string logicals | Haah [1101.1962v2](https://arxiv.org/abs/1101.1962v2), Phys.Rev.A83,042330(2011); finite source/peer/upper-word gates pass; remaining numeric/proof jobs in GH-182 |
| BB on twisted quotient tori | Six published inputs n=30..340 on main, all numeric smoke gates passed | GH-159, `TWISTED_TORUS.md`, [2503.03827v3](https://arxiv.org/abs/2503.03827v3) |
| Tanner-cycle balanced product, cyclic action | Six inputs n=78..962 on `codex/balanced-tanner-library`; five distances cross-checked, largest CC-only exact pending independent completion | GH-160, [2012.09271v3](https://arxiv.org/abs/2012.09271v3) |
| Weight-8-check BB | GH-164: six published examples at n=72,144,200; all exact claims reproduced by both engines, GF(2) witness audit passes; work branch only | `WEIGHT8_BB.md`, [2609.06572v1](https://arxiv.org/abs/2609.06572v1) |
| Periodic toric codes | GH-168: six periodic square toric inputs n18..2888,k2; all six both-half distances independently confirmed by internal signed-cover BFS/GF(2); both CLI engines exact first four, numeric gates n1458/2888 incomplete, three server jobs prepared. Planar repetition-HGP alone did not provide this topology | Kitaev [quant-ph/9707021](https://arxiv.org/abs/quant-ph/9707021) |
| Closed hyperbolic surface codes | GH-165: four {5,4} inputs at n=60,160,360,1800; independent quotient/manifold and both-half graph distances pass. Both engines solve first three; n=1800 numeric smoke incomplete after bounded diagnostics, server package prepared. Published n=1920 normal-closure ambiguity awaits PI decision | Breuckmann-Terhal [1506.04029v2](https://arxiv.org/abs/1506.04029v2) |
| Nonabelian balanced / lifted products and ZSZ-LP | GH-166: six published nonabelian ZSZ-LP cases n=160..775; all numeric smoke gates and upper witnesses pass. Two-engine d=10,12; CC d=14 pending other engine. Stronger open-code CC lower bounds marked PLAUSIBLE; seven exact-proof jobs packaged; cyclic GH-160 alone did not complete this coverage | Hong [2607.27644v1](https://arxiv.org/abs/2607.27644v1) |
| Moderate-blocklength Quantum Tanner from new finite groups | GH-169: six fixed nonabelian group/local-code inputs n288..864, source numeric parameters pinned and both source stabilizer spaces proved equivalent after explicit group enumeration. Independent inverse-permutation/column pullback,46 units, algebra/regeneration and all numeric smoke gates pass. Overall source upper words15,18,18,18,9,27 GF(2)-verified; CC-only exact9/lower improvements PLAUSIBLE,11 unresolved proof jobs packaged. Retain heuristic d as upper estimates | Mian et al. [2608.12509](https://arxiv.org/abs/2608.12509); Eq.(34), Tables1/9/12 give a lifted construction with explicit permutation-group multisets and column permutations; preserve table-specific heuristic upper bounds; GH-169 fixed local matrices and right-action inverse verified against numeric source records; remaining gate status in its report |
| Pair-partition / group-valued constructions | GH-167 pair-partition CPM cases n=104,276,472,584,1112,1784: source/pairing/CSS/girth checks pass; two-engine exact8 at n104, CC-only exact16/18/20 provisional, n1784 default numeric gate incomplete and CC [22,126]; seven unresolved engine proofs packaged. GH-170 adds four quaternary trace-expanded PP inputs n256..1024 including C16 x C2; source/field/group/GF(2)/reflection/source-word checks,46 units and all numeric smoke gates pass; CC exact12 and stronger lower bounds PLAUSIBLE, seven unresolved engine proofs packaged; no disjoint-family count claimed | Okada-Kasai [2607.14091](https://arxiv.org/abs/2607.14091); Lee [2610.06820v1](https://arxiv.org/abs/2610.06820v1), Sec.V and App.D.2, supplies a noncyclic C16 x C2 PP target; numeric C16 x C2 arrays and physical witness now located in the pinned public proof-data bundle; GH-170 rebuilds four mathematical instances including this product group; repository has no LICENSE so no original matrix/proof-program redistribution |
| BB from covering graphs | GH-176 adds six fixed weight8 inputs n64..288,k14; independent physical columns, actual neighborhood bijections, connectedness and chain projection/transfer identities pass, with full logicals and no same(n,k) peers. Linux44units/regeneration/all numeric gates and actual-word audit pass. Both engines exact8/12; CC-only exact16 at n192 PLAUSIBLE; other CC intervals[18,20]/[18,22]/[18,24] retain provisional lower bounds and verified upper words. Seven unresolved engine proofs packaged, unexecuted. Exact8/12 anchors and upper estimates16/20/22/24 remain distinct; this is a BB provenance/structure specialization, not a disjoint family | Symons-Rajput-Browne [2511.13560v3](https://arxiv.org/abs/2511.13560v3), Tables7/8 |
| LLM/evolution-discovered BB | GH-177 adds six model-attributed, source-connected/class-nonexact CSS targets n120..432,k4 with original weight5 generator, source hash/selection/provenance/license, independent columns/logicals and basis-independent row-space connectivity. Local+Linux45units/regeneration/all numeric/actual-word audits pass. All six initially source-open cases independently completed by both engines at exact10/9/12/16/22/23 with GF2 words; n180 source estimate14 improves to12 for ID CS-0d018ae6. No unresolved engine jobs; source supported uppers and decoder estimates remain separate. This is discovery provenance, not a disjoint mathematical family | Cruz-Benito [2610.06623v1](https://arxiv.org/abs/2610.06623v1), Eq1/2; qcode-discovery@da9178fd65ffc2eec3dab46089f9879eb02d4b23 |
| Homological products / higher-dimensional homological CSS | GH-175 adds six periodic4D face-qubit toric inputs n96..3000,k6. Independent column reconstruction and standalone finite-matrix lower/upper certificates confirm both-half d4/6/9/12/16/20; Linux46 units/regeneration/actual-word audit pass; CC reproduces all six exact distances and MaxSAT first five. MaxSAT n3000 default smoke has no numeric fields (INCOMPLETE), one unexecuted server completion job packaged. GH-179 now adds six explicit Bravyi-Hastings single-sector CSS products n169..2809,k9..169, with independent factor inverse/conjugacy/nilpotence, actual product columns, full canonical/computed logical quotient bases and actual upper words; local+Linux45units/construction/inventory/regeneration and actual-word audit pass. Both engines confirm exact2/4; CC-only exact6 PLAUSIBLE; other provisional combined intervals[10,12]/[9,16]/[8,49], all actual upper words GF2-verified (n2809 basis49 materialized separately). MaxSAT n2809 has no numeric fields (INCOMPLETE); seven proof/numeric jobs packaged unexecuted. These checks can grow asO(sqrtN), not constant-check modern qLDPC. No finite asymptotic-distance claim; periodic4D alone did not represent this construction | Breuckmann et al. [1609.00510v2](https://arxiv.org/abs/1609.00510v2), Sec.2/Fig.1; general product [1311.0885](https://arxiv.org/abs/1311.0885) |
| Spatially coupled2D-SC-HGP / quasi-abelian lifted products | GH-188 adds fixed published Eq89 3x7 partitions over C_L x C_L, L2/4/5/7/10, n232/928/1450/2842/5800,k88/280/424/808/1624. Source n5800 Table2 Code7 has estimated upper16, not exact; smaller original periods inherit no source distance/decoder/cycle claim. Independent actual columns, source Eq58 tensor-order bijections, complements/inverse shifts/two-path cancellation/full logicals/GF2/actual words/typed physical space pass;13new+34prior units. Initial basis uppers2/4/10/14/20 verified; initial source-upper word gate was pending and later passed. No same(n,k) peer across27 pinned refs. Linux run40915696103:47units/full construction/20matrix+5certificate byte regeneration/actual-word audit replay PASS; both engines exact2/4/8 for first3; CC-only14/16 PLAUSIBLE for n2842/5800. Source upper16 actual-word PASS; n5800 MaxSAT numeric INCOMPLETE; two unexecuted MaxSAT jobs. Spatially coupled provenance is a lifted-product specialization, not a disjoint new family | Yang–Calderbank [2305.00137v6](https://arxiv.org/abs/2305.00137v6), Eq58/Sec6.1 footnote2/Table2 Code7/AppB Eq89; Quantum9,1693(2025), CC BY4.0 attribution in NOTICE; SPATIALLY_COUPLED.md and GH-188/REPORT.md |
| Quantum Margulis / SL(2,p) two-block group algebra | GH-187 adds three original fixed p5/7/11 inputs here, n240/672/2640,k4/20/58, proposed prefix QMC. Independent integral rank-one generators/complete SL2/faithful nonprojective vector composition/all regular and inverse maps/commuting squares/actual columns/logicals/GF2/actual words/typed physical rowspace checks pass;15new+34prior units,12matrix+3certificate byte reproduction. Actual basis uppers52/26/12 are not minima. No same(n,k) peers across pinned main/library refs. Linux40912242015 passes; n672 both engines exact8; n240 CC-only17 and n2640 CC-only10 PLAUSIBLE; n2640 MaxSAT numeric INCOMPLETE; two unexecuted MaxSAT jobs. Actual words17/8/10 GF2-verified and local audit byte-identical. No unlicensed author matrices copied; no identity with ambiguous source642 dataset or k/decoder transfer. This branch27untiered+51tiered. This is2BGA provenance/group specialization, not disjointness or certified-distance theorem | Pacenti–Chytas–Vasic [2503.03936v3](https://arxiv.org/abs/2503.03936v3), Sec3 Eq8/Sec4 Eqs10–11; Quantum10,2101(2026), DOI10.22331/q-2026-05-12-2101; original source/provenance/soundness in QUANTUM_MARGULIS.md; raw/actions/default and runner in GH-187 |
| DHLV edge-qubit Tanner chain complexes | GH-186 adds six original fixed finite edge-qubit chains on its separate work branch, n108/784/1176/1568/1960/2744,k10/40/50/48/58/66. Faithful polygon group action, all edges/squares/full stars, every actual binary boundary column/corner tensor cancellation, full logicals/actual upper words and physical rowspace checks pass;15new+34prior units and24matrix+6complete-certificate byte reproduction. Supplied-basis uppers4/8/6/28/10/34 are not minima. No same(n,k) peers across main/pinned library refs. Local+Linux49units/construction/24matrix+6certificate byte reproduction and actual-word audit replay pass. Both engines exact4/8/6; CC-only exact16/10/14 PLAUSIBLE. Largest default MaxSAT numeric fields missing(INCOMPLETE); three guarded unexecuted proof/numeric jobs packaged. That work branch30untiered+51tiered. Distinct from collected face-qubit Tanner prescription; additional asymptotic expansion/robustness/decoder guarantees remain uncertified | Dinur–Hsieh–Lin–Vidick [2206.07750v1](https://arxiv.org/abs/2206.07750v1), Sec2.4/2.7/3.1 Eq6 and Lemma3.1; CC BY4.0 attributed in NOTICE; original finite source/chain/provenance and actual-word checks pass, one numeric/three proof gates remain |
| Cubical cosheaf / quantum locally testable CSS constructions | New research backlog identified during GH-185. The2026 preprint claims an explicit good qubit qLTC family, but its fixed numerical specialization uses r=2^15 and directional local lengths2^(r+i-1)+1, far beyond this library's practical sizes. This is a source claim/feasibility observation, not an independently validated theorem or matrix. Smaller substitutes must not inherit good-distance/testability claims without verifying every hypothesis | Gay–Jeronimo [2609.20780v1](https://arxiv.org/abs/2609.20780v1), Sec2/9/12/13.4; no source software/matrices copied and no implementation claimed |
| Fiber-bundle and asymptotically good qLDPC constructions | GH-178 supplies six original finite Definition2.11 circle bundles n252..2800 with full-rank(3,4) bases, nonremovable square-fiber subgroup twists, full logicals and actual upper words9/9/25/25/25/25; local+Linux45units/independent chain/gauge/rowspace checks/regeneration and actual-word audit pass. Both engines exact9 at n252/378; CC-only exact13 at n1400 and18 at n2100 PLAUSIBLE. Other CC[20,23]/[20,25] have provisional lower20. Default MaxSAT n1750/2100/2800 has no numeric fields (INCOMPLETE); six unresolved proof/numeric jobs packaged, unexecuted. This represents the finite bundle definition, not the paper's asymptotic polylog-base/weight-reduction specialization or asymptotically-good qLDPC. Those stronger hypotheses/practical good-code coverage remain genuine research gaps | Hastings-Haah-O'Donnell [2009.03921v2](https://arxiv.org/abs/2009.03921v2), Sec2.3/Definition2.11; good-code finite parameters remain to investigate |

Research-target links do not imply parameter extraction or license review has
passed. The broad literature backlog intentionally remains visible, including
families for which practical finite inputs may require PI judgment. Non-CSS,
subsystem-only, gauge-fixed and circuit-distance objects cannot be silently
converted into inputs for this CSS stabilizer-distance solver.

## Execution order and durable state

1. GH-164 package complete on its work branch: independent witness audits and raw Linux logs retained. Main integration remains pending PI approval.
2. GH-165 first three cases validated; n=1800 numeric smoke remains open for the prepared server package, and n=1920 remains a PI interpretation decision. Independent ZSZ-LP work is tracked in GH-166; periodic toric references are being added in GH-168.
3. GH-166 six-input library package passes construction/numeric gates; retain its provisional scientific bounds and unexecuted proof jobs. GH-167 CPM construction and five numeric gates pass; n1784 numeric gate and independent lower-bound completions remain open with a server package. GH-168 has six internally verified toric distances; two largest CLI numeric gates remain open with a three-job server package. GH-169 finite-group Tanner numeric/construction package passes; retain provisional lower bounds and its11 unexecuted proof jobs. GH-170 group-valued/quaternary PP construction/numeric package passes; its stronger lower bounds/exact12 remain provisional with seven unexecuted proof jobs. Other remaining cases stay open, prioritizing new structure over more BB variants.
4. Cover the remaining handoff targets and genuine family gaps; repair the
   incomplete numeric smoke gates listed above using short checks or a server
   package, without reinterpreting UNKNOWN as a certified interval.
5. Audit every row and every acceptance criterion against current files and
   durable evidence before claiming the continuous goal complete.

One construction per branch/report. The next agent should inspect current
main, work branches, issues and this ledger before selecting work. Relevant
active solver topics at this snapshot: GH-148, GH-152, GH-157, GH-162; library
work does not alter their solver files or occupy their server cores.


## PI priority update (2026-10-29)

PI priority first recorded during GH-176 and reiterated during GH-179:
after the current batch, prioritize cases whose exact
distance is unknown: published intervals, verified upper bounds or explicitly
heuristic estimates, especially substantial unresolved gaps across missing
families and sizes. Keep small known-distance anchors for correctness, but
further selection should emphasize open targets. Never promote a heuristic
claim to a verified bound without an actual checked word or search proof.
This priority supplements the full coverage goal; it does not remove open
families or waive validation, licenses, resource limits or PI decisions.

## Additional practical prescriptions requiring source reconstruction

These are open coverage items, not extra completed family counts. Primary
source review during GH192 identified specific prescriptions not established
by the existing generic LP/BB/surface labels:

| Prescription | Current evidence and next gate | Primary source |
|---|---|---|
| Quantum radial lifted products | GH193 adds sourceD2 n352k18 plus fixed original moduli29/47/79 n928/1504/2528,k18. Actual source columns/spoke pullback/hypotheses AND classical+quantum ranks/full logicals/typed space/ring words22/58/94/158 pass;17new units/16matrix byte reproduction,32pinned peer refs. Source90 is comparison-only due unresolved BB90 equivalence, no duplicate. Linux40931932802 passes51units/full16matrix byte reproduction/actual-word audit replay; actual uppers20/26/26/26 and source352 word20 PASS. Raw MaxSAT[9,20]/[9,26]/[9,26]/no numeric fields; CC[19,20]/[22,58]/[22,26]/[22,26]. Strongest CC lower19/22 PLAUSIBLE, largest MaxSAT numeric INCOMPLETE. Four default proof/numeric jobs and separately optional4CC completions frozen unexecuted. Common upper26 is not growth evidence; no inherited exact/single-shot claim | Scruby–Hillmann–Roffe [2406.14445v2](https://arxiv.org/abs/2406.14445v2), PRX Quantum7,020310(2026), DOI10.1103/67xf-zdjb |
| Planar tile CSS codes with boundary | GH194 implements four frozen finite boundary cases n288k8/n512k18/n1152k18/n2592k18 on this work branch. Source exact12 anchor and weight10 upper23 example distinguished; last2original, no inherited distance. Independent blue T2/reverse columns/Laurent+finite-boundary/pruning/full ranks/logicals/actual basis words and18new+34prior units PASS;16matrix+4certificate byte regeneration. Sole same(n,k)peer TN288 across33pinned refs is proved physically inequivalent via full typed stabilizer weight1..3 count invariants, not provisional Tanner lower bounds. Linux40936889050 passes52units/full construction/peer/inventory/16matrix+4certificate byte reproduction and retained actual-word audit replay. Both engines exact12 at288;512 rawMaxSAT[9,21]/CC[13,21],1152[5,41]/[12,46],2592MaxSATno numeric/CC[12,161]. Actual uppers12/21/41/161; source51223 word PASS. New strongest CC lower13/12/12 PLAUSIBLE, largest numeric INCOMPLETE;3defaultMaxSAT proof/numeric+3separateoptionalCC jobs frozen unexecuted. No main integration | Steffan et al. [2504.09171v1](https://arxiv.org/abs/2504.09171v1) |
| Published multivariate/trivariate bicycle prescriptions | Under source/equivalence review, not an automatically missing disjoint family. Voss third variable z=xy leaves two independent factors; independent three-factor prescriptions require CRT/Haah/GB/BB peer checks and source proof-status review | Voss et al. [2406.19151v4](https://arxiv.org/abs/2406.19151v4); Galimova [2603.17703v1](https://arxiv.org/abs/2603.17703v1) |

Details and unselected source parameters in GH192/NEXT_SOURCE_REVIEW.md.
Existing unresolved scientific/numeric gates remain; these additions keep
the original family-coverage goal visible while prioritizing unknown distance.

## Published interval targets after initial family coverage

GH191 adds PK2021 GB A1/A5 n254k28/n180k10 on a separate workbranch,
published14..20/15..18. Existing GB family, no new family label. Independent
physical columns/gcd/full logicals/GF2/typed stabilizer space/XZ map and
30pinned peer inventories pass;13new units/full8matrix byte regeneration.
Linux40925199585 passes47units/full8matrix byte reproduction/actual-word
audit replay; actual words20/18 reproduce source upper claims. MaxSAT
[10,20]/[9,18], CC[16,20]/[17,18]; numeric/word gates PASS, CC lower16/17
PLAUSIBLE pending independent proof. Four unexecuted proof jobs.
Source1904.02703v3 AppendixB sectionA/Table1; NOTICE/REFERENCE_GB.md.

GH192 adds PK2021 QC GHP/LP B1/B3 n882k24/n1270k28, published18..24/16..46,
original scalar-B/square-A lifted construction. Independent actual columns/
layer-major pullback/full logicals/GF2/typed physical space/cyclic map pass;
14new units/8matrix byte reproduction/31pinned peer refs. Actual basis
uppers initially24/64. Linux40927713672 passes48units/full8matrix byte
reproduction/actual-word audit replay. MaxSAT[18,24]/[18,48], CC exact24/
[24,64], actual words24/48. Numeric PASS; B3source46 word INCOMPLETE;
strongest CC lower/exact24 PLAUSIBLE pending independent proof. Three proof+
one supplemental source-word jobs frozen unexecuted. No presumed
XZ metric map or new disjoint family claim. NOTICE/REFERENCE_GHP.md/GH192.


## GH-196 lower-only source target

GB_688_30_unknown reconstructs Mostad-Rosnes-Lin2025 TableII published
lower19-only reference; GB_180_26_unknown is one exact7 correctness anchor.
No exact/global-open inference and no added480 case for quantity. Original
math reconstruction/independent actual columns/set-gcd/full logicals/GF2/
cyclic-XZ maps/typed physical space/actual words PASS;18new+34prior units,
8matrix byte reproduction and34pinned peer inventories(no same(n,k)peer).
Actual ranks77/329each half,k26/30; initial verified uppers10/104. Source
lower19 remains attributed, not our independent proof. Linux40939698187 passes52units/full construction/inventory/8matrix byte
reproduction and actual-word replay. Anchor7 cross-checked both engines;
GB688 rawMaxSAT[9,112]/CC[15,104], actualupper104, numericPASS. Source lower19
not independently re-certified; own15 is weaker and PLAUSIBLE, no new lower
claim. One defaultMaxSAT proof job+one separate optionalCC completion job
frozen unexecuted; no source-upper-word job (NOT_APPLICABLE). Existing GB family, not an
extra completed family label; source/semantic holds elsewhere remain open.


## GH-197 independent three-cycle finite prescription

Self-dual Galimova2603.17703v1 Eq5/Table1 sourceL3/L4 exact5/8 anchors and
four frozen original L5/7/9/11 instances n250/686/1458/2662. Actual k14/20/
26/38/50/62, both-half ranks20/54/112/324/704/1300; no extrapolated dimension
or source distance/growth claim. Proposed ITB provenance prefix, not a new
disjoint-family count. Row/independent-column/separate Kronecker-transpose/
full logical/GF2/physical cyclic-XZ/typed space/actual upper checks PASS;
18new+34prior units/24matrix byte reproduction,35pinned refs no same(n,k)peer.
Initial actual uppers5/8/17/14/65/121. Linux40942338412 passes52units/full
independent construction/inventory/24matrix byte reproduction and actual-
word audit replay. Both engines exact5/8/10 for54/128/250;686rawMaxSAT[9,14]/
CCexact14,1458[9,18]/CCexact18,2662[9,22]/CC[18,22]. Actualuppers5/8/10/14/
18/22, all numericPASS. CC-only14/18 and largestlower18 PLAUSIBLE;3default
MaxSAT proof/progress+1separateoptionalCCcompletion jobs frozen unexecuted.
No universal d=2L/growing-distance theorem or stem rename. Source exact labels not
heuristic; source prose transpose expansion caveat recorded, Eq5 followed
and actual product independently verified. Original unknown exact status
and poor/easy frozen outcomes retained. Remaining non-Cayley Schreier/MB/
longer-chain explicit prescriptions and prior scientific holds remain open.


## Longer-chain finite prescriptions requiring explicit coverage

New primary-source review during GH197 identifies TT length3/Koszul,
abelian multi-cycle and MM longer-chain finite prescriptions. Ordinary
2block GB/BB/ITB and2factorHGP labels do not establish those examples; their
homological overlap is not a new-disjoint-family claim. Jacob et al.
2508.08191v3(2Oct2026,CC BY4) Table5 has explicit overall upper-only targets
588k9<=14,648k6<=16/648k12<=14,735k18<=14,840k9<=16,1029k18<=16,
plus exact-known72k6d6 control. These are useful next structure+unknown-
distance candidates; full primaryPDF/rowspace/provenance review pending.
Lin et al.2506.16910v3(16Mar2026) AMC and Mian et al.2601.18879v2(24May2026)
MM remain source-review backlog; MM table-specific randomized-versus-MIP
proof status must be resolved before treating source labels as ground truth.
No new issue/input/benchmark selected for these longer-chain prescriptions
here. Details/math/source labels in GH-197/NEXT_LONG_CHAIN_REVIEW.md.


## GH-198 explicit trivariate tricycle upper-only targets

Six source cases, exact72k6d6 anchor plus upper-only588k9<=14/648k12<=14/
735k18<=14/840k9<=16/1029k18<=16, now have original reproducible length-3
Hx/Hz/Gx/Gz matrices on this work branch. Source first-column convention,
independent inverse columns AND separate tensor/block-transpose, full actual
ranks/logicals/pairing/metacheck redundancy/physical maps/typed spaces/actual
words PASS;18new+34prior units/24matrix byte reproduction/36pinned refs no
same(n,k)peer. Source half/global endpoints and absentXvalues separate.
Initial actual overall uppers8/70/18/20/128/24, not published targets or minima.
Linux numeric/global source-word gates PASS (run40946335182/job123702566399).
Two engines+GF2 confirm global6/14/14/14; larger840/1029CC16 remain
PLAUSIBLE with independent MaxSAT lower10. Full raw retained;2unexecuted
MaxSAT proof jobs; source-half uppers kept separate. No presumed XZ map or imported
single-shot/gate/layout/asymptotic guarantee; no disjoint-family count.
AMC/MM/Schreier/MB explicit-prescription and prior proof/numeric/equivalence
holds remain visible. Source2508.08191v3 Eq5-14/TableV, CC BY4.0 attributed.


## GH-199 collapsed 4D cyclic AMC finite prescriptions

AMC108k6 published exact9 control and four source-estimated216/330/438/522k6
inputs fixed before generation. These fill explicit collapsed4D length-4
prescriptions; not a disjoint-family increment over TOR4D/QHP/MM. Full GF2/
complete logicals/literal source R2,R3T/metachecks/actual cyclic and XZ maps
PASS;24new+34prior units,30tiny random/mutants,20matrix byte reproduction,
37pinned refs no same(n,k)peer. Initial basis-word X/Z upper18/9,12/25,
30/15,49/51,29/30 before search. Linux40949847060/job123714741574
passes58units/20matrix bytes/all numeric and actual-word gates; both complete
engines+GF2 confirm exact9/12/14/17/20. Full raw retained/audit replay;
zero unresolved heavy jobs. Source estimate labels retained; no novelty claim.
Longer/asymmetric MM, Schreier, certified expander hypotheses and earlier
scientific/integration holds remain open. No source single-shot/threshold/
confinement or asymptotic guarantee imported.


## GH-200 coupled MM source-dimension hold

Five preregistered144/324/432/648/972candidate inputs remain quarantined,
not accepted library additions. Source2601.18879v2 TableIII648k18 with
dims3/9/2/2 reconstructs to ranks318/318,k12. Separate numeric-support/
literal sourceblock/dense rank/scalar parity implementation agrees entrywise
with the subset constructor; unchanged complete logical bases have12rows.
LatestPDF/HTML/abstract checked; no silent source edit, k12rename, transfer
of source distance23 or post-result replacement. Normal generator refuses
the mismatch before writes. No distance runs; duplicate/Linux/source-word
gates incomplete.10hold units/30tiny random cases/four648byte reproduction
PASS only as evidence of hold. Entire20file batch in untiered/quarantine/GH-200;
prior300matrices and24row manifest unchanged. PI source interpretation
required before this batch proceeds. Coupled MM remains a coverage gap.


## GH-201 pinned cross-branch input inventory

[Machine-reproducible branch index](https://github.com/guluchen/DistQLDPC/blob/bbb684ead66fc64ac1ed137780ca3581945b68f5/docs/library/INDEX.md) groups shared manifests
without changing any matrix or source-dependent scientific gate.39pinned refs
(main+38matrix-library branches) contain1068manifest memberships but only
192distinct stored stems/192four-file versions;876memberships repeat across
branches.198distinct manifest metadata records are retained rather than
choosing a favorable result. Main itself remains51tiered+24untiered. Five
GH200quarantine candidates are excluded; no k12repair or source-adoption waiver.
Same(n,k)review groups include authoritative main tiers and untiered stems;
file inequality is not physical inequivalence.33retained canonical queue
versions and17other historical job-file versions are linked, not totalled
as new required workload. Matrix/manifest/scientific proof and completion
claims are not re-certified by this metadata-only inventory.


## GH-202 independent-source Schreier Tanner finite prescriptions

Published180/500/686controls and originalp11/19/29extensions n1100/1900/2900
are fixed before generation. Full inverse-arc/four-corner/local-code tensor
rowspace/shared-strip/actualGF2/complete logical/connected stabilizer checks
PASS. Original actualk66/98/138, no source distance inherited.16new+34prior
units/30tiny random cases/mutants/24matrix byte reproduction/39pinned refs
PASS. SolepeerGB180k26 exact7 versus actualTNword6 proves physical
inequivalence; TN lower6/source6/6/14 reproduction and Linux gates pending.
No disjoint family count or automatic asymptotically-good claim. GH200source
hold remains untouched; full remaining construction/integration/proof backlog
is not waived by this new independent source.


GH-202 terminal SOURCE_DISTANCE_REPRODUCTION_HOLD: Linux40957668835/
job123741864532 passed50units/geometry/24bytes, reproduced180distance6 in
one MaxSAT run, then source500reported8 against published6 and stopped.
Actual word8 GF2verified; one-engine8 remains PLAUSIBLE, no paper-erratum
claim or resolved local label mapping. CC and later four cases unrun. All24
files quarantined, main24row manifest restored,0accepted additions. Normal
generation refuses;18hold units/retained-failure replay validate only hold
evidence and guards. No reorder/reselection/renaming/rerun/server package.
PI source interpretation/diagnostic authorization needed; this finite
Schreier ladder remains an incomplete coverage item. GH200still separately held.


GH205 terminal construction/numeric gates PASS on its separate work branch.
Six fixed LP inputs are retained, not a family-count increment. Both engines
confirm8/11/11 atN420/840/1260 with actual GF2 minimum words. Three retained
CC14 results and original MaxSAT[9,14] remain distinct from source-construction
bounds; published900exact14 is a control, new1800/2700 search exact14 PLAUSIBLE.
Three guarded MaxSAT jobs remain unexecuted.54local contracts after one tiny
alias hardening leave every frozen matrix/construction receipt byte-identical;
follow-up CI replays original logs without renewed scientific search. GH200/
GH202 remain held. Mainstream BCH remains uncovered; preliminary nonprimitive
source-root review is not a globally-open assertion or accepted input.


GH207 independent BCH family reconstruction is LOCAL_CONSTRUCTION_PASS;
Linux short gates pending. Five frozen nonprimitive binary Euclidean CSS
inputs include one exact5 control and four theorem-lower-only targets. Full
physical root syndrome and reciprocal-polynomial constructions agree, logical
quotients/pairings and source hypotheses pass. This fills a missing CSS
construction prescription without claiming LDPC density or globally-open
problems. No source word at the lower endpoint is required. GH200/GH202
remain held; prior unfinished/server/integration/stronger family gaps remain.


GH207 terminal update supersedes the earlier pending construction checkpoint:
exact5/9/11 now have independent finite physical-root lower certificates plus
actual nontrivial GF2 upper words. Two genuine gaps17..22/19..24 remain, with
default MaxSAT numeric gate incomplete. Original search fields are immutable.
Source claims remain distinct, no globally novel/open assertion, no main move.
GH202 latest PI-authorized single CC500 also exact8 with same verified word
and same compiled binary as MaxSAT. Reconstructed input8 is cross-checked;
source6 remains unreproduced, intended local labeling unresolved, no erratum
or blanket solver-exoneration inference. All24 source inputs remain quarantined.
Authoritative archive4ed02242f04d4cf9ae0e2f1966f795d209e5a83c and issue202.


GH208 next missing mainstream QR CSS construction is locally reconstructed
with finite physical lower certificates and an independently exact tiny Golay
control. Linux native results pending. Future Reed–Muller/Shor/concatenated
controls, practical stronger good-code specializations, all existing server
packages/source holds and main integration remain open; no goal completion.


GH208 terminal native update: source00f51d54,run40993376260SUCCESS. Known
Golay7 independently reproduced; four large cases remain intended unknown
targets with finite certificates and actual-word intervals23..71/31..135/
35..191/47..427. Only MaxSAT2039numeric is a required unfinished gate;7long
search jobs are optional research. Source fields never fill native bounds.
Final54static Linux replay PASS40995422015; no native reruns/main changes.


GH209 adds the missing polynomial-minor2x3 cyclic CSS prescription with two
known controls and four original unconfirmed-distance finite lifts. All13
paper examples are exact labels; none is misrepresented as published open.
Local and Linux static gates pass. Existing source holds, numeric/server
queues, practical stronger family gaps and main integration remain open.


GH209 terminal selected native run41009341781SUCCESS retains original12
results and all actual words. New targets765/1275/1785/2805 keep upper54,
CC8PLAU; no independently certified8..54 claim.27control exact4 reproduced;
255source12proof and two missing default numeric gates give4required jobs.
Six optional unknown-distance searches do not force exact target completion.
Final62Linux static replay PASS41012928616/job123922652325; no native retries or main integration.
