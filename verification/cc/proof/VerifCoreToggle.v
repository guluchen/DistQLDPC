Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCArray CCV.CCMatrix CCV.VerifToggle.
Open Scope Z_scope.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition problem_type := Tstruct _ccv_problem noattr.
Definition workspace_type := Tstruct _ccv_workspace noattr.
Definition core_toggle_spec : ident * funspec :=
 DECLARE _toggle
 WITH pp:val,wp:val,hp:val,lp:val,sp:val,yp:val,zp:val,sh:share,
 n:Z,m:Z,l:Z,q:Z,xs:list Z,ys:list Z,zs:list Z,hs:list Z,ls:list Z
 PRE [tptr problem_type,tptr workspace_type,tuint]
 PROP(readable_share sh;0<n<=Int.max_signed;0<=m;0<=l;0<=q<n;
      (m*n)%Z<=Int.max_signed;(l*n)%Z<=Int.max_signed;
      Zlength xs=n;Zlength ys=m;Zlength zs=l;Zlength hs=(m*n)%Z;Zlength ls=(l*n)%Z;
      Forall(fun z=>z=0 \/ z=1) xs;Forall(fun z=>z=0 \/ z=1) ys;
      Forall(fun z=>z=0 \/ z=1) zs;Forall(fun z=>z=0 \/ z=1) hs;Forall(fun z=>z=0 \/ z=1) ls)
 PARAMS(pp;wp;Vint(Int.repr q))
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh workspace_type [StructField _selected] sp wp;
    field_at sh workspace_type [StructField _syndrome] yp wp;
    field_at sh workspace_type [StructField _logical_value] zp wp;
    data_at sh (tarray tuchar ((m*n)%Z)) (tbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (tbytes ls) lp;
    data_at Tsh (tarray tuchar n) (tbytes (xs)) sp;
    data_at Tsh (tarray tuchar m) (tbytes ys) yp;
    data_at Tsh (tarray tuchar l) (tbytes zs) zp)
 POST [tvoid] PROP() RETURN()
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh workspace_type [StructField _selected] sp wp;
    field_at sh workspace_type [StructField _syndrome] yp wp;
    field_at sh workspace_type [StructField _logical_value] zp wp;
    data_at sh (tarray tuchar ((m*n)%Z)) (tbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (tbytes ls) lp;
    data_at Tsh (tarray tuchar n) (tbytes (upd_Znth q xs (Z.lxor (Znth q xs) 1))) sp;
    data_at Tsh (tarray tuchar m) (tbytes (xor_vector ys (column n m q hs))) yp;
    data_at Tsh (tarray tuchar l) (tbytes (xor_vector zs (column n l q ls))) zp).
