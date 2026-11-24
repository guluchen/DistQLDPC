(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch ClosureMatrix VerifClosesBody VerifFlipBody
 RedundantState FlipRoundtrip DetectorMatrix NativeFlipPayload PreparedMatrixResponse PreparedRowCoverage PreparedResidualIndex.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Lemma csr_member_position (row:Integers.int) (store:seq Integers.int) lo hi:
 ((0<=lo<=hi)%coqZ /\ (hi<=Zlength store)%coqZ) -> List.In row (sublist lo hi store) ->
 exists i,(lo<=i<hi)%coqZ /\ Znth i store=row.
Proof.
 move=> range member.
 have [j [less value]]:=List.In_nth (sublist lo hi store) row (@default Integers.int _) member.
 rewrite nth_Znth' in value.
 have len:Zlength (sublist lo hi store)=(hi-lo)%coqZ by rewrite Zlength_sublist;lia.
 rewrite Zlength_correct in len;exists (Z.of_nat j+lo)%coqZ;split;first lia.
 rewrite -(Znth_sublist lo (Z.of_nat j) hi store);[exact value|lia|lia].
Qed.

Section View.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (x:'cV['F_2]_n)
 (rowkey:'I_m->int64) (q:'I_n) (rs:seq 'I_m) (payload:packed_support).
Let v:=words_at payload.
Let j:=Z.of_nat q.
Let lo:=Znth j (offsets v).
Let hi:=Znth (j+1)%coqZ (offsets v).

(* Both closing_qubit and flip see the same CSR entries, packed syndrome
   and detector columns. Derive the lookup view from those live arrays. *)
Theorem matrix_view_for_lookup:
 (Z.of_nat m<=Int.modulus)%coqZ -> uniq rs -> [set r in rs]=support (col q H) ->
 ((0<=lo<=hi)%coqZ /\ (hi<=Zlength (rows v))%coqZ) -> column_list v j=map (@encode m) rs ->
 represents (col_slice v j) (col q L) -> size (parities v)=size (col_slice v j) ->
 pcm_response H L rowkey x payload ->
 @ClosureMatrix.layout m n k H L x q rs v.
Proof.
 move=> dim unique incidence range csr column width [odd [logical hash]].
 change (sublist lo hi (rows v)=map (@encode m) rs) in csr.
 have len:(hi-lo)%coqZ=Z.of_nat (size rs).
 { have z:=f_equal (@Zlength Integers.int) csr;rewrite Zlength_sublist ?Zlength_map in z;try lia.
   by rewrite Zlength_correct in z. }
 constructor=> //.
 - move=> r live;apply:csr_member_position;first exact range.
   rewrite csr;apply/List.in_map_iff;exists r;split=> //;exact:member_as_in.
 - move=> i within.
   have hit:List.In (Znth i (rows v)) (sublist lo hi (rows v)).
   { change (lo<=i<hi)%coqZ in within.
     have at_index:=Znth_sublist lo (i-lo)%coqZ hi (rows v) ltac:(lia) ltac:(lia).
     replace (i-lo+lo)%coqZ with i in at_index by lia.
     rewrite -at_index;apply Znth_In;rewrite Zlength_sublist;lia. }
   rewrite csr in hit;case/List.in_map_iff:hit=>r [<- present].
   exists r;split;[exact:as_member|reflexivity].
 - move=> r member;exact:(proj1 (proj2 odd) r).
Qed.
End View.
