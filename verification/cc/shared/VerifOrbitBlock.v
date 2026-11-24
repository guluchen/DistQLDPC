(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected ClightSelect SiblingCounters ActiveChildren.
Local Open Scope Z_scope.

Definition orbit_loop (s:statement) :=
 match s with Ssequence (Ssequence _ (Sset j _)) (Sloop _ _) => Pos.eqb j _j
 | _=>false end.
Definition actual_orbit : statement:=ltac:(native_fragment orbit_loop f_cc_run_level).
Definition orbit_mem s p starts blocks bp offsets qs counts :=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _block_start] starts p *
  data_at Tsh (tarray tuint (Zlength offsets)) (map (fun z=>Vint (Int.repr z)) offsets) starts *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _block] blocks p *
  data_at Tsh (tarray tuint (Zlength qs)) (map (fun z=>Vint (Int.repr z)) qs) blocks *
  field_at Tsh level_type [StructField _blk] bp s *
  data_at Tsh (tarray tuint (Zlength counts)) (map Vint counts) bp)%logic.
Definition scanned lo j qs counts := sweep 1 (sublist lo j qs) counts.
Definition orbit_loc s p i := [temp _s s;temp _policy p;temp _i (Vint (Int.repr i))].

Lemma scanned_next lo i qs base : 0<=lo<=i -> i<Zlength qs ->
 scanned lo (i+1) qs base=adjust 1 (scanned lo i qs base) (Znth i qs).
Proof. intros;unfold scanned,sweep;rewrite (sublist_split lo i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity. Qed.
Lemma scanned_length lo i qs base:in_array (Zlength base) qs ->
 Zlength (scanned lo i qs base)=Zlength base.
Proof. intro H;apply sweep_size;apply Forall_sublist;assumption. Qed.
Theorem semax_policy_orbit {Espec:OracleKind} s p starts blocks bp offsets qs base i lo hi:
 0<=i<Int.max_signed -> i+1<Zlength offsets -> Znth i offsets=lo -> Znth (i+1) offsets=hi ->
 0<=lo<=hi -> hi<=Zlength qs -> hi<=Int.max_unsigned -> Zlength base<=Int.max_unsigned ->
 in_array (Zlength base) qs ->
 semax (func_tycontext f_cc_run_level Vprog [] [])
  (PROPx nil (LOCALx (orbit_loc s p i) (SEPx [orbit_mem s p starts blocks bp offsets qs base])))
  actual_orbit
  (normal_ret_assert (PROPx nil (LOCALx (orbit_loc s p i)
     (SEPx [orbit_mem s p starts blocks bp offsets qs (scanned lo hi qs base)])))).
Proof.
 intros ix offsets_len lo_eq hi_eq bounds live cap block_cap indices.
 unfold actual_orbit,orbit_loc;abbreviate_semax;reassoc_seq.
 unfold orbit_mem;Intros;do 2 forward.
 forward_loop
  (EX j:Z, PROP(lo<=j<=hi)
   LOCAL(temp _j (Vint (Int.repr j));temp _s s;temp _policy p;temp _i (Vint (Int.repr i)))
   SEP(orbit_mem s p starts blocks bp offsets qs (scanned lo j qs base)))%assert
 break: (PROPx nil (LOCALx (orbit_loc s p i) (SEPx [orbit_mem s p starts blocks bp offsets qs (scanned lo hi qs base)])))%assert.
 - Exists lo;unfold orbit_mem,scanned;rewrite sublist_nil by lia;rewrite ?lo_eq;entailer!;try apply derives_refl.
 - Intros j. pose proof (@scanned_length lo j qs base indices) as rowlength.
   unfold orbit_mem;Intros;do 2 (forward;try solve [entailer!;change (Int.signed Int.one) with 1;change Int.min_signed with (-2147483648);lia]).
   rewrite hi_eq;forward_if.
   + assert (within:lo<=j<hi) by rep_lia.
     assert (valid:0<=Znth j qs<Zlength base) by
       (apply Forall_forall with (x:=Znth j qs) in indices;[exact indices|apply Znth_In;lia]).
     assert (uq:Int.unsigned (Int.repr (Znth j qs))=Znth j qs) by (apply Int.unsigned_repr;lia).
     do 8 forward. forward.
     Exists (j+1);unfold orbit_mem;rewrite scanned_next by lia;unfold adjust.
     rewrite upd_Znth_Zlength,upd_Znth_map by lia;rewrite ?uq;entailer!.
   + assert (j=hi) by rep_lia;subst;forward;unfold orbit_loc,orbit_mem;entailer!.
 - unfold orbit_loc;entailer!;try apply derives_refl.
Qed.

(* An exhausted orbit blocks even the qubits already forbidden by other
   policies. A single increment remains nonzero when its old count fits. *)
Theorem orbit_free_after base qs q :
 in_array (Zlength base) qs -> NoDup qs -> 0<=q<Zlength base ->
 Int.unsigned (Znth q base)<Int.max_unsigned ->
 (Znth q (sweep 1 qs base)=Int.zero <-> Znth q base=Int.zero /\ ~In q qs).
Proof.
 intros range distinct live bounded;rewrite sweep_cell by assumption.
 rewrite unique_visits by assumption;destruct (in_dec Z.eq_dec q qs) as [hit|miss].
 - change (Int.add (Znth q base) Int.one=Int.zero <-> Znth q base=Int.zero /\ ~In q qs).
   assert (positive:Int.add (Znth q base) Int.one<>Int.zero).
   { unfold Int.add. change (Int.unsigned Int.one) with 1.
     intro bad;apply (f_equal Int.unsigned) in bad;rewrite Int.unsigned_repr in bad by
       (pose proof (Int.unsigned_range (Znth q base));lia).
     change (Int.unsigned Int.zero) with 0 in bad;pose proof (Int.unsigned_range (Znth q base));lia. }
   tauto.
 - rewrite Z.mul_0_r,Int.add_zero;tauto.
Qed.
