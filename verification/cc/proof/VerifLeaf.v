Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCArray CCV.CCMatrix CCV.CCLeaf CCV.VerifToggle CCV.VerifCoreToggle.
Open Scope Z_scope.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
#[export] Instance CoreSpecsPreserve: change_composite_env VerifCoreToggle.CompSpecs CompSpecs.
 make_cs_preserve VerifCoreToggle.CompSpecs CompSpecs.
Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition problem_type := Tstruct _ccv_problem noattr.
Definition workspace_type := Tstruct _ccv_workspace noattr.
Definition leaf_spec : ident * funspec :=
 DECLARE _leaf
 WITH pp:val,wp:val,hp:val,lp:val,sp:val,fp:val,yp:val,zp:val,sh:share,
 n:Z,m:Z,l:Z,xs:list Z,fs:list Z,ys:list Z,zs:list Z,hs:list Z,ls:list Z
 PRE [tptr problem_type,tptr workspace_type]
 PROP(readable_share sh;0<n<=Int.max_signed;0<=m;0<=l;
      (m*n)%Z<=Int.max_signed;(l*n)%Z<=Int.max_signed;
      Zlength xs=n;Zlength fs=n;Zlength ys=m;Zlength zs=l;Zlength hs=(m*n)%Z;Zlength ls=(l*n)%Z;
      Forall(fun z=>z=0 \/ z=1) xs;Forall(fun z=>z=0 \/ z=1) fs;
      Forall(fun z=>z=0 \/ z=1) ys;Forall(fun z=>z=0 \/ z=1) zs;
      Forall(fun z=>z=0 \/ z=1) hs;Forall(fun z=>z=0 \/ z=1) ls)
 PARAMS(pp;wp)
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar ((m*n)%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar ((l*n)%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar n) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar n) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar m) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar l) (tbytes (zs)) zp)
 POST [tint] EX hit:bool, EX chosen:Z,
 PROP(if hit then 0<=chosen<n /\ leaf_candidate n m l xs fs ys zs hs ls chosen=true
      else forall r:Z,0<=r<n -> leaf_candidate n m l xs fs ys zs hs ls r=false)
 RETURN(Vint(Int.repr(if hit then 1 else 0)))
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar ((m*n)%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar ((l*n)%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar n) (tbytes (if hit then (upd_Znth chosen xs (Z.lxor (Znth chosen xs) 1)) else xs)) sp;
   data_at Tsh (tarray tuchar n) (tbytes (if hit then (fs) else fs)) fp;
   data_at Tsh (tarray tuchar m) (tbytes (if hit then (xor_vector ys (column n m chosen hs)) else ys)) yp;
   data_at Tsh (tarray tuchar l) (tbytes (if hit then (xor_vector zs (column n l chosen ls)) else zs)) zp).
