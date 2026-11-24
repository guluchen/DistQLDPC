(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import SeedExemptionState SeedColumnModel SeedPolicyView ExemptionRollback SiblingCounters.
Local Open Scope Z_scope.

Definition eq_cell a (x:int):Z := if Z.eq_dec a (Int.signed x) then 1 else 0.
Definition exemption_credit a (limit x:int):Z := if Int.eq limit Int.zero then eq_cell a x else 0.
Fixpoint credits a (limits xs:list int):Z :=
 match limits,xs with l::ls,v::vs=>exemption_credit a l v+credits a ls vs | _,_=>0 end.
Lemma changed_credit a limits xs r v :
 Zlength xs=Zlength limits -> 0<=r<Zlength xs ->
 credits a limits (upd_Znth r xs v) =
 credits a limits xs + exemption_credit a (Znth r limits) v - exemption_credit a (Znth r limits) (Znth r xs).
Proof.
 revert limits r;induction xs as [|x xs IH];intros [|l ls] r size live;
  rewrite ?Zlength_cons,?Zlength_nil in *;try lia.
 destruct (Z.eq_dec r 0) as [->|ne].
 - rewrite upd_Znth0,!Znth_0_cons;cbn [credits];lia.
 - rewrite upd_Znth_cons,!Znth_pos_cons by lia;cbn [credits];rewrite IH by lia;lia.
Qed.

(* A zero-limit row has one unit of credit at its exempt qubit. The sum
   with the machine's block count is independent of the chosen exemption. *)
Definition conserved a limits st :=
 Int.add (Znth a (reference_counts st)) (Int.repr (credits a limits (exempts st))).
Lemma preserves_credit limits st r next a :
 0<=r<Zlength (exempts st) -> Zlength (exempts st)=Zlength limits ->
 0<=a<Zlength (reference_counts st) -> 0<=next<=Int.max_signed ->
 next<Zlength (reference_counts st) ->
 0<=Int.signed (Znth r (exempts st))<Zlength (reference_counts st) ->
 conserved a limits (replace_exemption limits st r next)=conserved a limits st.
Proof.
 intros row len key machine next_live old_live;unfold replace_exemption.
 destruct (Int.eq (Znth r (exempts st)) (Int.repr next));[reflexivity|].
 destruct (Int.eq (Znth r limits) Int.zero) eqn:zero;
 unfold conserved;cbn [reference_counts exempts];rewrite changed_credit by assumption;
 unfold exemption_credit;rewrite zero.
 - set (old:=Int.signed (Znth r (exempts st))) in *.
   change (reassign_blocks (reference_counts st) old next) with
    (move_in true (reference_counts st) (old,next)).
   rewrite one_move_cell by (unfold legal_move;cbn;lia).
   rewrite Int.add_assoc,add_encoded;unfold contribution,eq_cell;fold old.
   rewrite Int.signed_repr by rep_lia;cbn [fst snd].
   destruct (Z.eq_dec a old),(Z.eq_dec a next);f_equal;f_equal;lia.
 - rewrite Z.add_0_r,Z.sub_0_r;reflexivity.
Qed.

Definition same_shape st t :=
 Zlength (exempts t)=Zlength (exempts st) /\ Zlength (reference_counts t)=Zlength (reference_counts st).
Lemma replace_shape limits st row next :
 0<=row<Zlength (exempts st) -> 0<=next<Zlength (reference_counts st) ->
 0<=Int.signed (Znth row (exempts st))<Zlength (reference_counts st) ->
 same_shape st (replace_exemption limits st row next).
Proof.
 intros;unfold same_shape,replace_exemption;destruct Int.eq;[auto|];destruct Int.eq;
 cbn [exempts reference_counts];rewrite upd_Znth_Zlength by lia;split;try reflexivity.
 unfold reassign_blocks;rewrite !length_adjust by (rewrite ?length_adjust;lia);reflexivity.
Qed.
Definition conserved_scan a limits st t := same_shape st t /\ conserved a limits t=conserved a limits st.
Lemma prefix_preserves_credit g limits enter seed st a i :
 column_safe g limits enter seed st ->
 index_at g seed<=i<=index_at g (seed+1) -> 0<=a<Zlength (reference_counts st) ->
 conserved_scan a limits st (prefix g limits enter seed st i).
Proof.
 intros safe upto key;destruct safe as [seed_ok [seed_end [bounds [end_ok safe]]]].
 set (lo:=index_at g seed) in *;set (hi:=index_at g (seed+1)) in *.
 remember (Z.to_nat (i-lo)) as k eqn:distance;revert i distance upto.
 induction k as [|k IH];intros i distance upto.
 - assert (i=lo) by lia;subst i;unfold conserved_scan,same_shape,prefix,visited_seed_rows;fold lo.
   rewrite sublist_nil by lia;cbn [fold_left];auto.
 - set (j:=i-1);assert (step:lo<=j<hi) by (unfold j;lia).
   specialize (IH j ltac:(unfold j;lia) ltac:(lia));destruct IH as [[er br] conserved_j].
   specialize (safe j step);set (t:=prefix g limits enter seed st j) in *.
   replace i with (j+1) by (unfold j;lia).
   unfold prefix at 1;rewrite seed_prefix_next by lia;fold (prefix g limits enter seed st j);fold t.
   unfold visit_seed_row;set (r:=Int.unsigned (Znth j (col_rows g))) in *.
   destruct (Z_lt_dec (Int.signed (Znth r (base_order g))) 0);[unfold conserved_scan,same_shape;auto|].
   destruct safe as [rlo [_ actual]];specialize (actual ltac:(lia)).
   destruct actual as [rlen [aligned [machine [next_ok old_ok]]]].
   pose proof (replace_shape limits t r (seed_choice (base_order g) (first_block g) r seed enter)
     ltac:(lia) ltac:(lia) old_ok) as [er' br'].
   unfold conserved_scan,same_shape;split;[split;congruence|].
   rewrite preserves_credit by (try assumption;lia);exact conserved_j.
Qed.
