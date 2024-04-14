# yojsonpatch

This library provides a way to apply JSON patches to Yojson values following the [RFC 6902](https://tools.ietf.org/html/rfc6902) specification.

This library does not generate JSON patches, it only applies them.

## Documentation

TODO

## Examples

```Ocaml
open Yojsonpatch

let doc_str = {|
{
  "title": "UNIX: A History and a Memoir"
}
|}

let patch_str =
  {|
[
  {"op": "add", "path": "/author", "value": "Brian W. Kernighan"},
  {"op": "add", "path": "/publication", "value": 2020}
]
|}
;;

let () =
  let patch = Jsonpatch.from_string patch_str in
  let doc = Yojson.Safe.from_string doc_str in
  let patched_doc = Jsonpatch.apply doc patch in
  Format.printf
    " Original doc:\n%s\nPatched doc:\n%s\n"
    (Yojson.Safe.pretty_to_string doc)
    (Yojson.Safe.pretty_to_string patched_doc)
;;
```

To run the example:

```
$ dune build example
$ dune exec example/example.exe
Original doc:
{ "title": "UNIX: A History and a Memoir" }
Patched doc:
{
 "title": "UNIX: A History and a Memoir",
 "author": "Brian W. Kernighan",
 "publication": 2020
}
```

## TODO

- [ ] Create `.mli` files to export the required API
- [ ] Add more tests/fix skipped tests
- [ ] May be remove Core depdendency
- [ ] Implement JSON patches generation
- [ ] Publish it to opam

## Related projects

- [yojson](https://github.com/ocaml-community/yojson)

## License

Apache 2.0 - https://www.apache.org/licenses/LICENSE-2.0.txt
