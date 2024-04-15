# yojsonpatch

This library provides a way to apply JSON patches to Yojson values following the [RFC 6902](https://tools.ietf.org/html/rfc6902) specification.

This library does not generate JSON patches, it only applies them.

## Documentation

### Jsonpatch Module

The Jsonpatch module allows creating, applying, and manipulating JSON patches.
It cannot generate a patch by calculating the differences between two JSON documents.

#### Exceptions

`Invalid_operation of string`: Exception raised for invalid operations.
`Invalid_patch of string`: Exception raised for invalid JSON patches.
`Operation_error of string`: Exception raised for errors during operations.
`Operation_not_implemented of string`: Exception raised for unimplemented operations.

#### Operations

`Add (target, value`): Adds value at the specified target location. Use - for the index to insert at the end of an array.
`Remove target`: Removes the value at the specified target location.
`Replace (target, value)`: Replaces the value at target with value.
`Move (source, destination)`: Moves the value from source to destination.
`Copy (source, destination)`: Copies the value from source to destination.
`Test (target, value)`: Checks if the value at target matches value.

#### Types

`type operation`: Represents JSON Patch RFC 6902 operations.
`type t`: Represents a JSON patch, which is a list of operations that can be applied to a document to achieve the desired state.

#### Functions

`pp : Format.formatter -> t -> unit`: Prints a JSON patch.
`from_string : string -> t`: Parses a string into a JSON patch.
`from_json : Yojson.Safe.t -> t`: Parses a JSON value into a JSON patch.
`apply : Yojson.Safe.t -> t -> Yojson.Safe.t`: Applies a JSON patch to a JSON document and returns the patched document.

#### Operations Constructors

`add : string -> string -> operation`: Builds an Add operation from a JSON pointer and JSON value strings.
`remove : string -> operation`: Builds a Remove operation from a JSON pointer string.
`replace : string -> string -> operation`: Builds a Replace operation from a JSON pointer and JSON value strings.
`copy : string -> string -> operation`: Builds a Copy operation from JSON pointer strings.
`move : string -> string -> operation`: Builds a Move operation from JSON pointer strings.
`test : string -> string -> operation`: Builds a Test operation from a JSON pointer and JSON value strings.

## Examples

```Ocaml
open Yojsonpatch
open Jsonpatch

(** Define a json document, it must be converted to a Yojson.Safe.t *)
let doc_str = {|
{
  "title": "UNIX: A History and a Memoir"
}
|}

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
  Format.printf
    "Original doc:\n%s\nPatched doc:\n%s\n"
    (Yojson.Safe.pretty_to_string doc)
    (Yojson.Safe.pretty_to_string patched_doc)
;;
```

To run the example:

```
» dune build
» dune exec example/example.exe
Original doc:
{ "title": "UNIX: A History and a Memoir" }
Patched doc:
{
  "title": "UNIX: A History and a Memoir",
  "author": "Brian W. Kernighan",
  "published": 2020,
  "publisher": "Kindle Direct Publishing",
  "stars": 5,
  "purchased": "2019-10-22"
}
```

## TODO

- [x] Create `.mli` files to export the required API
- [ ] Add more tests/fix skipped tests
- [ ] May be remove Core depdendency
- [ ] Implement JSON patches generation
- [ ] Publish it to opam

## Related projects

- [yojson](https://github.com/ocaml-community/yojson)

## License

Apache 2.0 - https://www.apache.org/licenses/LICENSE-2.0.txt
