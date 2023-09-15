module Sub = Isolinear.Sub
module EntityDefinition = EntityDefinition
module Effect = Effect
module StringMap = Map.Make (String)
module EntityContext = EntityContext
module EntityId = EntityId
module Component = Component
module Msg = Msg
module ReadOnlyWorld = ReadOnlyWorld
module World = World
module System = System
module Entity = Entity

type 'msg effect = 'msg Effect.t
type t = { world : World.t; systems : System.Instance.t list }

let world { world; _ } = world
let initial = { world = World.initial; systems = [] }

let instantiate ~entity entityManager =
  { entityManager with world = World.instantiate ~entity entityManager.world }

let instantiatei ~entity entityManager =
  let id, world = World.instantiatei ~entity entityManager.world in
  let entManager' = { entityManager with world } in
  (id, entManager')

let destroy ~entityId entityManager =
  {
    entityManager with
    world = World.destroy ~entity:entityId entityManager.world;
  }

let count { world; _ } = World.count world

let register systemDefinition ({ systems; _ } as entityManager) =
  let system = System.instantiate systemDefinition in
  { entityManager with systems = system :: systems }

let entities { world; _ } = world |> World.entities

type msg = Entity of Entity.msg

let rec processEffect entityId effect entityManager
    (outEffects : msg Effect.sideEffect list) =
  let open Effect in
  match effect with
  | Batch effects ->
      effects
      |> List.fold_left
           (fun acc cur ->
             let prevEntMgr, prevEffects = acc in
             processEffect entityId cur prevEntMgr prevEffects)
           (entityManager, outEffects)
  | NoEffect -> (entityManager, outEffects)
  | CreateEntity { entity; idToEffect } ->
      let id, entityManager' = entityManager |> instantiatei ~entity in
      let effs =
        match idToEffect with
        | None -> outEffects
        | Some f ->
            let msg = f id in
            let eff = FunctionWithDispatch (fun dispatch -> dispatch msg) in
            eff :: outEffects
      in
      (entityManager', effs)
  | DestroyEntity entityToDestroy ->
      let entityManager' = entityManager |> destroy ~entityId:entityToDestroy in
      (entityManager', outEffects)
  | DestroySelf ->
      let entityManager' = entityManager |> destroy ~entityId in
      (entityManager', outEffects)
  | Send { entityId; msg; args } ->
      let eff =
        FunctionWithDispatch
          (fun dispatch ->
            dispatch
              (Entity
                 (Msg.Custom
                    {
                      uniqueId = entityId;
                      pipe = msg.pipe;
                      payload = args;
                      msgType = msg.typeId;
                    })))
      in
      (entityManager, eff :: outEffects)
  | Custom _ -> (entityManager, outEffects)
  | SideEffect eff -> (entityManager, eff :: outEffects)

module SideEffects = struct
  type t = msg Effect.sideEffect list

  let runSideEffects dispatch pendingEffects =
    let rec loop = function
      | [] -> ()
      | hd :: tail ->
          hd |> Effect.runSideEffect dispatch;
          loop tail
    in
    pendingEffects |> List.rev |> loop
end

let update =
  (fun msg ({ world; _ } as entityManager) ->
     let readOnlyWorld = world |> World.to_readonly in
     match msg with
     | Entity entityMsg ->
         let entitiesAndEffects =
           world
           |> World.map (fun ent -> Entity.update readOnlyWorld entityMsg ent)
         in
         let world' =
           World.set ~entities:(entitiesAndEffects |> List.map fst) world
         in
         let entityManager' = { entityManager with world = world' } in
         let entityManager'', outEffects =
           entitiesAndEffects
           |> List.fold_left
                (fun acc curr ->
                  let entityManager, effects = acc in
                  let entity, eff = curr in
                  let eff' = eff |> Effect.map (fun msg -> Entity msg) in
                  let entityId = Entity.uniqueId entity in
                  processEffect entityId eff' entityManager effects)
                (entityManager', [])
         in
         (entityManager'', outEffects)
    : msg -> t -> t * SideEffects.t)

let tick ~(deltaTime : float) ({ world; systems; _ } as entityManager) =
  let roWorld = world |> World.to_readonly in
  let entitiesAndEffects =
    world
    |> World.map (fun ent ->
           Entity.tick ~deltaTime
             { world = roWorld; entityId = Entity.uniqueId ent }
             ent)
  in
  let entities' = entitiesAndEffects |> List.map fst in
  let world' = World.set ~entities:entities' world in
  let entityManager' = { entityManager with world = world' } in
  let entityManager'', outEffects =
    entitiesAndEffects
    |> List.fold_left
         (fun acc curr ->
           let entityManager, effects = acc in
           let entity, eff = curr in
           let eff' = eff |> Effect.map (fun msg -> Entity msg) in
           let entityId = Entity.uniqueId entity in
           processEffect entityId eff' entityManager effects)
         (entityManager', [])
  in
  let world = entityManager''.world in
  let revSystems', world' =
    systems
    |> List.fold_left
         (fun acc system ->
           let prevContext, prevWorld = acc in
           let context, world' =
             System.Instance.tick ~deltaTime ~world:prevWorld system
           in
           (context :: prevContext, world'))
         ([], world)
  in
  let systems' = revSystems' |> List.rev in
  let entityManager''' = { systems = systems'; world = world' } in
  (entityManager''', outEffects)

let addStaticGeometry ~mesh { systems; _ } =
  systems
  |> List.iter (fun system -> System.Instance.addStaticGeometry ~mesh system)

let sub =
  (fun { world; _ } ->
     world
     |> World.filter_map (fun ent ->
            Entity.sub ent
            |> Option.map (Isolinear.Sub.map (fun msg -> Entity msg)))
     |> Isolinear.Sub.batch
    : t -> msg Sub.t)

let exists ~entity { world; _ } = World.exists ~entity world
let values component { world; _ } = World.values component world
let valuesi component { world; _ } = World.valuesi component world
let read ~entity component { world; _ } = World.read ~entity component world

let write ~entity ~value component ({ world; _ } as entityManager) =
  let world' = World.write ~entity ~value component world in
  { entityManager with world = world' }

let context system { systems; _ } =
  systems
  |> List.fold_left
       (fun acc curr ->
         match acc with
         | None -> System.Instance.context system curr
         | Some _ as s -> s)
       None
