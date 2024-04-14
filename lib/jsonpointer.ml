open Core

exception Invalid_pointer of string

type part =
  | Root
  | ObjectKey of string
  | ArrayIndex of int
  | ArrayAppend

type pointer = part list

let empty : pointer = []

let unescape str =
  let str = String.substr_replace_all ~pattern:"~1" ~with_:"/" str in
  String.substr_replace_all ~pattern:"~0" ~with_:"~" str
;;

let to_part str : part =
  match int_of_string_opt str with
  | Some pos -> ArrayIndex pos
  | None ->
    (match str with
     | "-" -> ArrayAppend
     | _ -> ObjectKey str)
;;

(** [from_string s] parses [s] into a JSON pointer *)
let from_string s : pointer =
  if String.length s <> 0 && not (Char.equal (String.get s 0) '/')
  then raise (Invalid_pointer "path must start with '/'")
  else (
    match s with
    | "" -> empty
    | "/" -> empty
    | _ ->
      let l = String.split s ~on:'/' |> List.map ~f:unescape |> List.map ~f:to_part in
      List.drop l 1)
;;

let pp_part fmt part =
  match part with
  | Root -> Format.fprintf fmt ""
  | ObjectKey key -> Format.fprintf fmt "/%s" key
  | ArrayIndex index -> Format.fprintf fmt "/%d" index
  | ArrayAppend -> Format.fprintf fmt "/-"
;;

(** [pp fmt pointer] prints a JSON pointer into [fmt] *)
let rec pp fmt pointer =
  match pointer with
  | [] -> ()
  | [ part ] -> pp_part fmt part
  | part :: rest -> Format.fprintf fmt "%a%a" pp_part part pp rest
;;

(** [is_descendant src dst] determines if [dst] is a descendant of [src] *)
let rec is_descendant src dst =
  let cmp p1 p2 =
    match p1, p2 with
    | ObjectKey o1, ObjectKey o2 when String.equal o1 o2 -> true
    | ArrayIndex i1, ArrayIndex i2 when i1 = i2 -> true
    | _, _ -> false
  in
  match src, dst with
  | hd :: tl, hd' :: tl' when cmp hd hd' -> is_descendant tl tl'
  | [], _ -> true
  | _, _ -> false
;;

let equal_part p1 p2 =
  match p1, p2 with
  | Root, Root -> true
  | ObjectKey s1, ObjectKey s2 -> String.equal s1 s2
  | ArrayIndex i1, ArrayIndex i2 -> i1 = i2
  | ArrayAppend, ArrayAppend -> true
  | _ -> false
;;

(** [equal ptr1 ptr2] returns true if [ptr1] and [ptr2] are equal. They will if all their parts are also equal. *)
let rec equal ptr1 ptr2 =
  match ptr1, ptr2 with
  | [], [] -> true (* both empty lists *)
  | part1 :: rest1, part2 :: rest2 ->
    if equal_part part1 part2 then equal rest1 rest2 else false
  | _, _ -> false (* different lengths *)
;;

let iter ptr ~f = List.iter ptr ~f
let fold_left ptr ~init ~f = List.fold_left ptr ~init ~f
let len ptr = List.length ptr
let to_list ptr = ptr
