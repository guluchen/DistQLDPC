(* SPDX-License-Identifier: GPL-3.0-or-later. Candidate until coqc PASS. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition workspace_type := Tstruct _ccv_workspace noattr.
Definition fbytes (xs:list Z) := map (fun z=>Vint(Int.repr z)) xs.
Definition fresh_push xs q t n :=
 if Z.eq_dec (Znth q xs) 0 then if zlt t n then true else false else false.
Definition forbid_result xs q t n : Z :=
 if Z.eq_dec (Znth q xs) 0 then if zlt t n then 1 else 0 else 1.
Definition forbid_spec : ident * funspec :=
 DECLARE _forbid
 WITH wp:val,tp:val,fp:val,up:val,sh:share,n:Z,t:Z,q:Z,xs:list Z,entries:list val
 PRE [tptr workspace_type,tuint,tptr tuint,tuint]
 PROP(readable_share sh;0<n<=Int.max_signed;0<=t<=n;0<=q<n;
      Zlength xs=n;Zlength entries=n;Forall (fun z=>z=0 \/ z=1) xs)
 PARAMS(wp;Vint(Int.repr q);tp;Vint(Int.repr n))
 SEP(field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _undo] up wp;
     data_at Tsh tuint (Vint(Int.repr t)) tp;
     data_at Tsh (tarray tuchar n) (fbytes xs) fp;
     data_at Tsh (tarray tuint n) entries up)
 POST [tint] PROP() RETURN(Vint(Int.repr(forbid_result xs q t n)))
 SEP(field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _undo] up wp;
     data_at Tsh tuint (Vint(Int.repr(if fresh_push xs q t n then t+1 else t))) tp;
     data_at Tsh (tarray tuchar n) (fbytes(if fresh_push xs q t n then upd_Znth q xs 1 else xs)) fp;
     data_at Tsh (tarray tuint n) (if fresh_push xs q t n then upd_Znth t entries (Vint(Int.repr q)) else entries) up).
Definition Gprog : funspecs := ltac:(with_library prog [forbid_spec]).
Lemma body_forbid : semax_body Vprog Gprog f_forbid forbid_spec.
Proof.
 start_function.
 assert (Hbounds:Forall (fun z=>0<=z<=1) xs).
 { eapply Forall_impl;[|eassumption]. intros z Hz;destruct Hz;subst;lia. }
 assert (Hflag:0<=Znth q xs<=1) by (apply Forall_Znth;auto;lia).
 unfold fbytes.
 forward.
 forward.
 { entailer!;rep_lia. }
 forward_if
 (PROP(forbid_result xs q t n=1)
  LOCAL()
  SEP(field_at sh workspace_type [StructField _forbidden] fp wp;
      field_at sh workspace_type [StructField _undo] up wp;
      data_at Tsh tuint (Vint(Int.repr(if fresh_push xs q t n then t+1 else t))) tp;
      data_at Tsh (tarray tuchar n) (fbytes(if fresh_push xs q t n then upd_Znth q xs 1 else xs)) fp;
      data_at Tsh (tarray tuint n) (if fresh_push xs q t n then upd_Znth t entries (Vint(Int.repr q)) else entries) up))%assert.
 - forward.
   forward_if
   (PROP(t<n;Znth q xs=0)
    LOCAL(temp _w wp;temp _q (Vint(Int.repr q));temp _top tp;temp _n (Vint(Int.repr n)))
    SEP(field_at sh workspace_type [StructField _forbidden] fp wp;
        field_at sh workspace_type [StructField _undo] up wp;
        data_at Tsh tuint (Vint(Int.repr t)) tp;
        data_at Tsh (tarray tuchar n) (fbytes xs) fp;
        data_at Tsh (tarray tuint n) entries up))%assert.
   + forward.
     unfold fresh_push,forbid_result;repeat if_tac;entailer!;try lia.
   + forward. entailer!.
   + forward. forward. forward. forward. forward. forward. forward.
     unfold fresh_push,forbid_result;repeat if_tac;entailer!;try lia.
     change (Vint (Int.zero_ext 8 (Int.repr 1))) with (Vint (Int.repr 1)).
     unfold fbytes;rewrite (upd_Znth_map (fun z:Z=>Vint(Int.repr z)) q xs 1) by lia.
     apply derives_refl.
 - forward.
   unfold fresh_push,forbid_result;repeat if_tac;entailer!;try lia.
 - forward.
Qed.
Print Assumptions body_forbid.
