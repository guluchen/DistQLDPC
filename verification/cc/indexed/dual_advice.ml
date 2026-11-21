(* Optional advice for the extracted raw_dual_check. Failure keeps both halves. *)
let index_rows n count flat =
  let bytes = Bytes.create (n*count) in
  List.iteri (fun i bit -> Bytes.set bytes i (Char.chr bit)) flat;
  let rows = Array.init count (fun r -> Bytes.sub_string bytes (r*n) n) in
  let lookup = Hashtbl.create count in
  Array.iteri (fun i row -> Hashtbl.replace lookup row i) rows;
  rows, lookup

let propose n (_, xcount, xflat) (_, zcount, zflat) =
  if n > 4096 || xcount <> zcount || xcount = 0 || List.length xflat <> n*xcount || List.length zflat <> n*zcount then None else
  let x, xt = index_rows n xcount xflat and z, zt = index_rows n zcount zflat in
  let images perm rows targets =
    Array.to_list (Array.map (fun row ->
      Hashtbl.find targets (String.init n (fun i -> row.[perm.(i)]))) rows)
  in
  let check perm =
    try Some (Array.to_list perm, images perm z xt, images perm x zt)
    with Not_found -> None
  in
  match check (Array.init n Fun.id) with
  | Some _ as cert -> cert
  | None when n mod 2 <> 0 -> None
  | None ->
    let half = n/2 in
    let rec next b =
      if b > half then None
      else if half mod b <> 0 then next (b+1)
      else
        let a = half/b in
        let perm = Array.init n (fun i ->
          let k = i mod half in
          (1-i/half)*half + ((a-k/b) mod a)*b + (b-k mod b) mod b)
        in match check perm with Some _ as c -> c | None -> next (b+1)
    in next 1
