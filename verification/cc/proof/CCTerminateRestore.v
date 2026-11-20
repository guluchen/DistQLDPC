(* Actual restore control flow. Concrete valid memory and nonaliasing premises
   remain explicit; no whole-search termination claim is made here. *)
Require Import VST.floyd.proofauto Coq.Arith.Wf_nat.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCClightWordReads CCV.CCClightLvalues
 CCV.CCClightStores CCV.CCRestoreMemory CCV.CCRestoreInvariant
 CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Local Transparent tptr tuchar tuint tint typeconv remove_attributes change_attributes Cop.sem_add.
Definition rt_counter:=uint_deref_expr _top.
Definition rt_guard:=Ebinop Cop.Ogt(Etempvar _t'6 tuint)(Etempvar _mark tuint)tint.
Definition rt_sub:=Ebinop Osub(Etempvar _t'5 tuint)(Econst_int(Int.repr 1)tuint)tuint.
Definition rt_flags:=struct_field_expr _w _ccv_workspace _forbidden(tptr tuchar).
Definition rt_undo:=struct_field_expr _w _ccv_workspace _undo(tptr tuint).
Definition rt_read:=uint_index_expr _t'2 _t'3.
Definition rt_byte:=uchar_index_expr _t'1 _t'4.
Definition rt_clear:=Ssequence(Sset _t'1 rt_flags)
 (Ssequence(Sset _t'2 rt_undo)(Ssequence(Sset _t'3 rt_counter)
 (Ssequence(Sset _t'4 rt_read)(Sassign rt_byte(Econst_int(Int.repr 0)tuint))))).
Definition rt_decrement:=Ssequence(Sset _t'5 rt_counter)(Sassign rt_counter rt_sub).
Definition rt_iteration:=Ssequence
 (Ssequence(Sset _t'6 rt_counter)(Sifthenelse rt_guard Sskip Sbreak))
 (Ssequence rt_decrement rt_clear).
Definition rt_loop:=Sloop rt_iteration Sskip.
Lemma rt_body_actual:fn_body f_restore=rt_loop. Proof. reflexivity. Qed.
Definition rt_env le bw ow bt ot mark:Prop:=
 PTree.get _w le=Some(Vptr bw ow) /\PTree.get _top le=Some(Vptr bt ot) /\
 PTree.get _mark le=Some(Vint(Int.repr mark)).
Definition rt_guard_env le top:=PTree.set _t'6(Vint(Int.repr top))le.
Definition rt_dec_env le top:=PTree.set _t'5(Vint(Int.repr top))(rt_guard_env le top).
Definition rt_flag_env le top bf ofl:=PTree.set _t'1(Vptr bf ofl)(rt_dec_env le top).
Definition rt_undo_env le top bf ofl bu ou:=PTree.set _t'2(Vptr bu ou)(rt_flag_env le top bf ofl).
Definition rt_index_env le top bf ofl bu ou:=PTree.set _t'3(Vint(Int.repr(top-1)))(rt_undo_env le top bf ofl bu ou).
Definition rt_next_env le top bf ofl bu ou q:=PTree.set _t'4(Vint(Int.repr q))(rt_index_env le top bf ofl bu ou).
Ltac rt_registers:=unfold rt_next_env,rt_index_env,rt_undo_env,rt_flag_env,rt_dec_env,rt_guard_env;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);first[assumption|reflexivity].
Lemma rt_next_valid le bw ow bt ot mark top bf ofl bu ou q:
 rt_env le bw ow bt ot mark ->rt_env(rt_next_env le top bf ofl bu ou q)bw ow bt ot mark.
Proof. intros[W[T M]];unfold rt_env;repeat split;rt_registers. Qed.
Lemma rt_counter_eval ge le m bw ow bt ot mark word:
 rt_env le bw ow bt ot mark ->Mem.loadv Mint32 m(Vptr bt ot)=Some(Vint word) ->
 Clight.eval_expr ge Clight.empty_env le m rt_counter(Vint word).
Proof. intros[W[T M]] Load;unfold rt_counter;apply(eval_uint_deref ge Clight.empty_env le m _top bt ot word);assumption. Qed.
Lemma rt_guard_eval ge le m bw ow bt ot mark top(flag:bool):
 rt_env le bw ow bt ot mark ->0<=top<=Int.max_unsigned ->0<=mark<=Int.max_unsigned ->
 (if flag then mark<top else top<=mark) ->
 Clight.eval_expr ge Clight.empty_env(rt_guard_env le top)m rt_guard
 (Vint(if flag then Int.one else Int.zero)).
Proof.
 intros[W[T M]] TR MR Order;unfold rt_guard.
 apply(eval_uint_gt ge Clight.empty_env(rt_guard_env le top)m _t'6 _mark top mark flag);try assumption.
 - unfold rt_guard_env;apply PTree.gss.
 - unfold rt_guard_env;rewrite PTree.gso by discriminate;exact M.
Qed.
Lemma rt_exit_path ge le m bw ow bt ot mark top k:
 rt_env le bw ow bt ot mark ->Mem.loadv Mint32 m(Vptr bt ot)=Some(Vint(Int.repr top)) ->
 0<=top<=Int.max_unsigned ->0<=mark<=Int.max_unsigned ->top<=mark ->
 star Clight.step2 ge(Clight.State f_restore rt_loop k Clight.empty_env le m) E0
 (Clight.State f_restore Sskip k Clight.empty_env(rt_guard_env le top)m).
Proof.
 intros Env Load TR MR Done;unfold rt_loop,rt_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr top)).
 { apply(rt_counter_eval ge le m bw ow bt ot mark _ Env Load). }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
 - apply(rt_guard_eval ge le m bw ow bt ot mark top false);assumption.
 - reflexivity. }
 weight_silent_step. apply Clight.step_break_seq.
 weight_silent_step. apply Clight.step_break_loop1.
 unfold rt_guard_env;apply star_refl.
Qed.
Print Assumptions rt_exit_path.
Section ConcreteLayout.
Variable ge:Clight.genv.
Variable n:Z.
Variables bt bw bf bu:block.
Variables ot ow ofl ou:ptrofs.
Variables df du:Z.
Variable undo:Z->Z.
Variable co:composite.
Hypothesis Composite:PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co.
Hypothesis FlagOffset:Ctypes.field_offset ge _forbidden(co_members co)=Errors.OK(df,Full).
Hypothesis UndoOffset:Ctypes.field_offset ge _undo(co_members co)=Errors.OK(du,Full).
Hypothesis NR:0<=n<=Int.max_unsigned.
Hypothesis UndoRange:forall j,0<=j<n ->0<=undo j<n.
Hypothesis Separate:restore_separation n bt bw bf bu ot ow ofl ou df du.
Let Memory:=restore_memory n bt bw bf bu ot ow ofl ou df du undo.
Theorem rt_continue_path le m top mark k:
 rt_env le bw ow bt ot mark ->Memory m top ->0<=mark /\mark<top /\top<=n ->
 exists m' le',Memory m'(top-1) /\rt_env le' bw ow bt ot mark /\
 star Clight.step2 ge(Clight.State f_restore rt_loop k Clight.empty_env le m) E0
 (Clight.State f_restore rt_loop k Clight.empty_env le' m').
Proof.
 intros Env Memory0 Range;pose proof Env as[W[T M]].
 destruct(restore_memory_decrement n bt bw bf bu ot ow ofl ou df du undo m top
 Separate UndoRange ltac:(lia)Memory0)as[m1[m2[Store1[Store2[Memory1 Memory2]]]]].
 pose proof Memory0 as[Data0[Permissions0 Load0]].
 pose proof Memory1 as[[Flag1[Undo1 Reads1]][Permissions1 Load1]].
 exists m2,(rt_next_env le top bf ofl bu ou(undo(top-1)));split;[exact Memory2|].
 split;[apply rt_next_valid;exact Env|].
 unfold rt_loop,rt_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr top)).
 { apply(rt_counter_eval ge le m bw ow bt ot mark _ Env Load0). }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
 - apply(rt_guard_eval ge le m bw ow bt ot mark top true);try assumption;lia.
 - reflexivity. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 unfold rt_decrement.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr top)).
 { apply(rt_counter_eval ge(rt_guard_env le top)m bw ow bt ot mark _);[unfold rt_env;repeat split;rt_registers|exact Load0]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { apply(defined_assignment_step ge f_restore _ Clight.empty_env
 (rt_dec_env le top)m rt_counter rt_sub bt ot Mint32(Vint(Int.repr(top-1)))(Vint(Int.repr(top-1)))m1).
 - apply lvalue_uint_deref;rt_registers.
 - apply(eval_uint_sub_one ge Clight.empty_env(rt_dec_env le top)m _t'5 top);[unfold rt_dec_env;apply PTree.gss|lia].
 - reflexivity.
 - reflexivity.
 - exact Store1. }
 weight_silent_step. apply Clight.step_skip_seq.
 unfold rt_clear.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr bf ofl).
 { apply(eval_struct_field ge Clight.empty_env(rt_dec_env le top)m1 _w _ccv_workspace
 _forbidden(tptr tuchar)co df Mptr bw ow(Vptr bf ofl));try assumption;[rt_registers|reflexivity]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr bu ou).
 { apply(eval_struct_field ge Clight.empty_env(rt_flag_env le top bf ofl)m1 _w _ccv_workspace
 _undo(tptr tuint)co du Mptr bw ow(Vptr bu ou));try assumption;[rt_registers|reflexivity]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr(top-1))).
 { apply(rt_counter_eval ge(rt_undo_env le top bf ofl bu ou)m1 bw ow bt ot mark _);
 [unfold rt_env;repeat split;rt_registers|exact Load1]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr(undo(top-1)))).
 { apply(eval_uint_index ge Clight.empty_env(rt_index_env le top bf ofl bu ou)m1
 _t'2 _t'3 bu ou(top-1)(Int.repr(undo(top-1))));try(rt_registers);[lia|apply Reads1;lia]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { apply(defined_assignment_step ge f_restore _ Clight.empty_env
 (rt_next_env le top bf ofl bu ou(undo(top-1)))m1 rt_byte(Econst_int(Int.repr 0)tuint)
 bf(restore_flag_pos ofl(undo(top-1)))Mint8unsigned(Vint Int.zero)(Vint Int.zero)m2).
 - apply(lvalue_uchar_index ge Clight.empty_env(rt_next_env le top bf ofl bu ou(undo(top-1)))m1
 _t'1 _t'4 bf ofl(undo(top-1)));try(rt_registers);pose proof(UndoRange(top-1)ltac:(lia));lia.
 - apply Clight.eval_Econst_int.
 - reflexivity.
 - reflexivity.
 - exact Store2. }
 weight_silent_step. apply Clight.step_skip_or_continue_loop1;left;reflexivity.
 weight_silent_step. apply Clight.step_skip_loop2.
 unfold rt_next_env,rt_index_env,rt_undo_env,rt_flag_env,rt_dec_env,rt_guard_env;apply star_refl.
Qed.

Theorem rt_loop_terminates mark k:
 0<=mark<=n ->forall top,mark<=top<=n ->forall m le,
 Memory m top ->rt_env le bw ow bt ot mark ->
 exists m' le',Memory m' mark /\
 star Clight.step2 ge(Clight.State f_restore rt_loop k Clight.empty_env le m) E0
 (Clight.State f_restore Sskip k Clight.empty_env le' m').
Proof.
 intros MR;refine(well_founded_induction_type
 (well_founded_ltof Z(fun j=>Z.to_nat(j-mark))) _ _).
 intros top IH Range m le Mem Env.
 destruct(Z_lt_dec mark top)as[Less|Done].
 - destruct(rt_continue_path le m top mark k Env Mem ltac:(lia))as[m1[le1[Mem1[Env1 Prefix]]]].
   assert(Decrease:(Z.to_nat((top-1)-mark)<Z.to_nat(top-mark))%nat)
    by(apply restore_counter_rank_decreases;lia).
   destruct(IH(top-1)Decrease ltac:(lia)m1 le1 Mem1 Env1)as[m2[le2[Mem2 Tail]]].
   exists m2,le2;split;[exact Mem2|].
   eapply star_trans;[exact Prefix|exact Tail|reflexivity].
 - assert(Eq:top=mark)by lia;subst top.
   exists m,(rt_guard_env le mark);split;[exact Mem|].
   pose proof Mem as[Data[Perm Load]].
   apply(rt_exit_path ge le m bw ow bt ot mark mark k);try assumption;lia.
Qed.
Definition rt_argument_temps mark:=
 PTree.set _mark(Vint(Int.repr mark))(PTree.set _top(Vptr bt ot)
 (PTree.set _w(Vptr bw ow)(Clight.create_undef_temps(fn_temps f_restore)))).
Lemma rt_entry mark m:
 Clight.function_entry2 ge f_restore[Vptr bw ow;Vptr bt ot;Vint(Int.repr mark)]m
 Clight.empty_env(rt_argument_temps mark)m.
Proof.
 constructor.
 - constructor.
 - vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Lemma rt_arguments_valid mark:rt_env(rt_argument_temps mark)bw ow bt ot mark.
Proof.
 unfold rt_env,rt_argument_temps;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;reflexivity.
Qed.
Theorem actual_restore_terminates m top mark k:
 Clight.is_call_cont k ->0<=mark<=top ->top<=n ->Memory m top ->
 exists m',Memory m' mark /\
 star Clight.step2 ge
 (Clight.Callstate(Internal f_restore)[Vptr bw ow;Vptr bt ot;Vint(Int.repr mark)]k m) E0
 (Clight.Returnstate Vundef k m').
Proof.
 intros Call Range Top Mem.
 destruct(rt_loop_terminates mark k ltac:(lia)top ltac:(lia)m(rt_argument_temps mark)
 Mem(rt_arguments_valid mark))as[m'[le'[Mem' Loop]]].
 exists m';split;[exact Mem'|].
 weight_silent_step. apply Clight.step_internal_function;apply rt_entry.
 rewrite rt_body_actual.
 eapply star_trans;[exact Loop| |reflexivity].
 weight_silent_step. { apply Clight.step_skip_call;[exact Call|reflexivity]. }
 apply star_refl.
Qed.
End ConcreteLayout.
Print Assumptions rt_continue_path.
Print Assumptions actual_restore_terminates.
