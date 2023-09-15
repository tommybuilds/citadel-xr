open Js_of_ocaml

type dispose = unit -> unit
type 'kind node
type abstract
type transform
type mesh
type camera
type bone
type 'kind light
type hemispheric
type point
type spot
type directional

module Angle = struct
  type radians = float

  let radians (angle : float) = angle
end

module Engine = struct
  type t

  external create : Dom_html.canvasElement Js.t -> t = "babylon_engine_ctor"
  external null : unit -> t = "babylon_engine_null_ctor"

  external runRenderLoop : (unit -> unit) -> t -> dispose
    = "babylon_engine_runRenderLoop"

  external enterPointerLock : t -> unit = "babylon_engine_enterPointerLock"
  external isPointerLock : t -> bool = "babylon_engine_isPointerLock"
  external getDeltaTime : t -> float = "babylon_engine_getDeltaTime"
end

module DebugLayer = struct
  type t

  external isVisible : t -> bool = "babylon_debugLayer_isVisible"
  external hide : t -> unit = "babylon_debugLayer_hide"
  external show : t -> unit = "babylon_debugLayer_show"
end

module Color = struct
  type t

  external make : r:float -> g:float -> b:float -> t = "babylon_color3_ctor"

  external make4f : r:float -> g:float -> b:float -> a:float -> t
    = "babylon_color4_ctor"

  let make3i ~r ~g ~b =
    let redF = float r /. 255. in
    let greenF = float g /. 255. in
    let blueF = float b /. 255. in
    make ~r:redF ~g:greenF ~b:blueF

  let black = make ~r:0. ~g:0. ~b:0.
  let white = make ~r:1.0 ~g:1.0 ~b:1.
end

module Scene = struct
  type t

  external create : Engine.t -> t = "babylon_scene_ctor"

  external createDefaultXRExperienceAsync : t -> unit Promise.t
    = "babylon_scene_create_default_xr_experience_async"

  external dispose : t -> unit = "babylon_scene_dispose"
  external render : t -> unit = "babylon_scene_render"
  external debugLayer : t -> DebugLayer.t = "babylon_scene_debugLayer"

  external registerBeforeRender : (unit -> unit) -> t -> dispose
    = "babylon_scene_registerBeforeRender"

  external setActiveCamera : camera:camera node -> t -> unit
    = "babylon_scene_setActiveCamera"

  external setAmbientColor : color:Color.t -> t -> unit
    = "babylon_scene_setAmbientColor"

  external setClearColor : color:Color.t -> t -> unit
    = "babylon_scene_setClearColor"
end

module GlowLayer = struct
  type t

  external create : Scene.t -> t = "babylon_glowLayer_ctor"

  external setIntensity : intensity:float -> t -> unit
    = "babylon_glowLayer_setIntensity"
end

module GUI = struct
  type 'kind control
  type button

  module Manager3d = struct
    type t

    external create : Scene.t -> t = "babylon_gui_manager3d_create"

    external addControl : control:'a control node -> t -> unit
      = "babylon_gui_manager3d_addControl"

    external removeControl : control:'a control node -> t -> unit
      = "babylon_gui_manager3d_removeControl"
  end
  external setText : text:string -> button control -> unit
    = "babylon_gui_setText"

  module HolographicButton = struct
    type t

    external create : name:string -> button control node
      = "babylon_gui_holographicButton_create"

    let unwrap = Obj.magic
  end
end

