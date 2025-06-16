let rec diff_impl ptr patch a b =
  match a, b with
  | `Assoc obj_a, `Assoc obj_b -> object_diff ptr patch obj_a obj_b
  | `List array_a, `List array_b -> array_diff ptr patch array_a array_b
  | a, b when Yojson.Safe.equal a b -> patch
  | _, _ -> patch @ [ Jsonpatch.Replace (ptr, b) ]

and array_diff ptr patch a b =
  let len_a = List.length a in
  let len_b = List.length b in
  let max_len = max len_a len_b in
  let rec loop idx shift patch =
    if idx >= max_len
    then patch
    else (
      let current_ptr = ptr @ [ Jsonpointer.ArrayIndex (idx - shift) ] in
      let a_elem = if idx < len_a then Some (List.nth a idx) else None in
      let b_elem = if idx < len_b then Some (List.nth b idx) else None in
      let new_patch =
        match a_elem, b_elem with
        | Some a_val, Some b_val ->
          (* Both arrays have an element at this index *)
          diff_impl current_ptr patch a_val b_val
        | Some _, None ->
          (* Left array has element, right doesn't - remove it *)
          patch @ [ Jsonpatch.Remove current_ptr ]
        | None, Some b_val ->
          (* Right array has element, left doesn't - add it *)
          patch @ [ Jsonpatch.Add (current_ptr, b_val) ]
        | None, None ->
          (* This case shouldn't happen given our loop condition *)
          patch
      in
      let new_shift =
        if Option.is_some a_elem && Option.is_none b_elem then shift + 1 else shift
      in
      loop (idx + 1) new_shift new_patch)
  in
  loop 0 0 patch

and object_diff ptr patch a b =
  (* Add or replace keys in the right object *)
  let patch_after_adds =
    List.fold_left
      (fun acc_patch (key, b_elem) ->
         let current_ptr = ptr @ [ Jsonpointer.ObjectKey key ] in
         match List.assoc_opt key a with
         | Some a_elem ->
           (* Key exists in both - recursively diff the values *)
           diff_impl current_ptr acc_patch a_elem b_elem
         | None ->
           (* Key only exists in right - add it *)
           Jsonpatch.Add (current_ptr, b_elem) :: acc_patch)
      patch
      b
  in
  (* Remove keys that are not in the right object *)
  List.fold_left
    (fun acc_patch (key, _) ->
       if List.assoc_opt key b = None
       then (
         let current_ptr = ptr @ [ Jsonpointer.ObjectKey key ] in
         Jsonpatch.Remove current_ptr :: acc_patch)
       else acc_patch)
    patch_after_adds
    a
;;

let diff a b = diff_impl [] [] a b
