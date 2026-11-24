(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SeedColumnModel SeedExemptionState.
Local Open Scope Z_scope.

Record exhausted_state := { exhausted_fallback:list int; live_rows:moving_state }.
Definition remember_row limits base q (st:exhausted_state) (word:int) :=
 let r:=Int.unsigned word in
 if Z_lt_dec (Int.signed (Znth r base)) 0 then st else
 if Z_lt_dec (Int.signed (Znth r (exhausted_fallback st))) 0 then
  Build_exhausted_state (upd_Znth r (exhausted_fallback st) (Int.repr q))
     (replace_exemption limits (live_rows st) r q)
 else st.
Definition remember_column limits base q lo j rows st :=
 fold_left (remember_row limits base q) (sublist lo j rows) st.
Lemma remember_next limits base q lo i rows st :
 0<=lo<=i -> i<Zlength rows ->
 remember_column limits base q lo (i+1) rows st =
 remember_row limits base q (remember_column limits base q lo i rows st) (Znth i rows).
Proof.
 intros;unfold remember_column;rewrite (sublist_split lo i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity.
Qed.

Lemma keep_recorded limits base q st row :
 0<=Int.signed (Znth (Int.unsigned row) (exhausted_fallback st)) ->
 remember_row limits base q st row=st.
Proof.
 intro known;unfold remember_row;destruct (Z_lt_dec (Int.signed (Znth (Int.unsigned row) base)) 0);auto.
 destruct (Z_lt_dec (Int.signed (Znth (Int.unsigned row) (exhausted_fallback st))) 0);[lia|reflexivity].
Qed.
Lemma remember_first limits base q st row :
 let r:=Int.unsigned row in
 0<=Int.signed (Znth r base) -> Int.signed (Znth r (exhausted_fallback st))<0 ->
 0<=r<Zlength (exhausted_fallback st) -> 0<=r<Zlength (exempts (live_rows st)) ->
 let final:=remember_row limits base q st row in
 Znth r (exhausted_fallback final)=Int.repr q /\ Znth r (exempts (live_rows final))=Int.repr q.
Proof.
 intros r enabled absent fr cr;unfold remember_row;fold r.
 destruct (Z_lt_dec (Int.signed (Znth r base)) 0);[lia|].
 destruct (Z_lt_dec (Int.signed (Znth r (exhausted_fallback st))) 0);[|lia].
 cbn [exhausted_fallback live_rows];split;[apply upd_Znth_same|apply row_always_selects_current];assumption.
Qed.
