open Mesh

let material =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/materials/brass/specular.png"
    ~normalTexture:"assets/materials/brass/normal.png"
    ~specularTexture:"assets/materials/brass/specular.png" ()

let asset =
  Mesh.mesh ~friendlyId:"ShellCase"
    ~postProcess:
      (MeshProcessor.chain
         [
           MeshProcessor.remapMaterial material;
           MeshProcessor.rotateAxis (Babylon.Vector3.right 1.0) (Float.pi /. 2.0);
           MeshProcessor.scalef 0.01;
         ])
    (Mesh.Loader.fromPrimitive (fun () ->
         Babylon.MeshBuilder.Cylinder.create ()))
