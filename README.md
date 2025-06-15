# yojsonpatch

This library provides a way to apply JSON patches to Yojson values following the [RFC 6902](https://tools.ietf.org/html/rfc6902) specification.

## Documentation

### Modules

The library consists of three main modules:

#### `Jsonpatch` - Creating and applying JSON patches

The core module for working with JSON patches. A patch is a list of operations that can transform one JSON document into another.

**Types:**
- `operation` - Represents a single JSON patch operation (Add, Remove, Replace, Move, Copy, Test)
- `t` - A JSON patch (list of operations)

**Key functions:**
```ocaml
(* Parse a JSON patch from string *)
val from_string : string -> t

(* Apply a patch to a JSON document *)
val apply : Yojson.Safe.t -> t -> Yojson.Safe.t

(* Convert a patch to JSON *)
val to_json : t -> Yojson.Safe.t
```

**Convenience functions for creating operations:**
```ocaml
val add : string -> string -> operation      (* Add value at path *)
val remove : string -> operation            (* Remove value at path *)
val replace : string -> string -> operation (* Replace value at path *)
val copy : string -> string -> operation    (* Copy from source to destination *)
val move : string -> string -> operation    (* Move from source to destination *)
val test : string -> string -> operation    (* Test if value at path matches *)
```

#### `Jsondiff` - Generating patches by comparing documents

Generate JSON patches by comparing two JSON documents.

```ocaml
(* Generate a patch that transforms document 'a' into document 'b' *)
val diff : Yojson.Safe.t -> Yojson.Safe.t -> Jsonpatch.t
```

#### `Jsonpointer` - JSON Pointer utilities

Handles JSON Pointer paths (RFC 6901) used to identify locations within JSON documents.

**Types:**
- `part` - Components of a JSON pointer (ObjectKey, ArrayIndex, etc.)
- `t` - A JSON pointer (list of parts)

**Key functions:**
```ocaml
val from_string : string -> t    (* Parse JSON pointer from string *)
val to_string : t -> string      (* Convert JSON pointer to string *)
val equal : t -> t -> bool       (* Compare two JSON pointers *)
```

### Basic Usage

1. **Applying a patch:**
```ocaml
let doc = Yojson.Safe.from_string {|{"name": "John"}|} in
let patch = Jsonpatch.[add "/age" "30"] in
let result = Jsonpatch.apply doc patch
```

2. **Generating a patch:**
```ocaml
let original = Yojson.Safe.from_string {|{"name": "John"}|} in
let modified = Yojson.Safe.from_string {|{"name": "Jane", "age": 30}|} in
let patch = Jsondiff.diff original modified
```

3. **Working with JSON pointers:**
```ocaml
let ptr = Jsonpointer.from_string "/users/0/name" in
let path_str = Jsonpointer.to_string ptr
```

## Examples

```Ocaml
open Yojsonpatch
open Jsonpatch
(** Define a json document, it must be converted to a Yojson.Safe.t *)
let doc_str =
  {|
{
  "title": "UNIX: A History and a Memoir"
}
|}
;;

(** We can create a patch from its JSON form as a string using the
    [Jsonpatch.from_string str] function or using convenience
    functions like add below *)
let patch =
  [ add "/author" {|"Brian W. Kernighan"|}
  ; add "/published" "2020"
  ; add "/publisher" {|"Kindle Direct Publishing"|}
  ; add "/stars" "5"
  ; add "/purchased" {|"2019-10-22"|}
  ]
;;

let () =
  let doc = Yojson.Safe.from_string doc_str in
  let patched_doc = Jsonpatch.apply doc patch in
  let gen_patch = Jsondiff.diff doc patched_doc in
  Format.printf
    "Original doc:\n%s\nPatch:\n%s\nPatched doc:\n%s\nGenerated patch:\n%s\n"
    (Yojson.Safe.pretty_to_string doc)
    (Yojson.Safe.pretty_to_string (to_json patch))
    (Yojson.Safe.pretty_to_string patched_doc)
    (Yojson.Safe.pretty_to_string (to_json gen_patch))
;;

```

To run the example:

```
Original doc:
{ "title": "UNIX: A History and a Memoir" }
Patch:
[
  { "op": "add", "path": "author", "value": "Brian W. Kernighan" },
  { "op": "add", "path": "published", "value": 2020 },
  { "op": "add", "path": "publisher", "value": "Kindle Direct Publishing" },
  { "op": "add", "path": "stars", "value": 5 },
  { "op": "add", "path": "purchased", "value": "2019-10-22" }
]
Patched doc:
{
  "title": "UNIX: A History and a Memoir",
  "author": "Brian W. Kernighan",
  "published": 2020,
  "publisher": "Kindle Direct Publishing",
  "stars": 5,
  "purchased": "2019-10-22"
}
Generated patch:
[
  { "op": "add", "path": "purchased", "value": "2019-10-22" },
  { "op": "add", "path": "stars", "value": 5 },
  { "op": "add", "path": "publisher", "value": "Kindle Direct Publishing" },
  { "op": "add", "path": "published", "value": 2020 },
  { "op": "add", "path": "author", "value": "Brian W. Kernighan" }
]
```
## Benchmarks

Using the program in `example/jp`, we've applied a 45MB patch to a 17MB document
generating a 26MB of prettified patched document in around 14 secs, using less than 1GB
of memory in a Apple M1 CPU.

Don't know if this is good or bad yet.

## TODO

- [x] Create `.mli` files to export the required API
- [x] Add more tests
- [ ] fix skipped tests
- [x] May be remove Core depdendency
- [x] Implement JSON patches generation
- [ ] Publish it to opam
- [ ] Benchmarks

## Related projects

- [yojson](https://github.com/ocaml-community/yojson)
- Rust [json-patch](https://github.com/idubrov/json-patch/), on which this lib is based

## License

Apache 2.0 - https://www.apache.org/licenses/LICENSE-2.0.txt
