(* Actual two-array dot loop: defined byte reads suffice for finite execution.
   Functional dot-product correctness is proved separately by its VST body. *)
Require Import VST.floyd.proofauto Coq.Arith.Wf_nat.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCTerminateWeight CCV.ccv_primitives.
Import ListNotations. Open Scope Z_scope.
Definition dot_read_a:=uchar_index_expr _a _i.
Definition dot_read_b:=uchar_index_expr _b _i.
Definition dot_update:=Ebinop Oxor(Etempvar _x tuint)
 (Ebinop Oand(Ecast(Etempvar _t'1 tuchar)tuint)(Ecast(Etempvar _t'2 tuchar)tuint)tuint)tuint.
Definition dot_iteration:=Ssequence(Sifthenelse weight_guard Sskip Sbreak)
 (Ssequence(Sset _t'1 dot_read_a)(Ssequence(Sset _t'2 dot_read_b)(Sset _x dot_update))).
Definition dot_loop:=Sloop dot_iteration weight_increment.
Definition dot_return:=Sreturn(Some(Etempvar _x tuint)).
Lemma dot_body_actual:fn_body f_ccv_dot=
 Ssequence(Sset _x(Econst_int(Int.repr 0)tuint))
 (Ssequence(Ssequence(Sset _i(Econst_int(Int.repr 0)tuint))dot_loop)dot_return).
Proof. reflexivity. Qed.
Definition dot_env le n ba oa bb ob i x:Prop:=
 PTree.get _n le=Some(Vint(Int.repr n)) /\PTree.get _a le=Some(Vptr ba oa) /\
 PTree.get _b le=Some(Vptr bb ob) /\PTree.get _i le=Some(Vint(Int.repr i)) /\
 PTree.get _x le=Some(Vint x).
Definition dot_after_a le va:=PTree.set _t'1(Vint va)le.
Definition dot_after_b le va vb:=PTree.set _t'2(Vint vb)(dot_after_a le va).
Definition dot_next le i x va vb:=PTree.set _i(Vint(Int.repr(i+1)))
 (PTree.set _x(Vint(Int.xor x(Int.and va vb)))(dot_after_b le va vb)).
Ltac dot_registers:=unfold dot_next,dot_after_b,dot_after_a;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);first[assumption|reflexivity].
Lemma dot_next_valid le n ba oa bb ob i x va vb:
 dot_env le n ba oa bb ob i x ->
 dot_env(dot_next le i x va vb)n ba oa bb ob(i+1)(Int.xor x(Int.and va vb)).
Proof. intros[N[A[B[I X]]]];unfold dot_env;repeat split;dot_registers. Qed.
Lemma dot_guard_eval ge le m n ba oa bb ob i x(flag:bool):
 dot_env le n ba oa bb ob i x ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->
 (if flag then i<n else n<=i) ->
 Clight.eval_expr ge Clight.empty_env le m weight_guard(Vint(if flag then Int.one else Int.zero)).
Proof.
 intros[N[A[B[I X]]]] IR NR Order.
 apply(eval_uint_lt ge Clight.empty_env le m _i _n i n flag);assumption.
Qed.
Lemma dot_continue_path ge le m n ba oa bb ob i x va vb k:
 dot_env le n ba oa bb ob i x ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->i<n ->
 Mem.loadv Mint8unsigned m(Vptr ba(Ptrofs.add oa(Ptrofs.repr i)))=Some(Vint va) ->
 Mem.loadv Mint8unsigned m(Vptr bb(Ptrofs.add ob(Ptrofs.repr i)))=Some(Vint vb) ->
 star Clight.step2 ge(Clight.State f_ccv_dot dot_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_dot dot_loop k Clight.empty_env(dot_next le i x va vb)m).
