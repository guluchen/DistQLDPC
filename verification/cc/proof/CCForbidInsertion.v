(* Complete taken insertion path of the actual forbid function.  Explicit
   writable/nonaliasing premises provide the concrete stores and later reads. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCClightWordReads CCV.CCClightLvalues
 CCV.CCWordIndexLvalue CCV.CCClightStores CCV.CCRestoreMemory CCV.CCForbidMemory
 CCV.CCForbidPaths CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition fi_base bw ow q bt ot n bf ofl top:=fb_after_top(fb_arguments bw ow q bt ot n)bf ofl Int.zero top.
Definition fi_undo le bu ou:=PTree.set _t'5(Vptr bu ou)le.
Definition fi_index le bu ou top:=PTree.set _t'6(Vint(Int.repr top))(fi_undo le bu ou).
Definition fi_oldtop le bu ou top:=PTree.set _t'4(Vint(Int.repr top))(fi_index le bu ou top).
Definition fi_flag le bu ou top bf ofl:=PTree.set _t'3(Vptr bf ofl)(fi_oldtop le bu ou top).
Ltac fi_registers:=unfold fi_flag,fi_oldtop,fi_index,fi_undo,fi_base;fb_registers.
Theorem actual_forbid_insert_path ge bw ow q bt ot n bf ofl bu ou top m k co df du:
 PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge _forbidden(co_members co)=Errors.OK(df,Full) ->
 Ctypes.field_offset ge _undo(co_members co)=Errors.OK(du,Full) ->
 Mem.loadv Mptr m(Vptr bw(Ptrofs.add ow(Ptrofs.repr df)))=Some(Vptr bf ofl) ->
 Mem.loadv Mptr m(Vptr bw(Ptrofs.add ow(Ptrofs.repr du)))=Some(Vptr bu ou) ->
 0<=q<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->0<=top<n ->
 Mem.loadv Mint8unsigned m(Vptr bf(Ptrofs.add ofl(Ptrofs.repr q)))=Some(Vint Int.zero) ->
 Mem.loadv Mint32 m(Vptr bt ot)=Some(Vint(Int.repr top)) ->
 Mem.valid_access m Mint32 bu(Ptrofs.unsigned(Ptrofs.add ou(Ptrofs.repr(4*top))))Writable ->
 Mem.valid_access m Mint32 bt(Ptrofs.unsigned ot)Writable ->
 Mem.valid_access m Mint8unsigned bf(Ptrofs.unsigned(Ptrofs.add ofl(Ptrofs.repr q)))Writable ->
 cell_apart Mint32 bu(Ptrofs.add ou(Ptrofs.repr(4*top)))Mint32 bt ot ->
 cell_apart Mint32 bu(Ptrofs.add ou(Ptrofs.repr(4*top)))Mptr bw(Ptrofs.add ow(Ptrofs.repr df)) ->
 cell_apart Mint32 bt ot Mptr bw(Ptrofs.add ow(Ptrofs.repr df)) ->
 exists m',star Clight.step2 ge
 (Clight.Callstate(Internal f_forbid)[Vptr bw ow;Vint(Int.repr q);Vptr bt ot;Vint(Int.repr n)]k m)E0
 (Clight.Returnstate(Vint Int.one)(Clight.call_cont k)m').
Proof.
 intros Composite FlagOffset UndoOffset Flags Undo QR NR TR Read Top UW TW FW UT UF TF.
 destruct(forbid_three_stores m bt ot bu(Ptrofs.add ou(Ptrofs.repr(4*top)))
 bw(Ptrofs.add ow(Ptrofs.repr df))bf(Ptrofs.add ofl(Ptrofs.repr q))ofl top q
 Top Flags UW TW FW UT UF TF)as[m1[m2[m3[Store1[Top1[Store2[Flags2 Store3]]]]]]].
 assert(Add:Int.add(Int.repr top)(Int.repr 1)=Int.repr(top+1)).
 { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 exists m3;eapply star_trans.
 - apply(fb_probe_path ge bw ow q bt ot n bf ofl Int.zero m k co df);assumption.
 - unfold fb_choose,fb_try.
   weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
   + apply(fb_free_eval ge _ m Int.zero);unfold fb_after_read;apply PTree.gss.
   + reflexivity. }
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr top)).
   { apply(eval_uint_deref ge Clight.empty_env(fb_after_read(fb_arguments bw ow q bt ot n)bf ofl Int.zero)m _top bt ot(Int.repr top));[fb_registers|exact Top]. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
   + apply(fb_full_eval ge(fi_base bw ow q bt ot n bf ofl top)m top n false);try assumption;try(fi_registers);lia.
   + reflexivity. }
   weight_silent_step. apply Clight.step_skip_seq.
   unfold fb_insert.
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. eapply Clight.step_set with(v:=Vptr bu ou).
   { apply(eval_struct_field ge Clight.empty_env(fi_base bw ow q bt ot n bf ofl top)m _w _ccv_workspace
   _undo(tptr tuint)co du Mptr bw ow(Vptr bu ou));try assumption;[fi_registers|reflexivity]. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr top)).
   { apply(eval_uint_deref ge Clight.empty_env(fi_undo(fi_base bw ow q bt ot n bf ofl top)bu ou)m
   _top bt ot(Int.repr top));[fi_registers|exact Top]. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. { apply(defined_assignment_step ge f_forbid _ Clight.empty_env
   (fi_index(fi_base bw ow q bt ot n bf ofl top)bu ou top)m(uint_index_expr _t'5 _t'6)
   (Etempvar _q tuint)bu(Ptrofs.add ou(Ptrofs.repr(4*top)))Mint32(Vint(Int.repr q))(Vint(Int.repr q))m1).
   + apply(lvalue_uint_index ge Clight.empty_env(fi_index(fi_base bw ow q bt ot n bf ofl top)bu ou top)m
     _t'5 _t'6 bu ou top);try(fi_registers);lia.
   + apply Clight.eval_Etempvar;fi_registers.
   + reflexivity.
   + reflexivity.
   + exact Store1. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr top)).
   { apply(eval_uint_deref ge Clight.empty_env(fi_index(fi_base bw ow q bt ot n bf ofl top)bu ou top)m1
   _top bt ot(Int.repr top));[fi_registers|exact Top1]. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. { apply(defined_assignment_step ge f_forbid _ Clight.empty_env
   (fi_oldtop(fi_base bw ow q bt ot n bf ofl top)bu ou top)m1 fb_counter
   (Ebinop Oadd(Etempvar _t'4 tuint)(Econst_int(Int.repr 1)tuint)tuint)
   bt ot Mint32(Vint(Int.repr(top+1)))(Vint(Int.repr(top+1)))m2).
   + apply lvalue_uint_deref;fi_registers.
   + eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr top))(v2:=Vint(Int.repr 1)).
     * apply Clight.eval_Etempvar;fi_registers.
     * apply Clight.eval_Econst_int.
     * change(Some(Vint(Int.add(Int.repr top)(Int.repr 1)))=Some(Vint(Int.repr(top+1))));rewrite Add;reflexivity.
   + reflexivity.
   + reflexivity.
   + exact Store2. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. apply Clight.step_seq.
   weight_silent_step. eapply Clight.step_set with(v:=Vptr bf ofl).
   { apply(eval_struct_field ge Clight.empty_env(fi_oldtop(fi_base bw ow q bt ot n bf ofl top)bu ou top)m2 _w _ccv_workspace
   _forbidden(tptr tuchar)co df Mptr bw ow(Vptr bf ofl));try assumption;[fi_registers|reflexivity]. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. { apply(defined_assignment_step ge f_forbid _ Clight.empty_env
   (fi_flag(fi_base bw ow q bt ot n bf ofl top)bu ou top bf ofl)m2(uchar_index_expr _t'3 _q)
   (Econst_int(Int.repr 1)tuint)bf(Ptrofs.add ofl(Ptrofs.repr q))Mint8unsigned(Vint Int.one)(Vint Int.one)m3).
   + apply(lvalue_uchar_index ge Clight.empty_env(fi_flag(fi_base bw ow q bt ot n bf ofl top)bu ou top bf ofl)m2
     _t'3 _q bf ofl q);try(fi_registers);exact QR.
   + apply Clight.eval_Econst_int.
   + reflexivity.
   + reflexivity.
   + exact Store3. }
   weight_silent_step. apply Clight.step_skip_seq.
   weight_silent_step. { unfold fb_one;eapply Clight.step_return_1 with(v:=Vint Int.one).
   + apply Clight.eval_Econst_int.
   + reflexivity.
   + reflexivity. }
   apply star_refl.
 - reflexivity.
Qed.
Print Assumptions actual_forbid_insert_path.
