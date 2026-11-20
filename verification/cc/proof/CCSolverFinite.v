(* Resolve all callees of the two public interfaces in the actual
   verification program. The lookup lemmas keep both bodies symbolic. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.lib.Maps.
Require Import CCV.ccv_core CCV.CCExpandedBody CCV.CCBoundedMain CCV.CCBodyProgram
 CCV.CCFiniteDrivers CCV.CCFiniteSearch CCV.CCScanCallees CCV.CCCapGuard.
Lemma proof_helpers s d:helpers_bound (proof_driver s d).
Proof.
 intros id fn Member;unfold helper_bindings in Member;cbn [List.In] in Member;
 repeat destruct Member as [E|Member];try contradiction;inversion E;subst;reflexivity.
Qed.
Lemma proof_public_bindings s d:forall id fn,In(id,fn)(driver_bindings s) ->
 PTree.get id (AST.prog_defmap (proof_driver s d))=Some(Gfun(Internal fn)).
Proof.
 intros id fn Member;unfold driver_bindings in Member;cbn [List.In] in Member;
 repeat destruct Member as [E|Member];try contradiction;inversion E;subst;reflexivity.
Qed.
Section Finite.
Variable n:nat.
Local Notation s := (body_with (bounded_main n)).
Local Notation p :=(proof_driver s (fn_body guarded_distance)).
Local Notation ge := (Clight.globalenv p).
Lemma proof_search_finite :call_settles ge (with_body f_search s).
Proof. apply expanded_search_settles;apply proof_helpers. Qed.
Lemma proof_decide_finite :call_settles ge f_ccv_decide.
Proof. apply(finite_decide_raw p s);first[apply proof_public_bindings|apply proof_helpers|apply proof_search_finite]. Qed.
Lemma proof_distance_finite :call_settles ge guarded_distance.
Proof. apply(finite_distance_raw p s);first[apply proof_public_bindings|apply proof_helpers|apply proof_search_finite]. Qed.
End Finite.
