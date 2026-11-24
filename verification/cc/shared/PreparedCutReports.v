(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch ColumnParityPCM NativeBoundAlgebra DetectorRank CSSLevelDistance
 DetectorMatrix PackedDetector VerifClosesBody PreparedMatrixPath PreparedLeafAtPath PreparedPrefixKernel
 NativeFlipPayload PreparedMatrixResponse PreparedWitnessWeight PreparedObservedWitness PreparedChildPrefix
 PreparedPCMLeafVisit PreparedInteriorReport OverlapColumnState.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Cuts.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (eligible:seq Integers.int->'cV['F_2]_n->Prop) (st:snapshot) (ids:seq 'I_n)
 (t:packed_support) (rowkey:'I_m->int64).
Let node:=literal_path ids.
Let P:=[set q:'I_n | q \in ids].
Let x:=vector_on (0:'cV['F_2]_n) ids.
Let d:=Z.of_nat (size ids).
Let goal:=recursive_result H S G eligible.
Hypotheses (unique:uniq ids) (fit:(Z.of_nat n<=Int.max_signed)%coqZ)
 (physical:pcm_response H G rowkey x t).

(* The signed subtraction may be negative. Z.odd_sub holds in both
   directions, just like the machine low-bit test. *)
Theorem native_parity_cut_is_empty w tail:
 (forall q:'I_n,odd #|support (col q H)|) -> Z.testbit (w-d-odd_count t)%coqZ 0=true ->
 goal w st node 0%coqZ tail.
Proof.
 move=> columns mask;split;last by split;discriminate.
 move=>target _ best wt _ _.
 have [odd_rep _]:=physical;have count:=proj2 (proj2 odd_rep).
 change (odd_count t=Z.of_nat #|support (H*m x)|) in count.
 have parity:=@parity_from_pcm m n H columns x.
 have weight:#|support x|=size ids by apply selected_path_weight.
 have even:~~odd #|support target|.
 { have [/andP[/eqP closed _] _]:=best;have law:=@parity_from_pcm m n H columns target.
   rewrite closed support_zero cards0 in law;by rewrite -law. }
 rewrite -wt count Z.bit0_odd !Z.odd_sub /d -!Z.bit0_odd !nat_low_bit parity weight (negbTE even) in mask.
 by case:(odd (size ids)) in mask.
Qed.

Theorem early_closed_has_valid_shorter_witness w tail:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N ->
 (0<d<w)%coqZ -> (w<=Zlength tail)%coqZ -> PreparedDepthSpec.active_prefix d tail=node ->
 odd_count t=0%coqZ ->
 goal w st node (if packed_detects (parities (words_at t)) then 3 else 0)%coqZ tail.
Proof.
 move=> orth det rank_ok depth room trace zero;have [rows [packed hash]]:=physical.
 have count:Z.of_nat #|support (H*m x)|=0%coqZ by rewrite -(proj2 (proj2 rows)).
 have closed:H*m x=0 by apply/eqP;rewrite -(@zero_syndrome m n H x) /number_odd count.
 have input:x=indicator P:=path_is_its_indicator unique.
 split.
 - rewrite /node literal_prefix_set //;move=>target _ best wt sub _.
   exfalso;apply:(@closed_prefix_rules_out_minimum m n k H G ids target unique _ _ _ closed best).
   + apply/eqP=>empty;move:depth;by rewrite /d empty /=;lia.
   + by rewrite (path_is_its_indicator unique) support_indicator.
   + apply/ltP;unfold d in depth;lia.
 - split;first by case:(packed_detects _);discriminate.
   case detected:(packed_detects _);last discriminate;move=>_.
   exists d;split;first exact depth.
   have logical:MinimumPrefix.logical H G x by rewrite /MinimumPrefix.logical closed eqxx -(packed_matrix_nonzero packed) detected.
   have [_ outside weight bound]:=@witnessed_half_distance_bound m r k n H S G ids orth det rank_ok unique logical.
   rewrite /stored_css_prefix trace /node literal_prefix_set // -input weight;split=> //;try lia;by split.
Qed.
End Cuts.
