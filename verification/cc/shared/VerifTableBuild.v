(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import level_ast VerifDetected TableFlow.

Definition ints (xs:list Z) := map (fun x => Vint (Int.repr x)) xs.
Definition table_arrays ks cap tab links kp tp np : mpred :=
  (data_at Tsh (tarray tulong (Zlength ks)) (map Vlong ks) kp *
   data_at Tsh (tarray tint cap) (ints tab) tp *
   data_at Tsh (tarray tint (Zlength ks)) (ints links) np)%logic.

Definition build_spec : ident * funspec :=
 DECLARE _cc_build_leaf_index
 WITH ks:list int64, mask:int64, cap:Z, kp:val, tp:val, np:val
 PRE [tint,tulong,tptr tulong,tptr tint,tptr tint]
  PROP(Zlength ks<=Int.max_signed; Int64.unsigned mask<cap)
  PARAMS(Vint (Int.repr (Zlength ks)); Vlong mask; kp; tp; np)
  SEP(table_arrays ks cap (Zrepeat (-1) cap) (Zrepeat (-1) (Zlength ks)) kp tp np)
 POST [tvoid] EX tab:list Z, EX links:list Z,
  PROP(history ks mask cap (-1) tab links) RETURN()
  SEP(table_arrays ks cap tab links kp tp np).
Definition BuildGprog : funspecs := ltac:(with_library prog [build_spec]).

Theorem body_table_builder : semax_body Vprog BuildGprog f_cc_build_leaf_index build_spec.
Proof.
  start_function. pose proof (Zlength_nonneg ks) as nn.
  forward_loop
    (EX q:Z, EX tab:list Z, EX links:list Z,
      PROP(history ks mask cap q tab links)
      LOCAL(temp _q (Vint (Int.repr q));temp _keys kp;temp _slots tp;temp _next np;
            temp _mask (Vlong mask))
      SEP(table_arrays ks cap tab links kp tp np))%assert
    break: (EX tab:list Z, EX links:list Z, PROP(history ks mask cap (-1) tab links)
        LOCAL() SEP(table_arrays ks cap tab links kp tp np))%assert.
  - forward. Exists (Zlength ks-1) (Zrepeat (-1) cap) (Zrepeat (-1) (Zlength ks)).
    entailer!;constructor.
  - Intros q tab links. rename H1 into previous.
    pose proof (@history_shape ks mask cap ltac:(assumption) q tab links previous)
      as [bounded tablen linklen heads ascending].
    forward_if.
    + assert (live:0<=q<Zlength ks) by rep_lia.
      unfold table_arrays,ints. Intros. do 2 forward.
      forward_loop
        (EX i:int64, PROP(reached ks mask q tab i)
         LOCAL(temp _q (Vint (Int.repr q));temp _i (Vlong i);temp _keys kp;temp _slots tp;
               temp _next np;temp _mask (Vlong mask))
         SEP(table_arrays ks cap tab links kp tp np))%assert
        break: (EX newtab:list Z, EX newlinks:list Z,
         PROP(history ks mask cap (q-1) newtab newlinks)
         LOCAL(temp _q (Vint (Int.repr q));temp _keys kp;temp _slots tp;temp _next np;
               temp _mask (Vlong mask))
         SEP(table_arrays ks cap newtab newlinks kp tp np))%assert.
      * Exists (insert_home ks mask q);unfold table_arrays,ints,insert_home;entailer!;constructor.
      * Intros i. match goal with R:reached _ _ _ _ i |- _ => rename R into route end.
        pose proof (@reached_inside ks mask cap ltac:(assumption) q tab i route) as location.
        pose proof (heads (slot_index i) location) as possible.
        assert (representable: -1<=head tab i<Zlength ks) by (unfold head;lia).
        unfold slot_index in location.
        assert (ptr_ix:Ptrofs.unsigned (Ptrofs.of_int64 i)=Int64.unsigned i).
        { unfold Ptrofs.of_int64;rewrite Ptrofs.unsigned_repr;[reflexivity|apply Int64.unsigned_range_2]. }
        assert (ptr_ok:0<=Ptrofs.unsigned (Ptrofs.of_int64 i)<Zlength tab) by lia.
        assert (sign_h:Int.signed (Int.repr (Znth (Int64.unsigned i) tab))=Znth (Int64.unsigned i) tab).
        { apply Int.signed_repr;unfold TableFlow.head,slot_index in representable;rep_lia. }
        unfold table_arrays,ints;Intros. forward. rewrite ?ptr_ix in *.
        reassoc_seq. apply semax_if_seq. forward_if.
        -- forward. forward. Exists (upd_Znth (slot_index i) tab q) links.
           unfold table_arrays,ints,slot_index;entailer!.
           ++ eapply placed_empty with (i:=i);try eassumption;unfold TableFlow.head,slot_index in *;
                rewrite ?sign_h in *;lia.
           ++ rewrite ptr_ix, <-upd_Znth_map;apply derives_refl.
        -- assert (old_valid:0<=head tab i<Zlength ks) by
              (unfold TableFlow.head,slot_index in *;rewrite ?sign_h in *;lia).
           do 2 forward. apply semax_if_seq. forward_if.
           ++ forward. forward. forward.
              Exists (upd_Znth (slot_index i) tab q) (upd_Znth q links (head tab i)).
              unfold table_arrays,ints,TableFlow.head,slot_index;entailer!.
              ** eapply placed_chain with (i:=i);try eassumption;try lia;unfold TableFlow.head,slot_index in *.
                 pose proof (Int64.eq_spec (Znth (Znth (Int64.unsigned i) tab) ks) (Znth q ks)) as test.
                 destruct (Int64.eq _ _);congruence.
              ** rewrite ?ptr_ix;repeat rewrite <-upd_Znth_map;cancel.
           ++ forward. Exists (insert_next mask i);unfold table_arrays,ints,insert_next;entailer!.
              apply after_collision;try assumption;try lia.
      * Intros newtab newlinks. forward. Exists (q-1) newtab newlinks. unfold table_arrays,ints;entailer!.
    + assert (q= -1) by rep_lia;subst q. forward. Exists tab links;entailer!.
  - Intros tab links. Exists tab links;unfold table_arrays,ints;entailer!.
Qed.
