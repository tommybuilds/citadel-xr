open Babylon
open React3d
type model = {
  hands: HandContext.t list ;
  grabHandles: Shape.t list }
let initial = ({ hands = []; grabHandles = [] } : model)
let shapeToRenderable =
  function
  | Shape.Sphere { position; radius } ->
      P.transform ~position
        [P.sphere ~material:Material.wireframe ~diameter:(radius *. 2.) []]
let yellow = Babylon.Color.make ~r:1. ~g:1.0 ~b:0.0
let white = Babylon.Color.make ~r:1. ~g:1.0 ~b:1.0
let green = Babylon.Color.make ~r:0. ~g:1.0 ~b:0.0
let emptyColor = Material.color yellow
let squeezingColor = Material.color white
let grabbingColor = Material.color green
let handToRenderable hand =
  let open HandContext in
    match hand.mode with
    | Squeezing ->
        P.transform ~position:(hand.position)
          [P.box ~material:squeezingColor ~size:0.1 []]
    | Empty ->
        P.transform ~position:(hand.position)
          [P.sphere ~material:emptyColor ~diameter:0.1 []]
    | Grabbing _ ->
        P.transform ~position:(hand.position)
          [P.cylinder ~material:grabbingColor ~diameter:0.1 ~height:0.1 []]
let render model =
  let handles = model.grabHandles |> (List.map shapeToRenderable) in
  let hands = model.hands |> (List.map handToRenderable) in
  P.transform (hands @ handles)
let component =
  (EntityManager.Component.readwrite
     ~name:"System_Renderable.DebugVisualizer.component" () : (EntityManager.Component.readwrite,
                                                                model)
                                                                EntityManager.Component.t)
let entity =
  (((EntityManager.Entity.define initial) |>
      (System_Renderable.Entity.renderable render))
     |>
     (EntityManager.Entity.withReadWriteComponent component
        ~read:(fun model -> model)
        ~write:(fun grabHandles -> fun model -> grabHandles)) : (unit, 
                                                                  model)
                                                                  EntityManager.Entity.definition)