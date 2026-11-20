(* Complete PURE loop-shape transition from phase0 to phase1. The real C stores
   and phase0 caller composition still require their spatial block proofs. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCSearchSpecs CCV.CCStackInvariant CCV.CCLoopInvariant
 CCV.CCActivateCoverage CCV.CCActivateMemory CCV.CCActivateGeometry CCV.CCMatrixModel.
Import ListNotations. Open Scope Z_scope.
Theorem loop_shape_activate a cap seed path prefix g log buf xs ys zs pk frames row:
 1<=cap<=model_n a ->ghost_phase g=0%nat ->
 (row<Z.to_nat(model_m a))%nat ->(length path<Z.to_nat cap)%nat ->
 parity(Z.to_nat(model_n a))(nth row(model_h_rows a)zero_vector)
 (prefix_selected path(length prefix))=true ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 loop_shape a cap seed path(prefix++[activated_record g row])log buf xs ys zs pk
 (activate_raw_frames prefix row frames).
Proof.
 intros Cap Phase Row Room Odd Whole.
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as [XL [YL [ZL [PKL [XB [YB [ZB [PKB [Trace [HC [LC [Phys [Geo [Tracks [Sep [Wgt [Before Live]]]]]]]]]]]]]]]]].
 assert(Len:length path=length(prefix++[g]))by(unfold stack_geometry in Geo;tauto).
 assert(Capacity:(length(prefix++[g])<=Z.to_nat(model_n a))%nat).
 { rewrite <-Len;apply Nat2Z.inj_le;rewrite Z2Nat.id by lia.
   apply Nat2Z.inj_lt in Room;rewrite Z2Nat.id in Room by lia;lia. }
 assert(Physical:physical_stack(Z.to_nat(model_n a))(prefix++[activated_record g row])
 (activate_raw_frames prefix row frames)).
 { apply activation_physical_stack;assumption. }
 assert(Geometry:stack_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
 (model_h_rows a)path(prefix++[activated_record g row])log).
 { apply geometry_activation;try assumption.
   rewrite app_length in Len;cbn[length]in Len;lia. }
 assert(Tracking:selected_tracks_stack(Z.to_nat(model_n a))(Z.to_nat seed)
 path(prefix++[activated_record g row])xs).
 { apply activated_selected_tracks;assumption. }
 assert(Hlen:length(model_h_rows a)=Z.to_nat(model_m a)).
 { unfold model_h_rows,matrix_vectors;rewrite map_length,seq_length;reflexivity. }
 assert(Coverage:target_stack_live(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
 (Z.to_nat cap)(Z.to_nat seed)(CCRootArray.root_mask(model_n a)seed)log
 path(prefix++[activated_record g row])).
 { apply activation_preserves_live_targets;try assumption;rewrite Hlen;assumption. }
 unfold loop_shape;tauto.
Qed.
Print Assumptions loop_shape_activate.
