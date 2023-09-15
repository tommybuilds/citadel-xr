open Mesh

module Animations = struct
  let run = animation ~startFrame:0. ~endFrame:150.0 "run"
  let idle = animation ~startFrame:180. ~endFrame:330.0 "idle"
  let attack2 = animation ~startFrame:451. ~endFrame:600.0 "idle"
  let die = animation ~loop:false ~startFrame:601. ~endFrame:670.0 "die"
end

let material =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/ghoul/ghoul-color.png"
    ~normalTexture:"assets/ghoul/ghoul-normal.png" ()

let postProcess =
  MeshProcessor.chain
    [
      MeshProcessor.remapMaterial material;
      MeshProcessor.rotateAxis (Babylon.Vector3.right 1.0) (Float.pi /. 2.0);
      MeshProcessor.scalef 0.03;
    ]

let mesh =
  Mesh.animated ~postProcess (Mesh.Loader.fromFile "assets/ghoul/ghoul.glb")