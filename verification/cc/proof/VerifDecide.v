(* Modular C driver proof candidate. The search_spec callee body is not yet
   proved; this file must never be reported as whole-program verification. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.VerifToggle CCV.CCModel CCV.CCRepresentation CCV.CCWeightBridge CCV.CCSearchSpecs CCV.CCAPIBridge CCV.VerifStats CCV.VerifShape CCV.VerifValidate CCV.VerifClear.
Import ListNotations.
Open Scope Z_scope.
#[export] Instance CompSpecs :compspecs. make_compspecs prog. Defined.
#[export] Instance VerifStatsPreserve :change_composite_env VerifStats.CompSpecs CompSpecs.
 make_cs_preserve VerifStats.CompSpecs CompSpecs.
Defined.
#[export] Instance VerifShapePreserve :change_composite_env VerifShape.CompSpecs CompSpecs.
 make_cs_preserve VerifShape.CompSpecs CompSpecs.
Defined.
#[export] Instance VerifValidatePreserve :change_composite_env VerifValidate.CompSpecs CompSpecs.
 make_cs_preserve VerifValidate.CompSpecs CompSpecs.
Defined.
#[export] Instance VerifClearPreserve :change_composite_env VerifClear.CompSpecs CompSpecs.
 make_cs_preserve VerifClear.CompSpecs CompSpecs.
Defined.
#[export] Instance CCSearchSpecsPreserve :change_composite_env CCSearchSpecs.CompSpecs CompSpecs.
 make_cs_preserve CCSearchSpecs.CompSpecs CompSpecs.
Defined.
Definition Vprog :varspecs. mk_varspecs prog. Defined.
Definition Gprog :funspecs :=ltac:(with_library prog
 [VerifStats.stats_init_spec;VerifShape.shape_spec;VerifValidate.validate_spec;
  VerifClear.clear_spec;CCSearchSpecs.search_spec;CCSearchSpecs.decide_spec]).
Lemma body_decide_modular :semax_body Vprog Gprog f_ccv_decide CCSearchSpecs.decide_spec.
Proof.
 start_function.
 match goal with H:legal_model a |- _ =>pose proof(legal_model_ranges a H)as Ranges;pose proof(legal_model_validation a H)as Validation end.
 unfold CCSearchSpecs.problem_repr,CCSearchSpecs.workspace_fields,CCSearchSpecs.workspace_any.
 Intros.
 forward_call(ptr_stats p).
 forward_call(ptr_problem p,ptr_workspace p,sh,model_n a,model_m a,model_l a,model_k a,
              workspace_capacity p,workspace_frame_capacity p,rules).
 { unfold legal_model,workspace_extent in *;tauto. }
 forward_if
 (PROP() LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _cap(Vint(Int.repr cap));temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _s(ptr_stats p);temp _t'2(Vint Int.zero)) SEP(problem_repr sh a p;workspace_fields sh p;workspace_any a p;data_at_ Tsh(tarray tuchar(model_n a))(ptr_out p);stats_repr(ptr_stats p)zero_stats))%assert.
 { forward;entailer!;unfold problem_repr,workspace_fields,workspace_any;cancel. }
 {
 forward_call(ptr_problem p,ptr_h p,ptr_lg p,ptr_g p,sh,model_n a,model_m a,model_l a,model_k a,
              model_h a,model_lg a,model_g a).
 { unfold legal_model in *;tauto. }
 forward.
 entailer!;unfold problem_repr,workspace_fields,workspace_any;cancel.
 }
 forward_if.
 { exfalso;congruence. }
 unfold problem_repr,workspace_fields,workspace_any. Intros.
 unfold data_at_.
 forward_call(ptr_problem p,ptr_workspace p,ptr_out p,ptr_selected p,ptr_forbidden p,ptr_packed p,
              ptr_syndrome p,ptr_logical_value p,sh,model_n a,model_m a,model_l a,
              Zrepeat Vundef(model_n a),Zrepeat Vundef(model_n a),Zrepeat Vundef(model_n a),
              Zrepeat Vundef(model_n a),Zrepeat Vundef(model_m a),Zrepeat Vundef(model_l a)).
 { rewrite !Zlength_Zrepeat by lia;repeat split;reflexivity. }
 forward_call(a,p,sh,cap,budget,rules,zero_stats).
 { unfold problem_repr,workspace_fields,workspace_zero. rewrite !zero_bytes_repr. entailer!;cancel. }
 { apply zero_stats_legal;assumption. }
 Intros vret. destruct vret as [[ret out]s1];cbn[fst snd]in *.
 forward.
 Exists ret out s1;entailer!.
Qed.
Print Assumptions body_decide_modular.
