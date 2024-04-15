open Core

exception Invalid_operation of string
exception Invalid_patch of string
exception Operation_error of string
exception Test_failed of string

type operation =
  | Add of Jsonpointer.t * Yojson.Safe.t
  | Remove of Jsonpointer.t
  | Replace of Jsonpointer.t * Yojson.Safe.t
  | Move of Jsonpointer.t * Jsonpointer.t
  | Copy of Jsonpointer.t * Jsonpointer.t
  | Test of Jsonpointer.t * Yojson.Safe.t

type t = operation list

let operation_pp fmt operation =
  match operation with
  | Add (path, value) ->
    Format.fprintf fmt "Add %a %a" Jsonpointer.pp path Yojson.Safe.pp value
  | Remove path -> Format.fprintf fmt "Remove %a" Jsonpointer.pp path
  | Replace (path, value) ->
    Format.fprintf fmt "Replace %a %a" Jsonpointer.pp path Yojson.Safe.pp value
  | Move (path, new_path) ->
    Format.fprintf fmt "Move %a %a" Jsonpointer.pp path Jsonpointer.pp new_path
  | Copy (path, new_path) ->
    Format.fprintf fmt "Copy %a %a" Jsonpointer.pp path Jsonpointer.pp new_path
  | Test (path, value) ->
    Format.fprintf fmt "Test %a %a" Jsonpointer.pp path Yojson.Safe.pp value
;;

let pp fmt patch =
  Format.fprintf fmt "[";
  List.iter patch ~f:(fun op -> operation_pp fmt op);
  Format.fprintf fmt "]"
;;

let has_member name = function
  | `Assoc l ->
    (try List.Assoc.find_exn l ~equal:String.equal name with
     | _ -> raise (Invalid_operation ("missing '" ^ name ^ "' parameter")))
  | _ -> raise (Invalid_operation "op is not an object")
;;

let not_null k = function
  | `Null -> raise (Invalid_operation ("'" ^ k ^ "' can't be null"))
  | obj -> obj
;;

let op_from_json json =
  try
    let open Yojson.Safe.Util in
    let op = json |> has_member "op" |> not_null "op" |> to_string in
    let ptr key json =
      json |> has_member key |> not_null key |> to_string |> Jsonpointer.from_string
    in
    match op with
    | "add" ->
      let value = json |> has_member "value" in
      let path = ptr "path" json in
      Add (path, value)
    | "remove" ->
      let path = ptr "path" json in
      Remove path
    | "replace" ->
      let value = json |> has_member "value" in
      let path = ptr "path" json in
      Replace (path, value)
    | "move" ->
      let from = ptr "from" json in
      let path = ptr "path" json in
      Move (from, path)
    | "copy" ->
      let from = ptr "from" json in
      let path = ptr "path" json in
      Copy (from, path)
    | "test" ->
      let value = json |> has_member "value" in
      let path = ptr "path" json in
      Test (path, value)
    | _ -> raise (Invalid_operation "invalid op type")
  with
  | Yojson.Json_error msg -> raise (Invalid_operation msg)
  | Yojson.Safe.Util.Type_error (msg, _) -> raise (Invalid_operation msg)
;;

let from_json json =
  match json with
  | `List l -> List.map l ~f:(fun op -> op_from_json op)
  | _ -> raise (Invalid_patch "patch must be an array of operations")
;;

let from_string s =
  try
    let json = Yojson.Safe.from_string s in
    from_json json
  with
  | Yojson.Json_error msg -> raise (Invalid_patch msg)
;;

let to_json patch =
  let operations =
    patch
    |> List.map ~f:(fun op ->
      match op with
      | Add (ptr, v) ->
        `Assoc
          [ "op", `String "add"; "path", `String (Jsonpointer.to_string ptr); "value", v ]
      | Remove ptr ->
        `Assoc [ "op", `String "remove"; "path", `String (Jsonpointer.to_string ptr) ]
      | Replace (ptr, v) ->
        `Assoc
          [ "op", `String "replace"
          ; "path", `String (Jsonpointer.to_string ptr)
          ; "value", v
          ]
      | Move (src, dst) ->
        `Assoc
          [ "op", `String "move"
          ; "from", `String (Jsonpointer.to_string src)
          ; "path", `String (Jsonpointer.to_string dst)
          ]
      | Copy (src, dst) ->
        `Assoc
          [ "op", `String "copy"
          ; "from", `String (Jsonpointer.to_string src)
          ; "path", `String (Jsonpointer.to_string dst)
          ]
      | Test (ptr, v) ->
        `Assoc
          [ "op", `String "test"
          ; "path", `String (Jsonpointer.to_string ptr)
          ; "value", v
          ])
  in
  `List operations
