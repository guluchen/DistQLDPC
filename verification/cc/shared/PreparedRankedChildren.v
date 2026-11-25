(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedFinalLookup PreparedCutReports PreparedMatrixResponse NativeFlipPayload LeafAPI PCMLeafAPI VerifClosesBody VerifOneLeft VerifFlipBody PackedDetector.
Require Import PreparedBudgetContract PreparedDescentFuel PreparedArenaContext PreparedSeedDispatch PreparedRootStages.
Require Import PreparedPackingVerdict NativePackingScan ChargeBound.
Require Import PreparedLeafVisit PreparedLeafAtPath PreparedPairEvent PreparedChildCall.
Require flag_level_ast.
Require Import LeafMatrix MinimumPrefix LevelSearch PreparedMatrixPath PreparedChildPrefix PreparedPCMLeafVisit
 PreparedInteriorReport PreparedWeightCases PreparedCSSTerminal PreparedTerminalPoll PreparedObservedWitness
 PreparedSiblingScan PreparedChildMode PreparedDepthSpec OverlapColumnState OverlapChildState OverlapTargetProgress
 PreparedResidualIndex PreparedRecursiveCall EnabledLoopFacts IndexRowBridge RowTally ChildColumn.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

(* The sibling scan records the prefix and the snapshot of each actual
   child, including previously exhausted siblings before a successful one. *)
Lemma map_children_of_scan (A B:node_report) update g root xs parent stop result tail :
 (forall seen q code path,A g seen (parent++[::q]) code path -> B g seen (parent++[::q]) code path) ->
 scan_outcome_mode update A g root xs parent stop result tail ->
 scan_outcome_mode update B g root xs parent stop result tail.
Proof.
 move=> child [earlier last].
 have transfer j code path:child_evidence_mode update A g root xs parent j code path ->
    child_evidence_mode update B g root xs parent j code path.
 { move=>[seen [state reported]];exists seen;split=> //;exact:child reported. }
 split.
 - move=>j in_range;have [path ok]:=earlier j in_range;exists path;exact:transfer ok.
 - case:last=>[empty|[within [nonzero live]]];first by left.
   right;split=> //;split=> //;exact:transfer live.
Qed.

Section Tree.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (eligible:seq Integers.int->'cV['F_2]_n->Prop).
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N)
 (fits:(Z.of_nat n<=Int.max_signed)%coqZ).
Let target:=recursive_result H S G eligible.

(* The native callback can return zero before writing any candidates.
   Record the packing scan or charge inequality that caused that return. *)
