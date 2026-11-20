(* Root-state mathematics used to establish the proposed C while invariant.
   Does not itself prove the complete C root caller or loop preservation. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCModel CCV.CCFunctional
 CCV.CCCache CCV.CCCandidateScan CCV.CCSearchPhases CCV.CCRepresentation
 CCV.CCMatrix CCV.CCMatrixModel CCV.CCRootArray CCV.CCSeedCoverage
 CCV.CCJournalArray CCV.CCJournalTrace CCV.CCFrameForget CCV.VerifSearchPush
 CCV.VerifPhaseOneTail CCV.VerifToggle CCV.CCSearchHeap CCV.CCStackInvariant CCV.CCLoopInvariant
 CCV.CCSearchSeparation CCV.CCAPIBridge.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Open Scope Z_scope.
Definition root_xs n seed:=chosen_xs seed(Zrepeat 0 n).
Definition root_cache n m seed h:=chosen_ys n m seed h(Zrepeat 0 m).
Definition root_ghost:ghost_frame:={|ghost_phase:=0%nat;ghost_row:=0%nat;
 ghost_next:=0%nat;ghost_chosen:=0%nat;ghost_mark:=0|}.
Definition root_frame_words:frame_value:=
 (Vundef,(Vundef,(Vundef,(Vint Int.zero,Vint Int.zero)))).
Definition root_frames n:=upd_Znth 0(Zrepeat(default_frame:frame_value)n)root_frame_words.
Definition root_buf n:=Zrepeat Vundef n.
Lemma root_zero_bits n:Forall(fun z:Z=>z=0\/z=1)(Zrepeat 0 n).
Proof. unfold Zrepeat;apply Forall_repeat;auto. Qed.
Lemma root_xs_length n seed:0<=seed<n ->Zlength(root_xs n seed)=n.
Proof.
 intros Q;unfold root_xs,chosen_xs.
 rewrite upd_Znth_Zlength by(rewrite Zlength_Zrepeat;lia).
 rewrite Zlength_Zrepeat;lia.
Qed.
Lemma root_xs_bits n seed:0<=seed<n ->Forall(fun z:Z=>z=0\/z=1)(root_xs n seed).
Proof.
 intros Q;unfold root_xs,chosen_xs;rewrite Znth_Zrepeat by assumption.
 change(Z.lxor 0 1)with 1;apply Forall_upd_Znth;[apply root_zero_bits|auto].
Qed.
Lemma root_xs_decode n seed i:0<=seed<n ->(i<Z.to_nat n)%nat ->
 decode(root_xs n seed)i=root_selected(Z.to_nat seed)i.
Proof. unfold root_xs,chosen_xs;intros;apply root_toggle_decode;assumption. Qed.
Lemma root_cache_length n m seed h:0<=m ->Zlength(root_cache n m seed h)=m.
Proof.
 intros M;unfold root_cache,chosen_ys.
 rewrite xor_vector_length by(rewrite Zlength_Zrepeat,column_length;lia).
 rewrite Zlength_Zrepeat;lia.
Qed.
Lemma root_cache_bits n m seed h:0<n ->0<=m ->0<=seed<n ->
 Zlength h=m*n ->Forall(fun z:Z=>z=0\/z=1)h ->
 Forall(fun z:Z=>z=0\/z=1)(root_cache n m seed h).
Proof.
 intros N M Seed Hlen HB;unfold root_cache,chosen_ys.
 apply xor_vector_bits.
 - rewrite Zlength_Zrepeat,column_length;lia.
 - apply root_zero_bits.
 - apply(column_bits n m seed h);assumption.
Qed.
Lemma root_cache_matches n m seed h:0<n ->0<=m ->0<=seed<n ->
 Zlength h=m*n ->Forall(fun z:Z=>z=0\/z=1)h ->
 cached n m(root_xs n seed)(root_cache n m seed h)h.
Proof.
 intros N M Seed Hlen HB;unfold root_xs,chosen_xs,root_cache,chosen_ys.
 apply cached_toggle;try assumption.
 - rewrite Zlength_Zrepeat;lia.
 - rewrite Zlength_Zrepeat;lia.
 - apply root_zero_bits.
 - apply clear_arrays_cache;assumption.
Qed.
Lemma root_xs_weight n seed:0<=seed<n ->weight(Z.to_nat n)(decode(root_xs n seed))=1%nat.
Proof.
 intros Seed;assert(QN:(Z.to_nat seed<Z.to_nat n)%nat)by(apply Z2Nat.inj_lt;lia).
 rewrite(weight_ext(Z.to_nat n)(decode(root_xs n seed))(root_selected(Z.to_nat seed)))
   by(intros;apply root_xs_decode;assumption).
 change(weight(Z.to_nat n)(setbit zero_vector(Z.to_nat seed))=1%nat).
 rewrite setbit_weight by(try assumption;reflexivity).
 rewrite zero_weight;reflexivity.
Qed.
Lemma singleton_path_bits seed i:path_bits[seed]i=root_selected seed i.
Proof. unfold path_bits,root_selected,setbit;simpl;rewrite orb_false_r;destruct(Nat.eqb i seed);reflexivity. Qed.
Lemma phase_selected_ext n depth phase q path before after:
 (forall i,(i<n)%nat ->after i=before i) ->
 phase_path n depth phase q path before ->phase_path n depth phase q path after.
Proof.
 intros Eq[ND[Range[Len State]]];split;[assumption|split;[assumption|split;[assumption|]]].
 destruct phase as[|[|[|phase]]];cbn in State |- *.
 - intros i I;rewrite Eq by assumption;apply State;assumption.
 - intros i I;rewrite Eq by assumption;apply State;assumption.
 - destruct State as[Q[Fresh Sel]];split;[assumption|split;[assumption|]].
   intros i I;rewrite Eq by assumption;apply Sel;assumption.
 - contradiction.
Qed.
Lemma root_selected_tracks n seed:0<=seed<n ->
 selected_tracks_stack(Z.to_nat n)(Z.to_nat seed)[Z.to_nat seed][root_ghost](root_xs n seed).
Proof.
 intros Seed;unfold selected_tracks_stack;cbn[rev app root_ghost ghost_phase ghost_chosen].
 split;[discriminate|split;[reflexivity|]].
 apply(phase_selected_ext(Z.to_nat n)1 0 0[Z.to_nat seed](path_bits[Z.to_nat seed])).
 - intros i I;rewrite root_xs_decode by assumption;symmetry;apply singleton_path_bits.
 - apply phase_root;apply Z2Nat.inj_lt;lia.
Qed.
Lemma root_separated n seed:0<=seed<n ->
 separated(Z.to_nat n)(decode(root_xs n seed))(decode(root_mask n seed)).
Proof.
 intros Seed i I Hit;rewrite root_xs_decode in Hit by assumption.
 unfold root_selected,setbit in Hit;destruct(Nat.eqb i(Z.to_nat seed))eqn:E;[|discriminate].
 apply Nat.eqb_eq in E;subst i.
 rewrite(root_mask_decode n seed(Z.to_nat seed))by(try lia;apply Z2Nat.inj_lt;lia).
 unfold root_forbidden;rewrite Nat.ltb_irrefl;reflexivity.
Qed.
Lemma root_empty_trace_at_seed n seed:0<=n ->journal_trace n(root_mask n seed)[](root_buf n).
Proof.
 intros N;unfold journal_trace.
 split;[change(0<=0<=n)%Z;lia|].
 split;[constructor|].
 split;[unfold nat_journal;cbn;constructor|].
 split.
 - unfold root_clear,nat_journal;intros q Hin;simpl in Hin;contradiction.
 - split.
   + unfold root_buf;rewrite Zlength_Zrepeat;lia.
   + unfold undo_prefix,tbytes;list_solve.
Qed.
Lemma root_frames_length n:0<n ->Zlength(root_frames n)=n.
Proof.
 intros N;unfold root_frames.
 rewrite upd_Znth_Zlength by(rewrite Zlength_Zrepeat;lia).
 rewrite Zlength_Zrepeat;lia.
Qed.
Lemma root_physical_frames n:0<n ->physical_stack(Z.to_nat n)[root_ghost](root_frames n).
Proof.
 intros N;unfold physical_stack;split.
 - rewrite root_frames_length by assumption;rewrite Z2Nat.id by lia;reflexivity.
 - intros k K;unfold root_frames;destruct k as[|k].
   + cbn[length nth];destruct(lt_dec 0 1);[|lia].
     rewrite upd_Znth_same by(rewrite Zlength_Zrepeat;lia).
     unfold frame_represents,root_ghost,root_frame_words;cbn.
     exists Vundef,Vundef,Vundef;reflexivity.
   + cbn[length];destruct(lt_dec(S k)1);[lia|].
     assert(I:0<=Z.of_nat(S k)<n).
     { apply Nat2Z.inj_lt in K;rewrite Z2Nat.id in K by lia;lia. }
     rewrite upd_Znth_diff by(rewrite ?Zlength_Zrepeat;lia).
     rewrite Znth_Zrepeat by assumption;unfold default_frame;reflexivity.
Qed.
Lemma root_geometry n m cap hs seed:(seed<n)%nat ->(0<cap)%nat ->
 stack_geometry n m cap hs[seed][root_ghost][].
Proof.
 intros Seed Cap;unfold stack_geometry.
 split;[reflexivity|split].
 - constructor;[simpl;tauto|constructor].
 - split;[constructor;[assumption|constructor]|split].
   + right;simpl;lia.
   + intros k g At;destruct k as[|k].
     * cbn in At;inversion At;subst g;cbn[root_ghost ghost_phase ghost_mark ghost_chosen ghost_next ghost_row Zlength].
       change(Zlength([]:list Z))with 0%Z. cbn[length]. repeat split;lia.
     * simpl in At;destruct k;discriminate.
Qed.
Print Assumptions root_cache_matches.
Print Assumptions root_selected_tracks.
Print Assumptions root_physical_frames.
Print Assumptions root_geometry.
Lemma root_live_targets n hs ls cap seed:0<=seed<n ->
 seeds_before_clear(Z.to_nat n)hs ls cap(Z.to_nat seed) ->
 target_stack_live(Z.to_nat n)hs ls cap(Z.to_nat seed)
 (root_mask n seed)[][Z.to_nat seed][root_ghost].
Proof.
 intros Seed Before e Min Within Hit.
 assert(QN:(Z.to_nat seed<Z.to_nat n)%nat)by(apply Z2Nat.inj_lt;lia).
 exists 0%nat;unfold critical_at;exists root_ghost;split;[reflexivity|].
 change(compatible(Z.to_nat n)e(path_bits[Z.to_nat seed])(decode(root_mask n seed))).
 destruct(current_seed_target_compatible(Z.to_nat n)hs ls cap(Z.to_nat seed)e
   Before QN Min Within Hit)as[Sub Avoid].
 split.
 - intros i I Chosen;apply Sub;[assumption|].
   rewrite singleton_path_bits in Chosen;assumption.
 - intros i I Forbidden;apply Avoid;[assumption|].
   rewrite(root_mask_decode n seed i ltac:(lia)I)in Forbidden;assumption.
Qed.
Theorem initial_root_loop_shape a cap seed:
 legal_model a ->1<=cap<=model_n a ->0<=seed<model_n a ->
 seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
   (Z.to_nat cap)(Z.to_nat seed) ->
 loop_shape a cap seed[Z.to_nat seed][root_ghost][](root_buf(model_n a))
   (root_xs(model_n a)seed)(root_cache(model_n a)(model_m a)seed(model_h a))
   (root_cache(model_n a)(model_l a)seed(model_lg a))(Zrepeat 0(model_n a))
   (root_frames(model_n a)).
Proof.
 intros Legal Cap Seed Before.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(N:0<model_n a)by lia.
 assert(QN:(Z.to_nat seed<Z.to_nat(model_n a))%nat)by(apply Z2Nat.inj_lt;lia).
 assert(CN:(0<Z.to_nat cap)%nat).
 { change(Z.to_nat 0<Z.to_nat cap)%nat;apply Z2Nat.inj_lt;lia. }
 destruct Legal as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 unfold loop_shape.
 split;[apply root_xs_length;assumption|].
 split;[apply root_cache_length;assumption|].
 split;[apply root_cache_length;assumption|].
 split;[rewrite Zlength_Zrepeat;lia|].
 split;[apply root_xs_bits;assumption|].
 split;[apply root_cache_bits;assumption|].
 split;[apply root_cache_bits;assumption|].
 split;[apply root_zero_bits|].
 split;[apply root_empty_trace_at_seed;lia|].
 split;[apply root_cache_matches;assumption|].
 split;[apply root_cache_matches;assumption|].
 split;[apply root_physical_frames;assumption|].
 split;[apply root_geometry;assumption|].
 split;[apply root_selected_tracks;assumption|].
 split.
 - change(separated(Z.to_nat(model_n a))(decode(root_xs(model_n a)seed))
     (decode(root_mask(model_n a)seed)));apply root_separated;assumption.
 - split.
   + rewrite(root_xs_weight(model_n a)seed Seed);cbn;lia.
   + split;[assumption|apply root_live_targets;assumption].
Qed.
Print Assumptions root_live_targets.
Print Assumptions initial_root_loop_shape.
