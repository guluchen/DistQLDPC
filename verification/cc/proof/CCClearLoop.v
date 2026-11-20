(* Concrete metadata-bounded clear loop. The bound is physically reloaded on
   every iteration and remains unchanged through protected byte stores. *)
Require Import VST.floyd.proofauto Coq.Arith.Wf_nat.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCProtectedByteStores CCV.CCClearControl
 CCV.CCClearPackets CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition clear_bound_layout ge bp op cells co delta temp field bound:Prop:=
 temp<>_p /\temp<>_w /\temp<>_out /\temp<>_i /\
 PTree.get _ccv_problem(Clight.genv_cenv ge)=Some co /\
 Ctypes.field_offset ge field(co_members co)=Errors.OK(delta,Full) /\
 In {|cpr_chunk:=Mint32;cpr_block:=bp;cpr_offset:=Ptrofs.add op(Ptrofs.repr delta);
 cpr_value:=Vint(Int.repr bound)|}cells.
Lemma clear_scratch_env le bp op bw ow bo oout i temp v:
 temp<>_p ->temp<>_w ->temp<>_out ->temp<>_i ->clear_env le bp op bw ow bo oout i ->
 clear_env(PTree.set temp v le)bp op bw ow bo oout i.
Proof. intros NP NW NO NI[P[W[O I]]];unfold clear_env;rewrite !PTree.gso by congruence;repeat split;assumption. Qed.
Lemma clear_increment_env le bp op bw ow bo oout i:
 clear_env le bp op bw ow bo oout i ->
 clear_env(PTree.set _i(Vint(Int.repr(i+1)))le)bp op bw ow bo oout(i+1).
Proof.
 intros[P[W[O I]]];unfold clear_env;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;assumption.
Qed.
Lemma clear_bound_eval ge bp op bw ow bo oout cells co delta temp field bound le m i:
 clear_bound_layout ge bp op cells co delta temp field bound ->cp_reads m cells ->
 clear_env le bp op bw ow bo oout i ->
 Clight.eval_expr ge Clight.empty_env le m(clear_bound temp field)(Vint(Int.repr bound)).
Proof.
 intros[NP[NW[NO[NI[Composite[Offset Cell]]]]]]Reads[P[W[O I]]].
 pose proof(cp_load_member m cells
 {|cpr_chunk:=Mint32;cpr_block:=bp;cpr_offset:=Ptrofs.add op(Ptrofs.repr delta);
 cpr_value:=Vint(Int.repr bound)|}Reads Cell)as Load;cbn in Load.
 apply(eval_struct_field ge Clight.empty_env le m _p _ccv_problem field tuint
 co delta Mint32 bp op(Vint(Int.repr bound)));try assumption;reflexivity.
Qed.
Lemma clear_probe_path ge bp op bw ow bo oout cells co delta temp field bound ds le m i k:
 clear_bound_layout ge bp op cells co delta temp field bound ->cp_reads m cells ->
 clear_env le bp op bw ow bo oout i ->
 star Clight.step2 ge(Clight.State f_clear(clear_loop temp field ds)k Clight.empty_env le m)E0
 (Clight.State f_clear(Sifthenelse(uint_lt_expr _i temp)Sskip Sbreak)
 (Kseq(clear_packet ds)(Kloop1(clear_iteration temp field ds)weight_increment k))
 Clight.empty_env(PTree.set temp(Vint(Int.repr bound))le)m).
Proof.
 intros Layout Reads Env;unfold clear_loop,clear_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr bound)).
 { apply(clear_bound_eval ge bp op bw ow bo oout cells co delta temp field bound le m i);assumption. }
 weight_silent_step. apply Clight.step_skip_seq.
 apply star_refl.
Qed.
Lemma clear_guard_eval ge bp op bw ow bo oout cells co delta temp field bound le m i(flag:bool):
 clear_bound_layout ge bp op cells co delta temp field bound ->clear_env le bp op bw ow bo oout i ->
 0<=i<=Int.max_unsigned ->0<=bound<=Int.max_unsigned ->(if flag then i<bound else bound<=i) ->
 Clight.eval_expr ge Clight.empty_env(PTree.set temp(Vint(Int.repr bound))le)m
 (uint_lt_expr _i temp)(Vint(if flag then Int.one else Int.zero)).
Proof.
 intros[NP[NW[NO[NI Rest]]]][P[W[O I]]] IR BR Order.
 apply(eval_uint_lt ge Clight.empty_env(PTree.set temp(Vint(Int.repr bound))le)m _i temp i bound flag);try assumption.
 - rewrite PTree.gso by congruence;exact I.
 - apply PTree.gss.
