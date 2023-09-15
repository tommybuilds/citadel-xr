type t = unit
module Shape = Shape
module Grabbable = Grabbable
module GrabState = GrabState
module Holster = Holster
module HolsterState = HolsterState
module Payload = Payload
module System = System
module Effects = Effects
module Entity =
  struct
    let grabbable ?(payloads= [])  ~readGrabState  ~writeGrabState 
      ~grabHandles  definition =
      let definition' =
        (definition |>
           (EntityManager.Entity.withReadWriteComponent GrabState.component
              ~read:readGrabState ~write:writeGrabState))
          |>
          (EntityManager.Entity.withReadonlyComponent Grabbable.component
             grabHandles) in
      payloads |>
        (List.fold_left
           (fun entity ->
              fun curr ->
                let open Payload in
                  match curr with
                  | Handler { payload; mapper } ->
                      EntityManager.Entity.withHandler payload.msg mapper
                        entity) definition')
    let holster ~readHolsterState  ~writeHolsterState  ~holsters  definition
      =
      (definition |>
         (EntityManager.Entity.withReadWriteComponent HolsterState.component
            ~read:readHolsterState ~write:writeHolsterState))
        |>
        (EntityManager.Entity.withReadonlyComponent Holster.component
           holsters)
    let suppliesPayload payload mapper definition =
      definition |>
        (EntityManager.Entity.withReadonlyComponent Payload.component
           (fun state ->
              [(payload |> (Payload.withValue (mapper state))) |>
                 Payload.Abstract.make]))
  end
module EntityFactory =
  struct
    module Hand =
      struct type model = PullEntity.model
             type msg = PullEntity.msg end
    let hand = PullEntity.entity
  end