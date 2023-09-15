open Babylon

type t =
  | Box of { dimensions : Vector3.t }
  | Capsule of { radius : float; height : float }
  | Sphere of { radius : float }

let box ?(width = 1.0) ?(height = 1.0) ?(depth = 1.0) () =
  let dimensions = Vector3.create ~x:width ~y:height ~z:depth in
  Box { dimensions }

let capsule ?(radius = 0.5) ?(height = 1.0) () = Capsule { radius; height }
let sphere ?(radius = 1.0) () = Sphere { radius }
