type 'msg dispatcher = 'msg -> unit
type 'msg t

val create : name:string -> (unit -> unit) -> 'msg t
val createWithDispatch : name:string -> ('msg dispatcher -> unit) -> 'msg t
val none : 'msg t
val batch : 'msg t list -> 'msg t
val map : ('a -> 'b) -> 'a t -> 'b t
val name : 'msg t -> string
val run : 'msg t -> 'msg dispatcher -> unit