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

(** [to_string ptr] returns a JSON pointer as a string. *)
val to_string : t -> string

(** [pp fmt pointer] prints a JSON pointer into [fmt]. *)
val pp : Format.formatter -> t -> unit

(** [is_descendant src dst] determines if [dst] is a descendant of [src]. *)
val is_descendant : t -> t -> bool

(** [equal ptr1 ptr2] returns true if [ptr1] and [ptr2] are equal. *)
val equal : t -> t -> bool

(** [iter ptr ~f] iterates over each part of the JSON pointer [ptr], applying function [f]. *)
val iter : ('a -> unit) -> 'a list -> unit

(** [append ptr part] appends [part] to the JSON pointer [ptr]. *)
val fold_left : ('a -> 'b -> 'a) -> 'a -> 'b list -> 'a

(** [length ptr] returns the length of the JSON pointer [ptr]. *)
val length : t -> int
