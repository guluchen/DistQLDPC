(* Operational termination of the actual logical-nontriviality scan.
   Concrete layout and valid-load premises remain explicit, not a parser proof. *)
Require Import VST.floyd.proofauto Coq.Arith.Wf_nat.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Local Transparent tptr tuchar tuint tint typeconv remove_attributes change_attributes Cop.sem_add.
Definition nt_rows:=struct_field_expr _p _ccv_problem _logical_rows tuint.
Definition nt_values:=struct_field_expr _w _ccv_workspace _logical_value(tptr tuchar).
Definition nt_read:=uchar_index_expr _t'1 _i.
Definition nt_guard:=uint_lt_expr _i _t'3.
Definition nt_nonzero:=Ebinop Cop.One(Etempvar _t'2 tuchar)(Econst_int(Int.repr 0)tuint)tint.
Definition nt_return_zero:=Sreturn(Some(Econst_int(Int.repr 0)tint)).
Definition nt_hit:=Sifthenelse nt_nonzero(Sreturn(Some(Econst_int(Int.repr 1)tint)))Sskip.
Definition nt_increment:=Sset _i(Ebinop Oadd(Etempvar _i tuint)(Econst_int(Int.repr 1)tint)tuint).
Definition nt_iteration:=Ssequence(Ssequence(Sset _t'3 nt_rows)(Sifthenelse nt_guard Sskip Sbreak))
 (Ssequence(Sset _t'1 nt_values)(Ssequence(Sset _t'2 nt_read)nt_hit)).
Definition nt_loop:=Sloop nt_iteration nt_increment.
Lemma nt_body_actual:fn_body f_nontrivial=
 Ssequence(Ssequence(Sset _i(Econst_int(Int.repr 0)tuint))nt_loop)nt_return_zero.
Proof. reflexivity. Qed.
Definition nt_env le bp op bw ow i:Prop:=
 PTree.get _p le=Some(Vptr bp op) /\PTree.get _w le=Some(Vptr bw ow) /\
 PTree.get _i le=Some(Vint(Int.repr i)).
Definition nt_memory ge m n bp op bw ow bl ol:Prop:=
 (exists co delta,PTree.get _ccv_problem(Clight.genv_cenv ge)=Some co /\
 Ctypes.field_offset ge _logical_rows(co_members co)=Errors.OK(delta,Full) /\
 Mem.loadv Mint32 m(Vptr bp(Ptrofs.add op(Ptrofs.repr delta)))=Some(Vint(Int.repr n))) /\
 (exists co delta,PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co /\
 Ctypes.field_offset ge _logical_value(co_members co)=Errors.OK(delta,Full) /\
 Mem.loadv Mptr m(Vptr bw(Ptrofs.add ow(Ptrofs.repr delta)))=Some(Vptr bl ol)) /\
 (forall j,0<=j<n ->exists v,Mem.loadv Mint8unsigned m(Vptr bl(Ptrofs.add ol(Ptrofs.repr j)))=Some(Vint v)).
Definition nt_after_rows le n:=PTree.set _t'3(Vint(Int.repr n))le.
Definition nt_before_read le n bl ol:=PTree.set _t'1(Vptr bl ol)(nt_after_rows le n).
Definition nt_after_read le n bl ol v:=PTree.set _t'2(Vint v)(nt_before_read le n bl ol).
Definition nt_next le n bl ol v i:=PTree.set _i(Vint(Int.repr(i+1)))(nt_after_read le n bl ol v).
Lemma nt_next_valid le bp op bw ow i n bl ol v:
 nt_env le bp op bw ow i ->nt_env(nt_next le n bl ol v i)bp op bw ow(i+1).
Proof.
 unfold nt_env,nt_next,nt_after_read,nt_before_read,nt_after_rows;intros[P[W I]].
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);tauto.
Qed.
Lemma nt_rows_eval ge le m n bp op bw ow bl ol i:
 nt_memory ge m n bp op bw ow bl ol ->nt_env le bp op bw ow i ->
 Clight.eval_expr ge Clight.empty_env le m nt_rows(Vint(Int.repr n)).
Proof.
 intros[[co[delta[Composite[Offset Load]]]]Rest][P[W I]];unfold nt_rows.
 apply(eval_struct_field ge Clight.empty_env le m _p _ccv_problem _logical_rows tuint co delta Mint32 bp op(Vint(Int.repr n)));try assumption;reflexivity.
Qed.
Lemma nt_values_eval ge le m n bp op bw ow bl ol i:
 nt_memory ge m n bp op bw ow bl ol ->nt_env le bp op bw ow i ->
 Clight.eval_expr ge Clight.empty_env(nt_after_rows le n)m nt_values(Vptr bl ol).
Proof.
 intros[Rows[[co[delta[Composite[Offset Load]]]]Rest]][P[W I]];unfold nt_values.
 apply(eval_struct_field ge Clight.empty_env(nt_after_rows le n)m _w _ccv_workspace _logical_value(tptr tuchar)co delta Mptr bw ow(Vptr bl ol));try assumption;[|reflexivity].
 unfold nt_after_rows;rewrite PTree.gso by discriminate;exact W.
Qed.
Lemma nt_nonzero_eval ge le m v:
 PTree.get _t'2 le=Some(Vint v) ->
 Clight.eval_expr ge Clight.empty_env le m nt_nonzero
 (Vint(if Int.eq v Int.zero then Int.zero else Int.one)).
Proof.
 intros Value;unfold nt_nonzero.
 eapply Clight.eval_Ebinop with(v1:=Vint v)(v2:=Vint Int.zero).
 - apply Clight.eval_Etempvar;exact Value.
 - apply Clight.eval_Econst_int.
 - change (Some(Val.of_bool(negb(Int.eq v Int.zero)))=
   Some(Vint(if Int.eq v Int.zero then Int.zero else Int.one))).
   destruct(Int.eq v Int.zero);reflexivity.
Qed.
Print Assumptions nt_rows_eval.
Print Assumptions nt_values_eval.
Print Assumptions nt_nonzero_eval.

Lemma nt_guard_eval ge le m n bp op bw ow i(flag:bool):
 nt_env le bp op bw ow i ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->
 (if flag then i<n else n<=i) ->
 Clight.eval_expr ge Clight.empty_env(nt_after_rows le n)m nt_guard
 (Vint(if flag then Int.one else Int.zero)).
Proof.
 intros[P[W I]] IR NR Order;unfold nt_guard.
 apply(eval_uint_lt ge Clight.empty_env(nt_after_rows le n)m _i _t'3 i n flag);try assumption.
 - unfold nt_after_rows;rewrite PTree.gso by discriminate;exact I.
 - unfold nt_after_rows;apply PTree.gss.
Qed.
Lemma nt_read_eval ge le m n bp op bw ow bl ol i v:
 nt_env le bp op bw ow i ->0<=i<=Int.max_unsigned ->
 Mem.loadv Mint8unsigned m(Vptr bl(Ptrofs.add ol(Ptrofs.repr i)))=Some(Vint v) ->
 Clight.eval_expr ge Clight.empty_env(nt_before_read le n bl ol)m nt_read(Vint v).
Proof.
 intros[P[W I]] Range Load;unfold nt_read.
 apply(eval_uchar_index ge Clight.empty_env(nt_before_read le n bl ol)m _t'1 _i bl ol i v);try assumption.
 - unfold nt_before_read;apply PTree.gss.
 - unfold nt_before_read,nt_after_rows;rewrite !PTree.gso by discriminate;exact I.
Qed.
Lemma nt_scan_read_path ge le m n bp op bw ow bl ol i v k:
 nt_memory ge m n bp op bw ow bl ol ->nt_env le bp op bw ow i ->
 0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->i<n ->
 Mem.loadv Mint8unsigned m(Vptr bl(Ptrofs.add ol(Ptrofs.repr i)))=Some(Vint v) ->
 star Clight.step2 ge
 (Clight.State f_nontrivial nt_loop k Clight.empty_env le m) E0
 (Clight.State f_nontrivial nt_hit(Kloop1 nt_iteration nt_increment k)
  Clight.empty_env(nt_after_read le n bl ol v)m).
Proof.
 intros Memory Env IR NR Less Load;unfold nt_loop,nt_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr n)).
 { apply(nt_rows_eval ge le m n bp op bw ow bl ol i Memory Env). }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
 - apply(nt_guard_eval ge le m n bp op bw ow i true);assumption.
 - reflexivity. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr bl ol).
 { apply(nt_values_eval ge le m n bp op bw ow bl ol i Memory Env). }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint v).
 { apply(nt_read_eval ge le m n bp op bw ow bl ol i v Env IR Load). }
 weight_silent_step. apply Clight.step_skip_seq.
 unfold nt_after_read,nt_before_read,nt_after_rows;apply star_refl.
