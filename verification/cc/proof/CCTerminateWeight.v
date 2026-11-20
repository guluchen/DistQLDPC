(* Operational termination groundwork for the actual frozen weight loop.
   No whole-search/library termination claim. *)
Require Import VST.floyd.proofauto.
Require Import Coq.Arith.Wf_nat.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.ccv_primitives.
Import ListNotations. Open Scope Z_scope.
Local Transparent tptr tuchar tuint tint typeconv remove_attributes change_attributes Cop.sem_add.
Definition weight_guard:=Ebinop Olt(Etempvar _i tuint)(Etempvar _n tuint)tint.
Definition weight_read:=Ederef(Ebinop Oadd(Etempvar _a(tptr tuchar))(Etempvar _i tuint)(tptr tuchar))tuchar.
Definition weight_add:=Ebinop Oadd(Etempvar _x tuint)(Ecast(Etempvar _t'1 tuchar)tuint)tuint.
Definition weight_increment:=Sset _i(Ebinop Oadd(Etempvar _i tuint)(Econst_int(Int.repr 1)tint)tuint).
Definition weight_iteration:=Ssequence(Sifthenelse weight_guard Sskip Sbreak)
 (Ssequence(Sset _t'1 weight_read)(Sset _x weight_add)).
Definition weight_loop:=Sloop weight_iteration weight_increment.
Lemma weight_body_actual:fn_body f_ccv_weight=
 Ssequence(Sset _x(Econst_int(Int.repr 0)tuint))
 (Ssequence(Ssequence(Sset _i(Econst_int(Int.repr 0)tuint))weight_loop)
 (Sreturn(Some(Etempvar _x tuint)))).
Proof. reflexivity. Qed.
Definition weight_env le n b ofs i x:Prop:=
 PTree.get _n le=Some(Vint(Int.repr n)) /\PTree.get _a le=Some(Vptr b ofs) /\
 PTree.get _i le=Some(Vint(Int.repr i)) /\PTree.get _x le=Some(Vint x).
Definition weight_next_env le i x v:=
 PTree.set _i(Vint(Int.repr(i+1)))
 (PTree.set _x(Vint(Int.add x v))(PTree.set _t'1(Vint v)le)).
Lemma weight_next_env_valid le n b ofs i x v:
 weight_env le n b ofs i x ->
 weight_env(weight_next_env le i x v)n b ofs(i+1)(Int.add x v).
Proof.
 unfold weight_env,weight_next_env;intros[N[A[I X]]].
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);tauto.
Qed.
Lemma weight_read_eval ge le m n b ofs i x v:
 weight_env le n b ofs i x ->0<=i<=Int.max_unsigned ->
 Mem.loadv Mint8unsigned m(Vptr b(Ptrofs.add ofs(Ptrofs.repr i)))=Some(Vint v) ->
 Clight.eval_expr ge Clight.empty_env le m weight_read(Vint v).
Proof.
 intros[N[A[I X]]] Range Load;unfold weight_read.
 eapply Clight.eval_Elvalue with(loc:=b)(ofs:=Ptrofs.add ofs(Ptrofs.repr i))(bf:=Full).
 - apply Clight.eval_Ederef.
   eapply Clight.eval_Ebinop with(v1:=Vptr b ofs)(v2:=Vint(Int.repr i)).
   + apply Clight.eval_Etempvar;exact A.
   + apply Clight.eval_Etempvar;exact I.
   + cbn[typeof sem_binary_operation].
     unfold Cop.sem_add,Cop.classify_add,Cop.sem_add_ptr_int,Cop.ptrofs_of_int,
       typeconv,tptr,tuchar,tuint,remove_attributes,change_attributes.
     cbn[Ctypes.sizeof].
     rewrite Ptrofs.mul_commut,Ptrofs.mul_one.
     unfold Ptrofs.of_intu,Ptrofs.of_int;rewrite Int.unsigned_repr by exact Range;reflexivity.

 - eapply Clight.deref_loc_value;[reflexivity|exact Load].
Qed.
Lemma weight_guard_eval ge le m n b ofs i x (flag:bool):
 weight_env le n b ofs i x ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->
 (if flag then i<n else n<=i) ->
 Clight.eval_expr ge Clight.empty_env le m weight_guard(Vint(if flag then Int.one else Int.zero)).
Proof.
 intros[N[A[I X]]] IR NR Order;unfold weight_guard.
 eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr n)).
 - apply Clight.eval_Etempvar;exact I.
 - apply Clight.eval_Etempvar;exact N.
 - change (Some (Val.of_bool (Int.ltu (Int.repr i) (Int.repr n))) =
   Some (Vint (if flag then Int.one else Int.zero))).
   unfold Int.ltu;rewrite !Int.unsigned_repr by assumption.
   destruct flag;destruct(zlt i n);cbn in *;try lia;reflexivity.
Qed.
Print Assumptions weight_read_eval.
Print Assumptions weight_guard_eval.

Ltac weight_silent_step:=eapply star_step with(t1:=E0)(t2:=E0);[unfold Clight.step2| |reflexivity].
Lemma weight_continue_path ge le m n b ofs i x v k:
 weight_env le n b ofs i x ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->i<n ->
 Mem.loadv Mint8unsigned m(Vptr b(Ptrofs.add ofs(Ptrofs.repr i)))=Some(Vint v) ->
 star Clight.step2 ge
 (Clight.State f_ccv_weight weight_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_weight weight_loop k Clight.empty_env(weight_next_env le i x v)m).
Proof.
 intros Env IR NR Less Load;pose proof Env as[N[A[I X]]].
 assert(Add:Int.add(Int.repr i)(Int.repr 1)=Int.repr(i+1)).
 { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 unfold weight_loop,weight_iteration,weight_increment,weight_add.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
 - apply(weight_guard_eval ge le m n b ofs i x true);assumption.
 - reflexivity. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint v).
 { apply(weight_read_eval ge le m n b ofs i x v);assumption. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.add x v)).
 { eapply Clight.eval_Ebinop with(v1:=Vint x)(v2:=Vint v).
   - apply Clight.eval_Etempvar;rewrite PTree.gso by discriminate;exact X.
   - eapply Clight.eval_Ecast with(v1:=Vint v).
     + apply Clight.eval_Etempvar;apply PTree.gss.
     + reflexivity.
   - reflexivity. }
 weight_silent_step. apply Clight.step_skip_or_continue_loop1;left;reflexivity.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr(i+1))).
 { eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr 1)).
   - apply Clight.eval_Etempvar;rewrite !PTree.gso by discriminate;exact I.
   - apply Clight.eval_Econst_int.
   - change (Some (Vint (Int.add (Int.repr i) (Int.repr 1))) = Some (Vint (Int.repr (i+1))));rewrite Add;reflexivity. }
 weight_silent_step. apply Clight.step_skip_loop2.
 unfold weight_next_env;apply star_refl.
