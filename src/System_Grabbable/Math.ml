open Babylon
let pointInSphere ~point  ~sphereRadius  ~spherePosition  =
  (Vector3.lengthSquared (Vector3.subtract point spherePosition)) <
    (sphereRadius *. sphereRadius)