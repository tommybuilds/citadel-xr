open TestFramework
open EntityManager

let simpleEntity = (Entity.define () : (unit, unit) Entity.definition)

let systemThatDeletesEverything =
  (let tick ~deltaTime:_ ~world context =
     let entities = World.entities world in
     let world' =
       entities
       |> List.fold_left (fun acc curr -> World.destroy ~entity:curr acc) world
     in
     (context, world')
   in
   System.define ~tick ()
    : unit System.definition)

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

    let incrementWithDispatch =
      System.Effect.sideEffectWithDispatch
        (fun ~dispatch () _ ->
          incr counter;
          !counter |> dispatch)
        system
  end

  module Entity = struct
    let effectOnTick =
      (Entity.define ()
       |> Entity.withTick (fun ~deltaTime:_ state ->
              (state, Effects.increment ()))
        : (unit, unit) Entity.definition)

    type msg = CounterValue of int

    let effectWithDispatchOnTick =
      (let open Entity in
       define 0
       |> withTick (fun ~deltaTime:_ state ->
              ( state,
                Effects.incrementWithDispatch ()
                |> Effect.map (fun v -> CounterValue v) ))
       |> withUpdate (fun msg state ->
              match msg with CounterValue i -> (i, Effect.none))
        : (msg, int) Entity.definition)
  end
end
;;

describe "System" (fun { describe; _ } ->
    describe "systemThatDeletesEverything" (fun { test; _ } ->
        test "deletes on tick" (fun { expect; _ } ->
            let entityManager =
              EntityManager.initial
              |> EntityManager.register systemThatDeletesEverything
              |> EntityManager.instantiate ~entity:simpleEntity
            in
            let count = entityManager |> EntityManager.count in
            (expect.int count).toBe 1;
            let entityManager', _effects =
              EntityManager.tick ~deltaTime:0.1 entityManager
            in
            let count' = entityManager' |> EntityManager.count in
            (expect.int count').toBe 0));
    describe "effects" (fun { test; _ } ->
        test "effect w/o dispatch runs on tick" (fun { expect; _ } ->
            SystemWithEffect.reset ();
            let entityManager =
              EntityManager.initial
              |> EntityManager.register SystemWithEffect.system
              |> EntityManager.instantiate
                   ~entity:SystemWithEffect.Entity.effectOnTick
            in
            let entityManager', effects =
              EntityManager.tick ~deltaTime:0.1 entityManager
            in
            (expect.int (SystemWithEffect.get ())).toBe 0;
            EntityManager.SideEffects.runSideEffects (fun _ -> ()) effects;
            (expect.int (SystemWithEffect.get ())).toBe 1;
            let entityManager'', effects =
              EntityManager.tick ~deltaTime:0.1 entityManager
            in
            (expect.int (SystemWithEffect.get ())).toBe 1;
            EntityManager.SideEffects.runSideEffects (fun _ -> ()) effects;
            (expect.int (SystemWithEffect.get ())).toBe 2);
        test
          ("effect w/ dispatch runs on tick and produces msg"
          [@reason.raw_literal
            "effect w/ dispatch runs on tick and produces msg"])
          (fun { expect; _ } ->
            SystemWithEffect.reset ();
            let entityManager =
              EntityManager.initial
              |> EntityManager.register SystemWithEffect.system
              |> EntityManager.instantiate
                   ~entity:SystemWithEffect.Entity.effectWithDispatchOnTick
            in
            let entityManager', effects =
              EntityManager.tick ~deltaTime:0.1 entityManager
            in
            let queuedMessages = ref [] in
            let dispatch msg = queuedMessages := msg :: !queuedMessages in
            (expect.int (SystemWithEffect.get ())).toBe 0;
            EntityManager.SideEffects.runSideEffects dispatch effects;
            (expect.int (SystemWithEffect.get ())).toBe 1;
            (expect.int (List.length !queuedMessages)).toBe 1)))
