(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import ClightSelect level_ast VerifDetected SiblingCounters VerifSiblingRollback.
Local Open Scope Z_scope.

Definition native_visit : statement := ltac:(native_fragment (counts_on _i) f_dfs).
Lemma native_visit_source : find_counted _i (fn_body f_dfs)=Some native_visit.
Proof. reflexivity. Qed.
Definition added xs base i := sweep 1 (sublist 0 i xs) base.
Lemma added_length xs base i : in_array (Zlength base) xs ->
  Zlength (added xs base i)=Zlength base.
Proof. intro range;apply sweep_size;apply Forall_sublist;exact range. Qed.
Lemma added_next xs base i : 0<=i<Zlength xs ->
  added xs base (i+1)=adjust 1 (added xs base i) (Znth i xs).
Proof.
  intro valid;unfold added,sweep. rewrite (sublist_split 0 i (i+1)) by lia.
  rewrite (sublist_one i),fold_left_app by lia. reflexivity.
Qed.
Definition child_fields s cp bp w blocks path :=
 (field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
  field_at Tsh level_type [StructField _blk] bp s *
  data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp *
  field_at Tsh level_type [StructField _cur] cp s *
  data_at Tsh (tarray tint (Zlength path)) (map Vint path) cp)%logic.
Definition child_array children xs :=
 data_at Tsh (tarray tuint (Zlength xs)) (map (fun q=>Vint (Int.repr q)) xs) children.

Record nested_calls := {
  nested_policy : val;
  nested_policy_valid : is_pointer_or_null nested_policy;
  active_support : val -> option Z -> mpred;
  child_outcome : list int -> Z -> Z;
  returned_trace : list int -> Z -> list int -> Prop
}.
Definition enter_child (c:nested_calls) : ident*funspec :=
 DECLARE _flip
 WITH s:val, q:Z, enter:bool
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
   PROP(0<=q<=Int.max_signed) PARAMS(s;nested_policy c;Vint (Int.repr q))
   SEP(active_support c s (if enter then None else Some q))
 POST [tvoid] PROP() RETURN() SEP(active_support c s (if enter then Some q else None)).
Definition recursive_child (c:nested_calls) : ident*funspec :=
 DECLARE _dfs
 WITH s:val, cp:val,bp:val,w:Z,depth:Z,q:Z,blocks:list int,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
   PROP(1<=depth<w-2; w<=Int.max_signed; w<=Zlength path;
     0<=q<Zlength blocks; Znth depth path=Int.repr q)
   PARAMS(s;nested_policy c;Vint (Int.repr (depth+1)))
   SEP(child_fields s cp bp w blocks path;active_support c s (Some q))
 POST [tint] EX next:list int, PROP(0<=child_outcome c blocks q<=3;Zlength next=Zlength path;
     sublist 0 (depth+1) next=sublist 0 (depth+1) path;
     child_outcome c blocks q <> 0 -> returned_trace c blocks q next)
   RETURN(Vint (Int.repr (child_outcome c blocks q)))
   SEP(child_fields s cp bp w blocks next;active_support c s (Some q)).

Definition NestedGprog c : funspecs :=
 ltac:(let fs:=constr:([enter_child c;recursive_child c]) in with_library prog fs).
Definition outcome_at c xs base i :=
 child_outcome c (added xs base (i+1)) (Znth i xs).
Definition clear_prefix c xs base i := forall j,0<=j<i -> outcome_at c xs base j=0.
Definition visit_finished c xs base i r :=
 clear_prefix c xs base i /\ ((i=Zlength xs /\ r=0) \/
 (0<=i<Zlength xs /\ r=outcome_at c xs base i /\ r<>0)).
Definition visit_trace c xs base i r tail :=
  r<>0 -> returned_trace c (added xs base (i+1)) (Znth i xs) tail.
Definition visit_loc c s children depth n i r :=
 [temp _s s;temp _children children;temp _policy (nested_policy c);temp _update_overlap (Vint Int.zero);
  temp _size (Vint (Int.repr depth));temp _count (Vint (Int.repr n));
  temp _excluded (Vint (Int.repr i));temp _result (Vint (Int.repr r))].

Theorem semax_recursive_siblings {Espec:OracleKind} c s children cp bp xs base path w depth :
  1<=depth<w-2 -> w<=Int.max_signed -> Zlength xs<=Int.max_signed ->
  Zlength base<=Int.max_signed -> w<=Zlength path -> in_array (Zlength base) xs ->
  semax (func_tycontext f_dfs Vprog (NestedGprog c) [])
   (PROPx nil (LOCALx (visit_loc c s children depth (Zlength xs) 0 0)
     (SEPx [child_fields s cp bp w base path;child_array children xs;active_support c s None])))
   native_visit
   (normal_ret_assert (EX i:Z, EX r:Z, EX tail:list int,
     PROPx [visit_finished c xs base i r; visit_trace c xs base i r tail; Zlength tail=Zlength path; sublist 0 depth tail=sublist 0 depth path]
     (LOCALx (visit_loc c s children depth (Zlength xs) i r)
       (SEPx [child_fields s cp bp w (added xs base i) tail;child_array children xs;active_support c s None])))).
Proof.
  intros deep weight count limit pathlen range. pose proof (nested_policy_valid c) as policy_ok. unfold native_visit,visit_loc. abbreviate_semax.
  forward.
  forward_loop
    (EX i:Z, EX cur:list int,
     PROP(0<=i<=Zlength xs;clear_prefix c xs base i;Zlength cur=Zlength path;sublist 0 depth cur=sublist 0 depth path)
     LOCAL(temp _i (Vint (Int.repr i));temp _excluded (Vint (Int.repr i));temp _result (Vint Int.zero);
       temp _s s;temp _children children;temp _policy (nested_policy c);temp _update_overlap (Vint Int.zero);
       temp _size (Vint (Int.repr depth));temp _count (Vint (Int.repr (Zlength xs))))
     SEP(child_fields s cp bp w (added xs base i) cur;child_array children xs;active_support c s None))%assert
    break: (EX i:Z, EX r:Z, EX cur:list int,
      PROPx [visit_finished c xs base i r;visit_trace c xs base i r cur;Zlength cur=Zlength path;sublist 0 depth cur=sublist 0 depth path]
       (LOCALx (visit_loc c s children depth (Zlength xs) i r)
        (SEPx [child_fields s cp bp w (added xs base i) cur;child_array children xs;active_support c s None])))%assert.
  - Exists 0 path;unfold added;rewrite sublist_nil by lia;entailer!.
    + unfold clear_prefix;intros;lia.
    + apply derives_refl.
  - Intros i cur. forward_if.
    2: { forward;Exists i 0 cur;unfold visit_loc,visit_finished,visit_trace;entailer!;tauto || lia. }
    assert (inrange:0<=i<Zlength xs) by rep_lia.
    set (q:=Znth i xs).
    assert (valid:0<=q<Zlength base) by (apply Forall_forall with (x:=q) in range;[exact range|apply Znth_In;lia]).
    pose proof (@added_length xs base i range) as oldlen.
    pose proof (@added_length xs base (i+1) range) as newlen.
    unfold child_fields,child_array;Intros. do 2 forward.
    do 4 forward.
    rewrite upd_Znth_map. change (Int.repr 1) with Int.one.
    forward_call (s,q,true).
    reassoc_seq;apply semax_if_seq;forward_if;[match goal with B:typed_true tbool (Vint _) |- _ => vm_compute in B;discriminate end|].
    forward. forward.
    rewrite upd_Znth_map. set (after:=upd_Znth depth cur (Int.repr q)).
    assert (alen:Zlength after=Zlength path) by (unfold after;rewrite upd_Znth_Zlength by lia;assumption).
    assert (apart:sublist 0 depth after=sublist 0 depth path).
    { unfold after;rewrite sublist_upd_Znth_l by lia;assumption. }
    assert (here:Znth depth after=Int.repr q) by (unfold after;rewrite upd_Znth_same by lia;reflexivity).
    assert (minus:Int.sub (Int.repr w) (Int.repr 2)=Int.repr (w-2))
      by (unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;reflexivity).
    forward. apply semax_if_seq;forward_if.
    { exfalso;match goal with K:Int.repr depth=Int.sub _ _ |- _ => rewrite minus in K;
      apply (f_equal Int.signed) in K;rewrite !Int.signed_repr in K by rep_lia;lia end. }
    forward_call (s,cp,bp,w,depth,q,added xs base (i+1),after).
    { change (Int.min_signed<=depth+1<=Int.max_signed);rep_lia. }
    { entailer!;try (f_equal;unfold Int.add;rewrite Int.unsigned_repr by rep_lia;reflexivity). }
    { unfold child_fields;rewrite newlen,oldlen,alen,H1,added_next by lia.
      unfold adjust,q,after;cancel. }
    Intros next. assert (npre:sublist 0 depth next=sublist 0 depth path).
    { match goal with K:sublist 0 (depth+1) next=_ |- _ =>
        apply (f_equal (sublist 0 depth)) in K;
        rewrite !sublist_sublist00 in K by lia;congruence end. }
    reassoc_seq;apply semax_if_seq;forward_if;[match goal with B:typed_true tbool (Vint _) |- _ => vm_compute in B;discriminate end|].
    forward_call (s,q,false). unfold child_fields;Intros. do 4 forward.
    rewrite upd_Znth_map,decrement_word.
    change (upd_Znth q (added xs base (i+1)) (Int.add (Znth q (added xs base (i+1))) (Int.repr (-1))))
      with (adjust (-1) (added xs base (i+1)) q).
    assert (restore:adjust (-1) (added xs base (i+1)) q=added xs base i).
    { rewrite added_next by lia;apply cancel_child;lia. }
    first [rewrite restore|unfold adjust,q in restore;rewrite restore]. apply semax_if_seq;forward_if.
    + assert (notempty:child_outcome c (added xs base (i+1)) q <> 0).
      { intro empty;rewrite empty in *;congruence. }
      assert (stop:visit_finished c xs base i (outcome_at c xs base i)).
      { split;[assumption|right;unfold outcome_at;repeat split;try lia;try reflexivity;exact notempty]. }
      assert (kept:visit_trace c xs base i (outcome_at c xs base i) next).
      { unfold visit_trace,outcome_at;fold q;auto. }
      forward;Exists i (outcome_at c xs base i) next.
      unfold visit_loc,child_fields,child_array;rewrite ?newlen,?oldlen;entailer!;try apply derives_refl.
    + assert (signed_inc:Int.min_signed <= i+1 <= Int.max_signed) by (change Int.min_signed with (-2147483648);lia).
      assert (plus_one:Int.add (Int.repr i) Int.one=Int.repr (i+1)) by apply add_encoded.
      do 5 forward;try solve [entailer!;exact signed_inc].
      forward;try solve [entailer!;exact signed_inc].
      rewrite ?plus_one.
      assert (empty:outcome_at c xs base i=0) by (unfold outcome_at;assumption).
      assert (passed:clear_prefix c xs base (i+1)).
      { intros j J;destruct (Z.eq_dec j i) as [->|other];[assumption|unfold clear_prefix in *;auto with zarith]. }
      Exists (i+1) next;unfold child_fields,child_array;rewrite ?newlen,?oldlen,added_next by lia.
      unfold adjust,q;rewrite upd_Znth_map;entailer!;try apply derives_refl.
      unfold outcome_at in empty;rewrite added_next in empty by lia;unfold adjust in empty;rewrite empty;reflexivity.
  - Intros i r cur;Exists i r cur;unfold visit_loc;entailer!.
Qed.
