(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto TableFlow BuiltLookup.

(* The descending outer loop has a next step at every nonnegative q.
   The final history therefore exists for any column keys, even empty keys. *)
Theorem builder_finishes ks mask cap bits :
  0<=bits<64 -> cap=2^bits -> mask=Int64.repr (Z.ones bits) ->
  Zlength ks<cap -> exists tab links, history ks mask cap (-1) tab links.
Proof.
  intros br power word room.
  assert (finish:forall t:nat, forall tab links,
    history ks mask cap (Z.of_nat t-1) tab links ->
    exists tab' links', history ks mask cap (-1) tab' links').
  { induction t as [|t ih];intros tab links prev.
    - exists tab,links;exact prev.
    - rewrite Nat2Z.inj_succ in prev.
      replace (Z.succ (Z.of_nat t)-1) with (Z.of_nat t) in prev by lia.
      destruct (@insertion_finishes ks mask cap bits br power word room _ _ _ prev)
        as [i [route [empty|same]]].
      + eapply ih;eapply placed_empty with (i:=i);eauto;lia.
      + destruct (Z_lt_dec (head tab i) 0) as [empty|full].
        * eapply ih;eapply placed_empty with (i:=i);eauto;lia.
        * eapply ih;eapply placed_chain with (i:=i);eauto;lia. }
  apply (finish (length ks) (Zrepeat (-1) cap) (Zrepeat (-1) (Zlength ks))).
  rewrite <- Zlength_correct;constructor.
Qed.
