(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch DetectorMatrix PackedDetector CSSLevelDistance DetectorRank
 PCMLeafAPI LeafAPI VerifClosesBody VerifOneLeft VerifFlipBody NativeFlipPayload PreparedMatrixResponse
 PreparedDepthSpec PreparedChildCall PreparedRecursiveCall PreparedMatrixPath PreparedWitnessWeight
 PreparedLeafAtPath PreparedChildPrefix PreparedPairTrace PreparedPairEvent PreparedLeafVisit.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Traces.
Variables m n k r:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)).
Definition stored_css_prefix (len:Z) (cells:seq Integers.int):Prop:=
 let x:=indicator (@prefix_set n (active_prefix len cells)) in
 [ /\ (0<len<=Zlength cells)%coqZ,H*m x=0,~~(x^T<=S)%MS &
     Z.of_nat #|support x|=len /\ (distance_index H (detectors S)<=#|support x|)%N ].

Theorem observed_witness_has_valid_length (ids:seq 'I_n) (F:{set 'I_n}) rowkey t depth q cur code tail:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N ->
 (Z.of_nat n<=Int.max_signed)%coqZ -> uniq ids ->
 (1<=depth)%coqZ -> (depth+1<Zlength cur)%coqZ -> (depth+1)%coqZ=Z.of_nat (size ids) ->
 append_qubit cur depth q=literal_path ids ->
 let P:=[set b:'I_n | b \in ids] in pcm_response H G rowkey (indicator P) t ->
 pair_observation t (pcm_completion H G P F) (Z.of_nat n) depth q cur code tail ->
 witness_status code -> stored_css_prefix (if Z.eq_dec code 3 then depth+1 else depth+2)%coqZ tail.
Proof.
 move=> orth det rank_ok nfit unique fits enough dim trace P physical [event [branch [-> ->]]] found.
 set next:=upd_Znth depth cur (Int.repr q).
 have room:Zlength next=Zlength cur by rewrite /next upd_Znth_Zlength;lia.
 have stored:active_prefix (depth+1)%coqZ next=literal_path ids by rewrite /next stored_prefix;[exact trace|lia].
 destruct event as [z|].
 - have [_ result]:=branch.
   have outcome:=@lookup_trace_and_distance m r k n H S G F ids next z orth det rank_ok unique
       ltac:(rewrite -dim;lia) ltac:(rewrite -dim;exact stored) result.
   change (witness_status (final_pick z)) in found.
   have pos:(0<=z)%coqZ by unfold witness_status,final_pick in found;destruct (Z_lt_dec z 0);lia.
   have pick:final_pick z = 1%coqZ by rewrite /final_pick;case:(Z_lt_dec z 0);lia.
   destruct outcome as [[miss _]|[a [same registers closed outside [weight upper]]]];first lia.
   cbn [pair_code pair_path];rewrite pick;change (stored_css_prefix (depth+2)%coqZ (last_path (depth+1)%coqZ z next)).
   have depth_ok:(depth+2=Z.of_nat (size ids)+1)%coqZ by lia.
   have at_len:active_prefix (depth+2)%coqZ (last_path (depth+1)%coqZ z next)=literal_path (rcons ids a).
   { replace (depth+2)%coqZ with (Z.of_nat (size ids)+1)%coqZ by lia;rewrite dim;exact registers. }
   rewrite /stored_css_prefix at_len literal_prefix_set //.
   have shape:[set b:'I_n | b \in rcons ids a]=a |: P by apply/setP=>b;rewrite /P !inE mem_rcons inE.
   rewrite shape weight;split=> //.
   + unfold last_path;case:(Z_lt_dec z 0)=>[bad|_];first lia.
     rewrite upd_Znth_Zlength;lia.
   + split=> //;lia.
 - have [odd [packed hash]]:=physical.
   have seen:packed_detects (parities (words_at t))=true.
   { change (witness_status (if packed_detects (parities (words_at t)) then 3 else 0)%coqZ) in found.
     destruct (packed_detects (parities (words_at t)));[reflexivity|unfold witness_status in found;lia]. }
   have counted:Z.of_nat #|support (H*m indicator P)|=0%coqZ by rewrite -(proj2 (proj2 odd));exact branch.
   have closed:H*m indicator P=0 by apply/eqP;rewrite -(@zero_syndrome m n H (indicator P)) /number_odd counted.
   have logical:MinimumPrefix.logical H G (indicator P) by rewrite /MinimumPrefix.logical closed eqxx -(packed_matrix_nonzero packed) seen.
   have yes:=@witnessed_half_distance_bound m r k n H S G ids orth det rank_ok unique.
   rewrite (path_is_its_indicator unique) in yes;have [_ outside weight upper]:=yes logical.
   cbn [pair_code pair_path];rewrite seen;change (stored_css_prefix (depth+1)%coqZ next).
   rewrite /stored_css_prefix stored literal_prefix_set // weight;split=> //;try lia.
Qed.
End Traces.
