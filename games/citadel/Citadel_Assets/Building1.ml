let material =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/Desert_Building_V1_AlbedoTransparency.png"
    ~normalTexture:"assets/Desert_Building_V1_Normal.png" ()

let mesh =
  Mesh.mesh
    ~postProcess:(Mesh.MeshProcessor.remapMaterial material)
    (Mesh.Loader.fromFile "assets/building1.glb")