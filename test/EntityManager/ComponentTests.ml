open TestFramework
open Babylon
open EntityManager

let intComponent =
  (Component.readonly ~name:"Test.Int" ()
    : (Component.readonly, int) Component.t)

let baseEntity = (Entity.define () : (unit, unit) Entity.definition)
let entityWithoutPosition = baseEntity

let entityWithPosition =
  baseEntity |> Entity.withReadonlyComponent intComponent (fun _ -> 42)
;;

describe "Component" (fun { test; _ } ->
    test "component can be read" (fun { expect; _ } ->
        let entityManager =
          EntityManager.initial
          |> EntityManager.instantiate ~entity:entityWithoutPosition
          |> EntityManager.instantiate ~entity:entityWithPosition
        in
        let count = entityManager |> EntityManager.count in
        (expect.int count).toBe 2;
        let vals = EntityManager.values intComponent entityManager in
        (expect.int (List.length vals)).toBe 1;
        (expect.int (List.hd vals)).toBe 42))
