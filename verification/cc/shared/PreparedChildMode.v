(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall UniversalRootSearch
 OverlapView OverlapChildState OverlapColumnState OverlapSharedBlocks EnabledLoopFacts
 PreparedSeedDispatch PreparedRootStages PreparedRecursiveCall PreparedDepthSpec PreparedBudgetContract
 PreparedChildCall PreparedChildPlain.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition entered_mode (update:bool) g q (parent:snapshot):=
 if update then after_column g q true parent else parent.
Definition mode_ready (update:bool) g q (parent:snapshot):Prop:=
 if update then check_child g q parent else q+1<Zlength (column_offsets g).

Lemma ready_for_selected update g root xs i st:
 0<=i<Zlength xs -> same_search st (sibling_state root xs i) ->
 mode_ready update g (Znth i xs) (sibling_state root xs (i+1)) ->
 mode_ready update g (Znth i xs) (selected st (Znth i xs)).
Proof. intros pos same;destruct update;cbn [mode_ready];auto;apply checked_from_iterator;assumption. Qed.

Lemma ready_for_flip update g q parent:
 mode_ready update g q parent -> q+1<Zlength (column_offsets g).
Proof. destruct update;cbn [mode_ready];auto;intros [_ [push _]];exact (proj1 (proj2 push)). Qed.

Lemma entered_mode_congruence update g q a b:
 same_search a b -> same_search (entered_mode update g q a) (entered_mode update g q b).
Proof. destruct update;cbn [entered_mode];auto;apply physical_child_congruence. Qed.

(* The cached overlap flag changes the state seen by this child. Its
   recursive call always receives the actual weight stored in the level. *)
Theorem recursive_bracket_at_weight {Espec:OracleKind} (flip:funspec) c heap report bits
 s cp w depth q parent path children count index frame update:
 1<=depth<w-2 -> w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked parent) ->
 is_pointer_or_null (callback_owner c) -> mode_ready update (geometry c) q parent ->
 let g:=geometry c in let entered:=entered_mode update g q parent in
 let prefix:=append_qubit path depth q in let locs:=descent_loc c s depth q children count index bits update in
 semax (func_tycontext f_dfs prepared_vars (prepared_calls flip (snd (budget_dfs c heap report bits))) [])
 (PROPx [] (LOCALx locs (SEPx [enabled_memory c s cp w path parent;heap w s prefix;frame])))
 child_bracket (normal_ret_assert (EX final:snapshot,EX tail:list int,EX r:Z,
 PROPx [same_search final parent;0<=r<=3;Zlength tail=Zlength path;active_prefix (depth+1) tail=prefix;
  report w g entered prefix r tail;witness_status r->returned_trace (nested c) (blocked entered) q tail]
 (LOCALx (temp _result (Vint (Int.repr r))::locs) (SEPx [enabled_memory c s cp w tail final;heap w s prefix;frame])))).
Proof.
 intros dep cap len idx own ok;destruct update;cbn [mode_ready entered_mode] in *.
 - destruct ok as [cols [push pop]];apply visit_with_actual_weight;assumption.
 - apply plain_with_actual_weight;assumption.
Qed.