module Vector3 = struct
  type t

  external create : x:float -> y:float -> z:float -> t = "babylon_vec3_ctor"

  let create1 v = create ~x:v ~y:v ~z:v

  external clone : t -> t = "babylon_clone"
  external cross : t -> t -> t = "babylon_vec3_cross"
  external dot : t -> t -> float = "babylon_vec3_dot"
  external normalize : t -> t = "babylon_vec3_normalize"
  external add : t -> t -> t = "babylon_vec3_add"
  external multiply : t -> t -> t = "babylon_vec3_multiply"
  external subtract : t -> t -> t = "babylon_vec3_subtract"
  external length : t -> float = "babylon_vec3_length"
  external lengthSquared : t -> float = "babylon_vec3_lengthSquared"
  external lerp : start:t -> stop:t -> float -> t = "babylon_vec3_lerp"
  external x : t -> float = "babylon_vec3_getX"
  external y : t -> float = "babylon_vec3_getY"
  external z : t -> float = "babylon_vec3_getZ"

  let zero () = create ~x:0. ~y:0. ~z:0.
  let one = create ~x:1. ~y:1. ~z:1.
  let up y = create ~x:0. ~y ~z:0.

  external scale : float -> t -> t = "babylon_vec3_scale"

  let forward z = create ~x:0. ~y:0. ~z
  let left x = create ~x:(-1.0 *. x) ~y:0. ~z:0.
  let right x = create ~x ~y:0. ~z:0.

  external equals : t -> t -> bool = "js_equals"
  external toString : t -> string = "js_to_string"
end

module Sound = struct
  type ambient
  type spatial
  type 'a t

  external ambient : name:string -> string -> ambient t
    = "babylon_sound_ambient"

  external spatial : name:string -> position:Vector3.t -> string -> spatial t
    = "babylon_sound_spatial"

  external isPaused : _ t -> bool = "babylon_sound_isPaused"
  external isPlaying : _ t -> bool = "babylon_sound_isPlaying"
  external isReady : _ t -> bool = "babylon_sound_isReady"
  external play : _ t -> unit = "babylon_sound_play"

  external setPosition : position:Vector3.t -> spatial t -> unit
    = "babylon_sound_setPosition"

  external dispose : _ t -> unit = "babylon_sound_dispose"
end

module Quaternion = struct
  type t

  external clone : t -> t = "babylon_clone"
  external equals : t -> t -> bool = "js_equals"
  external toString : t -> string = "js_to_string"

  external create : x:float -> y:float -> z:float -> w:float -> t
    = "babylon_quat_ctor"

  let zero () = create ~x:0. ~y:0. ~z:0. ~w:0.
  let identity () = create ~x:0. ~y:0. ~z:0. ~w:1.0

  external invert : t -> t = "babylon_quat_invert"
  external toEulerAngles : t -> Vector3.t = "babylon_quat_toEulerAngles"

  external lookAt : forward:Vector3.t -> up:Vector3.t -> t
    = "babylon_quat_lookAt"

  external multiply : t -> t -> t = "babylon_quat_multiply"
  external rotateAxis : axis:Vector3.t -> float -> t = "babylon_quat_rotateAxis"

  external rotateVector : Vector3.t -> t -> Vector3.t
    = "babylon_quat_rotateVector"

  let initial () = rotateAxis ~axis:(Vector3.up 1.0) 0.
end

module Matrix = struct
  type t

  external compose :
    scale:Vector3.t -> rotation:Quaternion.t -> translation:Vector3.t -> t
    = "babylon_matrix_compose"

  external multiply : t -> t -> t = "babylon_matrix_multiply"

  type decomposed = {
    translation : Vector3.t;
    rotation : Quaternion.t;
    scale : Vector3.t;
  }

  external decomposed_internal : t -> Js.Unsafe.any = "babylon_matrix_decompose"

  let decompose matrix =
    let obj = decomposed_internal matrix in
    let translation = (Js.Unsafe.get obj "translation" : Vector3.t) in
    let rotation = (Js.Unsafe.get obj "rotation" : Quaternion.t) in
    let scale = (Js.Unsafe.get obj "scale" : Vector3.t) in
    { translation; rotation; scale }

  external transformCoordinates : t -> Vector3.t -> Vector3.t
    = "babylon_matrix_transformCoordinates"
end

