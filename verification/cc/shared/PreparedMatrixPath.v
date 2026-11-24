(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix DetectorMatrix ClosureMatrix VerifClosesBody VerifToggleBody VerifFlipBody
 FlipRoundtrip RedundantState SyndromeHash NativeFlipPayload NativeDepthFlip PhysicalPrefixInvariant
 PreparedDFSTerminal PreparedMatrixResponse.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Path.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (rowkey:'I_m->int64).
Variables (rs:'I_n->seq 'I_m) (p:row_policy) (keys:list int64).
Hypotheses (row_cap:(Z.of_nat m<=Int.modulus)%coqZ) (qubit_cap:(Z.of_nat n<=Int.max_signed)%coqZ).
Hypothesis distinct:forall q,uniq (rs q).
Hypothesis incidence:forall q,[set r in rs q]=support (col q H).
Hypothesis redundant:forall q:'I_n,Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows p (Z.of_nat q)).
Hypothesis key_column:forall q:'I_n,Znth (Z.of_nat q) keys=signature rowkey (support (col q H)).

Definition encoded_at t:=forall q:'I_n,let j:=Z.of_nat q in let v:=words_at t in
  column_list v j=map (@encode m) (rs q) /\
  Forall (fun r=>(Int.unsigned r<64*Zlength (syndrome v))%coqZ) (extra_rows p j) /\
  represents (col_slice v j) (col q L) /\ size (parities v)=size (col_slice v j) /\
  ((j+1)*width v<=Zlength (masks v))%coqZ.
Lemma change_preserves_columns t (q:'I_n): encoded_at t -> encoded_at (step_support p keys (Z.of_nat q) t).
Proof.
move=> all a;have [_ [_ [_ [_ room]]]]:=all q.
have words:=preserved_word_count p keys (Z.of_nat q) t.
have wd:width (words_at (step_support p keys (Z.of_nat q) t))=width (words_at t).
{ change (Zlength (differences (words_at t) (Z.of_nat q))=width (words_at t));
  apply detector_word_count;try lia;unfold width;apply Zlength_nonneg. }
have sz:size (parities (words_at (step_support p keys (Z.of_nat q) t)))=size (parities (words_at t)).
{ apply Nat2Z.inj;unfold width in wd;rewrite !Zlength_correct in wd;exact wd. }
have [csr [bounds [det [same enough]]]]:=all a.
have mask:col_slice (words_at (step_support p keys (Z.of_nat q) t)) (Z.of_nat a)=col_slice (words_at t) (Z.of_nat a).
{ by rewrite /col_slice wd. }
split;first exact csr. split;first by rewrite words.
rewrite mask sz wd;auto.
Qed.

Definition literal_path (path:seq 'I_n):=map (fun q:'I_n=>Int.repr (Z.of_nat q)) path.
Definition vector_on (x:'cV['F_2]_n) (path:seq 'I_n):=foldl (fun v q=>v+delta_mx q 0) x path.

Theorem native_path_matrix_response path x initial: encoded_at initial -> pcm_response H L rowkey x initial ->
 pcm_response H L rowkey (vector_on x path) (payload_after p keys initial (literal_path path)).
Proof.
elim:path x initial=> [|q more ih] x initial enc physical //=.
change (pcm_response H L rowkey (vector_on (x+delta_mx q 0) more)
 (payload_after p keys (step_support p keys (Int.signed (Int.repr (Z.of_nat q))) initial) (literal_path more))).
have index_ok:=elimT ltP (ltn_ord q).
rewrite Int.signed_repr;last by change Int.min_signed with (-2147483648)%coqZ;lia.
apply:ih;first exact:(@change_preserves_columns initial q enc).
have [csr [bounded [det [width room]]]]:=enc q.
exact:(@native_column_response m n k H L rowkey p keys x q initial (rs q) row_cap (distinct q)
 (incidence q) csr (redundant q) bounded det width (key_column q) physical).
Qed.

Corollary terminal_matrix_test_after_path path x initial:
 encoded_at initial -> pcm_response H L rowkey x initial ->
 let t:=payload_after p keys initial (literal_path path) in let y:=vector_on x path in
 leaf_accept (odd_count t) (parities (words_at t))=((H *m y==0) && (L *m y!=0)).
Proof. move=> enc rep t y;apply:(physical_terminal (native_path_matrix_response path enc rep)). Qed.
End Path.
