type specimen =
  | Specimen: {
  definition: ('args, 'node, 'state) Definition.t ;
  args: 'args } -> specimen 
let idToSpecimen = (Hashtbl.create 16 : (string, specimen) Hashtbl.t)
let register (definition : ('args, 'node, 'state) Definition.t)
  (initialArgs : 'args) =
  Hashtbl.add idToSpecimen definition.friendlyId
    (Specimen { definition; args = initialArgs })
let all () =
  ((idToSpecimen |> Hashtbl.to_seq) |> List.of_seq) |> (List.map snd)