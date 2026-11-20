(* IN PROGRESS: Hoare proof of the actual C phase-1 scan loop.
   Not a proof of the complete search body. No function or C source is replaced. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps.
Require Import CCV.ccv_core CCV.CCSearchScan CCV.CCMatrix CCV.VerifToggle CCV.CCSearchSpecs.
Import ListNotations.
Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition Vprog :varspecs. mk_varspecs ccv_core.prog. Defined.
Definition scan_delta (G:funspecs):tycontext :=func_tycontext ccv_core.f_search Vprog G [].
Definition problem_type :=Tstruct _ccv_problem noattr.
Definition workspace_type :=Tstruct _ccv_workspace noattr.
Definition frame_type :=Tstruct _ccv_frame noattr.
Record scan_addresses := {
 sa_problem:val;sa_workspace:val;sa_h:val;
 sa_selected:val;sa_forbidden:val;sa_frame:val
}.
Definition scan_available n row (h xs fs:list Z) q :=
 andb(negb(Znth(row*n+q)h=?0))(andb(Znth q xs=?0)(Znth q fs=?0)).
Definition scan_skipped n row h xs fs lo hi :=
 forall j,lo<=j<hi ->scan_available n row h xs fs j=false.
Definition scan_memory sh a n m row h xs fs :mpred :=
 (field_at sh problem_type[StructField _n](Vint(Int.repr n))(sa_problem a)*
  field_at sh problem_type[StructField _h](sa_h a)(sa_problem a)*
  field_at sh workspace_type[StructField _selected](sa_selected a)(sa_workspace a)*
  field_at sh workspace_type[StructField _forbidden](sa_forbidden a)(sa_workspace a)*
  field_at Tsh frame_type[StructField _row](Vint(Int.repr row))(sa_frame a)*
  data_at sh(tarray tuchar((m*n)%Z))(tbytes h)(sa_h a)*
  data_at Tsh(tarray tuchar n)(tbytes xs)(sa_selected a)*
  data_at Tsh(tarray tuchar n)(tbytes fs)(sa_forbidden a))%logic.
Definition scan_state sh a n m row next h xs fs q :assert :=
 (PROP(next<=q<=n;scan_skipped n row h xs fs next q)
  LOCAL(temp _p(sa_problem a);temp _w(sa_workspace a);temp _f(sa_frame a);
        temp _q(Vint(Int.repr q)))
  SEP(scan_memory sh a n m row h xs fs))%assert.
Lemma scan_skipped_step n row h xs fs lo hi :
 scan_skipped n row h xs fs lo hi ->scan_available n row h xs fs hi=false ->
 scan_skipped n row h xs fs lo(hi+1).
Proof.
 unfold scan_skipped;intros Old Last j J;destruct(Z.eq_dec j hi)as[->|Ne];[assumption|apply Old;lia].
Qed.
Section ScanProof.
Context {Espec:OracleKind}.
Lemma block_candidate_scan :forall(G:funspecs)(sh:share)(a:scan_addresses)
 (n m row next:Z)(h xs fs:list Z),
 readable_share sh ->0<n<=Int.max_signed ->0<=m ->(m*n)%Z<=Int.max_signed ->
 0<=row<m ->0<=next<=n ->Zlength h=(m*n)%Z ->Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0 \/z=1)h ->Forall(fun z:Z=>z=0 \/z=1)xs ->Forall(fun z:Z=>z=0 \/z=1)fs ->
 semax(scan_delta G)
 (PROP() LOCAL(temp _p(sa_problem a);temp _w(sa_workspace a);temp _f(sa_frame a);
                temp _q(Vint(Int.repr next)))
  SEP(scan_memory sh a n m row h xs fs))%assert
 CCSearchScan.scan_loop
 (normal_ret_assert
  (EX q:Z,PROP(next<=q<=n;scan_skipped n row h xs fs next q;
              q<n ->scan_available n row h xs fs q=true)
   LOCAL(temp _p(sa_problem a);temp _w(sa_workspace a);temp _f(sa_frame a);
         temp _q(Vint(Int.repr q)))
   SEP(scan_memory sh a n m row h xs fs))%assert).
