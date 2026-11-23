(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect perm.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section OrbitSeed.
Variable Q : finType.
Variable orbit_index : Q -> nat.
Variable representative : nat -> Q.
Variable logical : {set Q} -> bool.

(* Each claimed orbit has a coordinate automorphism taking a given member
   to its representative. Applying it preserves each orbit and validity.
   The producer must supply these facts for its computed permutations. *)
Hypothesis certified : forall q : Q, exists p : {perm Q},
  [ /\ p q = representative (orbit_index q),
       forall a, orbit_index (p a) = orbit_index a &
       forall S, logical S -> logical (p @: S) ].

Theorem representative_covers S : logical S -> S != set0 ->
  exists (i : nat) (T : {set Q}),
    [ /\ logical T, #|T| = #|S|, representative i \in T &
         forall a, a \in T -> i <= orbit_index a ].
Proof.
move=> good /set0Pn [q0 q0S].
case: (@arg_minnP Q q0 (mem S) orbit_index q0S) => q qS first.
have [p [at_rep preserves valid]] := certified q.
exists (orbit_index q), (p @: S); split.
- exact: valid.
- by rewrite card_imset //; exact: perm_inj.
- rewrite -at_rep; exact: imset_f.
- move=> a /imsetP[b member ->]; rewrite preserves; exact: first.
Qed.
End OrbitSeed.
