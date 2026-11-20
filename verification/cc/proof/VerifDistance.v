(* Modular C distance-driver proof candidate. The search callee is not yet
   proved; successful checking here would not verify the linked solver. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.VerifToggle CCV.CCModel CCV.CCRepresentation CCV.CCWeightBridge CCV.CCSearchSpecs CCV.CCAPIBridge CCV.VerifStats CCV.VerifShape CCV.VerifValidate CCV.VerifClear CCV.VerifWeight CCV.CCFunctional.
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
#[export] Instance VerifWeightPreserve :change_composite_env VerifWeight.CompSpecs CompSpecs.
 make_cs_preserve VerifWeight.CompSpecs CompSpecs.
Defined.
Definition Vprog :varspecs. mk_varspecs prog. Defined.
Definition Gprog :funspecs :=ltac:(with_library prog
 [VerifStats.stats_init_spec;VerifShape.shape_spec;VerifValidate.validate_spec;
  VerifClear.clear_spec;VerifWeight.weight_spec;CCSearchSpecs.search_spec;CCSearchSpecs.distance_spec]).
Lemma body_distance_modular :semax_body Vprog Gprog f_ccv_distance CCSearchSpecs.distance_spec.
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
 (PROP() LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _distance dp;temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _s(ptr_stats p);temp _t'2(Vint Int.zero)) SEP(problem_repr sh a p;workspace_fields sh p;workspace_any a p;data_at_ Tsh(tarray tuchar(model_n a))(ptr_out p);data_at_ Tsh tuint dp;stats_repr(ptr_stats p)zero_stats))%assert.
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
 forward.
 forward.
 assert(ZS:legal_stats budget zero_stats)by(apply zero_stats_legal;assumption).
 assert(Lower1:forall e,model_good a e ->1<=Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e))by(intros e Good;pose proof(model_good_positive a e Good);lia).
 forward_loop
 (EX c:Z,EX s0:stats_model,
 PROP(1<=c<=model_n a+1;legal_stats budget s0;
      forall e,model_good a e ->c<=Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e))
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
       temp _distance dp;temp _s(ptr_stats p);temp _budget(Vint(Int.repr budget));
       temp _rules(Vint(Int.repr rules));temp _cap(Vint(Int.repr c)))
 SEP(problem_repr sh a p;workspace_fields sh p;workspace_zero a p;
     data_at Tsh(tarray tuchar(model_n a))(zero_bytes(model_n a))(ptr_out p);
     data_at Tsh tuint(Vint Int.zero)dp;stats_repr(ptr_stats p)s0))%assert
 break:
 (EX s0:stats_model,
 PROP(legal_stats budget s0;~exists e,model_good a e)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
       temp _distance dp;temp _s(ptr_stats p);temp _budget(Vint(Int.repr budget));
       temp _rules(Vint(Int.repr rules)))
 SEP(problem_repr sh a p;workspace_fields sh p;workspace_zero a p;
     data_at Tsh(tarray tuchar(model_n a))(zero_bytes(model_n a))(ptr_out p);
     data_at Tsh tuint(Vint Int.zero)dp;stats_repr(ptr_stats p)s0))%assert.
 { Exists 1 zero_stats. entailer!. unfold problem_repr,workspace_fields,workspace_zero. rewrite !zero_bytes_repr. cancel. }
 { Intros c s0.
   unfold problem_repr,workspace_fields.
   Intros.
   change_compspecs CompSpecs.
   forward.
   forward_if.
   - forward_call(a,p,sh,c,budget,rules,s0).
     { unfold problem_repr,workspace_fields;entailer!;cancel. }
     Intros vret. destruct vret as [[ret out]s1];cbn[fst snd]in *.
     match goal with Q:query_result a c ret out |- _ =>destruct Q as[Unknown|[Empty|Found]] end.
     + destruct Unknown as[Ret Out];subst ret out.
       cbn [Z.eq_dec].
       forward_if.
       { exfalso;lia. }
       forward_if.
       { forward. Exists(-1)(Zrepeat 0(model_n a))0 s1.
         entailer!;unfold minimum_result;left;auto. }
       { exfalso;lia. }
     + destruct Empty as[Ret[Out Empty]];subst ret out.
       rewrite if_false by lia.
       forward_if. { exfalso;lia. }
       forward_if. { exfalso;lia. }
       pose proof(empty_advances_distance_lower a c Empty)as NextLower.
       forward. Exists(c+1)s1;entailer!.
     + destruct Found as[Ret[Good Bound]];subst ret.
       cbn [Z.eq_dec].
       forward_if.
       { unfold problem_repr,workspace_fields;Intros.
         change_compspecs CompSpecs.
         forward.
         forward_call(ptr_out p,Tsh,out).
         { entailer!.
           assert(OP:isptr(ptr_out p))by(eapply field_compatible_isptr;eassumption).
           match goal with Len:Zlength out=model_n a |- _ =>rewrite Len end.
           destruct(ptr_out p);simpl in OP;try contradiction;reflexivity. }
         { unfold VerifWeight.byte_values,tbytes. match goal with Len:Zlength out=model_n a |- _ =>rewrite Len end. cancel. }
         assert(W:ccv_sum out=output_weight a out).
         { apply output_weight_runtime;assumption. }
         rewrite W. match goal with Len:Zlength out=model_n a |- _ =>rewrite Len end.
         try change_compspecs CompSpecs.
         forward.
         forward.
         Exists 1 out(output_weight a out)s1.
         entailer!.
         { split.
           - unfold output_weight;split;[lia|apply model_good_weight_bound;lia].
           - unfold minimum_result;right;right;split;[reflexivity|split;[apply(found_at_first_cap_minimum a c(decode out));assumption|reflexivity]]. }
         { unfold problem_repr,workspace_fields;cancel. }
       }
       { exfalso;lia. }
   - assert(Exhaust:~exists e,model_good a e).
     { intros[e Good].
       match goal with Lower:forall e,model_good a e ->c<=_ |- _ =>pose proof(Lower e Good)end.
       pose proof(model_good_weight_bound a e ltac:(lia));lia. }
     forward.
     Exists s0;unfold problem_repr,workspace_fields;entailer!. }
 Intros s0.
 assert(BZ:Forall(fun z:Z=>z=0 \/z=1)(Zrepeat 0(model_n a)))by(unfold Zrepeat;apply Forall_repeat;auto).
 assert(LZ:Zlength(Zrepeat 0(model_n a))=model_n a)by(rewrite Zlength_Zrepeat;lia).
 forward.
 Exists 0(Zrepeat 0(model_n a))0 s0.
 entailer!.
 { unfold minimum_result;right;left;auto. }
 rewrite if_false by lia;cancel.
Unshelve.
Qed.
Print Assumptions body_distance_modular.
