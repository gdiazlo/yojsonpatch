(lang dune 3.13)

(name yojsonpatch)

(generate_opam_files true)

(source
 (github gdiazlo/yojsonpatch))

(authors "Gabriel Díaz")

(maintainers "Gabriel Díaz")

(license LICENSE)

(documentation https://github.com/gdiazlo/yojsonpatch)

(package
 (name yojsonpatch)
 (synopsis "A jsonpatch implementation for yojson")
 (description "This library provides a jsonpatch implementation for yojson. It is based on the RFC 6902.")
 (depends ocaml dune yojson core)
 (tags
  (topics jsonpatch yojson)))
