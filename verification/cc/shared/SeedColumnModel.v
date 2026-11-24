(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SiblingCounters SeedExemptionState.
Local Open Scope Z_scope.

Record moving_state:={exempts:list int; reference_counts:list int; forbidden_events:int64}.
Definition replace_exemption (limits:list int) (st:moving_state) row next :=
 let old:=Znth row (exempts st) in
 if Int.eq old (Int.repr next) then st else
 let updated:=upd_Znth row (exempts st) (Int.repr next) in
 if Int.eq (Znth row limits) Int.zero then
  Build_moving_state updated (reassign_blocks (reference_counts st) (Int.signed old) next)
    (new_forbidden_count (forbidden_events st) (reference_counts st) (Int.signed old) next)
 else Build_moving_state updated (reference_counts st) (forbidden_events st).

Definition seed_choice (base fallback:list int) row seed (enter:bool) :=
 if enter then seed else clear_seed (Int.signed (Znth row base)) (Int.signed (Znth row fallback)).
Definition visit_seed_row limits base fallback seed enter st (row:int) :=
 let r:=Int.unsigned row in
 if Z_lt_dec (Int.signed (Znth r base)) 0 then st else
 replace_exemption limits st r (seed_choice base fallback r seed enter).
Definition visited_seed_rows limits base fallback seed enter st lo j rows :=
 fold_left (visit_seed_row limits base fallback seed enter) (sublist lo j rows) st.
Lemma seed_prefix_next limits base fallback seed enter st lo j rows :
 0<=lo<=j -> j<Zlength rows ->
 visited_seed_rows limits base fallback seed enter st lo (j+1) rows=
 visit_seed_row limits base fallback seed enter (visited_seed_rows limits base fallback seed enter st lo j rows) (Znth j rows).
Proof.
 intros;unfold visited_seed_rows;rewrite (sublist_split lo j (j+1)),(sublist_one j),fold_left_app by lia;reflexivity.
Qed.
Lemma row_always_selects_current limits st row next:
 0<=row<Zlength (exempts st) ->
 Znth row (exempts (replace_exemption limits st row next))=Int.repr next.
Proof.
 intro valid;unfold replace_exemption.
 destruct (Int.eq (Znth row (exempts st)) (Int.repr next)) eqn:E;[apply Int.same_if_eq;assumption|].
 destruct (Int.eq (Znth row limits) Int.zero);cbn [exempts];apply upd_Znth_same;assumption.
Qed.
Lemma other_exempt_unchanged limits st row next a :
 0<=row<Zlength (exempts st) -> 0<=a<Zlength (exempts st) -> a<>row ->
 Znth a (exempts (replace_exemption limits st row next))=Znth a (exempts st).
Proof.
 intros;unfold replace_exemption;destruct (Int.eq (Znth row (exempts st)) (Int.repr next));[reflexivity|].
 destruct (Int.eq (Znth row limits) Int.zero);cbn [exempts];rewrite upd_Znth_diff by lia;reflexivity.
Qed.
