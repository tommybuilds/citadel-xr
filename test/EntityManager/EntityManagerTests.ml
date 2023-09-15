open TestFramework [@@ocaml.doc " Simple test cases "]

open EntityManager

let simpleEntity = (Entity.define () : (unit, unit) Entity.definition)

let entityThatDestroysOnUpdate =
  (Entity.define ()
   |> Entity.withUpdate (fun _ model ->
          (model, EntityManager.Effect.destroySelf))
    : (unit, unit) Entity.definition)

let entityThatDestroysOnTick =
  (Entity.define ()
   |> Entity.withThink (fun ~deltaTime model ->
          (model, EntityManager.Effect.destroySelf))
    : (unit, unit) Entity.definition)
;;

describe "EntityManager" (fun { describe; _ } ->
    describe "count" (fun { test; _ } ->
        test "initial count is 0" (fun { expect; _ } ->
            let entityManager = EntityManager.initial in
            let count = EntityManager.count entityManager in
            (expect.int count).toBe 0);
        test "count is incremented when adding entities" (fun { expect; _ } ->
            let entityManager =
              EntityManager.initial
              |> EntityManager.instantiate ~entity:simpleEntity
            in
            let count = entityManager |> EntityManager.count in
            let entities = entityManager |> EntityManager.entities in
            (expect.int count).toBe 1;
            (expect.int (List.length entities)).toBe 1);
        test "count is decremented when destroying entities"
          (fun { expect; _ } ->
            let entityManager =
              EntityManager.initial
              |> EntityManager.instantiate ~entity:simpleEntity
            in
            let entities = entityManager |> EntityManager.entities in
            (expect.int (List.length entities)).toBe 1;
            let entityId = List.hd entities in
            let entityManager' =
              entityManager |> EntityManager.destroy ~entityId
            in
            let count' = entityManager' |> EntityManager.count in
            let entities' = entityManager' |> EntityManager.entities in
            (expect.int count').toBe 0;
            (expect.int (List.length entities')).toBe 0)))
