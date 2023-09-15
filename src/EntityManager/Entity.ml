open Util

type ('msg, 'state) entityDefinition =
  ('msg, 'state, 'msg Effect.t) EntityDefinition.entityDefinition

type ('msg, 'state) definition =
  ('msg, 'state, 'msg Effect.t) EntityDefinition.definition

type 'state component = 'state EntityDefinition.component

let withReadonlyComponent component context entity =
  match entity with
  | EntityDefinition.Definition entity ->
      let open Component in
      let eComponent =
        EntityDefinition.Component
          {
            reader = context;
            writer = (fun _ _ -> failwith "readonly");
            pipe = component.pipe;
          }
      in
      let components' =
        entity.components |> IntMap.add component.uniqueId eComponent
      in
      EntityDefinition.Definition { entity with components = components' }

let withReadWriteComponent ~read ~write component entity =
  match entity with
  | EntityDefinition.Definition entity ->
      let open Component in
      let eComponent =
        EntityDefinition.Component
          { reader = read; writer = write; pipe = component.pipe }
      in
      let components' =
        entity.components |> IntMap.add component.uniqueId eComponent
      in
      EntityDefinition.Definition { entity with components = components' }

let withHandler (msg : 'payload Msg.t) (mapper : 'payload -> 'msg) definition =
  match definition with
  | EntityDefinition.Definition entity ->
      let handlers' =
        entity.handlers
        |> IntMap.add msg.typeId
             (EntityDefinition.Handler { mapper; pipe = msg.pipe })
      in
      EntityDefinition.Definition { entity with handlers = handlers' }

let defaultTick ~deltaTime:_ _world model = (model, Effect.NoEffect)
let defaultSub _model = None
let defaultUpdate (_ : ReadOnlyWorld.t) _ model = (model, Effect.NoEffect)

let define initialState =
  EntityDefinition.Definition
    {
      initialState;
      msgPipe = Pipe.create ();
      tick = defaultTick;
      update = defaultUpdate;
      sub = defaultSub;
      components = IntMap.empty;
      handlers = IntMap.empty;
    }

let withUpdateW update = function
  | EntityDefinition.Definition definition ->
      EntityDefinition.Definition { definition with update }

let withUpdate update def =
  let wrappedUpdate _ msg model = update msg model in
  withUpdateW wrappedUpdate def

let withThinkEx tick = function
  | EntityDefinition.Definition definition ->
      EntityDefinition.Definition { definition with tick }

let withThinkW tick def =
  let wrappedTick ~deltaTime (context : EntityContext.t) model =
    tick ~deltaTime context.world model
  in
  withThinkEx wrappedTick def

let withThink tick def =
  let wrappedTick ~deltaTime _world model = tick ~deltaTime model in
  withThinkEx wrappedTick def

let withTick = withThink

let withSub sub definition =
  let wrappedSub model = Some (sub model) in
  match definition with
  | EntityDefinition.Definition definition ->
      EntityDefinition.Definition { definition with sub = wrappedSub }

open EntityInstance

type msg = Msg.instance

let tick ~deltaTime context instance =
  match instance with
  | Instance ({ uniqueId; currentState; definition; _ } as entity) ->
      let state', effect = definition.tick ~deltaTime context currentState in
      let effect' =
        effect
        |> Effect.map (fun msg ->
               Msg.Msg { uniqueId; msgPipe = definition.msgPipe; payload = msg })
      in
      (Instance { entity with currentState = state' }, effect')

let update (readOnlyWorld : ReadOnlyWorld.t) (msg : msg) instance =
  let id = uniqueId in
  match instance with
  | Instance ({ currentState; definition; _ } as entity) -> (
      match msg with
      | Msg { uniqueId; msgPipe; payload } -> (
          let maybeMsg = Pipe.send msgPipe definition.msgPipe payload in
          match maybeMsg with
          | Some msg when uniqueId == id instance ->
              let state', effect =
                definition.update readOnlyWorld msg currentState
              in
              let effect' =
                effect
                |> Effect.map (fun msg ->
                       Msg.Msg
                         {
                           uniqueId;
                           msgPipe = definition.msgPipe;
                           payload = msg;
                         })
              in
              (Instance { entity with currentState = state' }, effect')
          | _ -> (instance, Effect.NoEffect))
      | Custom { msgType; pipe; payload; uniqueId } ->
          definition.handlers |> IntMap.find_opt msgType
          |> Option.map (function EntityDefinition.Handler handler ->
                 (match Pipe.send pipe handler.pipe payload with
                 | Some msg when id instance == uniqueId ->
                     let state', effect =
                       definition.update readOnlyWorld (handler.mapper msg)
                         currentState
                     in
                     let effect' =
                       effect
                       |> Effect.map (fun msg ->
                              Msg.Msg
                                {
                                  uniqueId;
                                  msgPipe = definition.msgPipe;
                                  payload = msg;
                                })
                     in
                     (Instance { entity with currentState = state' }, effect')
                 | _ -> (instance, Effect.NoEffect)))
          |> Option.value ~default:(instance, Effect.NoEffect))

let sub = function
  | Instance { currentState; definition; uniqueId; _ } -> (
      match definition.sub currentState with
      | None -> None
      | Some sub ->
          Some
            (sub
            |> Isolinear.Sub.map (fun msg ->
                   Msg.Msg
                     { uniqueId; msgPipe = definition.msgPipe; payload = msg })
            ))

let uniqueId = EntityInstance.uniqueId