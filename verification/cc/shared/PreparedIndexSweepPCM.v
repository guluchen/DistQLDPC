(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto WordScan PreparedIndexSweep PreparedIndexWhile PreparedIndexAdvance.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedIndexWords PreparedIndexAdmission NativePackingScan LeafMatrix
 CSRWordTraversal SparseSyndrome SparseFlipBits.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Fixpoint physical_order wi (plan:seq (seq Z)) :=
 if plan is bits::later then
 (map (Z.add (64*wi)%coqZ) bits)++physical_order (wi+1)%coqZ later else [::].

Lemma plan_traces_words wi words plan :
 List.Forall2 scan_word words plan -> row_order (64*wi)%coqZ words (physical_order wi plan).
Proof.
 move=>pairs;elim:pairs wi=>[|word bits ws later run correct ih] wi;first constructor.
 cbn [physical_order];constructor=> //.
 replace (64*wi+64)%coqZ with (64*(wi+1))%coqZ by lia;exact:ih.
Qed.

Section Decoding.
Variable m:nat.
Let row_number (r:'I_m):=Z.of_nat r.
Inductive word_groups : Z -> seq (seq Z) -> seq 'I_m -> Prop :=
| end_groups wi : word_groups wi nil nil
| next_group wi bits later group tail :
  List.Forall2 (fun ix (r:'I_m)=>(64*wi+ix)%coqZ=row_number r) bits group ->
  word_groups (wi+1)%coqZ later tail ->
  word_groups wi (bits::later) (group++tail).

Lemma decode_group wi bits rest (rows:seq 'I_m) :
 map (Z.add (64*wi)%coqZ) bits++rest=map row_number rows ->
 exists group tail, rows=group++tail /\ rest=map row_number tail /\
 List.Forall2 (fun ix r=>(64*wi+ix)%coqZ=row_number r) bits group.
Proof.
 elim:bits rows=>[|a later ih] rows.
 - move=>same;exists [::],rows;repeat split=> //;constructor.
 - case:rows=>[|r rs] //=;move=>eqs;injection eqs=>first second.
   have [group [tail [split [left pairs]]]]:=ih rs ltac:(assumption).
   exists (r::group),tail;split;first by rewrite split.
   split=> //;constructor=> //.
Qed.

Lemma decoded_groups wi plan (physical:seq 'I_m) :
 physical_order wi plan=map row_number physical -> word_groups wi plan physical.
Proof.
 elim:plan wi physical=>[|bits later ih] wi physical /=.
 - case:physical=> //;constructor.
 - move/decode_group=>[group [tail [-> [rest matches]]]].
   apply:next_group matches _;exact:ih rest.
Qed.
End Decoding.

Section SemanticSweep.
Variables m n:nat.
Variables (rows:'I_m->seq 'I_n) (H:'M['F_2]_(m,n)) (prefix:'cV['F_2]_n) (free:{set 'I_n}).
Variables (blocks cols:seq Integers.int) (offsets:seq Z) (stamp:int64) (budget:nat) (dep w:Z).
Hypotheses (fits:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (available:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free)
 (covers:forall r q,H r q!=0 -> q \in rows r)
 (width:forall r,(Zlength (encoded rows r)<=Int.max_unsigned)%coqZ)
 (table:forall r:'I_m,sublist (Znth (Z.of_nat r) offsets) (Znth (Z.of_nat r+1)%coqZ offsets) cols=encoded rows r)
 (remaining:(w-dep)%coqZ=Z.of_nat budget).
Variables (first:'I_m) (rest:seq 'I_m) (initial:seq int64) (marked:{set 'I_n}).
Hypotheses (initial_tags:@tags_for n stamp initial marked)
 (all_odd:{subset first::rest <= support (H*m prefix)}).
Let reached:=reaches_row rows blocks stamp budget (first::rest) initial 0.

Theorem sweep_preserves_pcm wi plan physical pending b p ms :
 word_groups wi plan physical -> reached (physical++pending) ms p ->
 match sweep offsets cols blocks stamp dep w wi plan b (Z.of_nat p) ms with
 | EmptyRow _ | TooManyRows _=>no_completion H prefix free budget
 | AllBits picked count tags=>picked=selected_branch b physical /\
     exists q,count=Z.of_nat q /\ reached pending tags q /\ (q<=budget)%N
 end.
Proof.
 move=>groups;elim:groups b p ms=>[wi0|wi0 bits later group tail pairs groups ih] b p ms history.
 - split=> //;exists p;split=> //;split=> //;exact:count_within_budget history (leq0n _).
 - cbn [sweep];rewrite -catA in history.
   have ok:=@word_preserves_pcm m n rows H prefix free blocks cols offsets stamp budget wi0 dep w fits available
     covers width table remaining first rest initial marked initial_tags all_odd bits group (tail++pending)
     b p ms pairs history.
   case value:(scan_bits offsets cols blocks stamp wi0 dep w bits b (Z.of_nat p) ms) ok=>[picked count tags| |] //=.
   move=>[-> [q [-> [next room]]]].
   have result:=ih (selected_branch b group) q tags next.
   case:(sweep offsets cols blocks stamp dep w (wi0+1)%coqZ later (selected_branch b group) (Z.of_nat q) tags) result
     =>[final packed last| |] //=.
   have compose (g t:seq 'I_m):selected_branch (selected_branch b g) t=selected_branch b (g++t).
   { case:g=>[|r others] //=;exact:keep_first_physical. }
   by rewrite compose.
Qed.
End SemanticSweep.

(* Start with C's row and packing sentinels and the physical syndrome,
   without assuming which physical row the selector will choose. *)
Theorem sweep_from_syndrome m n (rows:'I_m->seq 'I_n) (H:'M['F_2]_(m,n))
 (prefix:'cV['F_2]_n) (free:{set 'I_n}) blocks cols offsets stamp budget dep w
 words count initial (marked:{set 'I_n}) :
 (Z.of_nat n<=Int.max_unsigned)%coqZ ->
 (forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free) ->
 (forall r q,H r q!=0 -> q \in rows r) ->
 (forall r,(Zlength (encoded rows r)<=Int.max_unsigned)%coqZ) ->
 (forall r:'I_m,sublist (Znth (Z.of_nat r) offsets) (Znth (Z.of_nat r+1)%coqZ offsets) cols=encoded rows r) ->
 (w-dep)%coqZ=Z.of_nat budget -> @tags_for n stamp initial marked ->
 stores_odd (words,count) (support (H*m prefix)) -> clear_padding (Z.of_nat m) words -> (0<count)%coqZ ->
 exists plan,List.Forall2 scan_word words plan /\
 match sweep offsets cols blocks stamp dep w 0 plan (-1) 0 initial with
 | EmptyRow _ | TooManyRows _=>no_completion H prefix free budget
 | AllBits branch value tags=>exists first rest,
    physical_order 0 plan=map (fun r:'I_m=>Z.of_nat r) (first::rest) /\ first \in support (H*m prefix) /\
    branch=Z.of_nat first /\ exists q,value=Z.of_nat q /\
      reaches_row rows blocks stamp budget (first::rest) initial 0 nil tags q /\ (q<=budget)%N
 end.
Proof.
 move=>cap avail cover width table amount marks stored pad live.
 have [plan run]:=plans_for_words words;exists plan;split=> //.
 have decoded:=@plan_traces_words 0 words plan run.
 have [first [rest [order [dark _]]]]:=
   @physical_branch_from_words m words count (support (H*m prefix)) (physical_order 0 plan) stored pad decoded live.
 have groups:=@decoded_groups m 0 plan (first::rest) order.
 have start:reaches_row rows blocks stamp budget (first::rest) initial 0 ((first::rest)++nil) initial 0
   by rewrite cats0;constructor.
 have checked:=@sweep_preserves_pcm m n rows H prefix free blocks cols offsets stamp budget dep w
   cap avail cover width table amount first rest initial marked marks dark 0 plan (first::rest) nil
   (-1)%coqZ 0 initial groups start.
 case verdict:(sweep offsets cols blocks stamp dep w 0 plan (-1) 0 initial) checked=>[branch value tags| |] //=.
 move=>[b physical];exists first,rest;split=> //;split;first by apply dark;rewrite inE eqxx.
 by split.
Qed.
