(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch LeafAPI PCMLeafAPI VerifOneLeft
 VerifClosesBody VerifFlipBody NativeFlipPayload PreparedMatrixResponse PreparedMatrixPath
 PreparedDepthSpec PreparedChildPrefix PreparedPairEvent PreparedPairTrace PreparedLeafMinimum
 PreparedObservedWitness PreparedInteriorReport PreparedPCMLeafVisit OverlapColumnState.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Final.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (qual:seq Integers.int->'cV['F_2]_n->Prop) (ids:seq 'I_n) (st:snapshot)
 (rowkey:'I_m->int64) (packed:packed_support) (cells:seq Integers.int) (z:Z).
Let d:=Z.of_nat (size ids).
Let P:=[set q:'I_n | q \in ids].
Let F:=@available_now n st.
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (rank_ok:(\rank (col_mx H G)+\rank S=n)%N)
 (nfit:(Z.of_nat n<=Int.max_signed)%coqZ) (distinct:uniq ids) (nonempty:ids!=[::])
 (room:(d<Zlength cells)%coqZ)
 (prefix:active_prefix d cells=literal_path ids)
 (physical:pcm_response H G rowkey (indicator P) packed) (open_node:odd_count packed<>0%coqZ).

(* One qubit left. A collision chain can produce any valid coordinate.
   The proof uses the coordinate actually returned by the lookup. *)
Theorem final_lookup_proves_recursive_verdict:
 leaf_answer (pcm_completion H G P F) (Z.of_nat n) z ->
 recursive_result H S G qual (d+1)%coqZ st (literal_path ids) (final_pick z) (last_path d z cells).
Proof.
 move=> observed.
 have count:#|P|=size ids by rewrite /P cardsE (card_uniqP distinct).
 have positive:P!=set0 by rewrite -card_gt0 count lt0n size_eq0.
 split.
 - rewrite literal_prefix_set //;move=> target _ best wt sub free.
   have missing:#|support target|=(#|P|).+1 by apply Nat2Z.inj;rewrite Nat2Z.inj_succ count;lia.
   exact:(@one_missing_qubit_prevents_empty m n k H G rowkey P F target packed (Some z) false
        best missing positive sub free physical (conj open_node observed)).
 - split;last by rewrite /final_pick;destruct (Z_lt_dec z 0);discriminate.
   move=>hit;have valid:(0<=z)%coqZ by move:hit;rewrite /final_pick;case:(Z_lt_dec z 0);lia.
   have bounds:=@lookup_trace_and_distance m r k n H S G F ids cells z orth det rank_ok distinct room prefix observed.
   destruct bounds as [[miss _]|[a [index regs closed outside [weight bound]]]];first lia.
   rewrite /stored_css_prefix regs literal_prefix_set //.
   have shape:[set b:'I_n | b \in rcons ids a]=a |: P by apply/setP=>b;rewrite /P !inE mem_rcons inE.
   rewrite shape weight;split=> //.
   + rewrite /last_path;case:(Z_lt_dec z 0)=>[bad|_];first lia.
     rewrite upd_Znth_Zlength;unfold d in *;lia.
   + split=> //;rewrite Nat2Z.inj_succ;lia.
Qed.
End Final.
