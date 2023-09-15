open Babylon
open EntityManager
open Util
let isPointReachable handPosition maxGrabDistance position =
  Math.pointInSphere ~point:handPosition ~sphereRadius:maxGrabDistance
    ~spherePosition:position
let getHolsterInRange (world : ReadOnlyWorld.t) (handPosition : Vector3.t) =
  let isPointReachable = isPointReachable handPosition in
  let isHolsterReachable idAndHolster =
    let open Holster in
      let holster = idAndHolster |> snd in
      isPointReachable holster.size holster.position in
  let allHolsters =
    (world |> (ReadOnlyWorld.valuesi Holster.component)) |>
      (List.filter isHolsterReachable) in
  (List.nth_opt allHolsters 0) |>
    (OptionEx.flatMap
       (fun (holsterId, holster) ->
          (ReadOnlyWorld.read world ~entityId:holsterId
             HolsterState.component)
            |>
            (Option.map
               (fun holsterState -> (holsterId, holster, holsterState)))))
let getDropTargetInRange world (payloads : Payload.Abstract.t list)
  (handPosition : Vector3.t) =
  let allGrabbables = world |> (ReadOnlyWorld.valuesi Grabbable.component) in
  let getPayloadTargetInRange payload =
    let candidateGrabbables =
      allGrabbables |>
        (List.filter_map
           (fun (entityId, grabbable) ->
              let grabbable' =
                grabbable |> (Grabbable.onlyDropTargets payload) in
              if grabbable'.handles = []
              then None
              else Some (entityId, payload))) in
    List.nth_opt candidateGrabbables 0 in
  payloads |>
    (List.fold_left
       (fun acc ->
          fun payload ->
            match acc with
            | Some _ as s -> s
            | None -> getPayloadTargetInRange payload) None)
let getEmptyHolsterInRange (world : ReadOnlyWorld.t)
  (holsterType : Holster.Type.t) (handPosition : Vector3.t) =
  (getHolsterInRange world handPosition) |>
    (OptionEx.flatMap
       (fun (holsterId, holster, holsterState) ->
          let targetHolsterType = holster |> Holster.holsterType in
          match holsterState with
          | HolsterState.Empty | HolsterState.Hovered when
              Holster.Type.equals holsterType targetHolsterType ->
              Some holsterId
          | _ -> None))
let getFullHolsterInRange (world : ReadOnlyWorld.t)
  (handPosition : Vector3.t) =
  (getHolsterInRange world handPosition) |>
    (OptionEx.flatMap
       (fun (holsterId, _holster, holsterState) ->
          match holsterState with
          | HolsterState.Empty | HolsterState.Hovered -> None
          | HolsterState.Full { entityId } -> Some entityId))
let getSecondaryGrabbableInRange world position =
  let allSecondaryGrabbables =
    (world |> (ReadOnlyWorld.valuesi Grabbable.component)) |>
      (List.filter_map
         (fun (entityId, grabbable) ->
            let isSecondaryGrabbable grabHandle =
              (grabHandle |> Grabbable.handleType) = Grabbable.Secondary in
            let secondaryHandles =
              (grabbable |> Grabbable.expand) |>
                (List.filter isSecondaryGrabbable) in
            (List.nth_opt secondaryHandles 0) |>
              (Option.map (fun handle -> (entityId, handle))))) in
  let candidateGrabbables =
    allSecondaryGrabbables |>
      (List.filter
         (fun (entityId, grabHandle) ->
            (grabHandle |> Grabbable.shape) |>
              (Shape.contains ~point:position))) in
  List.nth_opt candidateGrabbables 0
let getHolsterType ~entityId:(entityId : EntityId.t) 
  (world : ReadOnlyWorld.t) =
  let maybeGrabbable = ReadOnlyWorld.read world ~entityId Grabbable.component in
  match maybeGrabbable with
  | None -> Holster.Type.none
  | Some grabbable -> Grabbable.holsterType grabbable