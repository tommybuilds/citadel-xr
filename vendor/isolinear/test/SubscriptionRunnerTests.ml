open TestFramework
module Sub = Isolinear.Sub
module SubscriptionRunner = Isolinear.Testing.SubscriptionRunner

type testState = Init of int | Update of int | Dispose of int
type testState2 = Init2 of int | Update2 of int | Dispose2 of int

let map = function
  | Init v -> Init2 v
  | Update v -> Update2 v
  | Dispose v -> Dispose2 v

let disposeState = (ref [] : testState list ref)

module TestSubscription = Sub.Make (struct
  type params = int
  type msg = testState
  type state = testState list

  let name = "TestSubscription"
  let id params = params |> string_of_int

  let init ~params ~dispatch =
    dispatch (Init params);
    [ Init params ]

  let update ~params ~state ~dispatch =
    let newState = Update params :: state in
    dispatch (Update params);
    newState

  let dispose ~params:_ ~state:_ = ()
end)

let globalDispatch = ref None

module SubscriptionThatHoldsOnToDispatch = Sub.Make (struct
  type params = int
  type msg = testState
  type state = unit

  let name = "SubscriptionThatHoldsOnToDispatch"
  let id params = params |> string_of_int

  let init ~params ~dispatch =
    globalDispatch := Some dispatch;
    ()

  let update ~params:_ ~state:_ ~dispatch:_ = ()
  let dispose ~params:_ ~state:_ = ()
end)
;;

describe "SubscriptionRunner" (fun { describe; _ } ->
    describe "dispose" (fun { test; _ } ->
        test
          ("dispatch called after subscription is gone is a no-op"
          [@reason.raw_literal
            "dispatch called after subscription is gone is a no-op"])
          (fun { expect; _ } ->
            let actions = (ref [] : testState list ref) in
            let dispatch action = actions := action :: !actions in
            let sub = SubscriptionThatHoldsOnToDispatch.create 1 in
            let empty =
              (SubscriptionRunner.empty () : testState SubscriptionRunner.t)
            in
            let runner = SubscriptionRunner.run ~dispatch ~sub empty in
            !globalDispatch |> Option.iter (fun dispatch -> dispatch (Init 1));
            expect.equal !actions [ Init 1 ];
            actions := [];
            let _ =
              SubscriptionRunner.run ~dispatch ~sub:Isolinear.Sub.none runner
            in
            !globalDispatch |> Option.iter (fun dispatch -> dispatch (Init 2));
            expect.equal !actions []));
    describe "subscribe" (fun { test; _ } ->
        test "init is called" (fun { expect; _ } ->
            let lastAction = (ref None : testState option ref) in
            let dispatch action = lastAction := Some action in
            let sub = TestSubscription.create 1 in
            let empty =
              (SubscriptionRunner.empty () : testState SubscriptionRunner.t)
            in
            let _ = SubscriptionRunner.run ~dispatch ~sub empty in
            expect.equal !lastAction (Some (Init 1)));
        test "update is called" (fun { expect; _ } ->
            let lastAction = (ref None : testState option ref) in
            let dispatch action = lastAction := Some action in
            let sub = TestSubscription.create 1 in
            let empty =
              (SubscriptionRunner.empty () : testState SubscriptionRunner.t)
            in
            let newState = SubscriptionRunner.run ~dispatch ~sub empty in
            let _ = SubscriptionRunner.run ~dispatch ~sub newState in
            expect.equal !lastAction (Some (Update 1))));
    describe "batched subscriptions" (fun { test; _ } ->
        test "init called for both" (fun { expect; _ } ->
            let allActions = (ref [] : testState list ref) in
            let dispatch action = allActions := action :: !allActions in
            let sub1 = TestSubscription.create 1 in
            let sub2 = TestSubscription.create 2 in
            let subs = Sub.batch [ sub1; sub2 ] in
            let empty = SubscriptionRunner.empty () in
            let state = SubscriptionRunner.run ~dispatch ~sub:subs empty in
            expect.equal (!allActions |> List.rev) [ Init 1; Init 2 ];
            let subs = Sub.batch [ sub2 ] in
            let state = SubscriptionRunner.run ~dispatch ~sub:subs state in
            expect.equal (!allActions |> List.rev) [ Init 1; Init 2; Update 2 ];
            let subs = Sub.batch [ sub1; sub2 ] in
            let _state = SubscriptionRunner.run ~dispatch ~sub:subs state in
            expect.equal (!allActions |> List.rev)
              [ Init 1; Init 2; Update 2; Init 1; Update 2 ]));
    describe "mapped subscriptions" (fun { test; _ } ->
        test "init called for both" (fun { expect; _ } ->
            let allActions = (ref [] : testState2 list ref) in
            let dispatch action = allActions := action :: !allActions in
            let sub1 =
              (TestSubscription.create 1 |> Sub.map map : testState2 Sub.t)
            in
            let empty = SubscriptionRunner.empty () in
            let state = SubscriptionRunner.run ~dispatch ~sub:sub1 empty in
            expect.equal (!allActions |> List.rev) [ Init2 1 ];
            let _ = SubscriptionRunner.run ~dispatch ~sub:sub1 state in
            expect.equal (!allActions |> List.rev) [ Init2 1; Update2 1 ])))
