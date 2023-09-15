type ('model, 'msg) t = 'model -> 'msg -> 'model * 'msg Effect.t

let ofReducer reducer model msg = (reducer model msg, Effect.none)

let combine updaters state action =
  let newState, effects =
    List.fold_left
      (fun prev curr ->
        let prevState, prevEffects = prev in
        let newState, effect = curr prevState action in
        (newState, effect :: prevEffects))
      (state, [ Effect.none ])
      updaters
  in
  let effects =
    effects |> List.filter (fun eff -> eff != Effect.none) |> List.rev
  in
  (newState, Effect.batch effects)
