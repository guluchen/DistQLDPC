(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver VerifDetected VerifChildVisit
 VerifSiblingRollback SiblingCounters EnabledCall EnabledLoopFacts OverlapColumnState
 OverlapChildState PreparedSeedDispatch PreparedRootStages PreparedRecursiveCall
 PreparedDepthSpec PreparedBudgetContract PreparedChildCall PreparedChildMode PreparedSiblingScan
 VerifLookup PreparedPairDispatch PreparedPlainDescent PreparedPlainSiblings PreparedWitnessRegister
 PreparedIndexWitnessCall PreparedArenaContext PreparedNativeCallees flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition visit_calls (flip dfs:funspec):funspecs:=
 ltac:(let fs:=constr:([(_flip,flip);(_dfs,dfs);detected_spec;lookup_spec]) in with_library prog fs).

Section Scan.
Context {Espec:OracleKind}.
Variables (c:policy_state) (heap:node_storage) (dfs:funspec) (loan:mpred)
 (report:budget_report) (valid_witness:Z->list int->Prop) (bits:int) (s cp bp children:val)
 (xs:list Z) (root:snapshot) (path:list int) (w d:Z) (saved:int).
Let g:=geometry c.
Let base:=blocked root.
Let parent:=active_prefix d path.
Let regs:=plain_scan_regs s children d (Zlength xs).
Let D:=func_tycontext f_dfs prepared_vars (visit_calls (snd (depth_flip c heap bits)) dfs) nil.
Let memory i cur prior:=(child_fields s cp bp w (added xs base i) cur * child_array children xs *
                   heap s parent * loan * witness_register s prior)%logic.
Let result i code tail:=scan_outcome_mode false (report w) g root xs parent i code tail.
Let registered code written tail:=witness_at_limit w saved code written tail /\
                       (witness_status code -> valid_witness (Int.signed written) tail).
Hypotheses (plain:nested_policy (nested c)=nullval) (depth:1<=d<=w-2) (cap:w<=Int.max_signed)
 (room:w<=Zlength path) (count:Zlength xs<=Int.max_signed)
 (limit:Zlength base<=Int.max_signed) (range:in_array (Zlength base) xs)
 (columns:Zlength base<Zlength (column_offsets g)).

(* A direct recursive call and the optimized two-move lookup have the
   same effect on their caller. Both must return the word actually stored
   in _witness_size. An EMPTY visit preserves the previous word. *)
Hypothesis visit:forall i cur,0<=i<Zlength xs -> Zlength cur=Zlength path -> active_prefix d cur=parent ->
 let q:=Znth i xs in let seen:=sibling_state root xs (i+1) in let node:=append_qubit cur d q in
 let locs:=plain_descent_loc s d q children (Zlength xs) i bits in
 let state tail written:=(child_fields s cp bp w (blocked seen) tail * heap s node *
      witness_register s written * child_array children xs * loan)%logic in
 semax D (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [state cur saved]))) child_bracket
 (normal_ret_assert (EX tail:list int,EX code:Z,EX written:int,PROPx
   [0<=code<=3;Zlength tail=Zlength path;active_prefix (d+1) tail=node;
    report w g seen node code tail;registered code written tail]
   (LOCALx (temp _result (Vint (Int.repr code))::locs) (SEPx [state tail written])))).

Theorem scan_preserves_witness_register :
 semax D (PROPx nil (LOCALx (regs 0 0 bits) (SEPx [memory 0 path saved]))) search_children
 (normal_ret_assert (EX i:Z,EX code:Z,EX tail:list int,EX written:int,
    PROPx [result i code tail;0<=code<=3;Zlength tail=Zlength path;active_prefix d tail=parent;
           registered code written tail]
      (LOCALx (regs i code bits) (SEPx [memory i tail written])))).
Proof.
 unfold g in columns. unfold D,search_children,regs,plain_scan_regs;abbreviate_semax;forward.
 forward_loop (EX i:Z,EX cur:list int,
    PROPx [0<=i<=Zlength xs;prior_empty_mode false (report w) g root xs parent i;
           Zlength cur=Zlength path;active_prefix d cur=parent]
    (LOCALx (temp _i (Vint (Int.repr i))::regs i 0 bits) (SEPx [memory i cur saved])))%assert
 break: (EX i:Z,EX code:Z,EX tail:list int,EX written:int,
    PROPx [result i code tail;0<=code<=3;Zlength tail=Zlength path;active_prefix d tail=parent;registered code written tail]
      (LOCALx (regs i code bits) (SEPx [memory i tail written])))%assert.
 - Exists 0 path;unfold regs,plain_scan_regs,parent;entailer!;try apply derives_refl.
   unfold prior_empty_mode;intros;lia.
 - Intros i cur;unfold regs,plain_scan_regs;forward_if.
   2:{ forward;Exists i 0 cur saved;unfold result,regs,plain_scan_regs,scan_outcome_mode,registered,witness_at_limit,witness_status;entailer!;intuition lia. }
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
   eapply semax_seq'.
   { eapply semax_pre;[|apply (visit i cur pos)];try assumption.
     cbn zeta;unfold plain_descent_loc,child_fields,child_array,append_qubit;fold seen.
     rewrite ?marked,?next_len,added_next,?len by lia.
     match goal with K:active_prefix d cur=parent |- _=>rewrite K end.
     unfold adjust,q;entailer!;try apply derives_refl.
     }
   Intros tail code written;fold seen;unfold plain_descent_loc;Intros.
   assert (history:child_evidence_mode false (report w) g root xs parent i code tail).
   { exists seen;split;[split;reflexivity|].
     unfold append_qubit in *;match goal with K:active_prefix d cur=parent |- _=>rewrite <-K end;assumption. }
   assert (prefix:active_prefix d tail=parent).
   { match goal with K:active_prefix d cur=parent |- _=>rewrite <-K end.
     eapply kept_parent;try eassumption;lia. }
   unfold append_qubit;match goal with K:active_prefix d cur=parent |- _=>rewrite K end.
   forward_call (s,parent,q,false);try solve [rewrite plain;entailer!;lia|entailer!;lia|lia].
   { unfold Frame;instantiate (Frame:=[child_fields s cp bp w (blocked seen) tail;witness_register s written;
        child_array children xs;loan]);cbn [fold_right_sepcon];unfold q;entailer!;cancel. }
   unfold child_fields;Intros;rewrite marked;do 4 forward;rewrite upd_Znth_map,decrement_word.
   assert (restored:adjust (-1) (added xs base (i+1)) q=added xs base i).
   { rewrite added_next by lia;apply cancel_child;lia. }
   unfold adjust,q in restored;try fold base in *.
   first [rewrite restored | fold q;fold q in restored;rewrite restored].
   apply semax_if_seq;forward_if.
   + assert (hit:code<>0) by (intro e;subst code;congruence).
     assert (stopped:result i code tail) by (split;[assumption|right;auto]).
     forward;Exists i code tail written;unfold regs,plain_scan_regs,memory,child_fields,child_array;rewrite ?next_len,?len;
       entailer!;try apply derives_refl.
   + assert (empty:code=0) by rep_lia;subst code.
     assert (unchanged:written=saved) by
       (match goal with h:registered 0 written tail |- _ => exact ((proj1 (proj1 h)) (or_introl eq_refl)) end).
     subst written.
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
     all: try (rewrite upd_Znth_map;apply derives_refl).
     all: try solve [apply andp_left2;apply derives_refl].
Qed.
End Scan.
