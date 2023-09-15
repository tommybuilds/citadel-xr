open Babylon
type t =
  | Sphere of {
  radius: float ;
  position: Vector3.t } 
let sphere ~radius  position = Sphere { radius; position }
let transform ~position  ~rotation  shape =
  let matrix =
    Matrix.compose ~scale:Vector3.one ~rotation ~translation:position in
  match shape with
  | Sphere { radius; position } ->
      let position' = Matrix.transformCoordinates matrix position in
      Sphere { radius; position = position' }
let contains ~point  shape =
  match shape with
  | Sphere { radius; position } ->
      (Vector3.lengthSquared (Vector3.subtract point position)) <
        (radius *. radius)