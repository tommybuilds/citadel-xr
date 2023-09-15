open Util

type instance =
  | Instance : {
      uniqueId : int;
      currentState : 'state;
      definition :
        ('msg, 'state, 'msg Effect.t) EntityDefinition.entityDefinition;
    }
      -> instance

let nextUniqueId = ref 0

let instantiate definition =
  match definition with
  | EntityDefinition.Definition definition ->
      let instance =
        Instance
          {
            uniqueId = !nextUniqueId;
            currentState = definition.initialState;
            definition;
          }
      in
      incr nextUniqueId;
      instance

let uniqueId = function Instance { uniqueId; _ } -> uniqueId

let readComponent component entityInstance =
  match entityInstance with
  | Instance { definition; currentState; _ } -> (
      let open Component in
      let maybeComponent =
        IntMap.find_opt component.uniqueId definition.components
      in
      match maybeComponent with
      | Some (Component { reader; pipe }) ->
          let v = reader currentState in
          Pipe.send pipe component.pipe v
      | _ -> None)

let writeComponent =
  (fun v component entityInstance ->
     match entityInstance with
     | Instance ({ definition; currentState; _ } as instance) -> (
         let open Component in
         let maybeComponent =
           IntMap.find_opt component.uniqueId definition.components
         in
         match maybeComponent with
         | Some (Component { writer; pipe }) ->
             let pipedValue = Pipe.send component.pipe pipe v |> Option.get in
             let newState = writer pipedValue currentState in
             Instance { instance with currentState = newState }
         | _ -> entityInstance)
    : 'a -> (Component.readwrite, 'a) Component.t -> instance -> instance)
