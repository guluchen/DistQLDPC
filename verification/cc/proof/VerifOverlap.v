Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCArray CCV.CCMatrix CCV.CCOverlapArray CCV.CCJournalArray CCV.CCJournalTrace CCV.VerifForbid CCV.VerifToggle CCV.CCLeaf.
Open Scope Z_scope.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
#[export] Instance ForbidSpecsPreserve: change_composite_env VerifForbid.CompSpecs CompSpecs.
 make_cs_preserve VerifForbid.CompSpecs CompSpecs.
Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition problem_type := Tstruct _ccv_problem noattr.
Definition workspace_type := Tstruct _ccv_workspace noattr.
Definition overlap_spec : ident * funspec :=
 DECLARE _overlap
 WITH pp:val,wp:val,tp:val,gp:val,sp:val,fp:val,up:val,sh:share,n:Z,k:Z,
      base:list Z,xs:list Z,gs:list Z,log:list Z,buf:list val,Bad:Prop,Allowed:(Z->Prop)
 PRE [tptr problem_type,tptr workspace_type,tptr tuint]
 PROP(readable_share sh;0<n<=Int.max_signed;0<=k;(k*n)%Z<=Int.max_signed;
      Zlength base=n;Zlength xs=n;Zlength gs=(k*n)%Z;
      Forall(fun z=>z=0 \/ z=1) base;Forall(fun z=>z=0 \/ z=1) xs;Forall(fun z=>z=0 \/ z=1) gs;
      journal_trace n base log buf;overlap_policy n k xs gs Bad Allowed)
 PARAMS(pp;wp;tp)
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*n)%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar n) (tbytes xs) sp;
  data_at Tsh (tarray tuchar n) (tbytes(journal_bitmap base log)) fp;
  data_at Tsh (tarray tuint n) buf up;
  data_at Tsh tuint (Vint(Int.repr(Zlength log))) tp)
 POST [tint] EX ret:Z, EX lognew:list Z, EX bufnew:list val,
 PROP(ret=0 \/ ret=1;ret=0 ->Bad;journal_trace n base lognew bufnew;allowed_extension log lognew Allowed)
 RETURN(Vint(Int.repr ret))
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*n)%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar n) (tbytes xs) sp;
  data_at Tsh (tarray tuchar n) (tbytes(journal_bitmap base lognew)) fp;
  data_at Tsh (tarray tuint n) bufnew up;
  data_at Tsh tuint (Vint(Int.repr(Zlength lognew))) tp).
