(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected VerifChildVisit ClightSelect EnabledCall VerifEnabledVisit VerifOverlapDispatch
 OverlapColumnState OverlapView OverlapChildState OverlapSharedBlocks ChildColumn UniversalRootSearch
 PreparedSeedDispatch PreparedRootStages PreparedRecursiveCall PreparedDepthSpec.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition search_children:statement:=ltac:(native_fragment (counts_on _i) f_dfs).
Definition child_items:=match search_children with Ssequence _ (Sloop body _)=>sequence_items body|_=>[] end.
Fixpoint from_overlap (xs:list statement) : list statement:=
 match xs with []=>[]|h::t=>match h with Sifthenelse (Etempvar id _) _ _=>
 if Pos.eqb id _update_overlap then xs else from_overlap t | _=>from_overlap t end end.
Definition child_bracket:statement:=ltac:(
 let items:=eval cbv beta iota zeta delta [List.firstn from_overlap child_items search_children sequence_items app Pos.eqb _update_overlap] in
   (List.firstn 6 (from_overlap child_items)) in
 lazymatch items with ?a::?b::?c::?d::?e::?f::nil=>exact (Ssequence a (Ssequence b (Ssequence c (Ssequence d (Ssequence e f))))) end).
Definition descent_loc c s depth q children n index bits (update:bool):=
 [temp _s s;temp _policy (nested_policy (nested c));temp _size (Vint (Int.repr depth));temp _options (Vint bits);
  temp _a (Vint (Int.repr q));temp _update_overlap (Vint (if update then Int.one else Int.zero));
  temp _children children;temp _count (Vint (Int.repr n));temp _i (Vint (Int.repr index));temp _excluded (Vint (Int.repr index))].
Definition append_qubit path depth q:=active_prefix depth path++[Int.repr q].
Lemma stored_prefix path depth q:0<=depth<Zlength path ->
 active_prefix (depth+1) (upd_Znth depth path (Int.repr q))=append_qubit path depth q.
Proof.
 intros bound;unfold active_prefix,append_qubit,active_prefix.
 assert (length_ok:Zlength (upd_Znth depth path (Int.repr q))=Zlength path) by (rewrite upd_Znth_Zlength by lia;reflexivity).
 rewrite (sublist_split 0 depth (depth+1)) by lia;rewrite (sublist_one depth) by lia.
 rewrite upd_Znth_same,sublist_upd_Znth_l by lia;reflexivity.
Qed.

Theorem visit_with_declared_flip {Espec:OracleKind} (flip:funspec) c heap report bits s cp w depth q parent path children count index frame:
 1<=depth<w-2 -> w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked parent) ->
 is_pointer_or_null (callback_owner c) ->
 let g:=geometry c in let entered:=after_column g q true parent in
 column_bounds g q parent -> admissible g q true parent -> admissible g q false entered ->
 let prefix:=append_qubit path depth q in let locs:=descent_loc c s depth q children count index bits true in
 semax (func_tycontext f_dfs prepared_vars (prepared_calls flip (snd (depth_dfs c heap report bits))) [])
 (PROPx [] (LOCALx locs (SEPx [enabled_memory c s cp w path parent;heap s prefix;frame])))
 child_bracket (normal_ret_assert (EX final:snapshot,EX tail:list int,EX r:Z,
  PROPx [same_search final parent;0<=r<=3;Zlength tail=Zlength path;active_prefix (depth+1) tail=prefix;
   report g entered prefix r tail;witness_status r->returned_trace (nested c) (blocked entered) q tail]
  (LOCALx (temp _result (Vint (Int.repr r))::locs) (SEPx [enabled_memory c s cp w tail final;heap s prefix;frame])))).
Proof.
 intros deep cap room key owner g entered legal add_ok remove_ok prefix locs.
 pose proof (entered_block_count g q parent legal) as width;fold entered in width.
 unfold locs,descent_loc,child_bracket,enabled_memory,pointers,callback_fields.
 abbreviate_semax;Intros.
 apply semax_if_seq;forward_if;try solve [discriminate|congruence].
 do 2 forward;forward_call (parent,q,true);try solve [entailer!].
 unfold level_links;Intros;do 2 forward;rewrite upd_Znth_map.
 set (chosen:=upd_Znth depth path (Int.repr q)).
 assert (len:Zlength chosen=Zlength path) by (unfold chosen;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (save:active_prefix (depth+1) chosen=prefix) by (apply stored_prefix;lia).
 assert (mark:Znth depth chosen=Int.repr q) by (unfold chosen;rewrite upd_Znth_same by lia;reflexivity).
 forward;apply semax_if_seq;forward_if.
 { exfalso;match goal with K:Int.repr depth=Int.sub _ _ |- _=>
   unfold Int.sub in K;rewrite !Int.unsigned_repr in K by rep_lia;
   apply (f_equal Int.signed) in K;rewrite !Int.signed_repr in K by rep_lia;lia end. }
 forward_call (g,s,cp,w,depth+1,q,entered,chosen);
 try solve [entailer!;replace (depth+1-1) with depth by lia;assumption |
   entailer!;rep_lia | entailer!;f_equal;unfold Int.add;rewrite Int.unsigned_repr by rep_lia;reflexivity].
 { unfold enabled_memory,pointers,callback_fields,level_links,with_rows;cbn [nested geometry callback_owner callback_addr conn].
   rewrite save;unfold chosen;rewrite ?upd_Znth_Zlength by lia;unfold entered,g,Frame;cancel.
   instantiate (Frame:=[frame]);cbn [fold_right_sepcon];cancel;unfold cols;cbn [geometry callback_owner conn];apply derives_refl. }
 { replace (depth+1-1) with depth by lia;exact mark. }
 Intros vret;destruct vret as [[child tail] r];cbn [fst snd] in *.
 assert (out_ok:admissible g q false child) by
   (eapply same_admissible;[|exact remove_ok];match goal with K:same_search child entered |- _=>destruct K;split;congruence end).
 assert (back:same_search (after_column g q false child) parent) by (apply after_child_column;assumption).
 unfold enabled_memory,pointers,callback_fields,with_rows;cbn [nested geometry callback_owner callback_addr conn];Intros.
 forward_if;try solve [discriminate|congruence];do 2 forward;forward_call (child,q,false);try solve [entailer!].
 Exists (after_column g q false child) tail r;unfold enabled_memory,pointers,callback_fields;rewrite save in *.
 entailer!;try cancel;unfold cols,g;cbn [geometry callback_owner conn];apply derives_refl.
Qed.

Definition visit_with_active_column {Espec:OracleKind} (c:policy_state) (heap:node_storage) (report:node_report) (bits:int):=
 @visit_with_declared_flip Espec (snd (depth_flip c heap bits)) c heap report bits.