Qed.
Lemma weight_exit_path ge le m n b ofs i x k:
 weight_env le n b ofs i x ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->n<=i ->
 star Clight.step2 ge
 (Clight.State f_ccv_weight weight_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_weight Sskip k Clight.empty_env le m).
Proof.
 intros Env IR NR Done;unfold weight_loop,weight_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
 - apply(weight_guard_eval ge le m n b ofs i x false);assumption.
 - reflexivity. }
 weight_silent_step. apply Clight.step_break_seq.
 weight_silent_step. apply Clight.step_break_loop1.
 apply star_refl.
Qed.
Print Assumptions weight_continue_path.
Print Assumptions weight_exit_path.

Theorem actual_weight_loop_terminates ge m n b ofs k:
 0<=n<=Int.max_unsigned ->
 (forall j,0<=j<n ->exists v,Mem.loadv Mint8unsigned m
 (Vptr b(Ptrofs.add ofs(Ptrofs.repr j)))=Some(Vint v)) ->
 forall i,0<=i<=n ->forall x le,weight_env le n b ofs i x ->
 exists le' x',star Clight.step2 ge
 (Clight.State f_ccv_weight weight_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_weight Sskip k Clight.empty_env le' m) /\
 weight_env le' n b ofs n x'.
Proof.
 intros NR Reads.
 refine(well_founded_induction_type(well_founded_ltof Z(fun j=>Z.to_nat(n-j))) _ _).
 intros i IH Range x le Env.
 destruct(Z_lt_dec i n)as[Less|Done].
 - destruct(Reads i ltac:(lia))as[v Load].
   assert(Decrease:(Z.to_nat(n-(i+1))<Z.to_nat(n-i))%nat).
   { apply Z2Nat.inj_lt;lia. }
   pose proof(weight_next_env_valid le n b ofs i x v Env)as Next.
   destruct(IH(i+1)Decrease ltac:(lia)(Int.add x v)(weight_next_env le i x v)Next)
   as[le'[x'[Tail Final]]].
   exists le',x';split;[|exact Final].
   eapply star_trans.
   + apply(weight_continue_path ge le m n b ofs i x v k);try assumption;lia.
   + exact Tail.
   + reflexivity.
 - exists le,x;split.
   + apply(weight_exit_path ge le m n b ofs i x k);try assumption;lia.
   + assert(Eq:i=n)by lia;subst i;exact Env.
