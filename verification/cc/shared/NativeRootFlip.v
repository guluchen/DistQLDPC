(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VerifDetected VerifChildVisit EnabledCall
 VerifClosesBody VerifToggleBody VerifFlipBody PreparedFlip PreparedRecursiveCall OverlapColumnState NativeFlipPayload.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition live_support addr p keys initial s (root:option Z):=
 packed_mem s addr p keys (match root with None=>initial|Some q=>step_support p keys q initial end).
Definition valid_payload p (keys:list int64) q payload:=
 let v:=words_at payload in let odd:=odd_count payload in
 q+1<Zlength (offsets v) /\ q<Zlength keys /\
 0<=Znth q (offsets v)<=Znth (q+1) (offsets v) /\ Znth (q+1) (offsets v)<=Zlength (rows v) /\
 Zlength (rows v)<=Int.max_unsigned /\ Int.min_signed<=odd<=Int.max_signed /\
 0<width v<=Int.max_signed /\ (q+1)*width v<=Zlength (masks v) /\
 (forall i,Znth q (offsets v)<=i<Znth (q+1) (offsets v) -> word_index (Znth i (rows v))<Zlength (syndrome v)) /\
 (forall i,Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
  Int.min_signed<snd (flipped v q odd i)<Int.max_signed) /\ extra_bounds p q (Zlength (syndrome v)).
Definition pair_safe p keys q initial:=
 valid_payload p keys q initial /\ valid_payload p keys q (step_support p keys q initial) /\
 step_support p keys q (step_support p keys q initial)=initial.

Theorem native_root_flip_instantiated c p mask keys addr initial:
 nested_policy (nested c)=policy_ptr p -> redundant_option mask p ->
 (forall s pos,active_support (nested c) s pos=live_support addr p keys initial s pos) ->
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
 Exists (s,addr,words_at x,keys,q,odd_count x,checksum x,p,mask) emp;apply andp_right.
 - rewrite policy,represents;unfold live_support,packed_mem;destruct enter;unfold x;entailer!;try cancel.
 - apply prop_right;intro rho;normalize;rewrite represents;unfold live_support.
   pose proof (updated_packed_allocation s addr p keys q x ltac:(lia) ltac:(lia) room) as back.
   rewrite <- back;unfold x;destruct enter;cbn;try rewrite inverse;entailer!;try cancel.
Qed.

Corollary body_flip_for_prepared_root c p mask keys addr initial:
 nested_policy (nested c)=policy_ptr p -> redundant_option mask p ->
 (forall s pos,active_support (nested c) s pos=live_support addr p keys initial s pos) ->
 (forall q,0<=q<Int.max_signed -> q+1<Zlength (column_offsets (geometry c)) -> pair_safe p keys q initial) ->
 semax_body PreparedSeedDispatch.prepared_vars PreparedFlip.FlipGprog f_flip (root_flip c mask).
Proof.
 intros; eapply semax_body_funspec_sub;[exact PreparedFlip.body_flip|eapply native_root_flip_instantiated;eassumption|].
 vm_compute;repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
