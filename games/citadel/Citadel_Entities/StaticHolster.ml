open Babylon
open React3d

type model = {
  position : Vector3.t;
  rotation : Quaternion.t;
  holsterOffset : Vector3.t;
  holsterType : System_Grabbable.Holster.Type.t;
  holsterState : System_Grabbable.HolsterState.t;
}

let defaultHolsterOffset = Vector3.zero ()

let material =
  React3d.Material.standard ~hasAlpha:true ~diffuseTexture:"assets/circle.png"
    ~emissiveTexture:"assets/circle.png" ()

let render { position; rotation; holsterState; _ } =
  let size =
    match
      System_Grabbable.HolsterState.state holsterState
      == System_Grabbable.HolsterState.Hovered
    with
    | true -> 0.5
    | false -> 0.1
  in
  let open React3d in
  P.transform ~position
    [ P.plane ~material ~rotation ~width:size ~height:size [] ]

let holsters { position; rotation; holsterType; _ } =
  System_Grabbable.Holster.make ~position ~rotation holsterType

let entity ?entity position (holsterType : System_Grabbable.Holster.Type.t) =
  let open EntityManager.Entity in
  define
    {
      holsterOffset = Vector3.zero ();
      holsterType;
      position;
      rotation = Quaternion.identity ();
      holsterState =
        (match entity with
        | None -> System_Grabbable.HolsterState.initial
        | Some h -> System_Grabbable.HolsterState.full h);
    }
  |> withReadonlyComponent Components.render render
  |> System_Grabbable.Entity.holster
       ~readHolsterState:(fun { holsterState; _ } -> holsterState)
       ~writeHolsterState:(fun holsterState state ->
         { state with holsterState })
       ~holsters