Qed.
Lemma nt_exit_path ge le m n bp op bw ow bl ol i k:
 nt_memory ge m n bp op bw ow bl ol ->nt_env le bp op bw ow i ->
 0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->n<=i ->
 star Clight.step2 ge
 (Clight.State f_nontrivial nt_loop k Clight.empty_env le m) E0
 (Clight.State f_nontrivial Sskip k Clight.empty_env(nt_after_rows le n)m).
Proof.
 intros Memory Env IR NR Done;unfold nt_loop,nt_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr n)).
 { apply(nt_rows_eval ge le m n bp op bw ow bl ol i Memory Env). }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
 - apply(nt_guard_eval ge le m n bp op bw ow i false);assumption.
 - reflexivity. }
 weight_silent_step. apply Clight.step_break_seq.
 weight_silent_step. apply Clight.step_break_loop1.
 unfold nt_after_rows;apply star_refl.
Qed.
Print Assumptions nt_scan_read_path.
Print Assumptions nt_exit_path.

Lemma nt_continue_path ge le m n bp op bw ow bl ol i v k:
 nt_memory ge m n bp op bw ow bl ol ->nt_env le bp op bw ow i ->
 0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->i<n ->
 Mem.loadv Mint8unsigned m(Vptr bl(Ptrofs.add ol(Ptrofs.repr i)))=Some(Vint v) ->
 Int.eq v Int.zero=true ->
 star Clight.step2 ge
 (Clight.State f_nontrivial nt_loop k Clight.empty_env le m) E0
 (Clight.State f_nontrivial nt_loop k Clight.empty_env(nt_next le n bl ol v i)m).
