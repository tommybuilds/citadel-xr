open Babylon

type model = Vector3.t

let initial = (Vector3.zero () : model)
let update _msg model = (model, EntityManager.Effect.none)

let render model =
  let open React3d in
  P.transform ~position:model [ P.sphere ~diameter:1.0 [] ]

let sphere position =
  let open EntityManager.Entity in
  define position |> withUpdate update
  |> withReadonlyComponent Components.render render