Proof.
 intros Env IR NR Less LoadA LoadB;pose proof Env as[N[A[B[I X]]]].
 assert(Add:Int.add(Int.repr i)(Int.repr 1)=Int.repr(i+1)).
 { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 unfold dot_loop,dot_iteration,weight_increment,dot_update.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
 - apply(dot_guard_eval ge le m n ba oa bb ob i x true);assumption.
 - reflexivity. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint va).
 { apply(eval_uchar_index ge Clight.empty_env le m _a _i ba oa i va);assumption. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint vb).
 { apply(eval_uchar_index ge Clight.empty_env(dot_after_a le va)m _b _i bb ob i vb);try assumption;dot_registers. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.xor x(Int.and va vb))).
 { eapply Clight.eval_Ebinop with(v1:=Vint x)(v2:=Vint(Int.and va vb)).
 - apply Clight.eval_Etempvar;dot_registers.
 - eapply Clight.eval_Ebinop with(v1:=Vint va)(v2:=Vint vb).
   + eapply Clight.eval_Ecast with(v1:=Vint va);[apply Clight.eval_Etempvar;dot_registers|reflexivity].
   + eapply Clight.eval_Ecast with(v1:=Vint vb);[apply Clight.eval_Etempvar;dot_registers|reflexivity].
   + reflexivity.
 - reflexivity. }
 weight_silent_step. apply Clight.step_skip_or_continue_loop1;left;reflexivity.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr(i+1))).
 { eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr 1)).
 - apply Clight.eval_Etempvar;rewrite !PTree.gso by discriminate;exact I.
 - apply Clight.eval_Econst_int.
 - change(Some(Vint(Int.add(Int.repr i)(Int.repr 1)))=Some(Vint(Int.repr(i+1))));rewrite Add;reflexivity. }
 weight_silent_step. apply Clight.step_skip_loop2.
 unfold dot_next,dot_after_b,dot_after_a;apply star_refl.
Qed.
Lemma dot_exit_path ge le m n ba oa bb ob i x k:
 dot_env le n ba oa bb ob i x ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->n<=i ->
 star Clight.step2 ge(Clight.State f_ccv_dot dot_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_dot Sskip k Clight.empty_env le m).
Proof.
 intros Env IR NR Done;unfold dot_loop,dot_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
 - apply(dot_guard_eval ge le m n ba oa bb ob i x false);assumption.
 - reflexivity. }
 weight_silent_step. apply Clight.step_break_seq.
 weight_silent_step. apply Clight.step_break_loop1.
 apply star_refl.
Qed.
Theorem actual_dot_loop_terminates ge m n ba oa bb ob k:
 0<=n<=Int.max_unsigned ->
 (forall j,0<=j<n ->exists va vb,
 Mem.loadv Mint8unsigned m(Vptr ba(Ptrofs.add oa(Ptrofs.repr j)))=Some(Vint va) /\
 Mem.loadv Mint8unsigned m(Vptr bb(Ptrofs.add ob(Ptrofs.repr j)))=Some(Vint vb)) ->
 forall i,0<=i<=n ->forall x le,dot_env le n ba oa bb ob i x ->
 exists le' x',star Clight.step2 ge(Clight.State f_ccv_dot dot_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_dot Sskip k Clight.empty_env le' m) /\dot_env le' n ba oa bb ob n x'.
Proof.
 intros NR Reads;refine(well_founded_induction_type(well_founded_ltof Z(fun j=>Z.to_nat(n-j))) _ _).
 intros i IH Range x le Env;destruct(Z_lt_dec i n)as[Less|Done].
 - destruct(Reads i ltac:(lia))as[va[vb[LoadA LoadB]]].
   assert(Decrease:(Z.to_nat(n-(i+1))<Z.to_nat(n-i))%nat)by(apply Z2Nat.inj_lt;lia).
   pose proof(dot_next_valid le n ba oa bb ob i x va vb Env)as Next.
   destruct(IH(i+1)Decrease ltac:(lia)(Int.xor x(Int.and va vb))(dot_next le i x va vb)Next)
   as[le'[x'[Tail Final]]].
   exists le',x';split;[|exact Final].
   eapply star_trans;[apply(dot_continue_path ge le m n ba oa bb ob i x va vb k);try assumption;lia|exact Tail|reflexivity].
 - exists le,x;split.
   + apply(dot_exit_path ge le m n ba oa bb ob i x k);try assumption;lia.
   + assert(Eq:i=n)by lia;subst i;exact Env.
