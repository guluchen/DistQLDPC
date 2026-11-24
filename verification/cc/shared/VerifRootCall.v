(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifChildVisit VerifOverlapDispatch OverlapColumnState
 OverlapView OverlapSharedBlocks OverlapChildState ChildColumn VerifEnabledVisit EnabledCall SeedLoopModel.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Definition free_seed_body:=match root_visit with Ssequence _ (Ssequence _ (Sifthenelse _ yes _))=>yes|_=>Sskip end.
Definition root_bracket:statement:=ltac:(
 let xs:=eval cbv beta iota zeta delta [firstn skipn free_seed_body root_visit sequence_items app] in
   (firstn 8 (skipn 7 (sequence_items free_seed_body))) in
 lazymatch xs with ?a::?b::?c::?d::?e::?f::?g::?h::nil =>
  exact (Ssequence a (Ssequence b (Ssequence c (Ssequence d (Ssequence e (Ssequence f (Ssequence g h))))))) end).
Definition root_call_loc c s q i count:=
 [temp _s s;temp _q (Vint (Int.repr q));temp _policy (nested_policy (nested c));
  temp _i (Vint (Int.repr i));temp _count (Vint (Int.repr count))].
Definition live_links c:=(weak_valid_pointer (nested_policy (nested c)) * weak_valid_pointer (callback_addr c))%logic.
Definition root_trace c st q (path tail:list int) :=
 Zlength tail=Zlength path /\ Znth 0 tail=Int.repr q /\
 (child_outcome (nested c) (blocked st) q<>0 -> returned_trace (nested c) (blocked st) q tail).
Theorem root_call_under_overlap {Espec:OracleKind} c s cp w q initial path i count (frame:mpred) :
 1<=w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked initial) -> q<=Int.max_signed ->
 isptr (nested_policy (nested c)) -> isptr (callback_addr c) -> is_pointer_or_null (callback_owner c) ->
 let g:=geometry c in let entered:=after_column g q true initial in
 column_bounds g q initial -> admissible g q true initial -> admissible g q false entered ->
 semax (func_tycontext f_cc_run_level Vprog (RootG c) [])
 (PROPx [] (LOCALx (root_call_loc c s q i count)
  (SEPx [enabled_memory c s cp w path initial;active_support (nested c) s (Some q);live_links c;frame])))
 root_bracket
 (normal_ret_assert (EX final:snapshot,EX tail:list int,
   PROPx [same_search final initial;root_trace c entered q path tail;0<=child_outcome (nested c) (blocked entered) q<=3]
   (LOCALx (temp _result (Vint (Int.repr (child_outcome (nested c) (blocked entered) q)))::root_call_loc c s q i count)
    (SEPx [enabled_memory c s cp w tail final;active_support (nested c) s (Some q);live_links c;frame])))).
Proof.
 intros cap room key signed pp fp own g entered bounds add_ok off_ok.
 pose proof (@entered_block_count g q initial bounds) as extent;fold entered in extent.
 unfold root_bracket,root_call_loc,enabled_memory,pointers,callback_fields,live_links;abbreviate_semax;Intros.
 apply semax_if_seq;forward_if;try solve [congruence|contradiction].
 { destruct (nested_policy (nested c));try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
 do 2 forward;try solve [entailer!;destruct (callback_addr c);try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]].
 apply semax_if_seq;forward_if;try solve [destruct (callback_addr c);contradiction || discriminate].
 do 2 forward;forward_call (initial,q,true);try solve [entailer!].
 unfold level_links;Intros;do 2 forward;rewrite upd_Znth_map.
 set (chosen:=upd_Znth 0 path (Int.repr q)).
 assert (len:Zlength chosen=Zlength path) by (unfold chosen;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (head:Znth 0 chosen=Int.repr q) by (unfold chosen;rewrite upd_Znth_same by lia;reflexivity).
 forward_call (s,cp,w,q,entered,chosen);try solve [entailer!;rep_lia].
 { unfold enabled_memory,pointers,callback_fields,level_links,chosen;rewrite ?upd_Znth_Zlength by lia.
   unfold entered,g,Frame;cancel;instantiate (Frame:=[frame;weak_valid_pointer (nested_policy (nested c));weak_valid_pointer (callback_addr c)]);
   cbn [fold_right_sepcon];cancel. }
 Intros vret;destruct vret as [child tail];cbn [fst snd] in *;forward.
 assert (exit_ok:admissible g q false child) by
  (eapply same_admissible;[|exact off_ok];match goal with K:same_search child entered |- _=>destruct K;split;congruence end).
 assert (restored:same_search (after_column g q false child) initial) by (apply after_child_column;assumption).
 unfold enabled_memory,pointers,callback_fields;Intros;apply semax_if_seq;forward_if;try solve [congruence|contradiction].
 { destruct (nested_policy (nested c));try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
 do 2 forward;try solve [entailer!;destruct (callback_addr c);try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]].
 forward_if;try solve [destruct (callback_addr c);contradiction || discriminate].
 do 2 forward;forward_call (child,q,false);try solve [entailer!].
 Exists (after_column g q false child) tail;unfold root_trace,root_call_loc,enabled_memory,pointers,callback_fields,live_links.
 entailer!;try apply derives_refl.
 all:match goal with null_policy: _=nullval |- _ =>
   change (nested_policy (nested c)=nullval) in null_policy;rewrite null_policy in pp;contradiction end.
Qed.
