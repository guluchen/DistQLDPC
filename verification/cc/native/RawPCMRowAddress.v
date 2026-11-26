(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMComposites.
Local Open Scope Z_scope.

Definition reduction_type:=Tstruct _reduction noattr.
Definition row_layout sh r base words:=
 (field_at sh reduction_type [StructField _store] base r *
  field_at sh reduction_type [StructField _words] (Vint (Int.repr words)) r)%logic.
Definition row_address_spec:ident*funspec:=
 DECLARE _row_at WITH r:val,base:val,sh:share,i:Z,words:Z
 PRE [tptr reduction_type,tint]
 PROP(readable_share sh;isptr base;0<=i<=Int.max_signed;0<=words<=Int.max_signed;
      8*(i*words)<=Ptrofs.max_unsigned)
 PARAMS(r;Vint (Int.repr i)) SEP(row_layout sh r base words)
 POST [tptr tulong] PROP() RETURN(offset_val (8*(i*words)) base)
 SEP(row_layout sh r base words).
Definition address_calls:funspecs:=ltac:(with_library prog [row_address_spec]).

Theorem packed_row_address:semax_body raw_vars address_calls f_row_at row_address_spec.
Proof.
 start_function;unfold row_layout,reduction_type;Intros.
 forward. forward. forward;entailer!.
Qed.
