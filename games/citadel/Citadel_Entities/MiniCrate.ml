let crateMesh = Mesh.mesh (Mesh.Loader.fromFile "assets/crate2_out/crate2.gltf")
let size = 0.04
let scale = size /. 0.4
let shape = System_Physics.Shape.box ~width:size ~height:size ~depth:size ()

let render () =
  let open React3d in
  P.transform ~scale:(Vector3.create1 scale)
    ~position:(Vector3.up (-0.4 *. scale))
    [ P.mesh crateMesh ]

let entity position () =
  BaseGrabbable.entity ~mass:100. ~position ~physicsShape:shape render ()
  |> System_Grabbable.Entity.suppliesPayload Payloads.glockClip (fun _ -> 17)
