(* Finite actual Clight step2 execution of frozen primitive bodies.
   These are operational termination proofs, not just VST partial correctness.
   They do not establish termination of the search/library as a whole. *)
Require Import VST.floyd.proofauto.
Require Import compcert.common.Events.
Require Import compcert.lib.Maps.
Require Import compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.ccv_primitives.
Import ListNotations.
Definition binary_primitive_temps(a b:int):Clight.temp_env:=
 PTree.set ccv_primitives._b(Vint b)
 (PTree.set ccv_primitives._a(Vint a)(PTree.empty val)).
Lemma xor_function_entry ge a b m:
 Clight.function_entry2 ge ccv_primitives.f_ccv_bit_xor [Vint a;Vint b] m
 Clight.empty_env(binary_primitive_temps a b)m.
Proof.
 constructor.
 - constructor.
 - vm_compute. repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - unfold list_disjoint;cbn;intros;contradiction.
 - constructor.
 - reflexivity.
Qed.
Theorem actual_bit_xor_terminates ge a b k m:
 star Clight.step2 ge
 (Clight.Callstate(Internal ccv_primitives.f_ccv_bit_xor)[Vint a;Vint b]k m)
 E0 (Clight.Returnstate(Vint(Int.xor a b))(Clight.call_cont k)m).
Proof.
 eapply star_two with(s2:=Clight.State ccv_primitives.f_ccv_bit_xor
 (fn_body ccv_primitives.f_ccv_bit_xor)k Clight.empty_env(binary_primitive_temps a b)m).
 - unfold Clight.step2;apply Clight.step_internal_function;apply xor_function_entry.
 - unfold Clight.step2;cbn[fn_body ccv_primitives.f_ccv_bit_xor].
   eapply Clight.step_return_1 with(v:=Vint(Int.xor a b)).
   + eapply Clight.eval_Ebinop with(v1:=Vint a)(v2:=Vint b).
     * apply Clight.eval_Etempvar;reflexivity.
     * apply Clight.eval_Etempvar;reflexivity.
     * reflexivity.
   + reflexivity.
   + reflexivity.
 - reflexivity.
Qed.
Print Assumptions actual_bit_xor_terminates.