module Node = struct
  external setEnabled : enabled:bool -> 'a node -> unit
    = "babylon_node_setEnabled"

  external setParent : parent:'a node -> 'b node -> unit
    = "babylon_node_setParent"

  external setPosition : position:Vector3.t -> 'a node -> unit
    = "babylon_node_setPosition"

  external getChildren : 'a node -> abstract node array
    = "babylon_node_getChildren"

  external getChildMeshes : 'a node -> mesh node array
    = "babylon_node_getChildMeshes"

  external clone : 'a node -> 'a node = "babylon_node_clone"
  external abstract : _ node -> abstract node = "babylon_node_abstract"
  external name : _ node -> string = "babylon_node_getName"
  external setName : string -> 'a node -> unit = "babylon_node_setName"
  external getPosition : 'a node -> Vector3.t = "babylon_node_getPosition"
  external rotation : 'a node -> Vector3.t = "babylon_node_getRotation"

  external setRotation : rotation:Vector3.t -> 'a node -> unit
    = "babylon_node_setRotation"

  external scaling : 'a node -> Vector3.t = "babylon_node_getScaling"

  external setScaling : scale:Vector3.t -> 'a node -> unit
    = "babylon_node_setScaling"

  external rotationQuat : 'a node -> Quaternion.t = "babylon_node_getQuaternion"

  external setRotationQuat : quaternion:Quaternion.t -> 'a node -> unit
    = "babylon_node_setQuaternion"

  external computeWorldMatrix : 'a node -> Matrix.t
    = "babylon_node_computeWorldMatrix"

  external createTransform : name:string -> transform node
    = "babylon_node_createTransform"

  external getMeshesByName : string -> 'a node -> mesh node array
    = "babylon_node_getMeshesByName"

  external dispose : _ node -> unit = "babylon_node_dispose"
  external isMesh : _ node -> bool = "babylon_node_isMesh"

  let toMesh : 'a. 'a node -> 'mesh node option =
   fun node -> if isMesh node then Some (Obj.magic node) else None
end

module Light = struct
  external hemispheric :
    name:string -> direction:Vector3.t -> hemispheric light node
    = "babylon_light_hemispheric_ctor"

  external point : name:string -> position:Vector3.t -> point light node
    = "babylon_light_point_ctor"

  external _spot :
    angle:float ->
    exponent:float ->
    position:Vector3.t ->
    direction:Vector3.t ->
    spot light node = "babylon_light_spot_ctor"

  let spot ?(angle = Float.pi /. 3.0) ?(exponent = 2.0) ~position ~direction ()
      =
    _spot ~angle ~exponent ~position ~direction

  external setDirection : direction:Vector3.t -> spot light node -> unit
    = "babylon_light_setDirection"

  external setIntensity : intensity:float -> _ light node -> unit
    = "babylon_light_setIntensity"

  external setRange : range:float -> _ light node -> unit
    = "babylon_light_setRange"

  external setSpecular : color:Color.t -> _ light node -> unit
    = "babylon_light_setSpecular"

  external setDiffuse : color:Color.t -> _ light node -> unit
    = "babylon_light_setDiffuse"

  external setGroundColor : color:Color.t -> hemispheric light node -> unit
    = "babylon_light_setGroundColor"

  external dispose : _ light node -> unit = "babylon_dispose"
end

module Texture = struct
  type t

  external create : invertY:bool -> string -> t = "babylon_texture_ctor"

  external _dynamic : name:string -> width:int -> height:int -> t
    = "babylon_texture_dynamic"

  let dynamic ?(name = "DynamicTexture") ?(width = 256) ?(height = 256) () =
    _dynamic ~name ~width ~height

  external setUScale : scale:float -> t -> unit = "babylon_texture_setUScale"
  external setVScale : scale:float -> t -> unit = "babylon_texture_setVScale"

  external setHasAlpha : hasAlpha:bool -> t -> unit
    = "babylon_texture_setHasAlpha"

  external setAlpha : alpha:float -> t -> unit = "babylon_texture_setAlpha"
end

