(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VerifDetected VerifClosedPrefix
 PreparedVisitAccounting PreparedInteriorGuards.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The owner of a recursive node remembers the extent of by_budget. Its
   counter contents are updated by every descendant and can wrap around. *)
Definition tally_cells s bp nodes (budgets:list int64):=
 (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _by_budget] bp s *
  data_at Tsh (tarray tulong (Zlength budgets)) (map Vlong budgets) bp)%logic.
Definition visit_storage s bp len:mpred:=
 EX nodes:int64,EX budgets:list int64,!!(Zlength budgets=len) && tally_cells s bp nodes budgets.

Lemma return_tally_cells s bp n bs len:
 Zlength bs=len -> tally_cells s bp n bs |-- visit_storage s bp len.
Proof. intro extent;unfold visit_storage;Exists n bs;entailer!. Qed.

Lemma return_bumped_tallies s bp n bs i:
 0<=i<Zlength bs ->
 tally_cells s bp (Int64.add n Int64.one) (bump bs i) |-- visit_storage s bp (Zlength bs).
Proof. intro idx;apply return_tally_cells;unfold bump;rewrite upd_Znth_Zlength by lia;reflexivity. Qed.

(* The same persistent heap is available on both sides of the compiled
   counter update; no caller may assume its old counter values survive. *)
Theorem count_visit_with_descendants {Espec:OracleKind} s p depth bits bp w len (frame:mpred):
 0<=depth<=w -> w<=Int.max_signed -> w-depth<len ->
 let weight:=field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s in
 let ownership:=[weight;visit_storage s bp len;frame] in
 let at_visit:=PROPx [] (LOCALx (node_arguments s p depth bits) (SEPx ownership)) in
 semax (func_tycontext f_dfs PreparedSeedDispatch.prepared_vars [] []) at_visit visit_counts (normal_ret_assert at_visit).
Proof.
 intros deep width room weight ownership at_visit;unfold at_visit,ownership,visit_storage at 1;Intros nodes budgets.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact (@record_visit Espec s p depth bits bp w nodes budgets frame deep width ltac:(lia))].
     unfold node_arguments,accounting,tally_cells,weight;entailer!;try cancel;apply derives_refl. }
 unfold at_visit,ownership,node_arguments;unfold visit_storage;Exists (Int64.add nodes Int64.one) (bump budgets (w-depth)).
 assert (length:Zlength (bump budgets (w-depth))=len) by (unfold bump;rewrite upd_Znth_Zlength by lia;assumption).
 unfold accounting,tally_cells,weight;entailer!;try cancel;apply derives_refl.
Qed.
