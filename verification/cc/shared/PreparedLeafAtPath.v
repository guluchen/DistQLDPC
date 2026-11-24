(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance VerifClosesBody VerifFlipBody NativeFlipPayload
 NativeDepthFlip RedundantState FlipRoundtrip PhysicalPrefixInvariant PreparedMatrixResponse
 SyndromeHash PreparedMatrixPath PreparedWitnessWeight ClosureMatrix.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Lemma path_is_its_indicator n (ids:seq 'I_n):uniq ids ->
 vector_on (0:'cV['F_2]_n) ids=indicator [set q:'I_n | q \in ids].
Proof.
 move=> unique;apply:binary_support_inj;rewrite support_indicator;apply/setP=>a.
 rewrite distinct_path_changes_members // support_zero !inE;by case:(a \in ids).
Qed.

(* These are exactly the dimensions read by close_safe, including the
   physical CSR row IDs used to address the syndrome word array. *)
Definition same_lookup_geometry left right:=
 [ /\ offsets left=offsets right,rows left=rows right,width left=width right,
      masks left=masks right & Zlength (syndrome left)=Zlength (syndrome right) ].

Section Paths.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (rowkey:'I_m->int64)
  (rs:'I_n->seq 'I_m) (policy:row_policy) (keys:seq int64).
Let enc:=@encoded_at m n k G rs policy.
Hypothesis qubits:(Z.of_nat n<=Int.max_signed)%coqZ.

Lemma path_keeps_lookup_inputs (ids:seq 'I_n) initial:
 enc initial -> let t:=payload_after policy keys initial (literal_path ids) in
 enc t /\ same_lookup_geometry (words_at t) (words_at initial).
Proof.
 elim:ids initial=>[|q rest ih] initial encoded.
 - split=> //;by constructor.
 - cbn [literal_path map payload_after fold_left].
   have bounded:=elimT ltP (ltn_ord q).
   rewrite Int.signed_repr;last by change Int.min_signed with (-2147483648)%coqZ;lia.
   pose next:=step_support policy keys (Z.of_nat q) initial.
   have advanced:enc next by exact:(@change_preserves_columns m n k G rs policy keys initial q encoded).
   have [full [off row wid mask length]]:=ih next advanced.
   split;first exact full.
   have [_ [_ [_ [_ cap]]]]:=encoded q.
   have same_w:width (words_at next)=width (words_at initial).
   { apply detector_word_count;try lia;unfold width;apply Zlength_nonneg. }
   constructor;[exact off|exact row|by rewrite wid same_w|exact mask|].
   by rewrite length;apply preserved_word_count.
Qed.

Theorem emitted_path_matches_pcm (ids:seq 'I_n) initial:
 (Z.of_nat m<=Int.modulus)%coqZ -> (forall q,uniq (rs q)) ->
 (forall q,[set r in rs q]=support (col q H)) ->
 (forall q:'I_n,Forall (fun row=>(Z.of_nat m<=Int.unsigned row)%coqZ) (extra_rows policy (Z.of_nat q))) ->
 (forall q:'I_n,Znth (Z.of_nat q) keys=signature rowkey (support (col q H))) ->
 uniq ids -> enc initial -> pcm_response H G rowkey (0:'cV['F_2]_n) initial ->
 let t:=payload_after policy keys initial (literal_path ids) in
 [ /\ enc t,same_lookup_geometry (words_at t) (words_at initial) &
       pcm_response H G rowkey (indicator [set q:'I_n | q \in ids]) t ].
Proof.
 move=> rows unique inc high keyed unique_ids encoded start t.
 have [final geometry]:=path_keeps_lookup_inputs ids encoded.
 have model:=@native_path_matrix_response m n k H G rowkey rs policy keys rows qubits unique inc high keyed
    ids (0:'cV['F_2]_n) initial encoded start.
 rewrite (path_is_its_indicator unique_ids) in model;by split.
Qed.
End Paths.
