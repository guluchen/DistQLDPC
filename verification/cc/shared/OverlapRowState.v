(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver SiblingCounters.
From Coq Require Import List Lia.
Import ListNotations.
Local Open Scope Z_scope.

Definition effective (skip:int) (xs:list int) :=
 map Int.unsigned (filter (fun q=>negb (Int.eq q skip)) xs).
Definition block_step (skip:int) (st:list int * Z) (q:int) :=
 if Int.eq q skip then st else
 (adjust 1 (fst st) (Int.unsigned q),
  snd st + if Int.eq (Znth (Int.unsigned q) (fst st)) Int.zero then 1 else 0).
Definition unblock_step (skip:int) (xs:list int) (q:int) :=
 if Int.eq q skip then xs else adjust (-1) xs (Int.unsigned q).
Definition row_state skip qs base lo j :=
 fold_left (block_step skip) (sublist lo j qs) (base,0).
Definition row_return skip qs base lo j :=
 fold_left (unblock_step skip) (sublist lo j qs) base.
Lemma state_step skip qs counts lo i:0<=lo<=i -> i<Zlength qs ->
 row_state skip qs counts lo (i+1)=block_step skip (row_state skip qs counts lo i) (Znth i qs).
Proof. intros;unfold row_state;rewrite (sublist_split lo i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity. Qed.
Lemma return_step skip qs counts lo i:0<=lo<=i -> i<Zlength qs ->
 row_return skip qs counts lo (i+1)=unblock_step skip (row_return skip qs counts lo i) (Znth i qs).
Proof. intros;unfold row_return;rewrite (sublist_split lo i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity. Qed.
Lemma block_sweep skip xs base k :
 fst (fold_left (block_step skip) xs (base,k))=sweep 1 (effective skip xs) base.
Proof.
 revert base k;induction xs as [|a xs IH];intros base k;[reflexivity|].
 change (fst (fold_left (block_step skip) xs (block_step skip (base,k) a))=sweep 1 (effective skip (a::xs)) base).
 unfold block_step at 2;unfold effective at 1;cbn [filter];destruct (Int.eq a skip);
   cbn [fst snd negb map sweep fold_left];apply IH.
Qed.
Lemma unblock_sweep skip xs base :
 fold_left (unblock_step skip) xs base=sweep (-1) (effective skip xs) base.
Proof.
 revert base;induction xs as [|a xs IH];intros base;[reflexivity|].
 change (fold_left (unblock_step skip) xs (unblock_step skip base a)=sweep (-1) (effective skip (a::xs)) base).
 unfold unblock_step at 2;unfold effective at 1;cbn [filter];destruct (Int.eq a skip);
   cbn [negb map sweep fold_left];apply IH.
Qed.
Lemma effective_range skip xs n :
 Forall (fun q=>Int.unsigned q<n) xs -> in_array n (effective skip xs).
Proof.
 intro valid;apply Forall_forall;intros q member;unfold effective in member.
 apply in_map_iff in member;destruct member as [a [<- included]];apply filter_In in included as [inside _].
 apply Forall_forall with (x:=a) in valid;[pose proof (Int.unsigned_range a);lia|assumption].
Qed.
Lemma effective_length skip xs base :
 Forall (fun q=>Int.unsigned q<Zlength base) xs ->
 Zlength (fst (fold_left (block_step skip) xs (base,0)))=Zlength base /\
 Zlength (fold_left (unblock_step skip) xs base)=Zlength base.
Proof. intro valid;rewrite block_sweep,unblock_sweep;split;apply sweep_size;apply effective_range;assumption. Qed.
Lemma count_fits skip qs base k :
 k<=snd (fold_left (block_step skip) qs (base,k))<=k+Zlength qs.
Proof.
 revert base k;induction qs as [|a qs IH];intros base k;[cbn;lia|].
 rewrite Zlength_cons;cbn [fold_left].
 remember (block_step skip (base,k) a) as next eqn:S;destruct next as [bs z].
 assert (delta:k<=z<=k+1).
 { unfold block_step in S;destruct (Int.eq a skip);[inversion S;lia|].
   cbn [snd fst] in S;destruct (Int.eq (Znth (Int.unsigned a) base) Int.zero);inversion S;lia. }
 specialize (IH bs z);lia.
Qed.
Theorem inverse_row skip qs counts :
 Forall (fun q=>Int.unsigned q<Zlength counts) qs ->
 fold_left (unblock_step skip) qs (fst (fold_left (block_step skip) qs (counts,0)))=counts.
Proof. intro valid;rewrite unblock_sweep,block_sweep;apply rollback_siblings;apply effective_range;exact valid. Qed.
