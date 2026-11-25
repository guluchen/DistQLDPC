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
 PreparedInitializeScan PreparedInteriorGuards PreparedDFSRejected PreparedCandidateSlice PreparedInteriorEntry VerifClosedPrefix.
Require Import PreparedRankedChildren PreparedDescentFuel PreparedWritableChoice PreparedCounterJoin OverlapRowSpecs OverlapView.
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
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N).
Let report:=execution_report H S G admissible_target.
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


Let contents:=heap s (active_prefix depth cells).
Let input:choice_input:=fun owner sample=>
 (sample_data sample (Int.repr (-1)) Float.zero Float.zero * data_at_ Tsh (tarray tuint stride) buf)%logic.
Let output:choice_output:=fun owner sample written=>
 (!!(written=xs) && (sample_data sample (Int.repr (-1)) Float.zero Float.zero *
    spare_words buf stride written))%logic.

Variable tables:mpred.
Let before_pick:choice_input:=fun o a=>(tables * input o a)%logic.
Let after_pick:choice_output:=fun o a written=>(tables * output o a written)%logic.
Let blocks:=array32 (blocked root) (blockp (conn c)).
Let pick depth odd:=choose_callback depth odd buf (Z.of_nat n)
 (fun o a=>(blocks * before_pick o a)%logic) (fun o a written=>(blocks * after_pick o a written)%logic).
Let fuel:=Z.to_nat (w-(depth+1)).
Let children:=below_budget fuel heap (pool base stride levels).
Let D:=func_tycontext f_dfs prepared_vars (with_child_heap c heap children report options) nil.

Lemma only_smaller_children node:Zlength node=(depth+1)%coqZ ->
 children w s node=(heap s node * loan)%logic.
Proof.
 move=> len;unfold children,below_budget;rewrite len.
 have left:(0<=w-(depth+1))%coqZ by lia.
 unfold fuel;rewrite (Z2Nat.id _ left) Z.leb_refl;unfold node_heap,pool,loan;rewrite len;reflexivity.
Qed.


Let reported_exit a:Prop:=
 physical_exit H S G c options row root cells w depth admissible_target a /\
 report w geom root (active_prefix depth cells) (returned_code a) (output_trace a).

(* The prefix installed at each actual call is one word longer than the
   caller's prefix. This supplies every child of the raw parent tree,
   including the EMPTY siblings recorded before an early return. *)
Lemma assemble_parent stop code tail:
 scan_outcome_mode update (report w) geom root xs (active_prefix depth cells) stop code tail ->
 report w geom root (active_prefix depth cells) code tail.
Proof.
 move=>scan.
 have parent_len:Zlength (active_prefix depth cells)=depth
   by unfold active_prefix;rewrite Zlength_sublist;lia.
 rewrite prefix in parent_len scan |- *.
 have fuel_succ:Z.to_nat (w-depth)=(Z.to_nat (w-(depth+1))).+1.
 { apply Nat2Z.inj;rewrite Nat2Z.inj_succ !Z2Nat.id;lia. }
 unfold report,execution_report;rewrite parent_len fuel_succ;right.
 eapply from_row with (row:=row) (check:=check) (update:=update) (stop:=stop);try eassumption.
 eapply map_children_of_scan;last exact scan.
 move=>seen q value path child;unfold report,execution_report in child.
 by rewrite Zlength_app parent_len Zlength_cons Zlength_nil in child.
Qed.

Let scan_locals i r:=scan_loc_mode update c s buf depth (Zlength xs) i r options.
Let start:=[::enabled_memory c s cp w cells root;heap s (active_prefix depth cells);loan;child_array buf xs].
Let stop a:=[::enabled_memory c s cp w (output_trace a) (restored_snapshot a);
    heap s (active_prefix depth cells);loan;child_array buf xs].
Let owned a:=owned_after c heap s cp base cells w depth stride levels a.

Theorem report_after_rollback ptr klass t1 t2:
 (Int.signed klass<0)%coqZ -> (0<=depth<levels)%coqZ -> (0<=stride)%coqZ -> (Zlength xs<=stride)%coqZ ->
 field_compatible0 (tarray tuint ((levels-depth)*stride)) [ArraySubsc stride] buf ->
 semax D (PROPx nil (LOCALx (scan_locals 0%coqZ 0%coqZ ++ [::lvar _sample sample_type ptr])
    (SEPx (start++[::sample_data ptr klass t1 t2;spare_words buf stride xs])))) search_finish
 (existential_ret_assert (fun a=>function_body_ret_assert tint
   (PROP(reported_exit a) LOCAL(temp ret_temp (Vint (Int.repr (returned_code a))))
    SEP(data_at_ Tsh sample_type ptr;owned a)))).
