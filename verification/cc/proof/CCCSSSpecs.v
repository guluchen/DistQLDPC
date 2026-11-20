(* CSS-facing interpretation of the existing C API, with explicit completeness
   of supplied logical detectors. Definition only until refinement is checked. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCCSSResultBridge CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition css_distance_spec:ident*funspec:=
 DECLARE ccv_core._ccv_distance
 WITH a:half_model,p:kernel_pointers,dp:val,sh:share,budget:Z,rules:Z,same:list CCModel.vector
 PRE[tptr CCSearchSpecs.problem_type,tuint,tuint,tptr CCSearchSpecs.workspace_type,tptr tuchar,tptr tuint,tptr CCSearchSpecs.stats_type]
 PROP(readable_share sh;legal_model a;complete_css_model a same;
      Forall(CCModel.kernel(Z.to_nat(model_n a))(model_h_rows a))same;workspace_extent a p;
      0<=budget<=Int.max_unsigned;0<=rules<=63)
 PARAMS(ptr_problem p;Vint(Int.repr budget);Vint(Int.repr rules);
        ptr_workspace p;ptr_out p;dp;ptr_stats p)
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
