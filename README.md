# Citadel

An experiment in building a WebXR experience in a functional programming language (OCaml)

Unfortunately I don't have a license to re-publish the assets to host an interactive demo, but here is a video:

Demo (in browser, but better in VR):

https://github.com/tommybuilds/citadel-xr/assets/110304079/b846b856-733a-4ced-bbe6-684fdd045340

## Technologies Used

- [OCaml](https://ocaml.org/)
- [esy](https://esy.sh/)
- [BabylonJS](https://www.babylonjs.com/) - WebXR, WebGL library
- [Ammo](https://github.com/kripken/ammo.js) - Ammo Physics Engine (emscripten build of the Bullet Physics engine)

## Notes

### Functional Rendering

This project uses a simple React-style reconciler for describing what to render. This translates the functional description of the scene into a set of mutable updates for Babylon. This makes it fun and easy to describe what is rendered:

[`Flashlight.ml`](games/citadel/Flashlight.ml)

```ocaml
let render model =
  let open React3d in
  let light =
    if model.isFlashlightOn then P.transform [ P.pointLight []; P.spotLight [] ]
    else P.transform []
  in
  P.transform ~position:(Vector3.zero ()) [ P.mesh flashLightMesh; light ]
```

### Immutable Entity-Component-System

This project has a quick-and-dirty immutable entity-component-system, defined in [`EntityManager.mli`](src/EntityManager/EntityManager.mli)

Entities are declarative and built by composing components:

```ocaml
let entity position =
  let open EntityManager.Entity in
  define (initial position)
  (* an update function, run every frame *)
  |> withThink tick
  (* a render component *)
  |> withReadonlyComponent Components.render render
  (* a grabbale component *)
  |> System_Grabbable.Entity.grabbable
       ~readGrabState:(fun { grabState; _ } -> grabState)
       ~writeGrabState:(fun grabState state -> { state with grabState })
       ~grabHandles
  (* a dynamic physics component, that changes staet when grabbed *)
  |> System_Physics.Entity.dynamic
       ~read:(fun { grabState; physicsState; _ } ->
         match grabState |> GrabState.state with
         | GrabState.Ungrabbed -> Some physicsState
         | GrabState.Grabbed _ -> None)
       ~write:(fun state entity ->
         match state with
         | None -> entity
         | Some state -> { entity with physicsState = state })

```

This was just a fun experiment; so I apologize that is not well documented.

# License

The code in this repo, aside from external dependencies (Babylon/Ammo/Noise) is licenesed under the MIT License.

# Summary

I enjoyed writing an app in this style, however, I found the the OCaml toolchain limited. Ultimately I wanted to cross-compile this to a native Android application, but I found the cross-compilation story for the OCaml toolchain to be quite lacking (compared to `go` or `rust`, for example). This motivated to pivot to Rust. I'd still like to revisit this functional style of gameplay logic, perhaps using a tool like [Fable](https://github.com/fable-compiler/fable), which could target Rust and then be cross-compiled.
