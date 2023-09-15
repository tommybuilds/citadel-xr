open Babylon

module CameraController : sig
  type t

  val position : t -> Vector3.t
  val rotation : t -> Quaternion.t
  val realWorldHeight : t -> float
end

module Button : sig
  type t

  val isPressed : t -> bool
end

module Thumbstick : sig
  type t

  val x : t -> float
  val y : t -> float
end

module HandController : sig
  type t

  val position : t -> Vector3.t
  val rotation : t -> Quaternion.t
  val trigger : t -> Button.t
  val squeeze : t -> Button.t
  val button1 : t -> Button.t
  val button2 : t -> Button.t
  val thumbstick : t -> Thumbstick.t
end

module State : sig
  type t

  val default : t
  val camera : t -> CameraController.t
  val leftHand : t -> HandController.t option
  val rightHand : t -> HandController.t option
end

val fromXR : transform:Matrix.t -> WebXR.DefaultExperience.t -> State.t
val fromMock : transform:Matrix.t -> camera node -> State.t
val initializeDomHandlers : unit -> unit