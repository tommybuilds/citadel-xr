type t = {
  input: Input.State.t }
let _state = ref { input = Input.State.default }
let current () = !_state
let update v = _state := v