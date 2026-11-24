(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix LevelSearch CSSLevelDistance DetectorRank ValidatedHalfStart PreparedObservedWitness
 SeedExecution RootDriver PreparedSeed SeedLoopModel PreparedDepthSpec PreparedInteriorReport
 PreparedRootWitness PreparedSourceDriver.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Bounded.
Variables m n r:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)).
Let actual:=Z.of_nat (distance_index H (detectors S)).

Lemma stored_trace_is_upper_bound len words:
 stored_css_prefix H S len words -> (actual<=len)%coqZ.
Proof.
 move=>[_ _ _ [size bound]];unfold actual;rewrite -size;apply Nat2Z.inj_le;exact:(elimT leP bound).
Qed.

(* A prior certified lower bound makes an early, shorter witness
   impossible. If that premise is absent, its actual length still gives
   a valid upper bound. An EMPTY advances the lower bound by one. *)
Theorem certified_level_verdict w code tail:
 (w<=actual)%coqZ -> (code=0%coqZ -> w<>actual) ->
 (code = 1%coqZ -> stored_css_prefix H S w tail) ->
 (code = 3%coqZ -> exists len,(0<len<w)%coqZ /\ stored_css_prefix H S len tail) ->
 [ /\ code=0%coqZ -> (w+1<=actual)%coqZ,
      code = 1%coqZ -> w=actual /\ stored_css_prefix H S w tail &
      code<>3%coqZ ].
Proof.
 move=> lower empty found shorter;split.
 - move=>status;have excl:=empty status;lia.
 - move=>hit;have checked:=found hit;have upper:=stored_trace_is_upper_bound checked;by split=> //;lia.
 - move=>early;have [len [range ok]]:=shorter early;have bound:=stored_trace_is_upper_bound ok;lia.
Qed.

(* Both X and Z may close the distance first. The other half's lower
   bound, as maintained by the driver, determines when to return. *)
Lemma combine_two_certified_halves other other_lower w:
 (other_lower<=other)%coqZ -> (w<=other_lower)%coqZ -> w=actual -> Z.min actual other=w.
Proof. move=>lower done equal;subst w;apply Z.min_l;lia. Qed.
End Bounded.

Section SearchResult.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (qualified:seq Integers.int->'cV['F_2]_n->Prop) (e:seed_level) (initial:root_state).
Let w:=weight e.
Let ans:=root_projection (recursive_report H S G qualified w).
Let sched:=PreparedSourceDriver.schedule e ans initial.
Let d:=Z.of_nat (distance_index H (detectors S)).

(* Apply the physical seed postcondition to the half distance, using
   the same detector rank validation as the host. *)
Theorem checked_stop_updates_half_bounds i code:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N ->
 (w<=d)%coqZ -> stop_at sched i code -> (code=0%coqZ -> w<>Z.of_nat (distance_index H G)) ->
 [ /\ code=0%coqZ -> (w+1<=d)%coqZ,
      code = 1%coqZ -> w=d /\ exists st,PreparedSourceDriver.left_root e ans initial i code st /\
              stored_css_prefix H S w (witness_path st) &
      code<>3%coqZ ].
Proof.
 move=> orth det rank_ok lower stopped excludes.
 have same:=@validated_distance m r k n H S G orth det rank_ok.
 have next:code=0%coqZ -> (w+1<=d)%coqZ.
 { move=> empty;have impossible:=excludes empty;rewrite same in impossible;unfold d in *;lia. }
 have observed:code<>0%coqZ -> exists st,PreparedSourceDriver.left_root e ans initial i code st.
 { case:stopped=> [[_ empty]|[_ [_ actual]]];[by move=> n0;contradiction|by move=>_]. }
 split=> //.
 - move=> hit;have [st run]:=observed ltac:(lia).
   have [found short]:=@root_keeps_found_witness m n r k H S G qualified e initial i code st run.
   have record:=found hit;have upper:=stored_trace_is_upper_bound record.
   split;[unfold d in *;lia|by exists st].
 - move=> smaller;have [st run]:=observed ltac:(lia).
   have [_ short]:=@root_keeps_found_witness m n r k H S G qualified e initial i code st run.
   have [len [range ok]]:=short smaller;have impossible:=stored_trace_is_upper_bound ok;unfold d in *;lia.
Qed.
End SearchResult.
