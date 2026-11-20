(* Actual root depth/top/frame stores establish the full verified while
   invariant. Raw scratch is allowed on entry; no uninitialized read is used. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCSearchMemory CCV.CCRawTopHeap CCV.CCRootArray CCV.CCRootInvariant
 CCV.CCFrameFields CCV.CCFrameShape CCV.CCFrameJoin CCV.CCFrameForget CCV.CCLoopInvariant
 CCV.CCJournalArray CCV.CCSeedCoverage CCV.CCAPIBridge CCV.VerifRootFrame CCV.VerifRootPreparation.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_root_frame_heap:forall sh a p tp rp cap seed budget rules top s0 s,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->
 seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)(Z.to_nat cap)(Z.to_nat seed) ->
 semax CCSearchContext.Delta
 (root_state_raw sh a p tp rp cap seed budget rules top
 (root_xs(model_n a)seed)(root_mask(model_n a)seed)
 (root_cache(model_n a)(model_m a)seed(model_h a))(root_cache(model_n a)(model_l a)seed(model_lg a))
 (Zrepeat 0(model_n a))(root_buf(model_n a))(Zrepeat(default_frame:frame_value)(model_n a))
 (Zrepeat 0(model_n a))s)
 root_frame_init(normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules top s0 s SH Legal Cap Seed Stats Mono Before.
 pose proof(legal_model_ranges a Legal)as[NR More].
 pose proof(initial_root_loop_shape a cap seed Legal Cap Seed Before)as NewShape.
 assert(Len:Zlength(Zrepeat(default_frame:frame_value)(model_n a))=model_n a)by(rewrite Zlength_Zrepeat;lia).
 unfold root_state_raw,search_heap_raw_top,workspace_fields.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in root_frame_init in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 Intros. forward. forward. forward. forward.
 assert_PROP(isptr(ptr_frames p))as Ptr by entailer!.
 cbn[sem_binary_operation'].
 unfold sem_add,Cop.classify_add,typeconv,remove_attributes,change_attributes,sem_add_ptr_int.
 rewrite sem_add_pi_ptr by(auto;rep_lia). autorewrite with norm.
 lazymatch goal with|-context[complete_type ?ce ?ty]=>
 let T:=constr:(complete_type ce ty=true)in assert(CT_actual:T)by reflexivity;rewrite CT_actual end.
 cbn[force_val].
 assert(I:0<=0<model_n a)by lia.
 assert_PROP(field_compatible(tarray CCSearchSpecs.frame_type(model_n a))[](ptr_frames p))as FC by entailer!.
 pose proof(@frame_array_focus CCSearchSpecs.CompSpecs Tsh(model_n a)0
 (Zrepeat(default_frame:frame_value)(model_n a))(ptr_frames p)Len I)as Focus.
 unfold CCFrameFields.frame_type in Focus;unfold CCSearchSpecs.frame_type. rewrite Focus.
 assert(Address:field_address0(tarray(Tstruct _ccv_frame noattr)(model_n a))[ArraySubsc 0](ptr_frames p)=ptr_frames p).
 { rewrite field_address0_offset by auto with field_compatible;cbn;autorewrite with norm;reflexivity. }
 assert(Old:Znth 0(Zrepeat(default_frame:frame_value)(model_n a))=
 (Vundef,(Vundef,(Vundef,(Vundef,Vundef))))).
 { rewrite Znth_Zrepeat by lia;reflexivity. }
 pose proof(frame_data_at_fields Tsh Vundef Vundef Vundef Vundef Vundef
 (field_address0(tarray(Tstruct _ccv_frame noattr)(model_n a))[ArraySubsc 0](ptr_frames p)))as Shape.
 unfold CCFrameShape.frame_type in Shape.
 lazymatch goal with|-context[@data_at ?cs Tsh(Tstruct _ccv_frame noattr)?v ?adr]=>
 let Cell:=constr:(@data_at cs Tsh(Tstruct _ccv_frame noattr)v adr)in
 lazymatch type of Shape with ?Canonical = ?Fields=>
 assert(CellEq:Cell=Canonical)by(f_equal;exact Old)end end.
 rewrite CellEq,Shape,Address. unfold frame_fields. Intros. forward. forward.
 sep_apply(frame_fields_join Tsh Vundef Vundef Vundef(Vint(Int.repr 0))(Vint(Int.repr 0))(ptr_frames p)).
 pose proof(frame_cell_join Tsh(model_n a)0(Zrepeat(default_frame:frame_value)(model_n a))(ptr_frames p)
 (Vundef,(Vundef,(Vundef,(Vint(Int.repr 0),Vint(Int.repr 0)))))Len I)as Join.
 unfold CCFrameFields.frame_type in Join;rewrite Address in Join;sep_apply Join.
 unfold search_while_invariant.
 Exists[Z.to_nat seed][root_ghost]([]:list Z)(root_buf(model_n a))
 (root_xs(model_n a)seed)(root_cache(model_n a)(model_m a)seed(model_h a))
 (root_cache(model_n a)(model_l a)seed(model_lg a))(Zrepeat 0(model_n a))(root_frames(model_n a))s.
 unfold search_heap,workspace_fields,root_frames,root_frame_words.
 entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_root_frame_heap.
