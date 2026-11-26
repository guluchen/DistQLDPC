(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix LevelSearch PreparedMatrixPath PreparedChildPrefix
 PreparedDepthSpec PreparedLeafAtPath PreparedObservedWitness PreparedReplayAddresses.
Import GRing.Theory.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

(* The C loop reads the first d signed entries of cur and accumulates
   the corresponding row-major input bytes with XOR. *)
Fixpoint scan_row (bytes:seq bool) (words:seq Integers.int) (n r:Z) (k:nat):bool:=
 match k with
 | O=>false
 | S j=>xorb (scan_row bytes words n r j)
   (Znth (r*n+Int.signed (Znth (Z.of_nat j) words))%coqZ bytes)
 end.
Lemma scan_same_prefix bytes n r k xs ys:
 (forall j,(j<k)%N -> Znth (Z.of_nat j) xs=Znth (Z.of_nat j) ys) ->
 scan_row bytes xs n r k=scan_row bytes ys n r k.
Proof.
 elim:k=>[|k ih] agree //=.
 rewrite ih;last by move=>j ltj;apply:agree;exact:ltn_trans ltj (ltnSn k).
 by rewrite (agree k (ltnSn k)).
Qed.

Lemma xor_coefficients (a b:'F_2):xorb (a!=0) (b!=0)=(a+b!=0).
Proof.
 have cases (v:'F_2):v=0 \/ v= 1.
 { case:v=>j small;case:j small=>[|[|j]] small;[left|right|];try by apply:val_inj.
   by []. }
 have two:(1+1:'F_2)=0 by rewrite -[X in _+X=_](oppr_char2 (char_Fp (erefl:prime 2)) 1) addrN.
 case:(cases a)=>->;case:(cases b)=>->;by rewrite ?add0r ?addr0 ?two ?eqxx ?oner_eq0.
Qed.

Section RawRows.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (bytes:seq bool).
Hypotheses (fits:(Z.of_nat n<=Int.max_signed)%coqZ)
 (row_major:forall (r:'I_m) (j:'I_n),Znth (Z.of_nat r*Z.of_nat n+Z.of_nat j)%coqZ bytes=(H r j!=0)).
Lemma scan_physical_row (r:'I_m) (ids:seq 'I_n):
 scan_row bytes (literal_path ids) (Z.of_nat n) (Z.of_nat r) (size ids)=
 ((H*m vector_on (0:'cV['F_2]_n) ids) r 0!=0).
Proof.
 elim/last_ind:ids=>[|ids q ih].
 - by rewrite /= /vector_on /= mulmx0 mxE eqxx.
 - rewrite size_rcons /literal_path map_rcons -cats1;fold (literal_path ids).
   cbn [scan_row].
   have length:Zlength (literal_path ids)=Z.of_nat (size ids)
     by rewrite /literal_path Zlength_map Zlength_correct.
   have prefix:scan_row bytes (literal_path ids++[::Int.repr (Z.of_nat q)]) (Z.of_nat n) (Z.of_nat r) (size ids)=
     scan_row bytes (literal_path ids) (Z.of_nat n) (Z.of_nat r) (size ids).
   { apply:scan_same_prefix=>j ltj;rewrite app_Znth1 // length;apply Nat2Z.inj_lt;exact:(elimT ltP ltj). }
   have range:=elimT ltP (ltn_ord q).
   rewrite prefix ih app_Znth2;last by rewrite length;lia.
   rewrite length Z.sub_diag;change (Znth 0%coqZ [::Int.repr (Z.of_nat q)]) with (Int.repr (Z.of_nat q)).
   rewrite Int.signed_repr;last by change Int.min_signed with (-2147483648)%coqZ;lia.
   by rewrite row_major xor_coefficients /vector_on foldl_rcons mulmxDr -colE !mxE.
Qed.
Lemma stored_signed_coordinate s (S:'M['F_2]_(s,n)) d path:
 stored_css_prefix H S d path -> forall i,(0<=i<d)%coqZ ->
 (0<=Int.signed (Znth i path)<Z.of_nat n)%coqZ.
Proof.
 move=>witness i inside;have [ids [_ [word_path _]]]:=physical_replay_indices fits witness.
 have [bounds _ _ _]:=witness.
 have used:List.In (Znth i path) (active_prefix d path).
 { have idx:(0<=i<Zlength (active_prefix d path))%coqZ by rewrite /active_prefix Zlength_sublist;lia.
   have hit:=@Znth_In Integers.int ltac:(typeclasses eauto) i (active_prefix d path) idx.
   move:hit;rewrite /active_prefix Znth_sublist;try lia.
   by rewrite Z.add_0_r. }
 rewrite -word_path /literal_path in used.
 move/List.in_map_iff:used=>[q [<- _]];have range:=elimT ltP (ltn_ord q).
 rewrite Int.signed_repr;first lia.
 change Int.min_signed with (-2147483648)%coqZ;lia.
Qed.
Theorem replay_of_stored_witness s (S:'M['F_2]_(s,n)) d path:
 stored_css_prefix H S d path -> forall r:'I_m,
 scan_row bytes path (Z.of_nat n) (Z.of_nat r) (Z.to_nat d)=false.
Proof.
 move=>witness r;have [ids [unique [path_value path_weight]]]:=physical_replay_indices fits witness.
 have [bounds closed _ _]:=witness.
 have dk:Z.to_nat d=size ids by rewrite -path_weight Nat2Z.id.
 rewrite dk;transitivity (scan_row bytes (literal_path ids) (Z.of_nat n) (Z.of_nat r) (size ids)).
 - apply:scan_same_prefix=>j ltj;have small:=elimT ltP ltj.
   rewrite path_value /active_prefix Znth_sublist;try lia.
   by rewrite Z.add_0_r.
 - rewrite scan_physical_row (path_is_its_indicator unique).
   rewrite -path_value literal_prefix_set // in closed.
   by rewrite closed mxE eqxx.
Qed.
End RawRows.
