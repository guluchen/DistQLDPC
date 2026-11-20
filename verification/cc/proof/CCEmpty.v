(* The unconditional zero-free-candidate check used by the C bounds function. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPacking.
Import ListNotations.
Theorem odd_repair_nonempty n hs ls e s f h : good n hs ls e -> compatible n e s f ->
 In h hs ->parity n h s=true ->repair n h s f<>[].
Proof.
 intros [_ [Ker Log]] [Sub Avoid] Hin Odd Empty.
 destruct(odd_row_has_target_extension n h s e Sub Odd (Ker _ Hin)) as [q [Q [Hq [E S]]]].
 assert(F:f q=false).
 { destruct(f q) eqn:F;[pose proof(Avoid q Q F);congruence|reflexivity]. }
 assert(Member:In q (repair n h s f)) by (apply repair_member;tauto).
 rewrite Empty in Member;contradiction.
Qed.
Definition empty_prune n (hs:list vector) s f :=
 if existsb (fun h=>andb (parity n h s) (Nat.eqb (length(repair n h s f)) 0)) hs
 then None else Some f.
Theorem empty_prune_contract n hs ls cap : prune_contract n hs ls cap (empty_prune n hs).
Proof.
 intros e s f Min Cap Comp;unfold empty_prune.
 destruct(existsb _ _) eqn:E.
 - apply existsb_exists in E;destruct E as [h [Hin E]];apply andb_true_iff in E;destruct E as [Odd Len].
   apply Nat.eqb_eq in Len.
   pose proof(odd_repair_nonempty n hs ls e s f h (proj1 Min) Comp Hin Odd) as Nonempty.
   destruct(repair n h s f);[contradiction|simpl in Len;lia].
 - exists f;split;[reflexivity|exact(proj2 Comp)].
Qed.
Print Assumptions odd_repair_nonempty.
Print Assumptions empty_prune_contract.
