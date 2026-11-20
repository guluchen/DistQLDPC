Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.VerifToggle.
Definition column (n m q:Z) (h:list Z) := map (fun i=>Znth(Z.of_nat i*n+q) h) (seq 0 (Z.to_nat m)).
Lemma matrix_index n m q i : 0<n -> 0<=q<n -> 0<=i<m ->
 0<=i*n+q<m*n.
Proof. intros;nia. Qed.
Lemma column_length n m q h : 0<=m -> Zlength(column n m q h)=m.
Proof. intros;unfold column;rewrite Zlength_correct,map_length,seq_length,Z2Nat.id by lia;reflexivity. Qed.
Lemma seq_at i m : 0<=i<m -> Znth i (seq 0 (Z.to_nat m))=Z.to_nat i.
Proof. intros Hi;unfold Znth;rewrite if_false by lia;rewrite seq_nth.
 - reflexivity.
 - apply Nat2Z.inj_lt;rewrite !Z2Nat.id by lia;lia.
Qed.
Lemma column_at n m q h i : 0<=i<m -> Znth i (column n m q h)=Znth(i*n+q) h.
Proof. intros Hi;unfold column;rewrite Znth_map by (rewrite Zlength_correct,seq_length,Z2Nat.id by lia;lia).
 rewrite seq_at by lia;rewrite Z2Nat.id by lia;reflexivity.
Qed.

Lemma column_bits n m q h : 0<n -> 0<=m -> 0<=q<n ->
 Zlength h=m*n -> Forall(fun z:Z=>z=0 \/ z=1) h ->
 Forall(fun z:Z=>z=0 \/ z=1) (column n m q h).
Proof.
 intros Hn Hm Hq Hlen Hbits;unfold column;apply Forall_map;apply Forall_forall.
 intros i Hi;apply in_seq in Hi;destruct Hi as [Hlo Hhi];cbn beta;apply (proj1 (Forall_Znth _ _) Hbits).
 rewrite Hlen;apply matrix_index;try assumption.
 split;[lia|]. simpl in Hhi;apply Nat2Z.inj_lt in Hhi;rewrite Z2Nat.id in Hhi by lia;lia.

Qed.
Lemma xor_byte x y : (x=0 \/ x=1) -> (y=0 \/ y=1) ->
 Vint(Int.zero_ext 8 (Int.xor(Int.repr x)(Int.repr y)))=Vint(Int.repr(Z.lxor x y)).
Proof. intros Hx Hy;destruct Hx as [Hx|Hx];destruct Hy as [Hy|Hy];subst;reflexivity. Qed.
Print Assumptions column_bits.
