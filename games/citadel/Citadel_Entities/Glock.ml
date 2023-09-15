open Babylon
open React3d
open System_Grabbable
open Citadel_Assets

type msg = Noop | ClipInserted of { clipSize : int } | SilencerAdded
type clipState = Unloaded | Loaded of { bullets : int }

type model = {
  isBulletInChamber : bool;
  hasSilencer : bool;
  clip : clipState;
  rotation : Quaternion.t;
  position : Vector3.t;
  fireDelay : float;
  nextShoot : float;
  recoil : Recoil.t;
  grabState : System_Grabbable.GrabState.t;
  physicsState : System_Physics.State.t;
  muzzleFlash : MuzzleFlash.t;
  time : float;
}

let physicsShape =
  System_Physics.Shape.box ~height:0.075 ~width:0.02 ~depth:0.13 ()

let physicsOffset = Vector3.add (Vector3.up 0.00) (Vector3.forward 0.0)
let renderOffset = Vector3.create ~x:(-0.00) ~y:(-0.085) ~z:(-0.09)
let muzzleOffset = Vector3.add (Vector3.forward 0.227) (Vector3.up 0.11)

let initial position =
  {
    isBulletInChamber = true;
    hasSilencer = false;
    clip = Loaded { bullets = 17 };
    rotation = Quaternion.zero ();
    time = 0.;
    position;
    fireDelay = 0.5;
    nextShoot = 1.0;
    recoil = Recoil.create ();
    muzzleFlash = MuzzleFlash.make 0.2;
    grabState = System_Grabbable.GrabState.initial ();
    physicsState =
      System_Physics.State.create ~mass:5. ~initialPosition:position
        ~initialRotation:(Quaternion.initial ()) physicsShape;
  }

let cycle model =
  match model.clip with
  | Unloaded -> model
  | Loaded _ when model.isBulletInChamber -> model
  | Loaded { bullets } when bullets > 0 ->
      {
        model with
        isBulletInChamber = true;
        clip = Loaded { bullets = bullets - 1 };
      }
  | Loaded _ -> model

let shoot ~deltaTime rotation position model =
  let recoil =
    model.recoil
    |> Recoil.kick
         ~horizontal:(Random.float 1.0 -. 0.5)
         ~vertical:(Random.float 1.0) ~kickback:1.0
  in
  let muzzlePosition, rotationWithRecoil =
    Recoil.computeMuzzlePositionAndRotation ~position
      ~muzzleOffset:(Vector3.add muzzleOffset renderOffset)
      ~rotation recoil
  in
  let gForward =
    Quaternion.rotateVector (Vector3.forward 1.0) rotationWithRecoil
  in
  let gRight = Quaternion.rotateVector (Vector3.right 1.0) rotationWithRecoil in
  let gUp = Quaternion.rotateVector (Vector3.up 1.0) rotationWithRecoil in
  let rand x = Random.float (x *. 2.) -. x in
  let shellVelocity =
    Vector3.add
      (Vector3.scale (-0.5 +. rand 0.1) gRight)
      (Vector3.scale (2.0 +. rand 0.2) gUp)
  in
  let nextShoot = model.fireDelay in
  let muzzleFlash = model.muzzleFlash |> MuzzleFlash.flash in
  let eff =
    EntityManager.Effect.batch
      [
        EntityManager.Effect.createEntity
          (Gib.entity
             ~position:
               (muzzlePosition
               |> Vector3.add (Vector3.scale (-0.1) gForward)
               |> Vector3.add (Vector3.scale 0.01 shellVelocity))
             ~velocity:shellVelocity ~rotation:rotationWithRecoil);
        EntityManager.Effect.createEntity
          (Bullet.entity muzzlePosition rotationWithRecoil);
        (match model.hasSilencer with
        | true -> EntityManager.Effect.none
        | false ->
            System_Audio.Effect.play ~position:muzzlePosition
              ("https://playground.babylonjs.com/sounds/gunshot.wav"
              [@reason.raw_literal
                "https://playground.babylonjs.com/sounds/gunshot.wav"]));
      ]
    |> EntityManager.Effect.map (fun () -> Noop)
  in
  ( { model with isBulletInChamber = false; muzzleFlash; nextShoot; recoil }
    |> cycle,
    eff )

let ejectClip model = ({ model with clip = Unloaded }, EntityManager.Effect.none)

