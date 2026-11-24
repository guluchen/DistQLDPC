(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix RowTally IndexRowBridge VerifChildVisit SiblingCounters EnabledLoopFacts
 OverlapChildState OverlapColumnState PreparedResidualIndex PreparedMatrixPath PreparedDepthSpec
 PreparedChildCall PreparedSelectedBlocks.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition prefix_set n (words:seq Integers.int):=
 [set q:'I_n | List.existsb (Int.eq (Int.repr (Z.of_nat q))) words].
Lemma literal_prefix_set n (ids:seq 'I_n):
 (Z.of_nat n<=Int.max_signed)%coqZ ->
 @prefix_set n (literal_path ids)=[set q:'I_n | q \in ids].
Proof.
 move=> dim;apply/setP=>q;rewrite /prefix_set !inE;apply/idP/idP.
 - move/List.existsb_exists=>[b [/List.in_map_iff[a [<- included]] eqn]].
   have same:=Int.same_if_eq _ _ eqn.
   have qlt:=elimT ltP (ltn_ord q);have alt:=elimT ltP (ltn_ord a).
   have signed:=f_equal Int.signed same;rewrite !Int.signed_repr in signed;try rep_lia.
   have ->:q=a by apply val_inj;exact:(Nat2Z.inj _ _ signed).
   exact:(as_member included).
 - move=> used;apply/List.existsb_exists;exists (Int.repr (Z.of_nat q));split;last by rewrite Int.eq_true.
   apply List.in_map_iff;exists q;split;first reflexivity.
   elim:ids used=>[|a ids ih] //=.
   by rewrite inE=>/orP[/eqP->|later];[left|right;apply ih].
Qed.

(* The internal C candidate array is the filtered PCM row. Decode the
   actual i-th element and extend the parent's trace by exactly that qubit. *)
Theorem child_extends_protected_prefix n (parent row:seq 'I_n) root st i cur depth:
 let base:=blocked root in let allowed:=[set q:'I_n | Int.eq (Znth (Z.of_nat q) base) Int.zero] in
 let xs:=map Int.unsigned (free_row base (map (@address n) row)) in
 (Z.of_nat n<=Int.max_signed)%coqZ -> Zlength base=Z.of_nat n ->
 uniq row -> uniq parent -> active_prefix depth cur=literal_path parent ->
 (forall q:'I_n,q \in parent -> Znth (Z.of_nat q) base<>Int.zero) ->
 (0<=i<Zlength xs)%coqZ -> same_search st (sibling_state root xs i) ->
 let q:=Znth i xs in let child:=selected st q in let node:=append_qubit cur depth q in
 exists a:'I_n,let ids:=rcons parent a in
 [ /\ q=Z.of_nat a,uniq ids,node=literal_path ids,
    Zlength (blocked child)=Z.of_nat n &
    forall b:'I_n,b \in ids -> Znth (Z.of_nat b) (blocked child)<>Int.zero ].
Proof.
 move=> base allowed xs fits size_ok distinct parent_ok trace used inside state q child node.
 have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by move:fits;change Int.max_signed with 2147483647%coqZ;
   change Int.max_unsigned with 4294967295%coqZ;lia.
 have mem:forall b:'I_n,Znth (Z.of_nat b) base=Int.zero <-> b \in allowed.
 { move=>b;rewrite /allowed inE;split;[by move=>->;rewrite Int.eq_true|exact:Int.same_if_eq]. }
 have [range free]:=@emitted_range_and_availability n row base allowed unsigned size_ok mem.
 have unique:=@emitted_unique n row base allowed unsigned mem distinct.
 have result:=@actual_child_blocks root st xs i range unique free inside state.
 cbn zeta in result;move:result=>[width [one old]].
 have inxs:List.In q xs by exact:(Znth_In _ _ inside).
 have row_values:=@emitted_values n row base allowed unsigned mem.
 change (List.In q (map Int.unsigned (free_row base (map (@address n) row)))) in inxs.
 rewrite row_values in inxs;move/List.in_map_iff:inxs=>[a [addr elem]].
 have yes:a \in allowed by move:(as_member elem);rewrite mem_filter=>/andP[].
 have fresh:a \notin parent by apply/negP=>inc;exact:(used a inc ((proj2 (mem a)) yes)).
 exists a;cbn zeta;split;first by symmetry.
 - by rewrite rcons_uniq fresh parent_ok.
 - rewrite /node /append_qubit trace /literal_path map_rcons addr;by rewrite -cats1.
 - by rewrite width.
 - move=> b;rewrite mem_rcons inE=>/orP[/eqP->|inparent];first by rewrite addr.
   apply old;last exact:(used b inparent).
   change (0<=Z.of_nat b<Zlength base)%coqZ;rewrite size_ok;have lt:=elimT ltP (ltn_ord b);lia.
Qed.