Qed.
Definition dot_argument_temps n ba oa bb ob:=PTree.set _b(Vptr bb ob)
 (PTree.set _a(Vptr ba oa)(PTree.set _n(Vint(Int.repr n))(Clight.create_undef_temps(fn_temps f_ccv_dot)))).
Definition dot_started_temps n ba oa bb ob:=PTree.set _i(Vint(Int.repr 0))
 (PTree.set _x(Vint(Int.repr 0))(dot_argument_temps n ba oa bb ob)).
Lemma dot_entry ge n ba oa bb ob m:
 Clight.function_entry2 ge f_ccv_dot[Vint(Int.repr n);Vptr ba oa;Vptr bb ob]m
 Clight.empty_env(dot_argument_temps n ba oa bb ob)m.
Proof.
 constructor.
 - constructor.
 - vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Lemma dot_started_valid n ba oa bb ob:dot_env(dot_started_temps n ba oa bb ob)n ba oa bb ob 0 Int.zero.
Proof.
 unfold dot_env,dot_started_temps,dot_argument_temps;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;reflexivity.
Qed.
Lemma dot_start_path ge n ba oa bb ob m k:
 star Clight.step2 ge
 (Clight.Callstate(Internal f_ccv_dot)[Vint(Int.repr n);Vptr ba oa;Vptr bb ob]k m) E0
 (Clight.State f_ccv_dot dot_loop(Kseq dot_return k)Clight.empty_env(dot_started_temps n ba oa bb ob)m).
Proof.
 weight_silent_step. apply Clight.step_internal_function;apply dot_entry.
 rewrite dot_body_actual.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_set;apply Clight.eval_Econst_int.
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_set;apply Clight.eval_Econst_int.
 weight_silent_step. apply Clight.step_skip_seq.
 unfold dot_started_temps,dot_return;apply star_refl.
Qed.
Lemma dot_return_path ge le m n ba oa bb ob x k:
 dot_env le n ba oa bb ob n x ->
 star Clight.step2 ge(Clight.State f_ccv_dot Sskip(Kseq dot_return k)Clight.empty_env le m) E0
 (Clight.Returnstate(Vint x)(Clight.call_cont k)m).
Proof.
 intros[N[A[B[I X]]]].
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { unfold dot_return;eapply Clight.step_return_1 with(v:=Vint x).
 - apply Clight.eval_Etempvar;exact X.
 - reflexivity.
 - reflexivity. }
 apply star_refl.
Qed.
Theorem actual_dot_terminates ge m n ba oa bb ob k:
 0<=n<=Int.max_unsigned ->
 (forall j,0<=j<n ->exists va vb,
 Mem.loadv Mint8unsigned m(Vptr ba(Ptrofs.add oa(Ptrofs.repr j)))=Some(Vint va) /\
 Mem.loadv Mint8unsigned m(Vptr bb(Ptrofs.add ob(Ptrofs.repr j)))=Some(Vint vb)) ->
 exists x,star Clight.step2 ge
 (Clight.Callstate(Internal f_ccv_dot)[Vint(Int.repr n);Vptr ba oa;Vptr bb ob]k m) E0
 (Clight.Returnstate(Vint x)(Clight.call_cont k)m).
Proof.
 intros NR Reads.
 destruct(actual_dot_loop_terminates ge m n ba oa bb ob(Kseq dot_return k)NR Reads
 0 ltac:(lia)Int.zero(dot_started_temps n ba oa bb ob)(dot_started_valid n ba oa bb ob))
 as[le[x[Loop Env]]].
 exists x;eapply star_trans;[apply dot_start_path| |reflexivity].
 eapply star_trans;[exact Loop|apply(dot_return_path ge le m n ba oa bb ob x k Env)|reflexivity].
Qed.
Print Assumptions actual_dot_terminates.
