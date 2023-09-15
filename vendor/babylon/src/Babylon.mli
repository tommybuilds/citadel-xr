open Js_of_ocaml

type dispose = unit -> unit
type 'kind node
type abstract
type transform
type camera
type mesh
type bone
type 'kind light
type hemispheric
type point
type spot
type directional

module Engine : sig
  type t

  val create : Dom_html.canvasElement Js.t -> t
  val null : unit -> t
  val runRenderLoop : (unit -> unit) -> t -> dispose
  val enterPointerLock : t -> unit
  val isPointerLock : t -> bool
  val getDeltaTime : t -> float
end

module DebugLayer : sig
  type t

  val isVisible : t -> bool
  val hide : t -> unit
  val show : t -> unit
end

module Vector3 : sig
  type t

  val create : x:float -> y:float -> z:float -> t
  val create1 : float -> t
  val clone : t -> t
  val cross : t -> t -> t
  val dot : t -> t -> float
  val add : t -> t -> t
  val multiply : t -> t -> t
  val subtract : t -> t -> t
  val length : t -> float
  val lengthSquared : t -> float
  val zero : unit -> t
  val one : t
  val x : t -> float
  val y : t -> float
  val z : t -> float
  val normalize : t -> t
  val scale : float -> t -> t
  val up : float -> t
  val left : float -> t
  val right : float -> t
  val forward : float -> t
  val toString : t -> string
  val lerp : start:t -> stop:t -> float -> t
  val equals : t -> t -> bool
end

module Sound : sig
  type ambient
  type spatial
  type 'a t

  val ambient : name:string -> string -> ambient t
  val spatial : name:string -> position:Vector3.t -> string -> spatial t
  val isPaused : _ t -> bool
  val isPlaying : _ t -> bool
  val isReady : _ t -> bool
  val play : _ t -> unit
  val setPosition : position:Vector3.t -> spatial t -> unit
  val dispose : _ t -> unit
end

module Quaternion : sig
  type t

  val create : x:float -> y:float -> z:float -> w:float -> t
  val zero : unit -> t
  val identity : unit -> t
  val initial : unit -> t
  val invert : t -> t
  val clone : t -> t
  val lookAt : forward:Vector3.t -> up:Vector3.t -> t
  val toEulerAngles : t -> Vector3.t
  val multiply : t -> t -> t
  val rotateAxis : axis:Vector3.t -> float -> t
  val rotateVector : Vector3.t -> t -> Vector3.t
  val equals : t -> t -> bool
  val toString : t -> string
end

module Matrix : sig
  type t

  val compose :
    scale:Vector3.t -> rotation:Quaternion.t -> translation:Vector3.t -> t

  val multiply : t -> t -> t
  val transformCoordinates : t -> Vector3.t -> Vector3.t

  type decomposed = {
    translation : Vector3.t;
    rotation : Quaternion.t;
    scale : Vector3.t;
  }

  val decompose : t -> decomposed
end

module Color : sig
  type t

  val make : r:float -> g:float -> b:float -> t
  val make4f : r:float -> g:float -> b:float -> a:float -> t
  val make3i : r:int -> g:int -> b:int -> t
  val white : t
  val black : t
end

module Scene : sig
  type t

  val create : Engine.t -> t
  val render : t -> unit
  val dispose : t -> unit
  val createDefaultXRExperienceAsync : t -> unit Promise.t
  val debugLayer : t -> DebugLayer.t
  val registerBeforeRender : (unit -> unit) -> t -> dispose
  val setActiveCamera : camera:camera node -> t -> unit
  val setAmbientColor : color:Color.t -> t -> unit
  val setClearColor : color:Color.t -> t -> unit
end

module GlowLayer : sig
  type t

  val create : Scene.t -> t
  val setIntensity : intensity:float -> t -> unit
end

module Node : sig
  val setEnabled : enabled:bool -> 'a node -> unit
  val setParent : parent:'a node -> 'b node -> unit
  val setPosition : position:Vector3.t -> 'a node -> unit
  val getChildren : 'a node -> abstract node array
  val getChildMeshes : 'a node -> mesh node array
  val getPosition : 'a node -> Vector3.t
  val clone : 'a node -> 'a node
  val abstract : 'a node -> abstract node
  val name : 'a node -> string
  val setName : string -> 'a node -> unit
  val rotation : 'a node -> Vector3.t
  val setRotation : rotation:Vector3.t -> 'a node -> unit
  val scaling : 'a node -> Vector3.t
  val setScaling : scale:Vector3.t -> 'a node -> unit
  val rotationQuat : 'a node -> Quaternion.t
  val setRotationQuat : quaternion:Quaternion.t -> 'a node -> unit
  val createTransform : name:string -> transform node
  val computeWorldMatrix : 'a node -> Matrix.t
  val getMeshesByName : string -> 'a node -> mesh node array
  val isMesh : 'a node -> bool
  val toMesh : 'a node -> mesh node option
  val dispose : 'a node -> unit
