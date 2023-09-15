module type Reconciler = sig
  type primitives
  type node

  val canBeReused : primitives -> primitives -> bool
  val appendChild : node -> node -> node
  val createInstance : primitives -> node
  val replaceChild : node -> node -> node -> unit
  val removeChild : node -> node -> unit
  val updateInstance : node -> primitives -> primitives -> unit
end

module type React = sig
  type primitives
  type node

  type renderedElement = RenderedPrimitive of node
  and elementWithChildren = element list
  and render = unit -> elementWithChildren
  and element = Primitive of primitives * render | Empty of render

  type t
  type reconcileNotification = node -> unit

  val createContainer : node -> t
  val updateContainer : t -> element -> unit

  type component

  val primitiveComponent : children:element list -> primitives -> element
end
