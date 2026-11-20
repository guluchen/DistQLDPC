(* Exact shared finish conditional when finish=0. Arbitrary caller assertions
   are kept through the unreachable modifying branch without a false frame
   side-condition. This does not prove the whole search body. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.VerifSearchFinish.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition finish_zero:assert:=local(locald_denote(temp _finish(Vint Int.zero))).
Lemma search_finish_layout:search_finish=Sifthenelse(Etempvar _finish tint)finish_body Sskip.
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_finish_skip(I:assert):
 semax CCSearchContext.Delta(I&&finish_zero)%logic search_finish(normal_ret_assert I).
Proof.
 rewrite search_finish_layout.
 eapply semax_pre;[|apply semax_ifthenelse with(P:=(I&&finish_zero)%logic)].
 - go_lowerx. eapply derives_trans;[|apply now_later].
   unfold finish_zero;normalize;entailer!.
   + unfold locald_denote in H0;unfold_lift in H0.
     destruct H0 as[Eq NZ];unfold eval_id in Eq.
     destruct(Map.get(te_of rho)_finish)as[v|]eqn:Lookup;cbn[force_val]in Eq.
     * subst v;exists(Vint Int.zero);split;[reflexivity|simpl;auto].
     * discriminate.
   + apply andp_right;[apply derives_refl|apply prop_right;exact H0].
 - reflexivity.
 - eapply semax_pre;[|apply semax_ff].
   unfold finish_zero. go_lowerx;normalize. cbn[eval_expr]in *.
   unfold locald_denote in *;unfold_lift in *.
   repeat match goal with H: _ /\ _ |- _=>destruct H end.
   rewrite <-H0 in H1. exfalso;vm_compute in H1;discriminate.
 - eapply semax_pre;[|apply semax_skip].
   unfold finish_zero. go_lowerx;normalize;cancel.
Qed.
End Proof.
Print Assumptions block_finish_skip.

Definition finish_zero_frame:assert:=(PROP()LOCAL(temp _finish(Vint Int.zero))SEP())%assert.
Lemma finish_zero_frame_intro(I:assert):
 (I&&finish_zero)%logic |--(I*finish_zero_frame)%logic.
Proof. unfold finish_zero,finish_zero_frame;go_lowerx;normalize;entailer!. Qed.
Lemma finish_zero_frame_elim(I:assert):
 (I*finish_zero_frame)%logic |--(I&&finish_zero)%logic.
Proof. unfold finish_zero,finish_zero_frame;go_lowerx;normalize;entailer!. Qed.
Print Assumptions finish_zero_frame_intro.
Print Assumptions finish_zero_frame_elim.