Proof.
 move=>disabled at_depth wide fits comp.
 have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by move:dims;change Int.max_signed with 2147483647%coqZ;
   change Int.max_unsigned with 4294967295%coqZ;lia.
 have [range _]:=@emitted_range_and_availability n row _ F unsigned size_ok (@available_in_view n root).
 have positive:(0<Zlength (blocked root)<=Int.max_signed)%coqZ by rewrite size_ok.
 apply:(@finish_after_siblings scan_exit Espec D _ ptr klass t1 t2 returned_code reported_exit owned _ disabled).
 - unfold D,with_child_heap;apply tycontext_sub_Gprog_nil;vm_compute;
   repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - have loop:semax D (PROPx nil (LOCALx (scan_locals 0%coqZ 0%coqZ) (SEPx start)))
     (Ssequence search_children undo_children) (normal_ret_assert (EX a:scan_exit,
      PROPx [::reported_exit a] (LOCALx (scan_locals (next_index a) (returned_code a)) (SEPx (stop a))))).
   { eapply semax_post';last exact:(@restore_siblings_at_weight Espec c heap children loan report options s cp buf xs root cells w depth
        update fit budget cap count positive range owner ready only_smaller_children).
     Intros i value st path.
     match goal with h:scan_outcome_mode _ _ _ _ _ _ _ _ _ |- _ => pose proof h as scan end.
     have raw:=assemble_parent scan.
     have len:Zlength (active_prefix depth cells)=depth by unfold active_prefix;rewrite Zlength_sublist;lia.
     have correct:=@recursive_reports_by_remaining_depth m n r k H S G admissible_target orth det shape (proj2 dims)
        (Z.to_nat (w-Zlength (active_prefix depth cells))) w geom root (active_prefix depth cells) value path
        ltac:(rewrite Z2Nat.id;lia) raw.
     Exists (make_exit i value st path);unfold reported_exit,physical_exit,scan_locals,start,stop,scan_loc_mode;
       cbn [next_index returned_code restored_snapshot output_trace];entailer!;try apply derives_refl;intuition. }
   pose saved:=[::lvar _sample sample_type ptr].
   pose extra:=[::sample_data ptr klass t1 t2;spare_words buf stride xs].
   have stable:closed_wrt_modvars (Ssequence search_children undo_children) (LOCALx saved (SEPx extra))
       by unfold saved,extra,search_children,undo_children;auto 100 with closed.
   eapply semax_post';last exact:(@keep_caller_locals_for_answer scan_exit Espec VerifDetected.CompSpecs D
     (Ssequence search_children undo_children) nil (scan_locals 0%coqZ 0%coqZ) start saved extra
     (fun a=>[::reported_exit a]) (fun a=>scan_locals (next_index a) (returned_code a)) stop stable loop).
   Intros a;Exists a;unfold scan_locals,scan_loc_mode,stop,extra,saved,owned,owned_after;cbn [app].
   entailer!;try cancel.
   rewrite sepcon_assoc (sepcon_comm loan).
   exact:(@release_after_descendants base stride levels depth xs at_depth wide fits comp).
Qed.

Theorem choose_with_smaller_children cb odd_count ptr (rest:mpred):
  Int.and options Int.one<>Int.zero -> isptr ptr ->
  (0<=depth<levels)%coqZ -> (0<=stride)%coqZ -> (Zlength xs<=stride)%coqZ ->
  field_compatible0 (tarray tuint ((levels-depth)*stride)) [ArraySubsc stride] buf ->
  let counter:=field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd_count)) s in
  let fn:=choice_field c cb (pick depth odd_count) in
  contents=(counter * fn * tables * rest)%logic ->
  semax D (PROPx nil (LOCALx (before_choice c s buf ptr depth options)
    (SEPx [::enabled_memory c s cp w cells root;contents;input (callback_owner c) ptr;loan])))
  choose_search_return
  (existential_ret_assert (fun a=>function_body_ret_assert tint
    (PROP(reported_exit a)
     LOCAL(temp ret_temp (Vint (Int.repr (returned_code a))))
     SEP(data_at_ Tsh sample_type ptr;owned_after c heap s cp base cells w depth stride levels a)))).
Proof.
 move=>use live at_level width fits safe counter fn open_heap.
 have extend:tycontext_sub (func_tycontext f_dfs prepared_vars nil nil) D.
 { unfold D,with_child_heap;apply tycontext_sub_Gprog_nil;vm_compute;
   repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil. }
 eapply from_policy_choice.
 - eapply semax_pre;last first.
   + eapply semax_Delta_subsumption;[exact extend|].
     exact:(@select_with_live_blocks Espec c s buf ptr depth options odd_count cp w cells root cb
       (Z.of_nat n) before_pick after_pick (rest * loan)%logic use owner live).
   + rewrite open_heap;unfold fn,pick,blocks,before_pick,counter,before_choice,choice_loc;cbn [app];entailer!;try cancel;apply derives_refl.
 - Intros written;unfold after_pick,output;Intros;subst written.
   eapply semax_pre;last first.
   + eapply (@from_selected_candidates Espec D c s buf cp w cells root depth (Zlength xs) options ptr
        [::contents;loan;child_array buf xs;sample_data ptr (Int.repr (-1)) Float.zero Float.zero;
           spare_words buf stride xs]);[exact extend|lia|exact budget|].
     exact:(@report_after_rollback ptr (Int.repr (-1)) Float.zero Float.zero
       ltac:(compute;congruence) at_level width fits safe).
   + rewrite open_heap;unfold fn,pick,blocks,counter,chosen_loc;entailer!;try cancel;apply derives_refl.