Definition Gprog : funspecs := ltac:(with_library prog [core_toggle_spec;leaf_spec]).
Lemma body_leaf : semax_body Vprog Gprog f_leaf leaf_spec.
Proof.
 start_function. subst n m l.
 assert(M:0<=(Zlength ys)<=Int.max_signed) by nia.
 assert(L:0<=(Zlength zs)<=Int.max_signed) by nia.
 forward.
 forward_loop
 (EX q:Z, (PROP(0<=q<=(Zlength xs);forall r:Z,0<=r<q -> leaf_candidate (Zlength xs) (Zlength ys) (Zlength zs) xs fs ys zs hs ls r=false) LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert)%assert
 break:
 (PROP(forall r:Z,0<=r<(Zlength xs) -> leaf_candidate (Zlength xs) (Zlength ys) (Zlength zs) xs fs ys zs hs ls r=false) LOCAL(temp _p pp;temp _w wp)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert.
 { Exists 0;entailer!;intros r Hr;lia. }
 { Intros q. forward. forward_if.
 + assert(X:Znth q xs=0 \/ Znth q xs=1) by (apply Forall_Znth;auto;lia).
   assert(F:Znth q fs=0 \/ Znth q fs=1) by (apply Forall_Znth;auto;lia).
   forward. unfold tbytes. forward. { entailer!;destruct X as [X|X];rewrite X;rep_lia. }
   forward_if
(PROP() LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q)));temp _t'1 (Vint(Int.repr (if free_column xs fs q then 1 else 0))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert.
 { forward. forward. { entailer!;destruct F as [F|F];rewrite F;rep_lia. }
   forward;entailer!;unfold free_column;destruct X as [X|X];destruct F as [F|F];rewrite X,F in *;try lia;reflexivity. }
 { forward;entailer!;unfold free_column;destruct X as [X|X];destruct F as [F|F];rewrite X,F in *;try lia;reflexivity. }
 { forward_if
(PROP(forall r:Z,0<=r<q+1 -> leaf_candidate (Zlength xs) (Zlength ys) (Zlength zs) xs fs ys zs hs ls r=false) LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert.
 { assert(Free:free_column xs fs q=true) by (destruct(free_column xs fs q);auto;contradiction).
   forward. forward.
   forward_loop
 (EX i:Z, (PROP(0<=i<=(Zlength ys)) LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q)));temp _i (Vint(Int.repr (i)));temp _ok (Vint(Int.repr (if row_matches i (Zlength xs) q ys hs then 1 else 0))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q)));temp _ok (Vint(Int.repr (if row_matches (Zlength ys) (Zlength xs) q ys hs then 1 else 0))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert.
 { Exists 0;entailer!. }
 { Intros i. forward. forward_if.
 + assert(I:0<=i*(Zlength xs)+q<(Zlength ys)*(Zlength xs)) by (apply matrix_index;lia).
   assert(B1:Znth i ys=0 \/ Znth i ys=1) by (apply Forall_Znth;auto;lia).
   assert(B2:Znth(i*(Zlength xs)+q) hs=0 \/ Znth(i*(Zlength xs)+q) hs=1) by (apply Forall_Znth;auto;lia).
   forward. unfold tbytes. forward. { entailer!;destruct B1 as [B|B];rewrite B;rep_lia. }
   forward. forward. forward. { entailer!;destruct B2 as [B|B];rewrite B;rep_lia. }
   forward_if
(PROP() LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q)));temp _i (Vint(Int.repr (i)));temp _ok (Vint(Int.repr (if row_matches (i+1) (Zlength xs) q ys hs then 1 else 0))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert.
 { forward;entailer!;rewrite row_matches_step by lia.
   assert(E:(Znth i ys=?Znth(i*(Zlength xs)+q) hs)=false) by (apply Z.eqb_neq;auto).
   rewrite E,andb_false_r;reflexivity. }
 { forward;entailer!;rewrite row_matches_step by lia.
   assert(E:(Znth i ys=?Znth(i*(Zlength xs)+q) hs)=true) by (apply Z.eqb_eq;auto).
   rewrite E,andb_true_r;reflexivity. }
 { forward. Exists(i+1);entailer!. }
 + assert(i=(Zlength ys)) by lia;subst i;forward;entailer!. }
 Intros.
 forward_if
(PROP(forall r:Z,0<=r<q+1 -> leaf_candidate (Zlength xs) (Zlength ys) (Zlength zs) xs fs ys zs hs ls r=false) LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert.
 { assert(Match:row_matches (Zlength ys) (Zlength xs) q ys hs=true) by (destruct(row_matches (Zlength ys) (Zlength xs) q ys hs);auto;contradiction).
   forward. forward.
   forward_loop
 (EX i:Z, (PROP(0<=i<=(Zlength zs)) LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q)));temp _i (Vint(Int.repr (i)));temp _logical (Vint(Int.repr (if row_differs i (Zlength xs) q zs ls then 1 else 0))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr (q)));temp _logical (Vint(Int.repr (if row_differs (Zlength zs) (Zlength xs) q zs ls then 1 else 0))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
   field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
   field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
   field_at sh problem_type [StructField _h] hp pp;
   field_at sh problem_type [StructField _logical] lp pp;
   field_at sh workspace_type [StructField _selected] sp wp;
   field_at sh workspace_type [StructField _forbidden] fp wp;
   field_at sh workspace_type [StructField _syndrome] yp wp;
   field_at sh workspace_type [StructField _logical_value] zp wp;
   data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
   data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xs)) sp;
   data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (fs)) fp;
   data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (ys)) yp;
   data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (zs)) zp))%assert.
 { Exists 0;entailer!. }
 { Intros i. forward. forward_if.
 + assert(I:0<=i*(Zlength xs)+q<(Zlength zs)*(Zlength xs)) by (apply matrix_index;lia).
   assert(B1:Znth i zs=0 \/ Znth i zs=1) by (apply Forall_Znth;auto;lia).
   assert(B2:Znth(i*(Zlength xs)+q) ls=0 \/ Znth(i*(Zlength xs)+q) ls=1) by (apply Forall_Znth;auto;lia).
   forward. unfold tbytes. forward. { entailer!;destruct B1 as [B|B];rewrite B;rep_lia. }
   forward. forward. forward. { entailer!;destruct B2 as [B|B];rewrite B;rep_lia. }
   forward. forward. Exists(i+1);entailer!;rewrite row_differs_step by lia.
   destruct(row_differs i (Zlength xs) q zs ls);destruct B1 as [B1|B1];destruct B2 as [B2|B2];rewrite B1,B2;reflexivity.
 + assert(i=(Zlength zs)) by lia;subst i;forward;entailer!. }
 Intros.
 forward_if.
 { assert(Diff:row_differs (Zlength zs) (Zlength xs) q zs ls=true) by (destruct(row_differs (Zlength zs) (Zlength xs) q zs ls);auto;contradiction).
   assert(C:leaf_candidate (Zlength xs) (Zlength ys) (Zlength zs) xs fs ys zs hs ls q=true) by (unfold leaf_candidate;rewrite Free,Match,Diff;reflexivity).
   forward_call (pp,wp,hp,lp,sp,yp,zp,sh,(Zlength xs),(Zlength ys),(Zlength zs),q,xs,ys,zs,hs,ls).
   forward. Exists true q;entailer!. }
 { assert(Diff:row_differs (Zlength zs) (Zlength xs) q zs ls=false) by (apply bool_repr_zero;assumption).
   assert(Fail:leaf_candidate (Zlength xs) (Zlength ys) (Zlength zs) xs fs ys zs hs ls q=false) by (unfold leaf_candidate;rewrite Free,Match,Diff;reflexivity).
   forward;entailer!;eapply checked_prefix_extend;eauto. }
 }
 { assert(Match:row_matches (Zlength ys) (Zlength xs) q ys hs=false) by (apply bool_repr_zero;assumption).
   assert(Fail:leaf_candidate (Zlength xs) (Zlength ys) (Zlength zs) xs fs ys zs hs ls q=false) by (unfold leaf_candidate;rewrite Free,Match;reflexivity).
   forward;entailer!;eapply checked_prefix_extend;eauto. }
 }
 { assert(Free:free_column xs fs q=false) by (apply bool_repr_zero;assumption).
   assert(Fail:leaf_candidate (Zlength xs) (Zlength ys) (Zlength zs) xs fs ys zs hs ls q=false) by (unfold leaf_candidate;rewrite Free;reflexivity).
   forward;entailer!;eapply checked_prefix_extend;eauto. }
 { forward. Exists(q+1);entailer!. }
 }
 + assert(q=(Zlength xs)) by lia;subst q;forward;entailer!. }
 Intros. forward. Exists false 0;entailer!.
Qed.
Print Assumptions body_leaf.
