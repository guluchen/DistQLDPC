(* A successful unsigned strict-less-than guard leaves room for one
   increment even when the right-hand side is recomputed from memory. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCStructuredRuns CCV.CCScanFrames.
Import ListNotations. Open Scope Z_scope.
Definition room id l := exists x, PTree.get id l=Some(Vint x) /\ Int.unsigned x<Int.max_unsigned.
Definition less_guard id bound := Ebinop Cop.Olt (Etempvar id tuint) bound tint.
Lemma uint_test_room ge e le m id bound :
 typeof bound=tuint -> takes ge e le m (less_guard id bound) true -> room id le.
Proof.
 intros Ty [v [Ev Bool]]. inversion Ev; subst;
 try match goal with H:Clight.eval_lvalue _ _ _ _ (less_guard _ _) _ _ _ |- _ => inversion H end.
 match goal with H:Clight.eval_expr _ _ _ _ (Etempvar _ _) ?v |- _ =>
   inversion H; subst;try match goal with L:Clight.eval_lvalue _ _ _ _ (Etempvar _ _) _ _ _ |- _=>inversion L end end.
 match goal with Op:context[sem_binary_operation] |- _ =>
   cbn[typeof] in Op;rewrite Ty in Op;
   match type of Op with context[sem_binary_operation _ _ ?x _ ?y _ _] =>
    destruct x, y;cbn in Op; try discriminate end;
   inversion Op;subst end.
 match goal with H:context[Cop.bool_val (Val.of_bool (Int.ltu ?a ?b)) _ _] |- _ =>
   destruct (Int.ltu a b) eqn:Less; [|discriminate H];
   exists a;split;[assumption|pose proof(Int.unsigned_range_2 b);
      unfold Int.ltu in Less;destruct (zlt (Int.unsigned a) (Int.unsigned b));lia] end.
Qed.
Definition counter_rank id (l:Clight.temp_env) :=
 match PTree.get id l with
 |Some (Vint x) => Z.to_nat (Int.max_unsigned-Int.unsigned x)
 | _ => S (Z.to_nat Int.max_unsigned) end.
Definition increment id := Sset id (Ebinop Cop.Oadd (Etempvar id tuint) (Econst_int Int.one tint) tuint).
Lemma increment_room ge e le m id x v :
 PTree.get id le=Some(Vint x) ->
 Clight.eval_expr ge e le m (Ebinop Cop.Oadd (Etempvar id tuint) (Econst_int Int.one tint) tuint) v ->
 v=Vint(Int.add x Int.one).
Proof.
 intros Get Ev;inversion Ev;subst;
 try match goal with L:Clight.eval_lvalue _ _ _ _ (Ebinop _ _ _ _) _ _ _ |- _ => inversion L end.
 match goal with H:Clight.eval_expr _ _ _ _ (Etempvar _ _) _ |- _ =>
 inversion H;subst;try match goal with L:Clight.eval_lvalue _ _ _ _ (Etempvar _ _) _ _ _ |- _=>inversion L end end.
 match goal with H:Clight.eval_expr _ _ _ _ (Econst_int _ _) _ |- _ =>
 inversion H;subst;try match goal with L:Clight.eval_lvalue _ _ _ _ (Econst_int _ _) _ _ _ |- _=>inversion L end end.
 match goal with Op:sem_binary_operation _ _ ?lhs _ _ _ _=Some _ |- _ =>
   assert (Eql:lhs=Vint x) by congruence;rewrite Eql in Op;
   change (Some (Vint (Int.add x Int.one))=Some v) in Op end.
 congruence.
Qed.
Lemma increment_decreases id le x :
 PTree.get id le=Some(Vint x) -> Int.unsigned x<Int.max_unsigned ->
 (counter_rank id (PTree.set id (Vint(Int.add x Int.one)) le)<counter_rank id le)%nat.
Proof.
 intros Get R;unfold counter_rank;rewrite PTree.gss,Get;unfold Int.add;
 rewrite Int.unsigned_one,Int.unsigned_repr by (pose proof(Int.unsigned_range_2 x);lia).
 lia.
Qed.
