module Reconciler = Reactify.Make (WebReconciler)
include Reconciler

type 'msg container = {
  pipe : 'msg Util.Pipe.t;
  dispatch : 'msg -> unit;
  container : Reconciler.t;
}

type 'msg context = 'msg Util.Pipe.t

let div ~id ~children () =
  Reconciler.primitiveComponent ~children (WebReconciler.Div { id })

let text ~(children : string list) () =
  Reconciler.primitiveComponent ~children:[]
    (WebReconciler.Span { text = List.hd children })

let checkbox ~context ~onChange ~children:_ () =
  Reconciler.primitiveComponent ~children:[]
    (WebReconciler.Checkbox { handler = onChange; pipe = context })

let slider ?(min = 0.0) ?(max = 100.0) ~context ~onChange ~children:_ () =
  Reconciler.primitiveComponent ~children:[]
    (WebReconciler.Slider { min; max; handler = onChange; pipe = context })

let context { pipe; _ } = pipe

let createContainer ~dispatch rootNode =
  {
    pipe = Util.Pipe.create ();
    dispatch;
    container = Reconciler.createContainer rootNode;
  }

let updateContainer { pipe; dispatch; container } elements =
  WebReconciler.globalDispatch :=
    Some (WebReconciler.Dispatcher { dispatch; pipe });
  Reconciler.updateContainer container elements;
  WebReconciler.globalDispatch := None