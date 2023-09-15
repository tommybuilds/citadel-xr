open TestFramework
open EntityManager

let simpleEntity = (Entity.define () : (unit, unit) Entity.definition)

let entityThatDestroysOnUpdate =
  (Entity.define ()
   |> Entity.withUpdate (fun () model ->
          (model, EntityManager.Effect.destroySelf))
    : (unit, unit) Entity.definition)

let entityThatDestroysOnTick =
  (Entity.define ()
   |> Entity.withThink (fun ~deltaTime model ->
          (model, EntityManager.Effect.destroySelf))
    : (unit, unit) Entity.definition)

let entityThatDestroysAnotherEntityOnTick id =
  Entity.define ()
  |> Entity.withTick (fun ~deltaTime model ->
         (model, EntityManager.Effect.destroyEntity id))

module SystemWithEffect = struct
  let system =
    (let tick ~deltaTime:_ ~world _ = ((), world) in
     System.define ~tick ()
      : unit System.definition)

  let counter = ref 0
  let reset () = counter := 0
  let get () = !counter

  module Effects = struct
    let increment = System.Effect.sideEffect (fun _ _ -> incr counter) system
  end
end
;;

describe "Effects" (fun { describe; test; _ } ->
    test "entityThatDestroysOnTick should be removed" (fun { expect; _ } ->
        let entityManager =
          EntityManager.initial
          |> EntityManager.instantiate ~entity:entityThatDestroysOnTick
        in
        let entityManager', _effects =
          EntityManager.tick ~deltaTime:0.1 entityManager
        in
        let count = entityManager' |> EntityManager.count in
        let entities = entityManager' |> EntityManager.entities in
        (expect.int count).toBe 0;
        (expect.int (List.length entities)).toBe 0);
    test
      ("entityThatDestroysAnotherEntityOnTick should destroy other entity"
      [@reason.raw_literal
        "entityThatDestroysAnotherEntityOnTick should destroy other entity"])
      (fun { expect; _ } ->
        let targetEntityId, entityManager' =
          EntityManager.initial
          |> EntityManager.instantiatei ~entity:simpleEntity
        in
        let entityId, entityManager'' =
          entityManager'
          |> EntityManager.instantiatei
               ~entity:(entityThatDestroysAnotherEntityOnTick targetEntityId)
        in
        let count = entityManager'' |> EntityManager.count in
        (expect.int count).toBe 2;
        let entityManager''', _effects =
          EntityManager.tick ~deltaTime:0.1 entityManager''
        in
        let count = entityManager''' |> EntityManager.count in
        let entities = entityManager''' |> EntityManager.entities in
        let remainingEntityId = entities |> List.hd |> EntityId.toInt in
        let expectedEntityId = entityId |> EntityId.toInt in
        (expect.int count).toBe 1;
        (expect.int remainingEntityId).toBe expectedEntityId);
    describe "batching" (fun { test; _ } ->
        test "entity that creates multiple effects" (fun { expect; _ } ->
            let entityThatDispatchesMultipleEffects =
              (Entity.define ()
               |> Entity.withTick (fun ~deltaTime model ->
                      let createEffect = Effect.createEntity simpleEntity in
                      let incrementOnceEffect =
                        SystemWithEffect.Effects.increment ()
                      in
                      let incrementAgainEffect =
                        SystemWithEffect.Effects.increment ()
                      in
                      let effects =
                        Effect.batch
                          [
                            incrementOnceEffect;
                            createEffect;
                            incrementAgainEffect;
                          ]
                      in
                      (model, effects))
                : (unit, unit) Entity.definition)
            in
            let entityManager =
              EntityManager.initial
              |> EntityManager.register SystemWithEffect.system
              |> EntityManager.instantiate
                   ~entity:entityThatDispatchesMultipleEffects
            in
            SystemWithEffect.reset ();
            let entityManager', effects =
              EntityManager.tick ~deltaTime:0.1 entityManager
            in
            let queuedMessages = ref [] in
            let dispatch msg = queuedMessages := msg :: !queuedMessages in
            (expect.int (SystemWithEffect.get ())).toBe 0;
            EntityManager.SideEffects.runSideEffects dispatch effects;
            (expect.int (SystemWithEffect.get ())).toBe 2;
            (expect.int
               (entityManager' |> EntityManager.entities |> List.length))
              .toBe 2)))
