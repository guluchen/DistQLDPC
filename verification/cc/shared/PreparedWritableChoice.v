(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit EnabledCall
 OverlapView OverlapSharedBlocks OverlapColumnState SiblingCounters ClightSelect PreparedSeedDispatch
 PreparedChoiceCall PreparedSampling PreparedOwnerFields PreparedSampleOwnerReturn PreparedCallerLocals
 PreparedInitializeScan PreparedSelectedReturn.
Require Import PreparedChooseReturn OverlapColumnState OverlapRowSpecs.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* blk_ is shared by the C level and the C++ policy object. Lend exactly
   its existing array to the call. P and Q carry the row tables, syndrome,
   stamps and candidate slice; their writable parts may change. *)
Theorem select_with_live_blocks {Espec:OracleKind} c s child ptr depth bits odd cp w path st cb n P Q
 (frame:mpred):
 Int.and bits Int.one<>Int.zero -> is_pointer_or_null (callback_owner c) -> isptr ptr ->
 let counter:=field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s in
 let owner:=callback_owner c in let blocks:=array32 (blocked st) (blockp (conn c)) in
 let input:choice_input:=fun o a=>(blocks * P o a)%logic in
 let output:choice_output:=fun o a xs=>(blocks * Q o a xs)%logic in
 let spec:=choose_callback depth odd child n input output in let fn:=choice_field c cb spec in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx (before_choice c s child ptr depth bits)
   (SEPx [counter;P owner ptr;(enabled_memory c s cp w path st * fn)%logic;frame])))
 choose_count (normal_ret_assert (EX xs:list Z, PROPx [Zlength xs<=Int.max_signed;NoDup xs;in_array n xs]
  (LOCALx (chosen_loc c s child depth (Zlength xs) bits ptr)
    (SEPx [counter;child_array child xs;Q owner ptr xs;(enabled_memory c s cp w path st * fn)%logic;frame])))).
Proof.
 intros use own live counter owner blocks input output spec fn.
 pose (policy:=chooser_policy (nested_policy (nested c)) owner cb spec).
 pose (rest:=(level_links s cp (blockp (conn c)) w path *
     view_without_blocks owner (conn c) (geometry c) st * saved_overlap c * frame)%logic).
 pose (loc:=choice_loc s (nested_policy (nested c)) ptr depth bits).
 pose (save:=[temp _children child]).
 assert (stable:closed_wrt_modvars choose_count (LOCALx save (SEPx [])))
    by (unfold choose_count,save;auto 100 with closed).
 pose proof (@keep_caller_locals_for_answer (list Z) Espec VerifDetected.CompSpecs
  (func_tycontext f_dfs prepared_vars [] []) choose_count [] loc
  [counter;policy;input owner ptr;rest] save [] (fun xs=>[Zlength xs<=Int.max_signed;NoDup xs;in_array n xs])
  (fun xs=>temp _count (Vint (Int.repr (Zlength xs)))::loc)
  (fun xs=>[counter;policy;child_array child xs;output owner ptr xs;rest]) stable
  (@choose_from_owner Espec s (nested_policy (nested c)) owner cb ptr depth odd bits child n input output rest use own live)) as select_row.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact select_row];unfold before_choice,fn;rewrite lend_choice_field.
     unfold dormant_overlap,cols;rewrite split_view_blocks;
     unfold save,loc,policy,rest,choice_loc,input,output,blocks,owner;cbn [app];entailer!;try cancel;apply derives_refl. }
 Intros xs;Exists xs;unfold chosen_loc,fn;rewrite lend_choice_field.
 unfold dormant_overlap,cols;rewrite split_view_blocks;
     unfold save,loc,policy,rest,choice_loc,input,output,blocks,owner;cbn [app];entailer!;try cancel;apply derives_refl.
Qed.
