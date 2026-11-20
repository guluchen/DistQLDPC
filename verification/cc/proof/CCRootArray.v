(* Concrete byte-array model for the C canonical-root initialization loop.
   Not a proof of the complete C search function. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCRepresentation CCV.CCMatrixModel CCV.CCPackedArray CCV.CCCandidateScan.
Open Scope Z_scope.
Definition root_mask n seed :=blend(Zrepeat 0 n)(Zrepeat 1 n)seed.
Lemma root_mask_start n :root_mask n 0=Zrepeat 0 n.
Proof. unfold root_mask;apply blend_start. Qed.
Lemma root_mask_length n seed :0<=seed<=n ->Zlength(root_mask n seed)=n.
Proof. intros;unfold root_mask;rewrite blend_length;rewrite ?Zlength_Zrepeat;lia. Qed.
Lemma root_mask_at n seed q :0<=seed<=n ->0<=q<n ->
 Znth q(root_mask n seed)=if q<?seed then 1 else 0.
Proof.
 intros Seed Q;unfold root_mask,blend;destruct(q<?seed)eqn:T.
 - apply Z.ltb_lt in T;list_solve.
 - apply Z.ltb_ge in T;list_solve.
Qed.
Lemma root_mask_bits n seed :0<=seed<=n ->Forall(fun z:Z=>z=0 \/z=1)(root_mask n seed).
Proof.
 intros Seed;apply(proj2(Forall_Znth _ _));intros q Q.
 rewrite root_mask_length in Q by assumption;rewrite root_mask_at by assumption.
 destruct(q<?seed);auto.
Qed.
Lemma root_mask_step n seed :0<=seed<n ->
 upd_Znth seed(root_mask n seed)1=root_mask n(seed+1).
Proof.
 intros Seed;unfold root_mask;rewrite <-blend_step by(rewrite ?Zlength_Zrepeat;lia).
 rewrite Znth_Zrepeat by assumption;reflexivity.
Qed.
Theorem root_mask_decode n seed q :0<=seed<=n ->(q<Z.to_nat n)%nat ->
 decode(root_mask n seed)q=root_forbidden(Z.to_nat seed)q.
Proof.
 intros Seed Q;rewrite decode_at_nat,root_mask_at by lia.
 unfold root_forbidden;destruct(Nat.ltb q(Z.to_nat seed))eqn:T.
 - apply Nat.ltb_lt in T;assert(J:Z.of_nat q<seed)by lia.
   assert(Test:(Z.of_nat q<?seed)=true)by(apply Z.ltb_lt;assumption).
   rewrite Test;reflexivity.
 - apply Nat.ltb_ge in T;assert(J:seed<=Z.of_nat q)by lia.
   assert(Test:(Z.of_nat q<?seed)=false)by(apply Z.ltb_ge;assumption).
   rewrite Test;reflexivity.
Qed.
Theorem root_toggle_decode n seed q :0<=seed<n ->(q<Z.to_nat n)%nat ->
 decode(upd_Znth seed(Zrepeat 0 n)(Z.lxor(Znth seed(Zrepeat 0 n))1))q=
 root_selected(Z.to_nat seed)q.
Proof.
 intros Seed Q.
 rewrite decode_toggle by(rewrite ?Zlength_Zrepeat;try lia;unfold Zrepeat;apply Forall_repeat;auto).
 unfold flip,root_selected,setbit;rewrite decode_zero_vector.
 destruct(Nat.eqb q(Z.to_nat seed));reflexivity.
Qed.
Print Assumptions root_mask_step.
Print Assumptions root_mask_decode.
Print Assumptions root_toggle_decode.
