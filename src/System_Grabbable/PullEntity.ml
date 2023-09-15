open Babylon
open React3d
type model =
  {
  hand: HandContext.t ;
  lastHit: Vector3.t option ;
  physicsSystem:
    System_Physics.System.context EntityManager.System.definition ;
  grabSystem: System.context EntityManager.System.definition }
let grabDistance = 5.0
type msg =
  | RaycastResult of Vector3.t * System_Physics.RayCastResult.t 
let think ~deltaTime  world model =
  let hand = model.hand in
  let newState = (model.hand).getState () in
  let (hand', isSqueezing, isTriggerPressed, isButton1Pressed,
       isButton2Pressed)
    =
    match newState with
    | None -> ((model.hand), false, false, false, false)
    | Some controller ->
        ({
           hand with
           position = (Input.HandController.position controller);
           rotation = (Input.HandController.rotation controller)
         },
          ((Input.HandController.squeeze controller) |>
             Input.Button.isPressed),
          ((Input.HandController.trigger controller) |>
             Input.Button.isPressed),
          ((Input.HandController.button1 controller) |>
             Input.Button.isPressed),
          ((Input.HandController.button2 controller) |>
             Input.Button.isPressed)) in
  let (hand'', eff) =
    if isSqueezing
    then
      match hand'.mode with
      | HandContext.Squeezing ->
          let maybeHolsteredEntity =
            Helpers.getFullHolsterInRange world hand'.position in
          (match maybeHolsteredEntity with
           | None ->
               let maybeSecondaryGrabbable =
                 Helpers.getSecondaryGrabbableInRange world hand'.position in
               (match maybeSecondaryGrabbable with
                | Some (entityId, _) ->
                    let payloads =
                      (EntityManager.ReadOnlyWorld.read world entityId
                         Payload.component)
                        |> (Option.value ~default:[]) in
                    ((hand' |>
                        (HandContext.grab ~payloads ~entityId
                           ~holsterType:Holster.Type.none
                           ~handleType:Grabbable.Secondary)),
                      EntityManager.Effect.none)
                | None ->
                    let forward =
                      Quaternion.rotateVector (Vector3.forward grabDistance)
                        hand'.rotation in
                    let eff =
                      (System_Physics.Effects.rayCast
                         ~position:(hand'.position) ~direction:forward
                         model.physicsSystem)
                        |>
                        (EntityManager.Effect.map
                           (fun msg -> RaycastResult ((hand'.position), msg))) in
                    (hand', eff))
           | Some holsteredEntity ->
               let holsterType =
                 Helpers.getHolsterType ~entityId:holsteredEntity world in
               let payloads =
                 (EntityManager.ReadOnlyWorld.read world holsteredEntity
                    Payload.component)
                   |> (Option.value ~default:[]) in
               ((hand' |>
                   (HandContext.grab ~payloads ~entityId:holsteredEntity
                      ~holsterType ~handleType:Grabbable.Primary)),
                 EntityManager.Effect.none))
      | HandContext.Empty ->
          ((HandContext.squeeze hand'), EntityManager.Effect.none)
      | HandContext.Grabbing _ -> (hand', EntityManager.Effect.none)
    else
      (match hand'.mode with
       | HandContext.Squeezing ->
           ((hand' |> HandContext.release), EntityManager.Effect.none)
       | HandContext.Empty -> (hand', EntityManager.Effect.none)
       | HandContext.Grabbing { holsterType; payloads; entityId } ->
           let maybeDropTarget =
             Helpers.getDropTargetInRange world payloads hand'.position in
           (match maybeDropTarget with
            | Some (targetId, payload) ->
                ((hand' |> HandContext.release),
                  (Effects.dropOnto ~targetEntity:targetId ~payload
                     ~droppingEntity:entityId System.system))
            | None ->
                let maybeHolster =
                  Helpers.getEmptyHolsterInRange world holsterType
                    hand'.position in
                let eff =
                  match maybeHolster with
                  | None -> EntityManager.Effect.none
                  | Some holsterId ->
                      Effects.holster ~entityToHolster:entityId
                        ~holster:holsterId model.grabSystem in
                ((hand' |> HandContext.release), eff))) in
  ({
     model with
     hand =
       { hand'' with isTriggerPressed; isButton1Pressed; isButton2Pressed }
   }, eff)
let update world msg model =
  match msg with
  | RaycastResult
      (handPosition, System_Physics.RayCastResult.Hit
       { entityId; position; normal })
      ->
      let hand' =
        match EntityManager.ReadOnlyWorld.read world ~entityId
                Grabbable.component
        with
        | None -> model.hand
        | Some grabbable ->
            let holsterType = grabbable |> Grabbable.holsterType in
            let payloads =
              (EntityManager.ReadOnlyWorld.read world entityId
                 Payload.component)
                |> (Option.value ~default:[]) in
            HandContext.grab ~payloads ~entityId ~holsterType
              ~handleType:Grabbable.Primary model.hand in
      ({ model with lastHit = (Some position); hand = hand' },
        EntityManager.Effect.none)
  | RaycastResult _ -> (model, EntityManager.Effect.none)
let render model =
  let position = model.lastHit |> (Option.value ~default:(Vector3.zero ())) in
  let hand = model.hand in
  let rotation =
    Quaternion.rotateAxis ~axis:(Vector3.right 1.0) (Float.pi /. 2.) in
  let height = grabDistance in
  let tubePosition = Vector3.up (height /. 2.) in
  let vec = Vector3.create ~x:1.0 ~y:grabDistance ~z:1.0 in
  let scale = match hand.mode with | Squeezing -> vec | _ -> Vector3.zero () in
  P.transform
    [P.transform ~position:(hand.position) ~rotation:(hand.rotation)
       [P.transform ~rotation
          [P.transform ~position:tubePosition ~scale
             [P.cylinder ~diameter:0.02 ~height:1.0 []]]];
    P.transform ~position [P.box ~size:0.2 []]]
let entity getState physicsSystem grabSystem =
  let open EntityManager.Entity in
    ((((define
          {
            lastHit = None;
            hand = { HandContext.initial with getState };
            physicsSystem;
            grabSystem
          })
         |> (withThinkW think))
        |> (withUpdateW update))
       |> (System_Renderable.Entity.renderable render))
      |>
      (EntityManager.Entity.withReadonlyComponent HandContext.component
         (fun model -> [model.hand]))