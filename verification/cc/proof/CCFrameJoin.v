(* Rejoin focused C fields and a replaced frame-array cell. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCFrameShape CCV.CCFrameFields.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma frame_fields_join sh row next chosen mark phase p:
 (field_at sh CCFrameShape.frame_type[StructField _row]row p*
  field_at sh CCFrameShape.frame_type[StructField _next]next p*
  field_at sh CCFrameShape.frame_type[StructField _chosen]chosen p*
  field_at sh CCFrameShape.frame_type[StructField _mark]mark p*
  field_at sh CCFrameShape.frame_type[StructField _phase]phase p)%logic |--
 data_at sh CCFrameShape.frame_type(row,(next,(chosen,(mark,phase))))p.
Proof. rewrite frame_data_at_fields;unfold frame_fields;cancel. Qed.
Section ArrayProof.
Context{CS:compspecs}.
Lemma frame_cell_join sh n i(frames:list(reptype CCFrameFields.frame_type))p v:
 Zlength frames=n ->0<=i<n ->
 (data_at sh CCFrameFields.frame_type v
   (field_address0(tarray CCFrameFields.frame_type n)[ArraySubsc i]p)*
  frame_remainder sh n i frames p)%logic |--
 data_at sh(tarray CCFrameFields.frame_type n)(upd_Znth i frames v)p.
Proof. intros;rewrite frame_array_reassemble by assumption;apply derives_refl. Qed.
End ArrayProof.
Print Assumptions frame_cell_join.