module ParticleSystem = struct
  type t

  module Options = struct
    type t = { capacity : int }

    let default = { capacity = 100 }
    let withCapacity capacity _options = { capacity }
  end

  external _create : int -> t = "babylon_particleSystem_createDefault"

  let create ?(options = Options.default) pos = _create options.capacity

  external reset : t -> unit = "babylon_particleSystem_reset"
  external start : delay:float -> t -> unit = "babylon_particleSystem_start"
  external stop : t -> unit = "babylon_particleSystem_stop"

  external setTargetStopDuration : float -> t -> unit
    = "babylon_particleSystem_setTargetStopDuration"

  type emitter

  external createHemisphericEmitter :
    radius:float -> radiusRange:float -> t -> emitter
    = "babylon_particleSystem_createHemisphericEmitter"

  external setEmitter : _ node -> t -> unit
    = "babylon_particleSystem_setEmitter"

  external setEmitRate : float -> t -> unit
    = "babylon_particleSystem_setEmitRate"

  external setMinSize : float -> t -> unit = "babylon_particleSystem_setMinSize"
  external setMaxSize : float -> t -> unit = "babylon_particleSystem_setMaxSize"

  external setMinLifeTime : float -> t -> unit
    = "babylon_particleSystem_setMinLifeTime"

  external setMaxLifeTime : float -> t -> unit
    = "babylon_particleSystem_setMaxLifeTime"

  external setMinEmitPower : float -> t -> unit
    = "babylon_particleSystem_setMinEmitPower"

  external setMaxEmitPower : float -> t -> unit
    = "babylon_particleSystem_setMaxEmitPower"

  external addLimitVelocityGradient : factor:float -> float -> t -> unit
    = "babylon_particleSystem_addLimitVelocityGradient"

  external addColorGradient : color:Color.t -> float -> t -> unit
    = "babylon_particleSystem_addColorGradient"

  external addRampGradient : color:Color.t -> float -> t -> unit
    = "babylon_particleSystem_addRampGradient"

  external addColorRemapGradient : min:float -> max:float -> float -> t -> unit
    = "babylon_particleSystem_addColorRemapGradient"

  external setUseRampGradients : bool -> t -> unit
    = "babylon_particleSystem_setUseRampGradients"

  external setLimitVelocityDamping : float -> t -> unit
    = "babylon_particleSystem_setLimitVelocityDamping"

  external setMinInitialRotation : float -> t -> unit
    = "babylon_particleSystem_setMinInitialRotation"

  external setMaxInitialRotation : float -> t -> unit
    = "babylon_particleSystem_setMaxInitialRotation"

  external setParticleTexture : Texture.t -> t -> unit
    = "babylon_particleSystem_setParticleTexture"
end

module Material = struct
  type t

  external freeze : t -> unit = "babylon_material_freeze"
  external unfreeze : t -> unit = "babylon_material_unfreeze"
  external standard : name:string -> t = "babylon_material_standard"

  external setWireframe : wireframe:bool -> t -> unit
    = "babylon_material_setWireframe"

  external setDiffuseColor : color:Color.t -> t -> unit
    = "babylon_material_setDiffuseColor"

  external setSpecularColor : color:Color.t -> t -> unit
    = "babylon_material_setSpecularColor"

  external setEmissiveColor : color:Color.t -> t -> unit
    = "babylon_material_setEmissiveColor"

  external setAmbientColor : color:Color.t -> t -> unit
    = "babylon_material_setAmbientColor"

  external setDiffuseTexture : texture:Texture.t -> t -> unit
    = "babylon_material_setDiffuseTexture"

  external setNormalTexture : texture:Texture.t -> t -> unit
    = "babylon_material_setNormalTexture"

  external setSpecularTexture : texture:Texture.t -> t -> unit
    = "babylon_material_setSpecularTexture"

  external setEmissiveTexture : texture:Texture.t -> t -> unit
    = "babylon_material_setEmissiveTexture"

  external setBumpTexture : texture:Texture.t -> t -> unit
    = "babylon_material_setBumpTexture"
end

module AnimationGroup = struct
  type t

  external name : t -> string = "babylon_animationGroup_name"
  external play : t -> unit = "babylon_animationGroup_play"
  external stop : t -> unit = "babylon_animationGroup_stop"
  external goToFrame : float -> t -> unit = "babylon_animationGroup_goToFrame"
end

