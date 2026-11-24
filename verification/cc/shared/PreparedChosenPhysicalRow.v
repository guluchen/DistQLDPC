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
Require Import PreparedChoiceCall PreparedChooseReturn PreparedSelectedReturn PreparedInteriorExit
 PreparedInitializeScan.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section FromChoice.
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


Let D:=func_tycontext f_dfs prepared_vars (recursive_policy c heap (pool base stride levels) report options) nil.
Let contents:=heap s (active_prefix depth cells).
Let input:choice_input:=fun owner sample=>
 (sample_data sample (Int.repr (-1)) Float.zero Float.zero * data_at_ Tsh (tarray tuint stride) buf)%logic.
Let output:choice_output:=fun owner sample written=>
 (!!(written=xs) && (sample_data sample (Int.repr (-1)) Float.zero Float.zero *
    spare_words buf stride written))%logic.

(* The same heap supplies its odd counter and chooser pointer for the
   callback, then regains both before the first recursive sibling.
   The callback must put precisely the free members of the selected
   odd PCM row into the real buffer, leaving its unused suffix intact. *)
Theorem visit_chosen_physical_row cb odd_count ptr (rest:mpred):
  Int.and options Int.one<>Int.zero -> isptr ptr ->
  (0<=depth<levels)%coqZ -> (0<=stride)%coqZ -> (Zlength xs<=stride)%coqZ ->
  field_compatible0 (tarray tuint ((levels-depth)*stride)) [ArraySubsc stride] buf ->
  let counter:=field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd_count)) s in
  let fn:=choice_field c cb (choose_callback depth odd_count buf (Z.of_nat n) input output) in
  contents=(counter * fn * rest)%logic ->
  semax D (PROPx nil (LOCALx (before_choice c s buf ptr depth options)
    (SEPx [::enabled_memory c s cp w cells root;contents;input (callback_owner c) ptr;loan])))
  choose_search_return
  (existential_ret_assert (fun a=>function_body_ret_assert tint
    (PROP(physical_exit H S G c options row root cells w depth admissible_target a)
     LOCAL(temp ret_temp (Vint (Int.repr (returned_code a))))
     SEP(data_at_ Tsh sample_type ptr;owned_after c heap s cp base cells w depth stride levels a)))).
Proof.
 move=>use live at_level width fits safe counter fn open_heap.
 have extend:tycontext_sub (func_tycontext f_dfs prepared_vars nil nil) D.
 { unfold D,recursive_policy;apply tycontext_sub_Gprog_nil;vm_compute;
   repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil. }
 eapply from_policy_choice.
 - eapply semax_pre;last first.
   + eapply semax_Delta_subsumption;[exact extend|].
     exact:(@select_actual_candidate_row Espec c s buf ptr depth options odd_count cp w cells root cb
       (Z.of_nat n) input output (rest * loan)%logic use owner live).
   + rewrite open_heap;unfold fn,counter,before_choice,choice_loc;cbn [app];entailer!;try cancel;apply derives_refl.
 - Intros written;unfold output at 1;Intros;subst written.
   eapply semax_pre;last first.
   + eapply (@from_selected_candidates Espec D c s buf cp w cells root depth (Zlength xs) options ptr
        [::contents;loan;child_array buf xs;sample_data ptr (Int.repr (-1)) Float.zero Float.zero;
           spare_words buf stride xs]);[exact extend|lia|exact budget|].
     exact:(@recursive_interior_through_return Espec m n r k H S G c heap options s cp base parent row check
       root cells w depth stride levels admissible_target dims size_ok row_ok unique odd prefix fit budget cap
       owner count ready inherited overlap ptr (Int.repr (-1)) Float.zero Float.zero
       ltac:(compute;congruence) at_level width fits safe).
   + rewrite open_heap;unfold fn,counter,chosen_loc;entailer!;try cancel;apply derives_refl.
Qed.
End FromChoice.
