(* [diff] returns a [patch] so [a] becomes [b] when applied*)
val diff : Yojson.Safe.t -> Yojson.Safe.t -> Jsonpatch.t
