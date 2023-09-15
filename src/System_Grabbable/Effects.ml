let holster ~entityToHolster  ~holster  system =
  EntityManager.System.Effect.sideEffect
    (fun (entityId, holsterId) ->
       fun (context : System.context) ->
         context.pendingEffects := ((Holster { entityId; holsterId }) ::
           (!(context.pendingEffects)));
         ()) system (entityToHolster, holster)
let dropOnto ~droppingEntity  ~targetEntity 
  ~payload:(payload : Payload.Abstract.t)  system =
  let open Payload in
    match payload with
    | Abstract { msg; defaultValue } ->
        EntityManager.Effect.batch
          [EntityManager.Effect.send msg targetEntity defaultValue;
          EntityManager.Effect.destroyEntity droppingEntity]