Qed.
Theorem clear_continue_path ge bp op bw ow bo oout cells areas cp dp cw dw temp field bound ds le m i k:
 clear_bound_layout ge bp op cells cp dp temp field bound ->
 (forall d,In d ds ->clear_slot_layout ge bw ow bo oout cells areas cw dw d) ->
 (forall d,In d ds ->bound<=cpa_size(cd_area d)) ->
 clear_env le bp op bw ow bo oout i ->0<=i<bound ->0<=bound<=Int.max_unsigned ->
 cp_reads m cells ->cp_writables m areas ->cp_separation cells areas ->
 exists le' m',clear_env le' bp op bw ow bo oout(i+1) /\cp_reads m' cells /\cp_writables m' areas /\
 star Clight.step2 ge(Clight.State f_clear(clear_loop temp field ds)k Clight.empty_env le m)E0
 (Clight.State f_clear(clear_loop temp field ds)k Clight.empty_env le' m').
Proof.
 intros Bound Slots Sizes Env Range BR Reads Writable Apart.
 pose proof Bound as[NP[NW[NO[NI Rest]]]].
 pose proof(clear_scratch_env le bp op bw ow bo oout i temp(Vint(Int.repr bound))NP NW NO NI Env)as BoundEnv.
 destruct(clear_packet_terminates ge bp op bw ow bo oout cells areas cw dw ds Slots i ltac:(lia)
 ltac:(intros d Member;pose proof(Sizes d Member);lia)(PTree.set temp(Vint(Int.repr bound))le)m
 (Kloop1(clear_iteration temp field ds)weight_increment k)BoundEnv Reads Writable Apart)
 as[le1[m1[Env1[Reads1[Writable1 Packet]]]]].
 exists(PTree.set _i(Vint(Int.repr(i+1)))le1),m1;split;[apply clear_increment_env;exact Env1|].
 split;[exact Reads1|];split;[exact Writable1|].
 eapply star_trans.
 - apply(clear_probe_path ge bp op bw ow bo oout cells cp dp temp field bound ds le m i k);assumption.
 - weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
   + apply(clear_guard_eval ge bp op bw ow bo oout cells cp dp temp field bound le m i true);try assumption;lia.
   + reflexivity. }
   weight_silent_step. apply Clight.step_skip_seq.
   eapply star_trans;[exact Packet| |reflexivity].
   weight_silent_step. apply Clight.step_skip_or_continue_loop1;left;reflexivity.
   eapply star_step with(t1:=E0)(t2:=E0).
   + apply(clear_increment_step ge le1 m1 _ bp op bw ow bo oout i Env1);lia.
   + weight_silent_step. apply Clight.step_skip_loop2.
     apply star_refl.
   + reflexivity.
 - reflexivity.
Qed.
Lemma clear_exit_path ge bp op bw ow bo oout cells cp dp temp field bound ds le m i k:
 clear_bound_layout ge bp op cells cp dp temp field bound ->clear_env le bp op bw ow bo oout i ->
 0<=i<=Int.max_unsigned ->0<=bound<=Int.max_unsigned ->bound<=i ->cp_reads m cells ->
 star Clight.step2 ge(Clight.State f_clear(clear_loop temp field ds)k Clight.empty_env le m)E0
 (Clight.State f_clear Sskip k Clight.empty_env(PTree.set temp(Vint(Int.repr bound))le)m).
Proof.
 intros Bound Env IR BR Done Reads.
 eapply star_trans.
 - apply(clear_probe_path ge bp op bw ow bo oout cells cp dp temp field bound ds le m i k);assumption.
 - weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
   + apply(clear_guard_eval ge bp op bw ow bo oout cells cp dp temp field bound le m i false);assumption.
   + reflexivity. }
   weight_silent_step. apply Clight.step_break_seq.
   weight_silent_step. apply Clight.step_break_loop1.
   apply star_refl.
 - reflexivity.
Qed.
Print Assumptions clear_continue_path.
Print Assumptions clear_exit_path.
Theorem clear_loop_terminates ge bp op bw ow bo oout cells areas cp dp cw dw temp field bound ds:
 clear_bound_layout ge bp op cells cp dp temp field bound ->
 (forall d,In d ds ->clear_slot_layout ge bw ow bo oout cells areas cw dw d) ->
 (forall d,In d ds ->bound<=cpa_size(cd_area d)) ->0<=bound<=Int.max_unsigned ->
 forall i,0<=i<=bound ->forall le m k,clear_env le bp op bw ow bo oout i ->
 cp_reads m cells ->cp_writables m areas ->cp_separation cells areas ->
 exists le' m',clear_env le' bp op bw ow bo oout bound /\cp_reads m' cells /\cp_writables m' areas /\
 star Clight.step2 ge(Clight.State f_clear(clear_loop temp field ds)k Clight.empty_env le m)E0
 (Clight.State f_clear Sskip k Clight.empty_env le' m').
