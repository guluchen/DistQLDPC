(* A successful decision excludes every good vector of weight below d.
   Host callbacks supply suggestions. Only validated cuts can finish a branch. *)
From Coq Require Import List Bool Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPCMDetectors CCWideWords
 CCWideBranch CCWideRefute CCWideRoots CCWideShort
 CCWideLayout CCWideOrbit CCWideIndex.
Import ListNotations. Local Open Scope nat_scope.

Record advice := suggest {
  prepare_index : list packed_row -> nat -> entry;
  propose : nat -> list packed_row -> list (list nat * list nat);
  make_choice : list packed_row -> bits -> bits -> nat -> hint;
  membership : nat -> list column -> bits -> bool
}.

Definition short_both p q rem sy :=
  short_table 2 p rem sy || short_table 3 q rem sy.
Lemma short_both_ok n hs p q : short_correct n hs (short_table 2 p) ->
  short_correct n hs (short_table 3 q) -> short_correct n hs (short_both p q).
Proof.
  intros A B rem e s sy K Sub Sig Bound;unfold short_both.
  rewrite (A rem e s sy K Sub Sig Bound),(B rem e s sy K Sub Sig Bound);reflexivity.
Qed.

Definition skip_tables n hs ls (perms:list(list nat*list nat)) :=
 map (fun pm=>flags n hs ls (fst pm) (snd pm)) perms.
Definition covered (tables:list(list bool)) i :=
 existsb (fun row=>nth i row false) tables.
Lemma covered_safe n hs ls cap perms : n<=378 ->
 root_skip_ok n hs ls cap (covered (skip_tables n hs ls perms)).
Proof.
 intros N i I E B;unfold covered in E;apply existsb_exists in E as [f [F Hit]].
 unfold skip_tables in F;apply in_map_iff in F as [[p inv] [<- _]].
 cbn[fst snd] in Hit;rewrite flag_at in Hit by exact I.
 exact (checked_skip_sound n hs ls p inv cap N i I Hit B).
Qed.
Definition lower_test n hs ls d adv :=
  match d with
  | 0 | 1 => true
  | S (S k) =>
      if (n <=? 378) && (length hs <=? 378) && (length ls <=? 378) then
        let cs := columns n hs ls in
        let rows := map (make_row n cs) hs in
        let read := prepare_index adv rows in
        let tables := skip_tables n hs ls (propose adv n rows) in
        let p2 := membership adv 2 cs in
        index_ok rows read && verify_sums p2 cs 2 none &&
        all_roots (refute (indexed_active (length hs) read) (fun i=>fst(read i))
          (make_choice adv rows) (short_table 2 p2) k) (covered tables)
          (encode (repeat true n)) cs
      else false
  end.

Theorem lower_test_sound n hs ls d adv :
  lower_test n hs ls d adv=true -> forall e, good n hs ls e -> d<=weight n e.
Proof.
  destruct d as [|[|k]];try solve[intros _ e [P _];lia].
  cbn [lower_test];destruct (_ && _ && _)%bool eqn:B;[|discriminate].
  rewrite !andb_true_iff,!Nat.leb_le in B;destruct B as [[N H] L].
  set (cs:=columns _ _ _);set (rows:=map _ _).
  rewrite !andb_true_iff;intros [[Idx T2] R] e G.
  destruct(compiled_index n hs ls (prepare_index adv rows) N H L Idx) as [Act Layout].
  apply (packed_lower_bound n hs ls (indexed_active (length hs) (prepare_index adv rows))
    (fun i=>fst(prepare_index adv rows i)) (make_choice adv rows)
    (short_table 2 (membership adv 2 cs)) k (covered (skip_tables n hs ls (propose adv n rows))) cs (encode (repeat true n)));
    [exact Act|exact Layout| | |
     apply columns_valid;assumption|apply columns_positions| |exact R|exact G].
  - eapply validated_table_sound;try apply columns_positions;try exact T2.
    all: pose proof(columns_valid n hs ls N H L) as C; eapply Forall_impl;[|exact C].
    all: intros c [_ [_ [Sig _]]];exact Sig.
  - apply covered_safe;assumption.
  - intros j J;rewrite encode_nth by (rewrite repeat_length;assumption).
    rewrite (nth_indep _ false true) by (rewrite repeat_length;assumption). apply nth_repeat.
Qed.
