Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCMatrix CCV.CCRows CCV.VerifDot.
Open Scope Z_scope.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition problem_type := Tstruct _ccv_problem noattr.
Definition validation_dot t n m i j hs ls gs := if zlt j m then flat_dot t n j i hs gs else flat_dot t n (j-m) i ls gs.
Definition valid_stabilizers n m l k hs ls gs := forall i j:Z,0<=i<k -> 0<=j<m+l -> validation_dot n n m i j hs ls gs=Int.zero.
Definition validate_spec : ident * funspec :=
 DECLARE _validate
 WITH pp:val,hp:val,lp:val,gp:val,sh:share,n:Z,m:Z,l:Z,k:Z,hs:list Z,ls:list Z,gs:list Z
 PRE [tptr problem_type]
 PROP(readable_share sh;0<n<=Int.max_signed;0<=m;0<=l;0<=k;
      (m*n)%Z<=Int.max_signed;(l*n)%Z<=Int.max_signed;(k*n)%Z<=Int.max_signed;
      Zlength hs=(m*n)%Z;Zlength ls=(l*n)%Z;Zlength gs=(k*n)%Z;
      Forall(fun z=>z=0 \/ z=1) hs;Forall(fun z=>z=0 \/ z=1) ls;Forall(fun z=>z=0 \/ z=1) gs;
      valid_stabilizers n m l k hs ls gs)
 PARAMS(pp)
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp)
 POST [tint] PROP() RETURN(Vint(Int.repr 1))
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp).
Definition Gprog : funspecs := ltac:(with_library prog [validate_spec]).
Lemma body_validate_legal : semax_body Vprog Gprog f_validate validate_spec.
Proof.
 start_function.
 assert(M:0<=m<=Int.max_signed) by nia.
 assert(L:0<=l<=Int.max_signed) by nia.
 assert(K:0<=k<=Int.max_signed) by nia.
 assert(Sum:0<=m+l<=Int.max_unsigned) by (change Int.max_unsigned with 4294967295;change Int.max_signed with 2147483647 in *;nia).
 unfold valid_stabilizers in *.
 forward.