module Mesh = struct
  external custom : name:string -> mesh node = "babylon_mesh_custom"

  external setVisibility : float -> mesh node -> unit
    = "babylon_mesh_setVisibility"

  external visibility : mesh node -> float = "babylon_mesh_getVisibility"

  external setMaterial : material:Material.t -> mesh node -> unit
    = "babylon_mesh_setMaterial"

  external bakeTransformIntoVertices : Matrix.t -> mesh node -> unit
    = "babylon_mesh_bakeTransformIntoVertices"

  external refreshBoundingInfo : mesh node -> unit
    = "babylon_mesh_refreshBoundingInfo"
end

module WebXR = struct
  module Handedness = struct
    type t = None | Left | Right

    let toString = function None -> "none" | Left -> "left" | Right -> "right"
  end

  module ControllerAxes = struct
    type t

    external x : t -> float = "babylon_controllerAxes_x"
    external y : t -> float = "babylon_controllerAxes_y"
  end

  module ControllerComponent = struct
    type t

    external id : t -> string = "babylon_controllerComponent_id"
    external pressed : t -> bool = "babylon_controllerComponent_pressed"
    external axes : t -> ControllerAxes.t = "babylon_controllerComponent_axes"
  end

  module MotionController = struct
    type t

    external componentIds : t -> string array
      = "babylon_motionController_componentIds"

    external getComponent : string -> t -> ControllerComponent.t option
      = "babylon_motionController_component"

    external handedness : t -> Handedness.t
      = "babylon_motionController_handedness"

    external pulse : value:float -> duration:float -> t -> unit
      = "babylon_motionController_pulse"
  end

  module Controller = struct
    type t

    external uniqueId : t -> string = "babylon_webxr_controller_uniqueId"
    external grip : t -> mesh node option = "babylon_webxr_controller_grip"
    external pointer : t -> mesh node = "babylon_webxr_controller_pointer"

    external motionController : t -> MotionController.t option
      = "babylon_webxr_controller_motionController"
  end

  module Input = struct
    type t

    external controllers : t -> Controller.t array
      = "babylon_webxr_input_controllers"
  end

  module ExperienceHelper = struct
    type t

    external isInXR : t -> bool = "babylon_webxr_experienceHelper_isInXR"
    external camera : t -> camera node = "babylon_webxr_experienceHelper_camera"
  end

  module DefaultExperience = struct
    type t

    external input : t -> Input.t = "babylon_webxr_defaultExperience_input"

    external baseExperience : t -> ExperienceHelper.t
      = "babylon_webxr_defaultExperience_baseExperience"
  end

  external createDefaultXRExperienceAsync :
    Scene.t -> DefaultExperience.t Promise.t
    = "babylon_scene_create_default_xr_experience_async"
end

module VertexData = struct
  type t

  external create : unit -> t = "babylon_vertexData_ctor"

  external applyToMesh : mesh:mesh node -> t -> unit
    = "babylon_vertexData_applyToMesh"

  external setPositions : positions:float array -> t -> unit
    = "babylon_vertexData_setPositions"

  external setIndices : indices:int array -> t -> unit
    = "babylon_vertexData_setIndices"

  external setUVs : uvs:float array -> t -> unit = "babylon_vertexData_setUVs"
end

module MeshBuilder = struct
  module Sphere = struct
    type options = { diameter : float }

    let default = { diameter = 1.0 }

    external create : name:string -> options:options -> mesh node
      = "babylon_meshbuilder_sphere_create"
  end

  module Box = struct
    type options = { size : float }

    let default = { size = 1.0 }

    external _create : options -> mesh node = "babylon_meshbuilder_box_create"

    let create ?(options = default) () = _create options
  end

  module Cylinder = struct
    type options = { height : float; diameter : float }

    let default = { height = 2.0; diameter = 1.0 }

    external _create : options -> mesh node
      = "babylon_meshbuilder_cylinder_create"

    let create ?(options = default) () = _create options
  end

  module Ground = struct
    type options = { width : float; height : float }

    let default = { width = 1.0; height = 1.0 }

    external _create : options -> mesh node
      = "babylon_meshbuilder_ground_create"

    let create ?(options = default) () = _create options
  end

  module Plane = struct
    type options = { width : float; height : float }

    let default = { width = 1.; height = 1. }

    external _create : string -> options -> mesh node
      = "babylon_meshbuilder_plane_create"

    let create ?(options = default) ?(name = "Plane") () = _create name options
  end
