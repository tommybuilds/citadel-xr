open EntityManager
let dynamic =
  (Component.readwrite ~name:"System_Physics.dynamic" () : (Component.readwrite,
                                                             State.t list)
                                                             Component.t)