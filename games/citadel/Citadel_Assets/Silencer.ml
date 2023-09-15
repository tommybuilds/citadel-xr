let material =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/silencer/black_diffuse.png"
    ~normalTexture:"assets/silencer/black_normal.png"
    ~specularTexture:"assets/silencer/black_specular.png" ()

let mesh =
  Mesh.mesh
    ~postProcess:(Mesh.MeshProcessor.remapMaterial material)
    (Mesh.Loader.fromFile "assets/silencer/silencer.glb")