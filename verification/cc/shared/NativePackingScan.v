(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifMarkRow RowTally RowMarkSemantics IndexRowBridge.
From mathcomp Require Import all_ssreflect.
Require Import IndexPacking.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Delimit Scope Z_scope with coqZ.
Section Pack.
Variables n:nat.
Variable R:finType.
Variables (inc:R->seq 'I_n) (free:{set 'I_n}) (blocks:seq Integers.int) (stamp:int64).
Hypothesis cap:(Z.of_nat n<=Int.max_unsigned)%coqZ.
Hypothesis free_ok:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free.
Definition encoded r:=map (@address n) (inc r).
Definition neighbors r:=[set q in inc r].
Definition tags_for (ms:seq int64) (M:{set 'I_n}) :=
 Zlength ms=Z.of_nat n /\ forall q:'I_n,Znth (Z.of_nat q) ms=stamp <-> q \in M.
Definition mark r ms := fold_left (mark_word stamp) (encoded r) ms.
Lemma index_bounded r (q:Integers.int) : List.In q (encoded r) -> (Int.unsigned q<Z.of_nat n)%coqZ.
Proof.
move/List.in_map_iff=>[a [<- _]];rewrite unsigned_address //;have:=elimT ltP (ltn_ord a);lia.
Qed.
Lemma stored_index r (q:'I_n) : List.In (Z.of_nat q) (map Int.unsigned (encoded r)) <-> q \in inc r.
Proof.
rewrite /encoded;elim:(inc r)=>[|a xs IH] /=.
- intuition.
- rewrite inE unsigned_address //.
  split.
  + case=>[same|/IH ->];last by rewrite orbT.
    have eqaq:a=q by apply val_inj;change ((a:nat)=(q:nat));apply Nat2Z.inj;exact same.
    by rewrite eqaq eqxx.
  + move/orP=>[/eqP ->|/IH tail];[by left|by right].
Qed.
Lemma mark_view r ms M : tags_for ms M -> tags_for (mark r ms) (M :|: neighbors r).
Proof.
move=> [len represents].
have bounded:Forall (fun q=> (Int.unsigned q<Zlength ms)%coqZ) (encoded r).
  apply Forall_forall=>q inside;rewrite len;exact:index_bounded inside.
split;first by rewrite /mark marked_words_length.
move=>q;have inside:(0<=Z.of_nat q<Zlength ms)%coqZ by rewrite len;have:=elimT ltP (ltn_ord q);lia.
rewrite /mark mark_set_union // stored_index represents /neighbors !inE.
split;first by case=> ->;rewrite ?orbT.
by move/orP=> [old|hr];[right|left].
Qed.
Definition count_nonzero r :=
 negb (Int.eq (Int.repr (Zlength (free_row blocks (encoded r)))) Int.zero).
Hypothesis row_limit:forall r,(Zlength (encoded r)<=Int.max_unsigned)%coqZ.
Lemma counted_has r : count_nonzero r=(neighbors r :&: free != set0).
Proof.
rewrite /count_nonzero /encoded (physical_free_row cap free_ok).
case e:([seq q <- inc r | q \in free])=>[|a rest].
- have zero:neighbors r :&: free=set0.
    apply/setP=>q;rewrite /neighbors !inE;apply/negbTE/negP=>/andP[member avail].
    have inlist:q \in [seq t <- inc r | t \in free] by rewrite mem_filter member avail.
    by move:inlist;rewrite e.
  by rewrite zero eqxx.
- have upper: (Zlength (a::rest)<=Int.max_unsigned)%coqZ.
    have bound:=filtered_length blocks (encoded r);have limit:=@row_limit r.
    rewrite /encoded (physical_free_row cap free_ok) e !Zlength_map in bound.
    rewrite /encoded Zlength_map in limit.
    change (0<=Zlength (List.map (@address n) (a::rest))<=Zlength (inc r))%coqZ in bound.
    rewrite Zlength_map in bound;exact (@Z.le_trans _ _ _ (proj2 bound) limit).
  change (~~Int.eq (Int.repr (Zlength (List.map (@address n) (a::rest)))) Int.zero=(neighbors r :&: free != set0)).
  rewrite Zlength_map;have nz:Int.eq (Int.repr (Zlength (a::rest))) Int.zero=false.
    apply Int.eq_false;move/(congr1 Int.unsigned).
    have positive:(0<Zlength (a::rest))%coqZ by rewrite Zlength_cons;apply Z.lt_succ_r;apply Zlength_nonneg.
    rewrite Int.unsigned_repr;[change (Zlength (a::rest) = 0 -> False)%coqZ;lia|split;[lia|exact upper]].
  rewrite nz /=;apply/esym/set0Pn;exists a.
  have member:a \in [seq q <- inc r | q \in free] by rewrite e inE eqxx.
  move:member;rewrite mem_filter /neighbors !inE;by move/andP=> [-> ->].
Qed.
Fixpoint cpu_scan (budget:nat) (rows:seq R) ms (packed:nat) :=
 if rows is r::rs then
   if count_nonzero r then
     if row_clash blocks ms stamp (encoded r) then cpu_scan budget rs ms packed
     else (packed.+1<=budget)%N && cpu_scan budget rs (mark r ms) packed.+1
   else false
 else true.
Theorem agrees_with_packing budget rs ms M p : tags_for ms M ->
 cpu_scan budget rs ms p=scan neighbors free budget rs M p.
Proof.
elim:rs ms M p=>[|r rs IH] ms M p valid //=.
rewrite /choices counted_has;case:(_ == set0)=> //=.
have clash:=@clash_is_disjoint n free M blocks ms stamp cap free_ok (proj2 valid) (inc r).
rewrite -clash;case c:(row_clash blocks ms stamp (encoded r))=> /=.
- exact:IH valid.
- by rewrite (IH _ _ _ (mark_view r valid)).
Qed.
End Pack.
