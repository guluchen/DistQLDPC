(* Heuristics for the extracted checker. The membership snapshot is immutable
   for the lifetime of a check. Hints and upper witnesses are checked in Coq. *)
open Pcm_generated

type mask = int * int * int
let zero = 0,0,0
let xor (a,b,c) (x,y,z) = a lxor x,b lxor y,c lxor z
let bit (a,b,c) q =
  let lane = if q < 63 then a else if q < 126 then b else c in
  lane land (1 lsl (q mod 63)) <> 0
let unit q =
  let b = 1 lsl (q mod 63) in
  if q < 63 then b,0,0 else if q < 126 then 0,b,0 else 0,0,b
let word x = Int64.to_int (Uint63.to_int64 x)
let mask a = word a.low, word a.middle, word a.high
let positions n f =
  let b = ref zero in
  for q = 0 to n-1 do if f q then b := xor !b (unit q) done;
  !b

let basis n rs =
  let pivots = Array.make n zero in
  let reduce x =
    let a = ref x in
    for q = 0 to n-1 do if bit !a q then a := xor !a pivots.(q) done;
    !a
  in
  Array.iter (fun r ->
    let v = reduce r in
    if v <> zero then begin
      let q = ref 0 in while not (bit v !q) do incr q done;
      pivots.(!q) <- v
    end) rs;
  reduce

let propose n rows =
  let masks = Array.of_list (List.map (fun r -> mask r.support_mask) rows) in
  let reduce = basis n masks in
  let image period i = i - i mod period + (i mod period + 1) mod period in
  let rec find p =
    if p <= 1 then 1 else
    if n mod p = 0 && Array.for_all (fun r ->
      reduce (positions n (fun i -> bit r (image p i))) = zero) masks
    then p else find (p-1)
  in
  let p = find n in
  List.init n (image p), List.init n (fun i -> i-i mod p+(i mod p+p-1) mod p)

external row_hint : mask array -> mask -> mask -> int -> hint = "caml_ccv_packed_hint"
exception Advice_limit

let make_choice rows =
  let masks = Array.of_list (List.map (fun r->mask r.support_mask) rows) in
  let calls_left = ref 2000000 in
  fun sy free remaining ->
    if !calls_left=0 then raise Advice_limit;
    decr calls_left;
    row_hint masks (mask sy) (mask free) remaining

(* One immutable Bloom filter per bound. Collisions can only retain nodes.
   Coq checks all column sums up to the corresponding weight before use. *)
let membership k cols =
  let a = Array.of_list (List.map (fun c->word c.check_delta.low) cols)
  and b = Array.of_list (List.map (fun c->word c.check_delta.middle) cols)
  and c = Array.of_list (List.map (fun c->word c.check_delta.high) cols) in
  let bytes = if k=2 then 32768 else 1048576 in
  let limit = bytes*8-1 in
  let index x y z =
    let h = x lxor (y*1751310973423325005) lxor (z*2862933555777941757) in
    let h = (h lxor (h lsr 27))*2685821657736338717 in
    (h lxor (h lsr 29)) land limit
  in
  let bits = Bytes.make bytes '\000' in
  let insert x y z =
    let i=index x y z in let j=i lsr 3 in
    Bytes.unsafe_set bits j (Char.unsafe_chr (Char.code (Bytes.unsafe_get bits j) lor (1 lsl (i land 7))))
  in
  insert 0 0 0;
  for i=0 to Array.length a-1 do
    insert a.(i) b.(i) c.(i);
    for j=0 to i-1 do
      let x=a.(i) lxor a.(j) and y=b.(i) lxor b.(j) and z=c.(i) lxor c.(j) in
      insert x y z;
      if k=3 then for t=0 to j-1 do insert (x lxor a.(t)) (y lxor b.(t)) (z lxor c.(t)) done
    done
  done;
  let frozen=Bytes.unsafe_to_string bits in
  fun s -> let i=index (word s.low) (word s.middle) (word s.high) in
    Char.code (String.unsafe_get frozen (i lsr 3)) land (1 lsl (i land 7)) <> 0

let prepare_index rows =
  let data=Array.of_list (List.mapi (fun i r ->
    let a,b,c=unit i in
    r,{low=Uint63.of_int a;middle=Uint63.of_int b;high=Uint63.of_int c}) rows) in
  fun i -> if i<0 || i>=Array.length data then bad_row,none else data.(i)

let advice = {prepare_index; propose; make_choice; membership}

let rows n count flat =
  let data = Array.of_list flat in
  Array.init count (fun i -> positions n (fun q->data.(n*i+q)=1))

let upper n model other =
  let h = rows n model.model_m model.model_h in
  let l = rows n model.model_l model.model_lg in
  let signature rs w =
    let parity (a,b,c) (x,y,z) =
      let v = ref ((a land x) lxor (b land y) lxor (c land z)) in
      let odd = ref false in
      while !v<>0 do odd := not !odd; v := !v land (!v-1) done;
      !odd
    in positions (Array.length rs) (fun i -> parity rs.(i) w)
  in
  let best = ref (n+1,zero) in
  let accept w =
    let weight = ref 0 in
    for q=0 to n-1 do if bit w q then incr weight done;
    if !weight < fst !best && signature h w=zero && signature l w<>zero then
      best := (!weight,w)
  in
  Array.iter accept (rows n other.model_l other.model_lg);
  (* Periodic supports in any equal-width block. Colliding syndromes give
     a kernel vector, whose nonzero logical action is still checked. *)
  let patterns = Hashtbl.create 512 in
  if fst !best > 6 then begin
  for span = 1 to n do
    if n mod span = 0 then
      for step = 1 to span do
        if span mod step=0 && span/step < fst !best then
          for offset=0 to n/span-1 do
            for phase=0 to step-1 do
              let w = positions n (fun q -> q/span=offset && q mod step=phase) in
              let key = signature h w in
              if key=zero then accept w;
              match Hashtbl.find_opt patterns key with
              | None -> Hashtbl.add patterns key w
              | Some u when u<>w -> accept (xor u w)
              | _ -> ()
            done
          done
      done
  done;
  end;
  let d,w = !best in d,List.init n (bit w)

(* Try block reflection with exchange of the two physical blocks. Its
   inverse is itself; the checker independently verifies both row spaces. *)
let dual_candidate n ax az =
  if n mod 2<>0 then [],[] else
  let h=n/2 in
  let perm i = (1-i/h)*h + (h-i mod h) mod h in
  let checks = rows n ax.model_m ax.model_h in
  let reduce=basis n (rows n az.model_m az.model_h) in
  if Array.for_all (fun r->reduce (positions n (fun i->bit r (perm i))) = zero) checks
  then let p=List.init n perm in p,p else [],[]

let certify n ax az =
  if n>189 || List.exists (fun a -> a.model_m>189 || a.model_l>189) [ax;az] then None
  else
    let dx,x=upper n ax az and dz,z=upper n az ax in
    let d,side,w=if dx<=dz then dx,true,x else dz,false,z in
    if d<=6 || d>18 then None else
    let p,inv=dual_candidate n ax az in
    try packed_report n ax az side w advice p inv with Advice_limit -> None
