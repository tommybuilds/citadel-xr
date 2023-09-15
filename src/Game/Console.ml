open Js_of_ocaml

let log title =
  let _ =
    Js.Unsafe.fun_call
      (Js.Unsafe.js_expr "console.log")
      [| title |> Js.string |> Js.Unsafe.inject |]
  in
  ()

let error title =
  let _ =
    Js.Unsafe.fun_call
      (Js.Unsafe.js_expr "console.error")
      [| title |> Js.string |> Js.Unsafe.inject |]
  in
  ()