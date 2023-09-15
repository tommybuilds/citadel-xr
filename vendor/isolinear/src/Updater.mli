type ('model, 'msg) t = 'model -> 'msg -> 'model * 'msg Effect.t

val ofReducer : ('model -> 'msg -> 'model) -> ('model, 'msg) t
val combine : ('model, 'msg) t list -> ('model, 'msg) t