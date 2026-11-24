(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver
  VerifDetected VerifClosedPrefix PreparedSeedDispatch PreparedDeadline.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition visit_counts:=match fn_body f_dfs with
 | Ssequence nodes (Ssequence budget _)=>Ssequence nodes budget | _=>Sskip end.
Definition accounting s bp w nodes (budget:list int64):=
 (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _by_budget] bp s *
  field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
  data_at Tsh (tarray tulong (Zlength budget)) (map Vlong budget) bp)%logic.
Definition node_arguments s p depth bits:=[temp _s s;temp _policy p;temp _size (Vint (Int.repr depth));temp _options (Vint bits)].

Theorem record_visit {Espec:OracleKind} s p depth bits bp w nodes budget (frame:mpred):
 0<=depth<=w -> w<=Int.max_signed -> w-depth<Zlength budget ->
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx (node_arguments s p depth bits) (SEPx [accounting s bp w nodes budget;frame])))
 visit_counts (normal_ret_assert (PROPx [] (LOCALx (node_arguments s p depth bits)
 (SEPx [accounting s bp w (Int64.add nodes Int64.one) (bump budget (w-depth));frame])))).
Proof.
 intros room cap index;unfold visit_counts,accounting,node_arguments;cbn [fn_body f_dfs];abbreviate_semax;reassoc_seq;Intros.
 do 8 (forward;try solve [entailer!]).
 unfold bump;rewrite upd_Znth_Zlength by lia;entailer!;rewrite upd_Znth_map;apply derives_refl.
Qed.
