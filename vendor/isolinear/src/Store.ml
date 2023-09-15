type unsubscribe = unit -> unit

type ('msg, 'model) t = {
  latestState : 'model ref;
  pendingEffects : 'msg Effect.t list ref;
  updater : ('model, 'msg) Updater.t;
}

let make ~(updater : ('model, 'msg) Updater.t) (initial : 'model) =
  { pendingEffects = ref []; updater; latestState = ref initial }

let getState { latestState; _ } = !latestState
let updateState f { latestState; _ } = latestState := f !latestState

let rec dispatch (store : ('msg, 'model) t) (msg : 'msg) =
  let currentModel = !(store.latestState) in
  let newModel, effect = store.updater currentModel msg in
  let hasPendingEffect = ref false in
  if effect <> Effect.none then (
    store.pendingEffects := effect :: !(store.pendingEffects);
    hasPendingEffect := true);
  store.latestState := newModel

let hasPendingEffects store = !(store.pendingEffects) <> []

let runPendingEffects store =
  let effects = !(store.pendingEffects) in
  store.pendingEffects := [];
  effects
  |> List.filter (fun e -> e <> Effect.none)
  |> List.rev
  |> List.iter (fun e -> Effect.run e (dispatch store))
