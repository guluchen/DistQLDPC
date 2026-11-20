(* Exact read/early-return paths of the actual forbid helper.  The insertion
   path is a separate remaining obligation; no full helper totality is claimed. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCClightWordReads CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition fb_flags:=struct_field_expr _w _ccv_workspace _forbidden(tptr tuchar).
Definition fb_undo:=struct_field_expr _w _ccv_workspace _undo(tptr tuint).
Definition fb_counter:=uint_deref_expr _top.
Definition fb_read:=uchar_index_expr _t'1 _q.
Definition fb_free:=Ebinop Oeq(Etempvar _t'2 tuchar)(Econst_int(Int.repr 0)tuint)tint.
Definition fb_full:=Ebinop Oge(Etempvar _t'7 tuint)(Etempvar _n tuint)tint.
Definition fb_zero:=Sreturn(Some(Econst_int(Int.repr 0)tint)).
Definition fb_one:=Sreturn(Some(Econst_int(Int.repr 1)tint)).
Definition fb_insert:=Ssequence
 (Ssequence(Sset _t'5 fb_undo)(Ssequence(Sset _t'6 fb_counter)
 (Sassign(uint_index_expr _t'5 _t'6)(Etempvar _q tuint))))
 (Ssequence(Ssequence(Sset _t'4 fb_counter)
 (Sassign fb_counter(Ebinop Oadd(Etempvar _t'4 tuint)(Econst_int(Int.repr 1)tuint)tuint)))
 (Ssequence(Sset _t'3 fb_flags)(Sassign(uchar_index_expr _t'3 _q)(Econst_int(Int.repr 1)tuint)))).
Definition fb_try:=Ssequence(Ssequence(Sset _t'7 fb_counter)(Sifthenelse fb_full fb_zero Sskip))fb_insert.
Definition fb_choose:=Sifthenelse fb_free fb_try Sskip.
Definition fb_probe:=Ssequence(Sset _t'1 fb_flags)(Ssequence(Sset _t'2 fb_read)fb_choose).
Lemma fb_body_actual:fn_body f_forbid=Ssequence fb_probe fb_one.
Proof. reflexivity. Qed.
Definition fb_env le bw ow q bt ot n:Prop:=
 PTree.get _w le=Some(Vptr bw ow) /\PTree.get _q le=Some(Vint(Int.repr q)) /\
 PTree.get _top le=Some(Vptr bt ot) /\PTree.get _n le=Some(Vint(Int.repr n)).
Definition fb_arguments bw ow q bt ot n:=PTree.set _n(Vint(Int.repr n))
 (PTree.set _top(Vptr bt ot)(PTree.set _q(Vint(Int.repr q))
 (PTree.set _w(Vptr bw ow)(Clight.create_undef_temps(fn_temps f_forbid))))).
Definition fb_after_flags le bf ofl:=PTree.set _t'1(Vptr bf ofl)le.
Definition fb_after_read le bf ofl value:=PTree.set _t'2(Vint value)(fb_after_flags le bf ofl).
Definition fb_after_top le bf ofl value top:=PTree.set _t'7(Vint(Int.repr top))(fb_after_read le bf ofl value).
Ltac fb_registers:=unfold fb_after_top,fb_after_read,fb_after_flags,fb_arguments;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);first[assumption|reflexivity].
Lemma fb_arguments_valid bw ow q bt ot n:fb_env(fb_arguments bw ow q bt ot n)bw ow q bt ot n.
Proof. unfold fb_env;repeat split;fb_registers. Qed.
Lemma fb_entry ge bw ow q bt ot n m:
 Clight.function_entry2 ge f_forbid[Vptr bw ow;Vint(Int.repr q);Vptr bt ot;Vint(Int.repr n)]m
 Clight.empty_env(fb_arguments bw ow q bt ot n)m.
Proof.
 constructor.
 - constructor.
 - vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Lemma fb_free_eval ge le m value:
 PTree.get _t'2 le=Some(Vint value) ->
 Clight.eval_expr ge Clight.empty_env le m fb_free
 (Vint(if Int.eq value Int.zero then Int.one else Int.zero)).
Proof.
 intros Value;unfold fb_free;eapply Clight.eval_Ebinop with(v1:=Vint value)(v2:=Vint Int.zero).
 - apply Clight.eval_Etempvar;exact Value.
 - apply Clight.eval_Econst_int.
 - change(Some(Val.of_bool(Int.eq value Int.zero))=Some(Vint(if Int.eq value Int.zero then Int.one else Int.zero))).
   destruct(Int.eq value Int.zero);reflexivity.
Qed.
Lemma fb_full_eval ge le m top n(flag:bool):
 PTree.get _t'7 le=Some(Vint(Int.repr top)) ->PTree.get _n le=Some(Vint(Int.repr n)) ->
 0<=top<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->(if flag then n<=top else top<n) ->
 Clight.eval_expr ge Clight.empty_env le m fb_full(Vint(if flag then Int.one else Int.zero)).
Proof.
 intros Top N TR NR Order;unfold fb_full.
 eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr top))(v2:=Vint(Int.repr n)).
 - apply Clight.eval_Etempvar;exact Top.
 - apply Clight.eval_Etempvar;exact N.
 - change(Some(Val.of_bool(negb(Int.ltu(Int.repr top)(Int.repr n))))=
   Some(Vint(if flag then Int.one else Int.zero))).
   unfold Int.ltu;rewrite !Int.unsigned_repr by assumption.
   destruct flag;destruct(zlt top n);cbn in *;try lia;reflexivity.
Qed.
Lemma fb_probe_path ge bw ow q bt ot n bf ofl value m k co delta:
 PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge _forbidden(co_members co)=Errors.OK(delta,Full) ->
 Mem.loadv Mptr m(Vptr bw(Ptrofs.add ow(Ptrofs.repr delta)))=Some(Vptr bf ofl) ->
 0<=q<=Int.max_unsigned ->
 Mem.loadv Mint8unsigned m(Vptr bf(Ptrofs.add ofl(Ptrofs.repr q)))=Some(Vint value) ->
 star Clight.step2 ge
 (Clight.Callstate(Internal f_forbid)[Vptr bw ow;Vint(Int.repr q);Vptr bt ot;Vint(Int.repr n)]k m)E0
 (Clight.State f_forbid fb_choose(Kseq fb_one k)Clight.empty_env
 (fb_after_read(fb_arguments bw ow q bt ot n)bf ofl value)m).
Proof.
 intros Composite Offset Flags QR Read.
 weight_silent_step. apply Clight.step_internal_function;apply fb_entry.
 rewrite fb_body_actual.
 weight_silent_step. apply Clight.step_seq.
 unfold fb_probe.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr bf ofl).
 { apply(eval_struct_field ge Clight.empty_env(fb_arguments bw ow q bt ot n)m _w _ccv_workspace
 _forbidden(tptr tuchar)co delta Mptr bw ow(Vptr bf ofl));try assumption;[fb_registers|reflexivity]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint value).
 { apply(eval_uchar_index ge Clight.empty_env(fb_after_flags(fb_arguments bw ow q bt ot n)bf ofl)m
 _t'1 _q bf ofl q value);try assumption;fb_registers. }
 weight_silent_step. apply Clight.step_skip_seq.
 unfold fb_after_read,fb_after_flags;apply star_refl.
Qed.
Theorem actual_forbid_existing_path ge bw ow q bt ot n bf ofl value m k co delta:
 PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge _forbidden(co_members co)=Errors.OK(delta,Full) ->
 Mem.loadv Mptr m(Vptr bw(Ptrofs.add ow(Ptrofs.repr delta)))=Some(Vptr bf ofl) ->
 0<=q<=Int.max_unsigned ->
 Mem.loadv Mint8unsigned m(Vptr bf(Ptrofs.add ofl(Ptrofs.repr q)))=Some(Vint value) ->
 Int.eq value Int.zero=false ->
 star Clight.step2 ge
 (Clight.Callstate(Internal f_forbid)[Vptr bw ow;Vint(Int.repr q);Vptr bt ot;Vint(Int.repr n)]k m)E0
 (Clight.Returnstate(Vint Int.one)(Clight.call_cont k)m).
Proof.
 intros Composite Offset Flags QR Read Present.
 eapply star_trans.
 - apply(fb_probe_path ge bw ow q bt ot n bf ofl value m k co delta);assumption.
 - unfold fb_choose.
   weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
   + pose proof(fb_free_eval ge(fb_after_read(fb_arguments bw ow q bt ot n)bf ofl value)m value
     ltac:(unfold fb_after_read;apply PTree.gss))as Eval;rewrite Present in Eval;exact Eval.
   + reflexivity. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. { unfold fb_one;eapply Clight.step_return_1 with(v:=Vint Int.one).
   + apply Clight.eval_Econst_int.
   + reflexivity.
   + reflexivity. }
   apply star_refl.
 - reflexivity.
Qed.
Print Assumptions actual_forbid_existing_path.
Theorem actual_forbid_full_path ge bw ow q bt ot n bf ofl top m k co delta:
 PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge _forbidden(co_members co)=Errors.OK(delta,Full) ->
 Mem.loadv Mptr m(Vptr bw(Ptrofs.add ow(Ptrofs.repr delta)))=Some(Vptr bf ofl) ->
 0<=q<=Int.max_unsigned ->
 Mem.loadv Mint8unsigned m(Vptr bf(Ptrofs.add ofl(Ptrofs.repr q)))=Some(Vint Int.zero) ->
 Mem.loadv Mint32 m(Vptr bt ot)=Some(Vint(Int.repr top)) ->
 0<=top<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->n<=top ->
 star Clight.step2 ge
 (Clight.Callstate(Internal f_forbid)[Vptr bw ow;Vint(Int.repr q);Vptr bt ot;Vint(Int.repr n)]k m)E0
 (Clight.Returnstate(Vint Int.zero)(Clight.call_cont k)m).
Proof.
 intros Composite Offset Flags QR Read Top TR NR Full.
 eapply star_trans.
 - apply(fb_probe_path ge bw ow q bt ot n bf ofl Int.zero m k co delta);assumption.
 - unfold fb_choose,fb_try.
   weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
   + apply(fb_free_eval ge _ m Int.zero);unfold fb_after_read;apply PTree.gss.
   + reflexivity. }
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr top)).
   { apply(eval_uint_deref ge Clight.empty_env(fb_after_read(fb_arguments bw ow q bt ot n)bf ofl Int.zero)m _top bt ot(Int.repr top));[fb_registers|exact Top]. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
   + apply(fb_full_eval ge(fb_after_top(fb_arguments bw ow q bt ot n)bf ofl Int.zero top)m top n true);
     try assumption;fb_registers.
   + reflexivity. }
   weight_silent_step. { unfold fb_zero;eapply Clight.step_return_1 with(v:=Vint Int.zero).
   + apply Clight.eval_Econst_int.
   + reflexivity.
   + reflexivity. }
   apply star_refl.
 - reflexivity.
Qed.
Print Assumptions actual_forbid_full_path.
