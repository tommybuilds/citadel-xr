type t = { entities : EntityInstance.instance list }

let initial = { entities = [] }

let instantiatei ~entity world =
  let instance = EntityInstance.instantiate entity in
  let id = EntityInstance.uniqueId instance in
  (id, { entities = world.entities @ [ instance ] })

let instantiate ~entity world =
  let _id, world = instantiatei ~entity world in
  world

let destroy ~entity world =
  let entities' =
    world.entities
    |> List.filter (fun ent -> EntityInstance.uniqueId ent != entity)
  in
  { entities = entities' }

let count { entities; _ } = List.length entities
let entities { entities; _ } = entities |> List.map EntityInstance.uniqueId
let map f { entities; _ } = List.map f entities
let filter_map f { entities; _ } = List.filter_map f entities

let set =
  (fun ~entities _world -> { entities }
    : entities:EntityInstance.instance list -> t -> t)

let exists ~entity { entities; _ } =
  entities |> List.exists (fun ent -> EntityInstance.uniqueId ent = entity)

let values component { entities; _ } =
  entities |> List.filter_map (EntityInstance.readComponent component)

let valuesi component { entities; _ } =
  entities
  |> List.filter_map (fun ent ->
         ent
         |> EntityInstance.readComponent component
         |> Option.map (fun c -> (EntityInstance.uniqueId ent, c)))

let read ~entity component { entities; _ } =
  ( entities |> List.filter (fun ent -> EntityInstance.uniqueId ent = entity)
  |> fun l -> List.nth_opt l 0 )
  |> fun maybeEnt ->
  Option.bind maybeEnt (EntityInstance.readComponent component)

let has ~entityId component world =
  read ~entity:entityId component world |> Option.is_some

let write ~entity ~value component { entities } =
  let entities' =
    entities
    |> List.map (fun ent ->
           if EntityInstance.uniqueId ent = entity then
             EntityInstance.writeComponent value component ent
           else ent)
  in
  { entities = entities' }

let map_componentsi ~f component { entities } =
  let entities' =
    entities
    |> List.map (fun ent ->
           ent
           |> EntityInstance.readComponent component
           |> Option.map (fun v ->
                  EntityInstance.writeComponent
                    (f (EntityInstance.uniqueId ent) v)
                    component ent)
           |> Option.value ~default:ent)
  in
  { entities = entities' }

let map_components innerF component world =
  map_componentsi ~f:(fun _id v -> innerF v) component world

let map_entity ~f:innerF ~entityId component world =
  map_componentsi
    ~f:(fun id v -> if id = entityId then innerF v else v)
    component world

let fold ~f ~initial component { entities } =
  entities
  |> List.fold_left
       (fun acc curr ->
         curr
         |> EntityInstance.readComponent component
         |> Option.map (fun v ->
                let entityId = EntityInstance.uniqueId curr in
                f acc entityId v)
         |> Option.value ~default:acc)
       initial

let to_readonly world =
  let worldRead ~entityId component = read ~entity:entityId component world in
  let worldValuesI component = valuesi component world in
  let open ReadOnlyWorld in
  { read = worldRead; valuesi = worldValuesI }