Qed.
Print Assumptions actual_weight_loop_terminates.

Definition weight_argument_temps n b ofs:=
 PTree.set _a(Vptr b ofs)(PTree.set _n(Vint(Int.repr n))(Clight.create_undef_temps(fn_temps f_ccv_weight))).
Definition weight_started_temps n b ofs:=
 PTree.set _i(Vint(Int.repr 0))(PTree.set _x(Vint(Int.repr 0))(weight_argument_temps n b ofs)).
Definition weight_return:=Sreturn(Some(Etempvar _x tuint)).
Lemma weight_function_entry ge n b ofs m:
 Clight.function_entry2 ge f_ccv_weight [Vint(Int.repr n);Vptr b ofs] m
 Clight.empty_env(weight_argument_temps n b ofs)m.
Proof.
 constructor.
 - constructor.
 - vm_compute. repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Lemma weight_started_env n b ofs:weight_env(weight_started_temps n b ofs)n b ofs 0 Int.zero.
Proof.
 unfold weight_env,weight_started_temps,weight_argument_temps.
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;reflexivity.
Qed.
Lemma weight_start_path ge n b ofs m k:
 star Clight.step2 ge
 (Clight.Callstate(Internal f_ccv_weight)[Vint(Int.repr n);Vptr b ofs]k m) E0
 (Clight.State f_ccv_weight weight_loop(Kseq weight_return k)Clight.empty_env(weight_started_temps n b ofs)m).
Proof.
 weight_silent_step. apply Clight.step_internal_function;apply weight_function_entry.
 rewrite weight_body_actual.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_set;apply Clight.eval_Econst_int.
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_set;apply Clight.eval_Econst_int.
 weight_silent_step. apply Clight.step_skip_seq.
 unfold weight_started_temps,weight_return;apply star_refl.
Qed.
Lemma weight_return_path ge le m n b ofs x k:
 weight_env le n b ofs n x ->
 star Clight.step2 ge
 (Clight.State f_ccv_weight Sskip(Kseq weight_return k)Clight.empty_env le m) E0
 (Clight.Returnstate(Vint x)(Clight.call_cont k)m).
Proof.
 intros[N[A[I X]]].
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { unfold weight_return;eapply Clight.step_return_1 with(v:=Vint x).
 - apply Clight.eval_Etempvar;exact X.
 - reflexivity.
 - reflexivity. }
 apply star_refl.
Qed.
Theorem actual_weight_terminates ge m n b ofs k:
 0<=n<=Int.max_unsigned ->
 (forall j,0<=j<n ->exists v,Mem.loadv Mint8unsigned m
 (Vptr b(Ptrofs.add ofs(Ptrofs.repr j)))=Some(Vint v)) ->
 exists x,star Clight.step2 ge
 (Clight.Callstate(Internal f_ccv_weight)[Vint(Int.repr n);Vptr b ofs]k m) E0
 (Clight.Returnstate(Vint x)(Clight.call_cont k)m).
Proof.
 intros NR Reads.
 destruct(actual_weight_loop_terminates ge m n b ofs(Kseq weight_return k)NR Reads
 0 ltac:(lia) Int.zero(weight_started_temps n b ofs)(weight_started_env n b ofs))
 as[le[x[Loop Env]]].
 exists x;eapply star_trans.
 - apply weight_start_path.
 - eapply star_trans;[exact Loop|apply(weight_return_path ge le m n b ofs x k Env)|reflexivity].
 - reflexivity.
Qed.
Print Assumptions actual_weight_terminates.
