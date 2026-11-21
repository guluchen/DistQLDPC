external reverse_bfs : int -> bytes -> int array = "caml_ccv_reverse_bfs"

let order enabled n (_, rows, flat) =
  if not enabled || rows = 0 then [] else
  let cells = Bytes.create (n*rows) in
  List.iteri (fun i bit -> Bytes.set cells i (Char.chr bit)) flat;
  Array.to_list (reverse_bfs n cells)
