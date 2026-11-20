(* CSS API correctness from an executable Coq certificate precondition.
   This is not a C implementation of the checker or native preprocessing. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCCSSResultBridge CCV.CCCSSSpecs
 CCV.CCQuotientCertificate CCV.VerifCSSDistance CCV.VerifDistance CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition certified_css_distance_spec:ident*funspec:=
 DECLARE ccv_core._ccv_distance
 WITH a:half_model,p:kernel_pointers,dp:val,sh:share,budget:Z,rules:Z,
      same:list CCModel.vector,c:quotient_certificate
 PRE[tptr CCSearchSpecs.problem_type,tuint,tuint,tptr CCSearchSpecs.workspace_type,tptr tuchar,tptr tuint,tptr CCSearchSpecs.stats_type]
 PROP(readable_share sh;legal_model a;
      check_quotient_certificate(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)same c=true;
      workspace_extent a p;0<=budget<=Int.max_unsigned;0<=rules<=63)
 PARAMS(ptr_problem p;Vint(Int.repr budget);Vint(Int.repr rules);ptr_workspace p;ptr_out p;dp;ptr_stats p)
 SEP(problem_repr sh a p;workspace_fields sh p;workspace_any a p;
     data_at_ Tsh(tarray tuchar(model_n a))(ptr_out p);
     data_at_ Tsh tuint dp;data_at_ Tsh CCSearchSpecs.stats_type(ptr_stats p))
 POST[tint] EX ret:Z,EX out:list Z,EX d:Z,EX s1:stats_model,
 PROP(Zlength out=model_n a;Forall(fun z:Z=>z=0\/z=1)out;legal_stats budget s1;
      0<=d<=model_n a;css_distance_result a same ret out d)
 RETURN(Vint(Int.repr ret))
 SEP(problem_repr sh a p;workspace_fields sh p;
     (if Z.eq_dec ret 1 then workspace_any a p else workspace_zero a p);
     data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p);
     data_at Tsh tuint(Vint(Int.repr d))dp;stats_repr(ptr_stats p)s1).
Lemma certified_css_distance_sub:
 funspec_sub(snd css_distance_spec)(snd certified_css_distance_spec).
Proof.
 do_funspec_sub.
 destruct w as [[[[[[[a p]dp]sh]budget]rules]same]c]. cbn[fst snd];normalize.
 pose proof(check_quotient_certificate_sound(Z.to_nat(model_n a))
 (model_h_rows a)(model_l_rows a)same c ltac:(assumption))as[Comm Complete].
 change(complete_css_model a same)in Complete.
 Exists(a,p,dp,sh,budget,rules,same)emp. apply andp_right.
 - entailer!;cancel.
 - apply prop_right;intros rho';normalize.
   lazymatch goal with
   | HR:css_distance_result a same ?ret ?out ?d,HS:legal_stats budget ?s |- _ =>
     Exists ret out d s
   end.
   entailer!;cancel.
Qed.
Theorem body_distance_certified: @semax_body VerifDistance.Vprog VerifDistance.Gprog
 VerifDistance.CompSpecs ccv_core.f_ccv_distance certified_css_distance_spec.
Proof.
 eapply semax_body_funspec_sub.
 - exact body_distance_css.
 - exact certified_css_distance_sub.
 - vm_compute. repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
Print Assumptions certified_css_distance_sub.
Print Assumptions body_distance_certified.
Lemma distance_certificate_sub:
 funspec_sub(snd CCSearchSpecs.distance_spec)(snd certified_css_distance_spec).
Proof.
 eapply funspec_sub_trans.
 - exact distance_css_sub.
 - exact certified_css_distance_sub.
Qed.
Print Assumptions distance_certificate_sub.
