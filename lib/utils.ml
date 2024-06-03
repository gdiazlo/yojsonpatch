(** Some of these functions have been extracted from other libraries such as Base from Jane Street. *)
exception Index_out_of_bounds of int

let substr_replace_all pattern replacement str =
  let re = Str.regexp pattern in
  Str.global_substitute re (fun _ -> replacement) str
;;

(** Derived form Base library at https://github.com/janestreet/base/ *)
let rec list_drop n t =
  match t with
  | _ :: tl when n > 0 -> list_drop (n - 1) tl
  | t -> t
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
  if i < 0 then raise (Index_out_of_bounds i) else split i [] lst
;;

(** Derived form Base library at https://github.com/janestreet/base/ *)
let split_n n t_orig =
  if n <= 0
  then [], t_orig
  else (
    let rec loop n t accum =
      match t with
      | [] -> t_orig, [] (* in this case, t_orig = rev accum *)
      | hd :: tl -> if n = 0 then List.rev accum, t else loop (n - 1) tl (hd :: accum)
    in
    loop n t_orig [])
;;

(** Derived form Base library at https://github.com/janestreet/base/ *)
let list_take n t_orig =
  if n <= 0
  then []
  else (
    let rec loop n t accum =
      match t with
      | [] -> t_orig
      | hd :: tl -> if n = 0 then List.rev accum else loop (n - 1) tl (hd :: accum)
    in
    loop n t_orig [])
;;

(** Derived form Base library at https://github.com/janestreet/base/ *)
let nth t n =
  if n < 0
  then None
  else (
    let rec nth_aux t n =
      match t with
      | [] -> None
      | a :: t -> if n = 0 then Some a else nth_aux t (n - 1)
    in
    nth_aux t n)
;;

(** Derived form Base library at https://github.com/janestreet/base/ *)
let list_nth_exn n t =
  match nth t n with
  | None -> raise (Index_out_of_bounds n)
  | Some a -> a
;;
