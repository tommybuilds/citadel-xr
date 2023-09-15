open Babylon
open React3d
open System_Grabbable
open Citadel_Assets

type 'innerModel model = {
  rotation : Quaternion.t;
  position : Vector3.t;
  grabState : System_Grabbable.GrabState.t;
  physicsState : System_Physics.State.t;
  mass : float;
  physicsShape : System_Physics.Shape.t;
  thinkFn :
    deltaTime:float -> grabState:GrabState.t -> 'innerModel -> 'innerModel;
  renderFn : 'innerModel -> React3d.element;
  handlePosition : Vector3.t;
  innerModel : 'innerModel;
}

let initial ~mass ~physicsShape ~position ~renderFn ~thinkFn ~handlePosition
    innerModel =
  {
    mass;
    handlePosition;
    position;
    rotation = Quaternion.zero ();
    grabState = System_Grabbable.GrabState.initial ();
    renderFn;
    thinkFn;
    physicsShape;
    physicsState =
      System_Physics.State.create ~mass ~initialPosition:position
        ~initialRotation:(Quaternion.initial ()) physicsShape;
    innerModel;
  }

let baseThink ~deltaTime model =
  let model', eff =
    match model.grabState |> GrabState.state with
    | GrabState.Grabbed { position; rotation; _ } ->
        let physicsState' =
          System_Physics.State.create ~mass:model.mass ~initialPosition:position
            ~initialRotation:rotation model.physicsShape
        in
        ( { model with physicsState = physicsState'; position; rotation },
          EntityManager.Effect.none )
    | GrabState.Ungrabbed ->
        let physicsState = model.physicsState in
        let model' =
          {
            model with
            position = physicsState |> System_Physics.State.position;
            rotation = physicsState |> System_Physics.State.rotation;
          }
        in
        (model', EntityManager.Effect.none)
  in
  let innerModel' =
    model.thinkFn ~deltaTime ~grabState:model'.grabState model'.innerModel
  in
  ({ model' with innerModel = innerModel' }, eff)

let render { renderFn; position; rotation; grabState; innerModel; _ } =
  match grabState |> GrabState.state with
  | GrabState.Ungrabbed ->
      let open React3d in
      P.transform [ P.transform ~position ~rotation [ renderFn innerModel ] ]
  | GrabState.Grabbed _ ->
      let open React3d in
      P.transform [ P.transform ~position ~rotation [ renderFn innerModel ] ]

let grabHandles model =
  let position =
    match System_Grabbable.GrabState.state model.grabState with
    | GrabState.Grabbed _ -> model.position
    | GrabState.Ungrabbed -> model.position
  in
  System_Grabbable.Grabbable.make ~position ~rotation:model.rotation
    ~holsterType:HolsterTypes.smallItem
    [ Grabbable.primary (Shape.sphere ~radius:0.2 model.handlePosition) ]

let defaultPhysicsShape =
  System_Physics.Shape.box ~width:0.5 ~height:0.5 ~depth:0.5 ()

let entity ?(mass = 5.0) ?(physicsShape = defaultPhysicsShape)
    ?(handlePosition = Vector3.zero ()) ?(position = Vector3.zero ())
    ?(think = fun ~deltaTime ~grabState model -> model) renderFn innerModel =
  let open EntityManager.Entity in
  define
    (initial ~mass ~physicsShape ~renderFn ~thinkFn:think ~handlePosition
       ~position innerModel)
  |> withThink baseThink
  |> withReadonlyComponent Components.render render
  |> System_Grabbable.Entity.grabbable
       ~readGrabState:(fun { grabState; _ } -> grabState)
       ~writeGrabState:(fun grabState state -> { state with grabState })
       ~grabHandles
  |> System_Physics.Entity.dynamic
       ~read:(fun { grabState; physicsState; _ } ->
         match grabState |> GrabState.state with
         | GrabState.Ungrabbed -> Some physicsState
         | GrabState.Grabbed _ -> None)
       ~write:(fun state entity ->
         match state with
         | None -> entity
         | Some state -> { entity with physicsState = state })
