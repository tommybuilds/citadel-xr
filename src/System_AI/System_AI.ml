module Category = struct
  let uniqueId = ref 0

  type t = { id : int; name : string }

  let define name =
    incr uniqueId;
    { id = !uniqueId; name }
end

type componentInfo = { category : Category.t; position : Babylon.Vector3.t }

let component =
  (EntityManager.Component.readonly ~name:"System_AI.category" ()
    : ( EntityManager.Component.readonly,
        componentInfo )
      EntityManager.Component.t)

module Entity = struct
  let categorize ~category queryPosition entity =
    entity
    |> EntityManager.Entity.withReadonlyComponent component (fun state ->
           { category; position = queryPosition state })
end

module World = struct
  let getNearestEntityOfCategory ~position ~(category : Category.t)
      (world : EntityManager.ReadOnlyWorld.t) =
    let isMatchingEntity (entityCategory : Category.t) =
      category.id = entityCategory.id
    in
    let entitiesByDistance =
      world
      |> EntityManager.ReadOnlyWorld.valuesi component
      |> List.filter (fun (id, component) ->
             isMatchingEntity component.category)
      |> List.sort (fun aEntity bEntity ->
             let aPos = (snd aEntity).position in
             let bPos = (snd bEntity).position in
             let aDist =
               Babylon.Vector3.lengthSquared
                 (Babylon.Vector3.subtract position aPos)
             in
             let bDist =
               Babylon.Vector3.lengthSquared
                 (Babylon.Vector3.subtract position bPos)
             in
             aDist -. bDist |> int_of_float)
    in
    List.nth_opt entitiesByDistance 0 |> Option.map (fun entInfo -> fst entInfo)

  let getPosition entityId world =
    let maybeInfo =
      EntityManager.ReadOnlyWorld.read world ~entityId component
    in
    maybeInfo |> Option.map (fun { position; _ } -> position)
end
