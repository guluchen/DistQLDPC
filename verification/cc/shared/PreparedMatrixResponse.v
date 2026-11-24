(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix DetectorMatrix ClosureMatrix ToggleModel VerifClosesBody VerifToggleBody VerifFlipBody
 SparseSyndrome FlipRoundtrip RedundantState SyndromeHash NativeFlipPayload PreparedDFSTerminal.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Matrix.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (rowkey:'I_m->int64).
Variables (p:row_policy) (keys:list int64).

Definition pcm_response x t:=
 stores_odd (syndrome (words_at t),odd_count t) (support (H *m x)) /\
 represents (parities (words_at t)) (L *m x) /\ checksum t=signature rowkey (support (H *m x)).


Theorem native_column_response x (q:'I_n) t (rs:seq 'I_m):
 let v:=words_at t in let j:=Z.of_nat q in
 (Z.of_nat m<=Int.modulus)%coqZ -> uniq rs -> [set r in rs]=support (col q H) ->
 column_list v j=map (@encode m) rs ->
 Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows p j) ->
 Forall (fun r=>(Int.unsigned r<64*Zlength (syndrome v))%coqZ) (extra_rows p j) ->
 represents (col_slice v j) (col q L) -> size (parities v)=size (col_slice v j) ->
 Znth j keys=signature rowkey (support (col q H)) -> pcm_response x t ->
 pcm_response (x+delta_mx q 0) (step_support p keys j t).
Proof.
move=> v j dim distinct column csr high bounded detector same key [odd [logical hash]].
have [primary [next_detector next_key]]:=@toggle_pcm m n k H L x q v rs rowkey (odd_count t) (checksum t) keys
 dim distinct column csr odd logical detector same hash key.
set first:=after_primary v j (odd_count t).
change (stores_odd first (support (H *m (x+delta_mx q 0)))) in primary.
have word_cap: Zlength first.1=Zlength (syndrome v) by apply flip_length.
split.
- change (stores_odd (after_extra p j first.1,first.2) (support (H *m (x+delta_mx q 0)))).
  apply extra_preserves_physical;[by rewrite -(surjective_pairing first)|exact high|by rewrite word_cap].
- by split;[exact next_detector|exact next_key].
Qed.

Corollary physical_terminal x t: pcm_response x t ->
 leaf_accept (odd_count t) (parities (words_at t))=((H *m x==0) && (L *m x!=0)).
Proof.
move=> [[_ [_ count]] [logical _]];cbn [snd] in count;rewrite count.
exact:(@dfs_leaf_accept_pcm m n k H L x _ logical).
Qed.
End Matrix.