Inductive bound_cut (w:Z) (st:snapshot):seq Integers.int->Prop :=
| rejected (c:nat) (extra:'M['F_2]_(c,n)) (inc:'I_c->seq 'I_n) ids remaining
    (order:seq 'I_c) stamp marks marked charges capacity:
 let oddrows:=support (extra*m indicator [set a:'I_n | a \in ids]) in
 let incidence:=neighbors inc in
 w=Z.of_nat (size ids+remaining)%N -> uniq ids ->
 (forall x:'cV['F_2]_n,H*m x=0 -> extra*m x=0) ->
 (forall j q,extra j q!=0 -> q \in inc j) ->
 (forall j,(Zlength (encoded inc j)<=Int.max_unsigned)%coqZ) ->
 @tags_for n stamp marks marked -> {subset order <= oddrows} ->
 (forall q,q \in @available_now n st -> (\sum_(j in oddrows) load incidence charges j q<=capacity)%N) ->
 (cpu_scan inc (blocked st) stamp remaining order marks 0=false \/
   (remaining*capacity<\sum_(j in oddrows) charges j)%N) ->
 bound_cut w st (literal_path ids).

Lemma bound_cut_is_empty w st words tail:bound_cut w st words -> target w st words 0%coqZ tail.
Proof.
 case=>c extra inc ids remaining order stamp marks marked charges cap oddrows incidence -> distinct
   consequence covers width tags scanned feasible cut.
 exact:(@failing_pack_or_charge_returns_empty m n r k c H S G extra inc ids st order remaining eligible
    distinct fits consequence covers stamp marks marked charges cap tail width tags scanned feasible cut).
Qed.

(* These cases contain local evidence only. In particular, EMPTY at a
   complete prefix is checked from the actual matrix and the return word. *)
Inductive local_exit (w:Z) (st:snapshot):seq Integers.int->Z->seq Integers.int->Prop :=
| packing_or_charge words path:bound_cut w st words -> local_exit w st words 0%coqZ path
| interrupted words path:local_exit w st words 2%coqZ path
| found words path:stored_css_prefix H S w path -> local_exit w st words 1%coqZ path
| shorter words path len:(0<len<w)%coqZ -> stored_css_prefix H S len path -> local_exit w st words 3%coqZ path
| terminal ids path event:uniq ids -> w=Z.of_nat (size ids) ->
 (0<w<=Zlength path)%coqZ -> active_prefix w path=literal_path ids ->
 local_exit w st (literal_path ids) (Int.signed (@result_word m r n H S ids event)) path
| final_lookup ids cells rowkey packed z:
 let d:=Z.of_nat (size ids) in let P:=[set q:'I_n | q \in ids] in
 w=(d+1)%coqZ -> uniq ids -> ids!=[::] -> (d<Zlength cells)%coqZ ->
 active_prefix d cells=literal_path ids -> pcm_response H G rowkey (indicator P) packed ->
 odd_count packed<>0%coqZ -> leaf_answer (pcm_completion H G P (@available_now n st)) (Z.of_nat n) z ->
 local_exit w st (literal_path ids) (final_pick z) (last_path d z cells)
| parity_exit ids cells rowkey packed:
 let d:=Z.of_nat (size ids) in
 uniq ids -> pcm_response H G rowkey (vector_on 0 ids) packed ->
 (forall q:'I_n,odd #|support (col q H)|) -> Z.testbit (w-d-odd_count packed)%coqZ 0=true ->
 local_exit w st (literal_path ids) 0%coqZ cells
| closed_exit ids cells rowkey packed:
 let d:=Z.of_nat (size ids) in
 uniq ids -> pcm_response H G rowkey (vector_on 0 ids) packed ->
 (0<d<w)%coqZ -> (w<=Zlength cells)%coqZ -> active_prefix d cells=literal_path ids ->
 odd_count packed=0%coqZ -> local_exit w st (literal_path ids)
    (if packed_detects (parities (words_at packed)) then 3 else 0)%coqZ cells.

Lemma local_sound w st words code path:local_exit w st words code path -> target w st words code path.
Proof.
 case=>[words0 path0 cut|words0 path0|words0 path0 ok|words0 path0 len small ok|ids path0 event uniq_ids -> room prefix
  |ids cells rowkey packed z d P -> unique nonempty room prefix physical open_node observed
  |ids cells rowkey packed d unique physical columns bit
  |ids cells rowkey packed d unique physical depth room prefix no_odd].
 - exact:bound_cut_is_empty cut.
 - split;[intros;lia|split;discriminate].
 - split;[intros;lia|split;[auto|discriminate]].
 - split;[intros;lia|split;[discriminate|intros;exists len;auto]].
 - exact:(@terminal_at_actual_budget m n r k H S G eligible ids st fits uniq_ids orth det shape event path0 room prefix).
 - exact:(@final_lookup_proves_recursive_verdict m n r k H S G eligible ids st rowkey packed cells z
       orth det shape fits unique nonempty room prefix physical open_node observed).
 - unfold target;eapply native_parity_cut_is_empty;eassumption.
 - unfold target;eapply early_closed_has_valid_shorter_witness;eassumption.
Qed.

Inductive odd_scan (children:node_report) (g:layout) (st:snapshot) :seq Integers.int->Z->seq Integers.int->Prop :=
| from_row parent row (check:'I_m) update stop code tail:
 let P:=[set q:'I_n | q \in parent] in let F:=@available_now n st in
 let xs:=map Int.unsigned (free_row (blocked st) (map (@address n) row)) in
 Zlength (blocked st)=Z.of_nat n ->
 (forall q:'I_n,H check q!=0 -> q \in row) -> uniq row -> (H*m indicator P) check 0!=0 ->
 (forall x (a:'I_n),eligible (literal_path parent) x ->
    eligible (literal_path parent++[::Int.repr (Z.of_nat a)]) x) ->
 (forall x,eligible (literal_path parent) x -> minimum H G x -> P \subset support x -> support x :\: P \subset F ->
  let wanted:=physical_member (support x :\: P) in update=true ->
  forall i,(0<=i<Zlength xs)%coqZ -> wanted (Znth i xs)=true ->
  let seen:=sibling_state st xs (i+1)%coqZ in column_bounds g (Znth i xs) seen /\
  forall q,wanted q=true -> q<>Znth i xs -> ~List.In q (new_blocks g (Znth i xs) seen)) ->
 scan_outcome_mode update children g st xs (literal_path parent) stop code tail ->
 odd_scan children g st (literal_path parent) code tail.

Fixpoint reports_at (remaining:nat) (w:Z):node_report :=
 fun g st words code tail=>local_exit w st words code tail \/
 match remaining with
 | O=>False
 | remaining'.+1=>odd_scan (reports_at remaining' w) g st words code tail
 end.

(* A two-move node flips its first qubit inline. Convert the observation
   of that actual flip and final lookup into the one-move child required
   by the same induction as an ordinary recursive C call. *)
Theorem pair_observation_supplies_child ids st packed rowkey depth q cells code tail geom :
 let node:=append_qubit cells depth q in let P:=[set a:'I_n | a \in ids] in
 uniq ids -> (1<=depth)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 (depth+1)%coqZ=Z.of_nat (size ids) -> node=literal_path ids ->
 pcm_response H G rowkey (indicator P) packed ->
 pair_observation packed (pcm_completion H G P (@available_now n st)) (Z.of_nat n) depth q cells code tail ->
 reports_at 1 (depth+2)%coqZ geom st node code tail.
Proof.
 move=>node P unique depth_ok room count trace physical [event [observed [-> ->]]].
 pose next:=upd_Znth depth cells (Int.repr q).
 have stored:active_prefix (Z.of_nat (size ids)) next=literal_path ids
   by rewrite -count /next stored_prefix //;lia.
 have extent:Zlength next=Zlength cells by rewrite /next upd_Znth_Zlength //;lia.
 have nonempty:ids!=[::] by apply/eqP=>empty;rewrite empty /= in count;lia.
 rewrite trace;left;case:event observed=>[z|].
 - move=>[open_node answer];cbn [pair_path pair_code].
   fold next;rewrite count;eapply final_lookup;try eassumption;try lia.
 - move=>closed;cbn [pair_path pair_code];fold next.
   eapply closed_exit with (rowkey:=rowkey);try eassumption;try lia.
   rewrite (path_is_its_indicator unique);exact physical.
Qed.

Theorem recursive_reports_by_remaining_depth remaining w g st words code tail :
 Z.of_nat remaining=(w-Zlength words)%coqZ ->
 reports_at remaining w g st words code tail -> target w st words code tail.
Proof.
 elim:remaining g st words code tail=>[|remaining IH] g st words code tail amount.
 - cbn [reports_at];case=>[local|//];exact:local_sound local.
 - cbn [reports_at];case=>[local|scanned];first exact:local_sound local.
   case:scanned amount=>parent row check update stop value path P F xs width covers unique odd inherited overlap scan amount.
   apply:(@interior_scan_preserves_weight_and_witness m n r k H S G eligible st parent row check g update
        fits width covers unique odd inherited overlap w stop value path).
   eapply map_children_of_scan;last exact scan.
   move=>seen q returned trace child;apply:(IH g seen (literal_path parent++[::q]) returned trace _ child).
   rewrite Zlength_app Zlength_cons Zlength_nil;lia.
Qed.
(* Use the weight and the prefix actually supplied at the C call site. *)
Definition execution_report:budget_report:=fun w g st prefix code tail=>
 reports_at (Z.to_nat (w-Zlength prefix)) w g st prefix code tail.

Theorem execution_serves_recursive_call c heap bits :
 funspec_sub (snd (budget_dfs c heap execution_report bits))
             (snd (budget_dfs c heap (recursive_report H S G eligible) bits)).
Proof.
 do_funspec_sub;destruct w as [[[[[[[geom s] cp] weight] depth] q] st] path].
 cbn [fst snd];normalize.
 Exists (geom,s,cp,weight,depth,q,st,path) emp;apply andp_right.
 - entailer!;cancel.
 - apply prop_right;intro rho;normalize;Exists x x0 x1.
   have size_ok:Zlength (active_prefix depth path)=depth by
     unfold active_prefix;rewrite Zlength_sublist;lia.
   have valid:recursive_report H S G eligible weight geom st (active_prefix depth path) x1 x0.
   { eapply (@recursive_reports_by_remaining_depth (Z.to_nat (weight-Zlength (active_prefix depth path))) weight geom st (active_prefix depth path) x1 x0).
     - rewrite Z2Nat.id //;lia.
     - assumption. }
   entailer!;cancel.
Qed.

Theorem install_descendant_evidence c packed heap bits :
 tycontext_sub (func_tycontext flag_level_ast.f_dfs prepared_vars
   (with_child_heap c packed heap (recursive_report H S G eligible) bits) nil)
  (func_tycontext flag_level_ast.f_dfs prepared_vars
   (with_child_heap c packed heap execution_report bits) nil).
Proof.
 apply tycontext_sub_i99;split;first variable_map_sub.
 compare_function_maps (with_child_heap c packed heap (recursive_report H S G eligible) bits)
                       (with_child_heap c packed heap execution_report bits).
 repeat (apply Forall_cons;[first [apply subsumespec_refl|eexists;split;
    [reflexivity|apply funspec_sub_sub_si;apply execution_serves_recursive_call]]|]);apply Forall_nil.
Qed.
End Tree.
