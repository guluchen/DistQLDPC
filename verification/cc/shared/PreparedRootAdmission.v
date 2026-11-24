(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifChildVisit SeedLoopModel VerifRootCall EnabledCall
 SiblingCounters OverlapSharedBlocks OverlapView OverlapColumnState OverlapChildState VerifEnabledSiblings ChildColumn EnabledLoopFacts VerifRootAdmission PreparedRootStages PreparedSeedDispatch PreparedRecursiveCall.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Theorem prepared_root_admission {Espec:OracleKind} c report s cp w q st path i count calls bits (frame:mpred):
 1<=w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked st) -> q<=Int.max_signed ->
 Int.and bits (Int.repr 16)<>Int.zero -> is_pointer_or_null (callback_owner c) ->
 (available st q=true -> seed_checked c st q) ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (RecG c report bits) [])
 (PROPx [] (LOCALx (temp _result (Vint Int.zero)::visit_loc c s q i count bits)
   (SEPx [enabled_memory c s cp w path st;active_support (nested c) s None;seed_counter s calls;frame])))
 visit_root
 (normal_ret_assert (EX final:snapshot,EX tail:list int,EX r:Z,
  PROPx [same_search final st;0<=r<=3;Zlength tail=Zlength path;
   available st q=false -> r=0 /\ tail=path;
   available st q=true -> let entered:=after_column (geometry c) q true (selected st q) in
     report (geometry c) entered q r tail /\ Znth 0 tail=Int.repr q /\
      (witness_status r -> returned_trace (nested c) (blocked entered) q tail)]
  (LOCALx (temp _result (Vint (Int.repr r))::visit_loc c s q i count bits)
   (SEPx [enabled_memory c s cp w tail final;active_support (nested c) s None;
    seed_counter s (if available st q then Int64.add calls Int64.one else calls);frame])))).
Proof.
 intros cap room key signed enabled own check.
 unfold visit_root,visit_loc;abbreviate_semax;reassoc_seq.
 rewrite child_owner_view by lia;unfold child_fields,seed_counter;Intros;do 2 forward;forward_if.
 2:{ assert (skip:available st q=false) by (unfold available;apply Int.eq_false;assumption).
     forward;Exists st path 0;unfold visit_loc,seed_counter;rewrite skip,child_owner_view by lia.
     unfold child_fields,same_search;entailer!;try apply derives_refl;intuition congruence. }
 assert (admit:available st q=true) by (unfold available;rewrite H,Int.eq_true;reflexivity).
 specialize (check admit);destruct check as [bounds [plus minus]].
 pose proof (proj1 plus) as signed_key;pose proof (proj1 (proj2 plus)) as csr_slot.
 pose proof (Int.unsigned_range_2 (Znth q (blocked st))) as machine.
 do 6 forward;rewrite upd_Znth_map;change (Int.repr 1) with Int.one.
 forward_call (s,q,true);try solve [entailer!]. reassoc_seq;unfold_abbrev'.
 match goal with |- semax _ _ ?body _ =>
  let suffix:=lazymatch body with Ssequence _ (Ssequence _ (Ssequence _
        (Ssequence _ (Ssequence _ (Ssequence _ ?rest))))) =>rest end in
  apply (semax_unfold_seq (Ssequence root_bracket suffix) body eq_refl) end.
 eapply semax_seq'.
 { assert (marker: Zlength (blocked (selected st q))=Zlength (blocked st)) by
   (unfold selected,counters;cbn [blocked];unfold adjust;rewrite upd_Znth_Zlength by lia;reflexivity).
   eapply semax_pre;[|apply (@recursive_root_with_overlap Espec c report s cp w q (selected st q) path i count bits
      (seed_counter s (Int64.add calls Int64.one) * frame)%logic)];try eassumption;try lia.
   unfold visit_loc,seed_counter;rewrite child_owner_view by lia;unfold child_fields;rewrite marker.
   unfold selected,counters,view_without_blocks;cbn [blocked slack tight tight_extra forbidden].
   unfold adjust;entailer!;try apply derives_refl. }
 Intros final tail r;unfold visit_loc.
 assert (back:same_search final (selected st q)) by assumption.
 assert (width:Zlength (blocked final)=Zlength (blocked st)) by
  (rewrite (proj2 back);unfold selected,counters;cbn [blocked];unfold adjust;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (undo:adjust (-1) (blocked final) q=blocked st) by (rewrite (proj2 back);apply cancel_child;lia).
 forward_call (s,q,false);try solve [entailer!];rewrite child_owner_view by lia;unfold child_fields;Intros;do 4 forward.
 rewrite upd_Znth_map,decrement_word;Exists (released final q) tail r.
 rewrite admit;unfold visit_loc,seed_counter.
 rewrite child_owner_view by (unfold released,counters;cbn [blocked];rewrite undo;lia).
 unfold child_fields,released,counters,view_without_blocks;cbn [slack blocked tight tight_extra forbidden].
 unfold adjust in *;rewrite ?upd_Znth_Zlength by lia;entailer!;try cancel.
 all:first [solve [unfold same_search in *;cbn [slack blocked selected counters] in *;intuition congruence]|apply derives_refl].
Qed.
