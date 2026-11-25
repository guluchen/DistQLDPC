(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance NativeHalfExists PreparedNoLogical.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.

(* The external specification uses the two commuting PCMs alone. Its
   finite/infinite decision does not require supplied logical rows. *)
Theorem raw_half_has_finite_distance m r n (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)):
 S*m H^T=0 ->
 (distance_index H (detectors S)<=n)%N=(\rank S+\rank H<n)%N.
Proof.
 move=>commutes;pose A:=kermx H^T.
 have below:(S<=A)%MS by rewrite /A sub_kermx commutes eqxx.
 have rank_ok:(\rank S<\rank A)%N=(\rank S+\rank H<n)%N
   by rewrite /A mxrank_ker mxrank_tr -(ltn_add2r (\rank H)) (subnK (rank_leq_col H)).
 rewrite -rank_ok -(@nested_rank n r n S A below).
 apply/idP/idP.
 - move/distance_index_attained=>[x [logical_x weight]].
   move:logical_x;rewrite /logical detector_rowspan=>/andP[closed outside].
   apply/negP=>contained;move/negP:outside;apply.
   apply:(submx_trans _ contained);rewrite /A sub_kermx -trmx_eq0 trmx_mul !trmxK;exact closed.
 - move/row_subPn=>[i outside];pose x:=(row i A)^T.
   have closed:H*m x=0.
   { apply/eqP;move:(row_sub i A);rewrite {2}/A sub_kermx -trmx_eq0 trmx_mul !trmxK;by []. }
   have found:logical H (detectors S) x by rewrite /logical closed eqxx detector_rowspan /x trmxK.
   apply:leq_trans (distance_index_lower found) _.
   by move:(max_card (support x));rewrite card_ord.
Qed.

Theorem raw_pcm_distance_spec mx mz n (X:'M['F_2]_(mx,n)) (Z:'M['F_2]_(mz,n)):
 X*m Z^T=0 ->
 (extended_css_distance X Z=None <-> (n-(\rank X+\rank Z)=0)%N) /\
 (forall d,extended_css_distance X Z=Some d ->
  exists x z,mixed X Z x z /\ pauli_weight x z=d /\
     forall a b,mixed X Z a b -> (d<=pauli_weight a b)%N).
Proof.
 move=>orth;have transposed:Z*m X^T=0 by apply/eqP;rewrite -trmx_eq0 trmx_mul trmxK orth eqxx.
 split;last exact:(@finite_result_is_minimum mx mz n X Z).
 have finite:(css_index X Z<=n)%N=(\rank X+\rank Z<n)%N.
 { have fx:=@raw_half_has_finite_distance mz mx n Z X orth.
   have fz:=@raw_half_has_finite_distance mx mz n X Z transposed.
   have order:(\rank Z+\rank X<n)%N=(\rank X+\rank Z<n)%N by rewrite addnC.
   have same:=etrans fz order.
   exact:(etrans (geq_min n (distance_index Z (detectors X)) (distance_index X (detectors Z)))
            (etrans (congr2 orb fx same) (orbb _))). }
 rewrite /extended_css_distance finite;case present:((\rank X+\rank Z<n)%N).
 - split;[discriminate|move/eqP;by rewrite subn_eq0 leqNgt present].
 - split=>_;[apply/eqP;by rewrite subn_eq0 leqNgt present|reflexivity].
Qed.