Qed.

(* This theorem starts at the first instruction of the actual DFS body.
   The return contract is the one used recursively. The same level weight,
   odd count, callback field and candidate pointers are borrowed and
   reassembled as control passes through the guards and the C++ chooser. *)
Theorem entry_from_child_execution cb odd_count ptr bp nodes budgets mask (rest:mpred):
  Int.and options Int.one<>Int.zero -> isptr ptr -> isptr base ->
  (0<odd_count<=Int.max_signed)%coqZ -> (w-depth<Zlength budgets)%coqZ ->
  (Int.and options (Int.repr 2)<>Int.zero -> Int64.and (Int64.add nodes Int64.one) mask<>Int64.zero) ->
  (Int.and options (Int.repr 8)<>Int.zero -> Z.testbit (w-depth-odd_count) 0=false) ->
  (0<=depth<levels)%coqZ -> (0<=stride<=Int.max_signed)%coqZ -> (Zlength xs<=stride)%coqZ ->
  field_compatible0 (tarray tuint ((levels-depth)*stride)) [ArraySubsc stride] buf ->
  let counter:=field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd_count)) s in
  let fn:=choice_field c cb (pick depth odd_count) in
  let tallies:=tally_cells s bp nodes budgets in
  let visits:=visit_storage s bp (Zlength budgets) in
  let timer:=mask_field s mask in let pointers:=candidate_fields s base stride in
  let row_space:=data_at_ Tsh (tarray tuint stride) buf in
  contents=(counter * fn * tables * (pointers * visits * timer * rest))%logic ->
  semax D (PROPx nil (LOCALx (guard_loc s (nested_policy (nested c)) depth options ptr)
    (SEPx [::enabled_memory c s cp w cells root;counter;fn;tables;tallies;timer;rest;pointers;
       data_at_ Tsh sample_type ptr;row_space;loan]))) (fn_body f_dfs)
  (existential_ret_assert (fun a=>function_body_ret_assert tint
    (PROP(reported_exit a)
     LOCAL(temp ret_temp (Vint (Int.repr (returned_code a))))
     SEP(data_at_ Tsh sample_type ptr;owned_after c heap s cp base cells w depth stride levels a)))).
Proof.
 move=>use live base_ok odd_fit room between even at_level width fits safe counter fn tallies visits timer pointers row_space open_heap.
 pose (bumped:=tally_cells s bp (Int64.add nodes Int64.one) (bump budgets (w-depth))).
 have extend:tycontext_sub (func_tycontext f_dfs prepared_vars nil nil) D.
 { unfold D,with_child_heap;apply tycontext_sub_Gprog_nil;vm_compute;
   repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil. }
 pose (untouched:=(rest_of_level c s cp cells root * fn * tables * rest * pointers *
          data_at_ Tsh sample_type ptr * row_space * loan)%logic).
 pose (during:=(enabled_memory c s cp w cells root * counter * fn * tables * bumped * timer * rest * row_space * loan)%logic).
 eapply guards_then_search.
 - eapply semax_pre;last first.
   + eapply semax_Delta_subsumption;[exact extend|].
     assert (can_enter:(1<=depth<=w-2)%coqZ) by lia.
     exact (@enter_interior_on_live_flags Espec s (nested_policy (nested c)) bp w depth odd_count nodes budgets
       options mask ptr untouched can_enter budget odd_fit room between even).
   + rewrite share_weight_during_setup;unfold untouched,tallies,tally_cells,visit_fields,timer,counter,guard_loc;
     entailer!;try cancel;apply derives_refl.
 - eapply semax_pre;last first.
   + eapply (@nonterminal_entry_from_stack Espec D c s base stride depth options ptr during);
       [exact extend|lia|lia|exact base_ok|].
     eapply semax_pre;last first.
     * assert (wide:(0<=stride)%coqZ) by lia.
       exact (@choose_with_smaller_children cb odd_count ptr (pointers * visits * timer * rest)%logic use live
         at_level wide fits safe open_heap).
     * rewrite open_heap;unfold during,input,before_choice,choice_loc,pointers;cbn [app];entailer!;cancel.
       unfold bumped,visits,row_space;apply sepcon_derives;[apply return_bumped_tallies;lia|apply derives_refl].
   + unfold during,untouched;rewrite share_weight_during_setup;unfold bumped,tally_cells,visit_fields,
        timer,counter,pointers,guard_loc;entailer!;try cancel;apply derives_refl.
Qed.
End FromChoice.
