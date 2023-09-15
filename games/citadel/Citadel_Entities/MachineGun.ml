open Babylon
open React3d
open System_Grabbable
open Citadel_Assets

type model = {
  rotation : Quaternion.t;
  position : Vector3.t;
  fireDelay : float;
  nextShoot : float;
  recoil : Recoil.t;
  grabState : System_Grabbable.GrabState.t;
  muzzleFlash : MuzzleFlash.t;
  physicsState : System_Physics.State.t;
  time : float;
}

let physicsShape =
  System_Physics.Shape.box ~height:0.12 ~width:0.04 ~depth:0.57 ()

let physicsOffset = Vector3.add (Vector3.up (-0.05)) (Vector3.forward (-0.18))

let initial position =
  {
    rotation = Quaternion.zero ();
    time = 0.;
    position;
    fireDelay = 0.1;
    nextShoot = 1.0;
    recoil = Recoil.create ();
    grabState = System_Grabbable.GrabState.initial ();
    muzzleFlash = MuzzleFlash.make 0.6;
    physicsState =
      System_Physics.State.create ~mass:5. ~initialPosition:position
        ~initialRotation:(Quaternion.initial ()) physicsShape;
  }

let shoot ~deltaTime rotation position model =
  if model.nextShoot < 0. then
    let offset = Vector3.up 0.125 |> Vector3.add (Vector3.forward 1.1) in
    let twoHandedGrabFactor =
      match model.grabState |> GrabState.isTwoHandedGrabbed with
      | true -> 4.0
      | false -> 1.0
    in
    let recoil =
      model.recoil
      |> Recoil.kick
           ~horizontal:(Random.float 1.0 -. 0.5)
           ~vertical:(Random.float 1.0 +. (4.0 /. twoHandedGrabFactor))
           ~kickback:(2.0 /. twoHandedGrabFactor)
    in
    let muzzlePosition, rotationWithRecoil =
      Recoil.computeMuzzlePositionAndRotation ~position ~muzzleOffset:offset
        ~rotation recoil
    in
    ( model.fireDelay,
      model.muzzleFlash |> MuzzleFlash.flash,
      recoil,
      EntityManager.Effect.batch
        [
          System_Audio.Effect.play ~position:muzzlePosition
            "assets/mg/PlasmaRifleFire01.wav";
          EntityManager.Effect.createEntity
            (Bolt.entity muzzlePosition rotationWithRecoil);
        ] )
  else
    ( model.nextShoot -. deltaTime,
      model.muzzleFlash |> MuzzleFlash.update deltaTime,
      model.recoil,
      EntityManager.Effect.none )

let tick ~deltaTime model =
  match model.grabState |> GrabState.state with
  | GrabState.Grabbed { position; rotation; isTriggerPressed; _ } ->
      let nextShoot', muzzleFlash', recoil', eff =
        if isTriggerPressed then shoot ~deltaTime rotation position model
        else
          ( 0.,
            model.muzzleFlash |> MuzzleFlash.update deltaTime,
            model.recoil,
            EntityManager.Effect.none )
      in
      let recoil'' = Recoil.update deltaTime recoil' in
      let physicsState' =
        System_Physics.State.create ~mass:5. ~initialPosition:position
          ~initialRotation:rotation physicsShape
      in
      ( {
          model with
          muzzleFlash = muzzleFlash';
          physicsState = physicsState';
          nextShoot = nextShoot';
          recoil = recoil'';
          position;
          rotation;
        },
        eff )
  | GrabState.Ungrabbed ->
      let physicsState = model.physicsState in
      let model' =
        {
          model with
          position = physicsState |> System_Physics.State.position;
          rotation = physicsState |> System_Physics.State.rotation;
          time = model.time +. deltaTime;
        }
      in
      (model', EntityManager.Effect.none)

module Gun = struct
  let render muzzleFlash time =
    let open Babylon in
    let open React3d in
    P.transform
      ~position:(Vector3.create ~x:0. ~y:(-0.025) ~z:(-0.07))
      ~rotation:(Quaternion.rotateAxis ~axis:(Vector3.up 1.0) Float.pi)
      [
        P.meshWithArgs
          ~args:
            (let open PlasmaRifle in
            { clipVisible = true; selectorRotation = time })
          PlasmaRifle.mesh;
        P.transform
          ~position:(Vector3.add (Vector3.forward (-0.825)) (Vector3.up 0.14))
          [ MuzzleFlash.render muzzleFlash ];
      ]
end

let render { muzzleFlash; position; rotation; recoil; time; grabState; _ } =
  match grabState |> GrabState.state with
  | GrabState.Ungrabbed ->
      let open React3d in
      P.transform ~position:physicsOffset
        [
          P.transform ~position ~rotation
            [ Recoil.component recoil [ Gun.render muzzleFlash time ] ];
        ]
  | GrabState.Grabbed _ ->
      let open React3d in
      P.transform ~position:(Babylon.Vector3.zero ())
        [
          P.transform ~position ~rotation
            [ Recoil.component recoil [ Gun.render muzzleFlash time ] ];
        ]

let handlePosition = Vector3.create ~x:0. ~y:(-0.025) ~z:(-0.07)

let grabHandles model =
  let position =
    match System_Grabbable.GrabState.state model.grabState with
    | GrabState.Grabbed _ -> model.position
    | GrabState.Ungrabbed -> Vector3.add model.position physicsOffset
  in
  System_Grabbable.Grabbable.make ~position ~rotation:model.rotation
    ~holsterType:HolsterTypes.largeItem
    [
      Grabbable.primary (Shape.sphere ~radius:0.1 handlePosition);
      Grabbable.secondary (Shape.sphere ~radius:0.125 (Vector3.forward 0.32));
    ]

let entity position =
  let open EntityManager.Entity in
  define (initial position)
  |> withThink tick
  |> withReadonlyComponent Components.render render
  |> System_Grabbable.Entity.grabbable
       ~readGrabState:(fun { grabState; _ } -> grabState)
       ~writeGrabState:(fun grabState state -> { state with grabState })
       ~grabHandles
  |> System_Physics.Entity.dynamic
       ~read:(fun { grabState; physicsState; _ } ->
         match grabState |> GrabState.state with
         | GrabState.Ungrabbed -> Some physicsState
         | GrabState.Grabbed _ -> None)
       ~write:(fun state entity ->
         match state with
         | None -> entity
         | Some state -> { entity with physicsState = state })
