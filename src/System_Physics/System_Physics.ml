module State = State
module Component = Component
module Shape = Shape
module System = System

module RayCastResult = struct
  type t =
    | Hit of {
        position : Babylon.Vector3.t;
        normal : Babylon.Vector3.t;
        entityId : EntityManager.EntityId.t;
      }
    | Miss
end

module Effects = struct
  module Vector3 = Babylon.Vector3

  let applyToAll f (rigidBodyTable : (int, Ammo.RigidBody.t) Hashtbl.t) =
    rigidBodyTable |> Hashtbl.to_seq_values |> Seq.iter f

  let attract ~position ~force ~entityId definition =
    EntityManager.System.Effect.sideEffect
      (fun args (context : System.context) ->
        match !(context.physicsWorld) with
        | None -> ()
        | Some world ->
            let position, force = args in
            let () =
              Hashtbl.find_opt context.entityToRigidBody entityId
              |> Option.iter
                   (applyToAll (fun body ->
                        let bodyPosition = Ammo.RigidBody.position body in
                        let direction =
                          Vector3.subtract position bodyPosition
                          |> Vector3.normalize |> Vector3.scale force
                        in
                        let () =
                          Ammo.RigidBody.applyImpulse ~impulse:direction
                            ~position:bodyPosition world body
                        in
                        ()))
            in
            ())
      definition (position, force)

  let applyImpulse ?position ~impulse ~entityId definition =
    EntityManager.System.Effect.sideEffect
      (fun args (context : System.context) ->
        match !(context.physicsWorld) with
        | None -> ()
        | Some world ->
            let position, impulse = args in
            let () =
              Hashtbl.find_opt context.entityToRigidBody entityId
              |> Option.iter
                   (applyToAll (fun body ->
                        let positionToUse =
                          match position with
                          | None -> Ammo.RigidBody.position body
                          | Some v -> v
                        in
                        let () =
                          Ammo.RigidBody.applyImpulse ~impulse
                            ~position:positionToUse world body
                        in
                        ()))
            in
            ())
      definition (position, impulse)

  let applyForce ?position ~force ~entityId definition =
    EntityManager.System.Effect.sideEffect
      (fun args (context : System.context) ->
        match !(context.physicsWorld) with
        | None -> ()
        | Some world ->
            let position, force = args in
            let () =
              Hashtbl.find_opt context.entityToRigidBody entityId
              |> Option.iter
                   (applyToAll (fun body ->
                        let positionToUse =
                          match position with
                          | None -> Ammo.RigidBody.position body
                          | Some v -> v
                        in
                        let () =
                          Ammo.RigidBody.applyForce ~force
                            ~position:positionToUse world body
                        in
                        ()))
            in
            ())
      definition (position, force)

  let rayCast ?collisionMask ~position ~direction definition =
    EntityManager.System.Effect.sideEffectWithDispatch
      (fun ~dispatch args (context : System.context) ->
        let p, d = args in
        match !(context.physicsWorld) with
        | None -> dispatch RayCastResult.Miss
        | Some world -> (
            let raycastResult =
              Ammo.rayCast ?collisionMask ~start:p
                ~stop:(Babylon.Vector3.add p d) world
            in
            match raycastResult with
            | None -> dispatch RayCastResult.Miss
            | Some r ->
                let position = r |> Ammo.RayCastResult.position in
                let normal = r |> Ammo.RayCastResult.normal in
                let entityId =
                  r |> Ammo.RayCastResult.bodyId
                  |> EntityManager.EntityId.unsafeFromInt
                in
                dispatch (RayCastResult.Hit { position; normal; entityId })))
      definition (position, direction)

  let setLinearVelocity ~velocity ~entityId definition =
    EntityManager.System.Effect.sideEffect
      (fun args (context : System.context) ->
        match !(context.physicsWorld) with
        | None -> ()
        | Some world ->
            let velocity = args in
            let () =
              Hashtbl.find_opt context.entityToRigidBody entityId
              |> Option.iter
                   (applyToAll (fun body ->
                        let () =
                          Ammo.RigidBody.setLinearVelocity ~velocity world body
                        in
                        ()))
            in
            ())
      definition velocity
end

module Entity = struct
  let dynamic ~read ~write entity =
    let adjustedRead state = read state |> Option.to_list in
    let adjustedWrite state model = write (List.nth_opt state 0) model in
    entity
    |> EntityManager.Entity.withReadWriteComponent ~read:adjustedRead
         ~write:adjustedWrite Component.dynamic

  let dynamic ~read ~write entity =
    let adjustedRead state = read state |> Option.to_list in
    let adjustedWrite state model = write (List.nth_opt state 0) model in
    entity
    |> EntityManager.Entity.withReadWriteComponent ~read:adjustedRead
         ~write:adjustedWrite Component.dynamic

  let multiple ~read ~write entity =
    entity
    |> EntityManager.Entity.withReadWriteComponent ~read ~write
         Component.dynamic
end
