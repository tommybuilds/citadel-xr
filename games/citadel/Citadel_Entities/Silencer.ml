module Assets = Citadel_Assets

let size = 0.1
let shape = System_Physics.Shape.box ~width:size ~height:size ~depth:size ()

let render () =
  let open React3d in
  P.transform
    ~position:(Vector3.up (-1.0 *. size))
    [ P.mesh Assets.Silencer.mesh ]

let entity position () =
  BaseGrabbable.entity ~mass:100. ~position ~physicsShape:shape render ()
  |> System_Grabbable.Entity.suppliesPayload Payloads.glockSilencer (fun _ ->
         ())
