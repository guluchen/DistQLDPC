(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifClosesBody VerifToggleBody VerifFlipBody SparseSyndrome SparseRollback
  RedundantState ToggleModel.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Delimit Scope Z_scope with coqZ.

Definition one_flip policy q (rs:seq Integers.int) st :=
 let primary:=fold_left sparse_flip rs st in (after_extra policy q primary.1,primary.2).
Lemma combined_words policy q rs syn odd :
 (one_flip policy q rs (syn,odd)).1 =
 fold_left extra_step (rs ++ extra_rows policy q) syn.
Proof.
rewrite /one_flip fold_left_app policy_words -(extra_words_independent rs syn odd);reflexivity.
Qed.
Lemma twice_words policy q rs syn odd :
 Forall (fun r=>(Int.unsigned r<64*Zlength syn)%coqZ) (rs++extra_rows policy q) ->
 (one_flip policy q rs (one_flip policy q rs (syn,odd))).1=syn.
Proof.
move=> fits;set t:=one_flip policy q rs (syn,odd).
rewrite (surjective_pairing t) combined_words /t combined_words.
set all:=rs++extra_rows policy q in fits *.
rewrite (extra_words_independent all syn odd).
case step:(fold_left sparse_flip all (syn,odd))=>[mid cnt] /=.
rewrite (extra_words_independent all mid cnt).
have back:=@sparse_words_restore all syn odd fits;by rewrite step in back.
Qed.
Section Physical.
Variable m:nat.
Definition encode (r:'I_m):=Int.repr (Z.of_nat r).
Variables (rs:seq 'I_m) (policy:row_policy) (q:Z).
Let physical:=map encode rs.
Hypothesis distinct:uniq rs.
Hypothesis dim:(Z.of_nat m<=Int.modulus)%coqZ.
Hypothesis high:Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows policy q).
Lemma flips_rep st (A:{set 'I_m}) :
 stores_odd st A ->
 Forall (fun r=>(Int.unsigned r<64*Zlength st.1)%coqZ) (extra_rows policy q) ->
 stores_odd (one_flip policy q physical st) (foldl (fun B r=>flip_row r B) A rs).
Proof.
move=> prior extra.
have next:=@trace_correct m rs st A dim prior.
rewrite /one_flip;set t:=fold_left sparse_flip physical st.
change (stores_odd (after_extra policy q t.1,t.2) (foldl (fun B r=>flip_row r B) A rs)).
apply:(@extra_preserves_physical m _ policy q t.1 t.2).
- by rewrite -(surjective_pairing t);exact:next.
- exact:high.
- by rewrite /t walk_length.
Qed.
Theorem native_flip_rolls_back syn odd (A:{set 'I_m}) :
 stores_odd (syn,odd) A ->
 Forall (fun r=>(Int.unsigned r<64*Zlength syn)%coqZ) (physical++extra_rows policy q) ->
 one_flip policy q physical (one_flip policy q physical (syn,odd))=(syn,odd).
Proof.
move=> prior limits.
have words:=twice_words odd limits.
have extra:=proj2 (proj1 (Forall_app _ _ _) limits).
have first:=@flips_rep (syn,odd) A prior extra.
have cap:Zlength (one_flip policy q physical (syn,odd)).1=Zlength syn.
  by rewrite combined_words (extra_words_independent _ _ odd) walk_length.
have valid:Forall (fun r=>(Int.unsigned r<64*Zlength (one_flip policy q physical (syn,odd)).1)%coqZ)
                  (extra_rows policy q) by rewrite cap.
have second:=flips_rep first valid.
set B:=foldl (fun T r=>flip_row r T) A rs.
have same:foldl (fun T r=>flip_row r T) B rs=A.
  apply/setP=>j;rewrite (@flip_unique m rs B j distinct) /B (@flip_unique m rs A j distinct).
  by case:(j \in rs);case:(j \in A).
change (stores_odd (one_flip policy q physical (one_flip policy q physical (syn,odd)))
        (foldl (fun T r=>flip_row r T) B rs)) in second.
rewrite same in second.
have c1:=proj2 (proj2 prior);have c2:=proj2 (proj2 second).
set final:=one_flip policy q physical (one_flip policy q physical (syn,odd)) in words c2 *.
by rewrite (surjective_pairing final) words c2 -c1.
Qed.
End Physical.
