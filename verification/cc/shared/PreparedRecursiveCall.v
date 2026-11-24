(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected VerifChildVisit ClightSelect OverlapView OverlapColumnState OverlapSharedBlocks
 ChildColumn OverlapChildState VerifOverlapDispatch VerifEnabledVisit EnabledCall UniversalRootSearch SeedLoopModel PreparedSeedDispatch PreparedRootStages.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition selected_root_arm:=match visit_root with
 Ssequence _ (Ssequence _ (Sifthenelse _ yes _))=>yes|_=>Sskip end.
Definition root_bracket:statement:=ltac:(
 let xs:=eval cbv beta iota zeta delta [firstn skipn selected_root_arm visit_root sequence_items app] in
    (firstn 6 (skipn 7 (sequence_items selected_root_arm))) in
 lazymatch xs with ?a::?b::?c::?d::?e::?f::nil=>exact (Ssequence a (Ssequence b (Ssequence c (Ssequence d (Ssequence e f))))) end).
Definition witness_status (r:Z):=r=1 \/ r=3.
Definition root_report:=layout->snapshot->Z->Z->list int->Prop.
Definition root_flip c (mask:int):ident*funspec:=
 DECLARE _flip WITH s:val,q:Z,enter:bool
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(0<=q<Int.max_signed;q+1<Zlength (column_offsets (geometry c))) PARAMS(s;nested_policy (nested c);Vint (Int.repr q);Vint mask)
 SEP(active_support (nested c) s (if enter then None else Some q))
 POST [tvoid] PROP() RETURN() SEP(active_support (nested c) s (if enter then Some q else None)).
(* A real deadline may expire at any visit, including after a sibling was
   exhausted. Only FOUND and INCONSISTENT require a completed witness trace. *)
Definition root_dfs_spec c (report:root_report) (mask:int):ident*funspec:=
 DECLARE _dfs WITH geom:layout,s:val,cp:val,w:Z,q:Z,st:snapshot,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(1<=w<=Int.max_signed;w<=Zlength path;0<=q<Zlength (blocked st);Znth 0 path=Int.repr q)
 PARAMS(s;nested_policy (nested c);Vint Int.one;Vint mask)
 SEP(enabled_memory (with_rows c geom) s cp w path st;active_support (nested c) s (Some q))
 POST [tint] EX final:snapshot,EX tail:list int,EX r:Z,
 PROP(same_search final st;0<=r<=3;Zlength tail=Zlength path;Znth 0 tail=Int.repr q;
   report geom st q r tail;witness_status r -> returned_trace (nested c) (blocked st) q tail)
 RETURN(Vint (Int.repr r)) SEP(enabled_memory (with_rows c geom) s cp w tail final;active_support (nested c) s (Some q)).
Definition RecG c report bits:=prepared_calls (snd (root_flip c bits)) (snd (root_dfs_spec c report bits)).
Definition visit_loc c s q i count bits:=
 [temp _s s;temp _q (Vint (Int.repr q));temp _policy (nested_policy (nested c));temp _i (Vint (Int.repr i));
  temp _count (Vint (Int.repr count));temp _options (Vint bits)].

Theorem recursive_root_with_overlap {Espec:OracleKind} c report s cp w q st path i count bits (frame:mpred):
 1<=w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked st) -> q<=Int.max_signed ->
 Int.and bits (Int.repr 16)<>Int.zero -> is_pointer_or_null (callback_owner c) ->
 let g:=geometry c in let entered:=after_column g q true st in
 column_bounds g q st -> admissible g q true st -> admissible g q false entered ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (RecG c report bits) [])
 (PROPx [] (LOCALx (visit_loc c s q i count bits)
  (SEPx [enabled_memory c s cp w path st;active_support (nested c) s (Some q);frame])))
 root_bracket
 (normal_ret_assert (EX final:snapshot,EX tail:list int,EX r:Z,
  PROPx [same_search final st;0<=r<=3;Zlength tail=Zlength path;Znth 0 tail=Int.repr q;
    report g entered q r tail;witness_status r -> returned_trace (nested c) (blocked entered) q tail]
  (LOCALx (temp _result (Vint (Int.repr r))::visit_loc c s q i count bits)
   (SEPx [enabled_memory c s cp w tail final;active_support (nested c) s (Some q);frame])))).
Proof.
 intros bounds room key sign overlap owner g entered column on off.
 pose proof (entered_block_count g q st column) as width;fold entered in width.
 unfold root_bracket,visit_loc,enabled_memory,pointers,callback_fields;abbreviate_semax;Intros.
 apply semax_if_seq;forward_if;try solve [congruence|contradiction].
 do 2 (forward;try solve [entailer!]);forward_call (st,q,true);try solve [entailer!].
 unfold level_links;Intros;do 2 forward;rewrite upd_Znth_map.
 set (chosen:=upd_Znth 0 path (Int.repr q)).
 assert (len:Zlength chosen=Zlength path) by (unfold chosen;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (head:Znth 0 chosen=Int.repr q) by (unfold chosen;rewrite upd_Znth_same by lia;reflexivity).
 forward_call (g,s,cp,w,q,entered,chosen);try solve [entailer!;rep_lia].
 { unfold enabled_memory,pointers,callback_fields,level_links,chosen,with_rows;cbn [conn callback_owner callback_addr geometry nested].
   rewrite ?upd_Znth_Zlength by lia;unfold entered,g,Frame;cancel;instantiate (Frame:=[frame]);cbn [fold_right_sepcon];cancel.
   unfold cols;cbn [geometry callback_owner conn];apply derives_refl. }
 Intros vret;destruct vret as [[child tail] r];cbn [fst snd] in *;forward.
 assert (exit_ok:admissible g q false child) by
  (eapply same_admissible;[|exact off];match goal with H:same_search child entered |- _=>destruct H;split;congruence end).
 assert (back:same_search (after_column g q false child) st) by (apply after_child_column;assumption).
 unfold enabled_memory,pointers,callback_fields,with_rows;cbn [conn callback_owner callback_addr geometry nested];Intros.
 forward_if;try solve [congruence|contradiction];do 2 (forward;try solve [entailer!]);forward_call (child,q,false);try solve [entailer!].
 Exists (after_column g q false child) tail r;unfold visit_loc,enabled_memory,pointers,callback_fields.
 entailer!;try cancel;unfold cols,g;cbn [geometry callback_owner conn];apply derives_refl.
Qed.
