open Citadel_Entities
module Entity = Citadel_Entities
open Game

module Entities = struct
  let sphere = Entity.Sphere.sphere
  let crate = Entity.Crate.entity
  let miniCrate = Entity.MiniCrate.entity
  let flashlight = Entity.Flashlight.entity
  let pedestal position = Entity.Pedestal.entity position
  let target diameter position = Entity.Target.entity diameter position
  let bolt = Entity.Bolt.entity
  let glock position = Entity.Glock.entity position
  let machineGun position = Entity.MachineGun.entity position
  let laserPointer = Entity.LaserPointer.entity
  let holster = Entity.Holster.entity
  let player = Entity.Player.entity
  let leftHand = Systems.leftHand
  let rightHand = Systems.rightHand
  let staticHolster = Entity.StaticHolster.entity
  let ghoul = Entity.Ghoul.entity
end

let holoMaterial =
  React3d.Material.standard ~uScale:128.0 ~vScale:128.0
    ~diffuseTexture:"assets/holo.png" ~emissiveTexture:"assets/holo.png" ()

let logoMaterial =
  React3d.Material.standard ~invertY:true ~hasAlpha:true
    ~diffuseTexture:"/assets/logo.png" ~emissiveTexture:"/assets/logo.png" ()

let render element =
  let open React3d in
  P.transform
    [
      (* P.plane
         ~position:
           (let open Vector3 in
           add (up 2.0) (forward 25.0))
         ~height:4.0 ~width:8.0 ~material:logoMaterial []; *)
      P.ground ~material:holoMaterial
        ~scale:
          (let open Vector3 in
          create ~x:16. ~y:1.0 ~z:16.)
        ~position:
          (let open Vector3 in
          up 0.0)
        [];
      element;
      P.hemisphericLight ~intensity:0.8 ();
    ]

let scene =
  let gunPosition =
    let open Babylon.Vector3 in
    add (up 2.5) (forward (-2.5))
  in
  let gunPosition1 =
    let open Babylon.Vector3 in
    add gunPosition (right (-1.5))
  in
  let gunPosition2 =
    let open Babylon.Vector3 in
    add gunPosition (right 1.5)
  in
  let crate1Position =
    let open Babylon.Vector3 in
    add (right 0.5) (up 12.0)
  in
  let crate2Position =
    let open Babylon.Vector3 in
    add (right 1.0) (up 1.0)
  in
  let crate3Position =
    let open Babylon.Vector3 in
    add gunPosition (right 1.1)
  in
  let pedestal1Position =
    let open Babylon.Vector3 in
    add (forward (-2.25)) (right (-1.25))
  in
  let pedestal2Position =
    let open Babylon.Vector3 in
    add (forward (-2.25)) (right 1.25)
  in
  let glockPosition1 =
    let open Babylon.Vector3 in
    add gunPosition (right 1.0)
  in
  let glockPosition2 =
    let open Babylon.Vector3 in
    add gunPosition (right (-1.0))
  in
  let rightHolsterOffset =
    let open Babylon.Vector3 in
    add (add (up (-0.6)) (right 0.25)) (forward 0.25)
  in
  let shoulderHolsterOffset =
    let open Babylon.Vector3 in
    add (add (up (-0.2)) (right 0.25)) (forward 0.25)
  in
  let leftHolsterOffset =
    let open Babylon.Vector3 in
    add (add (up (-0.6)) (left 0.25)) (forward 0.25)
  in
  let spawnPosition =
    let open Babylon.Vector3 in
    add (forward (-3.0)) (up 10.)
  in
  let randomPosition () =
    let open Babylon.Vector3 in
    add (forward (Random.float 50.)) (left (Random.float 50.))
  in
  let stationaryHolsterPosition =
    let open Babylon.Vector3 in
    add (forward (-4.0)) (up 1.0)
  in
  let module SB = Game.S.SceneBuilder in
  let system = Game.S.SceneBuilder.system in
  let entity = Game.S.SceneBuilder.entity in
  let entityi = Game.S.SceneBuilder.entityi in
  let static = Game.S.SceneBuilder.static in
  let sceneWithSystems =
    Game.S.SceneBuilder.initial
    |> system Systems.targetSpawner
    |> system Systems.audio |> system Systems.damage |> system Systems.physics
    |> system Systems.grabbable
  in
  let mg, scene =
    sceneWithSystems |> entityi (Entities.machineGun gunPosition1)
  in
  scene
  |> static
       (Citadel_Assets.Crate.mesh
       |> Mesh.Static.static ~position:(Babylon.Vector3.up 1.0))
  |> entity Entities.laserPointer
  |> entity (Entities.player spawnPosition)
  |> entity (Entities.crate crate1Position)
  |> entity (Entities.ghoul (randomPosition ()))
  |> entity (Entities.ghoul (randomPosition ()))
  |> entity (Entities.ghoul (randomPosition ()))
  |> entity (Entities.ghoul (randomPosition ()))
  |> entity (Entities.ghoul (randomPosition ()))
  |> entity (Entities.ghoul (randomPosition ()))
  |> entity (Entities.flashlight crate3Position)
  |> entity (Entity.Silencer.entity crate3Position ())
  |> entity (Entities.pedestal pedestal1Position)
  |> entity (Entities.pedestal pedestal2Position)
  |> entity (Entities.machineGun gunPosition1)
  |> entity (Entities.machineGun gunPosition2)
  |> entity (Entities.glock glockPosition1)
  |> entity (Entities.glock glockPosition2)
  |> entity (Entities.holster leftHolsterOffset HolsterTypes.smallItem)
  |> entity (Entities.holster rightHolsterOffset HolsterTypes.smallItem)
  |> entity (Entities.holster shoulderHolsterOffset HolsterTypes.largeItem)
  |> entity
       (Entities.staticHolster ~entity:mg stationaryHolsterPosition
          HolsterTypes.largeItem)
  |> entity Entities.leftHand |> entity Entities.rightHand
  |> SB.wrapRender (fun element -> render element)
  |> SB.make "DemoScene2"
