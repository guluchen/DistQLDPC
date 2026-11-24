(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto overlap_ast OverlapView OverlapColumnState OverlapRowSpecs.
Require VerifChildVisit VerifDetected level_ast.
#[local] Existing Instance OverlapSpecs.
Local Open Scope Z_scope.
#[local] Instance LayoutBridge : change_composite_env OverlapSpecs VerifDetected.CompSpecs.
 make_cs_preserve OverlapSpecs VerifDetected.CompSpecs.
Qed.

Definition view_without_blocks p a g st :=
 view_mem p a g (counters st (slack st) []).

Lemma split_view_blocks p a g st :
 view_mem p a g st = (view_without_blocks p a g st * array32 (blocked st) (blockp a))%logic.
Proof. unfold view_without_blocks,view_mem;cbn [counters slack blocked tight tight_extra forbidden].
 change (array32 [] (blockp a)) with emp;apply pred_ext;cancel. Qed.

(* The level holds a pointer to the same mutable block buffer as the policy.
   Only the view owns its contents while the callback is running. *)
Definition level_links s cp bp w path :=
 (@field_at VerifDetected.CompSpecs Tsh VerifDetected.level_type [StructField level_ast._w] (Vint (Int.repr w)) s *
  @field_at VerifDetected.CompSpecs Tsh VerifDetected.level_type [StructField level_ast._blk] bp s *
  @field_at VerifDetected.CompSpecs Tsh VerifDetected.level_type [StructField level_ast._cur] cp s *
  @data_at VerifDetected.CompSpecs Tsh (tarray tint (Zlength path)) (map Vint path) cp)%logic.
Lemma callbacks_share_block_buffer s cp p a g st w path : 0<Zlength (blocked st) ->
 (VerifChildVisit.child_fields s cp (blockp a) w (blocked st) path * view_without_blocks p a g st)%logic =
 (level_links s cp (blockp a) w path * view_mem p a g st)%logic.
Proof.
 intro nonempty;rewrite split_view_blocks,stored_array by assumption.
 erewrite (@data_at_change_composite OverlapSpecs VerifDetected.CompSpecs _ Tsh (tarray tuint (Zlength (blocked st)))
            (map Vint (blocked st)) (map Vint (blocked st)));[|apply JMeq_refl|reflexivity].
 unfold VerifChildVisit.child_fields,level_links;apply pred_ext;cancel.
Qed.
