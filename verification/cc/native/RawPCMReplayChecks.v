(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq ClightSelect raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMComposites.
Local Open Scope Z_scope.

Definition replay_checks:statement:=ltac:(native_fragment (counts_on _r) f_replay).
Definition replay_level:=Tstruct _cc_level noattr.
Definition replay_trace sh s cp d path:=
 (field_at sh replay_level [StructField _witness_size] (Vint (Int.repr d)) s *
  field_at sh replay_level [StructField _cur] cp s *
  data_at sh (tarray tint (Zlength path)) (map Vint path) cp)%logic.
Fixpoint sparse_parity bytes path (n r:Z) (i:nat):bool:=
 match i with
 | O=>false
 | S k=>xorb (sparse_parity bytes path n r k)
    (Znth (r*n+Int.signed (Znth (Z.of_nat k) path)) bytes)
 end.
Lemma append_replay_bit bytes path n r i:0<=i ->
 sparse_parity bytes path n r (Z.to_nat (i+1))=xorb (sparse_parity bytes path n r (Z.to_nat i))
   (Znth (r*n+Int.signed (Znth i path)) bytes).
Proof. intro lo;replace (i+1) with (Z.succ i) by lia;rewrite Z2Nat.inj_succ by lia;cbn;rewrite Z2Nat.id by lia;reflexivity. Qed.
Definition replay_check_calls:funspecs:=ltac:(with_library prog [entry_spec]).
Definition replay_loc s checks same:=[temp _s s;temp _checks checks;temp _same same].

Theorem every_physical_syndrome_zero {Espec:OracleKind} s checks same cp buf sa sp nr n d bytes path:
 readable_share sa -> readable_share sp -> 0<=nr<=Int.max_signed -> 0<=n<=Int.max_signed ->
 0<=d<=Int.max_signed -> d<=Zlength path -> Zlength bytes=nr*n ->
 (forall i,0<=i<d -> 0<=Int.signed (Znth i path)<n) ->
 (forall r,0<=r<nr -> sparse_parity bytes path n r (Z.to_nat d)=false) ->
 let memory:=(matrix_bytes sa checks buf nr n bytes * replay_trace sp s cp d path)%logic in
 let loc:=replay_loc s checks same in
 semax (func_tycontext f_replay raw_vars replay_check_calls [])
 (PROPx [] (LOCALx loc (SEPx [memory]))) replay_checks
 (normal_ret_assert (PROPx [] (LOCALx loc (SEPx [memory])))).
Proof.
 intros read_a read_p rows cols size valid length addresses zero memory loc.
 unfold replay_checks,loc,replay_loc;abbreviate_semax;Intros. forward.
 forward_loop (EX r:Z,PROP(0<=r<=nr) LOCAL(temp _r (Vint (Int.repr r));temp _s s;temp _checks checks;temp _same same) SEP(memory))
   continue:(EX r:Z,PROP(0<=r<nr) LOCAL(temp _r (Vint (Int.repr r));temp _s s;temp _checks checks;temp _same same) SEP(memory))%assert
   break:(PROP() LOCAL(temp _s s;temp _checks checks;temp _same same) SEP(memory))%assert.
 - Exists 0;entailer!.
 - Intros r;unfold memory,matrix_bytes,pcm_view_type;Intros;forward;forward_if.
   2:{ forward;unfold memory,matrix_bytes,pcm_view_type;entailer!. }
   assert (row_ok:0<=r<nr) by rep_lia.
   forward. forward.
   forward_loop (EX i:Z,PROP(0<=i<=d)
     LOCAL(temp _i__1 (Vint (Int.repr i));temp _r (Vint (Int.repr r));temp _syndrome (cbit (sparse_parity bytes path n r (Z.to_nat i)));
           temp _s s;temp _checks checks;temp _same same) SEP(memory))
     continue:(EX i:Z,PROP(0<=i<d)
       LOCAL(temp _i__1 (Vint (Int.repr i));temp _r (Vint (Int.repr r));temp _syndrome (cbit (sparse_parity bytes path n r (Z.to_nat (i+1))));
             temp _s s;temp _checks checks;temp _same same) SEP(memory))%assert
     break:(PROP() LOCAL(temp _r (Vint (Int.repr r));temp _syndrome (Vint Int.zero);
       temp _s s;temp _checks checks;temp _same same) SEP(memory))%assert.
   + Exists 0;unfold memory,matrix_bytes,pcm_view_type;entailer!.
   + Intros i;unfold memory,matrix_bytes,pcm_view_type,replay_trace,replay_level;Intros;forward;forward_if.
     2:{ assert (i=d) by rep_lia;subst i;rewrite (zero r row_ok);forward;
         unfold memory,matrix_bytes,pcm_view_type,replay_trace,replay_level;entailer!. }
     assert (inside:0<=i<d) by rep_lia;simpl in inside.
     assert (in_pcm:=addresses i inside).
     do 2 forward. fold pcm_view_type.
     forward_call (checks,buf,sa,nr,n,bytes,r,Int.signed (Znth i path));try solve [
       unfold matrix_bytes,pcm_view_type;rewrite ?Int.repr_signed;entailer!;cancel;apply derives_refl].
     forward;Exists i;rewrite append_replay_bit by lia.
     unfold memory,matrix_bytes,pcm_view_type,replay_trace,replay_level;entailer!;try cancel;try apply derives_refl.
     unfold cbit;destruct (sparse_parity bytes path n r (Z.to_nat i)),(Znth (r*n+Int.signed (Znth i path)) bytes);
       try reflexivity;try solve [entailer!;cancel;apply derives_refl].
   + Intros i;forward;Exists (i+1);entailer!.
   + forward_if;[contradiction|forward;Exists r;entailer!].
 - Intros r;forward;Exists (r+1);entailer!.
 - apply andp_left2;apply derives_refl.
Qed.
