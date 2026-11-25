(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifLowestBit PreparedIndexSweep PreparedIndexWhile
 PreparedIndexBitBody PreparedIndexSweepPCM WordScan.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedIndexWords PreparedIndexAdmission NativePackingScan IndexRowBridge
 SparseSyndrome SparseFlipBits LeafMatrix CSRWordTraversal flag_level_ast.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

Lemma plan_entry_shape words plan :
 List.Forall2 scan_word words plan -> Zlength plan=Zlength words /\
 forall i,(0<=i<Zlength words)%coqZ -> scan_word (Znth i words) (Znth i plan).
Proof.
 elim=>[|word bits tail later entry pairs [same ih]].
 - split=> //;rewrite Zlength_nil;lia.
 - split;first by rewrite !Zlength_cons same.
   move=>i within;case:(Z.eq_dec i 0)=>[->|nz];first by rewrite !Znth_0_cons.
   rewrite !Znth_pos_cons;try lia;apply ih;rewrite Zlength_cons in within;lia.
Qed.

Lemma located_bits wi plan i :
 (0<=i<Zlength plan)%coqZ -> forall bit,List.In bit (Znth i plan) ->
 List.In (64*(wi+i)+bit)%coqZ (physical_order wi plan).
Proof.
 elim:plan wi i=>[|bits later ih] wi i;first rewrite Zlength_nil;try lia.
 rewrite Zlength_cons=> within bit inside;cbn [physical_order];apply List.in_or_app.
 case:(Z.eq_dec i 0)=>[zero|nz].
 - left;subst i;rewrite Z.add_0_r;apply List.in_map;by rewrite Znth_0_cons in inside.
 - right;replace (64*(wi+i)+bit)%coqZ with (64*(wi+1+(i-1))+bit)%coqZ by lia.
   apply ih;first lia;by rewrite Znth_pos_cons in inside;try lia.
Qed.

Section Tables.
Variables m n:nat.
Variables (rows:'I_m->seq 'I_n) (H:'M['F_2]_(m,n)) (prefix:'cV['F_2]_n)
 (free:{set 'I_n}) (blocks cols:seq Integers.int) (offsets:seq Z) (stamp:int64) (budget:nat) (dep w:Z).
Variables (words:seq int64) (count:Z) (initial:seq int64) (marked:{set 'I_n}).
Hypotheses (m_fits:(Z.of_nat m<=Int.max_signed)%coqZ) (n_fits:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (available:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free)
 (block_width:Zlength blocks=Z.of_nat n)
 (covers:forall r q,H r q!=0 -> q \in rows r)
 (width:forall r,(Zlength (encoded rows r)<=Int.max_unsigned)%coqZ)
 (offset_count:Zlength offsets=(Z.of_nat m+1)%coqZ)
 (csr:forall r:'I_m,let a:=Znth (Z.of_nat r) offsets in let b:=Znth (Z.of_nat r+1)%coqZ offsets in
    (0<=a<=b)%coqZ /\ (b<=Int.max_unsigned)%coqZ /\ (b<=Zlength cols)%coqZ /\ sublist a b cols=encoded rows r)
 (remaining:(w-dep)%coqZ=Z.of_nat budget)
 (tags:@tags_for n stamp initial marked) (stored:stores_odd (words,count) (support (H*m prefix)))
 (padding:clear_padding (Z.of_nat m) words) (live:(0<count)%coqZ).

Lemma physical_rows_are_safe (r:'I_m) : safe_index_row offsets cols blocks (Z.of_nat r).
Proof.
 have small:=elimT ltP (ltn_ord r).
 have [range [cap [within slice]]]:=csr r.
 unfold safe_index_row;repeat split;try lia.
 move=>j inside.
 have edge:List.In (Znth j cols) (sublist (Znth (Z.of_nat r) offsets) (Znth (Z.of_nat r+1)%coqZ offsets) cols).
 { pose a:=@Znth Z ltac:(typeclasses eauto) (Z.of_nat r) offsets;pose b:=@Znth Z ltac:(typeclasses eauto) (Z.of_nat r+1)%coqZ offsets.
   change (0<=a<=b)%coqZ in range;change (b<=Zlength cols)%coqZ in within;change (a<=j<b)%coqZ in inside.
   have pos:(0<=j-a<Zlength (sublist a b cols))%coqZ by rewrite Zlength_sublist;lia.
   have got:List.In (Znth (j-a)%coqZ (sublist a b cols)) (sublist a b cols) by apply Znth_In;exact pos.
   rewrite Znth_sublist in got;try lia;replace (j-a+a)%coqZ with j in got by lia;exact got. }
 rewrite slice in edge;rewrite block_width;exact:(index_bounded n_fits edge).
Qed.

Lemma plan_ready plan:List.Forall2 scan_word words plan ->
 Zlength plan=Zlength words /\ forall i,(0<=i<Zlength words)%coqZ ->
 scan_word (Znth i words) (Znth i plan) /\
 List.Forall (fun bit=>safe_index_row offsets cols blocks (64*i+bit)%coqZ) (Znth i plan).
Proof.
 move=> pairs;have [size_ok run]:=plan_entry_shape pairs;split=> // i within;split;first exact:run within.
 have order:=@plan_traces_words 0 words plan pairs.
 have [_ decode]:=@word_scan_physical_rows m words count (support (H*m prefix)) stored padding _ order.
 apply Forall_forall=>bit present.
 have member:=@located_bits 0 plan i ltac:(lia) bit present.
 rewrite Z.add_0_l in member;have [r [-> _]]:=proj1 (decode _) member.
 exact:physical_rows_are_safe.
Qed.

(* Both sides refer to the same fold produced by the actual set bits.
   Neither a list of candidates nor a cut certificate is a premise. *)
Theorem compiled_sweep_from_pcm {Espec:OracleKind} gv sh s sp op cp bp mp nc pk :
 readable_share sh -> (1<=dep<=w)%coqZ -> (w<=Int.max_signed)%coqZ ->
 (Zlength words<=Int.max_signed)%coqZ ->
 exists plan result,List.Forall2 scan_word words plan /\
 result=sweep offsets cols blocks stamp dep w 0 plan (-1) 0 initial /\
 semax (func_tycontext f_index_children Vprog LowGprog nil)
   (sweep_entry offsets cols blocks stamp dep w gv sh s sp op cp bp mp words nc pk (-1) 0 initial)
   all_words (sweep_post offsets cols blocks stamp dep w gv sh s sp op cp bp mp words nc pk result) /\
 match result with
 | EmptyRow _ | TooManyRows _=>no_completion H prefix free budget
 | AllBits branch value table_after=>exists first rest,
    physical_order 0 plan=map (fun r:'I_m=>Z.of_nat r) (first::rest) /\ first \in support (H*m prefix) /\
    branch=Z.of_nat first /\ exists q,value=Z.of_nat q /\
      reaches_row rows blocks stamp budget (first::rest) initial 0 nil table_after q /\ (q<=budget)%N
 end.
Proof.
 move=>readable depth cap size.
 have image (r:'I_m):sublist (Znth (Z.of_nat r) offsets) (Znth (Z.of_nat r+1)%coqZ offsets) cols=encoded rows r
   by case:(csr r)=> _ [_ [_ actual]].
 have [plan [run verdict]]:=@sweep_from_syndrome m n rows H prefix free blocks cols offsets stamp budget dep w
    words count initial marked n_fits available covers width image remaining tags stored padding live.
 have [same layout]:=plan_ready run.
 have init:row_state_ok blocks dep w (-1) 0 initial.
 { unfold row_state_ok;have [sz _]:=tags;rewrite block_width;repeat split;try lia;unfold Int.max_signed;lia. }
 exists plan,(sweep offsets cols blocks stamp dep w 0 plan (-1) 0 initial);split=> //;split=> //;split;last done.
 exact:(@compiled_word_sweep offsets cols blocks stamp dep w Espec gv sh s sp op cp bp mp words plan nc pk
     (-1)%coqZ 0 initial readable depth cap size same layout init).
Qed.
End Tables.
