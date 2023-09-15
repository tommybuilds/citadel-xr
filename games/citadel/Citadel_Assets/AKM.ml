let akmMaterial =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/akm/diffuse.png"
    ~normalTexture:"assets/akm/normal.png" ()

let mesh =
  Mesh.mesh
    ~postProcess:(Mesh.MeshProcessor.remapMaterial akmMaterial)
    (Mesh.Loader.fromFile "assets/akm/akm.gltf")