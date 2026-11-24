(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import SeedPolicyView SeedColumnModel SeedTransferTrace.
Local Open Scope Z_scope.

Definition touches_row (base:list int) (k:Z) (row:int):bool :=
 let r:=Int.unsigned row in if Z_lt_dec (Int.signed (Znth r base)) 0 then false else Z.eqb k r.
Definition touched g seed i k:=existsb (touches_row (base_order g) k)
 (sublist (index_at g seed) i (col_rows g)).
Lemma touched_next g seed i k:0<=index_at g seed<=i -> i<Zlength (col_rows g) ->
 touched g seed (i+1) k=orb (touched g seed i k) (touches_row (base_order g) k (Znth i (col_rows g))).
Proof.
 intros;unfold touched;rewrite (sublist_split (index_at g seed) i (i+1)),(sublist_one i),existsb_app by lia.
 cbn [existsb];rewrite orb_false_r;reflexivity.
Qed.
Lemma visit_sets_one_row limits base fb seed enter st word k:
 0<=k<Zlength (exempts st) ->
 (0<=Int.signed (Znth (Int.unsigned word) base) -> 0<=Int.unsigned word<Zlength (exempts st)) ->
 Znth k (exempts (visit_seed_row limits base fb seed enter st word))=
 if touches_row base k word then Int.repr (seed_choice base fb k seed enter) else Znth k (exempts st).
Proof.
 intros pos valid;unfold visit_seed_row,touches_row;destruct Z_lt_dec;[reflexivity|].
 destruct (Z.eqb k (Int.unsigned word)) eqn:eq.
 - apply Z.eqb_eq in eq;subst k;apply row_always_selects_current;assumption.
 - apply Z.eqb_neq in eq;apply other_exempt_unchanged;auto;apply valid;lia.
Qed.

Lemma seed_prefix_cell g limits enter seed st k i :
 column_safe g limits enter seed st -> 0<Zlength (reference_counts st) ->
 index_at g seed<=i<=index_at g (seed+1) -> 0<=k<Zlength (exempts st) ->
 Znth k (exempts (prefix g limits enter seed st i)) =
 if touched g seed i k then Int.repr (seed_choice (base_order g) (first_block g) k seed enter)
 else Znth k (exempts st).
Proof.
 intros valid has_blocks bounds live;pose proof valid as full.
 destruct valid as [qok [room [span [cap valid]]]].
 set (lo:=index_at g seed) in *;set (hi:=index_at g (seed+1)) in *.
 remember (Z.to_nat (i-lo)) as n eqn:len;revert i len bounds.
 induction n as [|n IH];intros i len bounds.
 - assert (i=lo) by lia;subst i;unfold prefix,visited_seed_rows,touched;fold lo;rewrite sublist_nil by lia;reflexivity.
 - set (j:=i-1);assert (step:lo<=j<hi) by (unfold j;lia).
   specialize (IH j ltac:(unfold j;lia) ltac:(lia)).
   pose proof (prefix_preserves_credit g limits enter seed st 0 j full ltac:(lia) ltac:(lia)) as [[er _] _].
   specialize (valid j step);destruct valid as [rpos [_ safe]].
   replace i with (j+1) by (unfold j;lia);rewrite touched_next by lia.
   unfold prefix at 1;rewrite seed_prefix_next by lia;fold (prefix g limits enter seed st j).
   rewrite visit_sets_one_row. 2:{ rewrite er;exact live. }
   2:{ intro active;specialize (safe active);destruct safe as [r_ok _];split;[lia|exact r_ok]. }
   rewrite IH;destruct (touches_row (base_order g) k (Znth j (col_rows g))), (touched g seed j k);reflexivity.
Qed.

Definition full_column g limits enter seed st:=prefix g limits enter seed st (index_at g (seed+1)).
(* Event counters can change in the recursive search. Its search state must
   restore before the seed exit callback runs. *)
Theorem native_seed_roundtrip g limits seed initial resumed :
 let entered:=full_column g limits true seed initial in
 let left:=full_column g limits false seed resumed in
 column_safe g limits true seed initial -> column_safe g limits false seed resumed ->
 0<Zlength (reference_counts initial) ->
 exempts resumed=exempts entered -> reference_counts resumed=reference_counts entered ->
 (forall k,0<=k<Zlength (exempts initial) -> touched g seed (index_at g (seed+1)) k=true ->
   Znth k (exempts initial)=Int.repr (seed_choice (base_order g) (first_block g) k seed false)) ->
 exempts left=exempts initial /\ reference_counts left=reference_counts initial.
Proof.
 intros entered left on off width ex_eq block_eq rest;set (hi:=index_at g (seed+1)).
 assert (bounds:index_at g seed<=hi<=index_at g (seed+1)) by
   (destruct on as [_ [_ [[_ bound] _]]];unfold hi;lia).
 pose proof (prefix_preserves_credit g limits true seed initial 0 hi on bounds ltac:(lia)) as [[e1 b1] _].
 change (Zlength (exempts entered)=Zlength (exempts initial)) in e1.
 change (Zlength (reference_counts entered)=Zlength (reference_counts initial)) in b1.
 assert (res_width:0<Zlength (reference_counts resumed)) by (rewrite block_eq,b1;assumption).
 pose proof (prefix_preserves_credit g limits false seed resumed 0 hi off bounds ltac:(lia)) as [[e2 b2] _].
 change (Zlength (exempts left)=Zlength (exempts resumed)) in e2.
 change (Zlength (reference_counts left)=Zlength (reference_counts resumed)) in b2.
 assert (ex_back:exempts left=exempts initial).
 { apply Znth_eq_ext;[congruence|]. intros k kr;rewrite e2,ex_eq,e1 in kr.
   unfold left,full_column;fold hi.
   rewrite (seed_prefix_cell g limits false seed resumed k hi off res_width bounds ltac:(rewrite ex_eq,e1;assumption)).
   destruct (touched g seed hi k) eqn:hit;[symmetry;apply rest;assumption|].
   rewrite ex_eq;unfold entered,full_column;fold hi.
   rewrite seed_prefix_cell by assumption;rewrite hit;reflexivity. }
 split;[exact ex_back|];apply Znth_eq_ext;[congruence|].
 intros q index;rewrite b2,block_eq,b1 in index.
 pose proof (prefix_preserves_credit g limits true seed initial q hi on bounds index) as [_ E].
 pose proof (prefix_preserves_credit g limits false seed resumed q hi off bounds ltac:(rewrite block_eq,b1;assumption)) as [_ F].
 change (conserved q limits entered=conserved q limits initial) in E.
 change (conserved q limits left=conserved q limits resumed) in F;unfold conserved in E,F.
 rewrite ex_back,ex_eq,block_eq in F;rewrite E in F.
 apply (f_equal (fun x=>Int.add x (Int.neg (Int.repr (credits q limits (exempts initial)))))) in F.
 rewrite !Int.add_assoc,Int.add_neg_zero,!Int.add_zero in F;exact F.
Qed.
