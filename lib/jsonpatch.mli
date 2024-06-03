(** Jsonpatch module allows creating, applying, and manipulating JSON patches. *)

exception Operation_error of string
exception Invalid_operation of string
exception Invalid_patch of string
exception Test_failed of string

(** JSON Patch RFC 6902 operations.
    - [Add (target, value)] adds [value] at the specified [target] location. Use [-] for index to insert at end of array.
    - [Remove target] removes the value at the specified [target] location.
    - [Replace (target, value)] replaces the value at [target] with [value].
    - [Move (source, destination)] moves the value from [source] to [destination].
    - [Copy (source, destination)] copies the value from [source] to [destination].
    - [Test (target, value)] checks if the value at [target] matches [value]. *)
type operation =
  | Add of Jsonpointer.t * Yojson.Safe.t
  | Remove of Jsonpointer.t
  | Replace of Jsonpointer.t * Yojson.Safe.t
  | Move of Jsonpointer.t * Jsonpointer.t
  | Copy of Jsonpointer.t * Jsonpointer.t
  | Test of Jsonpointer.t * Yojson.Safe.t

(** a Json patch is a list of operations which can be applied to a document to reach the desired state *)
type t = operation list

(** [pp fmt patch] prints [patch] into [fmt]. *)
val pp : Format.formatter -> t -> unit

(** [from_string s] parses [s] into a JSON patch. *)
val from_string : string -> t

(** [from_json s] parses [s] into a JSON patch. *)
val from_json : Yojson.Safe.t -> t

(** [to_json patch] returns a JSON patch as a Yojson.Safe.t *)
val to_json : t -> Yojson.Safe.t

(** [apply doc patch] applies [patch] into [doc], returning a patched doc. *)
val apply : Yojson.Safe.t -> t -> Yojson.Safe.t

(** Builds n [Add] operation from a JSON pointer and JSON value strings *)
val add : string -> string -> operation

(** Builds a [Remove] operation from a JSON pointer string*)
val remove : string -> operation

(** Builds a [Replace] operation from a JSON pointer and JSON value strings *)
val replace : string -> string -> operation

(** Builds a [Copy] operation from JSON pointer strings *)
val copy : string -> string -> operation

(** Builds a [Copy] operation from JSON pointer strings *)
val move : string -> string -> operation

(** Builds a [Test] operation from a JSON pointer and JSON value strings *)
val test : string -> string -> operation
