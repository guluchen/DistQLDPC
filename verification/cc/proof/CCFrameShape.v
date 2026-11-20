(* Separating ownership of the real C frame fields. No search theorem here. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition frame_type:=Tstruct _ccv_frame noattr.
Definition frame_fields sh row next chosen mark phase p:mpred:=
 (field_at sh frame_type[StructField _row]row p*
  field_at sh frame_type[StructField _next]next p*
  field_at sh frame_type[StructField _chosen]chosen p*
  field_at sh frame_type[StructField _mark]mark p*
  field_at sh frame_type[StructField _phase]phase p)%logic.
Lemma frame_data_at_fields sh row next chosen mark phase p:
 data_at sh frame_type(row,(next,(chosen,(mark,phase))))p=
 frame_fields sh row next chosen mark phase p.
Proof.
 unfold frame_fields.
 apply pred_ext;unfold_data_at(data_at sh frame_type _ p);cancel.
Qed.
Lemma frame_mark_focus sh row next chosen mark phase p:
 data_at sh frame_type(row,(next,(chosen,(mark,phase))))p |--
 (field_at sh frame_type[StructField _mark]mark p*
  (field_at sh frame_type[StructField _row]row p*
   field_at sh frame_type[StructField _next]next p*
   field_at sh frame_type[StructField _chosen]chosen p*
   field_at sh frame_type[StructField _phase]phase p))%logic.
Proof. rewrite frame_data_at_fields;unfold frame_fields;cancel. Qed.
Print Assumptions frame_data_at_fields.
