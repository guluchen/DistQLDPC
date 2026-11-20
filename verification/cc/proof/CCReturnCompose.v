(* A checked returning block can occur before unreachable source statements.
   No implementation or termination hypothesis is introduced. *)
Require Import VST.floyd.proofauto.
Section Proof.
Context{CS:compspecs}{Espec:OracleKind}.
Lemma returned_sequence Delta P c d R Q:
 RA_normal R=FF ->semax Delta P c R ->
 semax Delta P(Ssequence c d)(overridePost Q R).
Proof.
 intros Normal Body.
 eapply semax_seq with(Q:=FF).
 - destruct R as[RN RB RC RR];cbn in Normal;subst RN;exact Body.
 - apply semax_ff.
Qed.
Lemma function_block_post Delta P c t PostOld PostNew:
 PostOld |-- PostNew ->
 semax Delta P c(function_body_ret_assert t PostOld) ->
 semax Delta P c(function_body_ret_assert t PostNew).
Proof.
 intros Ent Body.
 eapply semax_post with(R':=function_body_ret_assert t PostOld).
 - cbn[RA_normal function_body_ret_assert];apply andp_left2;apply bind_ret_derives;assumption.
 - cbn[RA_break function_body_ret_assert];normalize.
 - cbn[RA_continue function_body_ret_assert];normalize.
 - intros vl;cbn[RA_return function_body_ret_assert];apply andp_left2;apply bind_ret_derives;assumption.
 - exact Body.
Qed.
End Proof.
Print Assumptions returned_sequence.

Print Assumptions function_block_post.
