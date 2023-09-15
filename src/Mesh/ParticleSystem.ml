module Color = Babylon.Color
module Texture = Babylon.Texture
open Util
module MeshBuilder = Babylon.MeshBuilder
module Node = Babylon.Node
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
open Definition
module Schema =
  struct
    type colorGradient = {
      color: Color.t ;
      stop: float }
    type rampGradient = {
      color: Color.t ;
      stop: float }
    type colorRemapGradient = {
      min: float ;
      max: float ;
      stop: float }
    type limitVelocityGradient = {
      factor: float ;
      stop: float }
    type t =
      {
      friendlyName: string ;
      emitRate: float ;
      minSize: float ;
      maxSize: float ;
      minLifeTime: float ;
      maxLifeTime: float ;
      minEmitPower: float ;
      maxEmitPower: float ;
      colorGradient: colorGradient list ;
      rampGradient: rampGradient list ;
      colorRemapGradient: colorRemapGradient list ;
      limitVelocityGradients: limitVelocityGradient list ;
      particleTexture: Babylon.Texture.t ;
      startDelay: float ;
      targetStopDuration: float }
    let initial =
      {
        friendlyName = "";
        emitRate = 5000.;
        minSize = 6.;
        maxSize = 12.;
        minLifeTime = 1.0;
        maxLifeTime = 3.0;
        minEmitPower = 30.;
        maxEmitPower = 60.;
        colorGradient = [];
        rampGradient = [];
        colorRemapGradient = [];
        limitVelocityGradients = [];
        particleTexture =
          (Babylon.Texture.create ~invertY:false
             (("https://raw.githubusercontent.com/PatrickRyanMS/BabylonJStextures/master/ParticleSystems/Explosion/ExplosionSim_Sample.png")
             [@reason.raw_literal
               "https://raw.githubusercontent.com/PatrickRyanMS/BabylonJStextures/master/ParticleSystems/Explosion/ExplosionSim_Sample.png"]));
        startDelay = 0.;
        targetStopDuration = 0.4
      }
    let make name = { initial with friendlyName = name }
  end
type args = {
  active: bool }
type state =
  {
  particleSystem: Babylon.ParticleSystem.t ;
  isCurrentlyActive: bool }
let loader args =
  let node = Babylon.Node.createTransform ~name:"particleSystem" in
  let particleSystem = Babylon.ParticleSystem.create () in
  (let open Babylon in
     particleSystem |> (ParticleSystem.setEmitRate 500.);
     particleSystem |> (ParticleSystem.setMinSize 0.01);
     particleSystem |> (ParticleSystem.setMaxSize 0.1);
     particleSystem |> (ParticleSystem.setMinLifeTime 1.);
     particleSystem |> (ParticleSystem.setMaxLifeTime 3.);
     particleSystem |> (ParticleSystem.setMinEmitPower 0.01);
     particleSystem |> (ParticleSystem.setMaxEmitPower 0.1);
     (let texture =
        Babylon.Texture.create ~invertY:false
          (("https://raw.githubusercontent.com/PatrickRyanMS/BabylonJStextures/master/ParticleSystems/Explosion/ExplosionSim_Sample.png")
          [@reason.raw_literal
            "https://raw.githubusercontent.com/PatrickRyanMS/BabylonJStextures/master/ParticleSystems/Explosion/ExplosionSim_Sample.png"]) in
      particleSystem |> (ParticleSystem.setParticleTexture texture);
      particleSystem |> (ParticleSystem.setEmitter node)));
  Promise.resolve ({ particleSystem; isCurrentlyActive = false }, node)
let applyArgs (args : args)
  ({ particleSystem; isCurrentlyActive } as lastState) _node =
  if args.active != isCurrentlyActive
  then
    (if args.active
     then Babylon.ParticleSystem.start ~delay:0.0 particleSystem
     else Babylon.ParticleSystem.stop particleSystem);
  { lastState with isCurrentlyActive = (args.active) }
let particleSystem = simple applyArgs loader "particle_system"