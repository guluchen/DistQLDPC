(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver SeedExemptionState SeedColumnModel
 SeedPolicyView SeedBlockModel SeedBlockView SeedColumnRestore SeedResume StableSeedPreference.
Local Open Scope Z_scope.

Lemma touched_base_is_enabled g q hi k :
 touched g q hi k=true -> 0<=Int.signed (Znth k (base_order g)).
Proof.
 unfold touched;rewrite existsb_exists;intros [word [_ yes]];unfold touches_row in yes.
 destruct Z_lt_dec;[discriminate|];apply Z.eqb_eq in yes;subst k;lia.
Qed.
Lemma stable_exemption_on_return g q st :
 between_seeds (base_order g) st -> Zlength (exempts (live_rows st))=Zlength (base_order g) ->
 forall k,0<=k<Zlength (exempts (live_rows st)) ->
 touched (dynamic_rows g st) q (index_at g (q+1)) k=true ->
 Znth k (exempts (live_rows st))=
 Int.repr (seed_choice (base_order g) (exhausted_fallback st) k q false).
Proof.
 intros rest len k room hit;apply touched_base_is_enabled in hit;cbn [dynamic_rows base_order] in hit.
 exact (proj2 (proj2 (rest k ltac:(lia) hit))).
Qed.
Lemma stable_exemption_after_search base st left :
 same_seed_state left (live_rows st) -> between_seeds base st ->
 between_seeds base (Build_exhausted_state (exhausted_fallback st) left).
Proof.
 intros [ex counts] rest row bound enabled;cbn [exhausted_fallback live_rows];rewrite ex;apply rest;assumption.
Qed.