Definition Gprog : funspecs := ltac:(with_library prog [forbid_spec;overlap_spec]).
Lemma body_overlap : semax_body Vprog Gprog f_overlap overlap_spec.
Proof.
 start_function. subst n.
 assert(K:0<=k<=Int.max_signed) by nia.
 assert(Policy:overlap_policy (Zlength base) k xs gs Bad Allowed) by assumption.
 forward.
 forward_loop
 (EX i:Z, EX logc:list Z, EX bufc:list val,
 (PROP(0<=i<=k;journal_trace (Zlength base) base logc bufc;allowed_extension log logc Allowed) LOCAL(temp _p pp;temp _w wp;temp _top tp;temp _i (Vint(Int.repr (i))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base logc)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufc up;
  data_at Tsh tuint (Vint(Int.repr(Zlength logc))) tp))%assert)%assert
 break:
 (EX lognew:list Z, EX bufnew:list val, (PROP(journal_trace (Zlength base) base lognew bufnew;allowed_extension log lognew Allowed) LOCAL(temp _p pp;temp _w wp;temp _top tp)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base lognew)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufnew up;
  data_at Tsh tuint (Vint(Int.repr(Zlength lognew))) tp))%assert)%assert.
 { Exists 0 log buf;entailer!;apply allowed_extension_refl. }
 { Intros i logc bufc. forward. forward_if.
 + assert(Jcur:journal_trace (Zlength base) base logc bufc) by assumption.
   assert(ExtCur:allowed_extension log logc Allowed) by assumption.
   forward. forward. forward.
   forward_loop
 (EX q:Z,
 (PROP(0<=q<=(Zlength base)) LOCAL(temp _p pp;temp _w wp;temp _top tp;temp _i (Vint(Int.repr (i)));temp _q (Vint(Int.repr (q)));temp _weight (Vint(Int.repr (stab_weight q (Zlength base) i gs)));temp _ov (Vint(Int.repr (stab_overlap q (Zlength base) i xs gs))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base logc)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufc up;
  data_at Tsh tuint (Vint(Int.repr(Zlength logc))) tp))%assert)%assert
 break:
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _top tp;temp _i (Vint(Int.repr (i)));temp _weight (Vint(Int.repr (stab_weight (Zlength base) (Zlength base) i gs)));temp _ov (Vint(Int.repr (stab_overlap (Zlength base) (Zlength base) i xs gs))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base logc)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufc up;
  data_at Tsh tuint (Vint(Int.repr(Zlength logc))) tp))%assert.
 { Exists 0;entailer!. }
 { Intros q. forward. forward_if.
 + assert(Index:0<=i*(Zlength base)+q<k*(Zlength base)) by (apply matrix_index;lia).
   assert(G:Znth(i*(Zlength base)+q) gs=0 \/ Znth(i*(Zlength base)+q) gs=1) by (apply Forall_Znth;auto;lia).
   assert(X:Znth q xs=0 \/ Znth q xs=1) by (apply Forall_Znth;auto;lia).
   forward. forward. unfold tbytes.
   forward. { entailer!;destruct G as [G|G];rewrite G;rep_lia. }
   forward.
   forward. forward. forward.
   forward. forward. { entailer!;destruct X as [X|X];rewrite X;rep_lia. }
   forward. forward. Exists(q+1);entailer!.
   rewrite (stab_weight_step q (Zlength base) k i gs) by (try assumption;lia).
   rewrite (stab_overlap_step q (Zlength base) k i xs gs) by (try assumption;lia).
   split;reflexivity.
 + assert(q=(Zlength base)) by lia;subst q;forward;entailer!. }
 Intros.
 pose proof(stab_counts_bounds (Zlength base) (Zlength base) i xs gs ltac:(lia)) as Counts.
 assert(Half:0<=stab_weight (Zlength base) (Zlength base) i gs/2<=stab_weight (Zlength base) (Zlength base) i gs).
 { split;[apply Z.div_pos;lia|apply Z.div_le_upper_bound;lia]. }
 assert(Div:Int.divu (Int.repr(stab_weight (Zlength base) (Zlength base) i gs)) (Int.repr 2)=Int.repr(stab_weight (Zlength base) (Zlength base) i gs/2)).
 { unfold Int.divu;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 forward. rewrite Div.
 forward_if.
 { change (Int.unsigned(Int.repr(stab_weight (Zlength base) (Zlength base) i gs/2)) < stab_overlap (Zlength base) (Zlength base) i xs gs) in H13.
   rewrite Int.unsigned_repr in H13 by rep_lia.
   assert(Strict:stab_overlap (Zlength base) (Zlength base) i xs gs>stab_weight (Zlength base) (Zlength base) i gs/2) by lia.
   assert(BadProof:Bad) by (apply (proj1 (Policy i ltac:(lia)));assumption).
   forward. Exists 0 logc bufc;entailer!;lia. }
 { forward_if
(EX lognew:list Z, EX bufnew:list val, (PROP(journal_trace (Zlength base) base lognew bufnew;allowed_extension log lognew Allowed) LOCAL(temp _p pp;temp _w wp;temp _top tp;temp _i (Vint(Int.repr (i))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base lognew)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufnew up;
  data_at Tsh tuint (Vint(Int.repr(Zlength lognew))) tp))%assert)%assert.
 { assert(Tight:stab_overlap (Zlength base) (Zlength base) i xs gs=stab_weight (Zlength base) (Zlength base) i gs/2).
   { eapply uint_repr_equal;try eassumption;rep_lia. }
   forward.
   forward_loop
 (EX q:Z, EX logq:list Z, EX bufq:list val,
 (PROP(0<=q<=(Zlength base);journal_trace (Zlength base) base logq bufq;allowed_extension log logq Allowed) LOCAL(temp _p pp;temp _w wp;temp _top tp;temp _i (Vint(Int.repr (i)));temp _q (Vint(Int.repr (q))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base logq)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufq up;
  data_at Tsh tuint (Vint(Int.repr(Zlength logq))) tp))%assert)%assert
 break:
 (EX lognew:list Z, EX bufnew:list val, (PROP(journal_trace (Zlength base) base lognew bufnew;allowed_extension log lognew Allowed) LOCAL(temp _p pp;temp _w wp;temp _top tp;temp _i (Vint(Int.repr (i))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base lognew)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufnew up;
  data_at Tsh tuint (Vint(Int.repr(Zlength lognew))) tp))%assert)%assert.
 { Exists 0 logc bufc;entailer!. }
 { Intros q logq bufq. forward. forward_if.
 + assert(Index:0<=i*(Zlength base)+q<k*(Zlength base)) by (apply matrix_index;lia).
   assert(G:Znth(i*(Zlength base)+q) gs=0 \/ Znth(i*(Zlength base)+q) gs=1) by (apply Forall_Znth;auto;lia).
   assert(X:Znth q xs=0 \/ Znth q xs=1) by (apply Forall_Znth;auto;lia).
   assert(Jq:journal_trace (Zlength base) base logq bufq) by assumption.
   assert(ExtQ:allowed_extension log logq Allowed) by assumption.
   forward. forward. unfold tbytes.
   forward. { entailer!;destruct G as [G|G];rewrite G;rep_lia. }
   forward_if
 (EX flag:bool,
 (PROP(flag=true ->Allowed q) LOCAL(temp _p pp;temp _w wp;temp _top tp;temp _i (Vint(Int.repr (i)));temp _q (Vint(Int.repr (q)));temp _t'2 (Vint(Int.repr (if flag then 1 else 0))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base logq)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufq up;
  data_at Tsh tuint (Vint(Int.repr(Zlength logq))) tp))%assert)%assert.
 { forward. forward. { entailer!;destruct X as [X|X];rewrite X;rep_lia. }
   assert(Safe:(Znth q xs=?0)=true ->Allowed q).
   { intros S;apply Z.eqb_eq in S;apply (proj2 (Policy i ltac:(lia)) q);try assumption;try lia. }
   forward. Exists (Znth q xs=?0);entailer!.
   destruct X as [X|X];rewrite X;reflexivity. }
 { forward. Exists false;entailer!;discriminate. }
 { Intros flag. forward_if
(EX lognew:list Z, EX bufnew:list val, (PROP(journal_trace (Zlength base) base lognew bufnew;allowed_extension log lognew Allowed) LOCAL(temp _p pp;temp _w wp;temp _top tp;temp _i (Vint(Int.repr (i)));temp _q (Vint(Int.repr (q))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr (Zlength base))) pp;
  field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
  field_at sh problem_type [StructField _stabilizer] gp pp;
  field_at sh workspace_type [StructField _selected] sp wp;
  field_at sh workspace_type [StructField _forbidden] fp wp;
  field_at sh workspace_type [StructField _undo] up wp;
  data_at sh (tarray tuchar ((k*(Zlength base))%Z)) (tbytes gs) gp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes xs) sp;
  data_at Tsh (tarray tuchar (Zlength base)) (tbytes(journal_bitmap base lognew)) fp;
  data_at Tsh (tarray tuint (Zlength base)) bufnew up;
  data_at Tsh tuint (Vint(Int.repr(Zlength lognew))) tp))%assert)%assert.
 { assert(Ft:flag=true) by (destruct flag;auto;contradiction).
   assert(Aq:Allowed q) by auto.
   assert(BitsF:Forall(fun z:Z=>z=0 \/ z=1) (journal_bitmap base logq)) by (apply journal_bitmap_bits;assumption).
   pose proof Jq as Jfields;unfold journal_trace in Jfields;destruct Jfields as [Top [Range [ND [Root [BL BP]]]]].
   pose proof(journal_bitmap_length (Zlength base) base logq ltac:(reflexivity) Range) as FL.
   destruct(forbid_trace_step (Zlength base) base logq bufq q ltac:(lia) ltac:(reflexivity) Jq ltac:(lia)) as [Result Next].
   assert(ExtNext:allowed_extension log (pushed_log (Zlength base) base logq q) Allowed) by (apply allowed_extension_forbid;assumption).
   forward.
   forward_call (wp,tp,fp,up,sh,(Zlength base),Zlength logq,q,journal_bitmap base logq,bufq).
   rewrite Result.
   forward_if.
   { exfalso;match goal with Hfalse:Int.repr 1=Int.zero |- _ =>apply (f_equal Int.unsigned) in Hfalse;change (1=0) in Hfalse;lia end. }
   { forward. Exists (pushed_log (Zlength base) base logq q) (pushed_buffer (Zlength base) base logq bufq q);entailer!.
     rewrite pushed_bitmap,pushed_top;unfold pushed_buffer,fbytes,tbytes;cancel. }
 }
 { forward. Exists logq bufq;entailer!. }
 { Intros lognext bufnext. forward. Exists(q+1) lognext bufnext;entailer!. }
 }
 + forward. Exists logq bufq;entailer!. }
 all: try (Intros logend bufend;forward;Exists logend bufend;entailer!).
 }
 { forward. Exists logc bufc;entailer!. }
 { Intros lognext bufnext. forward. Exists(i+1) lognext bufnext;entailer!. }
 }
 + forward. Exists logc bufc;entailer!. }
 Intros logend bufend. forward. Exists 1 logend bufend;entailer!;lia.
Qed.
Print Assumptions body_overlap.
