(* Exercise the extracted checker, independently of the speed of its adviser. *)
open Pcm_generated

let check n checks same p a b =
  let raw = {width=n; check_count=List.length checks; same_count=List.length same;
             checks=List.concat checks; same_bytes=List.concat same} in
  raw_dual_check raw p a b

let examples = ref 0
let expect name result wanted =
  incr examples;
  if result <> wanted then failwith name

let () =
  let hx = [[1;0;1;0]; [0;1;0;1]] in
  let hz = List.rev hx and id = [0;1;2;3] and ix = [1;0] in
  expect "row reordering" (check 4 hz hx id ix ix) true;
  List.iter (fun p -> expect "invalid coordinates" (check 4 hz hx p ix ix) false)
    [[0;0;2;3]; [0;1;2]; [0;1;2;4]; [1;2;0;3]];
  List.iter (fun bad ->
    expect "bad forward image" (check 4 hz hx id bad ix) false;
    expect "bad inverse image" (check 4 hz hx id ix bad) false)
    [[0;1];[1];[1;2];[1;0;0]];
  let x = [[1;1;0;0]] and z = [[0;0;1;1]] in
  expect "nonidentity involution" (check 4 z x [2;3;0;1] [0] [0]) true;
  expect "same dimensions but different rows" (check 4 z x id [0] [0]) false;
  expect "forward cover alone is insufficient"
    (check 4 x (x@z) id [0] [0;0]) false;
  for n = 1 to 6 do
    let id = List.init n Fun.id in
    for i = 0 to (1 lsl n)-1 do
      let row = List.init n (fun j -> (i lsr j) land 1) in
      expect "identity covers arbitrary rows" (check n [row] [row] id [0] [0]) true;
      let opposite = List.map ((lxor) 1) row in
      expect "changed row rejected" (check n [row] [opposite] id [0] [0]) false
    done
  done;
  expect "malformed storage rejected by adviser"
    (Dual_advice.propose 4 (4,1,[1]) (4,1,[1;0;1;0]) = None) true;
  Printf.printf "%d extracted dual-certificate checks passed\n" !examples
