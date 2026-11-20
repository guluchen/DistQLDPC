(* Actual primitive byte-XOR loop, including writes and finite return.
   Definedness permits aliasing; functional correctness has its own VST PRE. *)
Require Import VST.floyd.proofauto Coq.Arith.Wf_nat.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCClightLvalues CCV.CCClightStores
 CCV.CCByteInitialization CCV.CCTerminateWeight CCV.ccv_primitives.
Import ListNotations. Open Scope Z_scope.
Definition tog_read_a:=uchar_index_expr _a _i.
Definition tog_read_b:=uchar_index_expr _b _i.
Definition tog_rhs:=Ecast(Ebinop Oxor(Ecast(Etempvar _t'1 tuchar)tuint)
 (Ecast(Etempvar _t'2 tuchar)tuint)tuint)tuchar.
Definition tog_iteration:=Ssequence(Sifthenelse weight_guard Sskip Sbreak)
 (Ssequence(Sset _t'1 tog_read_a)(Ssequence(Sset _t'2 tog_read_b)(Sassign tog_read_a tog_rhs))).
Definition tog_loop:=Sloop tog_iteration weight_increment.
Lemma tog_body_actual:fn_body f_ccv_toggle=Ssequence(Sset _i(Econst_int(Int.repr 0)tuint))tog_loop.
Proof. reflexivity. Qed.
Definition tog_env le n ba oa bb ob i:Prop:=
 PTree.get _n le=Some(Vint(Int.repr n)) /\PTree.get _a le=Some(Vptr ba oa) /\
 PTree.get _b le=Some(Vptr bb ob) /\PTree.get _i le=Some(Vint(Int.repr i)).
Definition tog_read_env le va vb:=PTree.set _t'2(Vint vb)(PTree.set _t'1(Vint va)le).
Definition tog_next le i va vb:=PTree.set _i(Vint(Int.repr(i+1)))(tog_read_env le va vb).
Definition tog_memory m n ba oa bb ob:Prop:=forall j,0<=j<n ->
 byte_initialized m ba(Ptrofs.add oa(Ptrofs.repr j)) /\
 byte_initialized m bb(Ptrofs.add ob(Ptrofs.repr j)) /\
 Mem.valid_access m Mint8unsigned ba(Ptrofs.unsigned(Ptrofs.add oa(Ptrofs.repr j)))Writable.
Lemma tog_store_keeps_memory m n ba oa bb ob b ofs v m':
 Mem.storev Mint8unsigned m(Vptr b ofs)(Vint v)=Some m' ->
 tog_memory m n ba oa bb ob ->tog_memory m' n ba oa bb ob.
Proof.
 intros Store Memory j Range;destruct(Memory j Range)as[A[B Write]];split.
 - eapply byte_store_keeps_initialized;[exact Store|exact A].
 - split;[eapply byte_store_keeps_initialized;[exact Store|exact B]|].
   eapply storev_keeps_valid_access;[exact Store|exact Write].
Qed.
Ltac tog_registers:=unfold tog_next,tog_read_env;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);first[assumption|reflexivity].
Lemma tog_next_valid le n ba oa bb ob i va vb:
 tog_env le n ba oa bb ob i ->tog_env(tog_next le i va vb)n ba oa bb ob(i+1).
Proof. intros[N[A[B I]]];unfold tog_env;repeat split;tog_registers. Qed.
Lemma tog_guard_eval ge le m n ba oa bb ob i(flag:bool):
 tog_env le n ba oa bb ob i ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->
 (if flag then i<n else n<=i) ->
 Clight.eval_expr ge Clight.empty_env le m weight_guard(Vint(if flag then Int.one else Int.zero)).
Proof. intros[N[A[B I]]] IR NR Order;apply(eval_uint_lt ge Clight.empty_env le m _i _n i n flag);assumption. Qed.
Theorem tog_continue_path ge le m n ba oa bb ob i k:
 tog_env le n ba oa bb ob i ->tog_memory m n ba oa bb ob ->
 0<=i<n ->0<=n<=Int.max_unsigned ->
 exists le' m',tog_env le' n ba oa bb ob(i+1) /\tog_memory m' n ba oa bb ob /\
 star Clight.step2 ge(Clight.State f_ccv_toggle tog_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_toggle tog_loop k Clight.empty_env le' m').
Proof.
 intros Env Memory Range NR;pose proof Env as[N[A[B I]]].
 destruct(Memory i Range)as[[va LoadA][[vb LoadB]Writable]].
 set(written:=Int.zero_ext 8(Int.zero_ext 8(Int.xor va vb))).
 destruct(writable_byte_value_store m ba(Ptrofs.add oa(Ptrofs.repr i))written Writable)as[m' Store].
 exists(tog_next le i va vb),m';split;[apply tog_next_valid;exact Env|].
 split;[eapply tog_store_keeps_memory;[exact Store|exact Memory]|].
 assert(Add:Int.add(Int.repr i)(Int.repr 1)=Int.repr(i+1)).
 { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 unfold tog_loop,tog_iteration,weight_increment.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
 - apply(tog_guard_eval ge le m n ba oa bb ob i true);try assumption;lia.
 - reflexivity. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint va).
 { apply(eval_uchar_index ge Clight.empty_env le m _a _i ba oa i va);try assumption;lia. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint vb).
 { apply(eval_uchar_index ge Clight.empty_env(PTree.set _t'1(Vint va)le)m _b _i bb ob i vb);
 try assumption;try(tog_registers);try(rewrite PTree.gso by discriminate;assumption);lia. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { apply(defined_assignment_step ge f_ccv_toggle _ Clight.empty_env
 (tog_read_env le va vb)m tog_read_a tog_rhs ba(Ptrofs.add oa(Ptrofs.repr i))Mint8unsigned
 (Vint(Int.zero_ext 8(Int.xor va vb)))(Vint written)m').
 - apply(lvalue_uchar_index ge Clight.empty_env(tog_read_env le va vb)m _a _i ba oa i);
 try(tog_registers);lia.
 - unfold tog_rhs;eapply Clight.eval_Ecast with(v1:=Vint(Int.xor va vb)).
   + eapply Clight.eval_Ebinop with(v1:=Vint va)(v2:=Vint vb).
     * eapply Clight.eval_Ecast with(v1:=Vint va);[apply Clight.eval_Etempvar;tog_registers|reflexivity].
     * eapply Clight.eval_Ecast with(v1:=Vint vb);[apply Clight.eval_Etempvar;tog_registers|reflexivity].
     * reflexivity.
   + reflexivity.
 - reflexivity.
 - reflexivity.
 - exact Store. }
 weight_silent_step. apply Clight.step_skip_or_continue_loop1;left;reflexivity.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr(i+1))).
 { eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr 1)).
 - apply Clight.eval_Etempvar;tog_registers.
 - apply Clight.eval_Econst_int.
 - change(Some(Vint(Int.add(Int.repr i)(Int.repr 1)))=Some(Vint(Int.repr(i+1))));rewrite Add;reflexivity. }
 weight_silent_step. apply Clight.step_skip_loop2.
 unfold tog_next,tog_read_env;apply star_refl.
Qed.
Lemma tog_exit_path ge le m n ba oa bb ob i k:
 tog_env le n ba oa bb ob i ->0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->n<=i ->
 star Clight.step2 ge(Clight.State f_ccv_toggle tog_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_toggle Sskip k Clight.empty_env le m).
Proof.
 intros Env IR NR Done;unfold tog_loop,tog_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
 - apply(tog_guard_eval ge le m n ba oa bb ob i false);assumption.
 - reflexivity. }
 weight_silent_step. apply Clight.step_break_seq.
 weight_silent_step. apply Clight.step_break_loop1.
 apply star_refl.
Qed.
Theorem tog_loop_terminates ge n ba oa bb ob k:
 0<=n<=Int.max_unsigned ->forall i,0<=i<=n ->forall m le,
 tog_memory m n ba oa bb ob ->tog_env le n ba oa bb ob i ->
 exists le' m',tog_memory m' n ba oa bb ob /\
 star Clight.step2 ge(Clight.State f_ccv_toggle tog_loop k Clight.empty_env le m) E0
 (Clight.State f_ccv_toggle Sskip k Clight.empty_env le' m').
Proof.
 intros NR;refine(well_founded_induction_type(well_founded_ltof Z(fun j=>Z.to_nat(n-j))) _ _).
 intros i IH Range m le Mem Env;destruct(Z_lt_dec i n)as[Less|Done].
 - destruct(tog_continue_path ge le m n ba oa bb ob i k Env Mem ltac:(lia)NR)
 as[le1[m1[Env1[Mem1 Prefix]]]].
 assert(Decrease:(Z.to_nat(n-(i+1))<Z.to_nat(n-i))%nat)by(apply Z2Nat.inj_lt;lia).
 destruct(IH(i+1)Decrease ltac:(lia)m1 le1 Mem1 Env1)as[le2[m2[Mem2 Tail]]].
 exists le2,m2;split;[exact Mem2|];eapply star_trans;[exact Prefix|exact Tail|reflexivity].
 - exists le,m;split;[exact Mem|];apply(tog_exit_path ge le m n ba oa bb ob i k);try assumption;lia.
Qed.
Definition tog_arguments n ba oa bb ob:=PTree.set _b(Vptr bb ob)
 (PTree.set _a(Vptr ba oa)(PTree.set _n(Vint(Int.repr n))(Clight.create_undef_temps(fn_temps f_ccv_toggle)))).
Definition tog_started n ba oa bb ob:=PTree.set _i(Vint(Int.repr 0))(tog_arguments n ba oa bb ob).
Lemma tog_entry ge n ba oa bb ob m:
 Clight.function_entry2 ge f_ccv_toggle[Vint(Int.repr n);Vptr ba oa;Vptr bb ob]m
 Clight.empty_env(tog_arguments n ba oa bb ob)m.
Proof.
 constructor.
 - constructor.
 - vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Lemma tog_started_valid n ba oa bb ob:tog_env(tog_started n ba oa bb ob)n ba oa bb ob 0.
Proof.
 unfold tog_env,tog_started,tog_arguments;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;reflexivity.
Qed.
Theorem actual_byte_toggle_terminates ge m n ba oa bb ob k:
 Clight.is_call_cont k ->0<=n<=Int.max_unsigned ->tog_memory m n ba oa bb ob ->
 exists m',tog_memory m' n ba oa bb ob /\
 star Clight.step2 ge
 (Clight.Callstate(Internal f_ccv_toggle)[Vint(Int.repr n);Vptr ba oa;Vptr bb ob]k m) E0
 (Clight.Returnstate Vundef k m').
Proof.
 intros Call NR Mem.
 destruct(tog_loop_terminates ge n ba oa bb ob k NR 0 ltac:(lia)m(tog_started n ba oa bb ob)
 Mem(tog_started_valid n ba oa bb ob))as[le'[m'[Mem' Loop]]].
 exists m';split;[exact Mem'|].
 weight_silent_step. apply Clight.step_internal_function;apply tog_entry.
 rewrite tog_body_actual.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_set;apply Clight.eval_Econst_int.
 weight_silent_step. apply Clight.step_skip_seq.
 eapply star_trans;[exact Loop| |reflexivity].
 weight_silent_step. { apply Clight.step_skip_call;[exact Call|reflexivity]. }
 apply star_refl.
Qed.
Print Assumptions actual_byte_toggle_terminates.
