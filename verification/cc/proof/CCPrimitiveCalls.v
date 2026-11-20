(* Unified finite-call interface for all five internal functions of the
   frozen primitive translation unit. PREs are explicit, not arbitrary-input
   totality or an end-to-end search theorem. *)
Require Import VST.floyd.proofauto.
Require Import compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.ccv_primitives CCV.CCWord CCV.CCTerminatePrimitives
 CCV.CCTerminateCeil CCV.CCTerminateWeight CCV.CCTerminateDot
 CCV.CCTerminateByteToggle.
Import ListNotations. Open Scope Z_scope.
Definition byte_reads m n b ofs:=forall j,0<=j<n ->exists v,
 Mem.loadv Mint8unsigned m(Vptr b(Ptrofs.add ofs(Ptrofs.repr j)))=Some(Vint v).
Inductive primitive_call_pre:Clight.function->list val->mem->Prop:=
 | pre_xor:forall a b m,primitive_call_pre f_ccv_bit_xor[Vint a;Vint b]m
 | pre_ceil:forall a b m,Int.unsigned b<>0 ->primitive_call_pre f_ccv_ceil_div[Vint a;Vint b]m
 | pre_weight:forall n b ofs m,0<=n<=Int.max_unsigned ->byte_reads m n b ofs ->
 primitive_call_pre f_ccv_weight[Vint(Int.repr n);Vptr b ofs]m
 | pre_dot:forall n ba oa bb ob m,0<=n<=Int.max_unsigned ->
 byte_reads m n ba oa ->byte_reads m n bb ob ->
 primitive_call_pre f_ccv_dot[Vint(Int.repr n);Vptr ba oa;Vptr bb ob]m
 | pre_toggle:forall n ba oa bb ob m,0<=n<=Int.max_unsigned ->tog_memory m n ba oa bb ob ->
 primitive_call_pre f_ccv_toggle[Vint(Int.repr n);Vptr ba oa;Vptr bb ob]m.
Lemma call_cont_fixed k:Clight.is_call_cont k ->Clight.call_cont k=k.
Proof. destruct k;cbn;intros;try contradiction;reflexivity. Qed.
Theorem all_primitive_calls_terminate ge f args m k:
 primitive_call_pre f args m ->Clight.is_call_cont k ->
 exists v m',star Clight.step2 ge(Clight.Callstate(Internal f)args k m)E0
 (Clight.Returnstate v k m').
Proof.
 intros Pre Call;pose proof(call_cont_fixed k Call)as Fixed.
 destruct Pre.
 - exists(Vint(Int.xor a b)),m;pose proof(actual_bit_xor_terminates ge a b k m)as Path;rewrite Fixed in Path;exact Path.
 - exists(Vint(machine_ceil a b)),m;pose proof(actual_ceil_div_terminates ge a b k m H)as Path;rewrite Fixed in Path;exact Path.
 - destruct(actual_weight_terminates ge m n b ofs k H H0)as[x Path].
   exists(Vint x),m;rewrite Fixed in Path;exact Path.
 - assert(Reads:forall j,0<=j<n ->exists va vb,
   Mem.loadv Mint8unsigned m(Vptr ba(Ptrofs.add oa(Ptrofs.repr j)))=Some(Vint va) /\
   Mem.loadv Mint8unsigned m(Vptr bb(Ptrofs.add ob(Ptrofs.repr j)))=Some(Vint vb)).
   { intros j Range;destruct(H0 j Range)as[va A];destruct(H1 j Range)as[vb B];exists va,vb;auto. }
   destruct(actual_dot_terminates ge m n ba oa bb ob k H Reads)as[x Path].
   exists(Vint x),m;rewrite Fixed in Path;exact Path.
 - destruct(actual_byte_toggle_terminates ge m n ba oa bb ob k Call H H0)as[m'[Memory Path]].
   exists Vundef,m';exact Path.
Qed.
Definition primitive_internal_bodies:list Clight.function:=
 fold_right(fun def acc=>match snd def with
 | Gfun(Internal f)=>f::acc | _=>acc end)[]ccv_primitives.global_definitions.
Lemma primitive_internal_bodies_exact:
 primitive_internal_bodies=[f_ccv_bit_xor;f_ccv_ceil_div;f_ccv_dot;f_ccv_weight;f_ccv_toggle].
Proof. reflexivity. Qed.
Print Assumptions all_primitive_calls_terminate.