end

module Bone = struct
  external getLocalPosition : bone node -> Vector3.t
    = "babylon_bone_getLocalPosition"

  external getLocalRotation : bone node -> Quaternion.t
    = "babylon_bone_getLocalRotation"
end

module Skeleton = struct
  type t

  external boneCount : t -> int = "babylon_skeleton_boneCount"

  external getBoneByIndex : int -> t -> bone node option
    = "babylon_skeleton_getBoneByIndex"
end

module Camera = struct
  external free : name:string -> position:Vector3.t -> Scene.t -> camera node
    = "babylon_camera_free_ctor"

  external arcRotate : name:string -> target:Vector3.t -> Scene.t -> camera node
    = "babylon_camera_arcRotate_ctor"

  external attachControl :
    canvas:Dom_html.canvasElement Js.t -> attached:bool -> camera node -> unit
    = "babylon_camera_attach_control"

  external setTarget : target:Vector3.t -> camera node -> unit
    = "babylon_camera_set_target"

  external setInertia : inertia:float -> camera node -> unit
    = "babylon_camera_set_inertia"

  external rotate : x:Angle.radians -> y:Angle.radians -> camera node -> unit
    = "babylon_camera_rotate"

  external absoluteRotation : camera node -> Quaternion.t
    = "babylon_camera_getAbsoluteRotation"

  external _setTransformationFromNonVRCamera :
    resetToBaseReferenceSpace:bool ->
    sourceCamera:camera node ->
    camera node ->
    unit = "babylon_camera_setTransformationFromNonVRCamera"

  external realWorldHeight : camera node -> float
    = "babylon_camera_realWorldHeight"

  let setTransformationFromNonVRCamera ?(resetToBaseReferenceSpace = false)
      ~sourceCamera camera =
    _setTransformationFromNonVRCamera ~resetToBaseReferenceSpace ~sourceCamera
      camera
end

module AssetContainer = struct
  type t

  module Entries = struct
    type t

    external nodes : t -> _ node array = "babylon_assetContainer_entries_nodes"
  end

  external instantiateModelsToScene : prefix:string -> t -> Entries.t
    = "babylon_assetContainer_instantiateModelsToScene"
end

module SceneLoader = struct
  module LoadResult = struct
    type t

    external meshes : t -> mesh node array
      = "babylon_sceneLoader_loadResult_meshes"

    external skeletons : t -> Skeleton.t array
      = "babylon_sceneLoader_loadResult_skeletons"

    external animationGroups : t -> AnimationGroup.t array
      = "babylon_sceneLoader_loadResult_animationGroups"
  end

  external _importMeshAsync :
    string -> string -> Scene.t option -> LoadResult.t Promise.t
    = "babylon_sceneLoader_importMeshAsync"

  let importMeshAsync ?(rootUrl : string option) ~(fileName : string)
      (maybeScene : Scene.t option) =
    let root = match rootUrl with None -> "/" | Some v -> v in
    _importMeshAsync root fileName maybeScene

  external loadAssetContainerAsync :
    rootUrl:string -> string -> AssetContainer.t Promise.t
    = "babylon_sceneLoader_loadAssetContainerAsync"
end

module QuaternionEx = struct
  let _inferUpVector (nForwardVector : Vector3.t) =
    let dot = Vector3.dot nForwardVector (Vector3.up 1.0) in
    let initialUp =
      if dot > 0.999 then Vector3.forward 1.0 else Vector3.up 1.0
    in
    let nRight = Vector3.cross nForwardVector initialUp |> Vector3.normalize in
    Vector3.cross nRight nForwardVector |> Vector3.normalize

  let lookAt =
    (fun ?up forward ->
       let nForward = Vector3.normalize forward in
       let nUp =
         match up with
         | Some v -> Vector3.normalize v
         | None -> _inferUpVector nForward
       in
       Quaternion.lookAt ~forward:nForward ~up:nUp
      : ?up:Vector3.t -> Vector3.t -> Quaternion.t)
end
