(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch VerifDetected VerifChildVisit VerifEnabledSiblings
 EnabledCall EnabledLoopFacts OverlapChildState OverlapColumnState OverlapTargetProgress ChildColumn
 IndexRowBridge RowTally SiblingCounters PreparedChildMode PreparedRecursiveCall PreparedSeedDispatch
 PreparedDepthSpec PreparedRootStages PreparedArenaRoot PreparedArenaContext PreparedCandidateArena
 PreparedBudgetArena PreparedBudgetContract PreparedChildCall PreparedSiblingScan PreparedSiblingRestore
 PreparedMatrixPath PreparedPCMLeafVisit PreparedChildPrefix PreparedResidualIndex PreparedOverlapDepth
 PreparedInteriorReport PreparedPCMInterior PreparedVerdictExit PreparedReturnTrace PreparedSampling
 PreparedNativeCallees PreparedArenaContext PreparedCallerLocals.
Require Import PreparedDescentFuel.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section ReturnFromInterior.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (c:policy_state) (heap:node_storage) (options:Integers.int) (s cp base:Values.val)
 (parent row:seq 'I_n) (check:'I_m) (root:snapshot) (cells:seq Integers.int) (w depth stride levels:Z).
Variable admissible_target:seq Integers.int -> 'cV['F_2]_n -> Prop.
Let report:=recursive_report H S G admissible_target.
Let geom:=geometry c.
Let P:=[set b:'I_n | b \in parent].
Let F:=@available_now n root.
Let xs:=map Int.unsigned (free_row (blocked root) (map (@address n) row)).
Let update:=enabled_at options w depth.
Let buf:=row_pointer base stride depth.
Let loan:=remaining_arena base stride levels (depth+1)%coqZ.
Hypotheses (dims:(0<Z.of_nat n<=Int.max_signed)%coqZ) (size_ok:Zlength (blocked root)=Z.of_nat n)
 (row_ok:forall q:'I_n,H check q!=0 -> q \in row) (unique:uniq row)
 (odd:(H*m indicator P) check 0!=0) (prefix:active_prefix depth cells=literal_path parent)
 (fit:(1<=depth<w-2)%coqZ) (budget:(w<=Int.max_signed)%coqZ) (cap:(w<=Zlength cells)%coqZ)
 (owner:is_pointer_or_null (callback_owner c)) (count:(Zlength xs<=Int.max_signed)%coqZ)
 (ready:forall i,(0<=i<Zlength xs)%coqZ -> mode_ready update geom (Znth i xs) (sibling_state root xs (i+1)%coqZ)).
Hypothesis inherited:forall x (a:'I_n),admissible_target (literal_path parent) x ->
 admissible_target (literal_path parent++[::Int.repr (Z.of_nat a)]) x.
Hypothesis overlap:forall x,admissible_target (literal_path parent) x -> minimum H G x -> P \subset support x -> support x :\: P \subset F ->
 let wanted:=physical_member (support x :\: P) in update=true ->
 forall i,(0<=i<Zlength xs)%coqZ -> wanted (Znth i xs)=true ->
 let st:=sibling_state root xs (i+1)%coqZ in column_bounds geom (Znth i xs) st /\
  forall a,wanted a=true -> a<>Znth i xs -> ~List.In a (new_blocks geom (Znth i xs) st).

Record scan_exit:Type:=make_exit {
 next_index:Z; returned_code:Z; restored_snapshot:snapshot; output_trace:seq Integers.int
}.
Definition physical_exit a:Prop:=
 recursive_result H S G admissible_target w root (active_prefix depth cells) (returned_code a) (output_trace a) /\
 (0<=returned_code a<=3)%coqZ /\ keeps_witness_mode update c root xs (next_index a) (returned_code a) (output_trace a) /\
 same_search (restored_snapshot a) root /\ Zlength (output_trace a)=Zlength cells /\
 active_prefix depth (output_trace a)=active_prefix depth cells.
Definition owned_after a:=
 (enabled_memory c s cp w (output_trace a) (restored_snapshot a) *
    heap s (active_prefix depth cells) * remaining_arena base stride levels depth)%logic.
Let live i r:=scan_loc_mode update c s buf depth (Zlength xs) i r options.
Let start:=[::enabled_memory c s cp w cells root;heap s (active_prefix depth cells);loan;child_array buf xs].
Let stop a:=[::enabled_memory c s cp w (output_trace a) (restored_snapshot a);
    heap s (active_prefix depth cells);loan;child_array buf xs].

(* Return from the actual general child loop with the restored parent
   heap. Ancestors retain their candidate rows. At this common exit the
   sample class is negative, so there is no callback invocation. *)
Section ChildCalls.
Variable children:budget_heap.
Hypothesis at_child:forall node,Zlength node=(depth+1)%coqZ ->
 children w s node=(heap s node * loan)%logic.

Let D:=func_tycontext f_dfs prepared_vars (with_child_heap c heap children report options) nil.
Theorem recursive_interior_through_return_with_children ptr klass t1 t2:
 (Int.signed klass<0)%coqZ -> (0<=depth<levels)%coqZ -> (0<=stride)%coqZ -> (Zlength xs<=stride)%coqZ ->
 field_compatible0 (tarray tuint ((levels-depth)*stride)) [ArraySubsc stride] buf ->
 semax D (PROPx nil (LOCALx (live 0%coqZ 0%coqZ ++ [::lvar _sample sample_type ptr])
    (SEPx (start++[::sample_data ptr klass t1 t2;spare_words buf stride xs])))) search_finish
 (existential_ret_assert (fun a=>function_body_ret_assert tint
   (PROP(physical_exit a) LOCAL(temp ret_temp (Vint (Int.repr (returned_code a))))
    SEP(data_at_ Tsh sample_type ptr;owned_after a)))).
Proof.
 move=>disabled at_depth wide fits comp.
 apply:(@finish_after_siblings scan_exit Espec D _ ptr klass t1 t2 returned_code physical_exit owned_after _ disabled).
 - unfold D,with_child_heap;apply tycontext_sub_Gprog_nil;vm_compute;
   repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - have loop:semax D (PROPx nil (LOCALx (live 0%coqZ 0%coqZ) (SEPx start)))
     (Ssequence search_children undo_children) (normal_ret_assert (EX a:scan_exit,
      PROPx [::physical_exit a] (LOCALx (live (next_index a) (returned_code a)) (SEPx (stop a))))).
   { eapply semax_post';last exact:(@recursive_loop_at_physical_weight_with_children Espec m n r k H S G c heap options s cp base parent row
       check root cells w depth stride levels admissible_target dims size_ok row_ok unique odd prefix fit budget cap owner count ready
       inherited overlap children at_child).
     Intros i value st path;Exists (make_exit i value st path);unfold physical_exit,live,start,stop,scan_loc_mode;
     cbn [next_index returned_code restored_snapshot output_trace];entailer!;try apply derives_refl;intuition. }
   pose saved:=[::lvar _sample sample_type ptr].
   pose extra:=[::sample_data ptr klass t1 t2;spare_words buf stride xs].
   have stable:closed_wrt_modvars (Ssequence search_children undo_children) (LOCALx saved (SEPx extra))
       by unfold saved,extra,search_children,undo_children;auto 100 with closed.
   eapply semax_post';last exact:(@keep_caller_locals_for_answer scan_exit Espec VerifDetected.CompSpecs D
     (Ssequence search_children undo_children) nil (live 0%coqZ 0%coqZ) start saved extra
     (fun a=>[::physical_exit a]) (fun a=>live (next_index a) (returned_code a)) stop stable loop).
   Intros a;Exists a;unfold live,scan_loc_mode,stop,extra,saved,owned_after;cbn [app].
   entailer!;try cancel.
   rewrite sepcon_assoc (sepcon_comm loan).
   exact:(@release_after_descendants base stride levels depth xs at_depth wide fits comp).
Qed.
End ChildCalls.

Let D:=func_tycontext f_dfs prepared_vars (recursive_policy c heap (pool base stride levels) report options) nil.
Theorem recursive_interior_through_return ptr klass t1 t2:
 (Int.signed klass<0)%coqZ -> (0<=depth<levels)%coqZ -> (0<=stride)%coqZ -> (Zlength xs<=stride)%coqZ ->
 field_compatible0 (tarray tuint ((levels-depth)*stride)) [ArraySubsc stride] buf ->
 semax D (PROPx nil (LOCALx (live 0%coqZ 0%coqZ ++ [::lvar _sample sample_type ptr])
    (SEPx (start++[::sample_data ptr klass t1 t2;spare_words buf stride xs])))) search_finish
 (existential_ret_assert (fun a=>function_body_ret_assert tint
   (PROP(physical_exit a) LOCAL(temp ret_temp (Vint (Int.repr (returned_code a))))
    SEP(data_at_ Tsh sample_type ptr;owned_after a)))).
Proof.
 refine (@recursive_interior_through_return_with_children (fun _=>node_heap heap (pool base stride levels)) _ ptr klass t1 t2).
 intros node length;unfold node_heap,pool,loan;rewrite length;reflexivity.
Qed.
End ReturnFromInterior.
