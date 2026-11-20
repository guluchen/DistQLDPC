(* Candidate spatial while invariant. Definitions alone do NOT prove that
   the actual C body establishes/preserves it or terminates. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCStackInvariant
 CCV.CCModel CCV.CCFunctional CCV.CCCandidateScan CCV.CCJournalArray CCV.CCSearchPhases CCV.CCSearchSeparation
 CCV.CCSeedCoverage CCV.CCRootArray CCV.CCJournalTrace CCV.CCRepresentation.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition selected_tracks_stack(n seed:nat)(path:list nat)(ghosts:list ghost_frame)xs:Prop:=
 match rev ghosts with
 |[]=>path=[] /\forall i,(i<n)%nat ->decode xs i=root_selected seed i
 |g::_=>path<>[] /\hd 0%nat path=seed /\
  phase_path n(length path)(ghost_phase g)(ghost_chosen g)path(decode xs)
 end.
Open Scope Z_scope.
Definition loop_shape a cap seed path ghosts log buf xs ys zs pk frames:Prop:=
 Zlength xs=model_n a /\Zlength ys=model_m a /\Zlength zs=model_l a /\
 Zlength pk=model_n a /\
 Forall(fun z:Z=>z=0\/z=1)xs /\Forall(fun z:Z=>z=0\/z=1)ys /\
 Forall(fun z:Z=>z=0\/z=1)zs /\Forall(fun z:Z=>z=0\/z=1)pk /\
 journal_trace(model_n a)(root_mask(model_n a)seed)log buf /\
 cached(model_n a)(model_m a)xs ys(model_h a) /\
 cached(model_n a)(model_l a)xs zs(model_lg a) /\
 physical_stack(Z.to_nat(model_n a))ghosts frames /\
 stack_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
   (model_h_rows a)path ghosts log /\
 selected_tracks_stack(Z.to_nat(model_n a))(Z.to_nat seed)path ghosts xs /\
 separated(Z.to_nat(model_n a))(decode xs)
   (decode(journal_bitmap(root_mask(model_n a)seed)log)) /\
 0<Z.of_nat(weight(Z.to_nat(model_n a))(decode xs))<=cap /\
 seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
   (Z.to_nat cap)(Z.to_nat seed) /\
 target_stack_live(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
   (Z.to_nat cap)(Z.to_nat seed)(root_mask(model_n a)seed)log path ghosts.
Definition search_while_invariant sh a p tp rp cap seed budget rules s0:assert:=
 (EX path:list nat,EX ghosts:list ghost_frame,EX log:list Z,EX buf:list val,
  EX xs:list Z,EX ys:list Z,EX zs:list Z,EX pk:list Z,
  EX frames:list frame_value,EX s:stats_model,
 PROP(loop_shape a cap seed path ghosts log buf xs ys zs pk frames;
      legal_stats budget s;stats_monotone s0 s)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
   temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));
   temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
   temp _rules(Vint(Int.repr rules));
   temp _depth(Vint(Int.repr(Z.of_nat(length path))));
   lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs
   (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames
   (Zrepeat 0(model_n a))s))%assert.
(* Deliberately no theorem claiming establishment/preservation of the invariant.
   The f/q/finish/remaining registers are absent at the true while head; the
   verified entry block reloads f and finish before dispatch. *)

Lemma empty_loop_shape_advances a cap seed path ghosts log buf xs ys zs pk frames:
 loop_shape a cap seed path ghosts log buf xs ys zs pk frames ->path=[] ->
 seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
 (Z.to_nat cap)(S(Z.to_nat seed)).
Proof.
 intros Shape Empty.
 assert(Len:length path=length ghosts)by(unfold loop_shape,stack_geometry in Shape;tauto).
 assert(Ghosts:ghosts=[]).
 { rewrite Empty in Len;destruct ghosts;[reflexivity|simpl in Len;lia]. }
 subst ghosts.
 apply(empty_stack_advances_seed(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
   (Z.to_nat cap)(Z.to_nat seed)(root_mask(model_n a)seed)log path);
 unfold loop_shape in Shape;tauto.
Qed.
Lemma loop_pending_frame_room a cap seed path ghosts log buf xs ys zs pk frames g gs:
 0<=seed<=model_n a ->loop_shape a cap seed path ghosts log buf xs ys zs pk frames ->
 rev ghosts=g::gs ->ghost_phase g=2%nat ->
 Znth(Z.of_nat(ghost_chosen g))(journal_bitmap(root_mask(model_n a)seed)log)=0 /\
 Zlength log<model_n a.
Proof.
 intros Seed Shape Rev Phase2.
 assert(Tracks:selected_tracks_stack(Z.to_nat(model_n a))(Z.to_nat seed)path ghosts xs)
   by(unfold loop_shape in Shape;tauto).
 unfold selected_tracks_stack in Tracks;rewrite Rev in Tracks.
 destruct Tracks as[Nonempty[Root Phase]];rewrite Phase2 in Phase.
 pose proof(pending_phase_selected _ _ _ _ _ Phase)as[Chosen Hit].
 assert(Q:0<=Z.of_nat(ghost_chosen g)<model_n a).
 { apply Nat2Z.inj_lt in Chosen;rewrite Z2Nat.id in Chosen by lia;lia. }
 apply(pending_child_has_journal_room(model_n a)(root_mask(model_n a)seed)
   log buf xs(length path)path(Z.of_nat(ghost_chosen g))).
 - assumption.
 - apply root_mask_length;assumption.
 - apply root_mask_bits;assumption.
 - unfold loop_shape in Shape;tauto.
 - rewrite Nat2Z.id;assumption.
 - unfold loop_shape in Shape;tauto.
Qed.
Print Assumptions empty_loop_shape_advances.
Print Assumptions loop_pending_frame_room.
