let material =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/flashlight/albedo.png"
    ~normalTexture:"assets/flashlight/normal.png" ()

let target =
  Mesh.mesh
    ~postProcess:
      (let open Mesh.MeshProcessor in
      chain
        [
          remapMaterial material;
          scalef 0.01;
          rotate
            (Babylon.Quaternion.rotateAxis ~axis:(Babylon.Vector3.up 1.0)
               (Float.pi /. 2.0));
        ])
    (Mesh.Loader.fromFile "assets/flashlight/flashlight.glb")