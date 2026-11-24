(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall OverlapColumnState
 VerifClosesBody VerifToggleBody VerifFlipBody PreparedFlip NativeFlipPayload NativeRootFlip
 PreparedDepthSpec PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition column_in c q:=0<=q<Int.max_signed /\ q+1<Zlength (column_offsets (geometry c)).
Definition physical_prefix c:=Forall (fun word=>column_in c (Int.signed word)).
Definition payload_after policy keys initial (path:list int):=
 fold_left (fun x word=>step_support policy keys (Int.signed word) x) path initial.
Lemma append_column p keys x path q:0<=q<Int.max_signed ->
 payload_after p keys x (path++[Int.repr q])=step_support p keys q (payload_after p keys x path).
Proof. intros valid;unfold payload_after;rewrite fold_left_app;cbn;rewrite Int.signed_repr by rep_lia;reflexivity. Qed.
Lemma prefix_column c path q:column_in c q ->
 (physical_prefix c (path++[Int.repr q]) <-> physical_prefix c path).
Proof.
 intros [fit index];unfold physical_prefix;rewrite Forall_app;split;[tauto|].
 intro good;split;auto;constructor;[rewrite Int.signed_repr by rep_lia;split;assumption|constructor].
Qed.
Definition physical_store c p keys addr initial (workspace:val->mpred) :node_storage:=
 fun s path=> (!!physical_prefix c path &&
   (packed_mem s addr p keys (payload_after p keys initial path) * workspace s))%logic.

Theorem depth_flip_refinement c p bits keys addr initial workspace:
 nested_policy (nested c)=policy_ptr p -> redundant_option bits p ->
 (forall path q,physical_prefix c path->column_in c q->pair_safe p keys q (payload_after p keys initial path)) ->
 funspec_sub (snd PreparedFlip.flip_spec) (snd (depth_flip c (physical_store c p keys addr initial workspace) bits)).
Proof.
 intros policy options valid;do_funspec_sub;destruct w as [[[s path] q] enter];cbn [fst snd];normalize.
 assert (col:column_in c q) by (unfold column_in;lia).
 set (x:=payload_after p keys initial path).
 assert (both:physical_prefix c path -> pair_safe p keys q x) by (intro safe;apply valid;assumption).
 destruct enter;cbn;unfold physical_store;Intros.
 - destruct (both ltac:(assumption)) as [can _].
   destruct can as [qin [key [rows_ok [end_ok [size [count [width_ok [room [addressed [signed extras]]]]]]]]]].
   Exists (s,addr,words_at x,keys,q,odd_count x,checksum x,p,bits) (workspace s);apply andp_right.
   + rewrite policy;unfold packed_mem,x;entailer!;cancel.
   + apply prop_right;intro rho;normalize;unfold physical_store;rewrite append_column by (destruct col;lia);fold x.
     rewrite updated_packed_allocation by (try assumption;lia).
     entailer!;try cancel;apply (proj2 (prefix_column _ _ _ col));assumption.
 - assert (short:physical_prefix c path) by (apply (proj1 (prefix_column _ _ _ col));assumption).
   destruct (both short) as [_ [can back]].
   set (z:=step_support p keys q x) in *.
   destruct can as [qin [key [rows_ok [end_ok [size [count [width_ok [room [addressed [signed extras]]]]]]]]]].
   Exists (s,addr,words_at z,keys,q,odd_count z,checksum z,p,bits) (workspace s);apply andp_right.
   + rewrite policy,append_column by (destruct col;lia);fold x z;unfold packed_mem;entailer!;cancel.
   + apply prop_right;intro rho;normalize;unfold physical_store;fold x;rewrite <-back at 1.
     rewrite updated_packed_allocation by (try assumption;lia).
     entailer!;try cancel.
Qed.
Corollary body_flip_any_depth c p bits keys addr initial workspace:
 nested_policy (nested c)=policy_ptr p -> redundant_option bits p ->
 (forall path q,physical_prefix c path->column_in c q->pair_safe p keys q (payload_after p keys initial path)) ->
 semax_body prepared_vars PreparedFlip.FlipGprog f_flip (depth_flip c (physical_store c p keys addr initial workspace) bits).
Proof.
 intros;eapply semax_body_funspec_sub;[exact PreparedFlip.body_flip|apply depth_flip_refinement;assumption|].
 vm_compute;repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
