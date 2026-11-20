(* Normal-return block framing, including an existential result.
   Keeps the VST frame obligation explicit; no C body is assumed here. *)
Require Import VST.floyd.proofauto.
Section Proof.
Context{CS:compspecs}{Espec:OracleKind}.
Lemma semax_normal_block_frame Delta P Q c F:
 closed_wrt_modvars c F ->
 semax Delta P c(normal_ret_assert Q) ->
 semax Delta(P*F)%logic c(normal_ret_assert(Q*F)%logic).
Proof.
 intros Closed Body.
 eapply semax_post with(R':=frame_ret_assert(normal_ret_assert Q)F).
 - cbn[RA_normal frame_ret_assert normal_ret_assert];apply andp_left2;apply derives_refl.
 - cbn[RA_break frame_ret_assert normal_ret_assert];normalize.
 - cbn[RA_continue frame_ret_assert normal_ret_assert];normalize.
 - intros vl;cbn[RA_return frame_ret_assert normal_ret_assert];normalize.
 - eapply semax_frame;assumption.
Qed.
Lemma semax_exists_block_frame{A:Type}Delta P(Q:A->assert)c F:
 closed_wrt_modvars c F ->
 semax Delta P c(normal_ret_assert(EX x:A,Q x)%assert) ->
 semax Delta(P*F)%logic c(normal_ret_assert(EX x:A,(Q x*F)%logic)%assert).
Proof.
 intros Closed Body.
 eapply semax_post' with(R':=((EX x:A,Q x)*F)%logic).
 - apply andp_left2;normalize. Exists x;apply derives_refl.
 - apply semax_normal_block_frame;assumption.
Qed.
End Proof.
Print Assumptions semax_exists_block_frame.
