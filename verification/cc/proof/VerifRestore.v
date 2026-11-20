(* SPDX-License-Identifier: GPL-3.0-or-later. Candidate until checker PASS. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition rbytes (xs:list Z) := map (fun z=>Vint(Int.repr z)) xs.
Definition zero_indices (xs:list Z) (indices:list Z) :=
 fold_left (fun a q=>upd_Znth q a 0) indices xs.
Definition restored xs entries lo hi := zero_indices xs (rev (sublist lo hi entries)).
Lemma zero_indices_bits xs indices : Forall (fun z=>z=0 \/ z=1) xs ->
 Forall (fun z=>z=0 \/ z=1) (zero_indices xs indices).
Proof.
 unfold zero_indices;revert xs;induction indices;intros xs H;simpl;[assumption|].
 apply IHindices;apply Forall_upd_Znth;[assumption|left;reflexivity].
Qed.
Lemma zero_indices_length xs indices n : Zlength xs=n ->
 Forall (fun q=>0<=q<n) indices -> Zlength (zero_indices xs indices)=n.
Proof.
 unfold zero_indices;revert xs;induction indices;intros xs Hlen Hr;simpl;[assumption|].
 inversion Hr;subst;apply IHindices;[rewrite upd_Znth_Zlength by lia;auto|assumption].
Qed.
Lemma restored_length xs entries lo hi n : Zlength xs=n ->
 Forall (fun q=>0<=q<n) entries -> Zlength (restored xs entries lo hi)=n.
Proof.
 intros Hlen Hr;unfold restored;apply zero_indices_length;[assumption|].
 apply Forall_rev;apply Forall_sublist;assumption.
Qed.
Lemma restored_same xs entries hi : restored xs entries hi hi=xs.
Proof. unfold restored,zero_indices;autorewrite with sublist;reflexivity. Qed.
Lemma restored_step xs entries lo hi : 0<=lo<hi -> hi<=Zlength entries ->
 restored xs entries lo hi=upd_Znth (Znth lo entries) (restored xs entries (lo+1) hi) 0.
Proof.
 intros H Hhi;unfold restored,zero_indices.
 rewrite (sublist_split lo (lo+1) hi) by lia.
 rewrite (sublist_one lo) by lia.
 rewrite rev_app_distr;simpl;rewrite fold_left_app;simpl;reflexivity.
Qed.
Definition workspace_type := Tstruct _ccv_workspace noattr.
Definition restore_spec : ident * funspec :=
 DECLARE _restore
 WITH wp:val,tp:val,fp:val,up:val,sh:share,n:Z,t:Z,mark:Z,xs:list Z,entries:list Z
 PRE [tptr workspace_type,tptr tuint,tuint]
 PROP(readable_share sh;0<n<=Int.max_signed;0<=mark<=t; t<=n;
      Zlength xs=n;Zlength entries=t;
      Forall (fun z=>z=0 \/ z=1) xs;Forall (fun q=>0<=q<n) entries)
 PARAMS(wp;tp;Vint(Int.repr mark))
 SEP(field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _undo] up wp;
     data_at Tsh tuint (Vint(Int.repr t)) tp;
     data_at Tsh (tarray tuchar n) (rbytes xs) fp;
     data_at sh (tarray tuint t) (rbytes entries) up)
 POST [tvoid] PROP() RETURN()
 SEP(field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _undo] up wp;
     data_at Tsh tuint (Vint(Int.repr mark)) tp;
     data_at Tsh (tarray tuchar n) (rbytes(restored xs entries mark t)) fp;
     data_at sh (tarray tuint t) (rbytes entries) up).
Definition Gprog : funspecs := ltac:(with_library prog [restore_spec]).
Lemma body_restore : semax_body Vprog Gprog f_restore restore_spec.
Proof.
 start_function.
 forward_loop
 (EX i:Z,
  PROP(mark<=i<=t)
  LOCAL(temp _w wp;temp _top tp;temp _mark (Vint(Int.repr mark)))
  SEP(field_at sh workspace_type [StructField _forbidden] fp wp;
      field_at sh workspace_type [StructField _undo] up wp;
      data_at Tsh tuint (Vint(Int.repr i)) tp;
      data_at Tsh (tarray tuchar n) (rbytes(restored xs entries i t)) fp;
      data_at sh (tarray tuint t) (rbytes entries) up))%assert.
 - Exists t;rewrite restored_same;entailer!.
 - Intros i.
   forward.
   forward_if.
   + forward.
     forward.
     forward.
     forward.
     forward.
     assert (Hidx:0<=Znth (i-1) entries<n).
     { apply Forall_Znth;auto;lia. }
     unfold rbytes.
     forward.
     assert (Hlen:Zlength(restored xs entries i t)=n) by (apply restored_length;assumption).
     forward.
     Exists (i-1). entailer!.
     rewrite (restored_step xs entries (i-1) (Zlength entries)) by lia.
     replace (i-1+1) with i by lia.
     unfold rbytes.
     change (Vint (Int.zero_ext 8 (Int.repr 0))) with (Vint (Int.repr 0)).
     rewrite (upd_Znth_map (fun z:Z=>Vint(Int.repr z)) (Znth (i-1) entries) (restored xs entries i (Zlength entries)) 0) by lia.
     apply derives_refl.
   + assert (i=mark) by lia;subst i.
     forward. entailer!.
Qed.
Print Assumptions body_restore.
