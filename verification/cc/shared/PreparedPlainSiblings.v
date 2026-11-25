(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver VerifDetected VerifChildVisit
 VerifSiblingRollback SiblingCounters EnabledCall EnabledLoopFacts OverlapColumnState
 OverlapChildState PreparedSeedDispatch PreparedRootStages PreparedRecursiveCall
 PreparedDepthSpec PreparedBudgetContract PreparedChildCall PreparedChildMode PreparedSiblingScan
 PreparedPlainDescent flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition plain_scan_regs s children d count i code bits:=
 [temp _s s;temp _children children;temp _policy nullval;temp _options (Vint bits);
  temp _update_overlap (Vint Int.zero);temp _size (Vint (Int.repr d));temp _count (Vint (Int.repr count));
  temp _excluded (Vint (Int.repr i));temp _result (Vint (Int.repr code))].

Section Scan.
Context {Espec:OracleKind}.
Variables (c:policy_state) (heap:node_storage) (recursive_heap:budget_heap) (loan:mpred)
 (report:budget_report) (bits:int) (s cp bp children:val) (xs:list Z) (root:snapshot) (path:list int) (w d:Z).
Let g:=geometry c.
Let base:=blocked root.
Let parent:=active_prefix d path.
Let regs:=plain_scan_regs s children d (Zlength xs).
Let memory i cur:=(child_fields s cp bp w (added xs base i) cur * child_array children xs *
                   heap s parent * loan)%logic.
Let result i code tail:=scan_outcome_mode false (report w) g root xs parent i code tail.
Hypotheses (plain:nested_policy (nested c)=nullval) (depth:1<=d<w-2) (cap:w<=Int.max_signed)
 (room:w<=Zlength path) (count:Zlength xs<=Int.max_signed)
 (limit:Zlength base<=Int.max_signed) (range:in_array (Zlength base) xs)
 (columns:Zlength base<Zlength (column_offsets g))
 (lend:forall node,Zlength node=d+1 -> recursive_heap w s node=(heap s node * loan)%logic).

(* Every C iteration records its actual recursive result and physical
   block counters. The suffix after a nonempty result is never visited. *)
Theorem null_policy_sibling_scan :
 semax (func_tycontext f_dfs prepared_vars (prepared_calls (snd (depth_flip c heap bits))
   (snd (plain_dfs_contract recursive_heap report bits))) nil)
   (PROPx nil (LOCALx (regs 0 0 bits) (SEPx [memory 0 path])))
   search_children
   (normal_ret_assert (EX i:Z,EX code:Z,EX tail:list int,
    PROPx [result i code tail;0<=code<=3;Zlength tail=Zlength path;active_prefix d tail=parent]
      (LOCALx (regs i code bits) (SEPx [memory i tail])))).
Proof.
 unfold g in columns. unfold search_children,regs,plain_scan_regs;abbreviate_semax;forward.
 forward_loop (EX i:Z,EX cur:list int,
    PROPx [0<=i<=Zlength xs;prior_empty_mode false (report w) g root xs parent i;
           Zlength cur=Zlength path;active_prefix d cur=parent]
    (LOCALx (temp _i (Vint (Int.repr i))::regs i 0 bits) (SEPx [memory i cur])))%assert
 break: (EX i:Z,EX code:Z,EX tail:list int,
    PROPx [result i code tail;0<=code<=3;Zlength tail=Zlength path;active_prefix d tail=parent]
      (LOCALx (regs i code bits) (SEPx [memory i tail])))%assert.
 - Exists 0 path;unfold regs,plain_scan_regs,parent;entailer!;try apply derives_refl.
   unfold prior_empty_mode;intros;lia.
 - Intros i cur;unfold regs,plain_scan_regs;forward_if.
   2:{ forward;Exists i 0 cur;unfold result,regs,plain_scan_regs,scan_outcome_mode;entailer!;intuition lia. }
   assert (pos:0<=i<Zlength xs) by rep_lia.
   set (q:=Znth i xs).
   assert (valid:0<=q<Zlength base) by
     (apply Forall_forall with (x:=q) in range;[exact range|apply Znth_In;lia]).
   pose proof (@added_length xs base i range) as len.
   pose proof (@added_length xs base (i+1) range) as next_len.
   unfold memory,child_fields,child_array;Intros;do 6 forward;rewrite upd_Znth_map;change (Int.repr 1) with Int.one.
   forward_call (s,parent,q,true);try solve [rewrite plain;entailer!;lia|entailer!;lia|lia].
   reassoc_seq;unfold_abbrev'.
   match goal with |- semax _ _ ?body _ =>
     let suffix:=lazymatch body with
       Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ ?rest)))))=>rest end in
     apply (semax_unfold_seq (Ssequence child_bracket suffix) body eq_refl) end.
   set (seen:=sibling_state root xs (i+1)).
   assert (marked:blocked seen=added xs base (i+1)) by reflexivity.
   assert (node_len:Zlength (append_qubit cur d q)=d+1).
   { unfold append_qubit,active_prefix;rewrite Zlength_app,Zlength_sublist by lia;cbn;lia. }
   eapply semax_seq'.
   { eapply semax_pre;[|apply (@null_policy_recurses Espec (snd (depth_flip c heap bits)) recursive_heap report
       bits g s cp bp w d q seen cur children (Zlength xs) i (child_array children xs))];try assumption;try lia.
     rewrite (lend _ node_len);unfold plain_descent_loc,child_fields,child_array,append_qubit.
     rewrite marked,next_len,added_next,len by lia.
     match goal with K:active_prefix d cur=parent |- _=>rewrite K end.
     unfold adjust,q;entailer!;try apply derives_refl.
     }
   Intros tail code;unfold plain_descent_loc;rewrite (lend _ node_len);Intros.
   assert (history:child_evidence_mode false (report w) g root xs parent i code tail).
   { exists seen;split;[split;reflexivity|].
     unfold append_qubit in *;match goal with K:active_prefix d cur=parent |- _=>rewrite <-K end;assumption. }
   assert (prefix:active_prefix d tail=parent).
   { match goal with K:active_prefix d cur=parent |- _=>rewrite <-K end.
     eapply kept_parent;try eassumption;lia. }
   unfold append_qubit;match goal with K:active_prefix d cur=parent |- _=>rewrite K end.
   forward_call (s,parent,q,false);try solve [rewrite plain;entailer!;lia|entailer!;lia|lia].
   unfold child_fields;Intros;rewrite marked;do 4 forward;rewrite upd_Znth_map,decrement_word.
   assert (restored:adjust (-1) (added xs base (i+1)) q=added xs base i).
   { rewrite added_next by lia;apply cancel_child;lia. }
   unfold adjust,q in restored;try fold base in *.
   first [rewrite restored | fold q;fold q in restored;rewrite restored].
   apply semax_if_seq;forward_if.
   + assert (hit:code<>0) by (intro e;subst code;congruence).
     assert (stopped:result i code tail) by (split;[assumption|right;auto]).
     forward;Exists i code tail;unfold regs,plain_scan_regs,memory,child_fields,child_array;rewrite ?next_len,?len;
       entailer!;try apply derives_refl.
   + assert (empty:code=0) by rep_lia;subst code.
     assert (passed:prior_empty_mode false (report w) g root xs parent (i+1)).
     { intros j J;destruct (Z.eq_dec j i) as [->|other];[exists tail;assumption|].
       match goal with K:prior_empty_mode _ _ _ _ _ _ i |- _=>apply K;lia end. }
     assert (signed_inc:Int.min_signed<=i+1<=Int.max_signed) by rep_lia.
     assert (inc:Int.add (Int.repr i) Int.one=Int.repr (i+1)) by apply add_encoded.
     do 5 forward;try solve [entailer!;exact signed_inc].
     forward;try solve [entailer!;exact signed_inc].
     rewrite ?inc;Exists (i+1) tail;unfold regs,plain_scan_regs,memory,child_fields,child_array;
       rewrite ?next_len,?len,added_next by lia;unfold adjust,q;entailer!;try apply derives_refl.
     all: try (rewrite len;apply derives_refl).
     all: rewrite upd_Znth_map;apply derives_refl.
 - Intros i code tail;Exists i code tail;unfold regs,plain_scan_regs;entailer!;try apply derives_refl.
Qed.
End Scan.
