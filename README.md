# yojsonpatch

This library provides a way to apply JSON patches to Yojson values following the [RFC 6902](https://tools.ietf.org/html/rfc6902) specification.

This library does not generate JSON patches, it only applies them.

## Documentation

TODO

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
    "Original doc:\n%s\nPatch:\n%s\nPatched doc:\n%s\n"
    (Yojson.Safe.pretty_to_string doc)
    (Yojson.Safe.pretty_to_string (to_json patch))
    (Yojson.Safe.pretty_to_string patched_doc)
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
```

## TODO

- [x] Create `.mli` files to export the required API
- [ ] Add more tests/fix skipped tests
- [x] May be remove Core depdendency
- [ ] Implement JSON patches generation
- [ ] Publish it to opam

## Related projects

- [yojson](https://github.com/ocaml-community/yojson)

## License

Apache 2.0 - https://www.apache.org/licenses/LICENSE-2.0.txt