Proof.
 intros Memory Env IR NR Less Load Zero;pose proof Env as[P[W I]].
 assert(Add:Int.add(Int.repr i)(Int.repr 1)=Int.repr(i+1)).
 { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 eapply star_trans.
 - apply(nt_scan_read_path ge le m n bp op bw ow bl ol i v k);assumption.
 - unfold nt_hit,nt_increment.
   weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
   + pose proof(nt_nonzero_eval ge(nt_after_read le n bl ol v)m v
       ltac:(unfold nt_after_read;apply PTree.gss))as Condition.
     rewrite Zero in Condition;exact Condition.
   + reflexivity. }
   weight_silent_step. apply Clight.step_skip_or_continue_loop1;left;reflexivity.
   weight_silent_step. { eapply Clight.step_set with(v:=Vint(Int.repr(i+1))).
   eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr 1)).
   + apply Clight.eval_Etempvar;unfold nt_after_read,nt_before_read,nt_after_rows;
     rewrite !PTree.gso by discriminate;exact I.
   + apply Clight.eval_Econst_int.
   + change (Some(Vint(Int.add(Int.repr i)(Int.repr 1)))=Some(Vint(Int.repr(i+1))));rewrite Add;reflexivity. }
   weight_silent_step. apply Clight.step_skip_loop2.
   unfold nt_loop,nt_increment,nt_next;apply star_refl.
 - reflexivity.
Qed.
Lemma nt_hit_path ge le m n bp op bw ow bl ol i v k:
 nt_memory ge m n bp op bw ow bl ol ->nt_env le bp op bw ow i ->
 0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->i<n ->
 Mem.loadv Mint8unsigned m(Vptr bl(Ptrofs.add ol(Ptrofs.repr i)))=Some(Vint v) ->
 Int.eq v Int.zero=false ->
 star Clight.step2 ge
 (Clight.State f_nontrivial nt_loop k Clight.empty_env le m) E0
 (Clight.Returnstate(Vint Int.one)(Clight.call_cont k)m).
Proof.
 intros Memory Env IR NR Less Load Nonzero.
 eapply star_trans.
 - apply(nt_scan_read_path ge le m n bp op bw ow bl ol i v k);assumption.
 - unfold nt_hit.
   weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
   + pose proof(nt_nonzero_eval ge(nt_after_read le n bl ol v)m v
       ltac:(unfold nt_after_read;apply PTree.gss))as Condition.
     rewrite Nonzero in Condition;exact Condition.
   + reflexivity. }
   weight_silent_step. { eapply Clight.step_return_1 with(v:=Vint Int.one).
   + apply Clight.eval_Econst_int.
   + reflexivity.
   + reflexivity. }
   apply star_refl.
 - reflexivity.
Qed.
Lemma nt_zero_return_path ge le m k:
 star Clight.step2 ge
 (Clight.State f_nontrivial Sskip(Kseq nt_return_zero k)Clight.empty_env le m) E0
 (Clight.Returnstate(Vint Int.zero)(Clight.call_cont k)m).
Proof.
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { unfold nt_return_zero;eapply Clight.step_return_1 with(v:=Vint Int.zero).
 - apply Clight.eval_Econst_int.
 - reflexivity.
 - reflexivity. }
 apply star_refl.
