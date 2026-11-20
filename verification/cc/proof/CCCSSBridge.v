(* Mathematical CSS interpretation, CONDITIONAL on a complete logical quotient.
   Does not verify the PCM parser/Gaussian constructor or the C/C++ search. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional.
Import ListNotations.
Fixpoint linear_combination (rows:list vector)(coeffs:list bool):vector:=
 match rows,coeffs with
 |r::rs,b::bs=>if b then vxor r(linear_combination rs bs)else linear_combination rs bs
 |_,_=>zero_vector end.
Definition rowspan n rows e:=exists coeffs,
 length coeffs=length rows /\
 forall i,i<n ->e i=linear_combination rows coeffs i.
Definition css_quotient n checks same logicals:=forall e,
 kernel n checks e ->(rowspan n same e <->kernel n logicals e).
Definition css_logical n checks same e:=kernel n checks e /\~rowspan n same e.
Definition css_minimum n checks same e:=css_logical n checks same e /\
 forall f,css_logical n checks same f ->weight n e<=weight n f.
Lemma zero_kernel n rows:kernel n rows zero_vector.
Proof. intros h Hin;apply weight_zero_parity_false;apply zero_weight. Qed.
Lemma combination_kernel n checks rows:
 Forall(kernel n checks)rows ->forall coeffs,kernel n checks(linear_combination rows coeffs).
Proof.
 intros Valid;induction Valid as[|r rs Kr Tail IH];intros[|b bs];simpl;try apply zero_kernel.
 destruct b;[|apply IH].
 intros h Hin;rewrite parity_xor,(Kr h Hin),(IH bs h Hin);reflexivity.
Qed.
Theorem rowspan_kernel n checks rows e:
 Forall(kernel n checks)rows ->rowspan n rows e ->kernel n checks e.
Proof.
 intros Valid[coeffs[Len Eq]]h Hin.
 rewrite(parity_ext n h e(linear_combination rows coeffs)Eq).
 apply(combination_kernel n checks rows Valid coeffs h Hin).
Qed.
Lemma logical_iff_not_kernel n rows e:logical n rows e <->~kernel n rows e.
Proof.
 split.
 - intros[h[Hin Odd]]Ker;pose proof(Ker h Hin);congruence.
 - intros Not;destruct(existsb(fun h=>parity n h e)rows)eqn:B.
   + apply existsb_exists in B;exact B.
   + exfalso;apply Not;intros h Hin;exact(existsb_parity_false n rows e B h Hin).
Qed.
Theorem good_iff_css_logical n checks same logicals e:
 css_quotient n checks same logicals ->
 (good n checks logicals e <->css_logical n checks same e).
Proof.
 intros Quot;split.
 - intros[Pos[Ker Log]];split;[assumption|].
   intros Span;apply(logical_iff_not_kernel n logicals e)in Log.
   apply Log;apply(proj1(Quot e Ker));assumption.
 - intros[Ker NotSpan].
   assert(Log:logical n logicals e).
   { apply logical_iff_not_kernel;intro K;apply NotSpan;apply(proj2(Quot e Ker));assumption. }
   split;[apply(logical_positive n logicals e);assumption|split;assumption].
Qed.
Theorem minimum_iff_css_minimum n checks same logicals e:
 css_quotient n checks same logicals ->
 (minimum n checks logicals e <->css_minimum n checks same e).
Proof.
 intros Quot;split;intros[Good Best];split.
 - apply(proj1(good_iff_css_logical n checks same logicals e Quot));assumption.
 - intros f G;apply Best;apply(proj2(good_iff_css_logical n checks same logicals f Quot));assumption.
 - apply(proj2(good_iff_css_logical n checks same logicals e Quot));assumption.
 - intros f G;apply Best;apply(proj1(good_iff_css_logical n checks same logicals f Quot));assumption.
Qed.
Print Assumptions rowspan_kernel.
Print Assumptions minimum_iff_css_minimum.