end

module Light : sig
  val setIntensity : intensity:float -> _ light node -> unit
  val setRange : range:float -> _ light node -> unit
  val setSpecular : color:Color.t -> _ light node -> unit
  val setDiffuse : color:Color.t -> _ light node -> unit
  val setGroundColor : color:Color.t -> hemispheric light node -> unit

  val spot :
    ?angle:float ->
    ?exponent:float ->
    position:Vector3.t ->
    direction:Vector3.t ->
    unit ->
    spot light node

  val setDirection : direction:Vector3.t -> spot light node -> unit
  val point : name:string -> position:Vector3.t -> point light node
  val hemispheric : name:string -> direction:Vector3.t -> hemispheric light node
  val dispose : _ light node -> unit
end

module Angle : sig
  type radians

  val radians : float -> radians
end

module Camera : sig
  val free : name:string -> position:Vector3.t -> Scene.t -> camera node
  val arcRotate : name:string -> target:Vector3.t -> Scene.t -> camera node

  val attachControl :
    canvas:Dom_html.canvasElement Js.t -> attached:bool -> camera node -> unit

  val setTarget : target:Vector3.t -> camera node -> unit
  val setInertia : inertia:float -> camera node -> unit
  val rotate : x:Angle.radians -> y:Angle.radians -> camera node -> unit
  val absoluteRotation : camera node -> Quaternion.t
  val realWorldHeight : camera node -> float

  val setTransformationFromNonVRCamera :
    ?resetToBaseReferenceSpace:bool ->
    sourceCamera:camera node ->
    camera node ->
    unit
end

module GUI : sig
  type 'kind control
  type button

  val setText : text:string -> button control -> unit

  module Manager3d : sig
    type t

    val create : Scene.t -> t
    val addControl : control:'a control node -> t -> unit
    val removeControl : control:'a control node -> t -> unit
  end

  module HolographicButton : sig
    type t

    val create : name:string -> button control node
    val unwrap : button control node -> button control
  end
end

module Texture : sig
  type t

  val create : invertY:bool -> string -> t
  val dynamic : ?name:string -> ?width:int -> ?height:int -> unit -> t
  val setUScale : scale:float -> t -> unit
  val setVScale : scale:float -> t -> unit
  val setHasAlpha : hasAlpha:bool -> t -> unit
  val setAlpha : alpha:float -> t -> unit
end

module ParticleSystem : sig
  type t

  module Options : sig
    type t

    val default : t
    val withCapacity : int -> t -> t
  end

  val create : ?options:Options.t -> unit -> t

  type emitter

  val createHemisphericEmitter :
    radius:float -> radiusRange:float -> t -> emitter

  val setEmitter : _ node -> t -> unit
  val setEmitRate : float -> t -> unit
  val setMinSize : float -> t -> unit
  val setMaxSize : float -> t -> unit
  val setMinLifeTime : float -> t -> unit
  val setMaxLifeTime : float -> t -> unit
  val setMinEmitPower : float -> t -> unit
  val setMaxEmitPower : float -> t -> unit
  val addLimitVelocityGradient : factor:float -> float -> t -> unit
  val addColorGradient : color:Color.t -> float -> t -> unit
  val addRampGradient : color:Color.t -> float -> t -> unit
  val setUseRampGradients : bool -> t -> unit
  val addColorRemapGradient : min:float -> max:float -> float -> t -> unit
  val reset : t -> unit
  val start : delay:float -> t -> unit
  val stop : t -> unit
  val setTargetStopDuration : float -> t -> unit
  val setLimitVelocityDamping : float -> t -> unit
  val setMinInitialRotation : float -> t -> unit
  val setMaxInitialRotation : float -> t -> unit
  val setParticleTexture : Texture.t -> t -> unit
end

