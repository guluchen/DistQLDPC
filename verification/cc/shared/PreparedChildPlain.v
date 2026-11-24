(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected VerifChildVisit EnabledCall VerifEnabledVisit OverlapColumnState OverlapChildState
 OverlapSharedBlocks UniversalRootSearch PreparedSeedDispatch PreparedRootStages PreparedRecursiveCall PreparedDepthSpec PreparedChildCall.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* An installed overlap callback stays in the level state even where the
   cached update flag is false, in particular at w - depth = 3. *)
Theorem recursive_child_without_update {Espec:OracleKind} c heap report bits s cp w depth q parent path children count index frame:
 1<=depth<w-2 -> w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked parent) ->
 let g:=geometry c in let prefix:=append_qubit path depth q in
 let locs:=descent_loc c s depth q children count index bits false in
 semax (func_tycontext f_dfs prepared_vars (depth_context c heap report bits) [])
 (PROPx [] (LOCALx locs (SEPx [enabled_memory c s cp w path parent;heap s prefix;frame])))
 child_bracket (normal_ret_assert (EX final:snapshot,EX tail:list int,EX r:Z,
 PROPx [same_search final parent;0<=r<=3;Zlength tail=Zlength path;active_prefix (depth+1) tail=prefix;
  report g parent prefix r tail;witness_status r->returned_trace (nested c) (blocked parent) q tail]
 (LOCALx (temp _result (Vint (Int.repr r))::locs) (SEPx [enabled_memory c s cp w tail final;heap s prefix;frame])))).
Proof.
 intros deep cap room key g prefix locs;unfold locs,descent_loc,child_bracket,enabled_memory,level_links;abbreviate_semax;Intros.
 apply semax_if_seq;forward_if;try solve [contradiction|congruence|discriminate].
 do 2 forward;rewrite upd_Znth_map.
 set (chosen:=upd_Znth depth path (Int.repr q)).
 assert (len:Zlength chosen=Zlength path) by (unfold chosen;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (save:active_prefix (depth+1) chosen=prefix) by (apply stored_prefix;lia).
 assert (mark:Znth depth chosen=Int.repr q) by (unfold chosen;rewrite upd_Znth_same by lia;reflexivity).
 forward;apply semax_if_seq;forward_if.
 { exfalso;match goal with K:Int.repr depth=Int.sub _ _ |- _=>unfold Int.sub in K;rewrite !Int.unsigned_repr in K by rep_lia;
   apply (f_equal Int.signed) in K;rewrite !Int.signed_repr in K by rep_lia;lia end. }
 forward_call (g,s,cp,w,depth+1,q,parent,chosen);
 try solve [entailer!;rep_lia | entailer!;f_equal;unfold Int.add;rewrite Int.unsigned_repr by rep_lia;reflexivity].
 { unfold enabled_memory,level_links,with_rows;cbn [nested geometry callback_owner callback_addr conn].
   rewrite save;unfold chosen;rewrite ?upd_Znth_Zlength by lia;unfold g,Frame;cancel;
   instantiate (Frame:=[frame]);cbn [fold_right_sepcon];cancel;try apply derives_refl. }
 { replace (depth+1-1) with depth by lia;exact mark. }
 Intros vret;destruct vret as [[child tail] r];cbn [fst snd] in *.
 forward_if;try solve [contradiction|congruence|discriminate];forward.
 Exists child tail r;rewrite save in *;unfold enabled_memory,with_rows,g;cbn [nested geometry callback_owner callback_addr conn];entailer!;try apply derives_refl.
Qed.
