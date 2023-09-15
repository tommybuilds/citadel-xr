module Widget = struct
  type 'state t =
    | Checkbox of { label : string; handler : bool -> 'state -> 'state }
    | Slider of {
        label : string;
        min : float;
        max : float;
        handler : float -> 'state -> 'state;
      }

  let checkbox ~(label : string) (f : bool -> 'state -> 'state) =
    Checkbox { label; handler = f }

  let slider ?(min = 0.0) ?(max = 100.0) ~(label : string)
      (f : float -> 'state -> 'state) =
    Slider { min; max; label; handler = f }
end

type 'a editorHandler = 'a -> 'a

let render (ctx : ('state -> 'state) Reactify_web.context)
    (widget : 'state Widget.t) =
  match widget with
  | Slider { min; max; label; handler } ->
      let open Reactify_web in
      let dispatchMutator change =
        print_endline ("change: " ^ string_of_float change);
        let f = (handler change : 'state -> 'state) in
        f
      in
      (div ~id:"checkbox"
         ~children:
           [
             (text ~children:[ label ] () [@JSX]);
             (slider ~min ~max ~context:ctx ~onChange:dispatchMutator
                ~children:[] () [@JSX]);
           ]
         () [@JSX])
  | Checkbox { label; handler } ->
      let open Reactify_web in
      let dispatchMutator change =
        let f = (handler change : 'state -> 'state) in
        f
      in
      (div ~id:"checkbox"
         ~children:
           [
             (text ~children:[ label ] () [@JSX]);
             (checkbox ~context:ctx ~onChange:dispatchMutator ~children:[] ()
              [@JSX]);
           ]
         () [@JSX])

type 'state t = { widgets : 'state Widget.t list }

let empty = { widgets = [] }
let widgets (widgets : 'state Widget.t list) = { widgets }

module System = struct
  open Js_of_ocaml

  let make (initialState : 'state) { widgets } =
    let doc = Dom_html.window##.document in
    let body = doc##.body in
    let containerDiv = Dom_html.createDiv doc in
    Js_of_ocaml.Dom.appendChild body containerDiv;
    let queuedEvents = ref [] in
    let dispatch (evt : 'state -> 'state) =
      queuedEvents := evt :: !queuedEvents
    in
    let controlContainer =
      Reactify_web.createContainer ~dispatch containerDiv
    in
    let ctx = Reactify_web.context controlContainer in
    let tick ~deltaTime:_ ~world state =
      let elements = widgets |> List.map (render ctx) in
      let open Reactify_web in
      Reactify_web.updateContainer controlContainer
        (div ~id:"container" ~children:elements () [@JSX]);
      let state' =
        !queuedEvents |> List.fold_left (fun acc curr -> curr acc) state
      in
      queuedEvents := [];
      (state', world)
    in
    EntityManager.System.define ~tick initialState
end
