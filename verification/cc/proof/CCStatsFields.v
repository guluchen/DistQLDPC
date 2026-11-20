(* Split the actual statistics structure for the search callers. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition stats_fields sh steps nodes pack charge overlap p:mpred:=
 (field_at sh stats_type[StructField _steps]steps p*
  field_at sh stats_type[StructField _nodes]nodes p*
  field_at sh stats_type[StructField _pack_prunes]pack p*
  field_at sh stats_type[StructField _charge_prunes]charge p*
  field_at sh stats_type[StructField _overlap_prunes]overlap p)%logic.
Lemma stats_data_at_fields sh steps nodes pack charge overlap p:
 data_at sh stats_type(steps,(nodes,(pack,(charge,overlap))))p=
 stats_fields sh steps nodes pack charge overlap p.
Proof.
 unfold stats_fields.
 apply pred_ext;unfold_data_at(data_at sh stats_type _ p);cancel.
Qed.
Lemma stats_repr_fields p s:
 stats_repr p s=stats_fields Tsh
 (Vint(Int.repr(stat_steps s)))(Vint(Int.repr(stat_nodes s)))
 (Vint(Int.repr(stat_pack s)))(Vint(Int.repr(stat_charge s)))
 (Vint(Int.repr(stat_overlap s)))p.
Proof. unfold stats_repr;apply stats_data_at_fields. Qed.
Print Assumptions stats_data_at_fields.
