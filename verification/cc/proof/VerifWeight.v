(* SPDX-License-Identifier: GPL-3.0-or-later. Candidate until coqc PASS. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_primitives.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition ccv_sum (xs:list Z) : Z := fold_right Z.add 0 xs.
Definition byte_values (xs:list Z) : list val := map (fun x=>Vint (Int.repr x)) xs.
Lemma ccv_sum_app xs ys : ccv_sum (xs++ys)=ccv_sum xs+ccv_sum ys.
Proof. induction xs;simpl;unfold ccv_sum in *;simpl in *;lia. Qed.
Lemma ccv_sum_bits_bounds xs : Forall (fun z=>z=0 \/ z=1) xs ->
 0<=ccv_sum xs<=Zlength xs.
Proof.
 intros H;induction H;simpl;unfold ccv_sum in *;simpl in *.
 - autorewrite with sublist;lia.
 - try rewrite Zlength_cons. destruct H;subst;lia.
Qed.
Definition weight_spec : ident * funspec :=
 DECLARE _ccv_weight
 WITH p:val, sh:share, xs:list Z
 PRE [tuint,tptr tuchar]
 PROP(readable_share sh; Forall (fun z=>z=0 \/ z=1) xs;
      Zlength xs<=Int.max_signed)
 PARAMS(Vint (Int.repr (Zlength xs));p)
 SEP(data_at sh (tarray tuchar (Zlength xs)) (byte_values xs) p)
 POST [tuint] PROP() RETURN(Vint (Int.repr (ccv_sum xs)))
 SEP(data_at sh (tarray tuchar (Zlength xs)) (byte_values xs) p).
Definition Gprog : funspecs := ltac:(with_library prog [weight_spec]).
Lemma body_weight : semax_body Vprog Gprog f_ccv_weight weight_spec.
Proof.
 start_function.
 forward.
 forward_for_simple_bound (Zlength xs)
 (EX i:Z,
  PROP()
  LOCAL(temp _n (Vint (Int.repr (Zlength xs)));temp _a p;
        temp _x (Vint (Int.repr (ccv_sum (sublist 0 i xs)))))
  SEP(data_at sh (tarray tuchar (Zlength xs)) (byte_values xs) p)).
 - entailer!.
 - assert (Hbounds:Forall (fun z=>0<=z<=1) xs).
   { eapply Forall_impl;[|eassumption]. intros z Hz;destruct Hz;subst;lia. }
   assert_PROP (0<=Znth i xs<=1).
   { entailer!;apply Forall_Znth;auto. }
   unfold byte_values.
   forward.
   { entailer!;rep_lia. }
   forward.
   entailer!.
   f_equal.
   rewrite (sublist_split 0 i (i+1)) by lia.
   rewrite ccv_sum_app,(sublist_one i) by lia.
   unfold ccv_sum;simpl;rewrite Z.add_0_r;reflexivity.
 - forward. entailer!. autorewrite with sublist;reflexivity.
Qed.
Print Assumptions body_weight.
