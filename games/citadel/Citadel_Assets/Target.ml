let material =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/target/diffuse.png" ()

let target =
  Mesh.mesh
    ~postProcess:(Mesh.MeshProcessor.remapMaterial material)
    (Mesh.Loader.fromFile "assets/target/target.glb")