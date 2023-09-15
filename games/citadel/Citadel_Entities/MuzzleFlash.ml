let muzzleFlashMaterial =
  React3d.Material.standard ~diffuseTexture:"assets/muzzle-flash2.png"
    ~emissiveTexture:"assets/muzzle-flash2.png"
    ~emissiveColor:Babylon.Color.white ~hasAlpha:true ()
type t = {
  scale: float ;
  lifeTime: float }
let isVisible { lifeTime;_} = lifeTime > 0.0
let make scale = { lifeTime = 0.0; scale }
let flash prev = { prev with lifeTime = 0.1 }
let update deltaTime prev =
  { prev with lifeTime = (prev.lifeTime -. deltaTime) }
let render { lifeTime; scale } =
  let open React3d in
    let renderScale =
      match lifeTime > 0.0 with | true -> scale | false -> 0.0 in
    P.transform
      [P.meshWithArgs
         (let open Mesh.ParticleSystem in { active = (lifeTime > 0.0) })
         Mesh.particleSystem;
      P.plane ~material:muzzleFlashMaterial ~width:renderScale
        ~height:renderScale []]