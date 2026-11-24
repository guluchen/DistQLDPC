(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected ClightSelect ClightNested.
Definition mark_loop : statement:=ltac:(native_while_fragment (counts_on _i__1) f_index_children).
Definition mark_word (stamp:int64) (ms:list int64) (q:int) := upd_Znth (Int.unsigned q) ms stamp.
Definition marked (stamp:int64) (ms:list int64) (cols:list int) lo i :=
 fold_left (mark_word stamp) (sublist lo i cols) ms.
Lemma mark_step t ms cols lo i:0<=lo<=i->i<Zlength cols->
 marked t ms cols lo (i+1)=mark_word t (marked t ms cols lo i) (Znth i cols).
Proof. intros;unfold marked;rewrite (sublist_split lo i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity. Qed.
Lemma marked_words_length t ms xs :
 Forall (fun q=>Int.unsigned q<Zlength ms) xs ->
 Zlength (fold_left (mark_word t) xs ms)=Zlength ms.
Proof.
 revert ms;induction xs as [|q xs IH];intros ms ok;[reflexivity|].
 inversion ok as [|? ? valid rest];subst. cbn [fold_left].
 assert (L:Zlength (mark_word t ms q)=Zlength ms)
   by (unfold mark_word;rewrite upd_Znth_Zlength by (pose proof (Int.unsigned_range q);lia);reflexivity).
 rewrite IH;[exact L|rewrite L;exact rest].
Qed.
Lemma mark_range t ms cols lo i : 0<=lo<=i->i<=Zlength cols->
 (forall j,lo<=j<i->Int.unsigned (Znth j cols)<Zlength ms)->
 Zlength (marked t ms cols lo i)=Zlength ms.
Proof.
 intros bounds len valid;apply marked_words_length;apply Forall_forall;intros q member.
 destruct (In_Znth _ _ member) as [j [within read]].
 rewrite Zlength_sublist in within by lia.
 rewrite Znth_sublist in read by lia;subst q;apply valid;lia.
Qed.
Definition mark_memory s cp mp cols marks :=
 (field_at Tsh level_type [StructField _rq] cp s *
  data_at Tsh (tarray tuint (Zlength cols)) (map Vint cols) cp *
  field_at Tsh level_type [StructField _mark] mp s *
  data_at Tsh (tarray tulong (Zlength marks)) (map Vlong marks) mp)%logic.
Definition mark_env s lo hi t :=
 [temp _s s;temp _begin (Vint (Int.repr lo));temp _end (Vint (Int.repr hi));temp _stamp (Vlong t)].
Theorem semax_mark_row {Espec:OracleKind} s cp mp cols marks lo hi t :
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols ->
 (forall j,lo<=j<hi -> Int.unsigned (Znth j cols)<Zlength marks)->
 semax (func_tycontext f_index_children Vprog [] [])
  (PROPx nil (LOCALx (mark_env s lo hi t) (SEPx [mark_memory s cp mp cols marks])))
  mark_loop
  (normal_ret_assert (PROPx nil (LOCALx (mark_env s lo hi t)
     (SEPx [mark_memory s cp mp cols (marked t marks cols lo hi)])))).
Proof.
 intros bound cap len live;unfold mark_loop,mark_env;cbn iota;abbreviate_semax. forward.
 forward_loop
  (EX i:Z, PROPx [lo<=i<=hi] (LOCALx (temp _i__1 (Vint (Int.repr i))::mark_env s lo hi t)
        (SEPx [mark_memory s cp mp cols (marked t marks cols lo i)])))%assert
 break: (PROPx nil (LOCALx (mark_env s lo hi t)
        (SEPx [mark_memory s cp mp cols (marked t marks cols lo hi)])))%assert.
 - Exists lo;unfold mark_env,marked;rewrite sublist_nil by lia;entailer!;apply derives_refl.
 - Intros i;unfold mark_env,mark_memory;Intros;forward_if.
   + assert (pos:lo<=i<hi) by rep_lia.
     pose proof (live i pos) as index_ok.
     pose proof (Int.unsigned_range (Znth i cols)) as nn.
     assert (mslen:Zlength (marked t marks cols lo i)=Zlength marks)
       by (apply mark_range;try lia;intros;apply live;lia).
     do 5 forward. Exists (i+1);unfold mark_env,mark_memory;rewrite mark_step by lia.
     unfold mark_word;rewrite upd_Znth_Zlength,upd_Znth_map by lia;entailer!.
   + assert (i=hi) by rep_lia;subst;forward;unfold mark_env,mark_memory;entailer!;try apply derives_refl.
 - unfold mark_env;entailer!;try apply derives_refl.
Qed.
