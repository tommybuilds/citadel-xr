open Babylon
open EntityManager

type 'a tickFunction = deltaTime:float -> 'a -> 'a
type tick = Tick : { tick : 'a tickFunction } -> tick

module TargetSpawner = struct
  type context = { nextSpawnTime : float }

  let tick ~(deltaTime : float) ~world { nextSpawnTime } =
    let nextSpawnTime' = nextSpawnTime -. deltaTime in
    let world, nextSpawnTime'' =
      if nextSpawnTime <= 0.0 then
        let targetCount =
          world |> World.values Components.target |> List.length
        in
        if targetCount < 3 then
          let rand = Random.State.make_self_init () in
          let x = Random.State.float rand 10. -. 5.0 in
          let target = Target.entity 1.0 (Vector3.create ~x ~y:0.9 ~z:5.0) in
          let world' = world |> World.instantiate ~entity:target in
          (world', 1.0)
        else (world, nextSpawnTime)
      else (world, nextSpawnTime')
    in
    ({ nextSpawnTime = nextSpawnTime'' }, world)
end

let targetSpawner =
  (System.define ~tick:TargetSpawner.tick
     (let open TargetSpawner in
     { nextSpawnTime = 1.0 })
    : TargetSpawner.context System.definition)

let damage = Damage.system
let physics = System_Physics.System.create ()
let audio = System_Audio.system
let grabbable = System_Grabbable.System.system

let leftHand =
  System_Grabbable.EntityFactory.hand
    (fun () ->
      let input = (Ambient.current ()).input in
      input |> Input.State.leftHand)
    physics grabbable

let rightHand =
  System_Grabbable.EntityFactory.hand
    (fun () ->
      let input = (Ambient.current ()).input in
      input |> Input.State.rightHand)
    physics grabbable
