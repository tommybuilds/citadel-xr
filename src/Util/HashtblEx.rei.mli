val merge :
  ('key, 'a) Hashtbl.t ->
    ('key, 'b) Hashtbl.t ->
      f:('key ->
           [ `Left of 'a  | `Right of 'b  | `Both of ('a * 'b) ] -> 'c option)
        -> ('key, 'c) Hashtbl.t