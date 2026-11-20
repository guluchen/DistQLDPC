(* Candidate VST proof of the actual Clight bounds body. Only full coqc is PASS. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCWord.
Require Import CCV.ccv_core CCV.CCArray CCV.CCMatrix CCV.CCRepresentation CCV.CCBoundsArray CCV.CCBoundsPolicy CCV.CCPackedArray CCV.CCBoundsLoop CCV.CCModel CCV.CCFunctional CCV.VerifToggle CCV.VerifPrimitives.
Open Scope Z_scope.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
#[export] Instance PrimitiveSpecsPreserve: change_composite_env VerifPrimitives.CompSpecs CompSpecs.
 make_cs_preserve VerifPrimitives.CompSpecs CompSpecs.
Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition problem_type := Tstruct _ccv_problem noattr.
Definition workspace_type := Tstruct _ccv_workspace noattr.
Definition stats_type := Tstruct _ccv_stats noattr.
Definition bounds_spec : ident * funspec :=
 DECLARE _bounds
 WITH pp:val,wp:val,hp:val,sp:val,fp:val,yp:val,kp:val,rp:val,stp:val,
 sh:share,n:Z,m:Z,rem:Z,rules:int,h:list Z,xs:list Z,fs:list Z,ys:list Z,
 pk0:list val,counters:(Z*Z*Z),Bad:Prop
 PRE [tptr problem_type,tptr workspace_type,tuint,tuint,tptr tuint,tptr stats_type]
 PROP(readable_share sh;0<n<=Int.max_signed;0<=m;(m*n)%Z<=Int.max_signed;0<=rem<=n;
 Zlength h=(m*n)%Z;Zlength xs=n;Zlength fs=n;Zlength ys=m;Zlength pk0=n;
 Forall(fun z:Z=>z=0 \/ z=1) h;Forall(fun z:Z=>z=0 \/ z=1) xs;
 Forall(fun z:Z=>z=0 \/ z=1) fs;Forall(fun z:Z=>z=0 \/ z=1) ys;
 0<=(snd(fst counters))<Int.max_unsigned;0<=(snd counters)<Int.max_unsigned;0<=(fst(fst counters))<=Int.max_unsigned;
 bounds_policy n m h xs fs ys rem Bad)
 PARAMS(pp;wp;Vint(Int.repr rem);Vint rules;rp;stp)
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar ((m*n)%Z)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (pk0) kp;
 data_at Tsh tuint (Vint(Int.repr (fst(fst counters)))) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr (snd(fst counters)))) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr (snd counters))) stp)
 POST[tint] EX ret:Z,EX r:Z,EX pk:list Z,EX pc:Z,EX cc:Z,
 PROP(ret=0 \/ret=1;ret=0 ->Bad;0<=r<=m;ret=1 ->(r=m <->odd_count m ys=0);
 ret=1 ->r<m ->Znth r ys<>0;Zlength pk=n;Forall(fun z:Z=>z=0 \/ z=1)pk;
 (snd(fst counters))<=pc<=(snd(fst counters))+1;(snd counters)<=cc<=(snd counters)+1)
 RETURN(Vint(Int.repr ret))
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar ((m*n)%Z)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc)) stp).
Definition Gprog : funspecs :=ltac:(with_library prog [ceil_div_spec;bounds_spec]).
Lemma body_bounds : semax_body Vprog Gprog f_bounds bounds_spec.
Proof.
 start_function. destruct counters as [[oldrow pc0] cc0];cbn [fst snd] in *.
 assert(M:0<=m<=Int.max_signed) by nia.
 forward. forward. forward. forward. forward. forward. forward.
 forward_loop (EX q:Z, (PROP(0<=q<=n) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _q(Vint(Int.repr q));temp _best(Vint(Int.repr n));temp _pack(Vint Int.zero);temp _odd(Vint Int.zero);temp _maxdeg(Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar ((m*n)%Z)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (zero_prefix pk0 q) kp;
 data_at Tsh tuint (Vint(Int.repr m)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert
 break: (PROP() LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _best(Vint(Int.repr n));temp _pack(Vint Int.zero);temp _odd(Vint Int.zero);temp _maxdeg(Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar ((m*n)%Z)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (Zrepeat(Vint Int.zero)n) kp;
 data_at Tsh tuint (Vint(Int.repr m)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert.
 { Exists 0;rewrite zero_prefix_start;entailer!. }
 { Intros q. forward. forward_if.
   + forward. forward. forward. Exists(q+1);entailer!.
     rewrite zero_prefix_step by lia;cancel.
   + assert(q=n)by lia;subst q;forward;entailer!.
     rewrite zero_prefix_full by lia;cancel. }
 Intros.
 rewrite <- (tbytes_zero_repeat n).
 assert(ZeroLen:Zlength(Zrepeat 0 n)=n)by(rewrite Zlength_Zrepeat;lia).
 assert(ZeroBits:Forall(fun z:Z=>z=0 \/z=1)(Zrepeat 0 n))by apply zero_packed_bits.
 assert(ZeroMatch:packed_matches n h xs fs [](Zrepeat 0 n))by(apply zero_packed_matches;lia).
 assert(EmptyFamily:packed_family n m h xs fs ys [])by apply packed_family_empty.
 assert(InitialChoice:row_choice n m ys 0 m n)by(apply row_choice_initial;lia).
 forward.
 forward_loop (EX i:Z,EX best:Z,EX r:Z,EX rows:list nat,EX pk:list Z, (PROP(0<=i<=m;row_choice n m ys i r best;packed_family n m h xs fs ys rows;Forall(fun a=>(a<Z.to_nat i)%nat)rows;packed_matches n h xs fs rows pk;Zlength pk=n;Forall(fun z:Z=>z=0 \/z=1)pk) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best));temp _pack(Vint(Int.repr(Z.of_nat(length rows))));temp _odd(Vint(Int.repr(odd_count i ys)));temp _maxdeg(Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert
 break: (EX best:Z,EX r:Z,EX rows:list nat,EX pk:list Z, (PROP(row_choice n m ys m r best;packed_family n m h xs fs ys rows;Forall(fun a=>(a<Z.to_nat m)%nat)rows;packed_matches n h xs fs rows pk;Zlength pk=n;Forall(fun z:Z=>z=0 \/z=1)pk) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _best(Vint(Int.repr best));temp _pack(Vint(Int.repr(Z.of_nat(length rows))));temp _odd(Vint(Int.repr(odd_count m ys)));temp _maxdeg(Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert.
 { Exists 0 n m (@nil nat) (Zrepeat 0 n);entailer!;constructor. }
 { Intros i best r rows pk. forward. forward_if.
 + assert(Ybit:Znth i ys=0 \/Znth i ys=1)by(apply Forall_Znth;auto;lia).
   assert(OB:0<=odd_count i ys<=i)by(apply bitcount_bounds;lia).
   assert(PB:0<=Z.of_nat(length rows)<=i).
   { split;[lia|apply(packing_family_length n m h xs fs ys rows i);try assumption;lia]. }
   assert(BB:0<=best<=n)by(unfold row_choice in *;tauto).
   forward. unfold tbytes. forward.
   { entailer!;destruct Ybit as [Y|Y];rewrite Y;rep_lia. }
   forward_if
(EX bestj:Z,EX rj:Z,EX rowsj:list nat,EX pkj:list Z, (PROP(row_choice n m ys(i+1)rj bestj;packed_family n m h xs fs ys rowsj;Forall(fun a=>(a<Z.to_nat(i+1))%nat)rowsj;packed_matches n h xs fs rowsj pkj;Zlength pkj=n;Forall(fun z:Z=>z=0 \/z=1)pkj) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr bestj));temp _pack(Vint(Int.repr(Z.of_nat(length rowsj))));temp _odd(Vint(Int.repr(odd_count(i+1)ys)));temp _maxdeg(Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pkj) kp;
 data_at Tsh tuint (Vint(Int.repr rj)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert.
   * assert(Odd:Znth i ys<>0)by(intro Z;rewrite Z in *;contradiction).
     forward. forward. forward. forward.
     forward_loop (EX q:Z, (PROP(0<=q<=n) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best));temp _pack(Vint(Int.repr(Z.of_nat(length rows))));temp _odd(Vint(Int.repr(odd_count i ys+1)));temp _maxdeg(Vint Int.zero);temp _q(Vint(Int.repr q));temp _count(Vint(Int.repr(candidate_count q n i h xs fs)));temp _used(Vint(Int.repr(bitZ(used_prefix q n i h xs fs pk)))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert
 break: (PROP() LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best));temp _pack(Vint(Int.repr(Z.of_nat(length rows))));temp _odd(Vint(Int.repr(odd_count i ys+1)));temp _maxdeg(Vint Int.zero);temp _count(Vint(Int.repr(candidate_count n n i h xs fs)));temp _used(Vint(Int.repr(bitZ(used_prefix n n i h xs fs pk)))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert.
     { Exists 0;entailer!. }
     { Intros q. forward. forward_if.
       + assert(Index:0<=i*n+q<m*n)by(apply matrix_index;lia).
         assert(Hbit:Znth(i*n+q)h=0 \/Znth(i*n+q)h=1)by(apply Forall_Znth;auto;lia).
         assert(Xbit:Znth q xs=0 \/Znth q xs=1)by(apply Forall_Znth;auto;lia).
         assert(Fbit:Znth q fs=0 \/Znth q fs=1)by(apply Forall_Znth;auto;lia).
         assert(Kbit:Znth q pk=0 \/Znth q pk=1)by(apply Forall_Znth;auto;lia).
         assert(CB:0<=candidate_count q n i h xs fs<=q)by(apply bitcount_bounds;lia).
         unfold tbytes. forward. forward. forward.
         { entailer!;destruct Hbit as [B|B];rewrite B;rep_lia. }
         set(HX:=andb(negb(Znth(i*n+q)h=?0))(Znth q xs=?0)).
         forward_if (temp _t'1(Vint(Int.repr(bitZ HX)))).
         { assert(HT:(Znth(i*n+q)h=?0)=false)by(apply Z.eqb_neq;assumption).
           forward. forward. { entailer!;destruct Xbit as [B|B];rewrite B;rep_lia. }
           forward. entailer!. unfold HX;rewrite HT;destruct Xbit as [B|B];rewrite B;reflexivity. }
         { assert(Hz:Znth(i*n+q)h=0)by assumption.
           forward. entailer!. unfold HX;rewrite Hz;reflexivity. }
         set(HXF:=andb HX (Znth q fs=?0)).
         forward_if(temp _t'2(Vint(Int.repr(bitZ HXF)))).
         { assert(HXT:HX=true)by assumption.
           forward. forward. { entailer!;destruct Fbit as [B|B];rewrite B;rep_lia. }
           forward. entailer!. unfold HXF;rewrite HXT;destruct Fbit as [B|B];rewrite B;reflexivity. }
         { assert(HX0:HX=false)by assumption.
           forward. entailer!. unfold HXF;rewrite HX0;reflexivity. }
         assert(Free:HXF=free_vec n i h xs fs(Z.to_nat q)).
         { unfold HXF,HX;rewrite(free_vec_at n m i h xs fs q)by(try assumption;lia).
           destruct Hbit as [B|B];destruct Xbit as [X|X];destruct Fbit as [F|F];rewrite B,X,F;reflexivity. }
         assert(CStep:candidate_count(q+1)n i h xs fs=candidate_count q n i h xs fs+bitZ HXF).
         { unfold candidate_count;rewrite bitcount_step by lia;rewrite <-Free;reflexivity. }
         assert(UStep:used_prefix(q+1)n i h xs fs pk=
           orb(used_prefix q n i h xs fs pk)(andb HXF (Znth q pk=?1))).
         { rewrite used_prefix_step by lia;rewrite <-Free,decode_at_nat,Z2Nat.id by lia;reflexivity. }
         forward_if([temp _count(Vint(Int.repr(candidate_count(q+1)n i h xs fs)));
                     temp _used(Vint(Int.repr(bitZ(used_prefix(q+1)n i h xs fs pk))))]).
         { assert(FT:HXF=true)by assumption.
           forward. forward. forward. { entailer!;destruct Kbit as [B|B];rewrite B;rep_lia. }
           forward_if.
           { assert(K1:Znth q pk=1)by(destruct Kbit as [B|B];[contradiction|assumption]).
             forward. rewrite CStep,UStep,FT,K1. cbn [bitZ andb Z.eqb]. rewrite orb_true_r. entailer!. }
           { assert(K0:Znth q pk=0)by assumption.
             forward. rewrite CStep,UStep,FT,K0. cbn [bitZ andb Z.eqb]. rewrite orb_false_r. entailer!. } }
         { assert(FF:HXF=false)by assumption.
           forward. rewrite CStep,UStep,FF. cbn [bitZ andb]. rewrite orb_false_r. entailer!. }
         forward. Exists(q+1);entailer!.
       + assert(q=n)by lia;subst q;forward;entailer!. }
     Intros.
     assert(CFull:0<=candidate_count n n i h xs fs<=n)by(apply bitcount_bounds;lia).
     assert(RB:0<=r<=m)by(unfold row_choice in *;tauto).
     assert(Policy:bounds_policy n m h xs fs ys rem Bad)by assumption.
     forward_if.
     { assert(C0:candidate_count n n i h xs fs=0)by assumption.
       assert(BadProof:Bad)by(apply(proj1 Policy i);try assumption;lia).
       forward. Exists 0 r pk pc0 cc0;entailer!. }
     forward. forward.
     forward_if (EX take:bool, (PROP(take=false ->r<m) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best));temp _pack(Vint(Int.repr(Z.of_nat(length rows))));temp _odd(Vint(Int.repr(odd_count i ys+1)));temp _maxdeg(Vint Int.zero);temp _count(Vint(Int.repr(candidate_count n n i h xs fs)));temp _used(Vint(Int.repr(bitZ(used_prefix n n i h xs fs pk))));temp _t'3(Vint(Int.repr(bitZ take))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert.
     { forward. Exists true;entailer!;discriminate. }
     { assert(Less:r<m)by lia. forward_if.
       { forward. forward. Exists(candidate_count n n i h xs fs <?best);entailer!.
         match goal with |-context[zlt ?a ?b]=>destruct(zlt a b)as[L|L];[assert(E:(a<?b)=true)by(apply Z.ltb_lt;lia)|assert(E:(a<?b)=false)by(apply Z.ltb_ge;lia)];rewrite E;reflexivity end. }
       { forward. Exists false;entailer!. } }
     Intros take.
     forward_if (EX best1:Z,EX r1:Z, (PROP(row_choice n m ys(i+1)r1 best1) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best1));temp _pack(Vint(Int.repr(Z.of_nat(length rows))));temp _odd(Vint(Int.repr(odd_count i ys+1)));temp _maxdeg(Vint Int.zero);temp _count(Vint(Int.repr(candidate_count n n i h xs fs)));temp _used(Vint(Int.repr(bitZ(used_prefix n n i h xs fs pk)))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r1)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert.
     { assert(ChoiceNext:row_choice n m ys(i+1)i(candidate_count n n i h xs fs)).
       { apply row_choice_take;try assumption;lia. }
       forward. forward. Exists(candidate_count n n i h xs fs) i;entailer!. }
     { assert(TakeFalse:take=false)by assumption.
       assert(Less:r<m)by auto.
       assert(ChoiceNext:row_choice n m ys(i+1)r best).
       { apply row_choice_keep;try assumption;lia. }
       forward. Exists best r;entailer!. }
     Intros best1 r1.
     forward_if (EX enabled:bool, (PROP(enabled=true ->used_prefix n n i h xs fs pk=false) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best1));temp _pack(Vint(Int.repr(Z.of_nat(length rows))));temp _odd(Vint(Int.repr(odd_count i ys+1)));temp _maxdeg(Vint Int.zero);temp _count(Vint(Int.repr(candidate_count n n i h xs fs)));temp _used(Vint(Int.repr(bitZ(used_prefix n n i h xs fs pk))));temp _t'6(Vint(Int.repr(bitZ enabled))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r1)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert.
     { forward. Exists(negb(used_prefix n n i h xs fs pk)).
       destruct(used_prefix n n i h xs fs pk);cbn[bitZ];entailer!. }
     { forward. Exists false;entailer!;discriminate. }
     Intros enabled. forward_if.
     { assert(Unused:used_prefix n n i h xs fs pk=false)by auto.
       set(pknew:=packed_extend n i h xs fs pk).
       assert(NewLen:Zlength pknew=n)by(unfold pknew;apply packed_extend_length;lia).
       assert(NewBits:Forall(fun z:Z=>z=0 \/z=1)pknew)by(unfold pknew;apply packed_extend_bits;try assumption;lia).
       assert(NewMatch:packed_matches n h xs fs(rows++[Z.to_nat i])pknew).
       { unfold pknew;apply packed_extend_matches;try assumption;lia. }
       assert(NewFamily:packed_family n m h xs fs ys(rows++[Z.to_nat i])).
       { apply(packed_family_append n m h xs fs ys rows i pk);try assumption;lia. }
       assert(NextI:Z.to_nat(i+1)=S(Z.to_nat i)).
       { rewrite Z2Nat.inj_add by lia;simpl;rewrite Nat.add_1_r;reflexivity. }
       assert(NewEarlier:Forall(fun a=>(a<Z.to_nat(i+1))%nat)(rows++[Z.to_nat i])).
       { apply Forall_app;split.
         - assert(Earlier:Forall(fun a=>(a<Z.to_nat i)%nat)rows)by assumption.
           apply Forall_forall;intros a Hin;apply Forall_forall with(x:=a)in Earlier;[rewrite NextI;lia|assumption].
         - constructor;[rewrite NextI;lia|constructor]. }
       assert(NewCount:Z.of_nat(length(rows++[Z.to_nat i]))=Z.of_nat(length rows)+1).
       { rewrite app_length;simpl;rewrite Nat2Z.inj_add;reflexivity. }
       forward. forward.
       forward_loop (EX q:Z, (PROP(0<=q<=n) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best1));temp _pack(Vint(Int.repr(Z.of_nat(length rows)+1)));temp _odd(Vint(Int.repr(odd_count i ys+1)));temp _maxdeg(Vint Int.zero);temp _count(Vint(Int.repr(candidate_count n n i h xs fs)));temp _used(Vint Int.zero);temp _q(Vint(Int.repr q)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes(blend pk pknew q)) kp;
 data_at Tsh tuint (Vint(Int.repr r1)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert
 break: (PROP() LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best1));temp _pack(Vint(Int.repr(Z.of_nat(length rows)+1)));temp _odd(Vint(Int.repr(odd_count i ys+1)));temp _maxdeg(Vint Int.zero);temp _count(Vint(Int.repr(candidate_count n n i h xs fs)));temp _used(Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pknew) kp;
 data_at Tsh tuint (Vint(Int.repr r1)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert.
       { Exists 0;rewrite blend_start;rewrite Unused;entailer!. }
       { Intros q. forward. forward_if.
         + assert(Index:0<=i*n+q<m*n)by(apply matrix_index;lia).
           assert(Hbit:Znth(i*n+q)h=0 \/Znth(i*n+q)h=1)by(apply Forall_Znth;auto;lia).
           assert(Xbit:Znth q xs=0 \/Znth q xs=1)by(apply Forall_Znth;auto;lia).
           assert(Fbit:Znth q fs=0 \/Znth q fs=1)by(apply Forall_Znth;auto;lia).
           assert(BlendLen:Zlength(blend pk pknew q)=n)by(rewrite blend_length;try assumption;lia).
           unfold tbytes. forward. forward. forward.
           { entailer!;destruct Hbit as [B|B];rewrite B;rep_lia. }
           set(HX:=andb(negb(Znth(i*n+q)h=?0))(Znth q xs=?0)).
           forward_if(temp _t'4(Vint(Int.repr(bitZ HX)))).
         { assert(HT:(Znth(i*n+q)h=?0)=false)by(apply Z.eqb_neq;assumption).
           forward. forward. { entailer!;destruct Xbit as [B|B];rewrite B;rep_lia. }
           forward. entailer!. unfold HX;rewrite HT;destruct Xbit as [B|B];rewrite B;reflexivity. }
         { assert(Hz:Znth(i*n+q)h=0)by assumption.
           forward. entailer!. unfold HX;rewrite Hz;reflexivity. }
         set(HXF:=andb HX (Znth q fs=?0)).
         forward_if(temp _t'5(Vint(Int.repr(bitZ HXF)))).
         { assert(HXT:HX=true)by assumption.
           forward. forward. { entailer!;destruct Fbit as [B|B];rewrite B;rep_lia. }
           forward. entailer!. unfold HXF;rewrite HXT;destruct Fbit as [B|B];rewrite B;reflexivity. }
         { assert(HX0:HX=false)by assumption.
           forward. entailer!. unfold HXF;rewrite HX0;reflexivity. }
         assert(Free:HXF=free_vec n i h xs fs(Z.to_nat q)).
         { unfold HXF,HX;rewrite(free_vec_at n m i h xs fs q)by(try assumption;lia).
           destruct Hbit as [B|B];destruct Xbit as [X|X];destruct Fbit as [F|F];rewrite B,X,F;reflexivity. }
           forward_if (PROP() LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _i(Vint(Int.repr i));temp _best(Vint(Int.repr best1));temp _pack(Vint(Int.repr(Z.of_nat(length rows)+1)));temp _odd(Vint(Int.repr(odd_count i ys+1)));temp _maxdeg(Vint Int.zero);temp _count(Vint(Int.repr(candidate_count n n i h xs fs)));temp _used(Vint Int.zero);temp _q(Vint(Int.repr q)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes(blend pk pknew(q+1))) kp;
 data_at Tsh tuint (Vint(Int.repr r1)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert.
           { assert(FT:HXF=true)by assumption.
             assert(Tgt:Znth q pknew=1).
             { unfold pknew;rewrite packed_extend_at by lia;rewrite <-Free,FT;reflexivity. }
             pose proof(blend_step pk pknew q ltac:(lia)ltac:(lia))as Update;rewrite Tgt in Update.
             forward. forward.
             change (Vint(Int.zero_ext 8 (Int.repr 1))) with (Vint(Int.repr 1)).
             rewrite(upd_Znth_map (fun z:Z=>Vint(Int.repr z))q(blend pk pknew q)1)by lia.
             rewrite Update;entailer!. }
           { assert(FF:HXF=false)by assumption.
             assert(Tgt:Znth q pknew=Znth q pk).
             { unfold pknew;rewrite packed_extend_at by lia;rewrite <-Free,FF;reflexivity. }
             pose proof(blend_skip pk pknew q ltac:(lia)ltac:(lia)Tgt)as Update.
             forward. rewrite Update;entailer!. }
           forward. Exists(q+1);entailer!.
         + assert(Finish:blend pk pknew q=pknew).
           { replace q with(Zlength pk)by lia;apply blend_finish;lia. }
           forward. rewrite Finish;entailer!. }
       Intros.
       assert(Range1:0<=r1<=m)by(unfold row_choice in *;tauto).
       assert(OddNext:odd_count(i+1)ys=odd_count i ys+1)by(apply odd_count_step_one;try assumption;lia).
       forward_if.
       { assert(Big:Z.of_nat(length rows)+1>rem)by lia.
         assert(BadProof:Bad).
         { apply(proj1(proj2 Policy)(rows++[Z.to_nat i]));[exact NewFamily|rewrite NewCount;assumption]. }
         forward. forward. forward. Exists 0 r1 pknew (pc0+1) cc0;entailer!. }
       { forward. Exists best1 r1 (rows++[Z.to_nat i]) pknew.
         rewrite NewCount,OddNext;entailer!. } }
     { assert(Earlier:Forall(fun a=>(a<Z.to_nat i)%nat)rows)by assumption.
       assert(EarlierNext:Forall(fun a=>(a<Z.to_nat(i+1))%nat)rows).
       { apply Forall_forall;intros a Hin;apply Forall_forall with(x:=a)in Earlier;[|assumption].
         rewrite Z2Nat.inj_add by lia;simpl;lia. }
       assert(OddNext:odd_count(i+1)ys=odd_count i ys+1)by(apply odd_count_step_one;try assumption;lia).
       forward. Exists best1 r1 rows pk;rewrite OddNext;entailer!. }
   * assert(Zero:Znth i ys=0)by assumption.
     assert(ChoiceSkip:row_choice n m ys(i+1)r best)by(apply row_choice_skip;try assumption;lia).
     assert(Earlier:Forall(fun a=>(a<Z.to_nat i)%nat)rows)by assumption.
     assert(EarlierNext:Forall(fun a=>(a<Z.to_nat(i+1))%nat)rows).
     { apply Forall_forall;intros a Hin;apply Forall_forall with(x:=a)in Earlier;[|assumption].
       rewrite Z2Nat.inj_add by lia;simpl;lia. }
     forward. Exists best r rows pk;rewrite odd_count_step_zero by(try assumption;lia);entailer!.
   * Intros bestj rj rowsj pkj. forward. Exists(i+1) bestj rj rowsj pkj;entailer!.
 + assert(i=m)by lia;subst i;forward. Exists best r rows pk;entailer!. }
 Intros best r rows pk.
 assert(RangeR:0<=r<=m)by(unfold row_choice in *;tauto).
 assert(RowFinal:(r=m <->odd_count m ys=0)/\(r<m ->Znth r ys<>0)).
 { apply(row_choice_final n m ys r best);assumption. }
 assert(OddBound:0<=odd_count m ys<=m)by(apply bitcount_bounds;lia).
 assert(OddTest:(0<?odd_count m ys)=true ->odd_count m ys>0)by(intros T;apply Z.ltb_lt in T;lia).
 forward_if (EX active:bool, (PROP(active=true ->odd_count m ys>0) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _odd(Vint(Int.repr(odd_count m ys)));temp _maxdeg(Vint Int.zero);temp _t'9(Vint(Int.repr(bitZ active))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert.
 { forward. Exists(0<?odd_count m ys);entailer!;try assumption.
   match goal with |-context[zlt ?a ?b]=>destruct(zlt a b)as[L|L];[assert(E:(a<?b)=true)by(apply Z.ltb_lt;lia)|assert(E:(a<?b)=false)by(apply Z.ltb_ge;lia)];rewrite E;reflexivity end. }
 { forward. Exists false;entailer!;discriminate. }
 Intros active.
 forward_if (PROP() LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp)
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert.
 { assert(OddPositive:0<odd_count m ys)by(assert(P:odd_count m ys>0)by auto;lia).
   forward.
   forward_loop (EX q:Z,EX d:Z, (PROP(0<=q<=n;0<=d<=m;forall a,0<=a<q ->Znth a xs=0 ->Znth a fs=0 ->degree_count m n a h ys<=d) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _q(Vint(Int.repr q));temp _maxdeg(Vint(Int.repr d));temp _odd(Vint(Int.repr(odd_count m ys))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert
 break: (EX d:Z, (PROP(0<=d<=m;forall a,0<=a<n ->Znth a xs=0 ->Znth a fs=0 ->degree_count m n a h ys<=d) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _maxdeg(Vint(Int.repr d));temp _odd(Vint(Int.repr(odd_count m ys))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert.
   { Exists 0 0;entailer!;intros;lia. }
   { Intros q d. forward. forward_if.
   + assert(Xbit:Znth q xs=0 \/Znth q xs=1)by(apply Forall_Znth;auto;lia).
     assert(Fbit:Znth q fs=0 \/Znth q fs=1)by(apply Forall_Znth;auto;lia).
     forward. unfold tbytes. forward.
     { entailer!;destruct Xbit as [B|B];rewrite B;rep_lia. }
     set(FQ:=andb(Znth q xs=?0)(Znth q fs=?0)).
     forward_if(temp _t'7(Vint(Int.repr(bitZ FQ)))).
     { assert(X0:Znth q xs=0)by assumption.
       forward. forward. { entailer!;destruct Fbit as [B|B];rewrite B;rep_lia. }
       forward. entailer!. unfold FQ;rewrite X0;destruct Fbit as [B|B];rewrite B;reflexivity. }
     { assert(XN:Znth q xs<>0)by assumption.
       assert(XT:(Znth q xs=?0)=false)by(apply Z.eqb_neq;assumption).
       forward. entailer!. unfold FQ;rewrite XT;reflexivity. }
     forward_if (EX dnew:Z, (PROP(0<=dnew<=m;forall a,0<=a<q+1 ->Znth a xs=0 ->Znth a fs=0 ->degree_count m n a h ys<=dnew) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _q(Vint(Int.repr q));temp _maxdeg(Vint(Int.repr dnew));temp _odd(Vint(Int.repr(odd_count m ys))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert.
     { assert(FreeTrue:FQ=true)by assumption.
       assert(Sel0:Znth q xs=0 /\Znth q fs=0).
       { unfold FQ in FreeTrue;apply andb_true_iff in FreeTrue;destruct FreeTrue as [X F];apply Z.eqb_eq in X,F;auto. }
       forward. forward.
       forward_loop (EX i:Z, (PROP(0<=i<=m) LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _q(Vint(Int.repr q));temp _maxdeg(Vint(Int.repr d));temp _odd(Vint(Int.repr(odd_count m ys)));temp _i(Vint(Int.repr i));temp _deg(Vint(Int.repr(degree_count i n q h ys))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert)%assert
 break: (PROP() LOCAL(temp _p pp;temp _w wp;temp _remaining(Vint(Int.repr rem));temp _rules(Vint rules);temp _row rp;temp _stats stp;temp _q(Vint(Int.repr q));temp _maxdeg(Vint(Int.repr d));temp _odd(Vint(Int.repr(odd_count m ys)));temp _deg(Vint(Int.repr(degree_count m n q h ys))))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
 field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
 field_at sh problem_type [StructField _h] (hp) pp;
 field_at sh workspace_type [StructField _selected] (sp) wp;
 field_at sh workspace_type [StructField _forbidden] (fp) wp;
 field_at sh workspace_type [StructField _syndrome] (yp) wp;
 field_at sh workspace_type [StructField _packed] (kp) wp;
 data_at sh (tarray tuchar (m*n)) (tbytes h) hp;
 data_at sh (tarray tuchar n) (tbytes xs) sp;
 data_at sh (tarray tuchar n) (tbytes fs) fp;
 data_at sh (tarray tuchar m) (tbytes ys) yp;
 data_at Tsh (tarray tuchar n) (tbytes pk) kp;
 data_at Tsh tuint (Vint(Int.repr r)) rp;
 field_at Tsh stats_type [StructField _pack_prunes] (Vint(Int.repr pc0)) stp;
 field_at Tsh stats_type [StructField _charge_prunes] (Vint(Int.repr cc0)) stp))%assert.
       { Exists 0;entailer!. }
       { Intros i. forward. forward_if.
         + assert(Index:0<=i*n+q<m*n)by(apply matrix_index;lia).
           assert(Ybit:Znth i ys=0 \/Znth i ys=1)by(apply Forall_Znth;auto;lia).
           assert(Hbit:Znth(i*n+q)h=0 \/Znth(i*n+q)h=1)by(apply Forall_Znth;auto;lia).
           assert(DB:0<=degree_count i n q h ys<=i)by(apply bitcount_bounds;lia).
           assert(DStep:degree_count(i+1)n q h ys=degree_count i n q h ys+
                if Znth i ys=?0 then 0 else Znth(i*n+q)h).
           { unfold degree_count;rewrite bitcount_step by lia;unfold degree_vec;rewrite odd_vec_at by lia;rewrite Z2Nat.id by lia.
             rewrite(row_vector_column n m i h q)by(try assumption;lia).
             destruct Ybit as [Y|Y];destruct Hbit as [B|B];rewrite Y,B;reflexivity. }
           forward. unfold tbytes. forward.
           { entailer!;destruct Ybit as [B|B];rewrite B;rep_lia. }
           forward_if(temp _deg(Vint(Int.repr(degree_count(i+1)n q h ys)))).
           { assert(YN:Znth i ys<>0)by assumption.
             assert(YT:(Znth i ys=?0)=false)by(apply Z.eqb_neq;assumption).
             forward. forward. forward.
             { entailer!;destruct Hbit as [B|B];rewrite B;rep_lia. }
             forward. rewrite DStep,YT;entailer!. }
           { assert(Y0:Znth i ys=0)by assumption.
             forward. rewrite DStep,Y0;entailer!. }
           forward. Exists(i+1);entailer!.
         + assert(i=m)by lia;subst i;forward;entailer!. }
       Intros.
       assert(DBFull:0<=degree_count m n q h ys<=m)by(apply bitcount_bounds;lia).
       assert(OldUpper:forall a,0<=a<q ->Znth a xs=0 ->Znth a fs=0 ->degree_count m n a h ys<=d)by assumption.
       forward_if.
       { assert(NewUpper:forall a,0<=a<q+1 ->Znth a xs=0 ->Znth a fs=0 ->degree_count m n a h ys<=degree_count m n q h ys).
         { intros a A X F;destruct(Z.eq_dec a q)as [->|Ne];[lia|].
           pose proof(OldUpper a ltac:(lia) X F);lia. }
         forward. Exists(degree_count m n q h ys);entailer!. }
       { assert(NewUpper:forall a,0<=a<q+1 ->Znth a xs=0 ->Znth a fs=0 ->degree_count m n a h ys<=d).
         { intros a A X F;destruct(Z.eq_dec a q)as [->|Ne];[lia|].
           apply OldUpper;try assumption;lia. }
         forward. Exists d;entailer!. } }
     { assert(FreeFalse:FQ=false)by assumption.
       assert(OldUpper:forall a,0<=a<q ->Znth a xs=0 ->Znth a fs=0 ->degree_count m n a h ys<=d)by assumption.
       assert(NewUpper:forall a,0<=a<q+1 ->Znth a xs=0 ->Znth a fs=0 ->degree_count m n a h ys<=d).
       { intros a A X F;destruct(Z.eq_dec a q)as [->|Ne].
         - unfold FQ in FreeFalse;rewrite X,F in FreeFalse;discriminate.
         - apply OldUpper;try assumption;lia. }
       forward. Exists d;entailer!. }
     Intros dnew. forward. Exists(q+1)dnew;entailer!.
   + assert(q=n)by lia;subst q;forward. Exists d;entailer!. }
   Intros d.
   assert(Upper:degree_upper n m h xs fs ys d)by assumption.
   assert(Policy:bounds_policy n m h xs fs ys rem Bad)by assumption.
   forward_if.
   { assert(D0:d=0)by assumption.
     assert(BadProof:Bad).
     { apply(proj2(proj2 Policy)d);try assumption;try lia;left;assumption. }
     forward. Exists 0 r pk pc0 cc0;entailer!. }
   assert(DPos:0<d)by lia.
   forward_call(Int.repr(odd_count m ys),Int.repr d).
   try rewrite !Int.unsigned_repr by rep_lia.
   assert(CeilBound:0<=CCWord.ceil_Z(odd_count m ys)d<=odd_count m ys).
   { apply CCWord.ceil_Z_range;lia. }
   forward_if.
   { assert(Big:CCWord.ceil_Z(odd_count m ys)d>rem)by lia.
     assert(BadProof:Bad).
     { apply(proj2(proj2 Policy)d);try assumption;try lia;right;split;assumption. }
     forward. forward. forward. Exists 0 r pk pc0 (cc0+1);entailer!. }
   { forward;entailer!. } }
 { forward;entailer!. }
 forward. Exists 1 r pk pc0 cc0;entailer!;tauto.
Qed.
Print Assumptions body_bounds.
