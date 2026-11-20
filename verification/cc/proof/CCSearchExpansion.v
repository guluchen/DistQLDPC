(* The proof works at symbolic depth. Keeping the fixed machine bound
   opaque prevents construction of a multi-billion-node proof term. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCBoundedMain CCV.CCSearchSpecs CCV.CCSearchContext
 CCV.CCLoopInvariant CCV.CCSearchExit CCV.VerifMainLoop.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition word_heads := S (Z.to_nat Int.max_unsigned).
Lemma word_heads_large : Int.max_unsigned < Z.of_nat word_heads.
Proof. unfold word_heads;rewrite Nat2Z.inj_succ,Z2Nat.id;rep_lia. Qed.
Global Opaque word_heads.
Section Checked.
Context {Espec:OracleKind}.
Lemma expanded_main_spec sh a p tp rp cap seed budget rules s0 :
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->0<=rules<=63 ->
 semax CCSearchContext.Delta (search_while_invariant sh a p tp rp cap seed budget rules s0)
 (bounded_main word_heads)
 (overridePost(main_loop_finished sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros;unfold search_while_invariant at 1;Intros path ghosts log buf xs ys zs pk frames s.
 eapply semax_pre.
 2:{ apply (checked_bounded_main sh a p tp rp cap seed budget rules s0) with (n:=word_heads) (base:=s);try eassumption.
     unfold legal_stats in *;pose proof word_heads_large;lia. }
 unfold search_while_invariant;Exists path ghosts log buf xs ys zs pk frames s.
 assert (stats_monotone s s) by (unfold stats_monotone;lia);entailer!;cancel.
Qed.
End Checked.
