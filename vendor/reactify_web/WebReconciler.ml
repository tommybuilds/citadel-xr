open Js_of_ocaml
open Util

type primitives =
  | Div of { id : string }
  | Span of { text : string }
  | Slider : {
      pipe : 'a Pipe.t;
      handler : float -> 'a;
      min : float;
      max : float;
    }
      -> primitives
  | Checkbox : { pipe : 'a Pipe.t; handler : bool -> 'a } -> primitives

type node = Js_of_ocaml.Dom_html.htmlElement Js.t

type dispatcher =
  | Dispatcher : { pipe : 'msg Pipe.t; dispatch : 'msg -> unit } -> dispatcher

let globalDispatch = (ref None : dispatcher option ref)

let canBeReused prim1 prim2 =
  match (prim1, prim2) with
  | Checkbox _, Checkbox _ -> true
  | Slider _, Slider _ -> true
  | Div _, Div _ -> true
  | Span _, Span _ -> true
  | _ -> false

let appendChild (parent : Dom_html.element Js.t) (child : Dom_html.element Js.t)
    =
  Dom.appendChild parent child;
  child

let updateInstance node _oldPrim newPrim =
  match newPrim with
  | Span { text } -> node##.innerHTML := Js.string text
  | _ -> ()

let removeChild parent child = Dom.removeChild parent child

let createInstance = function
  | Checkbox { pipe = checkBoxPipe; handler } ->
      let checkbox =
        Dom_html.createInput ~_type:(Js.string "checkbox") Dom_html.document
      in
      let dispatcher = !globalDispatch in
      let _id =
        Dom_html.addEventListener checkbox Dom_html.Event.change
          (Dom_html.handler (fun _e ->
               let checked = checkbox##.checked = Js._true in
               (match dispatcher with
               | ((Some (Dispatcher { pipe; dispatch })) [@explicit_arity]) ->
                   let maybeVal =
                     Pipe.send checkBoxPipe pipe (handler checked)
                   in
                   maybeVal |> Option.iter dispatch
               | _ -> ());
               Js._true))
          (Js.bool true)
      in
      let elem = (checkbox :> Dom_html.htmlElement Js.t) in
      elem
  | Slider { pipe = sliderPipe; min; max; handler } ->
      let slider =
        Dom_html.createInput ~_type:(Js.string "range") Dom_html.document
      in
      let dispatcher = !globalDispatch in
      (Js.Unsafe.coerce slider)##.max := max;
      (Js.Unsafe.coerce slider)##.min := min;
      (Js.Unsafe.coerce slider)##.step := 0.1;
      let _id =
        Dom_html.addEventListener slider Dom_html.Event.input
          (Dom_html.handler (fun _e ->
               let num = Js.parseFloat slider##.value in
               (match dispatcher with
               | ((Some (Dispatcher { pipe; dispatch })) [@explicit_arity]) ->
                   let maybeVal = Pipe.send sliderPipe pipe (handler num) in
                   maybeVal |> Option.iter dispatch
               | _ -> ());
               Js._true))
          (Js.bool true)
      in
      let elem = (slider :> Dom_html.htmlElement Js.t) in
      elem
  | Div _ -> Dom_html.createDiv Dom_html.document
  | Span { text } as primitive ->
      let span = Dom_html.createSpan Dom_html.document in
      span##.innerHTML := Js.string text;
      updateInstance span primitive primitive;
      span

let replaceChild parent newChild oldChild =
  Dom.removeChild parent oldChild;
  Dom.appendChild parent newChild
