(* GF(2) cache invariant. This is not the C-array representation bridge. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional.
Import ListNotations.
Definition unit_vector (q:nat) : vector := fun i=>Nat.eqb i q.
Definition flip (s:vector) (q:nat) : vector := fun i=>if Nat.eqb i q then negb(s i) else s i.
Lemma parity_unit_outside n h q : n<=q -> parity n h (unit_vector q)=false.
Proof.
 induction n as [|n IH];intros H;[reflexivity|].
 cbn [parity];unfold unit_vector at 1.
 assert (E:Nat.eqb n q=false) by (apply Nat.eqb_neq;lia).
 rewrite E,IH by lia;destruct(h n);reflexivity.
Qed.
Lemma parity_unit_inside n h q : q<n -> parity n h (unit_vector q)=h q.
Proof.
 induction n as [|n IH];intros H;[lia|].
 cbn [parity];unfold unit_vector at 1.
 destruct(Nat.eq_dec n q) as [E|E].
 - subst q;rewrite Nat.eqb_refl,parity_unit_outside by lia;destruct(h n);reflexivity.
 - rewrite (proj2 (Nat.eqb_neq n q) E),IH by lia;destruct(h n), (h q);reflexivity.
Qed.
Theorem parity_flip n h s q : q<n -> parity n h (flip s q)=xorb (parity n h s) (h q).
Proof.
 intros Hq.
 rewrite (parity_ext n h (flip s q) (vxor s (unit_vector q))).
 - rewrite parity_xor,parity_unit_inside by assumption;reflexivity.
 - intros i Hi;unfold flip,vxor,unit_vector;destruct(Nat.eqb i q), (s i);reflexivity.
Qed.
Definition cache n rows s := map (fun h=>parity n h s) rows.
Definition bool_column rows q := map(fun h:vector=>h q) rows.
Fixpoint xor_cache (xs ys:list bool) : list bool :=
 match xs,ys with x::xt,y::yt=>xorb x y::xor_cache xt yt | _,_=>[] end.
Theorem cache_toggle_correct n rows s q : q<n ->
 cache n rows (flip s q)=xor_cache (cache n rows s) (bool_column rows q).
Proof.
 intros H;induction rows as [|h rows IH];[reflexivity|].
 cbn [cache bool_column xor_cache map] in *;rewrite parity_flip by assumption;f_equal;exact IH.
Qed.
Lemma flip_twice s q i : flip (flip s q) q i=s i.
Proof. unfold flip;destruct(Nat.eqb i q);[apply negb_involutive|reflexivity]. Qed.
Theorem cache_toggle_restore n rows s q : cache n rows (flip (flip s q) q)=cache n rows s.
Proof.
 unfold cache;apply map_ext;intros h;apply parity_ext;intros i Hi;apply flip_twice.
Qed.
Print Assumptions parity_flip.
Print Assumptions cache_toggle_correct.
Print Assumptions cache_toggle_restore.
