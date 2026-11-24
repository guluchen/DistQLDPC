(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import VerifSeedMove SeedSharedView OverlapColumnState OverlapView VerifOverlapDispatch.
Require seed_ast.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.

(* The code pointer is fixed for the level; the exemption array it reads
   changes on every seed. Quantify the concrete row layout at each call. *)
Definition dynamic_overlap p a:funspec:=
 WITH g:layout, st:snapshot, q:Z, enter:bool
 PRE [tptr tvoid,tint,tbool]
 PROP(is_pointer_or_null p;admissible g q enter st)
 PARAMS(p;Vint (Int.repr q);Vint (if enter then Int.one else Int.zero)) SEP(view_mem p a g st)
 POST [tvoid] PROP() RETURN() SEP(view_mem p a g (after_column g q enter st)).
Definition wrapped p a:=(seed_ast._cc_seed_overlap,dynamic_overlap p a).
Definition direct p a:=(seed_ast._cc_overlap_policy,dynamic_overlap p a).
Definition UniversalG p a:funspecs:=ltac:(with_library seed_ast.prog [update_spec;direct p a;wrapped p a]).

Theorem dynamic_direct_body p a:
 is_pointer_or_null (qubitp a) -> is_pointer_or_null (blockp a) ->
 semax_body SVars (UniversalG p a) seed_ast.f_cc_overlap_policy (direct p a).
Proof.
 intros;start_function;destruct enter.
 - forward_call (p,a,g,q,true,st);try solve [entailer!].
 - forward_call (p,a,g,q,false,st);try solve [entailer!].
Qed.
Theorem dynamic_wrapper_body p a:
 isptr p -> field_compatible seed_type [] p ->
 semax_body SVars (UniversalG p a) seed_ast.f_cc_seed_overlap (wrapped p a).
Proof.
 intros pp layout_ok;start_function.
 forward;destruct enter.
 - forward_call (g,st,q,true);try solve [entailer!;destruct p;try contradiction;reflexivity].
 - forward_call (g,st,q,false);try solve [entailer!;destruct p;try contradiction;reflexivity].
Qed.
Lemma specialize_dynamic_geometry p a geom:
 funspec_sub (dynamic_overlap p a) (callback_contract p geom (view_mem p a geom)).
Proof.
 do_funspec_sub;destruct w as [[st q] enter];cbn [fst snd];normalize.
 Exists (geom,st,q,enter) emp;apply andp_right.
 - entailer!;cancel.
 - apply prop_right;intro rho;normalize;entailer!;cancel.
Qed.
