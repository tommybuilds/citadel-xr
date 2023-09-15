module Options = struct
  type t = { damping : float; stiffness : float }

  let default = { damping = 14.; stiffness = 40. }
end

type t = {
  value : float;
  velocity : float;
  acceleration : float;
  options : Options.t;
  leftOverTime : float;
}

let create ?(options = Options.default) () =
  { value = 0.; velocity = 0.; acceleration = 0.; options; leftOverTime = 0. }

let deltaTime = 0.008

let tick spring =
  let target = 0. in
  let mass = 1.0 in
  let options = spring.options in
  let value = spring.value +. (spring.velocity *. deltaTime) in
  let forceSpring = (target -. value) *. options.stiffness in
  let forceDamping = options.damping *. spring.velocity in
  let force = forceSpring -. forceDamping in
  let acceleration = force /. mass in
  let velocity = spring.velocity +. (acceleration *. deltaTime) in
  { spring with acceleration; velocity; value }

let update deltaT spring =
  let time = spring.leftOverTime +. deltaT in
  let updatedSpring = ref spring in
  let remainingTime = ref time in
  while !remainingTime >= deltaTime do
    updatedSpring := tick !updatedSpring;
    remainingTime := !remainingTime -. deltaTime
  done;
  tick { !updatedSpring with leftOverTime = !remainingTime }

let applyImpulse magnitude ({ velocity; _ } as spring) =
  let velocity' = velocity +. magnitude in
  { spring with velocity = velocity' }

let value { value; _ } = value