module Material : sig
  type t

  val freeze : t -> unit
  val unfreeze : t -> unit
  val standard : name:string -> t
  val setWireframe : wireframe:bool -> t -> unit
  val setDiffuseColor : color:Color.t -> t -> unit
  val setSpecularColor : color:Color.t -> t -> unit
  val setEmissiveColor : color:Color.t -> t -> unit
  val setAmbientColor : color:Color.t -> t -> unit
  val setDiffuseTexture : texture:Texture.t -> t -> unit
  val setNormalTexture : texture:Texture.t -> t -> unit
  val setSpecularTexture : texture:Texture.t -> t -> unit
  val setEmissiveTexture : texture:Texture.t -> t -> unit
  val setBumpTexture : texture:Texture.t -> t -> unit
end

module AnimationGroup : sig
  type t

  val name : t -> string
  val play : t -> unit
  val stop : t -> unit
  val goToFrame : float -> t -> unit
end

module Bone : sig
  val getLocalPosition : bone node -> Vector3.t
  val getLocalRotation : bone node -> Quaternion.t
end

module Skeleton : sig
  type t

  val boneCount : t -> int
  val getBoneByIndex : int -> t -> bone node option
end

module Mesh : sig
  val custom : name:string -> mesh node
  val setVisibility : float -> mesh node -> unit
  val visibility : mesh node -> float
  val setMaterial : material:Material.t -> mesh node -> unit
  val bakeTransformIntoVertices : Matrix.t -> mesh node -> unit
  val refreshBoundingInfo : mesh node -> unit
end

module WebXR : sig
  module Handedness : sig
    type t = None | Left | Right

    val toString : t -> string
  end

  module ControllerAxes : sig
    type t

    val x : t -> float
    val y : t -> float
  end

  module ControllerComponent : sig
    type t

    val id : t -> string
    val pressed : t -> bool
    val axes : t -> ControllerAxes.t
  end

  module MotionController : sig
    type t

    val componentIds : t -> string array
    val getComponent : string -> t -> ControllerComponent.t option
    val handedness : t -> Handedness.t
    val pulse : value:float -> duration:float -> t -> unit
  end

  module Controller : sig
    type t

    val uniqueId : t -> string
    val grip : t -> mesh node option
    val pointer : t -> mesh node
    val motionController : t -> MotionController.t option
  end

  module Input : sig
    type t

    val controllers : t -> Controller.t array
  end

  module ExperienceHelper : sig
    type t

    val camera : t -> camera node
    val isInXR : t -> bool
  end

  module DefaultExperience : sig
    type t

    val input : t -> Input.t
    val baseExperience : t -> ExperienceHelper.t
  end

  val createDefaultXRExperienceAsync : Scene.t -> DefaultExperience.t Promise.t
end

module VertexData : sig
  type t

  val create : unit -> t
  val setPositions : positions:float array -> t -> unit
  val setIndices : indices:int array -> t -> unit
  val setUVs : uvs:float array -> t -> unit
  val applyToMesh : mesh:mesh node -> t -> unit
end

module MeshBuilder : sig
  module Sphere : sig
    type options = { diameter : float }

    val default : options
    val create : name:string -> options:options -> mesh node
  end

  module Box : sig
    type options = { size : float }

    val default : options
    val create : ?options:options -> unit -> mesh node
  end

  module Cylinder : sig
    type options = { height : float; diameter : float }

    val default : options
    val create : ?options:options -> unit -> mesh node
  end

  module Ground : sig
    type options = { width : float; height : float }

    val create : ?options:options -> unit -> mesh node
  end

  module Plane : sig
    type options = { width : float; height : float }

    val default : options
    val create : ?options:options -> ?name:string -> unit -> mesh node
  end
end

module AssetContainer : sig
  type t

  module Entries : sig
    type t

    val nodes : t -> _ node array
  end

  val instantiateModelsToScene : prefix:string -> t -> Entries.t
end

module SceneLoader : sig
  module LoadResult : sig
    type t

    val meshes : t -> mesh node array
    val skeletons : t -> Skeleton.t array
    val animationGroups : t -> AnimationGroup.t array
  end

  val importMeshAsync :
    ?rootUrl:string ->
    fileName:string ->
    Scene.t option ->
    LoadResult.t Promise.t

  val loadAssetContainerAsync :
    rootUrl:string -> string -> AssetContainer.t Promise.t
end

module QuaternionEx : sig
  val lookAt : ?up:Vector3.t -> Vector3.t -> Quaternion.t
end
