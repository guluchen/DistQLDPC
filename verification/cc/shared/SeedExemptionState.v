(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SiblingCounters.
Local Open Scope Z_scope.

Definition reassign_blocks (blocks:list int) (old next:Z):=
 adjust 1 (adjust (-1) blocks next) old.
Definition new_forbidden_count (events:int64) (blocks:list int) (old next:Z) :=
 Int64.add events (if Int.eq (Znth old (adjust (-1) blocks next)) Int.zero
                   then Int64.one else Int64.zero).

(* The initial two-qubit row contributed one block at [next]. The rest
   of the heap may contain arbitrary inherited or other-row blocks. *)
Lemma zero_limit_moves_one_row inherited old next :
 0<=next<Zlength inherited ->
 reassign_blocks (adjust 1 inherited next) old next=adjust 1 inherited old.
Proof. intros within;unfold reassign_blocks;rewrite cancel_child by assumption;reflexivity. Qed.
Lemma zero_limit_counts_free inherited old next events :
 0<=next<Zlength inherited ->
 new_forbidden_count events (adjust 1 inherited next) old next=
 Int64.add events (if Int.eq (Znth old inherited) Int.zero then Int64.one else Int64.zero).
Proof. intros within;unfold new_forbidden_count;rewrite cancel_child by assumption;reflexivity. Qed.

(* The base order is used until the first exhausted block meeting this
   row supplies an earlier member. The current seed takes priority for
   just its own search. Negative entries represent rows without a tie. *)
Definition clear_seed (base fallback:Z):=if Z_lt_dec fallback 0 then base else fallback.
Definition first_exhausted (member:Z->bool) (old:option Z) (qs:list Z) :=
 match old with Some q=>Some q | None=>List.find member qs end.
Lemma first_exhausted_app member old first rest :
 first_exhausted member (first_exhausted member old first) rest=
 first_exhausted member old (first++rest).
Proof.
 destruct old as [v|];[reflexivity|];unfold first_exhausted.
 induction first as [|q first IH];[reflexivity|];cbn;destruct (member q);[reflexivity|exact IH].
Qed.
Lemma earliest_exhausted_member member earlier q later :
 Forall (fun a=>member a=false) earlier -> member q=true ->
 first_exhausted member None (earlier++q::later)=Some q.
Proof.
 intros absent found;induction absent;cbn [first_exhausted app List.find].
 - rewrite found;reflexivity.
 - rewrite H;exact IHabsent.
Qed.
