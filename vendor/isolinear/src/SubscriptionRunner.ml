open Sub
open Util

type 'msg t = (string, 'msg Sub.t) Hashtbl.t

let empty = (fun () -> Hashtbl.create 0 : unit -> (string, _ Sub.t) Hashtbl.t)

let getSubscriptionName (subscription : 'msg Sub.t) =
  match subscription with
  | NoSubscription -> "__isolinear__nosubscription__"
  | ((Subscription ({ params; state; provider = (module Provider) }, _))
  [@explicit_arity]) ->
      Provider.name ^ "$" ^ Provider.id params
  | SubscriptionBatch _ -> "__isolinear__batch__"

let dispose (subscription : 'msg Sub.t) =
  match subscription with
  | NoSubscription -> ()
  | ((Subscription ({ provider = (module Provider); params; state; latch }, _))
  [@explicit_arity]) -> (
      latch := false;
      match state with
      | None -> ()
      | Some state -> Provider.dispose ~params ~state)
  | SubscriptionBatch _ -> ()

let init (subscription : 'msg Sub.t) (dispatch : 'msg -> unit) =
  match subscription with
  | NoSubscription -> NoSubscription
  | Subscription
      ({ latch; provider = (module Provider); params; state; pipe }, mapper) ->
      latch := true;
      let state =
        Provider.init ~params ~dispatch:(fun msg ->
            if !latch then dispatch (mapper msg))
      in
      Subscription
        ( {
            latch;
            provider = (module Provider);
            params;
            state = Some state;
            pipe;
          },
          mapper )
  | SubscriptionBatch _ -> NoSubscription

let update oldSubscription newSubscription dispatch =
  match (oldSubscription, newSubscription) with
  | NoSubscription, NoSubscription -> NoSubscription
  | NoSubscription, sub -> init sub dispatch
  | sub, NoSubscription ->
      dispose sub;
      NoSubscription
  | ( Subscription (oldData, oldMapper),
      ((Subscription
         (({ provider = (module Provider); _ } as newData), newMapper))
      [@explicit_arity]) ) -> (
      match Pipe.send oldData.pipe newData.pipe oldData.state with
      | Some (Some oldState) ->
          let latch = oldData.latch in
          let newState =
            Provider.update ~params:newData.params ~state:oldState
              ~dispatch:(fun msg -> if !latch then dispatch (newMapper msg))
          in
          Subscription ({ newData with latch; state = Some newState }, newMapper)
      | None | Some None ->
          dispose oldSubscription;
          init newSubscription dispatch)
  | _ -> NoSubscription

let reconcile subs oldState dispatch =
  let newState = Hashtbl.create (Hashtbl.length oldState) in
  let iter (sub : 'msg Sub.t) =
    let subscriptionName = getSubscriptionName sub in
    let newSubState =
      match Hashtbl.find_opt oldState subscriptionName with
      | None -> init sub dispatch
      | Some previousSub -> update previousSub sub dispatch
    in
    Hashtbl.replace newState subscriptionName newSubState
  in
  List.iter iter subs;
  newState

let run ~(dispatch : 'msg -> unit) ~(sub : 'msg Sub.t) (state : 'msg t) =
  let subs = Sub.flatten sub in
  let newState = reconcile subs state dispatch in
  Hashtbl.iter
    (fun key v ->
      match Hashtbl.find_opt newState key with
      | Some _ -> ()
      | None -> dispose v)
    state;
  newState