type 'msg sideEffect =
  | Function of (unit -> unit)
  | FunctionWithDispatch of (('msg -> unit) -> unit)

let runSideEffect dispatch = function
  | Function f -> f ()
  | FunctionWithDispatch f -> f dispatch

type 'msg t =
  | NoEffect
  | Batch : 'msg t list -> 'msg t
  | CreateEntity : {
      idToEffect : (EntityId.t -> 'a) option;
      entity : ('msg, 'state, 'msg t) EntityDefinition.definition;
    }
      -> 'a t
  | DestroyEntity of EntityId.t
  | Send : {
      entityId : EntityId.t;
      msg : 'payload Msg.t;
      args : 'payload;
    }
      -> _ t
  | DestroySelf
  | SideEffect : 'msg sideEffect -> 'msg t
  | Custom : 'custom -> 'custom t

let none = NoEffect
let destroyEntity entity = DestroyEntity entity
let destroySelf = DestroySelf

let createEntity entityDefinition =
  CreateEntity { entity = entityDefinition; idToEffect = None }

let createEntityI f entityDefinition =
  CreateEntity { entity = entityDefinition; idToEffect = Some f }

let batch eff = Batch eff
let sideEffect fn = SideEffect (Function fn)
let send msg entityId args = Send { msg; entityId; args }
let sideEffectWithDispatch fn = SideEffect (FunctionWithDispatch fn)

let rec map =
  (fun mapf item ->
     match item with
     | Batch effects ->
         let effects' = effects |> List.map (map mapf) in
         Batch effects'
     | NoEffect -> NoEffect
     | DestroyEntity id -> DestroyEntity id
     | DestroySelf -> DestroySelf
     | CreateEntity ent ->
         CreateEntity
           {
             entity = ent.entity;
             idToEffect =
               Option.map (fun oldF id -> mapf (oldF id)) ent.idToEffect;
           }
     | Send msg -> Send msg
     | SideEffect (Function f) -> SideEffect (Function f)
     | SideEffect (FunctionWithDispatch f) ->
         SideEffect
           (FunctionWithDispatch
              (fun dispatch ->
                let dispatch' a =
                  let b = mapf a in
                  dispatch b
                in
                f dispatch'))
     | Custom v -> Custom (mapf v)
    : ('a -> 'b) -> 'a t -> 'b t)
