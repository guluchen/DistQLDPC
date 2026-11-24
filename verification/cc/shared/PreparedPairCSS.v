(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch LeafShortcut CSSLevelDistance DetectorRank PCMLeafAPI LeafAPI
 VerifDetected VerifChildVisit VerifClosesBody VerifOneLeft EnabledCall OverlapColumnState NativeFlipPayload
 PreparedChildCall PreparedDepthSpec PreparedMatrixPath PreparedPairDispatch PreparedOpenPair PreparedPairTrace
 PreparedWitnessRegister.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section ConcreteAnswer.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m k r n:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (L:'M['F_2]_(k,n)) (F:{set 'I_n})
 (ids:seq 'I_n) (c:policy_state) (s cp:Values.val) (st:snapshot) (payload:packed_support)
 (b:HashLookup.lookup_data) (p:VerifLookup.lookup_ptrs) (policy:VerifFlipBody.row_policy).
Variables (parent_depth q:Z) (children:Values.val) (cnt i:Z) (bits:Integers.int)
 (cells:seq Integers.int) (leaves:int64) (saved:Integers.int).
Let depth:=(parent_depth+1)%coqZ.
Let w:=(parent_depth+2)%coqZ.
Let P:=[set j:'I_n | j \in ids].
Let node:=upd_Znth parent_depth cells (Int.repr q).
Let locs:=descent_loc c s parent_depth q children cnt i bits false.
Let state:=fun path l sv=>active_pair c s cp w st path payload policy b p l sv.
Let tail:=fun z=>last_path depth z node.
Let prior:=PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [::state cells leaves saved])).
Let after (z:Z) (facts:Prop):=PROPx [::facts] (LOCALx
 (temp _result (Vint (Int.repr (final_pick z)))::locs)
 (SEPx [::state (tail z) (Int64.add leaves Int64.one) (last_size w z saved)])).
Hypotheses (dim:depth=Z.of_nat (size ids)) (unique:uniq ids)
 (stored:active_prefix depth node=literal_path ids) (fit:(0<w<=Int.max_signed)%coqZ) (room:(depth<Zlength node)%coqZ)
 (orth:H*m S^T=0) (det:L*m S^T=0) (rank_ok:(\rank (col_mx H L)+\rank S=n)%N).

Theorem final_lookup_reports_css_witness:
 semax pair_delta prior child_bracket (normal_ret_assert (EX z:Z,after z (leaf_answer (pcm_completion H L P F) (Z.of_nat n) z))) ->
 semax pair_delta prior child_bracket (normal_ret_assert (EX z:Z,after z
  (witness_at_limit w saved (final_pick z) (last_size w z saved) (tail z) /\
   ((z=(-1)%coqZ /\ forall a:'I_n,a \in F -> ~~terminal H L (size ids).+1 (a |: P)) \/
   exists a:'I_n,let x:=indicator (a |: P) in
    [ /\ z=Z.of_nat a,active_prefix w (tail z)=literal_path (rcons ids a),H*m x=0,
      ~~(x^T<=S)%MS & #|support x|=(size ids).+1 /\ (distance_index H (detectors S)<=(size ids).+1)%N ])))).
Proof.
 move=> evaluated;eapply semax_post';last exact evaluated.
 Intros z;unfold after;Intros.
 have branch:=@lookup_trace_and_distance m r k n H S L F ids node z orth det rank_ok unique
   ltac:(rewrite -dim;exact room) ltac:(rewrite -dim;exact stored) ltac:(eassumption).
 have offset:w=(depth+1)%coqZ by unfold w,depth;lia.
 have record:=@open_pair_register w depth z saved node fit ltac:(rewrite offset;lia)
   ltac:(split;[rewrite dim;lia|exact room]).
 rewrite -dim -offset in branch.
 Exists z;unfold locs,descent_loc;entailer!;try apply derives_refl;try exact record;try exact branch;try tauto.
Qed.
End ConcreteAnswer.
