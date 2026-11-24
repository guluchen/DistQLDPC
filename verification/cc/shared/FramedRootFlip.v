(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VerifDetected VerifChildVisit EnabledCall
 VerifClosesBody VerifToggleBody VerifFlipBody PreparedFlip PreparedRecursiveCall OverlapColumnState NativeFlipPayload NativeRootFlip.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Theorem framed_root_flip c p mask keys addr initial (workspace:val->mpred):
 nested_policy (nested c)=policy_ptr p -> redundant_option mask p ->
 (forall s pos,active_support (nested c) s pos=(live_support addr p keys initial s pos * workspace s)%logic) ->
 (forall q,0<=q<Int.max_signed -> q+1<Zlength (column_offsets (geometry c)) -> pair_safe p keys q initial) ->
 funspec_sub (snd PreparedFlip.flip_spec) (snd (root_flip c mask)).
Proof.
 intros policy bit represents valid.
 do_funspec_sub;destruct w as [[s q] enter];cbn [fst snd];normalize.
 assert (index:0<=q<Int.max_signed) by lia.
 assert (slot:q+1<Zlength (column_offsets (geometry c))) by assumption.
 destruct (valid q index slot) as [can_enter [can_leave inverse]].
 set (x:=if enter then initial else step_support p keys q initial).
 assert (ok:valid_payload p keys q x) by (unfold x;destruct enter;assumption).
 destruct ok as [qin [key [rows_ok [end_ok [size [count [width_ok [room [addressed [signed extras]]]]]]]]]].
 Exists (s,addr,words_at x,keys,q,odd_count x,checksum x,p,mask) (workspace s);apply andp_right.
 - rewrite policy,represents;unfold live_support,packed_mem;destruct enter;unfold x;entailer!;try cancel.
 - apply prop_right;intro rho;normalize;rewrite represents;unfold live_support.
   pose proof (updated_packed_allocation s addr p keys q x ltac:(lia) ltac:(lia) room) as back.
   rewrite <- back;unfold x;destruct enter;cbn;try rewrite inverse;entailer!;try cancel.
Qed.

Corollary body_flip_with_dfs_storage c p mask keys addr initial (workspace:val->mpred):
 nested_policy (nested c)=policy_ptr p -> redundant_option mask p ->
 (forall s pos,active_support (nested c) s pos=(live_support addr p keys initial s pos * workspace s)%logic) ->
 (forall q,0<=q<Int.max_signed -> q+1<Zlength (column_offsets (geometry c)) -> pair_safe p keys q initial) ->
 semax_body PreparedSeedDispatch.prepared_vars PreparedFlip.FlipGprog f_flip (root_flip c mask).
Proof.
 intros; eapply semax_body_funspec_sub;[exact PreparedFlip.body_flip|eapply framed_root_flip;eassumption|].
 vm_compute;repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
