(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance DetectorRank DetectorMatrix PackedDetector
 VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody NativeFlipPayload EnabledCall OverlapColumnState
 PreparedDepthSpec PreparedChildCall PreparedMatrixResponse PreparedMatrixPath PreparedWitnessWeight PreparedDFSTerminal
 PreparedPairDispatch PreparedClosedPair PreparedClosedBracket PreparedWitnessRegister.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Shorter.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m k r n:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)) (rowkey:'I_m->int64)
 (ids:seq 'I_n) (c:policy_state) (s cp:Values.val) (st:snapshot) (t:packed_support) (policy:row_policy)
 (addr:Values.val) (ks:seq int64) (visits:int64) (saved:Integers.int).
Let x:=vector_on (0:'cV['F_2]_n) ids.
Let words:=parities (words_at t).
Let detected_now:=packed_detects words.
Theorem shorter_witness_from_pcm depth q children count i opts cells:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N ->
 uniq ids -> pcm_response H G rowkey x t -> odd_count t=0%coqZ ->
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 (Zlength words<=Int.max_signed)%coqZ -> (depth+1)%coqZ=Z.of_nat (size ids) ->
 append_qubit cells depth q=literal_path ids ->
 let w:=(depth+2)%coqZ in let next:=upd_Znth depth cells (Int.repr q) in
 let rcode:=if detected_now then 3%coqZ else 0%coqZ in
 let sv:=if detected_now then Int.repr (depth+1)%coqZ else saved in
 let state:=fun path count prior=>closed_pair_heap c s cp w st path t policy addr ks count prior in
 let locs:=descent_loc c s depth q children count i opts false in
 semax pair_delta (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [::state cells visits saved])))
 child_bracket (normal_ret_assert (PROPx [::active_prefix (depth+1)%coqZ next=literal_path ids;
 witness_at_limit w saved rcode sv next;H*m x=0;
 rcode=3%coqZ -> ~~(x^T<=S)%MS /\ #|support x|=size ids /\ (distance_index H (detectors S)<=size ids)%N]
 (LOCALx (temp _result (Vint (Int.repr rcode))::locs) (SEPx [::state next (Int64.add visits Int64.one) sv])))).
Proof.
 move=> orth det rank_ok unique physical shut fit enough size_ok len trace w next rcode sv state locs.
 have checked:=@closed_bracket_saves_current_child Espec c s cp st t policy addr ks visits saved depth q
   children count i opts cells fit enough shut size_ok.
 have [rows [logical hash]]:=physical.
 have odd:Z.of_nat #|support (H*m x)|=0%coqZ by rewrite -(proj2 (proj2 rows)).
 have closed:H*m x=0.
 { apply/eqP;rewrite -(@zero_syndrome m n H x);unfold number_odd;by rewrite odd. }
 have register:witness_at_limit w saved rcode sv next.
 { apply closed_pair_register;[unfold w;lia|unfold next;rewrite upd_Znth_Zlength;lia]. }
 have value:rcode=3%coqZ -> ~~(x^T<=S)%MS /\ #|support x|=size ids /\
                          (distance_index H (detectors S)<=size ids)%N.
 { unfold rcode,detected_now;rewrite (packed_matrix_nonzero logical).
   case found:(G*m x!=0);last by discriminate.
   move=>_;have yes:MinimumPrefix.logical H G x by rewrite /MinimumPrefix.logical closed eqxx found.
   have [_ outside weight bound]:=@witnessed_half_distance_bound m r k n H S G ids orth det rank_ok unique yes.
   by split=> //;split. }
 eapply semax_post';last exact checked.
 have stored:active_prefix (depth+1)%coqZ next=literal_path ids by unfold next;rewrite stored_prefix;[exact trace|lia].
 unfold locs,descent_loc,state,rcode,sv,detected_now,words;Intros;entailer!;try apply derives_refl;auto.
Qed.
End Shorter.
