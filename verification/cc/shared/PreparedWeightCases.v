(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance DetectorRank PreparedMatrixPath
 PreparedLeafAtPath PreparedMatrixResponse PreparedWitnessWeight PreparedObservedWitness
 PreparedRecursiveCall PreparedChildPrefix PreparedPCMLeafVisit PreparedLeafReport PreparedInteriorReport
 PreparedCSSTerminal PreparedTerminalPoll PreparedDeadline PreparedDepthSpec OverlapColumnState.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Classification.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (choose:seq Integers.int->'cV['F_2]_n->Prop) (ids:seq 'I_n) (st:snapshot).
Let node:=literal_path ids.
Let P:=[set q:'I_n | q \in ids].
Let F:=@available_now n st.
Let goal:=recursive_result H S G choose.
Hypotheses (fits:(Z.of_nat n<=Int.max_signed)%coqZ) (unique:uniq ids).

Lemma pair_at_actual_budget code tail:
 let w:=(Z.of_nat (size ids)+2)%coqZ in
 (forall x,minimum H G x -> #|support x|=(#|P|).+2 -> P \subset support x ->
       support x :\: P \subset F -> code<>0%coqZ) ->
 (code=0%coqZ \/ (witness_status code /\ stored_css_prefix H S (reported_len w code) tail)) ->
 goal w st node code tail.
Proof.
 move=>w keeps status;have size_ok:#|P|=size ids by rewrite /P cardsE (card_uniqP unique).
 split.
 - rewrite /node literal_prefix_set //;move=>x _ best weight sub free;apply:(keeps x best _ sub free).
   rewrite size_ok;apply Nat2Z.inj;rewrite !Nat2Z.inj_succ;exact weight || lia.
 - split.
   + move=>found;subst code;case:status=>[//|[_ valid]];exact valid.
   + move=>short;subst code;case:status=>[//|[_ valid]];exists (w-1)%coqZ;split;last exact valid.
     unfold w;lia.
Qed.

Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (rank_ok:(\rank (col_mx H G)+\rank S=n)%N).
Let d:=Z.of_nat (size ids).
Let x:=vector_on (0:'cV['F_2]_n) ids.
Lemma closed_minimum_at_weight target:
 minimum H G target -> Z.of_nat #|support target|=d -> P \subset support target ->
 target=x.
Proof.
 move=> best wt sub;apply binary_support_inj;unfold x;rewrite (path_is_its_indicator unique) support_indicator.
 have count:#|P|=size ids by rewrite /P cardsE (card_uniqP unique).
 have equal:#|support target|=#|P| by apply Nat2Z.inj;rewrite count;exact wt.
 symmetry;apply/eqP;by rewrite eqEcard sub equal leqnn.
Qed.

(* At depth equal to the current level, the compiled result word and
   possibly padded trace already satisfy the same recursive contract.
   A poll that signals interruption remains distinguishable from EMPTY. *)
Lemma terminal_at_actual_budget event tail:
 (0<d<=Zlength tail)%coqZ -> active_prefix d tail=node ->
 goal d st node (Int.signed (@result_word m r n H S ids event)) tail.
Proof.
 move=> room trace.
 have input: x=indicator P := path_is_its_indicator unique.
 set yes:=((H*m x==0) && ~~(x^T<=S)%MS)%bool.
 have answer:(Int.signed (@result_word m r n H S ids event))=
     (if abort_answer event then 2 else if yes then 1 else 0)%coqZ.
 { change (Int.signed (if abort_answer event then Int.repr 2 else if yes then Int.one else Int.zero)=
     (if abort_answer event then 2 else if yes then 1 else 0)%coqZ).
   destruct (abort_answer event);[reflexivity|destruct yes;reflexivity]. }
 rewrite answer;clear answer;case interrupted:(abort_answer event);first by split;[intros;lia|split;discriminate].
 split.
 - rewrite /node literal_prefix_set //;move=>y _ best weight sub _.
   have same:=closed_minimum_at_weight best weight sub.
   have good:yes.
   { have logical:=proj1 best;rewrite same in logical.
     rewrite (@validated_logical m r k n H S G orth det rank_ok) in logical.
     by move:logical;rewrite /yes /MinimumPrefix.logical detector_rowspan. }
   by rewrite good.
 - split;last by case:yes;discriminate.
   case live:yes;last discriminate;move=>_.
   have /andP[/eqP closed outside]:=live.
   have valid:MinimumPrefix.logical H G x.
   { rewrite (@validated_logical m r k n H S G orth det rank_ok);by rewrite /MinimumPrefix.logical detector_rowspan closed eqxx outside. }
   have [_ _ size_ok lower]:= @witnessed_half_distance_bound m r k n H S G ids orth det rank_ok unique valid.
   rewrite /stored_css_prefix trace /node literal_prefix_set // -input size_ok;by split=> //;split.
Qed.
End Classification.
