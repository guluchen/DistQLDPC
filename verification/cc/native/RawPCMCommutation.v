(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMPrimitives.RawPCMComposites.
Local Open Scope Z_scope.

Fixpoint dot_prefix (a b:list bool) (width i j:Z) (k:nat):bool:=
 match k with
 | O=>false
 | S k'=>xorb (dot_prefix a b width i j k')
              (andb (Znth (i*width+Z.of_nat k') a) (Znth (j*width+Z.of_nat k') b))
 end.
Definition orthogonal_bytes a b ra rb width:=
 forall i j,0<=i<ra -> 0<=j<rb -> dot_prefix a b width i j (Z.to_nat width)=false.

(* Both PCM views are borrowed read-only; they may use distinct readable
   shares of the same underlying matrix. *)
Definition commute_spec:ident*funspec:=
 DECLARE _commute WITH ap:val,bp:val,ab:val,bb:val,sa:share,sb:share,ra:Z,rb:Z,n:Z,a:list bool,b:list bool
 PRE [tptr pcm_view_type,tptr pcm_view_type]
   PROP(readable_share sa;readable_share sb;0<=ra<=Int.max_signed;0<=rb<=Int.max_signed;0<=n<=Int.max_signed;
        Zlength a=(ra*n)%Z;Zlength b=(rb*n)%Z;orthogonal_bytes a b ra rb n)
   PARAMS(ap;bp) SEP(matrix_bytes sa ap ab ra n a;matrix_bytes sb bp bb rb n b)
 POST [tbool] PROP() RETURN(Vint Int.one) SEP(matrix_bytes sa ap ab ra n a;matrix_bytes sb bp bb rb n b).
Definition commute_calls:funspecs:=ltac:(with_library prog [entry_spec;commute_spec]).

Lemma next_dot a b n i j q:0<=q ->
 dot_prefix a b n i j (Z.to_nat (q+1)) =
 xorb (dot_prefix a b n i j (Z.to_nat q)) (andb (Znth (i*n+q) a) (Znth (j*n+q) b)).
Proof.
 intro h;replace (q+1) with (Z.succ q) by lia;rewrite Z2Nat.inj_succ by lia;cbn;rewrite Z2Nat.id by lia;reflexivity.
Qed.

Theorem accept_commuting_views:semax_body raw_vars commute_calls f_commute commute_spec.
Proof.
 start_function.
 pose (owned:=(matrix_bytes sa ap ab ra n a * matrix_bytes sb bp bb rb n b)%logic).
 forward.
 forward_loop (EX i:Z,PROP(0<=i<=ra)
   LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i))) SEP(owned))
   continue:(EX i:Z,PROP(0<=i<ra) LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i))) SEP(owned))%assert
   break:(PROP() LOCAL() SEP(owned))%assert.
 - Exists 0;unfold owned;entailer!.
 - Intros i;unfold owned,matrix_bytes,pcm_view_type;Intros;forward;forward_if.
   2:{ forward;unfold owned,matrix_bytes,pcm_view_type;entailer!. }
   assert (inside:0<=i<ra) by rep_lia.
   forward.
   forward_loop (EX j:Z,PROP(0<=j<=rb)
     LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i));temp _j (Vint (Int.repr j))) SEP(owned))
    continue:(EX j:Z,PROP(0<=j<rb)
      LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i));temp _j (Vint (Int.repr j))) SEP(owned))%assert
    break:(PROP() LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i))) SEP(owned))%assert.
   + Exists 0;unfold owned,matrix_bytes,pcm_view_type;entailer!.
   + Intros j;unfold owned,matrix_bytes,pcm_view_type;Intros;forward;forward_if.
     2:{ forward;unfold owned,matrix_bytes,pcm_view_type;entailer!. }
     assert (inside_j:0<=j<rb) by rep_lia.
     forward;forward.
     forward_loop (EX q:Z,PROP(0<=q<=n)
       LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i));temp _j (Vint (Int.repr j));
          temp _q (Vint (Int.repr q));temp _dot (cbit (dot_prefix a b n i j (Z.to_nat q)))) SEP(owned))
      continue:(EX q:Z,PROP(0<=q<n)
       LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i));temp _j (Vint (Int.repr j));
          temp _q (Vint (Int.repr q));temp _dot (cbit (dot_prefix a b n i j (Z.to_nat (q+1))))) SEP(owned))%assert
      break:(PROP() LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i));temp _j (Vint (Int.repr j));
                         temp _dot (Vint Int.zero)) SEP(owned))%assert.
     * Exists 0;unfold owned,matrix_bytes,pcm_view_type;entailer!.
     * Intros q;unfold owned,matrix_bytes,pcm_view_type;Intros;forward;forward_if.
       2:{ assert (q=n) by rep_lia;subst q;forward.
           match goal with H:orthogonal_bytes _ _ _ _ _ |- _=>rewrite (H i j inside inside_j) end.
           unfold owned,matrix_bytes,pcm_view_type;entailer!. }
       assert (col:0<=q<n) by rep_lia.
       fold pcm_view_type.
       forward_call (ap,ab,sa,ra,n,a,i,q);try solve [unfold matrix_bytes,pcm_view_type;entailer!;cancel;try apply derives_refl].
       forward_call (bp,bb,sb,rb,n,b,j,q);try solve [unfold matrix_bytes,pcm_view_type;entailer!;cancel;try apply derives_refl].
       forward;Exists q;rewrite next_dot by lia.
       unfold owned,matrix_bytes,pcm_view_type;entailer!;try cancel;try apply derives_refl;unfold cbit;
         destruct (dot_prefix a b n i j (Z.to_nat q)),(Znth (i*n+q) a),(Znth (j*n+q) b);
         try reflexivity;try apply derives_refl;try solve [entailer!;cancel;apply derives_refl].
     * Intros q;forward;Exists (q+1);entailer!.
     * forward_if;[contradiction|forward;Exists j;entailer!].
   + Intros j;forward;Exists (j+1);entailer!.
   + Exists i;entailer!.
 - Intros i;forward;Exists (i+1);entailer!.
 - forward;unfold owned;entailer!.
Qed.
