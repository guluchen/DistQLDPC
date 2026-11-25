(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit SiblingCounters EnabledCall
 PreparedBudgetContract PreparedDepthSpec PreparedRootStages PreparedSeedDispatch PreparedChildCall
 PreparedSiblingRestore PreparedPlainDescent PreparedPlainSiblings PreparedPlainUndo
 PreparedPCMChooser PreparedIndexFinish PreparedIndexWhile PreparedIndexNodeReport PreparedVerdictExit
 PreparedSampling PreparedCallerLocals.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedResidualIndex PreparedMatrixPath PreparedChildPrefix PreparedPCMLeafVisit
 PreparedInteriorReport PreparedSiblingScan LeafMatrix LevelSearch NativePackingScan
 OverlapColumnState RowTally IndexRowBridge PreparedPlainReachable EnabledLoopFacts flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

Section Search.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (eligible:seq Integers.int->'cV['F_2]_n->Prop) (rows:'I_m->seq 'I_n) (parent:seq 'I_n)
 (st:snapshot) (offsets:seq Z) (cols:seq Integers.int) (result:scan_exit) (remaining:nat).
Let P:=[set q:'I_n | q \in parent].
Let F:=@available_now n st.
Let base:=blocked st.
Let node:=literal_path parent.
Let xs:=map Int.unsigned (output_columns offsets cols base result).
Let w:=Z.of_nat (size parent+remaining)%N.
Let d:=Z.of_nat (size parent).
Let report:=recursive_report H S G eligible.
Let entry:entry_domain:=fun _ _ _ _ _ snapshot prefix=>reachable_prefix n snapshot prefix.
Hypotheses (fits:(Z.of_nat n<=Int.max_signed)%coqZ) (width:Zlength base=Z.of_nat n)
 (unique:uniq parent) (protected:forall q:'I_n,q \in parent -> Znth (Z.of_nat q) base<>Int.zero)
 (distinct:forall i,uniq (rows i)) (covers:forall i q,H i q!=0 -> q \in rows i)
 (maxrow:forall i,(Zlength (encoded rows i)<=Int.max_signed)%coqZ)
 (origin:selection_origin rows H (indicator P) F remaining offsets cols base result).
Lemma actual_candidates_fit:
 in_array (Zlength base) xs /\ (Zlength xs<=Int.max_signed)%coqZ.
Proof.
 have uns:(Z.of_nat n<=Int.max_unsigned)%coqZ by
   move:fits;change Int.max_signed with 2147483647%coqZ;change Int.max_unsigned with 4294967295%coqZ;lia.
 rewrite /xs;case:result origin=>[row p tags|tags|tags] provenance.
 - case:provenance=>first [_ [_ written]];rewrite written Zlength_map;split.
   + exact:(proj1 (@emitted_range_and_availability n (rows first) base F uns width (@available_in_view n st))).
   + have bound:=filtered_length base (encoded rows first);have cap:=@maxrow first;lia.
 - split;[constructor|change (0<=2147483647)%coqZ;lia].
 - split;[constructor|change (0<=2147483647)%coqZ;lia].
Qed.

Theorem recursive_loop_from_physical_row {Espec:OracleKind} c (heap:node_storage) (rec_heap:budget_heap)
 loan bits s cp bp buffer path:
 nested_policy (nested c)=nullval -> (1<=d<w-2)%coqZ -> (w<=Int.max_signed)%coqZ ->
 (w<=Zlength path)%coqZ -> active_prefix d path=node ->
 (Zlength base<Zlength (column_offsets (geometry c)))%coqZ ->
 (forall subnode,Zlength subnode=(d+1)%coqZ -> rec_heap w s subnode=(heap s subnode * loan)%logic) ->
 (forall x (a:'I_n),eligible node x -> eligible (node++[::Int.repr (Z.of_nat a)]) x) ->
 let regs:=plain_scan_regs s buffer d (Zlength xs) in
 let own tail:=(child_fields s cp bp w base tail * child_array buffer xs * heap s node * loan)%logic in
 semax (func_tycontext f_dfs prepared_vars (prepared_calls (snd (depth_flip c heap bits))
      (snd (plain_dfs_contract entry rec_heap report bits))) nil)
   (PROPx nil (LOCALx (regs 0%coqZ 0%coqZ bits) (SEPx [::own path])))
   (Ssequence search_children undo_children)
   (normal_ret_assert (EX i:Z,EX code:Z,EX tail:seq Integers.int,
     PROPx [::recursive_result H S G eligible w st node code tail;(0<=code<=3)%coqZ;
              Zlength tail=Zlength path;active_prefix d tail=node]
       (LOCALx (regs i code bits) (SEPx [::own tail])))).
Proof.
 move=>plain deep cap room prefix colroom lend inherit regs own.
 have [range count]:=actual_candidates_fit.
 have limit:(Zlength base<=Int.max_signed)%coqZ by rewrite width.
 have reached i cur:(0<=i<Zlength xs)%coqZ -> active_prefix d cur=active_prefix d path ->
   entry (geometry c) s cp bp w (sibling_state st xs (i+1)%coqZ) (append_qubit cur d (Znth i xs)).
 { move=>pos same;rewrite prefix in same.
   exact:(@all_visited_children_are_reachable m n H rows parent st offsets cols remaining result
       fits width distinct unique protected origin i d cur pos same). }
 have run:=@plain_scan_and_restore Espec entry c heap rec_heap loan report bits s cp bp buffer xs st path w d
   plain deep cap room count limit range colroom lend reached.
 cbn zeta in run;rewrite prefix in run.
 eapply semax_post';[|exact run].
 Intros i code tail.
 match goal with K:scan_outcome_mode _ _ _ _ _ _ _ _ _ |- _=>pose proof K as covered end.
 have answer:=@index_children_preserve_recursive_result m n r k H S G eligible rows parent st offsets cols remaining
   fits width covers distinct unique (geometry c) result i code tail origin inherit covered.
 Exists i code tail;unfold regs,own,plain_scan_regs;entailer!;try apply derives_refl.
Qed.

Theorem recursive_suffix_from_physical_row {Espec:OracleKind} c (heap:node_storage) (rec_heap:budget_heap)
 loan bits s cp bp buffer path ptr klass t1 t2:
 nested_policy (nested c)=nullval -> (1<=d<w-2)%coqZ -> (w<=Int.max_signed)%coqZ ->
 (w<=Zlength path)%coqZ -> active_prefix d path=node ->
 (Zlength base<Zlength (column_offsets (geometry c)))%coqZ ->
 (forall subnode,Zlength subnode=(d+1)%coqZ -> rec_heap w s subnode=(heap s subnode * loan)%logic) ->
 (forall x (a:'I_n),eligible node x -> eligible (node++[::Int.repr (Z.of_nat a)]) x) ->
 (Int.signed klass<0)%coqZ ->
 let regs:=plain_scan_regs s buffer d (Zlength xs) in
 let own tail:=(child_fields s cp bp w base tail * child_array buffer xs * heap s node * loan)%logic in
 let evidence code tail:=recursive_result H S G eligible w st node code tail /\ (0<=code<=3)%coqZ /\
                          Zlength tail=Zlength path /\ active_prefix d tail=node in
 let D:=func_tycontext f_dfs prepared_vars (prepared_calls (snd (depth_flip c heap bits))
      (snd (plain_dfs_contract entry rec_heap report bits))) nil in
 semax D (PROPx nil (LOCALx (regs 0%coqZ 0%coqZ bits++[::lvar _sample sample_type ptr])
   (SEPx [::own path;sample_data ptr klass t1 t2]))) search_finish
   (existential_ret_assert (fun a:Z*(Z*seq Integers.int)=>function_body_ret_assert tint
     (PROP(evidence a.2.1 a.2.2) LOCAL(temp ret_temp (Vint (Int.repr a.2.1)))
       SEP(data_at_ Tsh sample_type ptr;own a.2.2))))%assert.
Proof.
 move=>plain deep cap room prefix colroom lend inherit disabled regs own evidence D.
 pose answer:=(Z*(Z*seq Integers.int))%type.
 pose before:=regs 0%coqZ 0%coqZ bits.
 pose after (a:answer):=regs a.1 a.2.1 bits.
 pose facts (a:answer):=[::evidence a.2.1 a.2.2].
 pose heap_out (a:answer):=[::own a.2.2].
 have loop:semax D (PROPx nil (LOCALx before (SEPx [::own path])))
    (Ssequence search_children undo_children) (normal_ret_assert (EX a:answer, PROPx (facts a) (LOCALx (after a) (SEPx (heap_out a))))).
 { eapply semax_post';last exact:(@recursive_loop_from_physical_row Espec c heap rec_heap loan bits s cp bp buffer path
      plain deep cap room prefix colroom lend inherit).
   Intros i code tail;Exists (i,(code,tail));unfold facts,evidence,after,heap_out,own,regs,plain_scan_regs;cbn [fst snd];entailer!;try apply derives_refl. }
 apply:(@finish_after_siblings answer Espec D _ ptr klass t1 t2 (fun a=>a.2.1)
   (fun a=>evidence a.2.1 a.2.2) (fun a=>own a.2.2) _ disabled).
 - unfold D;apply tycontext_sub_Gprog_nil;vm_compute;
   repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - pose saved:=[::lvar _sample sample_type ptr].
   pose extra:=[::sample_data ptr klass t1 t2].
   have stable:closed_wrt_modvars (Ssequence search_children undo_children) (LOCALx saved (SEPx extra))
     by unfold saved,extra,search_children,undo_children;auto 100 with closed.
   eapply semax_post';last exact:(@keep_caller_locals_for_answer answer Espec VerifDetected.CompSpecs D
      (Ssequence search_children undo_children) nil before [::own path] saved extra facts after heap_out stable loop).
   Intros a;Exists a;unfold after,regs,plain_scan_regs,facts,saved,heap_out,extra;cbn [app];entailer!;try apply derives_refl.
Qed.
End Search.
