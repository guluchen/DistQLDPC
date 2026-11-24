(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifLookup VerifOneLeft
 HashLookup HashProbe LeafMatrix LevelSearch ClosureMatrix SyndromeHash LeafAPI PCMLeafAPI
 TableFlow BuiltLookup BuiltPCM RedundantState SparseSyndrome NativeFlipPayload EnabledCall OverlapSharedBlocks
 OverlapView OverlapColumnState PreparedMatrixResponse PreparedMatrixPath PreparedChildCall PreparedTerminalTrace
 PreparedPairDispatch PreparedPairStorage PreparedOpenPair PreparedLookupMatrix PreparedPairBracket
 PreparedPairLedger PreparedPairEvent PreparedClosedBracket PreparedClosedPair PreparedClosedPairMemory PreparedAnswerFrame PreparedPhysicalPair PackedDetector
 LeafShortcut CSSLevelDistance PreparedDepthSpec PreparedPairCSS PreparedWitnessRegister.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section LiveTraversal.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (P F:{set 'I_n})
 (rs:'I_n->seq 'I_m) (rowkey:'I_m->int64).
Variables (c:policy_state) (st:snapshot) (t:packed_support) (policy:row_policy) (ks:seq int64)
 (mask:int64) (cap bits:Z) (tab links:seq Z) (s cp:Values.val) (p:lookup_ptrs).
Let v:=words_at t.
Let b:=table_book ks mask (checksum t) tab links (OverlapColumnState.blocked st).
Let has_completion:=pcm_completion H L P F.
Hypotheses (built:history ks mask cap (-1)%coqZ tab links) (npositive:(0<Zlength ks)%coqZ)
 (qubits:Zlength ks=Z.of_nat n) (spare:(Zlength ks<cap)%coqZ)
 (period:cap=(2^bits)%coqZ) (bits_ok:(0<=bits<64)%coqZ) (mask_ok:mask=Int64.repr (Z.ones bits))
 (disjoint:[disjoint F & P]) (free:forall q:'I_n,Znth (Z.of_nat q) (OverlapColumnState.blocked st)=Int.zero <-> q \in F)
 (fits:(Z.of_nat m<=Int.modulus)%coqZ) (unique:forall q,uniq (rs q))
 (incidence:forall q,[set r in rs q]=support (col q H))
 (enc:@encoded_at m n k L rs policy t)
 (colkeys:forall q:'I_n,Znth (Z.of_nat q) ks=signature rowkey (support (col q H)))
 (response:pcm_response H L rowkey (indicator P) t)
 (safe:odd_count t<>0%coqZ -> book_safe b v (odd_count t)) (alias:pb p=blockp (conn c)).


(* Use one allocation through each branch. The unused statistic and
   hash table are returned intact even after a shorter logical closure. *)
Theorem run_both_fast_paths depth q children count i options cells closed leaves saved:
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 (0<=odd_count t<=Int.max_signed)%coqZ -> (Zlength (parities v)<=Int.max_signed)%coqZ ->
 let w:=(depth+2)%coqZ in let next:=upd_Znth depth cells (Int.repr q) in
 let seen:=packed_detects (parities v) in let locs:=descent_loc c s depth q children count i options false in
 let store:=pair_storage c s cp w st in
 let before:=store cells t policy p ks mask tab links closed leaves saved in
 let after:=fun a=>let counts:=pair_counts closed leaves a in
    store (pair_path depth next a) t policy p ks mask tab links counts.1 counts.2 (pair_size depth saved seen a) in
 semax pair_delta (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [::before]))) child_bracket
 (normal_ret_assert (EX a:option Z,PROPx
 [::match a with Some z=>odd_count t<>0%coqZ /\ leaf_answer has_completion (Z.of_nat n) z | None=>odd_count t=0%coqZ end;
    active_prefix (depth+1)%coqZ (pair_path depth next a)=append_qubit cells depth q;
    Zlength (pair_path depth next a)=Zlength cells;
    (0<=pair_code seen a<=3)%coqZ;
    witness_at_limit w saved (pair_code seen a) (pair_size depth saved seen a) (pair_path depth next a)]
 (LOCALx (temp _result (Vint (Int.repr (pair_code seen a)))::locs) (SEPx [::after a])))).
Proof.
 move=> depth_ok room odd_bounds word_bounds w next seen locs store before after.
 destruct (Z.eq_dec (odd_count t) 0) as [zero|nonzero].
 - have raw:=@closed_bracket_saves_current_child Espec c s cp st t policy (pk p) ks closed saved depth q
     children count i options cells depth_ok room zero word_bounds.
   have framed:=@semax_frame' Espec VerifDetected.CompSpecs _ _ _ _ _ _ _ _
        (outside_closed_lookup s p mask tab links leaves) raw.
   eapply semax_post'.
   2:{ eapply semax_pre;last exact framed.
       unfold before,store,locs,descent_loc;rewrite lend_to_closed;cbn [app];entailer!;cancel;try apply derives_refl. }
   have [length_ok [prefix [range reg]]]:=@stored_child_survives_pair depth q cells seen None saved depth_ok room.
   Exists (@None Z);unfold after,store,locs,descent_loc;cbn [pair_code pair_path pair_size pair_counts fst snd];
    rewrite lend_to_closed;entailer!;try cancel;try apply derives_refl;auto.
 - have with_lookup:=safe nonzero.
   have raw:=@physical_pair_bracket Espec m n k H L P F rs rowkey c st t policy ks mask cap bits tab links
     s cp p built npositive qubits spare period bits_ok mask_ok disjoint free fits unique incidence enc colkeys
     response with_lookup alias depth q children count i options cells leaves saved depth_ok room ltac:(lia).
   have framed:=frame_answer _ _ _ _ _ _ _ _
     (@field_at VerifDetected.CompSpecs Tsh level_type [StructField _closed] (Vlong closed) s) raw.
   eapply semax_post'.
   2:{ eapply semax_pre;last exact framed.
       unfold before,store,locs,descent_loc;rewrite lend_to_open;cbn [app];entailer!;cancel;try apply derives_refl. }
   Intros z.
   have [length_ok [prefix [range reg]]]:=@stored_child_survives_pair depth q cells seen (Some z) saved depth_ok room.
   Exists (Some z);unfold after,store,locs,descent_loc;cbn [pair_code pair_path pair_size pair_counts fst snd];
    rewrite lend_to_open;entailer!;try cancel;try apply derives_refl;auto.
Qed.
End LiveTraversal.
