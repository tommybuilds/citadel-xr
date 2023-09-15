type 'a t = 'a option ref
let create () = ref None
let send : 'a t -> 'b t -> 'a -> 'b option =
  fun inPipe ->
    fun outPipe ->
      fun data ->
        inPipe := (Some data);
        (let received = !outPipe in inPipe := None; received)