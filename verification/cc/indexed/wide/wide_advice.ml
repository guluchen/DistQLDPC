open Wide_generated

let word x = Int64.to_int (Uint63.to_int64 x)
let words w =
  let a=w.first_part and b=w.second_part in
  [|word a.low;word a.middle;word a.high;word b.low;word b.middle;word b.high|]
let bit a q = a.(q/63) land (1 lsl (q mod 63)) <> 0
let positions n f =
  let a=Array.make 6 0 in
  for i=0 to n-1 do if f i then a.(i/63) <- a.(i/63) lor (1 lsl (i mod 63)) done; a

let propose n rows =
  let data=Array.of_list (List.map (fun r -> words r.support_mask) rows) in
  let basis=Array.make n None in
  let reduce w =
    for i=0 to n-1 do
      if bit w i then match basis.(i) with
        | None -> () | Some r -> for j=i/63 to 5 do w.(j)<-w.(j) lxor r.(j) done
    done in
  Array.iter (fun row ->
    let w=Array.copy row in reduce w;
    let rec insert i = if i<n then if bit w i then basis.(i)<-Some w else insert (i+1) in
    insert 0) data;
  let shift block step i = i-i mod block+(i mod block+step) mod block in
  let blocks=List.filter(fun b->b>=2 && n mod b=0)(List.init (n+1) Fun.id) in
  let shifts=List.concat_map(fun b->
    List.filter_map(fun step->if step>0 && b mod step=0 then Some(b,step) else None)
      (List.init b Fun.id)) blocks in
  let done_root=Array.make n false in
  let gain b step =
    let count=ref 0 in
    for i=0 to n-1 do if not done_root.(i) && shift b (b-step) i<i then incr count done;
    !count in
  let preserves b step = Array.for_all (fun row->
    let w=positions n (fun i->bit row (shift b step i)) in
    reduce w;Array.for_all ((=) 0) w) data in
  let rec pick left candidates =
    if left=0 then [] else
    let scored=List.filter_map(fun (b,s)->let g=gain b s in
      if g=0 then None else Some(g,b,s)) candidates in
    let sorted=List.sort(fun (g,_,_) (h,_,_)->compare h g) scored in
    let rec first=function
      | [] -> []
      | (_,b,s)::tail ->
        if not(preserves b s) then first tail else begin
          let inv=shift b (b-s) in
          for i=0 to n-1 do if inv i<i then done_root.(i)<-true done;
          (List.init n (shift b s),List.init n inv)::
            pick (left-1) (List.map(fun (_,k,t)->k,t)tail)
        end
    in first sorted
  in pick 3 shifts

exception Exhausted
external row_hint : (int array array * int array array) -> bits0 -> bits0 -> int -> hint = "caml_wide_hint"

(* A linear signature commutes with every column XOR. The extracted checker
   also verifies every required entry in the immutable filter. *)
external signature : bits0 -> int = "caml_wide_hash" [@@noalloc]
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

let make_advice ~logical_lines ?(extra_roots=Fun.id) limit pair_pack =
  let left=ref limit in
  let make_choice rows =
    let a=Array.of_list(List.map(fun r->words r.support_mask)rows) in
    let incident =
      if not pair_pack then [||] else
      let by_qubit = Array.make 378 [] in
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
    let a=Array.of_list(List.mapi(fun i r->r,singleton0 i)rows) in
    fun i -> if i<0 || i>=Array.length a then bad_row,none0 else a.(i) in
  {logical_lines;prepare_index;propose=(fun n rows -> extra_roots (propose n rows));make_choice;membership}
