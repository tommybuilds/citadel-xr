open TestFramework
open EntityManager

let simpleMsg = (Msg.define "test.int" : int Msg.t)

let entityThatDispatchesEvent entityId =
  Entity.define entityId
  |> Entity.withTick (fun ~deltaTime:_ entityId ->
         (entityId, Effect.send simpleMsg entityId 42))

type msg = TestIntMsg of int

let intComponent =
  (Component.readonly ~name:"component.int" ()
    : (Component.readonly, int) Component.t)

let entityThatHandlesEvent =
  Entity.define 50
  |> Entity.withUpdate (fun msg model ->
         match msg with TestIntMsg v -> (v, Effect.none))
  |> Entity.withReadonlyComponent intComponent (fun v -> v)
  |> Entity.withHandler simpleMsg (fun v -> TestIntMsg v)
;;

describe "Msg" (fun { test; _ } ->
    test "can be dispatched and received by entity" (fun { expect; _ } ->
        let entityManager =
          EntityManager.initial
          |> EntityManager.instantiate ~entity:entityThatHandlesEvent
        in
        let entityId = entityManager |> EntityManager.entities |> List.hd in
        let secondEntity = entityThatDispatchesEvent entityId in
        let entityManager =
          entityManager |> EntityManager.instantiate ~entity:secondEntity
        in
        let entityManager', effects =
          EntityManager.tick ~deltaTime:0.1 entityManager
        in
        let () =
          EntityManager.SideEffects.runSideEffects
            (fun msg ->
              let entityManager, _effects =
                EntityManager.update msg entityManager'
              in
              let valueAfterMsg =
                entityManager |> EntityManager.values intComponent |> List.hd
              in
              (expect.int valueAfterMsg).toBe 42)
            effects
        in
        ()))