Qed.
Theorem nt_loop_terminates ge m n bp op bw ow bl ol k:
 0<=n<=Int.max_unsigned ->nt_memory ge m n bp op bw ow bl ol ->
 forall i,0<=i<=n ->forall le,nt_env le bp op bw ow i ->
 exists result,(result=Int.zero \/result=Int.one) /\
 star Clight.step2 ge
 (Clight.State f_nontrivial nt_loop(Kseq nt_return_zero k)Clight.empty_env le m) E0
 (Clight.Returnstate(Vint result)(Clight.call_cont k)m).
Proof.
 intros NR Memory;pose proof Memory as[Rows[Values Reads]].
 refine(well_founded_induction_type(well_founded_ltof Z(fun j=>Z.to_nat(n-j))) _ _).
 intros i IH Range le Env.
 destruct(Z_lt_dec i n)as[Less|Done].
 - destruct(Reads i ltac:(lia))as[v Load].
   destruct(Int.eq v Int.zero)eqn:Value.
   + assert(Decrease:(Z.to_nat(n-(i+1))<Z.to_nat(n-i))%nat)by(apply Z2Nat.inj_lt;lia).
     pose proof(nt_next_valid le bp op bw ow i n bl ol v Env)as Next.
     destruct(IH(i+1)Decrease ltac:(lia)(nt_next le n bl ol v i)Next)as[result[Result Tail]].
     exists result;split;[exact Result|].
     eapply star_trans.
     * apply(nt_continue_path ge le m n bp op bw ow bl ol i v(Kseq nt_return_zero k));try assumption;lia.
     * exact Tail.
     * reflexivity.
   + exists Int.one;split;[right;reflexivity|].
     apply(nt_hit_path ge le m n bp op bw ow bl ol i v(Kseq nt_return_zero k));try assumption;lia.
 - exists Int.zero;split;[left;reflexivity|].
   eapply star_trans.
   + apply(nt_exit_path ge le m n bp op bw ow bl ol i(Kseq nt_return_zero k));try assumption;lia.
   + apply nt_zero_return_path.
   + reflexivity.
Qed.
Definition nt_argument_temps bp op bw ow:=
 PTree.set _w(Vptr bw ow)(PTree.set _p(Vptr bp op)(Clight.create_undef_temps(fn_temps f_nontrivial))).
Definition nt_started_temps bp op bw ow:=PTree.set _i(Vint(Int.repr 0))(nt_argument_temps bp op bw ow).
Lemma nt_function_entry ge bp op bw ow m:
 Clight.function_entry2 ge f_nontrivial[Vptr bp op;Vptr bw ow]m
 Clight.empty_env(nt_argument_temps bp op bw ow)m.
Proof.
 constructor.
 - constructor.
 - vm_compute. repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Lemma nt_started_env bp op bw ow:nt_env(nt_started_temps bp op bw ow)bp op bw ow 0.
Proof.
 unfold nt_env,nt_started_temps,nt_argument_temps.
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;reflexivity.
Qed.
Lemma nt_start_path ge bp op bw ow m k:
 star Clight.step2 ge
 (Clight.Callstate(Internal f_nontrivial)[Vptr bp op;Vptr bw ow]k m) E0
 (Clight.State f_nontrivial nt_loop(Kseq nt_return_zero k)Clight.empty_env(nt_started_temps bp op bw ow)m).
Proof.
 weight_silent_step. apply Clight.step_internal_function;apply nt_function_entry.
 rewrite nt_body_actual.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_set;apply Clight.eval_Econst_int.
 weight_silent_step. apply Clight.step_skip_seq.
 unfold nt_started_temps;apply star_refl.
Qed.
Theorem actual_nontrivial_terminates ge m n bp op bw ow bl ol k:
 0<=n<=Int.max_unsigned ->nt_memory ge m n bp op bw ow bl ol ->
 exists result,(result=Int.zero \/result=Int.one) /\
 star Clight.step2 ge
 (Clight.Callstate(Internal f_nontrivial)[Vptr bp op;Vptr bw ow]k m) E0
 (Clight.Returnstate(Vint result)(Clight.call_cont k)m).
Proof.
 intros NR Memory.
 destruct(nt_loop_terminates ge m n bp op bw ow bl ol k NR Memory
 0 ltac:(lia)(nt_started_temps bp op bw ow)(nt_started_env bp op bw ow))as[result[Result Loop]].
 exists result;split;[exact Result|].
 eapply star_trans;[apply nt_start_path|exact Loop|reflexivity].
Qed.
Print Assumptions nt_continue_path.
Print Assumptions nt_hit_path.
Print Assumptions nt_loop_terminates.
Print Assumptions actual_nontrivial_terminates.
