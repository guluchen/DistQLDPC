(* SPDX-License-Identifier: GPL-3.0-or-later. Candidate until coqc PASS. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition stats_type := Tstruct _ccv_stats noattr.
Definition stats_init_spec : ident * funspec :=
 DECLARE _stats_init
 WITH p:val
 PRE [tptr stats_type] PROP() PARAMS(p) SEP(data_at_ Tsh stats_type p)
 POST [tvoid] PROP() RETURN()
 SEP(data_at Tsh stats_type
      (Vint Int.zero,(Vint Int.zero,(Vint Int.zero,(Vint Int.zero,Vint Int.zero)))) p).
Definition Gprog : funspecs := ltac:(with_library prog [stats_init_spec]).
Lemma body_stats_init : semax_body Vprog Gprog f_stats_init stats_init_spec.
Proof.
 start_function.
 forward. forward. forward. forward. forward.
 entailer!.
Qed.
Print Assumptions body_stats_init.
