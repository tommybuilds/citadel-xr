open Babylon
open EntityManager
type effects =
  | Holster of {
  holsterId: EntityId.t ;
  entityId: EntityId.t } 
type context = {
  isFirstFrame: bool ;
  pendingEffects: effects list ref }
type grabHandleWithExtraData =
  {
  entityId: EntityId.t ;
  postTransformGrabHandle: Grabbable.grabHandle }
let getBestGrabCandidate (grabbables : grabHandleWithExtraData list)
  (position : Vector3.t) =
  let sorted =
    grabbables |>
      (List.filter
         (fun grabHandleWithExtraData ->
            (grabHandleWithExtraData.postTransformGrabHandle |>
               Grabbable.shape)
              |> (Shape.contains ~point:position))) in
  List.nth_opt sorted 0
let filterHolstersByType (holsterType : Holster.Type.t)
  (holsters : (EntityId.t * Holster.t) list) =
  holsters |>
    (List.filter
       (fun holster ->
          ((snd holster) |> Holster.holsterType) |>
            (Holster.Type.equals holsterType)))
let getBestHolsterCandidate (position : Vector3.t) holsters =
  let sorted =
    holsters |>
      (List.filter
         (fun holster ->
            ((snd holster) |> Holster.shape) |>
              (Shape.contains ~point:position))) in
  List.nth_opt sorted 0
let updateHolsterHover (emptyHolsters : (EntityId.t * Holster.t) list)
  (hands : HandContext.t list) (world : World.t) =
  let open Input in
    hands |>
      (List.fold_left
         (fun acc ->
            fun (hand : HandContext.t) ->
              let maybeController = hand.getState () in
              match maybeController with
              | None -> acc
              | Some controller ->
                  let position = Input.HandController.position controller in
                  let triggerButton = HandController.trigger controller in
                  let isTriggerPressed = triggerButton |> Button.isPressed in
                  let hand =
                    {
                      hand with
                      position;
                      rotation = (Input.HandController.rotation controller);
                      isTriggerPressed
                    } in
                  (match hand.mode with
                   | Squeezing | Empty -> acc
                   | Grabbing { holsterType; entityId } ->
                       let maybeHolster =
                         (emptyHolsters |> (filterHolstersByType holsterType))
                           |> (getBestHolsterCandidate position) in
                       (match maybeHolster with
                        | None -> world
                        | Some holster ->
                            let id = fst holster in
                            EntityManager.World.map_entity
                              ~f:(fun _holsterState -> HolsterState.Hovered)
                              ~entityId:id HolsterState.component world)))
         world)
let expandGrabbable ~entityId  grabbable =
  (grabbable |> Grabbable.expand) |>
    (List.map
       (fun grabHandle -> { entityId; postTransformGrabHandle = grabHandle }))
let updateHeldEntity (hand : HandContext.t) (world : World.t) =
  match hand.mode with
  | HandContext.Squeezing | HandContext.Empty -> world
  | HandContext.Grabbing { entityId; handleType } ->
      (match handleType with
       | DropTarget _ -> world
       | Primary ->
           let newState =
             GrabState.IGrabbed
               {
                 position = (hand.position);
                 rotation = (hand.rotation);
                 isTriggerPressed = (hand.isTriggerPressed);
                 isButton1Pressed = (hand.isButton1Pressed);
                 isButton2Pressed = (hand.isButton2Pressed)
               } in
           world |>
             (World.map_entity
                ~f:(fun grabState ->
                      let open GrabState in
                        { grabState with state = newState }) ~entityId
                GrabState.component)
       | Secondary ->
           world |>
             (World.map_entity
                ~f:(fun grabState ->
                      let open GrabState in
                        {
                          grabState with
                          secondaryGrabPosition = (Some (hand.position))
                        }) ~entityId GrabState.component))
let updateHolsteredEntities (world : World.t) =
  World.fold
    ~f:(fun acc ->
          fun entityId ->
            fun holsterState ->
              let holsterId = entityId in
              match HolsterState.state holsterState with
              | HolsterState.Full { entityId } ->
                  let newState =
                    ((acc |> (World.read ~entity:holsterId Holster.component))
                       |>
                       (Option.map
                          (fun (holsterItem : Holster.t) ->
                             let open Holster in
                               GrabState.IHolstered
                                 {
                                   position = (holsterItem.position);
                                   rotation = (holsterItem.rotation)
                                 })))
                      |>
                      (Option.value
                         ~default:(GrabState.IHolstered
                                     {
                                       position = (Vector3.up 1.0);
                                       rotation = (Quaternion.initial ())
                                     })) in
                  acc |>
                    (World.map_entity
                       ~f:(fun grabState ->
                             let open GrabState in
                               { grabState with state = newState }) ~entityId
                       GrabState.component)
              | _ -> acc) ~initial:world HolsterState.component world
