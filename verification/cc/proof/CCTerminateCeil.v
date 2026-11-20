(* Actual finite execution of the frozen ceil-div helper for nonzero divisor.
   Whole-library/search operational termination remains a separate obligation. *)
Require Import VST.floyd.proofauto.
Require Import compcert.common.Events.
Require Import compcert.lib.Maps compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.ccv_primitives CCV.CCWord CCV.CCTerminatePrimitives.
Import ListNotations.
Lemma ceil_function_entry ge a b m:
 Clight.function_entry2 ge ccv_primitives.f_ccv_ceil_div [Vint a;Vint b] m
 Clight.empty_env(binary_primitive_temps a b)m.
Proof.
 constructor.
 - constructor.
 - vm_compute. repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - unfold list_disjoint;cbn;intros;contradiction.
 - constructor.
 - reflexivity.
Qed.
Theorem actual_ceil_div_terminates ge a b k m:
 Int.unsigned b<>0 ->
 star Clight.step2 ge
 (Clight.Callstate(Internal ccv_primitives.f_ccv_ceil_div)[Vint a;Vint b]k m)
 E0 (Clight.Returnstate(Vint(machine_ceil a b))(Clight.call_cont k)m).
Proof.
 intros Nonzero.
 assert(B:Int.eq b Int.zero=false).
 { apply Int.eq_false;intro Eq;subst b;rewrite Int.unsigned_zero in Nonzero;contradiction. }
 eapply star_two with(s2:=Clight.State ccv_primitives.f_ccv_ceil_div
 (fn_body ccv_primitives.f_ccv_ceil_div)k Clight.empty_env(binary_primitive_temps a b)m).
 - unfold Clight.step2;apply Clight.step_internal_function;apply ceil_function_entry.
 - unfold Clight.step2;cbn[fn_body ccv_primitives.f_ccv_ceil_div].
   eapply Clight.step_return_1 with(v:=Vint(machine_ceil a b)).
   + eapply Clight.eval_Ebinop with(v1:=Vint(Int.divu a b))
     (v2:=Vint(if Int.eq(Int.modu a b)Int.zero then Int.zero else Int.one)).
     * eapply Clight.eval_Ebinop with(v1:=Vint a)(v2:=Vint b).
       -- apply Clight.eval_Etempvar;reflexivity.
       -- apply Clight.eval_Etempvar;reflexivity.
       -- cbn;rewrite B;reflexivity.
     * eapply Clight.eval_Ebinop with(v1:=Vint(Int.modu a b))(v2:=Vint Int.zero).
       -- eapply Clight.eval_Ebinop with(v1:=Vint a)(v2:=Vint b).
          ++ apply Clight.eval_Etempvar;reflexivity.
          ++ apply Clight.eval_Etempvar;reflexivity.
          ++ cbn;rewrite B;reflexivity.
       -- apply Clight.eval_Econst_int.
       -- cbn;destruct(Int.eq(Int.modu a b)Int.zero);reflexivity.
     * reflexivity.
   + reflexivity.
   + reflexivity.
 - reflexivity.
Qed.
Print Assumptions actual_ceil_div_terminates.
