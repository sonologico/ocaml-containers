
open OUnit

module H = PersistentHashtbl.Make(struct type t = int let equal = (=) let hash i = i end)
open Gen.Infix

let test_add () =
  let h = H.create 32 in
  let h = H.replace h 42 "foo" in
  OUnit.assert_equal (H.find h 42) "foo"

let my_list = 
  [ 1, "a";
    2, "b";
    3, "c";
    4, "d";
  ]

let my_gen = Gen.of_list my_list

let test_of_gen () =
  let h = H.of_gen my_gen in
  OUnit.assert_equal "b" (H.find h 2);
  OUnit.assert_equal "a" (H.find h 1);
  OUnit.assert_raises Not_found (fun () -> H.find h 42);
  ()

let test_to_gen () =
  let h = H.of_gen my_gen in
  let l = Gen.to_list (H.to_gen h) in
  OUnit.assert_equal my_list (List.sort compare l)

let test_resize () =
  let h = H.of_gen
    (Gen.map (fun i -> i, string_of_int i)
      (Gen.int_range 0 200)) in
  OUnit.assert_equal 201 (H.length h);
  ()

let test_persistent () =
  let h = H.of_gen my_gen in
  OUnit.assert_equal "a" (H.find h 1);
  OUnit.assert_raises Not_found (fun () -> H.find h 5);
  let h' = H.replace h 5 "e" in
  OUnit.assert_equal "a" (H.find h' 1);
  OUnit.assert_equal "e" (H.find h' 5);
  OUnit.assert_equal "a" (H.find h 1);
  OUnit.assert_raises Not_found (fun () -> H.find h 5);
  ()

let test_big () =
  let n = 10000 in
  let gen = Gen.map (fun i -> i, string_of_int i) (0--n) in
  let h = H.of_gen gen in
  (*
  Format.printf "@[<v2>table:%a@]@." (Gen.pp_gen
    (fun formatter (k,v) -> Format.fprintf formatter "%d -> \"%s\"" k v))
    (H.to_gen h);
  *)
  Gen.iter
    (fun (k,v) ->
      (*
      Format.printf "lookup %d@." k;
      *)
      OUnit.assert_equal ~printer:(fun x -> x) v (H.find h k))
    gen;
  OUnit.assert_raises Not_found (fun () -> H.find h (n+1));
  ()

let test_remove () =
  let h = H.of_gen my_gen in
  OUnit.assert_equal (H.find h 2) "b";
  OUnit.assert_equal (H.find h 3) "c";
  OUnit.assert_equal (H.find h 4) "d";
  OUnit.assert_equal (H.length h) 4;
  let h = H.remove h 2 in
  OUnit.assert_equal (H.find h 3) "c";
  OUnit.assert_equal (H.length h) 3;
  (* test that 2 has been removed *)
  OUnit.assert_raises Not_found (fun () -> H.find h 2)

let test_size () =
  let open Gen.Infix in
  let n = 10000 in
  let gen = Gen.map (fun i -> i, string_of_int i) (0 -- n) in
  let h = H.of_gen gen in
  OUnit.assert_equal (n+1) (H.length h);
  let h = Gen.fold (fun h i -> H.remove h i) h (0 -- 500) in
  OUnit.assert_equal (n-500) (H.length h);
  OUnit.assert_bool "is_empty" (H.is_empty (H.create 16));
  ()

let suite =
  "test_H" >:::
    [ "test_add" >:: test_add;
      "test_of_gen" >:: test_of_gen;
      "test_to_gen" >:: test_to_gen;
      "test_resize" >:: test_resize;
      "test_persistent" >:: test_persistent;
      "test_big" >:: test_big;
      "test_remove" >:: test_remove;
      "test_size" >:: test_size;
    ]