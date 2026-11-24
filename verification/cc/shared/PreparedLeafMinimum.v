(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch LeafShortcut DetectorMatrix SyndromeHash LeafAPI PCMLeafAPI
 VerifClosesBody VerifFlipBody NativeFlipPayload PreparedMatrixResponse VerifOneLeft PreparedPairEvent.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Completion.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (rowkey:'I_m->int64)
 (P F:{set 'I_n}) (x:'cV['F_2]_n) (t:packed_support).
Let w:=(#|P|).+1.

(* After the sibling's first flip a minimum target has exactly one
   missing qubit. The same argument covers a table miss and a zero
   syndrome in the compiled early-closure branch. *)
Theorem one_missing_qubit_prevents_empty (event:option Z) (seen:bool):
 minimum H G x -> #|support x|=w -> P!=set0 -> P \subset support x ->
 support x :\: P \subset F -> pcm_response H G rowkey (indicator P) t ->
 (match event with Some z=>odd_count t<>0%coqZ /\ leaf_answer (pcm_completion H G P F) (Z.of_nat n) z
  | None=>odd_count t=0%coqZ end) -> pair_code seen event<>0%coqZ.
Proof.
 move=> best weight positive inside free physical.
 have nonempty:descend H G 1 w P F by apply:(@descend_complete m n k H G 1 w P F x)=> //;rewrite addn1.
 rewrite -(unrolled_equals_search H G 1 w P F) /= in nonempty.
 case chose:(oddrow H P)=>[r|] in nonempty;last by [].
 have active:(H*m indicator P) r 0!=0.
 { by move:chose;rewrite /oddrow;case:pickP=> // a nonzero [eq];subst. }
 have [q entry hit]:=elimT hasP nonempty.
 have permitted:q \in F by move:entry;rewrite mem_enum.
 have real:pcm_completion H G P F (Z.of_nat q) by exists q;auto.
 have ord:=elimT ltP (ltn_ord q).
 destruct event as [z|].
 - move=> [_ [[miss impossible]|[range ok]]].
   + exfalso;exact:(impossible (Z.of_nat q) ltac:(lia) real).
   + rewrite /pair_code /final_pick;case: (Z_lt_dec z 0)=>[bad|pos];lia.
 - move=> closed;exfalso.
   have [rows _]:=physical;have zero:Z.of_nat #|support (H*m indicator P)|=0%coqZ by rewrite -(proj2 (proj2 rows)).
   have E:H*m indicator P=0 by apply/eqP;rewrite -(@zero_syndrome m n H (indicator P)) /number_odd zero.
   by move:active;rewrite E mxE eqxx.
Qed.
End Completion.
