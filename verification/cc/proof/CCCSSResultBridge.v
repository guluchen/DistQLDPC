(* Interpret the implemented generic H/L contracts as CSS distance contracts.
   Completeness of the supplied logical detectors is an explicit hypothesis;
   same is a ghost reference to the full same-Pauli stabilizer rows; pruning
   rows model_g may be only a subset. This is not a proof of the PCM parser
   or logical-detector constructor. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCRepresentation CCV.CCCSSBridge CCV.CCSearchSpecs.
Import ListNotations. Open Scope Z_scope.
Definition complete_css_model a same:=css_quotient(Z.to_nat(model_n a))
 (model_h_rows a)same(model_l_rows a).
Definition css_model_logical a same e:=css_logical(Z.to_nat(model_n a))
 (model_h_rows a) same e.
Definition css_model_minimum a same e:=css_minimum(Z.to_nat(model_n a))
 (model_h_rows a) same e.
Lemma model_good_css a same e:complete_css_model a same ->
 (model_good a e <->css_model_logical a same e).
Proof. apply good_iff_css_logical. Qed.
Lemma model_minimum_css a same e:complete_css_model a same ->
 (model_minimum a e <->css_model_minimum a same e).
Proof. apply minimum_iff_css_minimum. Qed.
Definition css_query_result a same cap ret out:=
 (ret=(-1) /\out=Zrepeat 0(model_n a)) \/
 (ret=0 /\out=Zrepeat 0(model_n a) /\
  forall e,css_model_logical a same e ->cap<Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e)) \/
 (ret=1 /\css_model_logical a same(decode out) /\output_weight a out<=cap).
Definition css_distance_result a same ret out distance:=
 (ret=(-1) /\out=Zrepeat 0(model_n a) /\distance=0) \/
 (ret=0 /\out=Zrepeat 0(model_n a) /\distance=0 /\~exists e,css_model_logical a same e) \/
 (ret=1 /\css_model_minimum a same(decode out) /\distance=output_weight a out).
Theorem query_result_is_css a same cap ret out:complete_css_model a same ->
 query_result a cap ret out ->css_query_result a same cap ret out.
Proof.
 intros Complete[Unknown|[Empty|Found]].
 - left;exact Unknown.
 - right;left;destruct Empty as[R[O NoGood]]. repeat split;try assumption.
   intros e Css;apply NoGood;apply(proj2(model_good_css a same e Complete));exact Css.
 - right;right;destruct Found as[R[G W]]. split;[exact R|split;[|exact W]].
   apply(proj1(model_good_css a same(decode out)Complete));exact G.
Qed.
Theorem minimum_result_is_css a same ret out distance:complete_css_model a same ->
 minimum_result a ret out distance ->css_distance_result a same ret out distance.
Proof.
 intros Complete[Unknown|[Empty|Found]].
 - left;exact Unknown.
 - right;left;destruct Empty as[R[O[D NoGood]]]. repeat split;try assumption.
   intros[e Css];apply NoGood;exists e;apply(proj2(model_good_css a same e Complete));exact Css.
 - right;right;destruct Found as[R[M D]]. split;[exact R|split;[|exact D]].
   apply(proj1(model_minimum_css a same(decode out)Complete));exact M.
Qed.
Print Assumptions query_result_is_css.
Print Assumptions minimum_result_is_css.
