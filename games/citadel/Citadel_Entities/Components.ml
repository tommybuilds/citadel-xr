open Babylon
open EntityManager
let render = System_Renderable.Components.render
type target = {
  position: Vector3.t ;
  radius: float }
let target : (Component.readonly, target) Component.t =
  Component.readonly ~name:"Citadel.target" ()
let bolt : (Component.readonly, Vector3.t) Component.t =
  Component.readonly ~name:"Citadel.bolt" ()