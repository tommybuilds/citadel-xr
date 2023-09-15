open Util

module type Provider = sig
  type params
  type msg
  type state

  val name : string
  val id : params -> string
  val init : params:params -> dispatch:(msg -> unit) -> state
  val update : params:params -> state:state -> dispatch:(msg -> unit) -> state
  val dispose : params:params -> state:state -> unit
end

type ('params, 'msg, 'state) provider =
  (module Provider
     with type msg = 'msg
      and type params = 'params
      and type state = 'state)

type ('params, 'msg, 'state) subscription = {
  latch : bool ref;
  provider : ('params, 'msg, 'state) provider;
  params : 'params;
  state : 'state option;
  pipe : 'state option Pipe.t;
}

type 'msg t =
  | NoSubscription : 'msg t
  | Subscription :
      ('params, 'originalMsg, 'state) subscription * ('originalMsg -> 'msg)
      -> 'msg t
  | SubscriptionBatch of 'msg t list

let batch subs = SubscriptionBatch subs

let flatten sub =
  let rec loop sub =
    match sub with
    | NoSubscription -> []
    | Subscription _ as sub -> [ sub ]
    | SubscriptionBatch subs -> subs |> List.map loop |> List.flatten
  in
  loop sub

let rec map =
  (fun f sub ->
     match sub with
     | NoSubscription -> NoSubscription
     | Subscription (sub, orig) ->
         let newMapFunction msg = f (orig msg) in
         Subscription (sub, newMapFunction)
     | SubscriptionBatch subs -> SubscriptionBatch (List.map (map f) subs)
    : ('a -> 'b) -> 'a t -> 'b t)

module type S = sig
  type params
  type msg

  val create : params -> msg t
end

module Make (Provider : Provider) = struct
  type params = Provider.params
  type msg = Provider.msg

  let pipe = Pipe.create ()

  let create params =
    Subscription
      ( {
          latch = ref false;
          pipe;
          provider = (module Provider);
          params;
          state = None;
        },
        Fun.id )
end

let none = NoSubscription