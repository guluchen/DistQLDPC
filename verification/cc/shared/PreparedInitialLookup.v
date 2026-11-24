(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix LevelSearch VerifClosesBody VerifFlipBody VerifLookup HashLookup BuiltLookup
 EnabledCall OverlapColumnState RedundantState NativeFlipPayload NativeDepthFlip SyndromeHash
 PreparedMatrixResponse PreparedMatrixPath PreparedLeafAtPath PreparedReusableBook PreparedPCMLeafVisit.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section FromPCM.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (rowkey:'I_m->int64)
 (rs:'I_n->seq 'I_m) (p:row_policy) (keys:seq int64) (mask:int64) (tab links:seq Z)
 (init:packed_support) (old_blocks:seq Integers.int).
Let base:=table_book keys mask (checksum init) tab links old_blocks.
Hypotheses (dim:(Z.of_nat m<=Int.max_signed)%coqZ) (qubits:Zlength keys=Z.of_nat n)
 (nonempty:(0<Zlength keys)%coqZ)
 (unique:forall q,uniq (rs q)) (inc:forall q,[set r in rs q]=support (col q H))
 (high:forall q:'I_n,Forall (fun row=>(Z.of_nat m<=Int.unsigned row)%coqZ) (extra_rows p (Z.of_nat q)))
 (keyed:forall q:'I_n,Znth (Z.of_nat q) keys=signature rowkey (support (col q H)))
 (encoded:@encoded_at m n k G rs p init) (zero:pcm_response H G rowkey (0:'cV['F_2]_n) init)
 (initial_bounds:book_safe base (words_at init) (odd_count init)).

(* All layout, detector and odd-count requirements at the leaf follow
   from one validated initial representation and its actual flip path.
   Only exclusion of the selected qubits uses the current block state. *)
Theorem reached_leaf_from_initial st (ids:seq 'I_n):
 uniq ids -> Zlength (OverlapColumnState.blocked st)=Zlength keys ->
 (forall q:'I_n,q \in ids -> Znth (Z.of_nat q) (OverlapColumnState.blocked st)<>Int.zero) ->
 @reached_leaf m n k H G rs rowkey keys mask tab links p init
      [set q:'I_n | q \in ids] st (literal_path ids).
Proof.
 move=> different block_count protected.
 have qbound:(Z.of_nat n<=Int.max_signed)%coqZ by rewrite -qubits;exact:(qubits_fit _ _ _ initial_bounds).
 have mfit:(Z.of_nat m<=Int.modulus)%coqZ by move:dim;change Int.max_signed with 2147483647%coqZ;
   change Int.modulus with 4294967296%coqZ;lia.
 have [live same physical]:=@emitted_path_matches_pcm m n k H G rowkey rs p keys qbound
     ids init mfit unique inc high keyed different encoded zero.
 have dis:[disjoint @available_now n st & [set q:'I_n | q \in ids]].
 { rewrite -setI_eq0;apply/eqP/setP=>q;rewrite /available_now !inE.
   case used:(q \in ids);last by rewrite andbF.
   rewrite andbT;apply/negbTE/negP=> free;exact:(protected q used (Int.same_if_eq _ _ free)). }
 have odd:=@count_at_leaf m n k H G (indicator [set q:'I_n | q \in ids]) rowkey _ dim physical.
 have block_width:Zlength (OverlapColumnState.blocked st)=Zlength old_blocks.
 { rewrite block_count;exact:(esym (block_length _ _ _ initial_bounds)). }
 have safe:=@same_book_after_flip keys mask (checksum init) _ tab links old_blocks (OverlapColumnState.blocked st)
      (words_at init) _ (odd_count init) _ initial_bounds same block_width odd.
 have col:=VerifLookup.column_safe _ _ _ initial_bounds 0%coqZ ltac:(change (0<=0<Zlength keys)%coqZ;lia).
 have [_ [_ [_ [_ [_ [_ [width_ok _]]]]]]]:=col.
 have [_ _ same_width _ _]:=same.
 have width_bound:(width (words_at (payload_after p keys init (literal_path ids)))<=Int.max_signed)%coqZ by rewrite same_width;lia.
 by split.
Qed.
End FromPCM.