Definition Gprog : funspecs := ltac:(with_library prog [core_toggle_spec]).
Lemma body_core_toggle : semax_body Vprog Gprog f_toggle core_toggle_spec.
Proof.
 start_function. subst n m l.
 assert (M:0<=(Zlength ys)<=Int.max_signed) by nia.
 assert (L:0<=(Zlength zs)<=Int.max_signed) by nia.
 assert (Xq:Znth q xs=0 \/ Znth q xs=1) by (apply Forall_Znth;auto;lia).
 forward. forward. unfold tbytes.
 forward. { entailer!;destruct Xq as [Xq|Xq];rewrite Xq;rep_lia. }
 forward.
 assert (Store:Vint(Int.zero_ext 8 (Int.xor(Int.repr(Znth q xs))(Int.repr 1)))=
      Vint(Int.repr(Z.lxor (Znth q xs) 1))) by (apply xor_byte;auto).
 simpl;rewrite Store.
 rewrite (upd_Znth_map (fun z=>Vint(Int.repr z)) q xs (Z.lxor (Znth q xs) 1)) by lia.
 fold tbytes.
 forward.
 forward_loop
 (EX i:Z, PROP(0<=i<=(Zlength ys))
 LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr q));temp _i (Vint(Int.repr i)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh workspace_type [StructField _selected] sp wp;
    field_at sh workspace_type [StructField _syndrome] yp wp;
    field_at sh workspace_type [StructField _logical_value] zp wp;
    data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
    data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
    data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (upd_Znth q xs (Z.lxor (Znth q xs) 1))) sp;
    data_at Tsh (tarray tuchar (Zlength ys)) (copy_prefix (tbytes ys) (tbytes (xor_vector ys (column (Zlength xs) (Zlength ys) q hs))) i) yp;
    data_at Tsh (tarray tuchar (Zlength zs)) (tbytes zs) zp))%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr q)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh workspace_type [StructField _selected] sp wp;
    field_at sh workspace_type [StructField _syndrome] yp wp;
    field_at sh workspace_type [StructField _logical_value] zp wp;
    data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
    data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
    data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (upd_Znth q xs (Z.lxor (Znth q xs) 1))) sp;
    data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (xor_vector ys (column (Zlength xs) (Zlength ys) q hs))) yp;
    data_at Tsh (tarray tuchar (Zlength zs)) (tbytes zs) zp))%assert.
 { Exists 0;entailer!;rewrite copy_prefix_start;cancel. }
 { Intros i. forward. forward_if.
 + assert (Index:0<=i*(Zlength xs)+q<((Zlength ys)*(Zlength xs))%Z) by (apply matrix_index;lia).
   assert (OldBit:Znth i ys=0 \/ Znth i ys=1) by (apply Forall_Znth;auto;lia).
   assert (MatBit:Znth (i*(Zlength xs)+q) hs=0 \/ Znth (i*(Zlength xs)+q) hs=1) by (apply Forall_Znth;auto;lia).
   assert (Len:Zlength(tbytes ys)=Zlength(tbytes(xor_vector ys (column (Zlength xs) (Zlength ys) q hs)))).
   { unfold tbytes;rewrite !Zlength_map,xor_vector_length;[reflexivity|rewrite column_length by lia;lia]. }
   forward. forward.
   forward.
   { rewrite copy_prefix_old by (try exact Len;unfold tbytes;rewrite Zlength_map;lia).
     unfold tbytes;rewrite Znth_map by lia;entailer!;destruct OldBit as [B|B];rewrite B;rep_lia. }
   forward. forward. unfold tbytes.
   forward. { entailer!;destruct MatBit as [B|B];rewrite B;rep_lia. }
   forward. forward. Exists(i+1);entailer!.
   rewrite copy_prefix_old by (try exact Len;unfold tbytes;rewrite Zlength_map;lia).
   unfold tbytes;rewrite !Znth_map by lia;simpl.
   assert (S:Vint(Int.zero_ext 8 (Int.xor(Int.repr(Znth i ys))(Int.repr(Znth (i*(Zlength xs)+q) hs))))=
      Znth i (tbytes(xor_vector ys (column (Zlength xs) (Zlength ys) q hs)))).
   { unfold tbytes;rewrite Znth_map by (rewrite xor_vector_length;[lia|rewrite column_length by lia;lia]).
     rewrite xor_vector_at by (try lia;rewrite column_length by lia;lia).
     rewrite column_at by lia;apply xor_byte;assumption. }
   fold (tbytes ys) (tbytes (xor_vector ys (column (Zlength xs) (Zlength ys) q hs)));rewrite S,copy_prefix_step by (try exact Len;unfold tbytes;rewrite Zlength_map;lia);cancel.
 + assert(i=(Zlength ys)) by lia;subst i;forward;entailer!;
   rewrite copy_prefix_full by (unfold tbytes;rewrite !Zlength_map;first [reflexivity|rewrite xor_vector_length;[reflexivity|rewrite column_length by lia;lia]]);cancel. }
 forward.
 forward_loop
 (EX i:Z, PROP(0<=i<=(Zlength zs))
 LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr q));temp _i (Vint(Int.repr i)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh workspace_type [StructField _selected] sp wp;
    field_at sh workspace_type [StructField _syndrome] yp wp;
    field_at sh workspace_type [StructField _logical_value] zp wp;
    data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
    data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
    data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (upd_Znth q xs (Z.lxor (Znth q xs) 1))) sp;
    data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (xor_vector ys (column (Zlength xs) (Zlength ys) q hs))) yp;
    data_at Tsh (tarray tuchar (Zlength zs)) (copy_prefix (tbytes zs) (tbytes (xor_vector zs (column (Zlength xs) (Zlength zs) q ls))) i) zp))%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _q (Vint(Int.repr q)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength xs))) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr (Zlength ys))) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr (Zlength zs))) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh workspace_type [StructField _selected] sp wp;
    field_at sh workspace_type [StructField _syndrome] yp wp;
    field_at sh workspace_type [StructField _logical_value] zp wp;
    data_at sh (tarray tuchar (((Zlength ys)*(Zlength xs))%Z)) (tbytes hs) hp;
    data_at sh (tarray tuchar (((Zlength zs)*(Zlength xs))%Z)) (tbytes ls) lp;
    data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (upd_Znth q xs (Z.lxor (Znth q xs) 1))) sp;
    data_at Tsh (tarray tuchar (Zlength ys)) (tbytes (xor_vector ys (column (Zlength xs) (Zlength ys) q hs))) yp;
    data_at Tsh (tarray tuchar (Zlength zs)) (tbytes (xor_vector zs (column (Zlength xs) (Zlength zs) q ls))) zp))%assert.
 { Exists 0;entailer!;rewrite copy_prefix_start;cancel. }
 { Intros i. forward. forward_if.
 + assert (Index:0<=i*(Zlength xs)+q<((Zlength zs)*(Zlength xs))%Z) by (apply matrix_index;lia).
   assert (OldBit:Znth i zs=0 \/ Znth i zs=1) by (apply Forall_Znth;auto;lia).
   assert (MatBit:Znth (i*(Zlength xs)+q) ls=0 \/ Znth (i*(Zlength xs)+q) ls=1) by (apply Forall_Znth;auto;lia).
   assert (Len:Zlength(tbytes zs)=Zlength(tbytes(xor_vector zs (column (Zlength xs) (Zlength zs) q ls)))).
   { unfold tbytes;rewrite !Zlength_map,xor_vector_length;[reflexivity|rewrite column_length by lia;lia]. }
   forward. forward.
   forward.
   { rewrite copy_prefix_old by (try exact Len;unfold tbytes;rewrite Zlength_map;lia).
     unfold tbytes;rewrite Znth_map by lia;entailer!;destruct OldBit as [B|B];rewrite B;rep_lia. }
   forward. forward. unfold tbytes.
   forward. { entailer!;destruct MatBit as [B|B];rewrite B;rep_lia. }
   forward. forward. Exists(i+1);entailer!.
   rewrite copy_prefix_old by (try exact Len;unfold tbytes;rewrite Zlength_map;lia).
   unfold tbytes;rewrite !Znth_map by lia;simpl.
   assert (S:Vint(Int.zero_ext 8 (Int.xor(Int.repr(Znth i zs))(Int.repr(Znth (i*(Zlength xs)+q) ls))))=
      Znth i (tbytes(xor_vector zs (column (Zlength xs) (Zlength zs) q ls)))).
   { unfold tbytes;rewrite Znth_map by (rewrite xor_vector_length;[lia|rewrite column_length by lia;lia]).
     rewrite xor_vector_at by (try lia;rewrite column_length by lia;lia).
     rewrite column_at by lia;apply xor_byte;assumption. }
   fold (tbytes zs) (tbytes (xor_vector zs (column (Zlength xs) (Zlength zs) q ls)));rewrite S,copy_prefix_step by (try exact Len;unfold tbytes;rewrite Zlength_map;lia);cancel.
 + assert(i=(Zlength zs)) by lia;subst i;forward;entailer!;
   rewrite copy_prefix_full by (unfold tbytes;rewrite !Zlength_map;first [reflexivity|rewrite xor_vector_length;[reflexivity|rewrite column_length by lia;lia]]);cancel. }
 forward.
Qed.
Print Assumptions body_core_toggle.