let clearNewlyEmptyHolsters (heldEntities : EntityId.t list)
  (world : World.t) =
  World.fold
    ~f:(fun acc ->
          fun entityId ->
            fun holsterState ->
              let holsterId = entityId in
              match HolsterState.state holsterState with
              | HolsterState.Full { entityId } ->
                  if List.mem entityId heldEntities
                  then
                    World.write ~entity:holsterId ~value:HolsterState.Empty
                      HolsterState.component acc
                  else acc
              | _ -> acc) ~initial:world HolsterState.component world
let updateHeldEntities hands world =
  hands |>
    (List.fold_left (fun acc -> fun hand -> updateHeldEntity hand acc) world)
let isReachable handPositions position =
  handPositions |>
    (List.exists
       (fun handPosition ->
          let maxGrabDistance = 5. in
          Math.pointInSphere ~point:position ~sphereRadius:maxGrabDistance
            ~spherePosition:position))
let updateDebugVisualizer hands candidateGrabbables world =
  let allGrabbables = world |> (World.valuesi Grabbable.component) in
  let candidateGrabbables =
    (allGrabbables |>
       (List.filter
          (fun item ->
             let open Grabbable in
               let grabbable = item |> snd in
               isReachable hands grabbable.position)))
      |>
      (List.concat_map
         (fun item ->
            let entityId = fst item in
            let grabbable = snd item in expandGrabbable ~entityId grabbable)) in
  world |>
    (World.map_componentsi
       ~f:(fun _entityId ->
             fun component ->
               let grabHandles =
                 (candidateGrabbables |>
                    (List.map
                       (fun grabHandleWithExtraData ->
                          grabHandleWithExtraData.postTransformGrabHandle)))
                   |> (List.map Grabbable.shape) in
               let open DebugVisualizerEntity in { hands; grabHandles })
       DebugVisualizerEntity.component)
let processEffect world =
  function
  | Holster { entityId; holsterId } ->
      EntityManager.World.map_entity
        ~f:(fun _holsterState -> HolsterState.Full { entityId })
        ~entityId:holsterId HolsterState.component world
let processPendingEffects context world =
  let world' =
    (!(context.pendingEffects)) |>
      (List.fold_left (fun world -> fun eff -> processEffect world eff) world) in
  context.pendingEffects := []; (context, world')
let tick ~deltaTime:(deltaTime : float)  ~world:(world : World.t)  context =
  let world =
    if context.isFirstFrame
    then world |> (World.instantiate ~entity:DebugVisualizerEntity.entity)
    else world in
  let (context, world) = processPendingEffects context world in
  let hands = (world |> (World.values HandContext.component)) |> List.concat in
  let handPositions =
    hands |> (List.map (fun (hand : HandContext.t) -> hand.position)) in
  let isReachable = isReachable handPositions in
  let world =
    world |>
      (World.map_componentsi
         ~f:(fun _entityId ->
               fun grabState ->
                 let open GrabState in
                   {
                     secondaryGrabPosition = None;
                     state = GrabState.IUngrabbed
                   }) GrabState.component) in
  let holsterStates = world |> (World.valuesi HolsterState.component) in
  let idToHolsterState =
    holsterStates |>
      (List.fold_left
         (fun acc ->
            fun curr ->
              let id = fst curr in
              let holsterState = snd curr in
              Hashtbl.add acc id holsterState; acc) (Hashtbl.create 16)) in
  let allHolsters = world |> (World.valuesi Holster.component) in
  let candidateHolsters =
    allHolsters |>
      (List.filter
         (fun item ->
            let open Holster in
              let holster = item |> snd in isReachable holster.position)) in
  let emptyHolsters =
    candidateHolsters |>
      (List.filter
         (fun item ->
            let id = fst item in
            let maybeState = Hashtbl.find_opt idToHolsterState id in
            match maybeState with
            | Some (HolsterState.Full _) -> false
            | Some (HolsterState.Hovered) -> true
            | Some (HolsterState.Empty) -> true
            | None -> (prerr_endline "Shouldn't happen!"; true))) in
  let clearHoverState (state : HolsterState.t) =
    match state with
    | HolsterState.Full _ as v -> v
    | HolsterState.Hovered -> HolsterState.Empty
    | HolsterState.Empty -> HolsterState.Empty in
  let world =
    World.map_components clearHoverState HolsterState.component world in
  let heldEntities =
    hands |>
      (List.filter_map
         (fun (hand : HandContext.t) ->
            match hand.mode with
            | HandContext.Squeezing | HandContext.Empty -> None
            | HandContext.Grabbing { entityId;_} -> Some entityId)) in
  let world' =
    (((world |> (updateHolsterHover emptyHolsters hands)) |>
        updateHolsteredEntities)
       |> (updateHeldEntities hands))
      |> (clearNewlyEmptyHolsters heldEntities) in
  ({ context with isFirstFrame = false }, world')
let system =
  System.define ~tick { isFirstFrame = true; pendingEffects = (ref []) }