Proof.
 intros Bound Slots Sizes BR;refine(well_founded_induction_type
 (well_founded_ltof Z(fun j=>Z.to_nat(bound-j))) _ _).
 intros i IH Range le m k Env Reads Writable Apart;destruct(Z_lt_dec i bound)as[Less|Done].
 - destruct(clear_continue_path ge bp op bw ow bo oout cells areas cp dp cw dw temp field bound ds le m i k
 Bound Slots Sizes Env ltac:(lia)BR Reads Writable Apart)as[le1[m1[Env1[Reads1[Writable1 Prefix]]]]].
 assert(Decrease:(Z.to_nat(bound-(i+1))<Z.to_nat(bound-i))%nat)by(apply Z2Nat.inj_lt;lia).
 destruct(IH(i+1)Decrease ltac:(lia)le1 m1 k Env1 Reads1 Writable1 Apart)
 as[le2[m2[Env2[Reads2[Writable2 Tail]]]]].
 exists le2,m2;split;[exact Env2|];split;[exact Reads2|];split;[exact Writable2|].
 eapply star_trans;[exact Prefix|exact Tail|reflexivity].
 - assert(Eq:i=bound)by lia;subst i.
 exists(PTree.set temp(Vint(Int.repr bound))le),m;split.
 + destruct Bound as[NP[NW[NO[NI Rest]]]];apply clear_scratch_env;assumption.
 + split;[exact Reads|];split;[exact Writable|].
   apply(clear_exit_path ge bp op bw ow bo oout cells cp dp temp field bound ds le m bound k);try assumption;lia.
Qed.
Definition clear_globals le bp op bw ow bo oout:Prop:=
 PTree.get _p le=Some(Vptr bp op) /\PTree.get _w le=Some(Vptr bw ow) /\PTree.get _out le=Some(Vptr bo oout).
Lemma clear_env_globals le bp op bw ow bo oout i:
 clear_env le bp op bw ow bo oout i ->clear_globals le bp op bw ow bo oout.
Proof. intros[P[W[O I]]];repeat split;assumption. Qed.
Lemma clear_zero_index le bp op bw ow bo oout:
 clear_globals le bp op bw ow bo oout ->clear_env(PTree.set _i(Vint Int.zero)le)bp op bw ow bo oout 0.
Proof.
 intros[P[W O]];unfold clear_env;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;assumption.
Qed.
Theorem clear_stage_terminates ge bp op bw ow bo oout cells areas cp dp cw dw temp field bound ds le m k:
 clear_bound_layout ge bp op cells cp dp temp field bound ->
 (forall d,In d ds ->clear_slot_layout ge bw ow bo oout cells areas cw dw d) ->
 (forall d,In d ds ->bound<=cpa_size(cd_area d)) ->0<=bound<=Int.max_unsigned ->
 clear_globals le bp op bw ow bo oout ->cp_reads m cells ->cp_writables m areas ->cp_separation cells areas ->
 exists le' m',clear_env le' bp op bw ow bo oout bound /\cp_reads m' cells /\cp_writables m' areas /\
 star Clight.step2 ge(Clight.State f_clear(clear_stage temp field ds)k Clight.empty_env le m)E0
 (Clight.State f_clear Sskip k Clight.empty_env le' m').
Proof.
 intros Bound Slots Sizes BR Globals Reads Writable Apart.
 destruct(clear_loop_terminates ge bp op bw ow bo oout cells areas cp dp cw dw temp field bound ds
 Bound Slots Sizes BR 0 ltac:(lia)(PTree.set _i(Vint Int.zero)le)m k
 (clear_zero_index le bp op bw ow bo oout Globals)Reads Writable Apart)
 as[le'[m'[Env'[Reads'[Writable' Loop]]]]].
 exists le',m';split;[exact Env'|];split;[exact Reads'|];split;[exact Writable'|].
 unfold clear_stage.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_set;apply Clight.eval_Econst_int.
 weight_silent_step. apply Clight.step_skip_seq.
 exact Loop.
Qed.
Print Assumptions clear_loop_terminates.
Print Assumptions clear_stage_terminates.