forward_loop
 (EX i:Z, (PROP(0<=i<=(m*n)%Z) LOCAL(temp _p pp;temp _i (Vint(Int.repr (i))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert.
{ Exists 0;entailer!. }
{ Intros i. forward. forward. forward_if.
+ assert(B:Znth i hs=0 \/ Znth i hs=1) by (apply Forall_Znth;auto;lia).
 forward. unfold dbytes.
 forward. { entailer!;destruct B as [B|B];rewrite B;rep_lia. }
 forward_if.
 * exfalso;destruct B;lia.
 * forward. Exists(i+1);entailer!.

+ forward;entailer!. }
 forward.
forward_loop
 (EX i:Z, (PROP(0<=i<=(l*n)%Z) LOCAL(temp _p pp;temp _i (Vint(Int.repr (i))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert.
{ Exists 0;entailer!. }
{ Intros i. forward. forward. forward_if.
+ assert(B:Znth i ls=0 \/ Znth i ls=1) by (apply Forall_Znth;auto;lia).
 forward. unfold dbytes.
 forward. { entailer!;destruct B as [B|B];rewrite B;rep_lia. }
 forward_if.
 * exfalso;destruct B;lia.
 * forward. Exists(i+1);entailer!.

+ forward;entailer!. }
 forward.
forward_loop
 (EX i:Z, (PROP(0<=i<=(k*n)%Z) LOCAL(temp _p pp;temp _i (Vint(Int.repr (i))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert.
{ Exists 0;entailer!. }
{ Intros i. forward. forward. forward_if.
+ assert(B:Znth i gs=0 \/ Znth i gs=1) by (apply Forall_Znth;auto;lia).
 forward. unfold dbytes.
 forward. { entailer!;destruct B as [B|B];rewrite B;rep_lia. }
 forward_if.
 * exfalso;destruct B;lia.
 * forward. Exists(i+1);entailer!.

+ forward;entailer!. }
 forward.
forward_loop
 (EX i:Z, (PROP(0<=i<=k) LOCAL(temp _p pp;temp _i (Vint(Int.repr (i))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert.
{ Exists 0;entailer!. }
{ Intros i. forward. forward_if.
+ forward.
forward_loop
 (EX j:Z, (PROP(0<=j<=m+l) LOCAL(temp _p pp;temp _i (Vint(Int.repr (i)));temp _j (Vint(Int.repr (j))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _i (Vint(Int.repr (i))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert.
{ Exists 0;entailer!. }
{ Intros j. forward. forward. forward_if.
+ forward. forward.
forward_loop
 (EX q:Z, (PROP(0<=q<=n) LOCAL(temp _p pp;temp _i (Vint(Int.repr (i)));temp _j (Vint(Int.repr (j)));temp _q (Vint(Int.repr (q)));temp _v (Vint(validation_dot q n m i j hs ls gs)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _i (Vint(Int.repr (i)));temp _j (Vint(Int.repr (j)));temp _v (Vint(validation_dot n n m i j hs ls gs)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert.
 { Exists 0;entailer!;unfold validation_dot;destruct(zlt j m);reflexivity. }
 { Intros q. forward. forward_if.
 +  forward.
 forward_if
 (PROP() LOCAL(temp _p pp;temp _i (Vint(Int.repr (i)));temp _j (Vint(Int.repr (j)));temp _q (Vint(Int.repr (q)));temp _v (Vint(validation_dot (q+1) n m i j hs ls gs)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh problem_type [StructField _h] hp pp;
    field_at sh problem_type [StructField _logical] lp pp;
    field_at sh problem_type [StructField _stabilizer] gp pp;
    data_at sh (tarray tuchar ((m*n)%Z)) (dbytes hs) hp;
    data_at sh (tarray tuchar ((l*n)%Z)) (dbytes ls) lp;
    data_at sh (tarray tuchar ((k*n)%Z)) (dbytes gs) gp))%assert.
{ assert(I1:0<=(j)*n+q<m*n) by (apply matrix_index;lia).
 assert(I2:0<=i*n+q<k*n) by (apply matrix_index;lia).
 assert(B1:Znth ((j)*n+q) hs=0 \/ Znth ((j)*n+q) hs=1) by (apply Forall_Znth;auto;lia).
 assert(B2:Znth (i*n+q) gs=0 \/ Znth (i*n+q) gs=1) by (apply Forall_Znth;auto;lia).
 unfold dbytes.
 forward. forward. 
 forward. { entailer!;destruct B1 as [B|B];rewrite B;rep_lia. }
 forward. forward.
 forward. { entailer!;destruct B2 as [B|B];rewrite B;rep_lia. }
 forward;entailer!.
 unfold validation_dot;rewrite !if_true by lia.
 rewrite flat_dot_step by lia;unfold Int.and;rewrite !Int.unsigned_repr by rep_lia;reflexivity.
 }
{ assert(I1:0<=(j-m)*n+q<l*n) by (apply matrix_index;lia).
 assert(I2:0<=i*n+q<k*n) by (apply matrix_index;lia).
 assert(B1:Znth ((j-m)*n+q) ls=0 \/ Znth ((j-m)*n+q) ls=1) by (apply Forall_Znth;auto;lia).
 assert(B2:Znth (i*n+q) gs=0 \/ Znth (i*n+q) gs=1) by (apply Forall_Znth;auto;lia).
 unfold dbytes.
 forward. forward. forward. 
 forward. { entailer!;destruct B1 as [B|B];rewrite B;rep_lia. }
 forward. forward.
 forward. { entailer!;destruct B2 as [B|B];rewrite B;rep_lia. }
 forward;entailer!.
 unfold validation_dot;rewrite !if_false by lia.
 rewrite flat_dot_step by lia;unfold Int.and;rewrite !Int.unsigned_repr by rep_lia;reflexivity.
 }
{ forward. Exists(q+1);entailer!. }
 + assert(q=n) by lia;subst q;forward;entailer!. }
 Intros.
 assert(D:validation_dot n n m i j hs ls gs=Int.zero).
 { match goal with Hd:forall i j:Z, _ -> _ -> _ |- _ =>apply Hd;lia end. }
 rewrite D.
 forward_if.
 { exfalso;congruence. }
 { forward. Exists(j+1);entailer!. }

+ forward;entailer!. }
forward. Exists(i+1);entailer!.
+ forward;entailer!. }
forward;entailer!.
Qed.
Print Assumptions body_validate_legal.
