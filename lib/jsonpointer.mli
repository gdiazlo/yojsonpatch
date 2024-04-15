(** Jsonpointer module provides utilities for working with JSON pointers. *)

exception Invalid_pointer of string

type part =
  | Root
  | ObjectKey of string
  | ArrayIndex of int
  | ArrayAppend

type t = part list

(** [empty] represents an empty JSON pointer. *)
val empty : t

(** [from_string s] parses [s] into a JSON pointer. *)
val from_string : string -> t

(** [pointer str] parses [str] into a [Jsonpointer.t] *)
val pointer : string -> t

(** [pp fmt pointer] prints a JSON pointer into [fmt]. *)
val pp : Format.formatter -> t -> unit

(** [is_descendant src dst] determines if [dst] is a descendant of [src]. *)
val is_descendant : t -> t -> bool

(** [equal ptr1 ptr2] returns true if [ptr1] and [ptr2] are equal. *)
val equal : t -> t -> bool

(** [iter ptr ~f] iterates over each part of the JSON pointer [ptr], applying function [f]. *)
val iter : t -> f:(part -> unit) -> unit

(** [fold_left ptr ~init ~f] folds over the JSON pointer [ptr] from left to right with initial value [init] and function [f]. *)
val fold_left : t -> init:'a -> f:('a -> part -> 'a) -> 'a

(** [len ptr] returns the length of the JSON pointer [ptr]. *)
val len : t -> int

(** [to_list ptr] converts the JSON pointer [ptr] into a list of parts. *)
val to_list : t -> part list
