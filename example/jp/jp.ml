let () =
  let doc_file = Sys.argv.(1) in
  let patch_file = Sys.argv.(2) in
  let doc = Yojson.Safe.from_file doc_file in
  let patch = Yojson.Safe.from_file patch_file |> Yojsonpatch.Jsonpatch.from_json in
  Yojsonpatch.Jsonpatch.apply doc patch |> Yojson.Safe.pretty_to_channel stdout
;;
