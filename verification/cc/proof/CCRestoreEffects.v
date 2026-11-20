(* Invert successful Clight2 evaluations and assignments at restore's two
   physical writes. No assumption about how the caller arranged its buffers. *)
Require Import VST.floyd.proofauto VST.veric.Clight_lemmas.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.ccv_core CCV.CCTerminateRestore CCV.CCClightWordReads CCV.CCStructuredRuns.
Open Scope Z_scope.
Lemma read_temp_inv ge e l m id ty v : eval_expr ge e l m (Etempvar id ty) v ->
 PTree.get id l=Some v.
Proof. inversion 1;subst;try assumption;match goal with L:eval_lvalue _ _ _ _ (Etempvar _ _) _ _ _|-_=>inversion L end. Qed.
Lemma read_counter_inv ge e l m v : eval_expr ge e l m rt_counter v ->
 exists b o, PTree.get _top l=Some(Vptr b o) /\ Mem.load Mint32 m b (Ptrofs.unsigned o)=Some v.
Proof.
 intros Ev;inversion Ev;subst.
 match goal with L:eval_lvalue _ _ _ _ _ _ _ _ |- _ =>inversion L;subst end.
 match goal with D:deref_loc _ _ _ _ _ _|-_=>inversion D;subst;try discriminate end.
 match goal with H:access_mode _=By_value _|-_=>injection H as <- end.
 do 2 eexists;split;[eapply read_temp_inv;eassumption|assumption].
Qed.
Lemma restore_guard_positive ge e l m v :
 PTree.get _t'6 l=Some v -> Val.has_type v AST.Tint ->
 takes ge e l m rt_guard true -> exists x,v=Vint x /\ 0<Int.unsigned x.
Proof.
 intros Get Typed [result [Ev Test]];inversion Ev;subst;
 try match goal with L:eval_lvalue _ _ _ _ (Ebinop _ _ _ _) _ _ _ |- _=>inversion L end.
 match goal with T:eval_expr _ _ _ _ (Etempvar _t'6 _) ?lhs |- _ =>
   apply read_temp_inv in T;assert(lhs=v) by congruence;subst lhs end.
 match goal with Op:sem_binary_operation _ _ _ _ ?rhs _ _=Some _ |- _=>
 destruct v, rhs;cbn in Typed,Op;try contradiction;try discriminate;
 inversion Op;subst;try discriminate end.
 match goal with H:context[Int.ltu ?a ?b] |- _=>
 destruct (Int.ltu a b) eqn:Less;try discriminate;
 exists b;split;[reflexivity|unfold Int.ltu in Less;destruct(zlt _ _);pose proof(Int.unsigned_range_2 a);lia] end.
all: match goal with L:eval_lvalue _ _ _ _ rt_guard _ _ _ |- _=>inversion L end.
Qed.

Lemma restore_word_write ge f k e l m m' t bt ot x :
 PTree.get _top l=Some(Vptr bt ot) -> PTree.get _t'5 l=Some(Vint x) ->
 step2 ge (State f (Sassign rt_counter rt_sub) k e l m) t (State f Sskip k e l m') ->
 Mem.store Mint32 m bt (Ptrofs.unsigned ot) (Vint(Int.sub x Int.one))=Some m'.
Proof.
 intros Top X Actual;inversion Actual;subst;try solve[intuition discriminate].
 match goal with L:eval_lvalue _ _ _ _ rt_counter _ _ _|-_ =>inversion L;subst end.
 match goal with V:eval_expr _ _ _ _ (Etempvar _top _) _ |- _ =>
   apply read_temp_inv in V;rewrite Top in V;injection V;intros;subst end.
 match goal with A:assign_loc _ _ _ _ _ _ _ _|-_=>inversion A;subst;try discriminate end.
 match goal with H:access_mode _=By_value _|-_=>injection H as <- end.
 assert (Value:eval_expr ge e l m rt_sub (Vint(Int.sub x Int.one))).
 { eapply eval_Ebinop with (v1:=Vint x) (v2:=Vint Int.one);
   [apply eval_Etempvar;exact X|apply eval_Econst_int|reflexivity]. }
 match goal with C:Cop.sem_cast ?u _ _ _=Some _, R:eval_expr _ _ _ _ rt_sub ?u |- _=>
   rewrite <- (eval_expr_fun Value R) in C end.
 match goal with C:Cop.sem_cast _ _ _ _=Some _ |- _=>cbn in C;inversion C;subst end.
 Show. assumption.
Qed.
Lemma restore_byte_write ge f k e l m m' t :
 step2 ge (State f (Sassign rt_byte (Econst_int Int.zero tuint)) k e l m) t (State f Sskip k e l m') ->
 exists b pos,Mem.store Mint8unsigned m b pos (Vint Int.zero)=Some m'.
Proof.
 intro Actual;inversion Actual;subst;try solve[intuition discriminate].
 match goal with L:eval_lvalue _ _ _ _ rt_byte _ _ _ |- _=>inversion L;subst end.
 match goal with R:eval_expr _ _ _ _ (Econst_int _ _) _ |- _=>
 inversion R;subst;try match goal with L:eval_lvalue _ _ _ _ (Econst_int _ _) _ _ _|-_=>inversion L end end.
 match goal with C:Cop.sem_cast _ _ _ _=Some _ |- _=>cbn in C;inversion C;subst end.
 match goal with A:assign_loc _ _ _ _ _ _ _ _|-_=>inversion A;subst;try discriminate end.
 match goal with H:access_mode _=By_value _|-_=>injection H as <- end.
 do 2 eexists;eassumption.
Qed.
