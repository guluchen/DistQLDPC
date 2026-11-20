Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCArray.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition problem_type := Tstruct _ccv_problem noattr.
Definition workspace_type := Tstruct _ccv_workspace noattr.
Definition clear_spec : ident * funspec :=
 DECLARE _clear
 WITH pp:val,wp:val,op:val,sp:val,fp:val,bp:val,yp:val,lp:val,
      sh:share,n:Z,m:Z,l:Z,xs:list val,fs:list val,bs:list val,os:list val,ys:list val,ls:list val
 PRE [tptr problem_type,tptr workspace_type,tptr tuchar]
 PROP(readable_share sh;0<=n<=Int.max_signed;0<=m<=Int.max_signed;0<=l<=Int.max_signed;
      Zlength xs=n;Zlength fs=n;Zlength bs=n;Zlength os=n;Zlength ys=m;Zlength ls=l)
 PARAMS(pp;wp;op)
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
     field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
     field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
     field_at sh workspace_type [StructField _selected] sp wp;
     field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _packed] bp wp;
     field_at sh workspace_type [StructField _syndrome] yp wp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at Tsh (tarray tuchar n) (xs) sp;
     data_at Tsh (tarray tuchar n) (fs) fp;
     data_at Tsh (tarray tuchar n) (bs) bp;
     data_at Tsh (tarray tuchar n) (os) op;
     data_at Tsh (tarray tuchar m) (ys) yp;
     data_at Tsh (tarray tuchar l) (ls) lp)
 POST [tvoid] PROP() RETURN()
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
     field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
     field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
     field_at sh workspace_type [StructField _selected] sp wp;
     field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _packed] bp wp;
     field_at sh workspace_type [StructField _syndrome] yp wp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) sp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) fp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) bp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) op;
     data_at Tsh (tarray tuchar m) (Zrepeat (Vint Int.zero) m) yp;
     data_at Tsh (tarray tuchar l) (Zrepeat (Vint Int.zero) l) lp).
Definition Gprog : funspecs := ltac:(with_library prog [clear_spec]).
Lemma body_clear : semax_body Vprog Gprog f_clear clear_spec.
Proof.
 start_function.
 forward.
 forward_loop
 (EX i:Z, PROP(0<=i<=n)
 LOCAL(temp _p pp;temp _w wp;temp _out op;temp _i (Vint(Int.repr i)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
     field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
     field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
     field_at sh workspace_type [StructField _selected] sp wp;
     field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _packed] bp wp;
     field_at sh workspace_type [StructField _syndrome] yp wp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at Tsh (tarray tuchar n) (zero_prefix xs i) sp;
     data_at Tsh (tarray tuchar n) (zero_prefix fs i) fp;
     data_at Tsh (tarray tuchar n) (zero_prefix bs i) bp;
     data_at Tsh (tarray tuchar n) (zero_prefix os i) op;
     data_at Tsh (tarray tuchar m) (ys) yp;
     data_at Tsh (tarray tuchar l) (ls) lp))%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _out op)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
     field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
     field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
     field_at sh workspace_type [StructField _selected] sp wp;
     field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _packed] bp wp;
     field_at sh workspace_type [StructField _syndrome] yp wp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) sp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) fp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) bp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) op;
     data_at Tsh (tarray tuchar m) (ys) yp;
     data_at Tsh (tarray tuchar l) (ls) lp))%assert.
 { Exists 0;entailer!;rewrite !zero_prefix_start;cancel. }
 { Intros i. forward. forward_if.
   + forward. forward. forward. forward. forward. forward. forward. forward.
     Exists(i+1);entailer!;
     repeat change (Vint(Int.zero_ext 8 (Int.repr 0))) with (Vint Int.zero);
     rewrite !zero_prefix_step by lia;cancel.
   + assert(i=n) by lia;subst i;forward;entailer!;
     rewrite !zero_prefix_full by lia;cancel. }
 forward.
 forward_loop
 (EX i:Z, PROP(0<=i<=m)
 LOCAL(temp _p pp;temp _w wp;temp _out op;temp _i (Vint(Int.repr i)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
     field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
     field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
     field_at sh workspace_type [StructField _selected] sp wp;
     field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _packed] bp wp;
     field_at sh workspace_type [StructField _syndrome] yp wp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) sp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) fp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) bp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) op;
     data_at Tsh (tarray tuchar m) (zero_prefix ys i) yp;
     data_at Tsh (tarray tuchar l) (ls) lp))%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _out op)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
     field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
     field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
     field_at sh workspace_type [StructField _selected] sp wp;
     field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _packed] bp wp;
     field_at sh workspace_type [StructField _syndrome] yp wp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) sp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) fp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) bp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) op;
     data_at Tsh (tarray tuchar m) (Zrepeat (Vint Int.zero) m) yp;
     data_at Tsh (tarray tuchar l) (ls) lp))%assert.
 { Exists 0;entailer!;rewrite !zero_prefix_start;cancel. }
 { Intros i. forward. forward_if.
   + forward. forward.
     forward. Exists(i+1);entailer!;
     repeat change (Vint(Int.zero_ext 8 (Int.repr 0))) with (Vint Int.zero);
     rewrite !zero_prefix_step by lia;cancel.
   + assert(i=m) by lia;subst i;forward;entailer!;
     rewrite !zero_prefix_full by lia;cancel. }
 forward.
 forward_loop
 (EX i:Z, PROP(0<=i<=l)
 LOCAL(temp _p pp;temp _w wp;temp _out op;temp _i (Vint(Int.repr i)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
     field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
     field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
     field_at sh workspace_type [StructField _selected] sp wp;
     field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _packed] bp wp;
     field_at sh workspace_type [StructField _syndrome] yp wp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) sp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) fp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) bp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) op;
     data_at Tsh (tarray tuchar m) (Zrepeat (Vint Int.zero) m) yp;
     data_at Tsh (tarray tuchar l) (zero_prefix ls i) lp))%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _out op)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
     field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
     field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
     field_at sh workspace_type [StructField _selected] sp wp;
     field_at sh workspace_type [StructField _forbidden] fp wp;
     field_at sh workspace_type [StructField _packed] bp wp;
     field_at sh workspace_type [StructField _syndrome] yp wp;
     field_at sh workspace_type [StructField _logical_value] lp wp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) sp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) fp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) bp;
     data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) op;
     data_at Tsh (tarray tuchar m) (Zrepeat (Vint Int.zero) m) yp;
     data_at Tsh (tarray tuchar l) (Zrepeat (Vint Int.zero) l) lp))%assert.
 { Exists 0;entailer!;rewrite !zero_prefix_start;cancel. }
 { Intros i. forward. forward_if.
   + forward. forward.
     forward. Exists(i+1);entailer!;
     repeat change (Vint(Int.zero_ext 8 (Int.repr 0))) with (Vint Int.zero);
     rewrite !zero_prefix_step by lia;cancel.
   + assert(i=l) by lia;subst i;forward;entailer!;
     rewrite !zero_prefix_full by lia;cancel. }
 - forward.
Qed.
Print Assumptions body_clear.
