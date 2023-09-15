module Loader = Loader
module Material = Material
module Definition = Definition
module Instance = Instance
module MeshProcessor = MeshProcessor
module Plane = Plane
module Registry = Registry
module Sphere = Sphere
module Static = Static
module ParticleSystem = ParticleSystem
module Animation = Animation
module AnimationPlayer = AnimationPlayer
module AnimatedMesh2 = AnimatedMesh2
let animation = Animation.animation
let plane = Plane.plane
let sphere = Sphere.sphere
let particleSystem = ParticleSystem.particleSystem
let mesh ?friendlyId  ?(postProcess= MeshProcessor.none)  loader =
  DynamicMesh.make ?friendlyId ~editor:Editor.empty ~initialArgs:()
    ~initialState:(fun _ -> ()) ~postProcess
    ~apply:(fun _args -> fun state -> fun _node -> state) loader
let animated = AnimatedMesh2.mesh
let dynamic = DynamicMesh.make