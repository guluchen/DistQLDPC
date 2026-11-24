(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifLookup VerifOneLeft
 HashLookup HashProbe LeafMatrix LevelSearch ClosureMatrix SyndromeHash LeafAPI PCMLeafAPI
 TableFlow BuiltLookup BuiltPCM RedundantState SparseSyndrome NativeFlipPayload EnabledCall OverlapSharedBlocks
 OverlapView OverlapColumnState PreparedMatrixResponse PreparedMatrixPath PreparedChildCall PreparedTerminalTrace
 PreparedPairDispatch PreparedPairStorage PreparedOpenPair PreparedLookupMatrix PreparedPairBracket
 LeafShortcut CSSLevelDistance PreparedDepthSpec PreparedPairCSS PreparedWitnessRegister.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Physical.
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
 (safe:book_safe b v (odd_count t)) (alias:pb p=blockp (conn c)).

(* The constructed index and active PCM determine the leaf answer.
   The C statements store the current child and, on success, the last
   qubit selected by the lookup. No answer or enumeration of hits is
   supplied to the procedure. *)
Theorem physical_pair_bracket depth q children count i options cells leaves saved:
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 (0<odd_count t<=Int.max_signed)%coqZ ->
 let w:=(depth+2)%coqZ in let next:=upd_Znth depth cells (Int.repr q) in
 let locs:=descent_loc c s depth q children count i options false in
 let state:=fun path l sv=>active_pair c s cp w st path t policy b p l sv in
 semax pair_delta (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs)
   (SEPx [::state cells leaves saved]))) child_bracket
 (normal_ret_assert (EX a:Z,PROPx [::leaf_answer has_completion (Z.of_nat n) a]
  (LOCALx (temp _result (Vint (Int.repr (final_pick a)))::locs)
   (SEPx [::state (last_path (depth+1)%coqZ a next)
      (Int64.add leaves Int64.one) (last_size w a saved)])))).
Proof.
 move=> bound len odd w next locs state.
 have columns:forall a:'I_n,@ClosureMatrix.layout m n k H L (indicator P) a (rs a) v.
 { move=>a;have aj:=elimT ltP (ltn_ord a).
   have valid:(0<=Z.of_nat a<Zlength (keys b))%coqZ by change (0<=Z.of_nat a<Zlength ks)%coqZ;rewrite qubits;lia.
   have [_ [_ [bounds [ends _]]]]:=VerifLookup.column_safe _ _ _ safe _ valid.
   have [csr [_ [column [width room]]]]:=enc a.
   exact:(@matrix_view_for_lookup m n k H L (indicator P) rowkey a (rs a) t fits (unique a)
     (incidence a) (conj bounds ends) csr column width response). }
 have [rows [detector hash]]:=response.
 have actual:odd_count t=Z.of_nat #|support (H*m indicator P)| by exact:(proj2 (proj2 rows)).
 have [qs image]:=@constructor_pcm_image m n k H L P F v rs rowkey ks mask (checksum t) cap bits tab links
   (OverlapColumnState.blocked st) built npositive qubits spare period bits_ok mask_ok disjoint free columns hash colkeys.
 rewrite -actual in image.
 have blen:Zlength (OverlapColumnState.blocked st)=Zlength ks by exact:(block_length _ _ _ safe).
 have inside:(depth+1<Zlength next)%coqZ by unfold next;rewrite upd_Znth_Zlength;lia.
 have claim:=@lookup_with_live_parent Espec c s cp st next t policy b p leaves saved depth has_completion qs
    ltac:(lia) alias ltac:(reflexivity) ltac:(reflexivity) bound inside odd safe image.
 have extent_ok:extent b=Z.of_nat n by exact qubits.
 rewrite extent_ok in claim.
 unfold locs,state,w,next.
 apply (@run_two_move_bracket Z Espec c s cp depth q children count i options cells
   (@field_at VerifDetected.CompSpecs Tsh level_type [StructField _w] (Vint (Int.repr (depth+2)%coqZ)) s *
    @field_at VerifDetected.CompSpecs Tsh level_type [StructField _blk] (blockp (conn c)) s * cols c st * pointers c *
    packed_mem s (pk p) policy (keys b) t * lookup_index s b p * pair_statistics s leaves saved)%logic
    (fun path=>state path leaves saved) (leaf_answer has_completion (Z.of_nat n)) final_pick
    (fun a=>state (last_path (depth+1)%coqZ a next) (Int64.add leaves Int64.one) (last_size w a saved)));
    [exact bound|exact len| |exact claim].
 intro path;unfold state,w,active_pair,enabled_memory,level_links,terminal_trace.
 apply pred_ext;cancel.
Qed.

Corollary stored_pair_from_pcm r (S:'M['F_2]_(r,n)) (ids:seq 'I_n)
 depth q children count i options cells leaves saved:
 H*m S^T=0 -> L*m S^T=0 -> (\rank (col_mx H L)+\rank S=n)%N ->
 P=[set a:'I_n | a \in ids] -> uniq ids -> (depth+1)%coqZ=Z.of_nat (size ids) ->
 active_prefix (depth+1)%coqZ (upd_Znth depth cells (Int.repr q))=literal_path ids ->
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 (0<odd_count t<=Int.max_signed)%coqZ ->
 let w:=(depth+2)%coqZ in let node:=upd_Znth depth cells (Int.repr q) in
 let tail:=fun z=>last_path (depth+1)%coqZ z node in
 let locs:=descent_loc c s depth q children count i options false in
 let state:=fun path l sv=>active_pair c s cp w st path t policy b p l sv in
 semax pair_delta (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs)
   (SEPx [::state cells leaves saved]))) child_bracket
 (normal_ret_assert (EX z:Z,PROPx [::witness_at_limit w saved (final_pick z) (last_size w z saved) (tail z) /\
   ((z=(-1)%coqZ /\ forall a:'I_n,a \in F -> ~~terminal H L (size ids).+1 (a |: P)) \/
    exists a:'I_n,let x:=indicator (a |: P) in
    [ /\ z=Z.of_nat a,active_prefix w (tail z)=literal_path (rcons ids a),H*m x=0,
      ~~(x^T<=S)%MS & #|support x|=(size ids).+1 /\ (distance_index H (detectors S)<=(size ids).+1)%N ])]
  (LOCALx (temp _result (Vint (Int.repr (final_pick z)))::locs)
   (SEPx [::state (tail z) (Int64.add leaves Int64.one) (last_size w z saved)])))).
Proof.
 move=> orth det rank_ok members unique_ids dim trace bound len odd w node tail locs state.
 have enough:(depth+1<Zlength node)%coqZ by unfold node;rewrite upd_Znth_Zlength;lia.
 have run:=@physical_pair_bracket depth q children count i options cells leaves saved bound len odd.
 unfold has_completion in run;rewrite members in run *.
 apply (@final_lookup_reports_css_witness Espec m k r n H S L F ids c s cp st t b p policy
   depth q children count i options cells leaves saved dim unique_ids trace ltac:(lia) enough orth det rank_ok run).
Qed.
End Physical.
