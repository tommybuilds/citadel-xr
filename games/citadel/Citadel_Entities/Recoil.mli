type t
val create : unit -> t
val update : deltaTime:float -> t -> t
val component : t -> React3d.element list -> React3d.element
val transform : t -> Babylon.Matrix.t
val kick : horizontal:float -> vertical:float -> kickback:float -> t -> t
val computeMuzzlePositionAndRotation :
  position:Babylon.Vector3.t ->
    muzzleOffset:Babylon.Vector3.t ->
      rotation:Babylon.Quaternion.t ->
        t -> (Babylon.Vector3.t * Babylon.Quaternion.t)