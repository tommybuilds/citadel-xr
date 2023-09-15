open Babylon
open EntityManager

type sound = { path : string; sound : Babylon.Sound.spatial Babylon.Sound.t }
type context = { activeSounds : sound list ref }

let isInactive sound =
  Babylon.Sound.isReady sound && not (Babylon.Sound.isPlaying sound)

let isActive sound = not (isInactive sound)

let tick ~deltaTime:_ ~world context =
  let currentSounds = !(context.activeSounds) in
  let inactiveSounds =
    currentSounds |> List.filter (fun { sound; _ } -> isInactive sound)
  in
  let activeSounds =
    currentSounds |> List.filter (fun { sound; _ } -> isActive sound)
  in
  inactiveSounds |> List.iter (fun { sound; _ } -> Babylon.Sound.dispose sound);
  context.activeSounds := activeSounds;
  (context, world)

let system = System.define ~tick { activeSounds = ref [] }

module Effect = struct
  let sideEffect = EntityManager.System.Effect.sideEffect

  type positionalArgs = { position : Vector3.t; path : string }

  let positionalEffect =
    sideEffect
      (fun args context ->
        let sound =
          Babylon.Sound.spatial ~name:"gunshot" ~position:args.position
            args.path
        in
        context.activeSounds :=
          { path = args.path; sound } :: !(context.activeSounds))
      system

  let play ~position path =
    let eff =
      (positionalEffect { position; path } : unit EntityManager.Effect.t)
    in
    eff
end
