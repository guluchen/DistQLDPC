(* Resolve replacement bodies by their declared names. All remaining
   declarations are paired without changing their position or type. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.common.Events compcert.lib.Maps.
Require Import CCV.ccv_core CCV.CCBodyProgram CCV.CCVerificationDriver CCV.CCReplayFrames
 CCV.CCReplayEnvironment CCV.CCBoundedMain CCV.CCExpandedBody CCV.CCCapGuard CCV.CCProgramRelation.
Import ListNotations.
Definition def_pair (x y:globdef Clight.fundef type) :=
 match x,y with Gfun f,Gfun g=>function_pair f g|Gvar v,Gvar w=>v=w|_,_=>False end.
Definition volatility (d:option (globdef Clight.fundef type)):bool :=
 match d with Some(Gvar v)=>gvar_volatile v|_=>false end.
Lemma volatile_pair x y:option_rel def_pair x y ->volatility y=volatility x.
Proof.
 intro M;destruct M as [|x y R];[reflexivity|destruct x,y;simpl in *;try contradiction;subst;reflexivity].
Qed.
Lemma volatile_at (ge:Genv.t Clight.fundef type) b:Genv.block_is_volatile ge b=volatility (Genv.find_def ge b).
Proof. unfold Genv.block_is_volatile,Genv.find_var_info;destruct(Genv.find_def ge b) as [[f|v]|];reflexivity. Qed.
Definition declarations (p:Clight.program) i := filter (fun d=>Pos.eqb (fst d) i) (prog_defs p).
Lemma named_unique p i d known:declarations p i=[(i,known)] ->In(i,d)(prog_defs p) ->d=known.
Proof.
 intros Only D. assert (H:In (i,d) (declarations p i)) by
 (apply filter_In;split;[assumption|apply Pos.eqb_refl]).
 rewrite Only in H;simpl in H;intuition congruence.
Qed.
Lemma same_global d:checked_definition d=true ->def_pair (snd d)(snd d).
Proof. destruct d as [i [fn|v]];simpl;[apply same_fd|auto]. Qed.
Section Linking.
Variable p:Clight.program.
Hypothesis search_name:declarations p _search=[(_search,Gfun(Internal f_search))].
Hypothesis dist_name:declarations p _ccv_distance=[(_ccv_distance,Gfun(Internal f_ccv_distance))].
Hypothesis checked:forallb checked_definition (prog_defs p)=true.
Variable n:nat.
Local Notation s := (body_with (bounded_main n)).
Local Notation d := (fn_body guarded_distance).
Local Notation q := (body_program s d p).
Lemma declarations_match : list_forall2 (fun x y=>fst x=fst y /\def_pair (snd x)(snd y)) (prog_defs q)(prog_defs p).
Proof.
 change(list_forall2 (fun x y=>fst x=fst y /\ def_pair (snd x)(snd y)) (map (replace_def s d) (prog_defs p)) (prog_defs p)).
 assert (Each:forall x,In x (prog_defs p) ->def_pair (snd (replace_def s d x))(snd x)).
 { intros [i gd] Member;unfold replace_def;cbn [fst snd].
   destruct (Pos.eqb_spec i _search) as [->|N].
   - pose proof(named_unique _ _ _ _ search_name Member) as ->.
     apply paired_fn;[apply headers_body|apply search_code_pair].
   - destruct (Pos.eqb_spec i _ccv_distance) as [->|N'].
     + pose proof(named_unique _ _ _ _ dist_name Member) as ->.
       apply paired_fn;[apply headers_body|apply distance_code_pair].
     + apply(same_global (i,gd));apply (proj1(forallb_forall _ _) checked);exact Member. }
 revert Each;generalize (prog_defs p);intro xs;induction xs as [|x xs IH];intros Each;[apply list_forall2_nil|apply list_forall2_cons].
 - split;[apply replace_def_id|apply Each;left;reflexivity].
 - apply IH;intros;apply Each;right;assumption.
Qed.
Lemma table_match:Genv.match_genvs def_pair (Genv.globalenv q)(Genv.globalenv p).
Proof.
 unfold Genv.globalenv;apply Genv.add_globals_match;[apply declarations_match|].
 constructor;intros;try reflexivity;cbn;rewrite !PTree.gempty;constructor.
Qed.
Lemma all_targets v fd:Genv.find_funct (globalenv q) v=Some fd ->
 exists fd',Genv.find_funct (globalenv p) v=Some fd' /\function_pair fd fd'.
Proof.
 intro F. destruct (Genv.find_funct_inv _ _ F) as [b ->].
 rewrite Genv.find_funct_find_funct_ptr in *;apply Genv.find_funct_ptr_iff in F.
 pose proof(Genv.mge_defs table_match b) as M;change (option_rel def_pair (Genv.find_def (Genv.globalenv q) b)(Genv.find_def (Genv.globalenv p)b)) in M.
 change (Genv.find_def (Genv.globalenv q) b=Some (Gfun fd)) in F.
 rewrite F in M;inversion M;subst;destruct y as [fd'|v'];try contradiction.
 exists fd';split;[apply Genv.find_funct_ptr_iff;change (Genv.find_def (Genv.globalenv p) b=Some (Gfun fd'));first [assumption|symmetry;assumption]|assumption].
Qed.
Lemma external_environment:Senv.equiv (globalenv q)(globalenv p).
Proof.
 red;simpl;repeat split.
 - intros i;symmetry;exact (body_addresses s d p i).
 - intros i;change (Genv.public_symbol (Genv.globalenv p) i=Genv.public_symbol (Genv.globalenv q) i).
   assert (S:Genv.find_symbol (Genv.globalenv q) i=Genv.find_symbol (Genv.globalenv p) i) by exact(body_addresses s d p i).
   unfold Genv.public_symbol;rewrite S.
   rewrite !Genv.globalenv_public;reflexivity.
 - intro b;change (Genv.block_is_volatile (Genv.globalenv p) b=Genv.block_is_volatile (Genv.globalenv q) b). rewrite !volatile_at.
   apply volatile_pair;exact (Genv.mge_defs table_match b).
Qed.
End Linking.
Lemma driver_search_decl:declarations driver_prog _search=[(_search,Gfun(Internal f_search))].
Proof. vm_compute;reflexivity. Qed.
Lemma driver_distance_decl:declarations driver_prog _ccv_distance=[(_ccv_distance,Gfun(Internal f_ccv_distance))].
Proof. vm_compute;reflexivity. Qed.
Lemma all_driver_code_supported:forallb checked_definition (prog_defs driver_prog)=true.
Proof. vm_compute;reflexivity. Qed.
