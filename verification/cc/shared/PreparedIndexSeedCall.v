(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit
 EnabledCall OverlapColumnState VerifSeedIndex SeedLoopModel PreparedSeedDispatch PreparedRootStages
 PreparedDepthSpec PreparedBudgetContract PreparedPlainDescent PreparedIndexGlobals PreparedIndexRoot
 PreparedRecursiveCall PreparedWitnessRegister PreparedIndexArena flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition seed_counter s value:=field_at Tsh level_type [StructField _seeds] (Vlong value) s.
Section Seed.
Variables (c:policy_state) (ph:root_phases) (gv:globals) (s cp bp base:val) (stride w:Z)
 (heap:node_storage) (entry:entry_domain) (report:budget_report) (witness:Z->list int->Prop).
Let n:=root_count ph.
Let arena:=live_arena base stride n 1.
Let rec_heap:=weight_bounded_rows base stride n heap.
Let calls:=prepared_calls (snd (depth_flip c heap Int.zero))
  (snd (index_dfs_using_globals gv entry rec_heap report witness Int.zero)).

Theorem visit_native_seed {Espec:OracleKind} i st path old count:
 0<=i<n -> n<=Int.max_signed -> 1<=w<=n -> w<=Zlength path ->
 nested_policy (nested c)=nullval -> i+1<Zlength (column_offsets (geometry c)) ->
 blocked st=seen n (i+1) -> entry (geometry c) s cp bp w st [Int.repr i] ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars calls [])
 (PROPx [] (LOCALx (root_call_regs ph s gv i)
  (SEPx [child_fields s cp bp w (seen n i) path;seed_counter s count;
         heap s [];arena;witness_register s old])))
 run_root (normal_ret_assert (EX tail:list int,EX r:Z,EX written:int,
   PROPx [0<=r<=3;Zlength tail=Zlength path;active_prefix 1 tail=[Int.repr i];
       report w (geometry c) st [Int.repr i] r tail;witness_at_limit w old r written tail;
       witness_status r -> witness (Int.signed written) tail]
    (LOCALx (temp _result (Vint (Int.repr r))::root_call_regs ph s gv i)
    (SEPx [child_fields s cp bp w (seen n i) tail;seed_counter s (Int64.add count Int64.one);
         heap s [];arena;witness_register s written])))).
Proof.
 intros index cap weight room plain col blocks admitted.
 unfold run_root,begin_seed,clear_verdict,visit_root,end_seed,root_call_regs,root_regs,child_fields,seed_counter.
 abbreviate_semax;Intros;reassoc_seq.
 assert (len:Zlength (seen n i)=n) by (apply seen_length;lia).
 assert (free:Znth i (seen n i)=Int.zero) by
   (rewrite seen_cell by lia;destruct (Z_lt_dec i i);[lia|reflexivity]).
 assert (nextlen:Zlength (seen n (i+1))=n) by (apply seen_length;lia).
 assert (busy:Znth i (seen n (i+1))=Int.one) by
   (rewrite seen_cell by lia;destruct (Z_lt_dec i (i+1));[reflexivity|lia]).
 apply semax_if_seq;forward_if;[contradiction|forward].
 forward. forward. rewrite free.
 apply semax_if_seq;forward_if;[|solve [contradiction|congruence]].
 do 5 forward. rewrite free. forward.
 rewrite upd_Znth_map,put_seed by lia.
 forward_call (s,(@nil int),i,true);try solve [rewrite plain;entailer!;rep_lia].
 reassoc_seq;apply semax_if_seq;forward_if;[contradiction|forward].
 forward. rewrite upd_Znth_map.
 set (saved:=upd_Znth 0 path (Int.repr i)).
 assert (same:Zlength saved=Zlength path) by (unfold saved;apply upd_Znth_Zlength;lia).
 assert (first:active_prefix 1 saved=[Int.repr i]) by
   (apply first_prefix;[lia|unfold saved;rewrite upd_Znth_same by lia;reflexivity]).
 forward_call (geometry c,s,cp,bp,w,1,st,saved,old);
   try solve [rewrite first;entailer!;rep_lia|entailer!;rep_lia].
 { unfold child_fields;rewrite first,blocks,nextlen.
   unfold rec_heap,weight_bounded_rows,depth_rows;cbn [Zlength Zlength_aux];fold arena.
   unfold Frame;entailer!;cancel.
   rewrite len,same;cbn [app];change (live_arena base stride n (Z.succ 0)) with arena.
   instantiate (Frame:=[seed_counter s (Int64.add count Int64.one)]).
   unfold seed_counter;cbn [fold_right_sepcon];cancel;apply derives_refl. }
 Intros answer;destruct answer as [[tail r] written];cbn [fst snd] in *.
 rewrite first in *;unfold child_fields;rewrite blocks,nextlen.
 unfold rec_heap,weight_bounded_rows,depth_rows;cbn [Zlength Zlength_aux];fold arena;Intros.
 forward. reassoc_seq;apply semax_if_seq;forward_if;[contradiction|].
 forward_call (s,(@nil int),i,false);try solve [rewrite plain;entailer!;rep_lia].
 { unfold Frame;instantiate (Frame:=[child_fields s cp bp w (seen n (i+1)) tail;
       arena;witness_register s written;seed_counter s (Int64.add count Int64.one)]).
   cbn [app fold_right_sepcon];unfold child_fields;rewrite nextlen;cancel;apply derives_refl. }
 unfold child_fields;rewrite nextlen;Intros.
 do 3 forward. rewrite busy. forward.
 change (Int.sub Int.one (Int.repr 1)) with Int.zero.
 rewrite upd_Znth_map,remove_seed by lia.
 forward_if;[contradiction|forward].
 Exists tail r written;entailer!;cancel;try apply derives_refl.
 rewrite seen_length by lia;unfold seed_counter;cancel.
Qed.
End Seed.