Proof.
 intros G sh a n m row next h xs fs SH N M Product Row Next Hlen Xlen Flen HB XB FB.
 set(guard:=fun q:Z=>andb(q<?n)(negb(scan_available n row h xs fs q))).
 assert(Skip0:scan_skipped n row h xs fs next next)by(unfold scan_skipped;intros;lia).
 pose (DS := @abbreviate (PTree.t funspec) (make_tycontext_s G)).
 pose (DG := @abbreviate (PTree.t type) (make_tycontext_g Vprog G)).
 pose (Delta := @abbreviate tycontext (func_tycontext ccv_core.f_search Vprog G [])).
 unfold scan_delta;change (func_tycontext ccv_core.f_search Vprog G []) with Delta.
 unfold func_tycontext, make_tycontext in Delta.
 change (make_tycontext_s G) with DS in Delta.
 change (make_tycontext_g Vprog G) with DG in Delta.
 cbv beta iota zeta delta - [abbreviate DS DG] in Delta.
 let C := eval cbv - [Int.repr] in CCSearchScan.scan_loop in
 lazymatch goal with |- semax ?D ?P _ ?R => change (semax D P C R) end.
 abbreviate_semax.
 forward_loop (EX q:Z,scan_state sh a n m row next h xs fs q)%assert.
 { Exists next. unfold scan_state;entailer!. }
 Intros q. unfold scan_state,scan_memory. Intros.
 forward.
 forward_if (PROP() LOCAL(temp _t'9(Vint(Int.repr(if guard q then 1 else 0)));
   temp _p(sa_problem a);temp _w(sa_workspace a);temp _f(sa_frame a);
   temp _q(Vint(Int.repr q))) SEP(scan_memory sh a n m row h xs fs))%assert.
 { forward. forward. forward.
   assert(I:0<=row*n+q<m*n)by(apply CCMatrix.matrix_index;lia).
   assert(Hbit:Znth(row*n+q)h=0\/Znth(row*n+q)h=1)
     by(apply (proj1(Forall_Znth _ _)HB);lia).
   unfold tbytes. forward.
   { destruct Hbit as[Hb|Hb];rewrite Hb;entailer!. }
   forward_if (PROP() LOCAL(temp _t'10(Vint(Int.repr
      (if orb(Znth(row*n+q)h=?0)(negb(Znth q xs=?0)) then 1 else 0)));
     temp _p(sa_problem a);temp _w(sa_workspace a);temp _f(sa_frame a);
     temp _q(Vint(Int.repr q))) SEP(scan_memory sh a n m row h xs fs))%assert.
   { forward. unfold scan_memory,tbytes. entailer!. rewrite H2;reflexivity. }
   { forward.
     assert(Xbit:Znth q xs=0\/Znth q xs=1)
       by(apply (proj1(Forall_Znth _ _)XB);lia).
     forward. { destruct Xbit as[Hx|Hx];rewrite Hx;entailer!. }
     forward. unfold scan_memory,tbytes;entailer!.
     rewrite (proj2(Z.eqb_neq _ _)H2).
     destruct Xbit as[Hx|Hx];rewrite Hx;reflexivity. }
   forward_if.
   { forward. unfold guard,scan_available,scan_memory. entailer!.
     rewrite (proj2(Z.ltb_lt _ _)H1).
     destruct(Znth(row*Zlength xs+q)h=?0)eqn:Ah;
       destruct(Znth q xs=?0)eqn:Ax;simpl in *;try congruence;reflexivity. }
   { unfold scan_memory. Intros. forward.
     assert(Fbit:Znth q fs=0\/Znth q fs=1)
       by(apply (proj1(Forall_Znth _ _)FB);lia).
     unfold tbytes;forward.
     { destruct Fbit as[Hf|Hf];rewrite Hf;entailer!. }
     forward. forward. unfold scan_memory,tbytes;entailer!.
     unfold guard,scan_available;rewrite (proj2(Z.ltb_lt _ _)H1).
     destruct(Znth(row*Zlength xs+q)h=?0)eqn:Ah;
       destruct(Znth q xs=?0)eqn:Ax;simpl in H2|-*;try discriminate.
     destruct Fbit as[Hf|Hf];rewrite Hf;reflexivity. }
 }
 { forward. unfold guard,scan_memory. entailer!.
   rewrite (proj2(Z.ltb_ge q (Zlength xs)) ltac:(lia));reflexivity. }
 Intros. forward_if.
 { assert(Gq:guard q=true)by(destruct(guard q);congruence).
   unfold guard in Gq;apply andb_true_iff in Gq;destruct Gq as[Inside Bad].
   apply Z.ltb_lt in Inside;apply negb_true_iff in Bad.
   forward. Exists(q+1). unfold scan_state. entailer!.
   apply scan_skipped_step;assumption. }
 { assert(Gq:guard q=false)by(destruct(guard q);[discriminate|reflexivity]).
   forward. Exists q. entailer!.
   unfold guard in Gq.
   rewrite (proj2(Z.ltb_lt _ _)H5) in Gq.
   simpl in Gq. apply negb_false_iff in Gq;assumption. }
Qed.
End ScanProof.
Print Assumptions block_candidate_scan.
