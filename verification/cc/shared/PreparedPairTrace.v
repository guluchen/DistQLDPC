(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch LeafShortcut PCMLeafAPI LeafAPI
 CSSLevelDistance DetectorRank VerifOneLeft PreparedDepthSpec PreparedChildCall PreparedMatrixPath PreparedWitnessWeight.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Lemma stored_address_after_lookup n depth (path:seq 'I_n) (q:'I_n) cells:
 (0<=depth<Zlength cells)%coqZ ->
 active_prefix depth cells=literal_path path ->
 active_prefix (depth+1)%coqZ (last_path depth (Z.of_nat q) cells)=literal_path (rcons path q).
Proof.
 move=> in_bounds prefix;rewrite /last_path.
 case: (Z_lt_dec (Z.of_nat q) 0)=> [bad|ok];first lia.
 rewrite stored_prefix // /append_qubit prefix /literal_path map_rcons -cats1;by [].
Qed.

Section FinalPick.
Variables m s k n:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(s,n)) (G:'M['F_2]_(k,n)) (F:{set 'I_n}).
Variables (path:seq 'I_n) (cells:seq Integers.int) (z:Z).
Let P:=[set q:'I_n | q \in path].
Let depth:=Z.of_nat (size path).
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (rank_ok:(\rank (col_mx H G)+\rank S=n)%N)
 (unique:uniq path) (disjoint:[disjoint F & P])
 (room:(depth<Zlength cells)%coqZ) (trace_ok:active_prefix depth cells=literal_path path).
Let accepted:=pcm_completion H G P F.
Let tail:=last_path depth z cells.

(* Decode exactly the element written by closing_qubit. A miss rules out
   every free one-qubit completion on this branch. A hit is a concrete
   witness, and the capacity of the C trace may exceed its logical length. *)
Theorem lookup_trace_and_distance:
 leaf_answer accepted (Z.of_nat n) z ->
 (z=(-1)%coqZ /\ forall q:'I_n,q \in F -> ~~terminal H G (size path).+1 (q |: P)) \/
 exists q:'I_n,let T:=q |: P in let x:=indicator T in
 [ /\ z=Z.of_nat q, active_prefix (depth+1)%coqZ tail=literal_path (rcons path q),
      H*m x=0, ~~(x^T<=S)%MS & #|support x|=(size path).+1 /\
          (distance_index H (detectors S)<=(size path).+1)%N ].
Proof.
 have count:#|P|=size path by rewrite /P cardsE (card_uniqP unique).
 case=> [[miss all]|[range [q [same [free logical]]]]].
 - left;split=> // q free;apply/negP=> hit.
   have bounded:=elimT ltP (ltn_ord q).
   apply: (all (Z.of_nat q) ltac:(lia));exists q;split=> //;split=> //;by rewrite count.
 - right;exists q;cbn zeta;have [weight yes]:=andP logical.
   have formatted:active_prefix (depth+1)%coqZ tail=literal_path (rcons path q).
   { rewrite /tail same;apply:stored_address_after_lookup;[split;[unfold depth;lia|exact room]|exact trace_ok]. }
   rewrite (@validated_logical m s k n H S G orth det rank_ok) in yes.
   have /andP[/eqP kernel outside]:=yes;rewrite detector_rowspan in outside.
   have weight_ok:#|support (indicator (q |: P))|=(size path).+1.
   { by rewrite support_indicator (eqP weight) count. }
   split=> //;split=> //;rewrite -weight_ok;exact:(distance_index_lower yes).
Qed.
End FinalPick.
