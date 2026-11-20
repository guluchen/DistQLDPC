(* Single-column minimum-target completion used by the actual leaf shortcut.
   Pure vector mathematics; the C search caller refinement is separate. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache.
Lemma zero_weight_support n p : weight n p=0 ->forall i,i<n ->p i=false.
Proof.
 induction n as [|n IH];simpl;intros W i I;[lia|].
 destruct(p n)eqn:P;[lia|].
 destruct(Nat.eq_dec i n)as [->|Ne];[assumption|apply IH;lia].
Qed.
Lemma unit_weight_support n p : weight n p=1 ->
 exists q,q<n /\p q=true /\forall i,i<n ->p i=Nat.eqb i q.
Proof.
 induction n as [|n IH];simpl;intros W;[lia|].
 destruct(p n)eqn:P.
 - assert(Zero:weight n p=0)by lia.
   exists n;split;[lia|split;[assumption|]].
   intros i I;destruct(Nat.eq_dec i n)as [->|Ne].
   + rewrite P,Nat.eqb_refl;reflexivity.
   + rewrite(zero_weight_support n p Zero i ltac:(lia));symmetry;apply Nat.eqb_neq;assumption.
 - assert(One:weight n p=1)by lia.
   destruct(IH One)as [q [Q [Hit Eq]]];exists q;split;[lia|split;[assumption|]].
   intros i I;destruct(Nat.eq_dec i n)as [->|Ne].
   + rewrite P;symmetry;apply Nat.eqb_neq;lia.
   + apply Eq;lia.
Qed.
Theorem single_extension n s e : subset n s e ->weight n e=weight n s+1 ->
 exists q,q<n /\s q=false /\e q=true /\forall i,i<n ->e i=flip s q i.
Proof.
 intros Sub Weights;pose proof(subset_split n s e Sub)as Split.
 assert(One:weight n(vdiff e s)=1)by lia.
 destruct(unit_weight_support n(vdiff e s)One)as [q [Q [Hit Eq]]].
 unfold vdiff in Hit;apply andb_true_iff in Hit;destruct Hit as [E S];apply negb_true_iff in S.
 exists q;repeat split;try assumption.
 intros i I;unfold flip;destruct(Nat.eqb i q)eqn:Same.
 - apply Nat.eqb_eq in Same;subst i;rewrite E,S;reflexivity.
 - pose proof(Eq i I)as D;rewrite Same in D;unfold vdiff in D.
   specialize(Sub i I);destruct(s i),(e i);simpl in *;try reflexivity;intuition congruence.
Qed.
Theorem single_extension_from_cap n s e :
 subset n s e ->weight n s<weight n e ->weight n e<=weight n s+1 ->
 exists q,q<n /\s q=false /\e q=true /\forall i,i<n ->e i=flip s q i.
Proof. intros Sub Less Cap;apply single_extension;[assumption|lia]. Qed.
Theorem single_extension_avoids n s e f :
 compatible n e s f ->weight n e=weight n s+1 ->
 exists q,q<n /\s q=false /\f q=false /\e q=true /\forall i,i<n ->e i=flip s q i.
Proof.
 intros [Sub Avoid] Weights;destruct(single_extension n s e Sub Weights)as [q [Q [S [E Eq]]]].
 assert(F:f q=false)by(destruct(f q)eqn:F;[pose proof(Avoid q Q F);congruence|reflexivity]).
 exists q;repeat split;assumption.
Qed.
Theorem single_extension_odd_candidate n h s e q :
 q<n ->(forall i,i<n ->e i=flip s q i) ->parity n h s=true ->parity n h e=false ->h q=true.
Proof.
 intros Q Eq Odd Ker;rewrite(parity_ext n h e(flip s q)Eq),parity_flip in Ker by assumption.
 rewrite Odd in Ker;destruct(h q);[reflexivity|discriminate].
Qed.
Print Assumptions single_extension.
Print Assumptions single_extension_avoids.
Print Assumptions single_extension_odd_candidate.
