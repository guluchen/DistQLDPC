(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifLowestBit VerifMarkRow
 PreparedIndexWordStep PreparedIndexAdvance PreparedIndexIteration PreparedIndexBitBody
 WordScan LowestWord ClightSelect ClightNested flag_level_ast.
Local Open Scope Z_scope.

Definition tests_odd_word (st:statement) :=
 match st with
 | Sloop (Ssequence (Sifthenelse (Etempvar id _) Sskip Sbreak) _) Sskip => Pos.eqb id _odd
 | _=>false end.
Definition odd_loop:statement:=ltac:(native_while_fragment tests_odd_word f_index_children).
Lemma odd_loop_shape:odd_loop=Swhile (Etempvar _odd tulong) active_word_iteration.
Proof. reflexivity. Qed.

Inductive scan_exit :=
| AllBits (branch packed:Z) (tags:list int64)
| EmptyRow (tags:list int64)
| TooManyRows (tags:list int64).

Definition resume_scan (step:row_result) old row branch (next:Z->Z->list int64->scan_exit) :=
 match step with
 | NoCandidate=>EmptyRow old
 | PackingExceeded=>TooManyRows old
 | ContinueRow p tags=>next (first_row branch row) p tags
 end.

Section Scan.
Variables (s op cp bp mp:val) (offsets:list Z) (cols blocks:list int) (stamp:int64)
 (wi dep w:Z) (nc pk:int64).
Let lo r:=Znth r offsets.
Let hi r:=Znth (r+1) offsets.
Definition safe_index_row r:=0<=r<Int.max_signed /\ r+1<Zlength offsets /\
 0<=lo r<=hi r /\ hi r<=Int.max_unsigned /\ hi r<=Zlength cols /\
 (forall j,lo r<=j<hi r->Int.unsigned (Znth j cols)<Zlength blocks).
Definition row_state_ok branch p (ms:list int64) := -1<=branch<=Int.max_signed /\
 0<=p<=w-dep /\ Zlength ms=Zlength blocks.

Fixpoint scan_bits offsets_in_word branch packed marks:=
 match offsets_in_word with
 | nil=>AllBits branch packed marks
 | ix::rest=>let r:=64*wi+ix in
   resume_scan (run_row blocks marks stamp cols (lo r) (hi r) packed (w-dep))
      marks r branch (scan_bits rest)
 end.

Lemma step_stays_in_range r before p ms q next :
 safe_index_row r -> row_state_ok before p ms ->
 run_row blocks ms stamp cols (lo r) (hi r) p (w-dep)=ContinueRow q next ->
 row_state_ok (first_row before r) q next.
Proof.
 intros [fits [off [range [cap [within ix]]]]] [branch [packed length]].
 unfold first_row,run_row;cbv zeta;destruct (Int.eq _ _);[discriminate|].
 destruct (Int.eq _ _).
 - destruct Z_lt_dec;[discriminate|].
   intro E;inversion E;subst;unfold row_state_ok;destruct Z_lt_dec;
     repeat split;try lia;rewrite <-length;apply mark_range;auto;intros;rewrite length;auto.
 - intro E;inversion E;subst;unfold row_state_ok;destruct Z_lt_dec;repeat split;try lia;auto.
Qed.

Context {Espec:OracleKind} (gv:globals) (sh:share).
Let at_word:=scanning gv sh s op cp bp mp offsets cols blocks stamp wi dep w nc pk.
Let finish outcome:=match outcome with
 | AllBits branch p tags=>normal_ret_assert (at_word Int64.zero branch p tags)
 | EmptyRow tags=>cut_word gv sh s op cp bp mp offsets cols blocks w tags (Int64.add nc Int64.one) pk
 | TooManyRows tags=>cut_word gv sh s op cp bp mp offsets cols blocks w tags nc (Int64.add pk Int64.one)
 end.

(* The invariant carries the unread suffix of set bits. The result for that
   suffix, with precisely the current C registers and tags, is the result
   promised at entry. A C return bypasses the remainder of the suffix. *)
Definition unread (final:scan_exit) :=
 (EX word:int64, EX bits:list Z, EX branch:Z, EX p:Z, EX ms:list int64,
  PROPx [scan_word word bits; Forall (fun i=>safe_index_row (64*wi+i)) bits;
         row_state_ok branch p ms; scan_bits bits branch p ms=final]
    (LOCALx (word_locals gv s stamp wi dep word branch p)
     (SEPx (word_heap gv sh s op cp bp mp offsets cols blocks w ms nc pk))))%assert.

Theorem compiled_odd_word word bits branch packed ms :
 readable_share sh -> 0<=wi -> 1<=dep<=w -> w<=Int.max_signed ->
 scan_word word bits -> Forall (fun i=>safe_index_row (64*wi+i)) bits ->
 row_state_ok branch packed ms ->
 semax (func_tycontext f_index_children Vprog LowGprog []) (at_word word branch packed ms)
 odd_loop (finish (scan_bits bits branch packed ms)).
Proof.
 intros readable wi_ok depth cap initial safe valid.
 remember (scan_bits bits branch packed ms) as final eqn:answer.
 rewrite odd_loop_shape;unfold Swhile;abbreviate_semax.
 forward_loop (unread final) break:(RA_normal (finish final)).
 - unfold unread;Exists word bits branch packed ms;unfold at_word,scanning,word_locals,word_heap;entailer!;try apply derives_refl.
 - unfold unread;Intros now rest b p tags.
   rename H into path. rename H0 into safe_rest. rename H1 into valid_now. rename H2 into final_now.
   unfold word_locals;forward_if.
   + inversion path as [empty zero|active bit tail live later];subst.
     * exfalso;apply H;rewrite <-(Int64.repr_unsigned now),zero;reflexivity.
     * { inversion safe_rest as [|i entry_rows allowed continue_safe];subst.
       set (row:=64*wi+trailing bit) in *.
       destruct allowed as [fit [room [range [limit [within indices]]]]].
       destruct valid_now as [branch_ok [packed_ok extent]].
       pose proof (@compiled_active_bit Espec gv sh s op cp bp mp offsets cols blocks stamp wi dep w nc pk
         now bit b p tags readable live wi_ok fit room range limit within indices extent depth cap packed_ok branch_ok) as step.
       cbn zeta in step.
       cbn [scan_bits] in final_now.
       set (this_row:=64*wi+trailing bit) in step,final_now.
       set (kind:=run_row blocks tags stamp cols (lo this_row) (hi this_row) p (w-dep)) in final_now.
       change (semax (func_tycontext f_index_children Vprog LowGprog []) (at_word now b p tags) active_word_iteration
         (bit_out gv sh s op cp bp mp offsets cols blocks stamp wi dep w nc pk now b this_row tags kind)) in step.
       assert (bounded_next:forall q next,kind=ContinueRow q next -> row_state_ok (first_row b this_row) q next).
       { intros q next E;eapply step_stays_in_range;[exact (conj fit (conj room (conj range (conj limit (conj within indices)))))|exact (conj branch_ok (conj packed_ok extent))|exact E]. }
       destruct kind as [| |q next] eqn:which;cbn [resume_scan] in final_now.
       all: eapply semax_post_flipped;
          [eapply semax_pre;[|exact step];unfold at_word,scanning,word_locals,word_heap;entailer!;try apply derives_refl|..].
       all: unfold POSTCONDITION,abbreviate;rewrite <-final_now;
         cbn [bit_out finish cut_word RA_normal RA_break RA_continue RA_return loop_nocontinue_ret_assert
               normal_ret_assert function_body_ret_assert loop1_ret_assert overridePost];
         try solve [intro v;apply andp_left2;apply FF_left|intro v;apply andp_left2;apply derives_refl
                    |apply andp_left2;apply FF_left|apply andp_left2;apply derives_refl|normalize].
       all: destruct (scan_bits tail (first_row b this_row) q next) eqn:ending;
         cbn [finish cut_word loop_nocontinue_ret_assert function_body_ret_assert normal_ret_assert
               RA_normal RA_break RA_continue RA_return overridePost];
         try solve [intro v;apply andp_left2;apply FF_left|apply andp_left2;apply FF_left|normalize].
       all: unfold unread;Exists (clear now) tail (first_row b this_row) q next;
         unfold scanning,word_locals,word_heap;specialize (bounded_next q next eq_refl);
         entailer!;try apply derives_refl. }
   + inversion path as [empty zero|active bit tail live later];subst.
     * cbn [scan_bits] in final_now. forward.
       try unfold POSTCONDITION,abbreviate;rewrite <-final_now.
       cbn [finish RA_break RA_normal loop_nocontinue_ret_assert normal_ret_assert overridePost].
       unfold at_word,scanning,word_locals,word_heap;entailer!;try apply derives_refl.
     * discriminate live.
Qed.
End Scan.

From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedIndexAdmission NativePackingScan LeafMatrix.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section MatrixWord.
Variables m n:nat.
Variables (rows:'I_m->seq 'I_n) (H:'M['F_2]_(m,n)) (prefix:'cV['F_2]_n) (free:{set 'I_n}).
Variables (blocks cols:seq Integers.int) (offsets:seq Z) (stamp:int64) (budget:nat) (wi dep w:Z).
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

Definition selected_branch (branch:Z) (physical:seq 'I_m) :=
 if physical is r::_ then first_row branch (Z.of_nat r) else branch.
Lemma keep_first_physical b (r:'I_m) later :
 selected_branch (first_row b (Z.of_nat r)) later=selected_branch b (r::later).
Proof.
 case:later=>[|a rs] //=.
 unfold first_row;repeat destruct Z_lt_dec;try lia;reflexivity.
Qed.

(* The suffix after this word may belong to later machine words. *)
Theorem word_preserves_pcm positions physical pending b p ms :
 List.Forall2 (fun i (r:'I_m)=>(64*wi+i)%coqZ=Z.of_nat r) positions physical ->
 reached (physical++pending) ms p ->
 match scan_bits offsets cols blocks stamp wi dep w positions b (Z.of_nat p) ms with
 | EmptyRow _ | TooManyRows _ => no_completion H prefix free budget
 | AllBits branch value tags => branch=selected_branch b physical /\
     exists q, value=Z.of_nat q /\ reached pending tags q /\ (q<=budget)%N
 end.
Proof.
 move=> pairs;elim:pairs b p ms=>[|i r tail next same pairs ih] b p ms history.
 - split=> //;exists p;split=> //;split=> //;exact:count_within_budget history (leq0n _).
 - cbn [scan_bits];rewrite same remaining.
   have safe:=@iteration_preserves_pcm m n rows blocks stamp budget H prefix free fits available covers width
      first rest initial marked r (next++pending) ms p cols (Znth (Z.of_nat r) offsets) (Znth (Z.of_nat r+1)%coqZ offsets)
      initial_tags all_odd history (table r).
   case verdict:(run_row _ _ _ _ _ _ _ _) safe=>[| |value tags] //=.
   move=>[q [-> [progress live]]].
   have searched:=ih (first_row b (Z.of_nat r)) q tags progress.
   case:(scan_bits offsets cols blocks stamp wi dep w tail (first_row b (Z.of_nat r)) (Z.of_nat q) tags) searched
    =>[chosen packed final| |] //=.
   by rewrite keep_first_physical.
Qed.
End MatrixWord.
