open Large_generated

let word x = Int64.to_int (Uint63.to_int64 x)
let words w =
  let wa=w.left_half and wb=w.right_half in
  let a=wa.first_part and b=wa.second_part and c=wb.first_part and d=wb.second_part in
  [|word a.low;word a.middle;word a.high;word b.low;word b.middle;word b.high;
    word c.low;word c.middle;word c.high;word d.low;word d.middle;word d.high|]
let bit a q = a.(q/63) land (1 lsl (q mod 63)) <> 0
let positions n f =
  let a=Array.make 12 0 in
  for i=0 to n-1 do if f i then a.(i/63) <- a.(i/63) lor (1 lsl (i mod 63)) done; a

let propose n rows =
  let data=Array.of_list (List.map (fun r -> words r.support_mask) rows) in
  let basis=Array.make n None in
  let reduce w =
    for i=0 to n-1 do
      if bit w i then match basis.(i) with
        | None -> () | Some r -> for j=i/63 to 11 do w.(j)<-w.(j) lxor r.(j) done
    done in
  Array.iter (fun row ->
    let w=Array.copy row in reduce w;
    let rec insert i = if i<n then if bit w i then basis.(i)<-Some w else insert (i+1) in
    insert 0) data;
  let shift k i = i-i mod k+(i mod k+1) mod k in
  let rec period k =
    if k=1 then 1 else
      if n mod k=0 && Array.for_all (fun row ->
        let w=positions n (fun i->bit row (shift k i)) in
        reduce w;Array.for_all ((=) 0) w) data then k else period (k-1) in
  let k=period n in List.init n (shift k),List.init n (fun i->i-i mod k+(i mod k+k-1) mod k)

exception Exhausted
external row_hint : (int array array * int array array) -> bits1 -> bits1 -> int -> hint = "caml_wide_hint"

(* A linear signature commutes with every column XOR. The extracted checker
   also verifies every required entry in the immutable filter. *)
external signature : bits1 -> int = "caml_wide_hash" [@@noalloc]
let membership k cols =
  let a=Array.of_list(List.map (fun c->signature c.check_delta) cols) in
  let bytes=if k=2 then 131072 else 2097152 in let mask=bytes*8-1 in
  let data=Bytes.make bytes '\000' in
  let index x = ((x lxor (x lsr 29))*2685821657736338717) land mask in
  let insert x = let i=index x in let j=i lsr 3 in
    Bytes.set data j (Char.chr(Char.code(Bytes.get data j) lor (1 lsl (i land 7)))) in
  insert 0;
  Array.iteri (fun i x -> insert x;
    for j=0 to i-1 do let y=x lxor a.(j) in insert y;
      if k=3 then for u=0 to j-1 do insert(y lxor a.(u)) done
    done) a;
  let immutable=Bytes.unsafe_to_string data in
  fun w -> let i=index (signature w) in Char.code immutable.[i lsr 3] land (1 lsl(i land 7)) <> 0

let make_advice ~logical_lines limit pair_pack =
  let left=ref limit in
  let make_choice rows =
    let a=Array.of_list(List.map(fun r->words r.support_mask)rows) in
    let incident =
      if not pair_pack then [||] else
      let by_qubit = Array.make 756 [] in
      Array.iteri (fun i mask ->
        for q=0 to Array.length by_qubit-1 do
          if bit mask q then by_qubit.(q)<-i::by_qubit.(q)
        done) a;
      Array.map Array.of_list by_qubit in
    let data = a,incident in
    fun sy free rem ->
      if !left=0 then raise Exhausted;
      decr left; row_hint data sy free rem in
  let prepare_index rows =
    let a=Array.of_list(List.mapi(fun i r->r,singleton1 i)rows) in
    fun i -> if i<0 || i>=Array.length a then bad_row,none1 else a.(i) in
  {logical_lines;prepare_index;propose;make_choice;membership}
