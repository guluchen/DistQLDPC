(* SPDX-License-Identifier: GPL-3.0-or-later. Candidate until coqc PASS. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition problem_type := Tstruct _ccv_problem noattr.
Definition workspace_type := Tstruct _ccv_workspace noattr.
Definition lbytes (xs:list Z) := map (fun z=>Vint(Int.repr z)) xs.
Definition has_nonzero xs := existsb (fun z=>negb (z=?0)) xs.
Lemma zeros_have_no_nonzero xs : Forall (fun z=>z=0) xs -> has_nonzero xs=false.
Proof. unfold has_nonzero;intros H;induction H;simpl;[reflexivity|subst;simpl;assumption]. Qed.
Lemma indexed_nonzero_exists xs i : 0<=i<Zlength xs -> Znth i xs<>0 -> has_nonzero xs=true.
Proof.
 intros Hi Hnz;unfold has_nonzero;apply existsb_exists;exists (Znth i xs);split.
 - apply Znth_In;assumption.
 - apply negb_true_iff;apply Z.eqb_neq;assumption.
Qed.
Definition nontrivial_spec : ident * funspec :=
 DECLARE _nontrivial
 WITH pp:val,wp:val,lp:val,sh:share,xs:list Z
 PRE [tptr problem_type,tptr workspace_type]
 PROP(readable_share sh;Zlength xs<=Int.max_signed;Forall (fun z=>z=0 \/ z=1) xs)
 PARAMS(pp;wp)
 SEP(field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr(Zlength xs))) pp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at sh (tarray tuchar (Zlength xs)) (lbytes xs) lp)
 POST [tint] PROP() RETURN(Vint(Int.repr(if has_nonzero xs then 1 else 0)))
 SEP(field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr(Zlength xs))) pp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at sh (tarray tuchar (Zlength xs)) (lbytes xs) lp).
Definition Gprog : funspecs := ltac:(with_library prog [nontrivial_spec]).
Lemma body_nontrivial : semax_body Vprog Gprog f_nontrivial nontrivial_spec.
Proof.
 start_function.
 assert (Hbounds:Forall (fun z=>0<=z<=1) xs).
 { eapply Forall_impl;[|eassumption]. intros z Hz;destruct Hz;subst;lia. }
 forward.
 forward_loop
 (EX i:Z,
  PROP(0<=i<=Zlength xs;Forall (fun z=>z=0) (sublist 0 i xs))
  LOCAL(temp _p pp;temp _w wp;temp _i (Vint(Int.repr i)))
  SEP(field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr(Zlength xs))) pp;
      field_at sh workspace_type [StructField _logical_value] lp wp;
      data_at sh (tarray tuchar (Zlength xs)) (lbytes xs) lp))%assert
 break:
 (PROP(Forall (fun z=>z=0) xs)
  LOCAL()
  SEP(field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr(Zlength xs))) pp;
      field_at sh workspace_type [StructField _logical_value] lp wp;
      data_at sh (tarray tuchar (Zlength xs)) (lbytes xs) lp))%assert.
 - Exists 0;entailer!;autorewrite with sublist;constructor.
 - Intros i.
   forward.
   forward_if.
   + forward.
     assert (Hchar:0<=Znth i xs<=1) by (apply Forall_Znth;auto;lia).
     unfold lbytes.
     forward.
     { entailer!;rep_lia. }
     forward_if.
     * assert (Hnz:has_nonzero xs=true) by (apply indexed_nonzero_exists with (i:=i);auto;lia).
       forward. entailer!;rewrite Hnz;reflexivity.
     * forward.
       Exists (i+1);entailer!.
       rewrite (sublist_split 0 i (i+1)) by lia.
       apply Forall_app;split;[assumption|].
       rewrite (sublist_one i) by lia.
       constructor;[lia|constructor].
   + assert (i=Zlength xs) by lia;subst i.
     forward. entailer!;autorewrite with sublist in *;assumption.
 - Intros.
   assert (Hnone:has_nonzero xs=false) by (apply zeros_have_no_nonzero;assumption).
   forward. entailer!;rewrite Hnone;reflexivity.
Qed.
Print Assumptions body_nontrivial.
