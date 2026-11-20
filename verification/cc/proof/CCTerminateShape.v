(* Finite accepting execution for every shape admitted by the VST spec.
   Only the six dimension words are read; the code never follows matrix pointers. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCLinkedProgram CCV.CCShapeArithmetic CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Local Notation ge := (Clight.globalenv linked_prog).
Definition shape_word m b ofs delta x :=
 Mem.loadv Mint32 m (Vptr b (Ptrofs.add ofs (Ptrofs.repr delta))) = Some (Vint (Int.repr x)).
Definition shape_temps pp wp rules :=
 PTree.set _rules (Vint (Int.repr rules)) (PTree.set _w wp
 (PTree.set _p pp (Clight.create_undef_temps (fn_temps f_shape)))).
Lemma shape_entry pp wp rules m :
 Clight.function_entry2 ge f_shape [pp; wp; Vint(Int.repr rules)] m
 Clight.empty_env (shape_temps pp wp rules) m.
Proof.
 constructor; [constructor| | |constructor|reflexivity].
 - vm_compute; repeat (apply list_norepet_cons; [simpl; intuition congruence|]); constructor.
 - vm_compute; intros; intuition congruence.
Qed.

Lemma shape_size_frame : @Ctypes.sizeof (Clight.genv_cenv ge) (Tstruct _ccv_frame noattr)=20.
Proof.
 change (@Ctypes.sizeof (prog_comp_env linked_prog) (Tstruct _ccv_frame noattr)=20).
 rewrite linked_composite_env. reflexivity.
Qed.
Lemma shape_size_expr e le m :
 Clight.eval_expr ge e le m (Esizeof (Tstruct _ccv_frame noattr) tulong) (Vlong (Int64.repr 20)).
Proof.
 pose proof (Clight.eval_Esizeof ge e le m (Tstruct _ccv_frame noattr) tulong) as E.
 rewrite shape_size_frame in E. exact E.
Qed.
Local Opaque linked_prog.
Ltac shape_layout :=
 change (Clight.genv_cenv ge) with (prog_comp_env linked_prog);
 rewrite linked_composite_env;reflexivity.
Ltac shape_register := unfold shape_temps;
 repeat first [rewrite PTree.gss | rewrite PTree.gso by discriminate]; reflexivity.
Ltac shape_field base sid field :=
 let offset := lazymatch field with
 | _n => constr:(0) | _checks => constr:(4) | _logical_rows => constr:(8)
 | _stabilizers => constr:(12) | _capacity => constr:(0) | _frame_capacity => constr:(4) end in
 match goal with H: shape_word ?m ?b ?ofs offset ?x |- _ =>
   eapply (eval_struct_field ge _ _ m base sid field tuint _ offset Mint32 b ofs (Vint (Int.repr x)));
   [shape_register |shape_layout|reflexivity|reflexivity|exact H]
 end.
Ltac shape_expr :=
 lazymatch goal with
 | |- Clight.eval_expr _ _ _ _ (Efield (Ederef (Etempvar ?base _) (Tstruct ?sid _)) ?field _) _ => shape_field base sid field
 | |- Clight.eval_expr _ _ _ _ (Etempvar _ _) _ => apply Clight.eval_Etempvar;shape_register
 | |- Clight.eval_expr _ _ _ _ (Econst_int _ _) _ => apply Clight.eval_Econst_int
 | |- Clight.eval_expr _ _ _ _ (Ecast _ _) _ => eapply Clight.eval_Ecast; [shape_expr|reflexivity]
 | |- Clight.eval_expr _ _ _ _ (Ebinop Odiv _ (Esizeof (Tstruct _ _) _) _) _ =>
   eapply Clight.eval_Ebinop with (v := Vlong (Int64.repr 107374182));
     [apply Clight.eval_Econst_int|apply shape_size_expr|vm_compute;reflexivity]
 | |- Clight.eval_expr _ _ _ _ (Ebinop Odiv _ (Esizeof _ _) _) _ =>
   eapply Clight.eval_Ebinop with (v := Vlong (Int64.repr 536870911));
     [apply Clight.eval_Econst_int|apply Clight.eval_Esizeof|reflexivity]
 | |- Clight.eval_expr _ _ _ _ (Ebinop ?op _ ?rhs _) _ =>
   let lemma := lazymatch op with
     | Oeq => constr:(shape_eq_zero) | Odiv => constr:(shape_divisor)
     | Olt => constr:(shape_cmp_lt)
     | Ogt => lazymatch rhs with Ebinop Odiv _ (Esizeof _ _) _ => constr:(shape_long_gt)
                                | _ => constr:(shape_cmp_gt) end end in
   eapply Clight.eval_Ebinop; [shape_expr|shape_expr|apply lemma;rep_lia]
 end.
Ltac shape_step :=
 lazymatch goal with
 | |- star _ _ (Clight.State _ (Ssequence _ _) _ _ _ _) _ _ =>
   weight_silent_step; [apply Clight.step_seq|]
 | |- star _ _ (Clight.State _ Sskip (Kseq _ _) _ _ _) _ _ =>
   weight_silent_step; [apply Clight.step_skip_seq|]
 | |- star _ _ (Clight.State _ (Sset _ _) _ _ _ _) _ _ =>
   weight_silent_step; [eapply Clight.step_set; shape_expr|]
 | |- star _ _ (Clight.State _ (Sifthenelse _ _ _) _ _ _ _) _ _ =>
   weight_silent_step; [eapply Clight.step_ifthenelse with (v1:=Vint Int.zero) (b:=false);
       [shape_expr|reflexivity]|]
 | |- star _ _ (Clight.State _ (Sreturn _) _ _ _ _) _ _ =>
   weight_silent_step; [eapply Clight.step_return_1; [apply Clight.eval_Econst_int|reflexivity|reflexivity]|]
 end.
Theorem actual_shape_terminates bp op bw ow n checks logical stab cap frames rules m k :
 0<n<=107374182 -> 0<=checks<=2147483647/n -> 0<logical<=2147483647/n ->
 0<=stab<=2147483647/n -> n<=cap<=Int.max_unsigned -> n<=frames<=Int.max_unsigned ->
 0<=rules<=63 -> shape_word m bp op 0 n -> shape_word m bp op 4 checks ->
 shape_word m bp op 8 logical -> shape_word m bp op 12 stab ->
 shape_word m bw ow 0 cap -> shape_word m bw ow 4 frames ->
 star Clight.step2 ge
   (Clight.Callstate (Internal f_shape) [Vptr bp op;Vptr bw ow;Vint(Int.repr rules)] k m) E0
   (Clight.Returnstate (Vint Int.one) (Clight.call_cont k) m).
Proof.
 intros.
 assert (0<=2147483647/n<=2147483647) by
 (split; [apply Z.div_pos|apply Z.div_le_upper_bound]; nia).
 weight_silent_step. apply Clight.step_internal_function; apply shape_entry.
 cbn [fn_body f_shape].
 repeat shape_step.
 apply star_refl.
Qed.
Print Assumptions actual_shape_terminates.