let tick ~deltaTime model =
  match model.grabState |> GrabState.state with
  | GrabState.Grabbed
      {
        position;
        rotation;
        isTriggerPressed;
        isButton1Pressed;
        isButton2Pressed;
        _;
      } ->
      let model', eff =
        if isButton1Pressed then model |> ejectClip
        else if isButton2Pressed && not model.isBulletInChamber then
          (model |> cycle, EntityManager.Effect.none)
        else if isTriggerPressed then
          if model.nextShoot < 0. && model.isBulletInChamber then
            shoot ~deltaTime rotation position model
          else (model, EntityManager.Effect.none)
        else ({ model with nextShoot = -0.1 }, EntityManager.Effect.none)
      in
      let recoil'' = Recoil.update deltaTime model'.recoil in
      let physicsState' =
        System_Physics.State.create ~mass:5. ~initialPosition:position
          ~initialRotation:rotation physicsShape
      in
      ( {
          model' with
          muzzleFlash = MuzzleFlash.update deltaTime model'.muzzleFlash;
          physicsState = physicsState';
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

let muzzleFlashMaterial =
  React3d.Material.standard ~diffuseTexture:"assets/muzzle-flash2.png"
    ~emissiveTexture:"assets/muzzle-flash2.png"
    ~emissiveColor:Babylon.Color.white ~hasAlpha:true ()

module Gun = struct
  let render ~hasSilencer ~clipVisible ~slideOpen ~muzzleFlash time =
    let open Babylon in
    let open React3d in
    P.transform ~position:renderOffset
      [
        P.meshWithArgs
          ~args:
            (let open Glock in
            {
              clipVisible;
              slideAmount = (match slideOpen with true -> 1.0 | false -> 0.0);
            })
          Glock.glock;
        P.transform ~position:muzzleOffset
          [
            P.transform
              ~position:(Vector3.add (Vector3.up 0.005) (Vector3.forward 0.03))
              ~scale:(Vector3.create1 1.1)
              (match hasSilencer with
              | true -> [ P.mesh Silencer.mesh ]
              | false -> []);
            P.transform
              ~position:
                (match hasSilencer with
                | true -> Vector3.forward 0.15
                | false -> Vector3.zero ())
              [ MuzzleFlash.render muzzleFlash ];
          ];
      ]
end

let isClipVisible { clip } =
  match clip with Loaded _ -> true | Unloaded -> false

let render
    ({
       hasSilencer;
       isBulletInChamber;
       muzzleFlash;
       position;
       rotation;
       recoil;
       time;
       grabState;
       _;
     } as model) =
  let slideOpen =
    (not isBulletInChamber) || MuzzleFlash.isVisible muzzleFlash
  in
  let clipVisible = model |> isClipVisible in
  match grabState |> GrabState.state with
  | GrabState.Ungrabbed ->
      let open React3d in
      P.transform ~position:physicsOffset
        [
          P.transform ~position ~rotation
            [
              Recoil.component recoil
                [
                  Gun.render ~hasSilencer ~clipVisible ~slideOpen ~muzzleFlash
                    time;
                ];
            ];
        ]
  | GrabState.Grabbed _ ->
      let open React3d in
      P.transform
        [
          P.transform ~position ~rotation
            [
              Recoil.component recoil
                [
                  Gun.render ~hasSilencer ~clipVisible ~slideOpen ~muzzleFlash
                    time;
                ];
            ];
        ]

let handlePosition = Vector3.create ~x:0. ~y:0.2 ~z:0.05

let grabHandles model =
  let position =
    match System_Grabbable.GrabState.state model.grabState with
    | GrabState.Grabbed _ -> model.position
    | GrabState.Ungrabbed -> Vector3.add model.position physicsOffset
  in
  System_Grabbable.Grabbable.make ~position ~rotation:model.rotation
    ~holsterType:HolsterTypes.smallItem
    [
      Grabbable.primary (Shape.sphere ~radius:0.2 handlePosition);
      Grabbable.dropTarget (Shape.sphere ~radius:0.2 handlePosition)
        Payloads.glockClip (fun num -> ClipInserted { clipSize = num });
      Grabbable.dropTarget (Shape.sphere ~radius:0.2 handlePosition)
        Payloads.glockSilencer (fun num -> SilencerAdded);
    ]

let update msg model =
  match msg with
  | Noop -> (model, EntityManager.Effect.none)
  | ClipInserted { clipSize } ->
      ( { model with clip = Loaded { bullets = clipSize } },
        EntityManager.Effect.none )
  | SilencerAdded ->
      ({ model with hasSilencer = true }, EntityManager.Effect.none)

let entity position =
  let clipHandler =
    Payload.handler Payloads.glockClip (fun num ->
        ClipInserted { clipSize = num })
  in
  let silencerHandler =
    Payload.handler Payloads.glockSilencer (fun () -> SilencerAdded)
  in
  let open EntityManager.Entity in
  define (initial position)
  |> withUpdate update |> withThink tick
  |> withReadonlyComponent Components.render render
  |> System_Grabbable.Entity.grabbable
       ~payloads:[ clipHandler; silencerHandler ]
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