;;

let safe_add ptr_part doc =
  match ptr_part, doc with
  | Jsonpointer.Root, `String _ -> `Assoc [ "", doc ]
  | Jsonpointer.Root, `Int _ -> `Assoc [ "", doc ]
  | Jsonpointer.Root, `Bool _ -> `Assoc [ "", doc ]
  | Jsonpointer.Root, `Float _ -> `Assoc [ "", doc ]
  | Jsonpointer.ObjectKey k, _ -> `Assoc [ k, doc ]
  | _, _ -> doc
;;

let split_assoc key assoc_list =
  let rec split pre elem post = function
    | [] -> List.rev pre, elem, List.rev post
    | (k, v) :: tail ->
      (match String.equal k key, elem with
       | true, None -> split pre (Some (k, v)) post tail
       | _, _ -> split ((k, v) :: pre) elem post tail)
  in
  split [] None [] assoc_list
;;

let split_at_index i lst =
  let rec split i acc = function
    | [] -> List.rev acc, None, []
    | hd :: tl ->
      if i = 0 then List.rev acc, Some hd, tl else split (i - 1) (hd :: acc) tl
  in
  if i < 0 then raise (Operation_error "index out of bounds") else split i [] lst
;;

let is_empty = function
  | [] -> true
  | _ -> false
;;

let apply_add ptr value doc =
  let rec _add parent p doc =
    match doc, p with
    | `List l, Jsonpointer.ArrayAppend :: _ -> `List (l @ [ value ])
    | `Assoc l, Jsonpointer.ArrayIndex i :: [] -> `Assoc (l @ [ string_of_int i, value ])
    | `List l, Jsonpointer.ArrayIndex i :: tl ->
      if i > List.length l || i < 0
      then raise (Operation_error "index out of bounds")
      else if is_empty tl
      then (
        let pre, post = List.split_n l i in
        `List (pre @ [ value ] @ post))
      else (
        let pre, e, post = split_at_index i l in
        match e with
        | Some e ->
          let v' = _add (Jsonpointer.ArrayIndex i) tl e in
          `List (pre @ [ v' ] @ post)
        | None -> raise (Operation_error "unable to find element in araray"))
    | `Assoc l, Jsonpointer.ObjectKey k :: tl ->
      if is_empty tl
      then (
        let pre, _, post = split_assoc k l in
        `Assoc (pre @ [ k, value ] @ post))
      else (
        let pre, e, post = split_assoc k l in
        match e with
        | None -> raise (Operation_error "missing objects are not created recursively")
        | Some (k, v) ->
          let v' = _add (Jsonpointer.ObjectKey k) tl v in
          `Assoc (pre @ [ k, v' ] @ post))
    | _, [] -> safe_add parent value
    | _ -> raise (Operation_error "path not found")
  in
  _add Jsonpointer.Root ptr doc
;;

let rec apply_remove ptr doc =
  match doc, ptr with
  | _, [] -> raise (Operation_error "cannot remove an empty pointer")
  | `List l, Jsonpointer.ArrayIndex i :: tl ->
    if i > List.length l
    then raise (Operation_error "index out of bounds")
    else (
      let h = List.take l i in
      let t = List.drop l (i + 1) in
      let e =
        if List.length l <= i
        then raise (Operation_error "unable to remove, invalid path")
        else List.nth_exn l i
      in
      if List.length tl = 0 then `List (h @ t) else `List (h @ [ apply_remove tl e ] @ t))
  | `Assoc l, Jsonpointer.ObjectKey k :: tl ->
    (match List.Assoc.find l ~equal:String.equal k with
     | None -> `Assoc l
     | Some e ->
       let nl = List.filter l ~f:(fun (key, _) -> not (String.equal key k)) in
       if List.length tl > 0
       then (
         let v = apply_remove tl e in
         `Assoc ((k, v) :: nl))
       else `Assoc (List.Assoc.remove l ~equal:String.equal k))
  | _ -> raise (Operation_error "unable to remove, invalid path")
;;

let rec apply_replace ptr (value : Yojson.Safe.t) doc =
  match doc, ptr with
  | _, [] -> value
  | `List l, Jsonpointer.ArrayIndex i :: tl ->
    if i > List.length l || i < 0
    then raise (Operation_error "index out of bounds")
    else if List.length tl > 0
    then (
      let pre, e, post = split_at_index i l in
      match e with
      | Some e ->
        let v' = apply_replace tl value e in
        `List (pre @ [ v' ] @ post)
      | None -> raise (Operation_error "unable to find element in araray"))
    else (
      let pre, e, post = split_at_index i l in
      match e with
      | Some _ -> `List (pre @ [ value ] @ post)
      | None -> raise (Operation_error "unable to find element in araray"))
  | `Assoc l, Jsonpointer.ObjectKey k :: tl ->
    if List.length tl > 0
    then (
      let pre, e, post = split_assoc k l in
      match e with
      | None -> raise (Operation_error "missing objects cannot be replaced")
      | Some (k, v) ->
        let v' = apply_replace tl value v in
        `Assoc (pre @ [ k, v' ] @ post))
    else (
      let pre, _, post = split_assoc k l in
      `Assoc (pre @ [ k, value ] @ post))
  | _ -> raise (Operation_error "unable to replace, invalid path")
;;

let rec eval ptr doc =
  match doc, ptr with
  | v, [] -> v
  | `List l, Jsonpointer.ArrayIndex i :: tl ->
    (match List.nth l i with
     | Some e -> eval tl e
     | None -> raise (Operation_error "element path not found in array"))
  | `Assoc l, Jsonpointer.ObjectKey k :: tl ->
    (match List.Assoc.find l ~equal:String.equal k with
     | None -> raise (Operation_error ("key '" ^ k ^ "' not found in object"))
     | Some e -> eval tl e)
  | _ -> raise (Operation_error "path not found")
;;

let apply_copy from path doc =
  let value = eval from doc in
  apply_add path value doc
;;

let apply_move src dst doc =
  if Jsonpointer.equal src dst
  then doc
  else if Jsonpointer.is_descendant src dst
  then
    raise
      (Operation_error "the destination path cannot be a descendant of the source path")
  else (
    let value = eval src doc in
    let cleaned = apply_remove src doc in
    apply_add dst value cleaned)
;;

let apply_test value path doc =
  let v = eval path doc in
  let msg = Format.asprintf "test operation failed, value not equal" in
  if Yojson.Safe.equal value v then v else raise (Test_failed msg)
;;

let rec apply doc patch =
  match patch with
  | op :: tl ->
    let patched_doc =
      match op with
      | Add (path, value) -> apply_add path value doc
      | Remove path -> apply_remove path doc
      | Replace (path, value) -> apply_replace path value doc
      | Copy (from, path) -> apply_copy from path doc
      | Move (from, path) -> apply_move from path doc
      | Test (path, value) ->
        let _ = apply_test value path doc in
        doc
    in
    apply patched_doc tl
  | [] -> doc
;;

let add ptr value = Add (Jsonpointer.from_string ptr, Yojson.Safe.from_string value)
let remove ptr = Remove (Jsonpointer.from_string ptr)
let replace ptr value = Add (Jsonpointer.from_string ptr, Yojson.Safe.from_string value)
let copy src dst = Copy (Jsonpointer.from_string src, Jsonpointer.from_string dst)
let move src dst = Move (Jsonpointer.from_string src, Jsonpointer.from_string dst)
let test ptr value = Test (Jsonpointer.from_string ptr, Yojson.Safe.from_string value)
