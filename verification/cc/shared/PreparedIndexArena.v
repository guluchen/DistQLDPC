(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected PreparedIndexFinish PreparedIndexReuse
 PreparedCandidateArena PreparedDepthSpec PreparedBudgetContract VerifChildVisit PreparedWitnessRegister.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* Each scratch row contains uint32_t objects initialized once by the
   raw PCM constructor. Descendants can change subsequent rows only. *)
Fixpoint initialized_rows base stride depth (count:nat):mpred:=
 match count with
 | O=>emp
 | S rest=>(ready_row (row_pointer base stride depth) stride *
           initialized_rows base stride (depth+1) rest)%logic
 end.
Definition live_arena base stride levels depth:=
 initialized_rows base stride depth (Z.to_nat (levels-depth)).

Lemma lend_initialized_row base stride levels depth:
 depth<levels ->
 live_arena base stride levels depth=
 (ready_row (row_pointer base stride depth) stride*live_arena base stride levels (depth+1))%logic.
Proof.
 intro room;unfold live_arena.
 replace (levels-depth) with (Z.succ (levels-(depth+1))) by lia.
 rewrite Z2Nat.inj_succ by lia;reflexivity.
Qed.

Definition depth_rows base stride levels (heap:node_storage):budget_heap:=
 fun _ s node=>(heap s node*live_arena base stride levels (Zlength node))%logic.
Lemma child_receives_later_rows base stride levels heap w s node depth:
 Zlength node=depth+1 ->
 depth_rows base stride levels heap w s node=
 (heap s node*live_arena base stride levels (depth+1))%logic.
Proof. intro next;unfold depth_rows;rewrite next;reflexivity. Qed.

Theorem restore_parent_row base stride levels d contents spare:
 d<levels ->
 (contents*spare |-- ready_row (row_pointer base stride d) stride)%logic ->
 ((contents*spare)*live_arena base stride levels (d+1)) |-- live_arena base stride levels d.
Proof.
 intros fits release;rewrite (lend_initialized_row base stride levels d fits).
 apply sepcon_derives;[exact release|apply derives_refl].
Qed.

(* A raw-code invocation searches weights through the physical width.
   Keep that invariant on the heap side of the common recursive ABI. *)
Definition weight_bounded_rows base stride levels (heap:node_storage):budget_heap:=
 fun weight s words=>(!!(weight<=levels) && depth_rows base stride levels heap weight s words)%logic.

Lemma lend_bounded_child base stride levels heap w s sub d:
 w<=levels -> Zlength sub=d+1 ->
 weight_bounded_rows base stride levels heap w s sub=
 (heap s sub*live_arena base stride levels (d+1))%logic.
Proof.
 intros fits at_depth;unfold weight_bounded_rows,depth_rows;rewrite at_depth.
 apply pred_ext;[apply andp_left2|apply andp_right;[apply prop_right|]];auto.
Qed.

Lemma bounded_activation_owns_row base stride levels heap w s cp bp blocks path written words d:
 w<=levels -> d<w -> Zlength words=d ->
 (child_fields s cp bp w blocks path * weight_bounded_rows base stride levels heap w s words *
  witness_register s written)%logic =
 (child_fields s cp bp w blocks path * ready_row (row_pointer base stride d) stride *
  heap s words * live_arena base stride levels (d+1) * witness_register s written)%logic.
Proof.
 intros fits open at_depth;unfold weight_bounded_rows,depth_rows;rewrite at_depth.
 rewrite lend_initialized_row by lia;apply pred_ext;normalize;cancel.
Qed.
