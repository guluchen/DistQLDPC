(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import SparseSyndrome FlipRoundtrip RedundantState VerifClosesBody VerifToggleBody VerifFlipBody
 NativeFlipPayload NativeRootFlip PhysicalColumnBounds PreparedPhysicalPCM.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Delimit Scope Z_scope with coqZ.

Lemma preserved_word_count p keys q x :
 Zlength (syndrome (words_at (step_support p keys q x)))=Zlength (syndrome (words_at x)).
Proof.
case:x=>v odd key;case:p=>[|ptr|ptr starts data os rs];cbn [step_support words_at odd_count syndrome set_words after_extra];
 try rewrite extra_length;apply flip_length.
Qed.

Section PCM.
Variables (m:nat) (inc:Z->seq 'I_m) (usable:Z->Prop) (p:row_policy) (keys:list int64).
Hypothesis signed_dim:(Z.of_nat m<Int.max_signed)%coqZ.
Hypothesis nonnegative:forall q,usable q -> (0<=q)%coqZ.
Hypothesis distinct:forall q,usable q -> uniq (inc q).
Hypothesis redundant_high:forall q,usable q -> Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows p q).

Definition pcm_columns x := forall q, usable q ->
 let v:=words_at x in static_column p keys q v /\ column_list v q=map (@encode m) (inc q) /\
 Forall (fun r=>(Int.unsigned r<64*Zlength (syndrome v))%coqZ) (column_list v q++extra_rows p q).
Definition pcm_state x := pcm_columns x /\ exists A:{set 'I_m},stores_odd (syndrome (words_at x),odd_count x) A.

Lemma pcm_columns_step x q: pcm_columns x -> usable q -> pcm_columns (step_support p keys q x).
Proof.
move=> all allowed k allowed_k.
have [current _]:=all q allowed.
have [other [encoding limits]]:=all k allowed_k.
have [a [b [c [d [e [width_ok [room extra]]]]]]]:=current.
have len:=preserved_word_count p keys q x.
have wd:width (words_at (step_support p keys q x))=width (words_at x).
{ change (Zlength (differences (words_at x) q)=width (words_at x));apply detector_word_count;try lia;exact:(nonnegative allowed). }
split;last (split;[exact encoding|by rewrite len]).
rewrite /static_column wd len;exact other.
Qed.

Lemma pcm_state_step x q: pcm_state x -> usable q -> pcm_state (step_support p keys q x).
Proof.
move=> [all [A stored]] allowed;split;first exact:(pcm_columns_step all allowed).
have [_ [encoding limits]]:=all q allowed.
have extras:=proj2 (proj1 (Forall_app _ _ _) limits).
have dim:(Z.of_nat m<=Int.modulus)%coqZ by move:signed_dim;change Int.max_signed with 2147483647%coqZ;change Int.modulus with 4294967296%coqZ;lia.
exists (foldl (fun B r=>flip_row r B) A (inc q)).
change (@stores_odd m (one_flip p q (column_list (words_at x) q) (syndrome (words_at x),odd_count x)) (foldl (fun B r=>flip_row r B) A (inc q))).
rewrite encoding;apply flips_rep;auto.
Qed.

Lemma pcm_state_pair x q: pcm_state x -> usable q -> pair_safe p keys q x.
Proof.
case:x=>v odd key;pose x:=Build_packed_support v odd key;move=> state allowed.
have [all [A stored]]:=state;have [column [encoding limits]]:=all q allowed.
have [after [B count]]:=pcm_state_step state allowed.
have [next [enc_next _]]:=after q allowed.
have before:=@signed_and_addressed_from_pcm m (inc q) A p keys q (words_at x) (odd_count x) (checksum x) signed_dim encoding stored column.
have late:=@signed_and_addressed_from_pcm m (inc q) B p keys q _ _ (checksum (step_support p keys q x)) signed_dim enc_next count next.
apply:(@physical_payload_pair m (inc q) A p keys q x);try assumption;try exact:(nonnegative allowed);try exact:(distinct allowed);try exact:(redundant_high allowed).
move:signed_dim;change Int.max_signed with 2147483647%coqZ;change Int.modulus with 4294967296%coqZ;lia.
Qed.

Theorem pcm_prefix pairs x: Forall (fun word=>usable (Int.signed word)) pairs -> pcm_state x ->
 pcm_state (fold_left (fun prior word=>step_support p keys (Int.signed word) prior) pairs x).
Proof. move=> ok;elim:ok x=>[|head tail good rest IH] x state //=;apply:IH;exact:(pcm_state_step state good). Qed.
End PCM.
