let merge leftHash rightHash ~f  =
  let touched = Hashtbl.create 16 in
  let output = Hashtbl.create 16 in
  let hasVisited key = (Hashtbl.find_opt touched key) <> None in
  let apply key v =
    match f key v with | None -> () | Some c -> Hashtbl.add output key c in
  let visit key =
    if not (hasVisited key)
    then
      let leftV = Hashtbl.find_opt leftHash key in
      let rightV = Hashtbl.find_opt rightHash key in
      ((match (leftV, rightV) with
        | (None, None) -> ()
        | (Some l, None) -> apply key (`Left l)
        | (None, Some r) -> apply key (`Right r)
        | (Some l, Some r) -> apply key (`Both (l, r)));
       Hashtbl.add touched key true) in
  (leftHash |> Hashtbl.to_seq_keys) |> (Seq.iter visit);
  (rightHash |> Hashtbl.to_seq_keys) |> (Seq.iter visit);
  output